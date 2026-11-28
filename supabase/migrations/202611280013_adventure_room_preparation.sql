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
   v_enemy_difficulty:=case
    when v_offset=1 and v_base_difficulty='beginner' then 'intermediate'
    when v_offset=1 and v_base_difficulty='intermediate' then 'advanced'
    when v_offset=1 and v_base_difficulty='advanced' then 'advanced'
    else v_base_difficulty end;

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
