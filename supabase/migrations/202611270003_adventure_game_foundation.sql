-- Multiplayer adventure foundation: five musical rooms, a shared treasure chamber,
-- individual progression, three-strike elimination, teacher controls and reconnect grace.
create table if not exists public.adventure_games (
 id uuid primary key default gen_random_uuid(),
 owner_id uuid not null references auth.users(id) on delete cascade,
 code text not null unique,
 title text not null check(char_length(title) between 1 and 90),
 status text not null default 'lobby' check(status in ('lobby','active','finished')),
 difficulty text not null default 'beginner' check(difficulty in ('beginner','intermediate','advanced','mixed')),
 created_at timestamptz not null default now(),
 updated_at timestamptz not null default now()
);
create table if not exists public.adventure_rooms (
 id uuid primary key default gen_random_uuid(),
 game_id uuid not null references public.adventure_games(id) on delete cascade,
 room_index integer not null check(room_index between 0 and 5),
 title text not null,
 description text not null default '',
 room_type text not null default 'puzzle' check(room_type in ('puzzle','treasure')),
 unique(game_id,room_index)
);
create table if not exists public.adventure_challenges (
 id uuid primary key default gen_random_uuid(),
 game_id uuid not null references public.adventure_games(id) on delete cascade,
 room_index integer not null check(room_index between 0 and 4),
 difficulty text not null check(difficulty in ('beginner','intermediate','advanced')),
 challenge_type text not null default 'normal' check(challenge_type in ('normal','enemy','trap')),
 variant_key text not null,
 prompt text not null,
 options jsonb not null check(jsonb_typeof(options)='array'),
 correct_answer text not null,
 explanation text not null default '',
 unique(game_id,room_index,variant_key)
);
create table if not exists public.adventure_players (
 id uuid primary key default gen_random_uuid(),
 game_id uuid not null references public.adventure_games(id) on delete cascade,
 user_id uuid not null references auth.users(id) on delete cascade,
 nickname text not null check(char_length(nickname) between 1 and 24),
 room_index integer not null default 0 check(room_index between 0 and 5),
 challenge_id uuid references public.adventure_challenges(id),
 errors integer not null default 0 check(errors between 0 and 3),
 eliminated boolean not null default false,
 joined_at timestamptz not null default now(),
 last_seen_at timestamptz not null default now(),
 disconnected_at timestamptz,
 finished_at timestamptz,
 unique(game_id,user_id)
);
create table if not exists public.adventure_answers (
 id uuid primary key default gen_random_uuid(),
 game_id uuid not null references public.adventure_games(id) on delete cascade,
 player_id uuid not null references public.adventure_players(id) on delete cascade,
 challenge_id uuid not null references public.adventure_challenges(id),
 selected_answer text not null,
 is_correct boolean not null,
 answered_at timestamptz not null default now(),
 unique(player_id,challenge_id)
);
create table if not exists public.adventure_inventory (
 id uuid primary key default gen_random_uuid(),
 game_id uuid not null references public.adventure_games(id) on delete cascade,
 player_id uuid not null references public.adventure_players(id) on delete cascade,
 item_key text not null,
 label text not null,
 description text not null default '',
 quantity integer not null default 1 check(quantity>0),
 created_at timestamptz not null default now(),
 unique(player_id,item_key)
);
create table if not exists public.adventure_treasures (
 id uuid primary key default gen_random_uuid(),
 game_id uuid not null unique references public.adventure_games(id) on delete cascade,
 item_key text not null default 'catacomb_crown',
 label text not null default 'Corona de las Catacumbas',
 description text not null default 'El primer aventurero que la reclame se queda con el tesoro.',
 available boolean not null default true,
 claimed_by uuid references public.adventure_players(id),
 claimed_at timestamptz
);
create table if not exists public.adventure_events (
 id uuid primary key default gen_random_uuid(),
 game_id uuid not null references public.adventure_games(id) on delete cascade,
 actor_player_id uuid references public.adventure_players(id) on delete set null,
 event_type text not null,
 message text not null,
 payload jsonb not null default '{}'::jsonb,
 created_at timestamptz not null default now()
);
create table if not exists public.adventure_enemies (
 id uuid primary key default gen_random_uuid(),
 game_id uuid not null references public.adventure_games(id) on delete cascade,
 room_index integer not null check(room_index between 0 and 4),
 name text not null,
 weakness text not null,
 health integer not null default 3 check(health>=0),
 status text not null default 'active' check(status in ('active','defeated')),
 created_at timestamptz not null default now()
);
create table if not exists public.adventure_combat (
 id uuid primary key default gen_random_uuid(),
 game_id uuid not null references public.adventure_games(id) on delete cascade,
 enemy_id uuid not null references public.adventure_enemies(id) on delete cascade,
 player_id uuid not null references public.adventure_players(id) on delete cascade,
 challenge_prompt text not null,
 correct_answer text not null,
 answered_correctly boolean,
 created_at timestamptz not null default now()
);
create index if not exists adventure_players_game_idx on public.adventure_players(game_id);
create index if not exists adventure_events_game_idx on public.adventure_events(game_id,created_at desc);
create index if not exists adventure_challenges_room_idx on public.adventure_challenges(game_id,room_index,difficulty);

alter table public.adventure_games enable row level security;
alter table public.adventure_rooms enable row level security;
alter table public.adventure_challenges enable row level security;
alter table public.adventure_players enable row level security;
alter table public.adventure_answers enable row level security;
alter table public.adventure_inventory enable row level security;
alter table public.adventure_treasures enable row level security;
alter table public.adventure_events enable row level security;
alter table public.adventure_enemies enable row level security;
alter table public.adventure_combat enable row level security;

create or replace function public.is_adventure_member(p_game_id uuid)
returns boolean language sql stable security definer set search_path=public
as $$ select exists(select 1 from public.adventure_players p where p.game_id=p_game_id and p.user_id=auth.uid()) $$;
create or replace function public.is_adventure_owner(p_game_id uuid)
returns boolean language sql stable security definer set search_path=public
as $$ select exists(select 1 from public.adventure_games g where g.id=p_game_id and g.owner_id=auth.uid()) $$;
drop policy if exists "adventure games visible to members" on public.adventure_games;
create policy "adventure games visible to members" on public.adventure_games for select to authenticated
using(public.is_adventure_owner(id) or public.is_adventure_member(id));
drop policy if exists "adventure players visible to members" on public.adventure_players;
create policy "adventure players visible to members" on public.adventure_players for select to authenticated
using(public.is_adventure_owner(game_id) or public.is_adventure_member(game_id));
drop policy if exists "adventure events visible to members" on public.adventure_events;
create policy "adventure events visible to members" on public.adventure_events for select to authenticated
using(public.is_adventure_owner(game_id) or public.is_adventure_member(game_id));
drop policy if exists "adventure inventory visible to owner" on public.adventure_inventory;
create policy "adventure inventory visible to owner" on public.adventure_inventory for select to authenticated
using(exists(select 1 from public.adventure_players p where p.id=player_id and p.user_id=auth.uid()) or public.is_adventure_owner(game_id));
drop policy if exists "adventure treasures visible to members" on public.adventure_treasures;
create policy "adventure treasures visible to members" on public.adventure_treasures for select to authenticated
using(public.is_adventure_owner(game_id) or public.is_adventure_member(game_id));
drop policy if exists "adventure enemies visible to members" on public.adventure_enemies;
create policy "adventure enemies visible to members" on public.adventure_enemies for select to authenticated
using(public.is_adventure_owner(game_id) or public.is_adventure_member(game_id));

revoke all on public.adventure_challenges,public.adventure_answers,public.adventure_combat from anon,authenticated;
revoke all on public.adventure_games,public.adventure_rooms,public.adventure_players,public.adventure_inventory,public.adventure_treasures,public.adventure_events,public.adventure_enemies from anon,authenticated;
grant select on public.adventure_games,public.adventure_players,public.adventure_events,public.adventure_inventory,public.adventure_treasures,public.adventure_enemies to authenticated;

create or replace function public.adventure_get_challenge(p_challenge_id uuid)
returns jsonb language sql stable security definer set search_path=public
as $$
 select jsonb_build_object('challenge_id',c.id,'room_index',c.room_index,'room_title',r.title,'room_description',r.description,'challenge_type',c.challenge_type,'prompt',c.prompt,'options',c.options)
 from public.adventure_challenges c join public.adventure_rooms r on r.game_id=c.game_id and r.room_index=c.room_index
 where c.id=p_challenge_id
$$;

create or replace function public.create_adventure_game(p_title text,p_difficulty text)
returns jsonb language plpgsql security definer set search_path=public
as $$
declare v_game public.adventure_games; v_code text;
begin
 if auth.uid() is null or not public.is_authorized_teacher() then raise exception 'Solo el docente autorizado puede crear aventuras.'; end if;
 if p_difficulty not in ('beginner','intermediate','advanced','mixed') then raise exception 'Nivel no válido.'; end if;
 if char_length(trim(p_title))<1 or char_length(trim(p_title))>90 then raise exception 'El título debe tener entre 1 y 90 caracteres.'; end if;
 -- Serialize code allocation with the assessment-session factory.
 perform pg_advisory_xact_lock(hashtext('guitar_tutor_shared_session_code_namespace'));
 loop v_code:=upper(substr(encode(gen_random_bytes(5),'hex'),1,6)); exit when not exists(select 1 from public.adventure_games where code=v_code) and not exists(select 1 from public.sessions where code=v_code); end loop;
 insert into public.adventure_games(owner_id,code,title,difficulty) values(auth.uid(),v_code,trim(p_title),p_difficulty) returning * into v_game;
 insert into public.adventure_rooms(game_id,room_index,title,description,room_type) values
 (v_game.id,0,'La puerta de las notas','La primera puerta exige reconocer la escala de Sol mayor.','puzzle'),
 (v_game.id,1,'El corredor de Sol mayor','Las paredes esconden las notas de la escala de Sol mayor.','puzzle'),
 (v_game.id,2,'La cámara de Do mayor','Una inscripción revela la escala natural de Do mayor.','puzzle'),
 (v_game.id,3,'La sala de Mi mayor','Tres símbolos musicales custodian esta sala.','puzzle'),
 (v_game.id,4,'El puente de los acordes','Solo el acorde correcto permitirá cruzar.','puzzle'),
 (v_game.id,5,'La cámara del tesoro','Has superado las cinco pruebas. El tesoro espera a su primer reclamante.','treasure');
 -- Beginner variants plus level-specific intermediate and advanced challenges; each player receives one challenge per room.
 insert into public.adventure_challenges(game_id,room_index,difficulty,variant_key,prompt,options,correct_answer,explanation) values
 (v_game.id,0,'beginner','g-scale-a','¿Qué nota debe aparecer en la escala de Sol mayor?','["Fa","Fa♯","Do♯","Si♭"]'::jsonb,'Fa♯','La escala de Sol mayor contiene Fa♯.'),
 (v_game.id,0,'beginner','g-scale-b','¿Qué alteración tiene la tonalidad de Sol mayor?','["Fa♯","Do♯","Si♭","Mi♭"]'::jsonb,'Fa♯','Sol mayor tiene un sostenido: Fa♯.'),
 (v_game.id,1,'beginner','g-notes-a','¿Cuál es el orden correcto de las notas de Sol mayor?','["Sol–La–Si–Do–Re–Mi–Fa♯","Sol–La–Si♭–Do–Re–Mi–Fa","Sol–Si–Do–Re–Mi–Fa–Sol","Sol–La–Do–Re–Mi–Fa♯–Sol"]'::jsonb,'Sol–La–Si–Do–Re–Mi–Fa♯','Sol mayor contiene Fa♯ y las demás notas naturales.'),
 (v_game.id,1,'beginner','g-notes-b','¿Qué nota sigue a Mi en la escala ascendente de Sol mayor?','["Fa","Fa♯","Sol♯","La"]'::jsonb,'Fa♯','Después de Mi viene Fa♯ en la escala de Sol mayor.'),
 (v_game.id,2,'beginner','c-scale-a','¿Qué conjunto corresponde a la escala de Do mayor?','["Do–Re–Mi–Fa–Sol–La–Si","Do–Re–Mi♭–Fa–Sol–La–Si♭","Do–Re–Mi–Fa♯–Sol–La–Si","Do–Mi–Sol–Si–Re–Fa–La"]'::jsonb,'Do–Re–Mi–Fa–Sol–La–Si','Do mayor no tiene alteraciones en su armadura.'),
 (v_game.id,2,'beginner','c-scale-b','¿Qué nota NO pertenece a la escala natural de Do mayor?','["Fa","La","Si","Fa♯"]'::jsonb,'Fa♯','Do mayor utiliza las siete notas naturales.'),
 (v_game.id,3,'beginner','e-scale-a','¿Cuántos sostenidos tiene la tonalidad de Mi mayor?','["Dos","Tres","Cuatro","Cinco"]'::jsonb,'Cuatro','Mi mayor tiene Fa♯, Do♯, Sol♯ y Re♯.'),
 (v_game.id,3,'beginner','e-scale-b','¿Cuál de estas notas está alterada en Mi mayor?','["Fa♯","La","Si","Mi"]'::jsonb,'Fa♯','Mi mayor contiene cuatro sostenidos, incluido Fa♯.'),
 (v_game.id,4,'beginner','g-chord-a','¿Cuál de estos acordes mayores contiene la nota Sol?','["Do–Mi–Sol","Re–Fa♯–La","La–Do♯–Mi","Mi–Sol♯–Si"]'::jsonb,'Do–Mi–Sol','Do mayor contiene las notas Do, Mi y Sol.'),
 (v_game.id,4,'beginner','g-chord-b','Ordena las notas del acorde de Re mayor desde la más grave hasta la más aguda.','["Re–Fa♯–La","Fa♯–La–Re","La–Re–Fa♯","Re–La–Fa♯"]'::jsonb,'Re–Fa♯–La','En estado fundamental, Re mayor se ordena Re, Fa♯ y La.'),
 (v_game.id,0,'intermediate','g-scale-c','¿Qué grado de la escala de Sol mayor es Fa♯?','["Cuarto","Quinto","Sexto","Séptimo"]'::jsonb,'Séptimo','Fa♯ es el séptimo grado de Sol mayor.'),
 (v_game.id,0,'advanced','g-scale-d','¿Qué intervalo separa Mi de Fa♯ en Sol mayor?','["Segunda mayor","Tercera menor","Segunda menor","Tercera mayor"]'::jsonb,'Segunda mayor','Mi–Fa♯ es una segunda mayor.'),
 (v_game.id,1,'intermediate','g-notes-c','¿Qué nota ocupa el sexto grado de Sol mayor?','["Do","Re","Mi","Fa♯"]'::jsonb,'Mi','Los grados son Sol, La, Si, Do, Re, Mi y Fa♯.'),
 (v_game.id,1,'advanced','g-notes-d','¿Qué intervalo hay entre Sol y Fa♯ dentro de la escala?','["Séptima mayor","Séptima menor","Octava justa","Sexta mayor"]'::jsonb,'Séptima mayor','Sol–Fa♯ forma una séptima mayor.'),
 (v_game.id,2,'intermediate','c-scale-c','¿Qué grado de Do mayor corresponde a la nota La?','["Quinto","Sexto","Séptimo","Cuarto"]'::jsonb,'Sexto','La es el sexto grado de Do mayor.'),
 (v_game.id,2,'advanced','c-scale-d','¿Qué intervalo hay entre Si y Do en la escala de Do mayor?','["Segunda mayor","Segunda menor","Tercera menor","Unísono"]'::jsonb,'Segunda menor','Entre Si y Do hay un semitono: segunda menor.'),
 (v_game.id,3,'intermediate','e-scale-c','¿Cuáles son las cuatro alteraciones de Mi mayor?','["Fa♯, Do♯, Sol♯, Re♯","Fa♯, Do♯, Sol♯, La♯","Si♭, Mi♭, La♭, Re♭","Fa♯, Sol♯, La♯, Mi♯"]'::jsonb,'Fa♯, Do♯, Sol♯, Re♯','Mi mayor tiene cuatro sostenidos.'),
 (v_game.id,3,'advanced','e-scale-d','¿Qué tonalidad menor comparte armadura con Mi mayor?','["Do♯ menor","La menor","Fa♯ menor","Si menor"]'::jsonb,'Do♯ menor','Do♯ menor es la relativa menor de Mi mayor.'),
 (v_game.id,4,'intermediate','g-chord-c','¿Qué intervalo hay entre Si y Re en la tríada de Sol mayor?','["Tercera mayor","Tercera menor","Cuarta justa","Quinta justa"]'::jsonb,'Tercera menor','Si–Re es una tercera menor; Sol–Si es la tercera mayor del acorde.'),
 (v_game.id,4,'advanced','g-chord-d','¿Qué inversión de Sol mayor tiene Si en el bajo?','["Estado fundamental","Primera inversión","Segunda inversión","No es una inversión posible"]'::jsonb,'Primera inversión','La primera inversión coloca la tercera del acorde, Si, en el bajo.');

 insert into public.adventure_treasures(game_id) values(v_game.id);
 insert into public.adventure_events(game_id,event_type,message) values(v_game.id,'game_created','Se han abierto las puertas de las Catacumbas de la Guitarra.');
 return jsonb_build_object('id',v_game.id,'code',v_game.code,'title',v_game.title,'status',v_game.status,'difficulty',v_game.difficulty,'created_at',v_game.created_at);
end $$;

create or replace function public.join_adventure_game(p_code text,p_nickname text)
returns jsonb language plpgsql security definer set search_path=public
as $$
declare v_game public.adventure_games; v_player public.adventure_players; v_challenge public.adventure_challenges;
begin
 if auth.uid() is null then raise exception 'No se pudo identificar al aventurero.'; end if;
 if char_length(trim(p_nickname))<1 or char_length(trim(p_nickname))>24 then raise exception 'El nombre debe tener entre 1 y 24 caracteres.'; end if;
 select * into v_game from public.adventure_games where code=upper(trim(p_code));
 if not found or v_game.status='finished' then raise exception 'La partida no existe o ya terminó.'; end if;
 select * into v_player from public.adventure_players where game_id=v_game.id and user_id=auth.uid();
 if not found then
  select * into v_challenge from public.adventure_challenges where game_id=v_game.id and room_index=0 and (v_game.difficulty='mixed' or difficulty=v_game.difficulty) order by random() limit 1;
  insert into public.adventure_players(game_id,user_id,nickname,challenge_id) values(v_game.id,auth.uid(),trim(p_nickname),v_challenge.id) returning * into v_player;
  insert into public.adventure_events(game_id,actor_player_id,event_type,message) values(v_game.id,v_player.id,'player_joined',v_player.nickname||' se ha unido a la expedición.');
 else
  if v_game.status='active' and v_player.last_seen_at < now()-interval '3 minutes' then
   update public.adventure_players set eliminated=true,errors=3,last_seen_at=now(),disconnected_at=now() where id=v_player.id returning * into v_player;
   insert into public.adventure_events(game_id,actor_player_id,event_type,message) values(v_game.id,v_player.id,'reconnect_expired',v_player.nickname||' perdió la conexión durante más de tres minutos y quedó fuera de la expedición.');
  else
   update public.adventure_players set nickname=trim(p_nickname),last_seen_at=now(),disconnected_at=null where id=v_player.id returning * into v_player;
  end if;
  select * into v_challenge from public.adventure_challenges where id=v_player.challenge_id;
 end if;
 return jsonb_build_object('game',jsonb_build_object('id',v_game.id,'code',v_game.code,'title',v_game.title,'status',v_game.status,'difficulty',v_game.difficulty,'created_at',v_game.created_at),'player_id',v_player.id,'challenge',case when v_challenge.id is null then null else public.adventure_get_challenge(v_challenge.id) end,'room_index',v_player.room_index,'errors',v_player.errors,'eliminated',v_player.eliminated);
end $$;

create or replace function public.start_adventure_game(p_game_id uuid)
returns void language plpgsql security definer set search_path=public
as $$
begin
 update public.adventure_games set status='active',updated_at=now() where id=p_game_id and owner_id=auth.uid() and public.is_authorized_teacher() and status='lobby';
 if not found then raise exception 'No puedes iniciar esta partida.'; end if;
 insert into public.adventure_events(game_id,event_type,message) values(p_game_id,'game_started','¡El maestro del juego ha abierto las catacumbas!');
end $$;

create or replace function public.submit_adventure_answer(p_game_id uuid,p_answer text)
returns jsonb language plpgsql security definer set search_path=public
as $$
declare
 v_player public.adventure_players;
 v_game public.adventure_games;
 v_challenge public.adventure_challenges;
 v_next public.adventure_challenges;
 v_correct boolean;
 v_message text;
begin
 select * into v_player
 from public.adventure_players
 where game_id=p_game_id and user_id=auth.uid()
 for update;
 if not found then raise exception 'No formas parte de esta expedición.'; end if;

 select * into v_game from public.adventure_games where id=p_game_id;
 if v_game.status<>'active' or v_player.eliminated or v_player.room_index>=5 then
  raise exception 'No puedes responder en este momento.';
 end if;

 select * into v_challenge
 from public.adventure_challenges
 where id=v_player.challenge_id and game_id=p_game_id;
 if not found then raise exception 'No se encontró el desafío asignado.'; end if;

 if not exists(
  select 1 from jsonb_array_elements_text(v_challenge.options) o(value)
  where value=p_answer
 ) then raise exception 'La opción elegida no es válida.'; end if;

 v_correct:=p_answer=v_challenge.correct_answer;

 -- A normal room question can be retried. Keep only the latest attempt for this challenge.
 insert into public.adventure_answers(game_id,player_id,challenge_id,selected_answer,is_correct)
 values(p_game_id,v_player.id,v_challenge.id,p_answer,v_correct)
 on conflict(player_id,challenge_id) do update
 set selected_answer=excluded.selected_answer,
     is_correct=excluded.is_correct,
     answered_at=now();

 if v_correct then
  update public.adventure_players
  set room_index=room_index+1,challenge_id=null,last_seen_at=now()
  where id=v_player.id returning * into v_player;

  if v_player.room_index<5 then
   select * into v_next
   from public.adventure_challenges
   where game_id=p_game_id and room_index=v_player.room_index
     and (v_game.difficulty='mixed' or difficulty=v_game.difficulty)
   order by random() limit 1;
   if not found then raise exception 'No hay desafíos configurados para la siguiente sala.'; end if;
   update public.adventure_players set challenge_id=v_next.id
   where id=v_player.id returning * into v_player;
   v_message:='¡Correcto! Has abierto la puerta y avanzas a la siguiente sala.';
  else
   v_message:='¡Has superado las cinco salas! La cámara del tesoro está abierta.';
  end if;

  insert into public.adventure_events(game_id,actor_player_id,event_type,message)
  values(p_game_id,v_player.id,'room_cleared',v_player.nickname||' ha superado la sala '||v_player.room_index||'.');
 else
  if v_challenge.challenge_type in ('enemy','trap') then
   update public.adventure_players
   set errors=least(errors+1,3),
       eliminated=(errors+1>=3),
       last_seen_at=now()
   where id=v_player.id returning * into v_player;

   if v_player.eliminated then
    v_message:='Respuesta incorrecta. Has perdido tu última vida y quedas eliminado. Puedes observar la partida.';
   else
    v_message:='Respuesta incorrecta. Has perdido una vida. Te quedan '||(3-v_player.errors)||'.';
   end if;
   insert into public.adventure_events(game_id,actor_player_id,event_type,message)
   values(p_game_id,v_player.id,
     case when v_player.eliminated then 'player_eliminated' else 'life_lost' end,
     case when v_player.eliminated then v_player.nickname||' ha quedado eliminado.'
          else v_player.nickname||' ha perdido una vida.' end);
  else
   update public.adventure_players set last_seen_at=now()
   where id=v_player.id returning * into v_player;
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
  'message',v_message
 );
end $$;

create or replace function public.claim_adventure_treasure(p_game_id uuid)
returns jsonb language plpgsql security definer set search_path=public
as $$
declare
 v_player public.adventure_players;
 v_game public.adventure_games;
 v_t public.adventure_treasures;
begin
 select * into v_player
 from public.adventure_players
 where game_id=p_game_id and user_id=auth.uid()
 for update;
 if not found or v_player.eliminated or v_player.room_index<5 then
  raise exception 'Debes superar las cinco salas para reclamar el tesoro.';
 end if;

 select * into v_game from public.adventure_games where id=p_game_id;
 if not found or v_game.status<>'active' then
  raise exception 'La aventura ya no está activa.';
 end if;

 update public.adventure_treasures
 set claimed_by=v_player.id,claimed_at=now(),available=false
 where game_id=p_game_id and available=true and claimed_by is null
 returning * into v_t;
 if not found then
  return jsonb_build_object('claimed',false,'message','Otro aventurero ya reclamó el tesoro.');
 end if;

 insert into public.adventure_inventory(game_id,player_id,item_key,label,description)
 values(p_game_id,v_player.id,v_t.item_key,v_t.label,v_t.description)
 on conflict(player_id,item_key) do update
 set quantity=public.adventure_inventory.quantity+1;

 update public.adventure_players set finished_at=now() where id=v_player.id;
 insert into public.adventure_events(game_id,actor_player_id,event_type,message)
 values(p_game_id,v_player.id,'treasure_claimed',v_player.nickname||' ha reclamado el tesoro: '||v_t.label||'.');
 return jsonb_build_object('claimed',true,'message','¡Has reclamado el tesoro! '||v_t.label,'item_label',v_t.label);
end $$;

create or replace function public.adventure_heartbeat(p_game_id uuid)
returns void language plpgsql security definer set search_path=public
as $$
declare
 v_player public.adventure_players;
 v_game public.adventure_games;
begin
 select * into v_player
 from public.adventure_players
 where game_id=p_game_id and user_id=auth.uid()
 for update;
 if not found then raise exception 'No perteneces a esta partida.'; end if;

 select * into v_game from public.adventure_games where id=p_game_id;
 if not found then raise exception 'La partida ya no existe.'; end if;

 -- The three-minute reconnect grace applies only after the teacher starts the adventure.
 if v_game.status='active'
    and v_player.last_seen_at < now()-interval '3 minutes'
    and not v_player.eliminated then
  update public.adventure_players
  set eliminated=true,errors=3,disconnected_at=now()
  where id=v_player.id;
  insert into public.adventure_events(game_id,actor_player_id,event_type,message)
  values(p_game_id,v_player.id,'reconnect_expired',
    v_player.nickname||' perdió la conexión durante más de tres minutos y quedó fuera de la expedición.');
  return;
 end if;

 update public.adventure_players
 set last_seen_at=now(),disconnected_at=null
 where id=v_player.id;
end $$;

create or replace function public.adventure_teacher_action(p_game_id uuid,p_action text,p_payload jsonb default '{}'::jsonb)
returns jsonb language plpgsql security definer set search_path=public
as $$
declare v_player public.adventure_players; v_item text; v_label text; v_msg text;
begin
 if not exists(select 1 from public.adventure_games where id=p_game_id and owner_id=auth.uid()) or not public.is_authorized_teacher() then raise exception 'No tienes permisos de maestro del juego.'; end if;
 if p_action='announce' then
  v_msg:=left(coalesce(p_payload->>'message',''),240); if v_msg='' then raise exception 'Escribe un anuncio.'; end if;
  insert into public.adventure_events(game_id,event_type,message) values(p_game_id,'announcement',v_msg);
 elsif p_action='gift' then
  select * into v_player from public.adventure_players where id=(p_payload->>'player_id')::uuid and game_id=p_game_id;
  if not found then raise exception 'Selecciona un estudiante válido.'; end if;
  v_item:=coalesce(p_payload->>'item_key','teacher_gift');v_label:=coalesce(p_payload->>'label','Regalo del maestro');
  insert into public.adventure_inventory(game_id,player_id,item_key,label,description) values(p_game_id,v_player.id,v_item,v_label,coalesce(p_payload->>'description','Regalo del maestro del juego'))
  on conflict(player_id,item_key) do update set quantity=public.adventure_inventory.quantity+1;
  insert into public.adventure_events(game_id,actor_player_id,event_type,message) values(p_game_id,v_player.id,'gift',v_player.nickname||' ha recibido: '||v_label||'.');
 elsif p_action='revive' then
  update public.adventure_players set eliminated=false,errors=0,challenge_id=(select c.id from public.adventure_challenges c where c.game_id=p_game_id and c.room_index=adventure_players.room_index and (c.difficulty=(select g.difficulty from public.adventure_games g where g.id=p_game_id) or (select g.difficulty from public.adventure_games g where g.id=p_game_id)='mixed') order by random() limit 1),last_seen_at=now()
  where id=(p_payload->>'player_id')::uuid and game_id=p_game_id;
  if not found then raise exception 'No se encontró al estudiante.'; end if;
  insert into public.adventure_events(game_id,event_type,message) values(p_game_id,'revival','El maestro del juego ha devuelto a un aventurero a la expedición.');
 elsif p_action='remove_item' then
  delete from public.adventure_inventory where player_id=(p_payload->>'player_id')::uuid and game_id=p_game_id and item_key=coalesce(p_payload->>'item_key','teacher_gift');
  insert into public.adventure_events(game_id,event_type,message) values(p_game_id,'item_removed','El maestro del juego ha retirado un objeto.');
 elsif p_action='spawn_treasure' then
  update public.adventure_treasures set available=true,claimed_by=null,claimed_at=null where game_id=p_game_id;
  insert into public.adventure_events(game_id,event_type,message) values(p_game_id,'treasure_spawned','¡Ha aparecido un tesoro en las catacumbas!');
 elsif p_action='summon_enemy' then
  insert into public.adventure_enemies(game_id,room_index,name,weakness) values(p_game_id,0,'Guardián de las cuerdas','Escalas y acordes');
  insert into public.adventure_events(game_id,event_type,message) values(p_game_id,'enemy_summoned','¡Un guardián musical ha aparecido en las catacumbas!');
 elsif p_action='end_game' then
  update public.adventure_games set status='finished',updated_at=now() where id=p_game_id;
  insert into public.adventure_events(game_id,event_type,message) values(p_game_id,'game_finished','El maestro del juego ha finalizado la partida.');
 else raise exception 'Acción de maestro desconocida.'; end if;
 return jsonb_build_object('success',true,'action',p_action);
end $$;

revoke all on function public.adventure_get_challenge(uuid) from public,anon,authenticated;
revoke all on function public.create_adventure_game(text,text),public.join_adventure_game(text,text),public.start_adventure_game(uuid),public.submit_adventure_answer(uuid,text),public.claim_adventure_treasure(uuid),public.adventure_heartbeat(uuid),public.adventure_teacher_action(uuid,text,jsonb) from public,anon;
grant execute on function public.create_adventure_game(text,text),public.join_adventure_game(text,text),public.start_adventure_game(uuid),public.submit_adventure_answer(uuid,text),public.claim_adventure_treasure(uuid),public.adventure_heartbeat(uuid),public.adventure_teacher_action(uuid,text,jsonb) to authenticated;

do $$ begin alter publication supabase_realtime add table public.adventure_games; exception when duplicate_object then null; end $$;
do $$ begin alter publication supabase_realtime add table public.adventure_players; exception when duplicate_object then null; end $$;
do $$ begin alter publication supabase_realtime add table public.adventure_events; exception when duplicate_object then null; end $$;
