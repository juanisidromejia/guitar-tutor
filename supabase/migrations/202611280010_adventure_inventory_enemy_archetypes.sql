-- Usable inventory and pedagogically differentiated enemies.
alter table public.adventure_enemies
  add column if not exists enemy_type text not null default 'specter',
  add column if not exists difficulty text not null default 'intermediate',
  add column if not exists challenge_id uuid references public.adventure_challenges(id);

alter table public.adventure_enemies
  drop constraint if exists adventure_enemies_enemy_type_check;
alter table public.adventure_enemies
  add constraint adventure_enemies_enemy_type_check
  check (enemy_type in ('skeleton','specter','dragon'));

alter table public.adventure_enemies
  drop constraint if exists adventure_enemies_difficulty_check;
alter table public.adventure_enemies
  add constraint adventure_enemies_difficulty_check
  check (difficulty in ('beginner','intermediate','advanced'));

update public.adventure_enemies
set enemy_type='specter', difficulty='intermediate'
where enemy_type is null or difficulty is null;

update public.adventure_enemies e
set challenge_id = (
  select c.id from public.adventure_challenges c
  where c.game_id=e.game_id and c.room_index=e.room_index
    and c.difficulty=e.difficulty
  order by random() limit 1
)
where e.challenge_id is null;


-- Add a second intermediate and advanced question in every room so enemies
-- can rotate questions instead of repeating a single prompt indefinitely.
insert into public.adventure_challenges(game_id,room_index,difficulty,variant_key,prompt,options,correct_answer,explanation)
select g.id, q.room_index, q.difficulty, q.variant_key, q.prompt, q.options::jsonb, q.correct_answer, q.explanation
from public.adventure_games g
cross join (values
 (0,'intermediate','g-scale-e','¿Qué grado ocupa Re en la escala de Sol mayor?','["Segundo","Tercero","Quinto","Sexto"]','Quinto','Re es el quinto grado de Sol mayor.'),
 (0,'advanced','g-scale-f','¿Qué intervalo se forma entre Do y Fa♯?','["Cuarta justa","Cuarta aumentada","Quinta justa","Tercera mayor"]','Cuarta aumentada','Do–Fa♯ forma una cuarta aumentada.'),
 (1,'intermediate','g-notes-e','¿Qué nota ocupa el segundo grado de Sol mayor?','["La","Si","Do","Re"]','La','La es el segundo grado de Sol mayor.'),
 (1,'advanced','g-notes-f','¿Qué intervalo se forma entre Sol y Si?','["Tercera menor","Tercera mayor","Cuarta justa","Quinta justa"]','Tercera mayor','Sol–Si forma una tercera mayor.'),
 (2,'intermediate','c-scale-e','¿Qué grado ocupa Mi en la escala de Do mayor?','["Segundo","Tercero","Cuarto","Sexto"]','Tercero','Mi es el tercer grado de Do mayor.'),
 (2,'advanced','c-scale-f','¿Qué intervalo se forma entre Fa y Si?','["Cuarta justa","Cuarta aumentada","Quinta justa","Sexta menor"]','Cuarta aumentada','Fa–Si forma una cuarta aumentada.'),
 (3,'intermediate','e-scale-e','¿Qué grado ocupa Re♯ en la escala de Mi mayor?','["Quinto","Sexto","Séptimo","Octavo"]','Séptimo','Re♯ es el séptimo grado de Mi mayor.'),
 (3,'advanced','e-scale-f','¿Cuál es la sensible de la tonalidad de Mi mayor?','["Do♯","Re♯","Fa♯","Sol♯"]','Re♯','La sensible de Mi mayor es Re♯.'),
 (4,'intermediate','g-chord-e','¿Qué función cumple Do mayor en la tonalidad de Sol mayor?','["Tónica","Subdominante","Dominante","Sensible"]','Subdominante','Do mayor es el acorde de subdominante (IV) en Sol mayor.'),
 (4,'advanced','g-chord-f','¿Qué acorde cumple la función dominante en Sol mayor?','["Do mayor","Re mayor","Mi menor","La menor"]','Re mayor','Re mayor es el acorde de dominante (V) en Sol mayor.')
) as q(room_index,difficulty,variant_key,prompt,options,correct_answer,explanation)
where not exists (
 select 1 from public.adventure_challenges c
 where c.game_id=g.id and c.room_index=q.room_index and c.variant_key=q.variant_key
);

create index if not exists adventure_enemies_challenge_idx
  on public.adventure_enemies(challenge_id);



-- New adventures also receive the expanded question pool. This trigger is
-- separate from create_adventure_game so its existing crypto search_path fix
-- remains untouched.
create or replace function public.seed_adventure_enemy_challenges()
returns trigger
language plpgsql
security definer
set search_path=public
as $$
begin
 insert into public.adventure_challenges(game_id,room_index,difficulty,variant_key,prompt,options,correct_answer,explanation)
 values
 (new.id,0,'intermediate','g-scale-e','¿Qué grado ocupa Re en la escala de Sol mayor?','["Segundo","Tercero","Quinto","Sexto"]'::jsonb,'Quinto','Re es el quinto grado de Sol mayor.'),
 (new.id,0,'advanced','g-scale-f','¿Qué intervalo se forma entre Do y Fa♯?','["Cuarta justa","Cuarta aumentada","Quinta justa","Tercera mayor"]'::jsonb,'Cuarta aumentada','Do–Fa♯ forma una cuarta aumentada.'),
 (new.id,1,'intermediate','g-notes-e','¿Qué nota ocupa el segundo grado de Sol mayor?','["La","Si","Do","Re"]'::jsonb,'La','La es el segundo grado de Sol mayor.'),
 (new.id,1,'advanced','g-notes-f','¿Qué intervalo se forma entre Sol y Si?','["Tercera menor","Tercera mayor","Cuarta justa","Quinta justa"]'::jsonb,'Tercera mayor','Sol–Si forma una tercera mayor.'),
 (new.id,2,'intermediate','c-scale-e','¿Qué grado ocupa Mi en la escala de Do mayor?','["Segundo","Tercero","Cuarto","Sexto"]'::jsonb,'Tercero','Mi es el tercer grado de Do mayor.'),
 (new.id,2,'advanced','c-scale-f','¿Qué intervalo se forma entre Fa y Si?','["Cuarta justa","Cuarta aumentada","Quinta justa","Sexta menor"]'::jsonb,'Cuarta aumentada','Fa–Si forma una cuarta aumentada.'),
 (new.id,3,'intermediate','e-scale-e','¿Qué grado ocupa Re♯ en la escala de Mi mayor?','["Quinto","Sexto","Séptimo","Octavo"]'::jsonb,'Séptimo','Re♯ es el séptimo grado de Mi mayor.'),
 (new.id,3,'advanced','e-scale-f','¿Cuál es la sensible de la tonalidad de Mi mayor?','["Do♯","Re♯","Fa♯","Sol♯"]'::jsonb,'Re♯','La sensible de Mi mayor es Re♯.'),
 (new.id,4,'intermediate','g-chord-e','¿Qué función cumple Do mayor en la tonalidad de Sol mayor?','["Tónica","Subdominante","Dominante","Sensible"]'::jsonb,'Subdominante','Do mayor es el acorde de subdominante (IV) en Sol mayor.'),
 (new.id,4,'advanced','g-chord-f','¿Qué acorde cumple la función dominante en Sol mayor?','["Do mayor","Re mayor","Mi menor","La menor"]'::jsonb,'Re mayor','Re mayor es el acorde de dominante (V) en Sol mayor.');
 return new;
end;
$$;

drop trigger if exists seed_adventure_enemy_challenges_after_game on public.adventure_games;
create trigger seed_adventure_enemy_challenges_after_game
after insert on public.adventure_games
for each row execute function public.seed_adventure_enemy_challenges();

-- Challenges are intentionally not directly selectable by authenticated clients.
-- Expose only the prompt/options attached to enemies through a membership-checked RPC.
create or replace function public.adventure_get_enemies(p_game_id uuid)
returns jsonb
language plpgsql
stable
security definer
set search_path=public
as $$
declare v_result jsonb;
begin
 if not public.is_adventure_member(p_game_id) and not public.is_adventure_owner(p_game_id) then
  raise exception 'No formas parte de esta expedición.';
 end if;

 select coalesce(jsonb_agg(
  jsonb_build_object(
   'id',e.id,'room_index',e.room_index,'name',e.name,'weakness',e.weakness,
   'enemy_type',e.enemy_type,'difficulty',e.difficulty,
   'health',e.health,'max_health',e.max_health,'status',e.status,
   'challenge',case when c.id is null then null else jsonb_build_object('prompt',c.prompt,'options',c.options) end
  ) order by e.created_at desc
 ),'[]'::jsonb)
 into v_result
 from public.adventure_enemies e
 left join public.adventure_challenges c on c.id=e.challenge_id
 where e.game_id=p_game_id;

 return v_result;
end;
$$;

revoke all on function public.adventure_get_enemies(uuid) from public,anon;
grant execute on function public.adventure_get_enemies(uuid) to authenticated;

-- The student can consume a health potion. The server validates ownership,
-- quantity and current health, then records the action in the shared log.
create or replace function public.use_adventure_item(
  p_game_id uuid,
  p_item_id uuid
)
returns jsonb
language plpgsql
security definer
set search_path=public
as $$
declare
  v_player public.adventure_players;
  v_item public.adventure_inventory;
  v_message text;
begin
  select * into v_player
  from public.adventure_players
  where game_id=p_game_id and user_id=auth.uid()
  for update;

  if not found then raise exception 'No formas parte de esta expedición.'; end if;
  if v_player.eliminated then raise exception 'No puedes usar objetos mientras estás eliminado.'; end if;

  select * into v_item
  from public.adventure_inventory
  where id=p_item_id and game_id=p_game_id and player_id=v_player.id
  for update;

  if not found then raise exception 'Ese objeto no está en tu inventario.'; end if;
  if v_item.item_key <> 'health_potion' then
    raise exception 'Este objeto todavía no tiene un uso habilitado.';
  end if;
  if v_player.errors=0 then raise exception 'Ya tienes todas tus vidas. Guarda la poción para después.'; end if;

  if v_item.quantity=1 then
    delete from public.adventure_inventory where id=v_item.id;
  else
    update public.adventure_inventory set quantity=quantity-1 where id=v_item.id;
  end if;

  update public.adventure_players
  set errors=greatest(errors-1,0), last_seen_at=now()
  where id=v_player.id returning * into v_player;

  v_message := v_player.nickname||' ha usado una poción de vida y recuperó una vida.';
  insert into public.adventure_events(game_id,actor_player_id,event_type,message,payload)
  values(p_game_id,v_player.id,'item_used',v_message,
    jsonb_build_object('item_key',v_item.item_key,'remaining_quantity',greatest(v_item.quantity-1,0),'errors',v_player.errors));

  return jsonb_build_object(
    'success',true,'errors',v_player.errors,
    'lives',3-v_player.errors,
    'message','¡Poción utilizada! Has recuperado una vida.'
  );
end;
$$;

revoke all on function public.use_adventure_item(uuid,uuid) from public,anon;
grant execute on function public.use_adventure_item(uuid,uuid) to authenticated;

-- Teacher actions now support selecting a pedagogical enemy archetype.
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
        and (c.difficulty=(select g.difficulty from public.adventure_games g where g.id=p_game_id)
          or (select g.difficulty from public.adventure_games g where g.id=p_game_id)='mixed')
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

-- Every enemy carries its own question at its own difficulty. A successful hit
-- advances that enemy's question; an incorrect answer leaves it for reinforcement.
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
 v_next public.adventure_challenges;
 v_door public.adventure_challenges;
 v_enemy public.adventure_enemies;
 v_correct boolean;
 v_remaining integer;
 v_message text;
begin
 perform 1 from public.adventure_players
 where game_id=p_game_id order by id for update;

 select * into v_player from public.adventure_players
 where game_id=p_game_id and user_id=auth.uid();
 if not found then raise exception 'No formas parte de esta expedición.'; end if;

 select * into v_game from public.adventure_games where id=p_game_id;
 if v_game.status<>'active' or v_player.eliminated or v_player.room_index>=5 then
  raise exception 'No puedes combatir en este momento.';
 end if;

 select * into v_enemy from public.adventure_enemies
 where id=p_enemy_id and game_id=p_game_id
  and room_index=v_player.room_index and status='active'
 for update;
 if not found then raise exception 'Este enemigo ya no está disponible.'; end if;

 select * into v_challenge from public.adventure_challenges
 where id=v_enemy.challenge_id and game_id=p_game_id;
 if not found then raise exception 'Este enemigo no tiene una pregunta asignada.'; end if;

 if not exists(select 1 from jsonb_array_elements_text(v_challenge.options) o(value) where value=p_answer) then
  raise exception 'La opción elegida no es válida.';
 end if;

 v_correct:=p_answer=v_challenge.correct_answer;

 insert into public.adventure_answers(game_id,player_id,challenge_id,selected_answer,is_correct)
 values(p_game_id,v_player.id,v_challenge.id,p_answer,v_correct)
 on conflict(player_id,challenge_id) do update
 set selected_answer=excluded.selected_answer,is_correct=excluded.is_correct,answered_at=now();

 insert into public.adventure_combat(game_id,enemy_id,player_id,challenge_prompt,correct_answer,answered_correctly)
 values(p_game_id,v_enemy.id,v_player.id,v_challenge.prompt,v_challenge.correct_answer,v_correct);

 if v_correct then
  update public.adventure_enemies
  set health=greatest(health-1,0),
      status=case when health<=1 then 'defeated' else 'active' end
  where id=v_enemy.id returning * into v_enemy;

  select count(*) into v_remaining from public.adventure_enemies
  where game_id=p_game_id and room_index=v_player.room_index and status='active';

  if v_enemy.status='active' then
   select * into v_next from public.adventure_challenges c
   where c.game_id=p_game_id and c.room_index=v_enemy.room_index
    and c.difficulty=v_enemy.difficulty and c.id<>v_challenge.id
    and not exists(select 1 from public.adventure_answers a
      where a.game_id=p_game_id and a.challenge_id=c.id)
    and not exists(select 1 from public.adventure_enemies other_enemy
      where other_enemy.game_id=p_game_id and other_enemy.room_index=v_enemy.room_index
       and other_enemy.status='active' and other_enemy.id<>v_enemy.id
       and other_enemy.challenge_id=c.id)
   order by random() limit 1;

   -- If the room's unused questions are exhausted, keep this enemy's current
   -- question for reinforcement instead of borrowing another active enemy's prompt.
   if found then
    update public.adventure_enemies set challenge_id=v_next.id where id=v_enemy.id
    returning * into v_enemy;
   end if;
  end if;

  if v_remaining=0 then
   select * into v_door from public.adventure_challenges c
   where c.game_id=p_game_id and c.room_index=v_player.room_index
    and (v_game.difficulty='mixed' or c.difficulty=v_game.difficulty)
    and not exists(select 1 from public.adventure_answers a
      where a.game_id=p_game_id and a.challenge_id=c.id)
   order by random() limit 1;

   if not found then
    select * into v_door from public.adventure_challenges c
    where c.game_id=p_game_id and c.room_index=v_player.room_index
     and (v_game.difficulty='mixed' or c.difficulty=v_game.difficulty)
    order by random() limit 1;
   end if;

   if found then
    update public.adventure_players p set challenge_id=v_door.id
    where p.game_id=p_game_id and p.room_index=v_player.room_index and not p.eliminated;
    select * into v_player from public.adventure_players where id=v_player.id;
   end if;
  end if;

  if v_enemy.status='defeated' then
   v_message:=case when v_remaining=0
    then '¡'||v_enemy.name||' ha sido derrotado! La sala está libre. Resuelve el desafío de la puerta.'
    else '¡'||v_enemy.name||' ha sido derrotado! Todavía quedan '||v_remaining||' enemigo(s) en esta sala.' end;
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
  set errors=least(errors+1,3),eliminated=(errors+1>=3),last_seen_at=now()
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
  'challenge',case when v_player.challenge_id is null then null else public.adventure_get_challenge(v_player.challenge_id) end,
  'enemy',jsonb_build_object('id',v_enemy.id,'room_index',v_enemy.room_index,
   'name',v_enemy.name,'enemy_type',v_enemy.enemy_type,'difficulty',v_enemy.difficulty,
   'health',v_enemy.health,'max_health',v_enemy.max_health,'status',v_enemy.status),
  'remaining_enemies',v_remaining,'message',v_message
 );
end;
$$;

revoke all on function public.attack_adventure_enemy(uuid,uuid,text) from public,anon;
grant execute on function public.attack_adventure_enemy(uuid,uuid,text) to authenticated;

do $$
begin
 alter publication supabase_realtime add table public.adventure_inventory;
exception when duplicate_object then null;
end $$;
