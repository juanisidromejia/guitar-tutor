-- Per-room preparation for Catacumbas: automatic enemies, difficulty boost and trap rooms.
alter table public.adventure_games
  add column if not exists room_config jsonb not null default
  '[{"enemies":0,"difficulty_offset":0,"trap":false},{"enemies":0,"difficulty_offset":0,"trap":false},{"enemies":0,"difficulty_offset":0,"trap":false},{"enemies":0,"difficulty_offset":0,"trap":false},{"enemies":0,"difficulty_offset":0,"trap":false}]'::jsonb;

alter table public.adventure_rooms drop constraint if exists adventure_rooms_room_type_check;
alter table public.adventure_rooms add constraint adventure_rooms_room_type_check
  check(room_type in ('puzzle','trap','treasure'));

-- Include the room hazard in the challenge payload so the player UI can explain it.
create or replace function public.adventure_get_challenge(p_challenge_id uuid)
returns jsonb
language sql stable security definer set search_path=public
as $$
 select jsonb_build_object(
  'challenge_id',c.id,'room_index',c.room_index,'room_title',r.title,
  'room_description',r.description,'room_type',r.room_type,
  'challenge_type',c.challenge_type,'prompt',c.prompt,'options',c.options
 )
 from public.adventure_challenges c
 join public.adventure_rooms r on r.game_id=c.game_id and r.room_index=c.room_index
 where c.id=p_challenge_id
$$;

drop function if exists public.create_class_adventure_session(text,text);
create or replace function public.create_class_adventure_session(
 p_title text,
 p_difficulty text,
 p_room_config jsonb default null
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
 v_config jsonb;
 v_room jsonb;
 v_room_index integer;
 v_enemy_count integer;
 v_offset integer;
 v_trap boolean;
 v_base_difficulty text;
 v_enemy_difficulty text;
 v_enemy_type text;
 v_enemy_name text;
 v_weakness text;
 v_hp integer;
 v_challenge_id uuid;
 v_enemy_number integer;
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

 v_config:=coalesce(p_room_config,
 '[{"enemies":0,"difficulty_offset":0,"trap":false},{"enemies":0,"difficulty_offset":0,"trap":false},{"enemies":0,"difficulty_offset":0,"trap":false},{"enemies":0,"difficulty_offset":0,"trap":false},{"enemies":0,"difficulty_offset":0,"trap":false}]'::jsonb);
 if jsonb_typeof(v_config)<>'array' or jsonb_array_length(v_config)<>5 then
  raise exception 'La configuración debe incluir exactamente cinco salas.';
 end if;

 v_game:=public.create_adventure_game(trim(p_title),p_difficulty);
 v_game_id:=(v_game->>'id')::uuid;
 v_code:=v_game->>'code';
 v_base_difficulty:=case p_difficulty when 'beginner' then 'beginner' when 'advanced' then 'advanced' else 'intermediate' end;

 for v_room_index in 0..4 loop
  v_room:=v_config->v_room_index;
  if jsonb_typeof(v_room)<>'object' then raise exception 'Configuración no válida en sala %.',v_room_index+1; end if;
  v_enemy_count:=coalesce((v_room->>'enemies')::integer,0);
  v_offset:=coalesce((v_room->>'difficulty_offset')::integer,0);
  v_trap:=coalesce((v_room->>'trap')::boolean,false);
  if v_enemy_count<0 or v_enemy_count>3 then raise exception 'Cada sala admite entre cero y tres enemigos.'; end if;
  if v_offset not in (0,1) then raise exception 'El incremento de dificultad debe ser 0 o 1.'; end if;

  if v_trap then
   update public.adventure_rooms
   set room_type='trap',description=description||' ¡Cuidado! Esta sala contiene una trampa: una respuesta incorrecta puede costarte una vida.'
   where game_id=v_game_id and room_index=v_room_index;
   update public.adventure_challenges set challenge_type='trap'
   where game_id=v_game_id and room_index=v_room_index;
  end if;

  for v_enemy_number in 1..v_enemy_count loop
   if p_difficulty='mixed' and v_offset=0 then
    v_enemy_difficulty:=(array['beginner','intermediate','advanced'])[1+floor(random()*3)::integer];
   elsif v_offset=1 and v_base_difficulty='beginner' then
    v_enemy_difficulty:='intermediate';
   elsif v_offset=1 and v_base_difficulty='intermediate' then
    v_enemy_difficulty:='advanced';
   else
    v_enemy_difficulty:=v_base_difficulty;
   end if;

   if v_enemy_difficulty='beginner' then
    v_enemy_type:='skeleton';v_enemy_name:='Esqueleto del pentagrama';v_weakness:='Reconocimiento de notas y figuras musicales';v_hp:=2;
   elsif v_enemy_difficulty='intermediate' then
    v_enemy_type:='specter';v_enemy_name:='Espectro armónico';v_weakness:='Intervalos, escalas y acordes';v_hp:=3;
   else
    v_enemy_type:='dragon';v_enemy_name:='Dragón cromático';v_weakness:='Armonía, análisis y aplicación musical';v_hp:=4;
   end if;

   select c.id into v_challenge_id
   from public.adventure_challenges c
   where c.game_id=v_game_id and c.room_index=v_room_index and c.difficulty=v_enemy_difficulty
    and not exists(select 1 from public.adventure_enemies e
     where e.game_id=v_game_id and e.room_index=v_room_index and e.status='active' and e.challenge_id=c.id)
   order by random() limit 1;
   if v_challenge_id is null then
    select c.id into v_challenge_id from public.adventure_challenges c
    where c.game_id=v_game_id and c.room_index=v_room_index and c.difficulty=v_enemy_difficulty
    order by random() limit 1;
   end if;
   if v_challenge_id is null then
    raise exception 'No hay preguntas de nivel % para la sala %.',v_enemy_difficulty,v_room_index+1;
   end if;

   insert into public.adventure_enemies(
    game_id,room_index,name,weakness,health,max_health,enemy_type,difficulty,challenge_id
   ) values(v_game_id,v_room_index,v_enemy_name,v_weakness,v_hp,v_hp,v_enemy_type,v_enemy_difficulty,v_challenge_id);
   insert into public.adventure_events(game_id,event_type,message,payload)
   values(v_game_id,'enemy_summoned',
    '¡'||v_enemy_name||' ha aparecido en la sala '||(v_room_index+1)||'! Nivel: '||v_enemy_difficulty||'.',
    jsonb_build_object('room_index',v_room_index,'enemy_type',v_enemy_type,'difficulty',v_enemy_difficulty,'automatic',true));
  end loop;
 end loop;

 update public.adventure_games set room_config=v_config where id=v_game_id;

 if exists(select 1 from public.sessions where code=v_code) then
  loop
   v_code:=upper(substr(replace(gen_random_uuid()::text,'-',''),1,6));
   exit when not exists(select 1 from public.sessions where code=v_code)
     and not exists(select 1 from public.adventure_games where code=v_code and id<>v_game_id);
  end loop;
  update public.adventure_games set code=v_code where id=v_game_id;
 end if;

 insert into public.sessions(owner_id,code,title,mode,question_count,difficulty,activity_type,adventure_game_id)
 values(auth.uid(),v_code,trim(p_title),'live',1,p_difficulty,'adventure',v_game_id)
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

revoke all on function public.create_class_adventure_session(text,text,jsonb) from public,anon;
grant execute on function public.create_class_adventure_session(text,text,jsonb) to authenticated;


-- Resolve the actual question level for a room. Mixed keeps its mixed pool unless +1
-- is selected, in which case the room uses advanced questions.
create or replace function public.adventure_room_difficulty(p_game_id uuid,p_room_index integer)
returns text
language sql stable security definer set search_path=public
as $$
 select case
  when g.difficulty='mixed' and coalesce((g.room_config->p_room_index->>'difficulty_offset')::integer,0)=0 then 'mixed'
  when g.difficulty='mixed' then 'advanced'
  when coalesce((g.room_config->p_room_index->>'difficulty_offset')::integer,0)=1 and g.difficulty='beginner' then 'intermediate'
  when coalesce((g.room_config->p_room_index->>'difficulty_offset')::integer,0)=1 and g.difficulty='intermediate' then 'advanced'
  else g.difficulty
 end
 from public.adventure_games g where g.id=p_game_id
$$;

-- New players receive a question at the configured difficulty of the first room.
create or replace function public.join_adventure_game(p_code text,p_nickname text)
returns jsonb language plpgsql security definer set search_path=public
as $$
declare
 v_game public.adventure_games; v_player public.adventure_players;
 v_challenge public.adventure_challenges; v_base text; v_candidate text;
 v_suffix integer:=1; v_suffix_text text; v_is_new boolean;
begin
 if auth.uid() is null then raise exception 'No se pudo identificar al aventurero.'; end if;
 if char_length(trim(p_nickname))<1 or char_length(trim(p_nickname))>24 then raise exception 'El nombre debe tener entre 1 y 24 caracteres.'; end if;
 select * into v_game from public.adventure_games where code=upper(trim(p_code)) for update;
 if not found or v_game.status='finished' then raise exception 'La partida no existe o ya terminó.'; end if;
 select * into v_player from public.adventure_players where game_id=v_game.id and user_id=auth.uid();
 v_is_new:=not found;
 v_base:=trim(p_nickname);v_candidate:=left(v_base,24);
 loop
  if not exists(select 1 from public.adventure_players p where p.game_id=v_game.id and lower(p.nickname)=lower(v_candidate) and (v_player.id is null or p.id<>v_player.id)) then exit; end if;
  v_suffix:=v_suffix+1;v_suffix_text:=' '||v_suffix::text;v_candidate:=left(v_base,24-char_length(v_suffix_text))||v_suffix_text;
 end loop;
 if v_is_new then
  select * into v_challenge from public.adventure_challenges
  where game_id=v_game.id and room_index=0
   and (public.adventure_room_difficulty(v_game.id,0)='mixed' or difficulty=public.adventure_room_difficulty(v_game.id,0))
  order by random() limit 1;
  if v_challenge.id is null then raise exception 'No hay preguntas disponibles para iniciar esta aventura.'; end if;
  insert into public.adventure_players(game_id,user_id,nickname,challenge_id)
  values(v_game.id,auth.uid(),v_candidate,v_challenge.id) returning * into v_player;
  insert into public.adventure_events(game_id,actor_player_id,event_type,message)
  values(v_game.id,v_player.id,'player_joined',v_player.nickname||' se ha unido a la expedición.');
 else
  if v_game.status='active' and v_player.last_seen_at<now()-interval '3 minutes' then
   update public.adventure_players set eliminated=true,errors=3,last_seen_at=now(),disconnected_at=now()
   where id=v_player.id returning * into v_player;
   insert into public.adventure_events(game_id,actor_player_id,event_type,message)
   values(v_game.id,v_player.id,'reconnect_expired',v_player.nickname||' perdió la conexión durante más de tres minutos y quedó fuera de la expedición.');
  else
   update public.adventure_players set nickname=v_candidate,last_seen_at=now(),disconnected_at=null
   where id=v_player.id returning * into v_player;
  end if;
  select * into v_challenge from public.adventure_challenges where id=v_player.challenge_id;
 end if;
 return jsonb_build_object(
  'game',jsonb_build_object('id',v_game.id,'code',v_game.code,'title',v_game.title,'status',v_game.status,'difficulty',v_game.difficulty,'created_at',v_game.created_at),
  'player_id',v_player.id,
  'challenge',case when v_challenge.id is null then null else public.adventure_get_challenge(v_challenge.id) end,
  'room_index',v_player.room_index,'errors',v_player.errors,'eliminated',v_player.eliminated
 );
end;
$$;

-- Door questions in +1 rooms use the raised level. Trap rooms keep the trap penalty
-- because their challenge rows were marked challenge_type='trap' at preparation time.
create or replace function public.submit_adventure_answer(p_game_id uuid,p_answer text)
returns jsonb language plpgsql security definer set search_path=public
as $$
declare
 v_player public.adventure_players;v_game public.adventure_games;
 v_challenge public.adventure_challenges;v_next public.adventure_challenges;
 v_correct boolean;v_message text;v_target text;
begin
 select * into v_player from public.adventure_players
 where game_id=p_game_id and user_id=auth.uid() for update;
 if not found then raise exception 'No formas parte de esta expedición.'; end if;
 select * into v_game from public.adventure_games where id=p_game_id;
 if v_game.status<>'active' or v_player.eliminated or v_player.room_index>=5 then raise exception 'No puedes responder en este momento.'; end if;
 if exists(select 1 from public.adventure_enemies where game_id=p_game_id and room_index=v_player.room_index and status='active') then
  raise exception 'Primero debes derrotar a todos los enemigos de esta sala.';
 end if;
 select * into v_challenge from public.adventure_challenges where id=v_player.challenge_id and game_id=p_game_id;
 if not found then raise exception 'No se encontró el desafío asignado.'; end if;
 if not exists(select 1 from jsonb_array_elements_text(v_challenge.options) o(value) where value=p_answer) then raise exception 'La opción elegida no es válida.'; end if;
 v_correct:=p_answer=v_challenge.correct_answer;
 insert into public.adventure_answers(game_id,player_id,challenge_id,selected_answer,is_correct)
 values(p_game_id,v_player.id,v_challenge.id,p_answer,v_correct)
 on conflict(player_id,challenge_id) do update set selected_answer=excluded.selected_answer,is_correct=excluded.is_correct,answered_at=now();
 if v_correct then
  update public.adventure_players set room_index=room_index+1,challenge_id=null,last_seen_at=now()
  where id=v_player.id returning * into v_player;
  if v_player.room_index<5 then
   v_target:=public.adventure_room_difficulty(p_game_id,v_player.room_index);
   select * into v_next from public.adventure_challenges
   where game_id=p_game_id and room_index=v_player.room_index
    and (v_target='mixed' or difficulty=v_target)
   order by random() limit 1;
   if not found then raise exception 'No hay desafíos configurados para la siguiente sala.'; end if;
   update public.adventure_players set challenge_id=v_next.id where id=v_player.id returning * into v_player;
   v_message:='¡Correcto! La puerta se abre y avanzas a la siguiente sala.';
  else v_message:='¡Has superado las cinco salas! La cámara del tesoro está abierta.'; end if;
  insert into public.adventure_events(game_id,actor_player_id,event_type,message)
  values(p_game_id,v_player.id,'room_cleared',v_player.nickname||' ha abierto la puerta de la sala '||v_player.room_index||'.');
 else
  if v_challenge.challenge_type in ('enemy','trap') then
   update public.adventure_players set errors=least(errors+1,3),eliminated=(errors+1>=3),last_seen_at=now()
   where id=v_player.id returning * into v_player;
   v_message:=case when v_player.eliminated then 'Respuesta incorrecta. Has perdido tu última vida y quedas eliminado.'
    else 'Respuesta incorrecta. Has perdido una vida. Te quedan '||(3-v_player.errors)||'.' end;
   insert into public.adventure_events(game_id,actor_player_id,event_type,message)
   values(p_game_id,v_player.id,case when v_player.eliminated then 'player_eliminated' else 'life_lost' end,v_player.nickname||' ha fallado un desafío peligroso.');
  else
   update public.adventure_players set last_seen_at=now() where id=v_player.id returning * into v_player;
   v_message:='Respuesta incorrecta. Inténtalo nuevamente; esta pregunta no quita vidas.';
   insert into public.adventure_events(game_id,actor_player_id,event_type,message)
   values(p_game_id,v_player.id,'wrong_answer',v_player.nickname||' ha fallado el desafío de la puerta.');
  end if;
 end if;
 return jsonb_build_object('correct',v_correct,'eliminated',v_player.eliminated,'room_index',v_player.room_index,
  'errors',v_player.errors,'completed',v_player.room_index>=5,
  'challenge',case when v_player.challenge_id is null then null else public.adventure_get_challenge(v_player.challenge_id) end,
  'message',v_message);
end;
$$;

-- When the last enemy falls, assign the door question at the room's configured level.
create or replace function public.attack_adventure_enemy(p_game_id uuid,p_enemy_id uuid,p_answer text)
returns jsonb language plpgsql security definer set search_path=public
as $$
declare
 v_player public.adventure_players;v_game public.adventure_games;
 v_challenge public.adventure_challenges;v_next public.adventure_challenges;
 v_door public.adventure_challenges;v_enemy public.adventure_enemies;
 v_correct boolean;v_remaining integer;v_message text;v_target text;
begin
 perform 1 from public.adventure_players where game_id=p_game_id order by id for update;
 select * into v_player from public.adventure_players where game_id=p_game_id and user_id=auth.uid();
 if not found then raise exception 'No formas parte de esta expedición.'; end if;
 select * into v_game from public.adventure_games where id=p_game_id;
 if v_game.status<>'active' or v_player.eliminated or v_player.room_index>=5 then raise exception 'No puedes combatir en este momento.'; end if;
 select * into v_enemy from public.adventure_enemies
 where id=p_enemy_id and game_id=p_game_id and room_index=v_player.room_index and status='active' for update;
 if not found then raise exception 'Este enemigo ya no está disponible.'; end if;
 select * into v_challenge from public.adventure_challenges where id=v_enemy.challenge_id and game_id=p_game_id;
 if not found then raise exception 'Este enemigo no tiene una pregunta asignada.'; end if;
 if not exists(select 1 from jsonb_array_elements_text(v_challenge.options) o(value) where value=p_answer) then raise exception 'La opción elegida no es válida.'; end if;
 v_correct:=p_answer=v_challenge.correct_answer;
 insert into public.adventure_answers(game_id,player_id,challenge_id,selected_answer,is_correct)
 values(p_game_id,v_player.id,v_challenge.id,p_answer,v_correct)
 on conflict(player_id,challenge_id) do update set selected_answer=excluded.selected_answer,is_correct=excluded.is_correct,answered_at=now();
 insert into public.adventure_combat(game_id,enemy_id,player_id,challenge_prompt,correct_answer,answered_correctly)
 values(p_game_id,v_enemy.id,v_player.id,v_challenge.prompt,v_challenge.correct_answer,v_correct);
 if v_correct then
  update public.adventure_enemies set health=greatest(health-1,0),status=case when health<=1 then 'defeated' else 'active' end
  where id=v_enemy.id returning * into v_enemy;
  select count(*) into v_remaining from public.adventure_enemies
  where game_id=p_game_id and room_index=v_player.room_index and status='active';
  if v_enemy.status='active' then
   select * into v_next from public.adventure_challenges c
   where c.game_id=p_game_id and c.room_index=v_enemy.room_index and c.difficulty=v_enemy.difficulty and c.id<>v_challenge.id
    and not exists(select 1 from public.adventure_answers a where a.game_id=p_game_id and a.challenge_id=c.id)
    and not exists(select 1 from public.adventure_enemies other_enemy where other_enemy.game_id=p_game_id
     and other_enemy.room_index=v_enemy.room_index and other_enemy.status='active' and other_enemy.id<>v_enemy.id and other_enemy.challenge_id=c.id)
   order by random() limit 1;
   if found then update public.adventure_enemies set challenge_id=v_next.id where id=v_enemy.id returning * into v_enemy; end if;
  end if;
  if v_remaining=0 then
   v_target:=public.adventure_room_difficulty(p_game_id,v_player.room_index);
   select * into v_door from public.adventure_challenges c
   where c.game_id=p_game_id and c.room_index=v_player.room_index
    and (v_target='mixed' or c.difficulty=v_target)
    and not exists(select 1 from public.adventure_answers a where a.game_id=p_game_id and a.challenge_id=c.id)
   order by random() limit 1;
   if not found then
    select * into v_door from public.adventure_challenges c where c.game_id=p_game_id and c.room_index=v_player.room_index
     and (v_target='mixed' or c.difficulty=v_target) order by random() limit 1;
   end if;
   if found then
    update public.adventure_players p set challenge_id=v_door.id
    where p.game_id=p_game_id and p.room_index=v_player.room_index and not p.eliminated;
    select * into v_player from public.adventure_players where id=v_player.id;
   end if;
  end if;
  if v_enemy.status='defeated' then
   v_message:=case when v_remaining=0 then '¡'||v_enemy.name||' ha sido derrotado! La sala está libre. Resuelve el desafío de la puerta.'
    else '¡'||v_enemy.name||' ha sido derrotado! Todavía quedan '||v_remaining||' enemigo(s) en esta sala.' end;
   insert into public.adventure_events(game_id,actor_player_id,event_type,message,payload)
   values(p_game_id,v_player.id,'enemy_defeated',v_player.nickname||' derrotó a '||v_enemy.name||'.',
    jsonb_build_object('enemy_id',v_enemy.id,'room_index',v_enemy.room_index,'remaining_enemies',v_remaining));
  else
   v_message:='¡Impacto! Has causado 1 punto de daño a '||v_enemy.name||'. Le quedan '||v_enemy.health||'/'||v_enemy.max_health||' HP.';
   insert into public.adventure_events(game_id,actor_player_id,event_type,message,payload)
   values(p_game_id,v_player.id,'enemy_damaged',v_player.nickname||' ha causado 1 punto de daño a '||v_enemy.name||'.',
    jsonb_build_object('enemy_id',v_enemy.id,'room_index',v_enemy.room_index,'health',v_enemy.health,'max_health',v_enemy.max_health));
  end if;
 else
  update public.adventure_players set errors=least(errors+1,3),eliminated=(errors+1>=3),last_seen_at=now()
  where id=v_player.id returning * into v_player;
  v_message:=case when v_player.eliminated then 'Respuesta incorrecta. Has perdido tu última vida y quedas eliminado.'
   else 'Respuesta incorrecta. '||v_enemy.name||' te ha herido. Te quedan '||(3-v_player.errors)||' vidas.' end;
  insert into public.adventure_events(game_id,actor_player_id,event_type,message,payload)
  values(p_game_id,v_player.id,case when v_player.eliminated then 'player_eliminated' else 'life_lost' end,
   v_player.nickname||' ha fallado un ataque contra '||v_enemy.name||'.',jsonb_build_object('enemy_id',v_enemy.id,'room_index',v_enemy.room_index));
 end if;
 return jsonb_build_object('correct',v_correct,'eliminated',v_player.eliminated,'room_index',v_player.room_index,
  'errors',v_player.errors,'completed',v_player.room_index>=5,
  'challenge',case when v_player.challenge_id is null then null else public.adventure_get_challenge(v_player.challenge_id) end,
  'enemy',jsonb_build_object('id',v_enemy.id,'room_index',v_enemy.room_index,'name',v_enemy.name,'enemy_type',v_enemy.enemy_type,
   'difficulty',v_enemy.difficulty,'health',v_enemy.health,'max_health',v_enemy.max_health,'status',v_enemy.status),
  'remaining_enemies',v_remaining,'message',v_message);
end;
$$;

revoke all on function public.join_adventure_game(text,text) from public,anon;
grant execute on function public.join_adventure_game(text,text) to authenticated;
revoke all on function public.submit_adventure_answer(uuid,text) from public,anon;
grant execute on function public.submit_adventure_answer(uuid,text) to authenticated;
revoke all on function public.attack_adventure_enemy(uuid,uuid,text) from public,anon;
grant execute on function public.attack_adventure_enemy(uuid,uuid,text) to authenticated;


-- Reviving a player also respects the configured difficulty of their current room.
create or replace function public.adventure_teacher_action(
 p_game_id uuid,
 p_action text,
 p_payload jsonb default '{}'::jsonb
)
returns jsonb
language plpgsql
security definer
set search_path=public
as $$
declare
 v_player public.adventure_players;
 v_item text;
 v_label text;
 v_msg text;
 v_room integer;
 v_type text;
 v_name text;
 v_weakness text;
 v_difficulty text;
 v_hp integer;
 v_challenge_id uuid;
begin
 if not exists(select 1 from public.adventure_games where id=p_game_id and owner_id=auth.uid())
    or not public.is_authorized_teacher() then
  raise exception 'No tienes permisos de maestro del juego.';
 end if;

 if p_action='announce' then
  v_msg:=left(coalesce(p_payload->>'message',''),240);
  if v_msg='' then raise exception 'Escribe un anuncio.'; end if;
  insert into public.adventure_events(game_id,event_type,message)
  values(p_game_id,'announcement',v_msg);

 elsif p_action='gift' then
  select * into v_player from public.adventure_players
  where id=(p_payload->>'player_id')::uuid and game_id=p_game_id;
  if not found then raise exception 'Selecciona un estudiante válido.'; end if;
  v_item:=coalesce(p_payload->>'item_key','teacher_gift');
  v_label:=coalesce(p_payload->>'label','Regalo del maestro');
  insert into public.adventure_inventory(game_id,player_id,item_key,label,description)
  values(p_game_id,v_player.id,v_item,v_label,coalesce(p_payload->>'description','Regalo del maestro del juego'))
  on conflict(player_id,item_key) do update
  set quantity=public.adventure_inventory.quantity+1,
      label=excluded.label, description=excluded.description;
  insert into public.adventure_events(game_id,actor_player_id,event_type,message)
  values(p_game_id,v_player.id,'gift',v_player.nickname||' ha recibido: '||v_label||'.');

 elsif p_action='revive' then
  update public.adventure_players
  set eliminated=false,errors=0,
      challenge_id=(select c.id from public.adventure_challenges c
       where c.game_id=p_game_id and c.room_index=adventure_players.room_index
        and (public.adventure_room_difficulty(p_game_id,adventure_players.room_index)='mixed'
          or c.difficulty=public.adventure_room_difficulty(p_game_id,adventure_players.room_index))
       order by random() limit 1),
      last_seen_at=now()
  where id=(p_payload->>'player_id')::uuid and game_id=p_game_id;
  if not found then raise exception 'No se encontró al estudiante.'; end if;
  insert into public.adventure_events(game_id,event_type,message)
  values(p_game_id,'revival','El maestro del juego ha devuelto a un aventurero a la expedición.');

 elsif p_action='remove_item' then
  delete from public.adventure_inventory
  where player_id=(p_payload->>'player_id')::uuid and game_id=p_game_id
    and item_key=coalesce(p_payload->>'item_key','teacher_gift');
  insert into public.adventure_events(game_id,event_type,message)
  values(p_game_id,'item_removed','El maestro del juego ha retirado un objeto.');

 elsif p_action='spawn_treasure' then
  update public.adventure_treasures
  set available=true,claimed_by=null,claimed_at=null where game_id=p_game_id;
  insert into public.adventure_events(game_id,event_type,message)
  values(p_game_id,'treasure_spawned','¡Ha aparecido un tesoro en las catacumbas!');

 elsif p_action='summon_enemy' then
  v_room:=coalesce((p_payload->>'room_index')::integer,0);
  if v_room<0 or v_room>4 then raise exception 'La sala seleccionada no es válida.'; end if;

  v_type:=coalesce(p_payload->>'enemy_type','specter');
  if v_type='random' then
    v_type:=(array['skeleton','specter','dragon'])[1+floor(random()*3)::integer];
  end if;

  if v_type='skeleton' then
    v_name:='Esqueleto del pentagrama';
    v_weakness:='Reconocimiento de notas y figuras musicales';
    v_difficulty:='beginner'; v_hp:=2;
  elsif v_type='specter' then
    v_name:='Espectro armónico';
    v_weakness:='Intervalos, escalas y acordes';
    v_difficulty:='intermediate'; v_hp:=3;
  elsif v_type='dragon' then
    v_name:='Dragón cromático';
    v_weakness:='Armonía, análisis y aplicación musical';
    v_difficulty:='advanced'; v_hp:=4;
  else
    raise exception 'Tipo de enemigo no válido.';
  end if;

  select c.id into v_challenge_id
  from public.adventure_challenges c
  where c.game_id=p_game_id and c.room_index=v_room and c.difficulty=v_difficulty
    and not exists(select 1 from public.adventure_enemies e
      where e.game_id=p_game_id and e.room_index=v_room and e.status='active'
        and e.challenge_id=c.id)
  order by random() limit 1;

  if v_challenge_id is null then
    select c.id into v_challenge_id
    from public.adventure_challenges c
    where c.game_id=p_game_id and c.room_index=v_room and c.difficulty=v_difficulty
    order by random() limit 1;
  end if;
  if v_challenge_id is null then
    raise exception 'No hay preguntas de nivel % para esta sala.',v_difficulty;
  end if;

  insert into public.adventure_enemies(
    game_id,room_index,name,weakness,health,max_health,enemy_type,difficulty,challenge_id
  ) values (
    p_game_id,v_room,v_name,v_weakness,v_hp,v_hp,v_type,v_difficulty,v_challenge_id
  );

  insert into public.adventure_events(game_id,event_type,message,payload)
  values(p_game_id,'enemy_summoned',
    '¡'||v_name||' ha aparecido en la sala '||(v_room+1)||'! Nivel: '||v_difficulty||'.',
    jsonb_build_object('room_index',v_room,'enemy_type',v_type,'difficulty',v_difficulty));

 elsif p_action='end_game' then
  update public.adventure_games set status='finished',updated_at=now() where id=p_game_id;
  insert into public.adventure_events(game_id,event_type,message)
  values(p_game_id,'game_finished','El maestro del juego ha finalizado la partida.');

 else
  raise exception 'Acción de maestro desconocida.';
 end if;

 return jsonb_build_object('success',true,'action',p_action);
end;
$$;
