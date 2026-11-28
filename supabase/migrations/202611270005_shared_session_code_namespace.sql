-- Keep the shared code namespace collision-free for both assessments and adventure bonuses.
create or replace function public.create_class_session(
  p_title text,
  p_mode text,
  p_question_count integer,
  p_difficulty text
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
  if p_difficulty is null or p_difficulty not in ('beginner','intermediate','advanced','mixed') then
    raise exception 'Nivel de dificultad no válido.';
  end if;
  if char_length(trim(p_title)) < 1 or char_length(trim(p_title)) > 90 then
    raise exception 'El nombre debe tener entre 1 y 90 caracteres.';
  end if;

  select count(*) into v_available
  from public.class_question_bank
  where p_difficulty='mixed' or difficulty=p_difficulty;

  if p_question_count is null or p_question_count < 1 or p_question_count > v_available then
    raise exception 'El número de preguntas debe estar entre 1 y % para el nivel seleccionado.', v_available;
  end if;

  -- Use the same transaction lock as adventure creation to prevent cross-table collisions.
  perform pg_advisory_xact_lock(hashtext('guitar_tutor_shared_session_code_namespace'));

  loop
    v_code := upper(substr(replace(pg_catalog.gen_random_uuid()::text,'-',''),1,6));
    exit when not exists(select 1 from public.sessions where code=v_code)
      and not exists(select 1 from public.adventure_games where code=v_code);
  end loop;

  insert into public.sessions(owner_id,code,title,mode,question_count,difficulty)
  values(v_uid,v_code,trim(p_title),p_mode,p_question_count,p_difficulty)
  returning * into v_session;

  with ranked as (
    select q.*,
      row_number() over(partition by q.difficulty order by random()) as level_rank
    from public.class_question_bank q
    where p_difficulty='mixed' or q.difficulty=p_difficulty
  ),
  picked as (
    select * from ranked
    order by case when p_difficulty='mixed' then level_rank else 0 end, random()
    limit p_question_count
  ),
  numbered as (
    select *, row_number() over(order by random())-1 as position from picked
  )
  insert into public.session_questions(
    session_id,position,difficulty,category,prompt,options,correct_answer,explanation,midi
  )
  select v_session.id,position,difficulty,category,prompt,options,correct_answer,explanation,midi
  from numbered
  order by position;

  return jsonb_build_object(
    'id',v_session.id,'code',v_session.code,'title',v_session.title,
    'mode',v_session.mode,'status',v_session.status,'created_at',v_session.created_at,
    'current_question_index',v_session.current_question_index,
    'question_count',v_session.question_count,'difficulty',v_session.difficulty
  );
end
$$;


revoke all on function public.create_class_session(text,text,integer,text) from public, anon;
grant execute on function public.create_class_session(text,text,integer,text) to authenticated;
