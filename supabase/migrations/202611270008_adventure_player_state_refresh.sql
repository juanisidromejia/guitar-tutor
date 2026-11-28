-- Safe per-player state refresh for cooperative room unlocks.
-- The RPC exposes only the authenticated player's assigned challenge, never its answer.

create or replace function public.adventure_get_player_state(p_game_id uuid)
returns jsonb
language plpgsql
stable
security definer
set search_path=public
as $$
declare
 v_player public.adventure_players;
begin
 select * into v_player
 from public.adventure_players
 where game_id=p_game_id and user_id=auth.uid();

 if not found then
  raise exception 'No formas parte de esta expedición.';
 end if;

 return jsonb_build_object(
  'player_id',v_player.id,
  'room_index',v_player.room_index,
  'errors',v_player.errors,
  'eliminated',v_player.eliminated,
  'finished_at',v_player.finished_at,
  'challenge',case
   when v_player.challenge_id is null then null
   else public.adventure_get_challenge(v_player.challenge_id)
  end
 );
end;
$$;

revoke all on function public.adventure_get_player_state(uuid) from public,anon;
grant execute on function public.adventure_get_player_state(uuid) to authenticated;
