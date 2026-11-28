-- Separate enemy attacks from door challenges. Each enemy is targeted independently.
create or replace function public.attack_adventure_enemy(
 p_game_id uuid,
 p_enemy_id uuid,
 p_answer text
)
returns jsonb
language plpgsql
security definer
set search_path=public
as $$
declare
 v_player public.adventure_players;
 v_game public.adventure_games;
 v_challenge public.adventure_challenges;
 v_enemy public.adventure_enemies;
 v_correct boolean;
 v_remaining integer;
 v_message text;
begin
 select * into v_player
 from public.adventure_players
 where game_id=p_game_id and user_id=auth.uid()
 for update;
 if not found then raise exception 'No formas parte de esta expedición.'; end if;

 select * into v_game from public.adventure_games where id=p_game_id;
 if v_game.status<>'active' or v_player.eliminated or v_player.room_index>=5 then
  raise exception 'No puedes combatir en este momento.';
 end if;

 select * into v_enemy
 from public.adventure_enemies
 where id=p_enemy_id and game_id=p_game_id
   and room_index=v_player.room_index and status='active'
 for update;
 if not found then raise exception 'Este enemigo ya no está disponible.'; end if;

 select * into v_challenge
 from public.adventure_challenges
 where id=v_player.challenge_id and game_id=p_game_id;
 if not found then raise exception 'No se encontró el desafío de combate.'; end if;

 if not exists (
  select 1 from jsonb_array_elements_text(v_challenge.options) o(value)
  where value=p_answer
 ) then raise exception 'La opción elegida no es válida.'; end if;

 v_correct := p_answer=v_challenge.correct_answer;

 insert into public.adventure_answers(game_id,player_id,challenge_id,selected_answer,is_correct)
 values(p_game_id,v_player.id,v_challenge.id,p_answer,v_correct)
 on conflict(player_id,challenge_id) do update
 set selected_answer=excluded.selected_answer,
     is_correct=excluded.is_correct,
     answered_at=now();

 insert into public.adventure_combat(
  game_id,enemy_id,player_id,challenge_prompt,correct_answer,answered_correctly
 ) values (
  p_game_id,v_enemy.id,v_player.id,v_challenge.prompt,v_challenge.correct_answer,v_correct
 );

 if v_correct then
  update public.adventure_enemies
  set health=greatest(health-1,0),
      status=case when health<=1 then 'defeated' else 'active' end
  where id=v_enemy.id
  returning * into v_enemy;

  select count(*) into v_remaining
  from public.adventure_enemies
  where game_id=p_game_id and room_index=v_player.room_index and status='active';

  if v_enemy.status='defeated' then
   v_message := case when v_remaining=0
    then '¡Enemigo derrotado! La sala está libre. Ahora resuelve el desafío de la puerta.'
    else '¡Enemigo derrotado! Todavía quedan '||v_remaining||' enemigo(s) en esta sala.' end;
   insert into public.adventure_events(game_id,actor_player_id,event_type,message,payload)
   values(p_game_id,v_player.id,'enemy_defeated',
    v_player.nickname||' derrotó a '||v_enemy.name||'.',
    jsonb_build_object('enemy_id',v_enemy.id,'room_index',v_enemy.room_index,'remaining_enemies',v_remaining));
  else
   v_message:='¡Impacto! Has causado 1 punto de daño a '||v_enemy.name||'. Le quedan '||v_enemy.health||'/'||v_enemy.max_health||' HP.';
   insert into public.adventure_events(game_id,actor_player_id,event_type,message,payload)
   values(p_game_id,v_player.id,'enemy_damaged',
    v_player.nickname||' ha causado 1 punto de daño a '||v_enemy.name||'.',
    jsonb_build_object('enemy_id',v_enemy.id,'room_index',v_enemy.room_index,'health',v_enemy.health,'max_health',v_enemy.max_health));
  end if;
 else
  update public.adventure_players
  set errors=least(errors+1,3),
      eliminated=(errors+1>=3),
      last_seen_at=now()
  where id=v_player.id returning * into v_player;

  v_message:=case when v_player.eliminated
   then 'Respuesta incorrecta. Has perdido tu última vida y quedas eliminado.'
   else 'Respuesta incorrecta. '||v_enemy.name||' te ha herido. Te quedan '||(3-v_player.errors)||' vidas.' end;

  insert into public.adventure_events(game_id,actor_player_id,event_type,message,payload)
  values(p_game_id,v_player.id,
   case when v_player.eliminated then 'player_eliminated' else 'life_lost' end,
   v_player.nickname||' ha fallado un ataque contra '||v_enemy.name||'.',
   jsonb_build_object('enemy_id',v_enemy.id,'room_index',v_enemy.room_index));
 end if;

 return jsonb_build_object(
  'correct',v_correct,'eliminated',v_player.eliminated,
  'room_index',v_player.room_index,'errors',v_player.errors,
  'completed',v_player.room_index>=5,
  'challenge',public.adventure_get_challenge(v_player.challenge_id),
  'enemy',jsonb_build_object('id',v_enemy.id,'room_index',v_enemy.room_index,
   'name',v_enemy.name,'health',v_enemy.health,'max_health',v_enemy.max_health,'status',v_enemy.status),
  'remaining_enemies',v_remaining,'message',v_message
 );
end;
$$;

-- Door answers are accepted only after every enemy in the player's room is defeated.
create or replace function public.submit_adventure_answer(p_game_id uuid,p_answer text)
returns jsonb
language plpgsql
security definer
set search_path=public
as $$
declare
 v_player public.adventure_players;
 v_game public.adventure_games;
 v_challenge public.adventure_challenges;
 v_next public.adventure_challenges;
 v_correct boolean;
 v_message text;
begin
 select * into v_player from public.adventure_players
 where game_id=p_game_id and user_id=auth.uid() for update;
 if not found then raise exception 'No formas parte de esta expedición.'; end if;

 select * into v_game from public.adventure_games where id=p_game_id;
 if v_game.status<>'active' or v_player.eliminated or v_player.room_index>=5 then
  raise exception 'No puedes responder en este momento.';
 end if;

 if exists(select 1 from public.adventure_enemies
  where game_id=p_game_id and room_index=v_player.room_index and status='active') then
  raise exception 'Primero debes derrotar a todos los enemigos de esta sala.';
 end if;

 select * into v_challenge from public.adventure_challenges
 where id=v_player.challenge_id and game_id=p_game_id;
 if not found then raise exception 'No se encontró el desafío asignado.'; end if;
 if not exists(select 1 from jsonb_array_elements_text(v_challenge.options) o(value) where value=p_answer) then
  raise exception 'La opción elegida no es válida.';
 end if;

 v_correct:=p_answer=v_challenge.correct_answer;
 insert into public.adventure_answers(game_id,player_id,challenge_id,selected_answer,is_correct)
 values(p_game_id,v_player.id,v_challenge.id,p_answer,v_correct)
 on conflict(player_id,challenge_id) do update
 set selected_answer=excluded.selected_answer,is_correct=excluded.is_correct,answered_at=now();

 if v_correct then
  update public.adventure_players
  set room_index=room_index+1,challenge_id=null,last_seen_at=now()
  where id=v_player.id returning * into v_player;

  if v_player.room_index<5 then
   select * into v_next from public.adventure_challenges
   where game_id=p_game_id and room_index=v_player.room_index
    and (v_game.difficulty='mixed' or difficulty=v_game.difficulty)
   order by random() limit 1;
   if not found then raise exception 'No hay desafíos configurados para la siguiente sala.'; end if;
   update public.adventure_players set challenge_id=v_next.id
   where id=v_player.id returning * into v_player;
   v_message:='¡Correcto! La puerta se abre y avanzas a la siguiente sala.';
  else
   v_message:='¡Has superado las cinco salas! La cámara del tesoro está abierta.';
  end if;

  insert into public.adventure_events(game_id,actor_player_id,event_type,message)
  values(p_game_id,v_player.id,'room_cleared',v_player.nickname||' ha abierto la puerta de la sala '||v_player.room_index||'.');
 else
  update public.adventure_players set last_seen_at=now()
  where id=v_player.id returning * into v_player;
  v_message:='Respuesta incorrecta. Inténtalo nuevamente; esta pregunta no quita vidas.';
  insert into public.adventure_events(game_id,actor_player_id,event_type,message)
  values(p_game_id,v_player.id,'wrong_answer',v_player.nickname||' ha fallado el desafío de la puerta.');
 end if;

 return jsonb_build_object(
  'correct',v_correct,'eliminated',v_player.eliminated,
  'room_index',v_player.room_index,'errors',v_player.errors,
  'completed',v_player.room_index>=5,
  'challenge',case when v_player.challenge_id is null then null else public.adventure_get_challenge(v_player.challenge_id) end,
  'message',v_message
 );
end;
$$;

revoke all on function public.attack_adventure_enemy(uuid,uuid,text) from public,anon;
grant execute on function public.attack_adventure_enemy(uuid,uuid,text) to authenticated;
revoke all on function public.submit_adventure_answer(uuid,text) from public,anon;
grant execute on function public.submit_adventure_answer(uuid,text) to authenticated;
