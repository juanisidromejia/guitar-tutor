-- Integrate the adventure as a teacher-prepared bonus behind the existing class-session code.
-- Students continue to use /sesion/:code; the activity type is resolved only after joining.

alter table public.sessions
  add column if not exists activity_type text not null default 'assessment'
    check (activity_type in ('assessment','adventure')),
  add column if not exists adventure_game_id uuid
    references public.adventure_games(id) on delete set null;

create unique index if not exists sessions_adventure_game_unique
  on public.sessions(adventure_game_id)
  where adventure_game_id is not null;

create or replace function public.create_class_adventure_session(
  p_title text,
  p_difficulty text
)
returns jsonb
language plpgsql
security definer
set search_path=public
as $$
declare
  v_game jsonb;
  v_session public.sessions;
  v_code text;
  v_game_id uuid;
begin
  if auth.uid() is null or not public.is_authorized_teacher() then
    raise exception 'Este correo no está autorizado para administrar sesiones.';
  end if;
  if p_difficulty is null or p_difficulty not in ('beginner','intermediate','advanced','mixed') then
    raise exception 'Nivel de dificultad no válido.';
  end if;
  if char_length(trim(coalesce(p_title,''))) < 1 or char_length(trim(p_title)) > 90 then
    raise exception 'El nombre debe tener entre 1 y 90 caracteres.';
  end if;

  -- Reuse the adventure factory so rooms, challenges, treasure and events are seeded consistently.
  v_game := public.create_adventure_game(trim(p_title),p_difficulty);
  v_game_id := (v_game->>'id')::uuid;
  v_code := v_game->>'code';

  -- Codes are shared across the two entry systems, so guard against collisions in sessions too.
  if exists(select 1 from public.sessions where code=v_code) then
    loop
      v_code := upper(substr(replace(gen_random_uuid()::text,'-',''),1,6));
      exit when not exists(select 1 from public.sessions where code=v_code)
        and not exists(select 1 from public.adventure_games where code=v_code and id<>v_game_id);
    end loop;
    update public.adventure_games set code=v_code where id=v_game_id;
  end if;

  insert into public.sessions(
    owner_id,code,title,mode,question_count,difficulty,activity_type,adventure_game_id
  )
  values(
    auth.uid(),v_code,trim(p_title),'live',1,p_difficulty,'adventure',v_game_id
  )
  returning * into v_session;

  return jsonb_build_object(
    'id',v_session.id,'code',v_session.code,'title',v_session.title,
    'mode',v_session.mode,'status',v_session.status,'created_at',v_session.created_at,
    'current_question_index',v_session.current_question_index,
    'question_count',v_session.question_count,'difficulty',v_session.difficulty,
    'activity_type',v_session.activity_type,'adventure_game_id',v_session.adventure_game_id
  );
end
$$;

create or replace function public.join_class_session(p_code text,p_nickname text)
returns jsonb
language plpgsql
security definer
set search_path=public
as $$
declare
  v_uid uuid:=auth.uid();
  v_session public.sessions;
  v_p public.participants;
begin
  if v_uid is null then raise exception 'No se pudo identificar al participante.'; end if;
  if char_length(trim(p_nickname))<1 or char_length(trim(p_nickname))>24 then
    raise exception 'El nickname debe tener entre 1 y 24 caracteres.';
  end if;

  select * into v_session
  from public.sessions
  where code=upper(trim(p_code));
  if not found then raise exception 'No existe una sesión con ese código.'; end if;
  if v_session.status='finished' then raise exception 'Esta sesión ya finalizó.'; end if;

  insert into public.participants(session_id,user_id,nickname)
  values(v_session.id,v_uid,trim(p_nickname))
  on conflict(session_id,user_id) do update set nickname=excluded.nickname
  returning * into v_p;

  return jsonb_build_object(
    'session',jsonb_build_object(
      'id',v_session.id,'code',v_session.code,'title',v_session.title,
      'mode',v_session.mode,'status',v_session.status,
      'current_question_index',v_session.current_question_index,
      'question_count',v_session.question_count,'difficulty',v_session.difficulty,
      'activity_type',v_session.activity_type,'adventure_game_id',v_session.adventure_game_id
    ),
    'participant_id',v_p.id,'score',v_p.score
  );
end
$$;

create or replace function public.start_class_session(p_session_id uuid)
returns void
language plpgsql
security definer
set search_path=public
as $$
declare
  v_session public.sessions;
begin
  if not public.is_authorized_teacher() then
    raise exception 'Este correo no está autorizado para administrar sesiones.';
  end if;

  update public.sessions
  set status='active',current_question_index=0,updated_at=now()
  where id=p_session_id and owner_id=auth.uid() and status='lobby'
  returning * into v_session;
  if not found then raise exception 'No puedes iniciar esta sesión o ya fue iniciada.'; end if;

  if v_session.activity_type='adventure' then
    update public.adventure_games
    set status='active',updated_at=now()
    where id=v_session.adventure_game_id and owner_id=auth.uid() and status='lobby';
    if not found then raise exception 'No se pudo iniciar la aventura asociada.'; end if;
    insert into public.adventure_events(game_id,event_type,message)
    values(v_session.adventure_game_id,'game_started','¡El maestro ha abierto las catacumbas!');
  end if;
end
$$;

create or replace function public.finish_class_session(p_session_id uuid)
returns void
language plpgsql
security definer
set search_path=public
as $$
declare
  v_session public.sessions;
begin
  if not public.is_authorized_teacher() then
    raise exception 'Este correo no está autorizado para administrar sesiones.';
  end if;

  update public.sessions
  set status='finished',updated_at=now()
  where id=p_session_id and owner_id=auth.uid()
  returning * into v_session;
  if not found then raise exception 'La sesión no existe o no te pertenece.'; end if;

  update public.participants
  set finished_at=coalesce(finished_at,now())
  where session_id=p_session_id;

  if v_session.activity_type='adventure' then
    update public.adventure_games
    set status='finished',updated_at=now()
    where id=v_session.adventure_game_id and owner_id=auth.uid();
    insert into public.adventure_events(game_id,event_type,message)
    values(v_session.adventure_game_id,'game_finished','El maestro ha finalizado la aventura.');
  end if;
end
$$;

create or replace function public.advance_class_session(p_session_id uuid)
returns void
language plpgsql
security definer
set search_path=public
as $$
declare
  v_idx integer;
  v_total integer;
  v_type text;
begin
  if not public.is_authorized_teacher() then
    raise exception 'Este correo no está autorizado para administrar sesiones.';
  end if;
  select current_question_index,activity_type into v_idx,v_type
  from public.sessions
  where id=p_session_id and owner_id=auth.uid() and status='active'
  for update;
  if not found then raise exception 'La sesión no está activa o no te pertenece.'; end if;
  if v_type='adventure' then raise exception 'La aventura no utiliza avance de preguntas en vivo.'; end if;

  select count(*) into v_total from public.session_questions where session_id=p_session_id;
  if v_idx+1>=v_total then
    update public.sessions set status='finished',updated_at=now() where id=p_session_id;
    update public.participants set finished_at=coalesce(finished_at,now()) where session_id=p_session_id;
  else
    update public.sessions set current_question_index=v_idx+1,updated_at=now() where id=p_session_id;
  end if;
end
$$;

revoke all on function public.create_class_adventure_session(text,text) from public,anon;
grant execute on function public.create_class_adventure_session(text,text) to authenticated;
revoke all on function public.join_class_session(text,text) from public,anon;
grant execute on function public.join_class_session(text,text) to authenticated;
revoke all on function public.start_class_session(uuid) from public,anon;
grant execute on function public.start_class_session(uuid) to authenticated;
revoke all on function public.finish_class_session(uuid) from public,anon;
grant execute on function public.finish_class_session(uuid) to authenticated;
revoke all on function public.advance_class_session(uuid) from public,anon;
grant execute on function public.advance_class_session(uuid) to authenticated;
