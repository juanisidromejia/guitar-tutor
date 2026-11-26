-- Explicit API grants for the classroom feature. Row/column policies remain the access boundary.
grant select, update on public.sessions to authenticated;
grant select on public.participants, public.session_answers to authenticated;
-- Student-visible question columns only; never grant correct_answer.
revoke select on public.session_questions from anon, authenticated;
grant select(id,session_id,position,category,prompt,options,explanation,midi) on public.session_questions to authenticated;
