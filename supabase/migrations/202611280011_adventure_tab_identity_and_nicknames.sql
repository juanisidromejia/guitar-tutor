-- Give each browser tab an independent anonymous Supabase identity and
-- assign collision-free nicknames within each adventure.
-- The game-row lock serializes joins so simultaneous students cannot claim
-- the same display name.

create or replace function public.join_adventure_game(p_code text,p_nickname text)
returns jsonb
language plpgsql
security definer
set search_path=public
as $$
declare
  v_game public.adventure_games;
  v_player public.adventure_players;
  v_challenge public.adventure_challenges;
  v_base text;
  v_candidate text;
  v_suffix integer := 1;
  v_suffix_text text;
begin
  if auth.uid() is null then
    raise exception 'No se pudo identificar al aventurero.';
  end if;

  if char_length(trim(p_nickname)) < 1 or char_length(trim(p_nickname)) > 24 then
    raise exception 'El nombre debe tener entre 1 y 24 caracteres.';
  end if;

  -- Serialize joins to this game while choosing a unique nickname.
  select * into v_game
  from public.adventure_games
  where code=upper(trim(p_code))
  for update;

  if not found or v_game.status='finished' then
    raise exception 'La partida no existe o ya terminó.';
  end if;

  select * into v_player
  from public.adventure_players
  where game_id=v_game.id and user_id=auth.uid();

  v_base:=trim(p_nickname);
  v_candidate:=left(v_base,24);

  loop
    if not exists(
      select 1
      from public.adventure_players p
      where p.game_id=v_game.id
        and lower(p.nickname)=lower(v_candidate)
        and (v_player.id is null or p.id<>v_player.id)
    ) then
      exit;
    end if;

    v_suffix:=v_suffix+1;
    v_suffix_text:=' '||v_suffix::text;
    v_candidate:=left(v_base,24-char_length(v_suffix_text))||v_suffix_text;
  end loop;

  if not found then
    select * into v_challenge
    from public.adventure_challenges
    where game_id=v_game.id and room_index=0
      and (v_game.difficulty='mixed' or difficulty=v_game.difficulty)
    order by random()
    limit 1;

    if v_challenge.id is null then
      raise exception 'No hay preguntas disponibles para iniciar esta aventura.';
    end if;

    insert into public.adventure_players(game_id,user_id,nickname,challenge_id)
    values(v_game.id,auth.uid(),v_candidate,v_challenge.id)
    returning * into v_player;

    insert into public.adventure_events(game_id,actor_player_id,event_type,message)
    values(v_game.id,v_player.id,'player_joined',v_player.nickname||' se ha unido a la expedición.');
  else
    if v_game.status='active' and v_player.last_seen_at < now()-interval '3 minutes' then
      update public.adventure_players
      set eliminated=true,errors=3,last_seen_at=now(),disconnected_at=now()
      where id=v_player.id
      returning * into v_player;

      insert into public.adventure_events(game_id,actor_player_id,event_type,message)
      values(v_game.id,v_player.id,'reconnect_expired',
        v_player.nickname||' perdió la conexión durante más de tres minutos y quedó fuera de la expedición.');
    else
      update public.adventure_players
      set nickname=v_candidate,last_seen_at=now(),disconnected_at=null
      where id=v_player.id
      returning * into v_player;
    end if;

    select * into v_challenge
    from public.adventure_challenges
    where id=v_player.challenge_id;
  end if;

  return jsonb_build_object(
    'game',jsonb_build_object(
      'id',v_game.id,'code',v_game.code,'title',v_game.title,
      'status',v_game.status,'difficulty',v_game.difficulty,'created_at',v_game.created_at
    ),
    'player_id',v_player.id,
    'challenge',case when v_challenge.id is null then null else public.adventure_get_challenge(v_challenge.id) end,
    'room_index',v_player.room_index,
    'errors',v_player.errors,
    'eliminated',v_player.eliminated
  );
end;
$$;

revoke all on function public.join_adventure_game(text,text) from public,anon;
grant execute on function public.join_adventure_game(text,text) to authenticated;
