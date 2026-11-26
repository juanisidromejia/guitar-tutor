-- Configurable question count and teacher-only per-student answer review.
alter table public.sessions
  add column if not exists question_count integer not null default 12
  check (question_count between 1 and 100);

update public.sessions s
set question_count = (
  select count(*)::integer from public.session_questions q where q.session_id=s.id
)
where exists (select 1 from public.session_questions q where q.session_id=s.id);

-- Remove obsolete creation RPCs, including the former client-supplied question-bank overload.
drop function if exists public.create_class_session(text,text);
drop function if exists public.create_class_session(text,text,jsonb);

create function public.create_class_session(
  p_title text,
  p_mode text,
  p_question_count integer
)
returns jsonb
language plpgsql
security definer
set search_path=public
as $$
declare
  v_uid uuid := auth.uid();
  v_session public.sessions;
  v_code text;
  v_available integer;
begin
  if v_uid is null or not public.is_authorized_teacher() then
    raise exception 'Este correo no está autorizado para administrar sesiones.';
  end if;
  if p_mode not in ('self_paced','live') then
    raise exception 'Modalidad no válida.';
  end if;
  if char_length(trim(p_title)) < 1 or char_length(trim(p_title)) > 90 then
    raise exception 'El nombre debe tener entre 1 y 90 caracteres.';
  end if;
  select count(*) into v_available from public.class_question_bank;
  if p_question_count is null or p_question_count < 1 or p_question_count > v_available then
    raise exception 'El número de preguntas debe estar entre 1 y %.', v_available;
  end if;

  loop
    v_code := upper(substr(replace(pg_catalog.gen_random_uuid()::text,'-',''),1,6));
    exit when not exists(select 1 from public.sessions where code=v_code);
  end loop;

  insert into public.sessions(owner_id,code,title,mode,question_count)
  values(v_uid,v_code,trim(p_title),p_mode,p_question_count)
  returning * into v_session;

  with picked as (
    select * from public.class_question_bank order by random() limit p_question_count
  ),
  numbered as (
    select *, row_number() over(order by random())-1 as position from picked
  )
  insert into public.session_questions(
    session_id,position,category,prompt,options,correct_answer,explanation,midi
  )
  select v_session.id,position,category,prompt,options,correct_answer,explanation,midi
  from numbered
  order by position;

  return jsonb_build_object(
    'id',v_session.id,
    'code',v_session.code,
    'title',v_session.title,
    'mode',v_session.mode,
    'status',v_session.status,
    'created_at',v_session.created_at,
    'current_question_index',v_session.current_question_index,
    'question_count',v_session.question_count
  );
end
$$;

revoke all on function public.create_class_session(text,text,integer) from public, anon;
grant execute on function public.create_class_session(text,text,integer) to authenticated;

-- This SECURITY DEFINER RPC is the only route for the teacher UI to obtain
-- the selected and correct answers together with explanations.
create or replace function public.get_class_session_results(p_session_id uuid)
returns jsonb
language plpgsql
stable
security definer
set search_path=public
as $$
declare
  v_results jsonb;
begin
  if not public.is_class_owner(p_session_id) then
    raise exception 'No tienes autorización para consultar estos resultados.';
  end if;

  select coalesce(
    jsonb_agg(
      jsonb_build_object(
        'participant_id',p.id,
        'answers',coalesce((
          select jsonb_agg(
            jsonb_build_object(
              'position',q.position,
              'prompt',q.prompt,
              'selected_answer',a.selected_answer,
              'correct_answer',q.correct_answer,
              'explanation',q.explanation,
              'is_correct',a.is_correct
            ) order by q.position
          )
          from public.session_answers a
          join public.session_questions q on q.id=a.question_id
          where a.participant_id=p.id and a.session_id=p_session_id
        ),'[]'::jsonb)
      ) order by p.joined_at
    ),
    '[]'::jsonb
  )
  into v_results
  from public.participants p
  where p.session_id=p_session_id;

  return v_results;
end
$$;

revoke all on function public.get_class_session_results(uuid) from public, anon;
grant execute on function public.get_class_session_results(uuid) to authenticated;
