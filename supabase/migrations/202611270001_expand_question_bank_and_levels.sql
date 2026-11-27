-- Expand the server-side question bank and add level-based session selection.
alter table public.class_question_bank
  add column if not exists difficulty text not null default 'beginner'
  check (difficulty in ('beginner','intermediate','advanced'));

alter table public.session_questions
  add column if not exists difficulty text not null default 'beginner'
  check (difficulty in ('beginner','intermediate','advanced'));

alter table public.sessions
  add column if not exists difficulty text not null default 'beginner'
  check (difficulty in ('beginner','intermediate','advanced','mixed'));

-- Students may read the difficulty label, but never the answer key.
grant select (difficulty) on public.session_questions to authenticated;

update public.class_question_bank set difficulty='beginner';

insert into public.class_question_bank
  (id,difficulty,category,prompt,options,correct_answer,explanation,midi)
values
-- BEGINNER: 20 questions total (the original 12 plus these 8).
(13,'beginner','Pentagrama','¿Qué nota se escribe en el primer espacio del pentagrama en clave de sol?','["Do4","Fa4","La4","Do5"]'::jsonb,'Fa4','En clave de sol, el primer espacio desde abajo corresponde a Fa4.',65),
(14,'beginner','Pentagrama','¿Qué nota se escribe en la segunda línea del pentagrama en clave de sol?','["Mi4","Sol4","Si4","Re5"]'::jsonb,'Sol4','Las líneas desde abajo son Mi4, Sol4, Si4, Re5 y Fa5.',67),
(15,'beginner','Pentagrama','¿Qué nota se escribe en el espacio inmediatamente encima de la primera línea?','["Fa4","Sol4","La4","Do5"]'::jsonb,'Fa4','El primer espacio del pentagrama es Fa4.',65),
(16,'beginner','Diapasón','¿Qué nota produce la primera cuerda al aire de la guitarra?','["Mi4","La3","Re3","Sol3"]'::jsonb,'Mi4','En afinación estándar, la primera cuerda al aire produce Mi4.',null),
(17,'beginner','Diapasón','¿Qué nota produce la sexta cuerda al aire?','["Mi2","La2","Re3","Sol2"]'::jsonb,'Mi2','La sexta cuerda al aire produce Mi2.',null),
(18,'beginner','Diapasón','Si avanzas un traste en la misma cuerda, ¿qué ocurre con la altura?','["Sube un semitono","Sube un tono","Baja un semitono","No cambia"]'::jsonb,'Sube un semitono','Cada traste consecutivo aumenta la altura un semitono.',null),
(19,'beginner','Ritmo','¿Cuántas corcheas equivalen a una blanca?','["Dos","Tres","Cuatro","Ocho"]'::jsonb,'Cuatro','Una blanca equivale a dos negras y cada negra a dos corcheas: cuatro corcheas.',null),
(20,'beginner','Ritmo','¿Qué indica el número superior de un compás de 4/4?','["Cuatro pulsos por compás","Cuatro compases","Cuatro silencios","Cuatro notas obligatorias"]'::jsonb,'Cuatro pulsos por compás','El numerador indica cuántas unidades de pulso contiene el compás.',null),

-- INTERMEDIATE: accidentals, key signatures, relative keys, minor scales, intervals and triads.
(21,'intermediate','Pentagrama','En un compás, aparece Fa♯ y después otro Fa sin signo. ¿Cómo se interpreta el segundo Fa?','["Fa sostenido","Fa natural","Fa bemol","Depende de la cuerda"]'::jsonb,'Fa sostenido','Una alteración accidental se mantiene para la misma nota y octava durante el compás.',null),
(22,'intermediate','Pentagrama','¿Qué función cumple el becuadro dentro de un compás?','["Cancela una alteración anterior","Sube la nota un tono","Baja la nota un semitono","Indica que la nota se repite"]'::jsonb,'Cancela una alteración anterior','El becuadro anula el sostenido o bemol que afectaba a esa nota en el compás.',null),
(23,'intermediate','Pentagrama','Si una nota alterada aparece después de la barra de compás, ¿qué ocurre?','["La alteración anterior sigue siempre","Se restablece la armadura","La nota se vuelve doble sostenido","La nota pierde su duración"]'::jsonb,'Se restablece la armadura','Las alteraciones accidentales dejan de aplicarse al cruzar la barra de compás.',null),
(24,'intermediate','Pentagrama','¿Cuántos sostenidos tiene la armadura de Re mayor?','["Uno","Dos","Tres","Cuatro"]'::jsonb,'Dos','Re mayor tiene Fa♯ y Do♯ en la armadura.',null),
(25,'intermediate','Pentagrama','¿Cuántos bemoles tiene la armadura de Si♭ mayor?','["Uno","Dos","Tres","Cuatro"]'::jsonb,'Dos','Si♭ mayor contiene Si♭ y Mi♭.',null),
(26,'intermediate','Pentagrama','¿Qué tonalidad mayor comparte armadura con La menor?','["Do mayor","Sol mayor","Fa mayor","Mi mayor"]'::jsonb,'Do mayor','La menor es la relativa menor de Do mayor; ambas tienen la misma armadura.',null),
(27,'intermediate','Armonía','¿Qué notas forman la escala de La menor natural?','["La–Si–Do–Re–Mi–Fa–Sol","La–Si–Do–Re–Mi–Fa♯–Sol♯","La–Si–Do♯–Re–Mi–Fa–Sol","La–Si♭–Do–Re–Mi–Fa–Sol"]'::jsonb,'La–Si–Do–Re–Mi–Fa–Sol','La menor natural utiliza los grados 1, 2, ♭3, 4, 5, ♭6 y ♭7.',null),
(28,'intermediate','Armonía','¿Qué nota se altera en La menor armónica respecto de La menor natural?','["Fa pasa a Fa♯","Sol pasa a Sol♯","Do pasa a Do♯","Si pasa a Si♭"]'::jsonb,'Sol pasa a Sol♯','La menor armónica eleva el séptimo grado: Sol♯ funciona como sensible de La.',null),
(29,'intermediate','Armonía','¿Cuántos semitonos contiene una tercera mayor?','["Dos","Tres","Cuatro","Cinco"]'::jsonb,'Cuatro','La tercera mayor abarca cuatro semitonos.',null),
(30,'intermediate','Armonía','¿Cuántos semitonos contiene una tercera menor?','["Dos","Tres","Cuatro","Cinco"]'::jsonb,'Tres','La tercera menor abarca tres semitonos.',null),
(31,'intermediate','Armonía','¿Qué intervalo hay entre Do y Sol?','["Tercera mayor","Cuarta justa","Quinta justa","Sexta mayor"]'::jsonb,'Quinta justa','Do–Sol es una quinta justa de siete semitonos.',null),
(32,'intermediate','Armonía','¿Qué intervalo tiene seis semitonos y puede escribirse como Do–Fa♯?','["Cuarta aumentada","Quinta justa","Tercera menor","Sexta menor"]'::jsonb,'Cuarta aumentada','Do–Fa♯ es una cuarta aumentada; comparte seis semitonos con la quinta disminuida.',null),
(33,'intermediate','Armonía','¿Qué notas forman una tríada mayor de Do?','["Do–Mi–Sol","Do–Mi♭–Sol","Do–Mi♭–Sol♭","Do–Mi–Sol♯"]'::jsonb,'Do–Mi–Sol','La tríada mayor contiene fundamental, tercera mayor y quinta justa.',null),
(34,'intermediate','Armonía','¿Qué notas forman una tríada menor de Do?','["Do–Mi–Sol","Do–Mi♭–Sol","Do–Mi–Sol♭","Do–Mi♭–Sol♭"]'::jsonb,'Do–Mi♭–Sol','La tríada menor contiene fundamental, tercera menor y quinta justa.',null),
(35,'intermediate','Armonía','¿Qué estructura de semitonos tiene una tríada disminuida?','["4 + 3","3 + 4","3 + 3","4 + 4"]'::jsonb,'3 + 3','La tríada disminuida se forma con dos terceras menores consecutivas.',null),
(36,'intermediate','Armonía','¿Qué estructura de semitonos tiene una tríada aumentada?','["3 + 3","3 + 4","4 + 4","4 + 3"]'::jsonb,'4 + 4','La tríada aumentada contiene dos terceras mayores consecutivas.',null),
(37,'intermediate','Armonía','En la primera inversión de Do mayor, ¿qué nota queda en el bajo?','["Do","Mi","Sol","Si"]'::jsonb,'Mi','La primera inversión coloca la tercera del acorde en el bajo: Mi.',null),
(38,'intermediate','Armonía','En la segunda inversión de Do mayor, ¿qué nota queda en el bajo?','["Do","Mi","Sol","La"]'::jsonb,'Sol','La segunda inversión coloca la quinta del acorde en el bajo: Sol.',null),
(39,'intermediate','Ritmo','En un compás de 6/8, ¿cuántas corcheas completan el compás?','["Tres","Cuatro","Seis","Ocho"]'::jsonb,'Seis','El 6/8 contiene seis unidades de corchea, agrupadas habitualmente en dos pulsos compuestos.',null),
(40,'intermediate','Ritmo','¿Qué figura equivale a tres corcheas?','["Negra con puntillo","Blanca","Redonda","Negra"]'::jsonb,'Negra con puntillo','El puntillo añade la mitad del valor: negra más corchea equivale a tres corcheas.',null),

-- ADVANCED: key signatures, minor modes, interval spelling and chord inversions/functions.
(41,'advanced','Pentagrama','¿Qué tonalidad mayor tiene siete sostenidos en la armadura?','["Fa♯ mayor","Do♯ mayor","Si mayor","Mi mayor"]'::jsonb,'Do♯ mayor','Do♯ mayor utiliza los siete sostenidos: Fa, Do, Sol, Re, La, Mi y Si.',null),
(42,'advanced','Pentagrama','¿Qué tonalidad mayor tiene seis bemoles en la armadura?','["Re♭ mayor","Sol♭ mayor","Do♭ mayor","La♭ mayor"]'::jsonb,'Sol♭ mayor','Sol♭ mayor tiene seis bemoles: Si, Mi, La, Re, Sol y Do.',null),
(43,'advanced','Pentagrama','¿Cuál es el último sostenido de la armadura de Mi mayor?','["Fa♯","Do♯","Sol♯","Re♯"]'::jsonb,'Re♯','El orden de sostenidos es Fa–Do–Sol–Re–La–Mi–Si; Mi mayor contiene los cuatro primeros.',null),
(44,'advanced','Pentagrama','¿Cuál es el penúltimo bemol de la armadura de Re♭ mayor?','["Si♭","Mi♭","La♭","Re♭"]'::jsonb,'La♭','El orden de bemoles es Si–Mi–La–Re–Sol–Do–Fa; el penúltimo de Re♭ mayor es La♭.',null),
(45,'advanced','Armonía','En la escala menor melódica clásica ascendente, ¿qué grados se elevan respecto de la menor natural?','["6.º y 7.º","3.º y 6.º","4.º y 7.º","2.º y 5.º"]'::jsonb,'6.º y 7.º','La menor melódica ascendente eleva el sexto y el séptimo grado; al descender, la forma clásica vuelve a la natural.',null),
(46,'advanced','Armonía','¿Qué intervalo se forma entre Fa y Sol♯?','["Segunda aumentada","Tercera menor","Segunda mayor","Tercera mayor"]'::jsonb,'Segunda aumentada','Fa–Sol♯ abarca dos nombres de nota y tres semitonos: es una segunda aumentada.',null),
(47,'advanced','Armonía','¿Cuál es la sensible de La menor armónica?','["Fa♯","Sol♯","Si♭","Do♯"]'::jsonb,'Sol♯','El séptimo grado elevado de La menor armónica es Sol♯ y resuelve hacia La.',null),
(48,'advanced','Armonía','¿Qué intervalo enarmónico comparte seis semitonos con la cuarta aumentada?','["Quinta disminuida","Quinta justa","Cuarta justa","Sexta menor"]'::jsonb,'Quinta disminuida','La cuarta aumentada y la quinta disminuida tienen seis semitonos, pero distinta escritura interválica.',null),
(49,'advanced','Armonía','¿Qué notas forman la tríada disminuida de Do?','["Do–Mi–Sol","Do–Mi♭–Sol","Do–Mi♭–Sol♭","Do–Mi–Sol♯"]'::jsonb,'Do–Mi♭–Sol♭','La tríada disminuida contiene fundamental, tercera menor y quinta disminuida.',null),
(50,'advanced','Armonía','¿Qué notas forman la tríada aumentada de Do?','["Do–Mi–Sol♯","Do–Mi♭–Sol","Do–Mi–Sol","Do–Mi♭–Sol♭"]'::jsonb,'Do–Mi–Sol♯','La tríada aumentada contiene fundamental, tercera mayor y quinta aumentada.',null),
(51,'advanced','Armonía','¿Qué inversión de una tríada coloca la quinta en el bajo?','["Estado fundamental","Primera inversión","Segunda inversión","Tercera inversión"]'::jsonb,'Segunda inversión','En una tríada, la segunda inversión coloca la quinta del acorde en el bajo.',null),
(52,'advanced','Armonía','En un acorde de séptima de dominante en Do mayor, ¿qué acorde cumple la función dominante?','["Fa–La–Do–Mi","Sol–Si–Re–Fa","Do–Mi–Sol–Si","La–Do–Mi–Sol"]'::jsonb,'Sol–Si–Re–Fa','El acorde V7 de Do mayor es Sol–Si–Re–Fa y resuelve normalmente hacia Do.',null),
(53,'advanced','Armonía','¿Qué grado de la escala mayor forma la tríada disminuida diatónica?','["I","II","V","VII"]'::jsonb,'VII','En una escala mayor, la tríada sobre el séptimo grado es disminuida.',null),
(54,'advanced','Armonía','¿Qué cualidad tiene el acorde construido sobre el segundo grado de una escala mayor?','["Mayor","Menor","Disminuido","Aumentado"]'::jsonb,'Menor','La tríada diatónica sobre el segundo grado de una escala mayor es menor.',null),
(55,'advanced','Armonía','¿Qué cualidad tiene el acorde construido sobre el quinto grado de una escala mayor?','["Mayor","Menor","Disminuido","Aumentado"]'::jsonb,'Mayor','La tríada sobre el quinto grado de una escala mayor es mayor; con séptima menor forma V7.',null),
(56,'advanced','Armonía','¿Qué notas forman el acorde de séptima de dominante de Sol?','["Sol–Si–Re–Fa","Sol–Si♭–Re–Fa","Sol–Si–Re–Fa♯","Sol–Si–Re♭–Fa"]'::jsonb,'Sol–Si–Re–Fa','Un acorde de séptima de dominante contiene fundamental, tercera mayor, quinta justa y séptima menor.',null),
(57,'advanced','Armonía','¿Cuál es la relativa menor de Mi♭ mayor?','["Do menor","Sol menor","La menor","Fa menor"]'::jsonb,'Do menor','La relativa menor se encuentra una tercera menor por debajo de la tónica mayor; Mi♭ mayor y Do menor comparten armadura.',null),
(58,'advanced','Armonía','¿Qué escala menor eleva el séptimo grado para crear una sensible, pero conserva el sexto grado natural?','["Menor natural","Menor armónica","Menor melódica ascendente","Mayor"]'::jsonb,'Menor armónica','La menor armónica eleva el séptimo grado y mantiene el sexto grado de la menor natural.',null),
(59,'advanced','Diapasón','¿Qué nota real produce la segunda cuerda en el traste 1?','["Do4","Do♯4","Re4","Si3"]'::jsonb,'Do4','La segunda cuerda al aire es Si3; el primer traste sube un semitono a Do4.',null),
(60,'advanced','Diapasón','¿Qué nota real produce la primera cuerda en el traste 8?','["Do5","Do4","La4","Si4"]'::jsonb,'Do5','La primera cuerda al aire es Mi4; el octavo traste produce Do5.',null)
on conflict (id) do update set
  difficulty=excluded.difficulty,category=excluded.category,prompt=excluded.prompt,
  options=excluded.options,correct_answer=excluded.correct_answer,
  explanation=excluded.explanation,midi=excluded.midi;

drop function if exists public.create_class_session(text,text,integer);
create function public.create_class_session(
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

  loop
    v_code := upper(substr(replace(pg_catalog.gen_random_uuid()::text,'-',''),1,6));
    exit when not exists(select 1 from public.sessions where code=v_code);
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
  select * into v_session from public.sessions where code=upper(trim(p_code));
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
      'question_count',v_session.question_count,'difficulty',v_session.difficulty
    ),
    'participant_id',v_p.id,'score',v_p.score
  );
end
$$;

revoke all on function public.join_class_session(text,text) from public, anon;
grant execute on function public.join_class_session(text,text) to authenticated;
