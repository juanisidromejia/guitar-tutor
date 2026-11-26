-- Students receive only an acknowledgement, never correctness, points, or explanations.
create or replace function public.submit_class_answer(
  p_session_id uuid,
  p_question_id uuid,
  p_answer text
)
returns jsonb
language plpgsql
security definer
set search_path=public
as $$
declare
  v_p public.participants;
  v_s public.sessions;
  v_q public.session_questions;
  v_ok boolean;
  v_pts integer;
begin
  select * into v_p
  from public.participants
  where session_id=p_session_id and user_id=auth.uid()
  for update;

  if not found then raise exception 'No perteneces a esta sesión.'; end if;

  select * into v_s from public.sessions where id=p_session_id;
  if v_s.status<>'active' then raise exception 'La sesión no está aceptando respuestas.'; end if;

  select * into v_q
  from public.session_questions
  where id=p_question_id and session_id=p_session_id;
  if not found then raise exception 'Pregunta no válida.'; end if;

  if v_s.mode='live' and v_q.position<>v_s.current_question_index then
    raise exception 'Esta pregunta no está abierta actualmente.';
  end if;

  if exists(
    select 1 from public.session_answers
    where participant_id=v_p.id and question_id=p_question_id
  ) then raise exception 'Ya respondiste esta pregunta.'; end if;

  if not exists(
    select 1 from jsonb_array_elements_text(v_q.options) as opts(value)
    where value=p_answer
  ) then raise exception 'La opción seleccionada no es válida.'; end if;

  v_ok:=p_answer=v_q.correct_answer;
  v_pts:=case when v_ok then 1000 else 0 end;

  insert into public.session_answers(
    session_id,participant_id,question_id,selected_answer,is_correct,points
  ) values(p_session_id,v_p.id,p_question_id,p_answer,v_ok,v_pts);

  update public.participants set score=score+v_pts where id=v_p.id;

  return jsonb_build_object('accepted',true);
end
$$;

-- Preserve the existing authenticated execution grant while preventing public execution.
revoke all on function public.submit_class_answer(uuid,uuid,text) from public, anon;
grant execute on function public.submit_class_answer(uuid,uuid,text) to authenticated;

-- Students must not be able to inspect their own correctness rows through REST.
drop policy if exists "answers visible to owner and self" on public.session_answers;
create policy "answers visible to owner only"
on public.session_answers for select to authenticated
using (public.is_class_owner(session_id));

-- Explanations can disclose the correct option, so they are not student-readable.
revoke select (explanation) on public.session_questions from authenticated;
