-- Keep the classroom answer key entirely on the server.
create table if not exists public.class_question_bank (
 id integer primary key,
 category text not null,
 prompt text not null,
 options jsonb not null check(jsonb_typeof(options)='array'),
 correct_answer text not null,
 explanation text not null default '',
 midi integer
);
alter table public.class_question_bank enable row level security;
revoke all on public.class_question_bank from anon, authenticated;

insert into public.class_question_bank(id,category,prompt,options,correct_answer,explanation,midi) values
(1,'Pentagrama','¿Qué nota aparece en el pentagrama?','["Do4","Mi4","Sol4","La4"]'::jsonb,'Mi4','Mi4 se escribe en la primera línea. En guitarra suena una octava más grave.',64),
(2,'Pentagrama','¿Qué nota aparece en el pentagrama?','["Re4","Fa4","Sol4","Si4"]'::jsonb,'Sol4','Sol4 se escribe en la segunda línea. En guitarra suena una octava más grave.',67),
(3,'Pentagrama','¿Qué nota aparece en el pentagrama?','["Do4","Re4","Mi4","Fa4"]'::jsonb,'Do4','Do4 se escribe en la línea adicional inferior. En guitarra suena una octava más grave: Do3.',60),
(4,'Pentagrama','¿Qué nota aparece en el pentagrama?','["Do5","Re5","Fa5","Sol5"]'::jsonb,'Do5','Do5 está en el tercer espacio. En guitarra suena una octava más grave: Do4.',72),
(5,'Diapasón','¿En qué posición encuentras la nota Sol4?','["1.ª cuerda, traste 3","2.ª cuerda, traste 8","3.ª cuerda, traste 12","4.ª cuerda, traste 5"]'::jsonb,'1.ª cuerda, traste 3','La primera cuerda, traste 3, produce Sol4 real.',null),
(6,'Diapasón','¿Dónde se encuentra la nota La3?','["3.ª cuerda, traste 2","4.ª cuerda, traste 7","5.ª cuerda, traste 0","6.ª cuerda, traste 5"]'::jsonb,'3.ª cuerda, traste 2','La tercera cuerda al aire produce Sol3; el segundo traste produce La3.',null),
(7,'Diapasón','¿Qué nota suena en la segunda cuerda al aire?','["Mi4","Si3","Sol3","Re4"]'::jsonb,'Si3','En afinación estándar, la segunda cuerda al aire produce Si3 real.',null),
(8,'Diapasón','¿Qué nota obtienes en la quinta cuerda, traste 3?','["Do3","Re3","Mi3","Fa3"]'::jsonb,'Do3','La quinta cuerda al aire produce La2; en el tercer traste encontramos Do3.',null),
(9,'Ritmo','¿Cuántas negras equivalen a una redonda?','["Dos","Tres","Cuatro","Ocho"]'::jsonb,'Cuatro','La redonda equivale a cuatro negras.',null),
(10,'Ritmo','¿Cuántas corcheas equivalen a una negra?','["Una","Dos","Tres","Cuatro"]'::jsonb,'Dos','Dos corcheas tienen la misma duración que una negra.',null),
(11,'Ritmo','¿Qué debes hacer durante un silencio de negra?','["Detener el pulso","Mantener el pulso sin sonar","Tocar una corchea","Acelerar"]'::jsonb,'Mantener el pulso sin sonar','El silencio ocupa el tiempo de una negra, pero no produce sonido.',null),
(12,'Ritmo','En un compás de 3/4, ¿cuántas negras completan el compás?','["Dos","Tres","Cuatro","Seis"]'::jsonb,'Tres','En 3/4 hay tres pulsos de negra por compás.',null)
on conflict(id) do update set category=excluded.category,prompt=excluded.prompt,options=excluded.options,correct_answer=excluded.correct_answer,explanation=excluded.explanation,midi=excluded.midi;

drop function if exists public.create_class_session(text,text,jsonb);
create or replace function public.create_class_session(p_title text,p_mode text)
returns jsonb language plpgsql security definer set search_path=public
as $$
declare
 v_uid uuid:=auth.uid();
 v_session public.sessions;
 v_code text;
begin
 if v_uid is null or coalesce((auth.jwt()->>'is_anonymous')::boolean,false) then
  raise exception 'Debes iniciar sesión como docente.';
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
revoke all on function public.create_class_session(text,text) from public;
grant execute on function public.create_class_session(text,text) to authenticated;
