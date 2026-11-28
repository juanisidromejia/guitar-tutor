-- Cooperative enemy health: every correct musical answer deals one shared point of damage.
-- Enemy rows are locked while resolving attacks so simultaneous students cannot overwrite health.

alter table public.adventure_enemies
  add column if not exists max_health integer not null default 3;

update public.adventure_enemies
set max_health = greatest(health, 3)
where max_health < health;

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
 v_enemy public.adventure_enemies;
 v_correct boolean;
 v_message text;
 v_enemy_active boolean := false;
begin
 select * into v_player
 from public.adventure_players
 where game_id=p_game_id and user_id=auth.uid()
 for update;

 if not found then
  raise exception 'No formas parte de esta expedición.';
 end if;

 select * into v_game from public.adventure_games where id=p_game_id;
 if v_game.status<>'active' or v_player.eliminated or v_player.room_index>=5 then
  raise exception 'No puedes responder en este momento.';
 end if;

 select * into v_challenge
 from public.adventure_challenges
 where id=v_player.challenge_id and game_id=p_game_id;

 if not found then
  raise exception 'No se encontró el desafío asignado.';
 end if;

 if not exists(
  select 1 from jsonb_array_elements_text(v_challenge.options) o(value)
  where value=p_answer
 ) then
  raise exception 'La opción elegida no es válida.';
 end if;

 -- Lock the active enemy in this room. This serializes attacks from different students.
 select * into v_enemy
 from public.adventure_enemies
 where game_id=p_game_id
  and room_index=v_player.room_index
  and status='active'
 order by created_at desc
 limit 1
 for update;

 v_enemy_active := found;
 v_correct := p_answer=v_challenge.correct_answer;

 insert into public.adventure_answers(game_id,player_id,challenge_id,selected_answer,is_correct)
 values(p_game_id,v_player.id,v_challenge.id,p_answer,v_correct)
 on conflict(player_id,challenge_id) do update
 set selected_answer=excluded.selected_answer,
     is_correct=excluded.is_correct,
     answered_at=now();

 if v_enemy_active then
  insert into public.adventure_combat(
   game_id,enemy_id,player_id,challenge_prompt,correct_answer,answered_correctly
  )
  values(
   p_game_id,v_enemy.id,v_player.id,v_challenge.prompt,v_challenge.correct_answer,v_correct
  );

  if v_correct then
   update public.adventure_enemies
   set health=greatest(health-1,0),
       status=case when health<=1 then 'defeated' else 'active' end
   where id=v_enemy.id
   returning * into v_enemy;

   if v_enemy.status='defeated' then
    -- Defeating the enemy opens this room for every living player currently inside it.
    update public.adventure_players p
    set room_index=p.room_index+1,
        challenge_id=case
          when p.room_index<4 then (
            select c.id
            from public.adventure_challenges c
            where c.game_id=p_game_id
             and c.room_index=p.room_index+1
             and (v_game.difficulty='mixed' or c.difficulty=v_game.difficulty)
            order by random()
            limit 1
          )
          else null
        end,
        last_seen_at=now()
    where p.game_id=p_game_id
     and p.room_index=v_enemy.room_index
     and not p.eliminated;

    select * into v_player
    from public.adventure_players
    where id=v_player.id;

    v_message:='¡Enemigo derrotado! El grupo ha abierto la puerta y todos los aventureros de esta sala avanzan.';
    insert into public.adventure_events(game_id,actor_player_id,event_type,message,payload)
    values(
     p_game_id,v_player.id,'enemy_defeated',
     v_player.nickname||' ha dado el golpe final. ¡El grupo derrotó al enemigo!',
     jsonb_build_object('enemy_id',v_enemy.id,'room_index',v_enemy.room_index,'health',0,'max_health',v_enemy.max_health)
    );
   else
    -- A successful hit keeps the player in the room while the shared enemy is alive.
    select * into v_next
    from public.adventure_challenges c
    where c.game_id=p_game_id
     and c.room_index=v_player.room_index
     and (v_game.difficulty='mixed' or c.difficulty=v_game.difficulty)
     and c.id<>v_challenge.id
    order by random()
    limit 1;

    if found then
     update public.adventure_players
     set challenge_id=v_next.id,last_seen_at=now()
     where id=v_player.id
     returning * into v_player;
    else
     update public.adventure_players
     set last_seen_at=now()
     where id=v_player.id
     returning * into v_player;
    end if;

    v_message:='¡Respuesta correcta! Has causado 1 punto de daño al enemigo. La vida compartida del enemigo es '||v_enemy.health||'/'||v_enemy.max_health||'.';
    insert into public.adventure_events(game_id,actor_player_id,event_type,message,payload)
    values(
     p_game_id,v_player.id,'enemy_damaged',
     v_player.nickname||' ha causado 1 punto de daño al enemigo.',
     jsonb_build_object('enemy_id',v_enemy.id,'room_index',v_enemy.room_index,'health',v_enemy.health,'max_health',v_enemy.max_health)
    );
   end if;
  else
   update public.adventure_players
   set errors=least(errors+1,3),
       eliminated=(errors+1>=3),
       last_seen_at=now()
   where id=v_player.id
   returning * into v_player;

   if v_player.eliminated then
    v_message:='Respuesta incorrecta. Has perdido tu última vida y quedas eliminado. Puedes observar la partida.';
   else
    v_message:='Respuesta incorrecta. El enemigo te ha herido: has perdido una vida. Te quedan '||(3-v_player.errors)||'.';
   end if;

   insert into public.adventure_events(game_id,actor_player_id,event_type,message,payload)
   values(
    p_game_id,v_player.id,
    case when v_player.eliminated then 'player_eliminated' else 'life_lost' end,
    case when v_player.eliminated then v_player.nickname||' ha quedado eliminado durante el combate.'
         else v_player.nickname||' ha perdido una vida durante el combate.' end,
    jsonb_build_object('enemy_id',v_enemy.id,'room_index',v_enemy.room_index)
   );
  end if;

 else
  -- Preserve the existing rules when no enemy is present in the player's room.
  if v_correct then
   update public.adventure_players
   set room_index=room_index+1,challenge_id=null,last_seen_at=now()
   where id=v_player.id
   returning * into v_player;

   if v_player.room_index<5 then
    select * into v_next
    from public.adventure_challenges
    where game_id=p_game_id
     and room_index=v_player.room_index
     and (v_game.difficulty='mixed' or difficulty=v_game.difficulty)
    order by random()
    limit 1;

    if not found then
     raise exception 'No hay desafíos configurados para la siguiente sala.';
    end if;

    update public.adventure_players
    set challenge_id=v_next.id
    where id=v_player.id
    returning * into v_player;

    v_message:='¡Correcto! Has abierto la puerta y avanzas a la siguiente sala.';
   else
    v_message:='¡Has superado las cinco salas! La cámara del tesoro está abierta.';
   end if;

   insert into public.adventure_events(game_id,actor_player_id,event_type,message)
   values(p_game_id,v_player.id,'room_cleared',v_player.nickname||' ha superado la sala '||v_player.room_index||'.');

  elsif v_challenge.challenge_type in ('enemy','trap') then
   update public.adventure_players
   set errors=least(errors+1,3),
       eliminated=(errors+1>=3),
       last_seen_at=now()
   where id=v_player.id
   returning * into v_player;

   if v_player.eliminated then
    v_message:='Respuesta incorrecta. Has perdido tu última vida y quedas eliminado. Puedes observar la partida.';
   else
    v_message:='Respuesta incorrecta. Has perdido una vida. Te quedan '||(3-v_player.errors)||'.';
   end if;

   insert into public.adventure_events(game_id,actor_player_id,event_type,message)
   values(
    p_game_id,v_player.id,
    case when v_player.eliminated then 'player_eliminated' else 'life_lost' end,
    case when v_player.eliminated then v_player.nickname||' ha quedado eliminado.'
         else v_player.nickname||' ha perdido una vida.' end
   );
  else
   update public.adventure_players
   set last_seen_at=now()
   where id=v_player.id
   returning * into v_player;

   v_message:='Respuesta incorrecta. Inténtalo nuevamente; esta pregunta no quita vidas.';
   insert into public.adventure_events(game_id,actor_player_id,event_type,message)
   values(p_game_id,v_player.id,'wrong_answer',v_player.nickname||' está intentando resolver el desafío nuevamente.');
  end if;
 end if;

 return jsonb_build_object(
  'correct',v_correct,
  'eliminated',v_player.eliminated,
  'room_index',v_player.room_index,
  'errors',v_player.errors,
  'completed',v_player.room_index>=5,
  'challenge',case when v_player.challenge_id is null then null else public.adventure_get_challenge(v_player.challenge_id) end,
  'enemy',case when v_enemy.id is null then null else jsonb_build_object(
    'id',v_enemy.id,'room_index',v_enemy.room_index,'name',v_enemy.name,
    'health',v_enemy.health,'max_health',v_enemy.max_health,'status',v_enemy.status
  ) end,
  'message',v_message
 );
end;
$$;

revoke all on function public.submit_adventure_answer(uuid,text) from public,anon;
grant execute on function public.submit_adventure_answer(uuid,text) to authenticated;

do $$
begin
 alter publication supabase_realtime add table public.adventure_enemies;
exception when duplicate_object then null;
end $$;
