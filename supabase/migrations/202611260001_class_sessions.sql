create extension if not exists pgcrypto;
create table if not exists public.sessions (
 id uuid primary key default gen_random_uuid(), owner_id uuid not null references auth.users(id) on delete cascade,
 code text not null unique, title text not null check(char_length(title) between 1 and 90),
 mode text not null check(mode in ('self_paced','live')), status text not null default 'lobby' check(status in ('lobby','active','finished')),
 current_question_index integer not null default 0, created_at timestamptz not null default now(), updated_at timestamptz not null default now()
);
create table if not exists public.session_questions (
 id uuid primary key default gen_random_uuid(), session_id uuid not null references public.sessions(id) on delete cascade,
 position integer not null check(position>=0), category text not null, prompt text not null, options jsonb not null check(jsonb_typeof(options)='array'),
 correct_answer text not null, explanation text not null default '', midi integer, unique(session_id,position)
);
create table if not exists public.participants (
 id uuid primary key default gen_random_uuid(), session_id uuid not null references public.sessions(id) on delete cascade,
 user_id uuid not null references auth.users(id) on delete cascade, nickname text not null check(char_length(nickname) between 1 and 24),
 score integer not null default 0, joined_at timestamptz not null default now(), finished_at timestamptz, unique(session_id,user_id)
);
create table if not exists public.session_answers (
 id uuid primary key default gen_random_uuid(), session_id uuid not null references public.sessions(id) on delete cascade,
 participant_id uuid not null references public.participants(id) on delete cascade, question_id uuid not null references public.session_questions(id) on delete cascade,
 selected_answer text not null, is_correct boolean not null, points integer not null default 0, answered_at timestamptz not null default now(),
 unique(participant_id,question_id)
);
create index if not exists participants_session_idx on public.participants(session_id);
create index if not exists session_answers_session_idx on public.session_answers(session_id);

create or replace function public.is_class_owner(p_session_id uuid)
returns boolean language sql stable security definer set search_path=public
as $$ select exists(select 1 from public.sessions where id=p_session_id and owner_id=auth.uid()) $$;
create or replace function public.is_class_participant(p_session_id uuid)
returns boolean language sql stable security definer set search_path=public
as $$ select exists(select 1 from public.participants where session_id=p_session_id and user_id=auth.uid()) $$;

alter table public.sessions enable row level security;
alter table public.session_questions enable row level security;
alter table public.participants enable row level security;
alter table public.session_answers enable row level security;

drop policy if exists "class sessions visible to owner and joined students" on public.sessions;
create policy "class sessions visible to owner and joined students" on public.sessions for select to authenticated
using(owner_id=auth.uid() or public.is_class_participant(id));
drop policy if exists "owners update class sessions" on public.sessions;
create policy "owners update class sessions" on public.sessions for update to authenticated using(owner_id=auth.uid()) with check(owner_id=auth.uid());
drop policy if exists "questions visible to owner and joined students" on public.session_questions;
create policy "questions visible to owner and joined students" on public.session_questions for select to authenticated
using(public.is_class_owner(session_id) or public.is_class_participant(session_id));
drop policy if exists "participants visible to owner and self" on public.participants;
create policy "participants visible to owner and self" on public.participants for select to authenticated
using(user_id=auth.uid() or public.is_class_owner(session_id));
drop policy if exists "answers visible to owner and self" on public.session_answers;
create policy "answers visible to owner and self" on public.session_answers for select to authenticated
using(public.is_class_owner(session_id) or exists(select 1 from public.participants p where p.id=participant_id and p.user_id=auth.uid()));

-- Column-level grants keep the answer key out of every browser query, including direct REST requests.
revoke select on public.session_questions from anon, authenticated;
grant select(id,session_id,position,category,prompt,options,explanation,midi) on public.session_questions to authenticated;

create or replace function public.create_class_session(p_title text,p_mode text,p_questions jsonb)
returns jsonb language plpgsql security definer set search_path=public
as $$
declare v_uid uuid:=auth.uid(); v_session public.sessions; v_code text; v_q jsonb; v_pos integer:=0;
begin
 if v_uid is null or coalesce((auth.jwt()->>'is_anonymous')::boolean,false) then raise exception 'Debes iniciar sesión como docente.'; end if;
 if p_mode not in ('self_paced','live') then raise exception 'Modalidad no válida.'; end if;
 if jsonb_typeof(p_questions)<>'array' or jsonb_array_length(p_questions)<1 or jsonb_array_length(p_questions)>100 then raise exception 'El cuestionario debe tener entre 1 y 100 preguntas.'; end if;
 loop v_code:=upper(substr(encode(gen_random_bytes(5),'hex'),1,6)); exit when not exists(select 1 from public.sessions where code=v_code); end loop;
 insert into public.sessions(owner_id,code,title,mode) values(v_uid,v_code,left(trim(p_title),90),p_mode) returning * into v_session;
 for v_q in select value from jsonb_array_elements(p_questions) loop
  if not(v_q ? 'prompt' and v_q ? 'options' and v_q ? 'correct_answer') then raise exception 'Una pregunta no contiene los campos necesarios.'; end if;
  insert into public.session_questions(session_id,position,category,prompt,options,correct_answer,explanation,midi)
  values(v_session.id,v_pos,coalesce(v_q->>'category','General'),v_q->>'prompt',v_q->'options',v_q->>'correct_answer',coalesce(v_q->>'explanation',''),nullif(v_q->>'midi','')::integer);
  v_pos:=v_pos+1;
 end loop;
 return jsonb_build_object('id',v_session.id,'code',v_session.code,'title',v_session.title,'mode',v_session.mode,'status',v_session.status,'created_at',v_session.created_at);
end $$;

create or replace function public.join_class_session(p_code text,p_nickname text)
returns jsonb language plpgsql security definer set search_path=public
as $$
declare v_uid uuid:=auth.uid(); v_session public.sessions; v_p public.participants;
begin
 if v_uid is null then raise exception 'No se pudo identificar al participante.'; end if;
 if char_length(trim(p_nickname))<1 or char_length(trim(p_nickname))>24 then raise exception 'El nickname debe tener entre 1 y 24 caracteres.'; end if;
 select * into v_session from public.sessions where code=upper(trim(p_code));
 if not found then raise exception 'No existe una sesión con ese código.'; end if;
 if v_session.status='finished' then raise exception 'Esta sesión ya finalizó.'; end if;
 insert into public.participants(session_id,user_id,nickname) values(v_session.id,v_uid,trim(p_nickname))
 on conflict(session_id,user_id) do update set nickname=excluded.nickname returning * into v_p;
 return jsonb_build_object('session',jsonb_build_object('id',v_session.id,'code',v_session.code,'title',v_session.title,'mode',v_session.mode,'status',v_session.status,'current_question_index',v_session.current_question_index),'participant_id',v_p.id,'score',v_p.score);
end $$;

create or replace function public.submit_class_answer(p_session_id uuid,p_question_id uuid,p_answer text)
returns jsonb language plpgsql security definer set search_path=public
as $$
declare v_p public.participants; v_s public.sessions; v_q public.session_questions; v_ok boolean; v_pts integer;
begin
 select * into v_p from public.participants where session_id=p_session_id and user_id=auth.uid() for update;
 if not found then raise exception 'No perteneces a esta sesión.'; end if;
 select * into v_s from public.sessions where id=p_session_id;
 if v_s.status<>'active' then raise exception 'La sesión no está aceptando respuestas.'; end if;
 select * into v_q from public.session_questions where id=p_question_id and session_id=p_session_id;
 if not found then raise exception 'Pregunta no válida.'; end if;
 if v_s.mode='live' and v_q.position<>v_s.current_question_index then raise exception 'Esta pregunta no está abierta actualmente.'; end if;
 if exists(select 1 from public.session_answers where participant_id=v_p.id and question_id=p_question_id) then raise exception 'Ya respondiste esta pregunta.'; end if;
 if not exists(select 1 from jsonb_array_elements_text(v_q.options) as opts(value) where value=p_answer) then raise exception 'La opción seleccionada no es válida.'; end if;
 v_ok:=p_answer=v_q.correct_answer; v_pts:=case when v_ok then 1000 else 0 end;
 insert into public.session_answers(session_id,participant_id,question_id,selected_answer,is_correct,points) values(p_session_id,v_p.id,p_question_id,p_answer,v_ok,v_pts);
 update public.participants set score=score+v_pts where id=v_p.id;
 return jsonb_build_object('correct',v_ok,'points',v_pts,'explanation',v_q.explanation);
end $$;

create or replace function public.start_class_session(p_session_id uuid)
returns void language plpgsql security definer set search_path=public
as $$ begin
 update public.sessions set status='active',current_question_index=0,updated_at=now() where id=p_session_id and owner_id=auth.uid() and status='lobby';
 if not found then raise exception 'No puedes iniciar esta sesión o ya fue iniciada.'; end if;
end $$;
create or replace function public.advance_class_session(p_session_id uuid)
returns void language plpgsql security definer set search_path=public
as $$
declare v_idx integer; v_total integer;
begin
 select current_question_index into v_idx from public.sessions where id=p_session_id and owner_id=auth.uid() and status='active' for update;
 if not found then raise exception 'La sesión no está activa o no te pertenece.'; end if;
 select count(*) into v_total from public.session_questions where session_id=p_session_id;
 if v_idx+1>=v_total then
  update public.sessions set status='finished',updated_at=now() where id=p_session_id;
  update public.participants set finished_at=coalesce(finished_at,now()) where session_id=p_session_id;
 else update public.sessions set current_question_index=v_idx+1,updated_at=now() where id=p_session_id; end if;
end $$;
create or replace function public.finish_class_session(p_session_id uuid)
returns void language plpgsql security definer set search_path=public
as $$ begin
 update public.sessions set status='finished',updated_at=now() where id=p_session_id and owner_id=auth.uid();
 if not found then raise exception 'La sesión no existe o no te pertenece.'; end if;
 update public.participants set finished_at=coalesce(finished_at,now()) where session_id=p_session_id;
end $$;
create or replace function public.finish_self_paced_session(p_session_id uuid)
returns void language plpgsql security definer set search_path=public
as $$ begin
 update public.participants set finished_at=coalesce(finished_at,now()) where session_id=p_session_id and user_id=auth.uid();
 if not found then raise exception 'No perteneces a esta sesión.'; end if;
end $$;

revoke all on function public.create_class_session(text,text,jsonb) from public;
revoke all on function public.join_class_session(text,text) from public;
revoke all on function public.submit_class_answer(uuid,uuid,text) from public;
revoke all on function public.start_class_session(uuid) from public;
revoke all on function public.advance_class_session(uuid) from public;
revoke all on function public.finish_class_session(uuid) from public;
revoke all on function public.finish_self_paced_session(uuid) from public;
grant execute on function public.create_class_session(text,text,jsonb) to authenticated;
grant execute on function public.join_class_session(text,text) to authenticated;
grant execute on function public.submit_class_answer(uuid,uuid,text) to authenticated;
grant execute on function public.start_class_session(uuid) to authenticated;
grant execute on function public.advance_class_session(uuid) to authenticated;
grant execute on function public.finish_class_session(uuid) to authenticated;
grant execute on function public.finish_self_paced_session(uuid) to authenticated;

do $$ begin alter publication supabase_realtime add table public.sessions; exception when duplicate_object then null; end $$;
do $$ begin alter publication supabase_realtime add table public.participants; exception when duplicate_object then null; end $$;
