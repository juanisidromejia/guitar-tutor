-- Allow the teacher to choose the room where an enemy is summoned.
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
begin
 if not exists(
  select 1 from public.adventure_games
  where id=p_game_id and owner_id=auth.uid()
 ) or not public.is_authorized_teacher() then
  raise exception 'No tienes permisos de maestro del juego.';
 end if;

 if p_action='announce' then
  v_msg:=left(coalesce(p_payload->>'message',''),240);
  if v_msg='' then raise exception 'Escribe un anuncio.'; end if;
  insert into public.adventure_events(game_id,event_type,message)
  values(p_game_id,'announcement',v_msg);

 elsif p_action='gift' then
  select * into v_player
  from public.adventure_players
  where id=(p_payload->>'player_id')::uuid and game_id=p_game_id;
  if not found then raise exception 'Selecciona un estudiante válido.'; end if;
  v_item:=coalesce(p_payload->>'item_key','teacher_gift');
  v_label:=coalesce(p_payload->>'label','Regalo del maestro');
  insert into public.adventure_inventory(game_id,player_id,item_key,label,description)
  values(p_game_id,v_player.id,v_item,v_label,coalesce(p_payload->>'description','Regalo del maestro del juego'))
  on conflict(player_id,item_key) do update
  set quantity=public.adventure_inventory.quantity+1;
  insert into public.adventure_events(game_id,actor_player_id,event_type,message)
  values(p_game_id,v_player.id,'gift',v_player.nickname||' ha recibido: '||v_label||'.');

 elsif p_action='revive' then
  update public.adventure_players
  set eliminated=false,errors=0,
      challenge_id=(
       select c.id from public.adventure_challenges c
       where c.game_id=p_game_id
        and c.room_index=adventure_players.room_index
        and (c.difficulty=(
          select g.difficulty from public.adventure_games g where g.id=p_game_id
        ) or (
          select g.difficulty from public.adventure_games g where g.id=p_game_id
        )='mixed')
       order by random() limit 1
      ),
      last_seen_at=now()
  where id=(p_payload->>'player_id')::uuid and game_id=p_game_id;
  if not found then raise exception 'No se encontró al estudiante.'; end if;
  insert into public.adventure_events(game_id,event_type,message)
  values(p_game_id,'revival','El maestro del juego ha devuelto a un aventurero a la expedición.');

 elsif p_action='remove_item' then
  delete from public.adventure_inventory
  where player_id=(p_payload->>'player_id')::uuid
   and game_id=p_game_id
   and item_key=coalesce(p_payload->>'item_key','teacher_gift');
  insert into public.adventure_events(game_id,event_type,message)
  values(p_game_id,'item_removed','El maestro del juego ha retirado un objeto.');

 elsif p_action='spawn_treasure' then
  update public.adventure_treasures
  set available=true,claimed_by=null,claimed_at=null
  where game_id=p_game_id;
  insert into public.adventure_events(game_id,event_type,message)
  values(p_game_id,'treasure_spawned','¡Ha aparecido un tesoro en las catacumbas!');

 elsif p_action='summon_enemy' then
  v_room:=coalesce((p_payload->>'room_index')::integer,0);
  if v_room<0 or v_room>4 then
   raise exception 'La sala seleccionada no es válida.';
  end if;
  insert into public.adventure_enemies(game_id,room_index,name,weakness)
  values(p_game_id,v_room,'Guardián de las cuerdas','Escalas y acordes');
  insert into public.adventure_events(game_id,event_type,message,payload)
  values(
   p_game_id,
   'enemy_summoned',
   '¡Un guardián musical ha aparecido en la sala '||(v_room+1)||'!',
   jsonb_build_object('room_index',v_room)
  );

 elsif p_action='end_game' then
  update public.adventure_games
  set status='finished',updated_at=now()
  where id=p_game_id;
  insert into public.adventure_events(game_id,event_type,message)
  values(p_game_id,'game_finished','El maestro del juego ha finalizado la partida.');

 else
  raise exception 'Acción de maestro desconocida.';
 end if;

 return jsonb_build_object('success',true,'action',p_action);
end;
$$;

revoke all on function public.adventure_teacher_action(uuid,text,jsonb) from public,anon;
grant execute on function public.adventure_teacher_action(uuid,text,jsonb) to authenticated;
