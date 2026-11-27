-- Standalone diagnostic assessments use the same protected, level-based question bank
-- as teacher sessions. Students only receive question content; answer keys stay server-side.

create table if not exists public.diagnostic_attempts (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  difficulty text not null check (difficulty in ('beginner','intermediate','advanced','mixed')),
  question_count integer not null check (question_count between 1 and 20),
  status text not null default 'active' check (status in ('active','finished')),
  started_at timestamptz not null default now(),
  finished_at timestamptz
);

create table if not exists public.diagnostic_attempt_questions (
  attempt_id uuid not null references public.diagnostic_attempts(id) on delete cascade,
  question_id integer not null references public.class_question_bank(id),
  position integer not null check (position >= 0),
  selected_answer text,
  answered_at timestamptz,
  primary key (attempt_id, question_id),
  unique (attempt_id, position)
);

alter table public.diagnostic_attempts enable row level security;
alter table public.diagnostic_attempt_questions enable row level security;
revoke all on public.diagnostic_attempts from anon, authenticated;
revoke all on public.diagnostic_attempt_questions from anon, authenticated;

create or replace function public.start_diagnostic_attempt(
  p_difficulty text,
  p_question_count integer
)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  v_uid uuid := auth.uid();
  v_attempt public.diagnostic_attempts;
  v_available integer;
  v_questions jsonb;
begin
  if v_uid is null then
    raise exception 'Debes iniciar una sesión para comenzar el diagnóstico.';
  end if;

  if p_difficulty is null or p_difficulty not in ('beginner','intermediate','advanced','mixed') then
    raise exception 'Nivel de dificultad no válido.';
  end if;

  select count(*) into v_available
  from public.class_question_bank
  where p_difficulty = 'mixed' or difficulty = p_difficulty;

  if p_question_count is null or p_question_count < 1 or p_question_count > 20 or p_question_count > v_available then
    raise exception 'El número de preguntas debe estar entre 1 y 20 para el nivel seleccionado.';
  end if;

  insert into public.diagnostic_attempts(user_id, difficulty, question_count)
  values (v_uid, p_difficulty, p_question_count)
  returning * into v_attempt;

  with ranked as (
    select q.*,
      row_number() over (partition by q.difficulty order by random()) as level_rank
    from public.class_question_bank q
    where p_difficulty = 'mixed' or q.difficulty = p_difficulty
  ),
  picked as (
    select * from ranked
    order by level_rank, random()
    limit p_question_count
  ),
  numbered as (
    select *, row_number() over (order by random()) - 1 as position
    from picked
  )
  insert into public.diagnostic_attempt_questions(attempt_id, question_id, position)
  select v_attempt.id, id, position
  from numbered
  order by position;

  select coalesce(
    jsonb_agg(
      jsonb_build_object(
        'id', q.id,
        'position', aq.position,
        'difficulty', q.difficulty,
        'category', q.category,
        'prompt', q.prompt,
        'options', q.options,
        'midi', q.midi
      ) order by aq.position
    ),
    '[]'::jsonb
  )
  into v_questions
  from public.diagnostic_attempt_questions aq
  join public.class_question_bank q on q.id = aq.question_id
  where aq.attempt_id = v_attempt.id;

  return jsonb_build_object(
    'attempt_id', v_attempt.id,
    'difficulty', v_attempt.difficulty,
    'question_count', v_attempt.question_count,
    'questions', v_questions
  );
end
$$;

create or replace function public.submit_diagnostic_answer(
  p_attempt_id uuid,
  p_question_id integer,
  p_answer text
)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  v_attempt public.diagnostic_attempts;
  v_question public.class_question_bank;
begin
  select * into v_attempt
  from public.diagnostic_attempts
  where id = p_attempt_id and user_id = auth.uid()
  for update;

  if not found then
    raise exception 'No se encontró este intento diagnóstico.';
  end if;
  if v_attempt.status <> 'active' then
    raise exception 'Este diagnóstico ya fue finalizado.';
  end if;

  select q.* into v_question
  from public.class_question_bank q
  join public.diagnostic_attempt_questions aq on aq.question_id = q.id
  where aq.attempt_id = p_attempt_id and aq.question_id = p_question_id;

  if not found then
    raise exception 'La pregunta no pertenece a este diagnóstico.';
  end if;

  if not exists (
    select 1
    from public.class_question_bank q
    cross join lateral jsonb_array_elements_text(q.options) as option_value(value)
    where q.id = p_question_id and option_value.value = p_answer
  ) then
    raise exception 'La opción seleccionada no es válida.';
  end if;

  update public.diagnostic_attempt_questions
  set selected_answer = p_answer, answered_at = now()
  where attempt_id = p_attempt_id
    and question_id = p_question_id
    and selected_answer is null;

  if not found then
    raise exception 'Ya respondiste esta pregunta.';
  end if;

  return jsonb_build_object('accepted', true);
end
$$;

create or replace function public.finish_diagnostic_attempt(p_attempt_id uuid)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  v_attempt public.diagnostic_attempts;
  v_answered integer;
  v_correct integer;
  v_review jsonb;
  v_categories jsonb;
begin
  select * into v_attempt
  from public.diagnostic_attempts
  where id = p_attempt_id and user_id = auth.uid()
  for update;

  if not found then
    raise exception 'No se encontró este intento diagnóstico.';
  end if;

  select count(*) into v_answered
  from public.diagnostic_attempt_questions
  where attempt_id = p_attempt_id and selected_answer is not null;

  if v_answered <> v_attempt.question_count then
    raise exception 'Debes responder todas las preguntas antes de finalizar.';
  end if;

  update public.diagnostic_attempts
  set status = 'finished', finished_at = coalesce(finished_at, now())
  where id = p_attempt_id;

  select count(*) filter (where aq.selected_answer = q.correct_answer)
  into v_correct
  from public.diagnostic_attempt_questions aq
  join public.class_question_bank q on q.id = aq.question_id
  where aq.attempt_id = p_attempt_id;

  select coalesce(
    jsonb_agg(
      jsonb_build_object(
        'id', q.id,
        'position', aq.position,
        'difficulty', q.difficulty,
        'category', q.category,
        'prompt', q.prompt,
        'selected_answer', aq.selected_answer,
        'correct_answer', q.correct_answer,
        'is_correct', aq.selected_answer = q.correct_answer,
        'explanation', q.explanation,
        'midi', q.midi
      ) order by aq.position
    ),
    '[]'::jsonb
  )
  into v_review
  from public.diagnostic_attempt_questions aq
  join public.class_question_bank q on q.id = aq.question_id
  where aq.attempt_id = p_attempt_id;

  select coalesce(
    jsonb_agg(
      jsonb_build_object(
        'category', grouped.category,
        'correct', grouped.correct,
        'total', grouped.total
      ) order by grouped.category
    ),
    '[]'::jsonb
  )
  into v_categories
  from (
    select q.category,
      count(*) filter (where aq.selected_answer = q.correct_answer)::integer as correct,
      count(*)::integer as total
    from public.diagnostic_attempt_questions aq
    join public.class_question_bank q on q.id = aq.question_id
    where aq.attempt_id = p_attempt_id
    group by q.category
  ) grouped;

  return jsonb_build_object(
    'attempt_id', v_attempt.id,
    'difficulty', v_attempt.difficulty,
    'correct_count', v_correct,
    'total', v_attempt.question_count,
    'percentage', round(v_correct::numeric / v_attempt.question_count * 100)::integer,
    'category_results', v_categories,
    'review', v_review
  );
end
$$;

revoke all on function public.start_diagnostic_attempt(text, integer) from public, anon;
revoke all on function public.submit_diagnostic_answer(uuid, integer, text) from public, anon;
revoke all on function public.finish_diagnostic_attempt(uuid) from public, anon;
grant execute on function public.start_diagnostic_attempt(text, integer) to authenticated;
grant execute on function public.submit_diagnostic_answer(uuid, integer, text) to authenticated;
grant execute on function public.finish_diagnostic_attempt(uuid) to authenticated;
