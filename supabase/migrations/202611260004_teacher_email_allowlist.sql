-- Restrict teacher administration to the initial authorized email.
-- Students continue to join through anonymous authentication.
create or replace function public.is_authorized_teacher()
returns boolean
language sql
stable
as $$
  select lower(coalesce(auth.jwt()->>'email','')) = 'juanisidromejia@gmail.com'
    and coalesce((auth.jwt()->>'is_anonymous')::boolean,false) = false;
$$;

revoke all on function public.is_authorized_teacher() from public, anon;
grant execute on function public.is_authorized_teacher() to authenticated;

create or replace function public.is_class_owner(p_session_id uuid)
returns boolean
language sql
stable
security definer
set search_path=public
as $$
  select public.is_authorized_teacher()
    and exists(select 1 from public.sessions where id=p_session_id and owner_id=auth.uid());
$$;

drop policy if exists "class sessions visible to owner and joined students" on public.sessions;
create policy "class sessions visible to owner and joined students"
on public.sessions for select to authenticated
using ((owner_id=auth.uid() and public.is_authorized_teacher()) or public.is_class_participant(id));

drop policy if exists "owners update class sessions" on public.sessions;
create policy "owners update class sessions"
on public.sessions for update to authenticated
using (owner_id=auth.uid() and public.is_authorized_teacher())
with check (owner_id=auth.uid() and public.is_authorized_teacher());

create or replace function public.create_class_session(p_title text,p_mode text)
returns jsonb
language plpgsql
security definer
set search_path=public
as $$
declare
 v_uid uuid:=auth.uid();
 v_session public.sessions;
 v_code text;
begin
 if v_uid is null or not public.is_authorized_teacher() then
  raise exception 'Este correo no está autorizado para administrar sesiones.';
 end if;
 if p_mode not in ('self_paced','live') then raise exception 'Modalidad no válida.'; end if;
 if char_length(trim(p_title))<1 or char_length(trim(p_title))>90 then raise exception 'El nombre debe tener entre 1 y 90 caracteres.'; end if;
 loop
  v_code:=upper(substr(encode(gen_random_bytes(5),'hex'),1,6));
  exit when not exists(select 1 from public.sessions where code=v_code);
 end loop;
 insert into public.sessions(owner_id,code,title,mode)
 values(v_uid,v_code,trim(p_title),p_mode) returning * into v_session;
 insert into public.session_questions(session_id,position,category,prompt,options,correct_answer,explanation,midi)
 select v_session.id,row_number() over(order by id)-1,category,prompt,options,correct_answer,explanation,midi
 from public.class_question_bank order by id;
 return jsonb_build_object('id',v_session.id,'code',v_session.code,'title',v_session.title,'mode',v_session.mode,'status',v_session.status,'created_at',v_session.created_at);
end $$;

create or replace function public.start_class_session(p_session_id uuid)
returns void
language plpgsql
security definer
set search_path=public
as $$
begin
 if not public.is_authorized_teacher() then raise exception 'Este correo no está autorizado para administrar sesiones.'; end if;
 update public.sessions set status='active',current_question_index=0,updated_at=now()
 where id=p_session_id and owner_id=auth.uid() and status='lobby';
 if not found then raise exception 'No puedes iniciar esta sesión o ya fue iniciada.'; end if;
end $$;

create or replace function public.advance_class_session(p_session_id uuid)
returns void
language plpgsql
security definer
set search_path=public
as $$
declare v_idx integer; v_total integer;
begin
 if not public.is_authorized_teacher() then raise exception 'Este correo no está autorizado para administrar sesiones.'; end if;
 select current_question_index into v_idx from public.sessions
 where id=p_session_id and owner_id=auth.uid() and status='active' for update;
 if not found then raise exception 'La sesión no está activa o no te pertenece.'; end if;
 select count(*) into v_total from public.session_questions where session_id=p_session_id;
 if v_idx+1>=v_total then
  update public.sessions set status='finished',updated_at=now() where id=p_session_id;
  update public.participants set finished_at=coalesce(finished_at,now()) where session_id=p_session_id;
 else
  update public.sessions set current_question_index=v_idx+1,updated_at=now() where id=p_session_id;
 end if;
end $$;

create or replace function public.finish_class_session(p_session_id uuid)
returns void
language plpgsql
security definer
set search_path=public
as $$
begin
 if not public.is_authorized_teacher() then raise exception 'Este correo no está autorizado para administrar sesiones.'; end if;
 update public.sessions set status='finished',updated_at=now()
 where id=p_session_id and owner_id=auth.uid();
 if not found then raise exception 'La sesión no existe o no te pertenece.'; end if;
 update public.participants set finished_at=coalesce(finished_at,now()) where session_id=p_session_id;
end $$;

revoke all on function public.create_class_session(text,text) from public;
revoke all on function public.start_class_session(uuid) from public;
revoke all on function public.advance_class_session(uuid) from public;
revoke all on function public.finish_class_session(uuid) from public;
grant execute on function public.create_class_session(text,text) to authenticated;
grant execute on function public.start_class_session(uuid) to authenticated;
grant execute on function public.advance_class_session(uuid) to authenticated;
grant execute on function public.finish_class_session(uuid) to authenticated;
