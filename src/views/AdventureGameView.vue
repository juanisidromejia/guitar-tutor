<script setup lang="ts">
import { computed, onMounted, onUnmounted, ref } from 'vue'
import { RouterLink, useRoute } from 'vue-router'
import { ArrowLeft, BookOpen, CheckCircle2, Clock3, Gem, Heart, LogOut, RefreshCw, ShieldAlert, Skull, Sparkles, Swords, Users } from 'lucide-vue-next'
import { isSupabaseConfigured, requireSupabase } from '../services/supabase'
import { joinAdventure, submitAdventureAnswer, attackAdventureEnemy, claimAdventureTreasure, sendAdventureHeartbeat, teacherAction, loadAdventurePlayers, loadAdventureEvents, loadAdventureInventory, loadAdventureEnemies, loadAdventurePlayerState, useAdventureItem, subscribeAdventure, removeAdventureSubscription } from '../modules/adventure/adventureService'
import type { AdventureDifficulty, AdventureGame, AdventureChallenge, AdventurePlayer, AdventureEvent, AdventureInventoryItem, AdventureEnemy } from '../modules/adventure/types'

const route=useRoute()
const role=ref<'teacher'|'player'>('player')
const code=ref(''),nickname=ref(''),sessionId=ref(''),game=ref<AdventureGame|null>(null),playerId=ref('')
const challenge=ref<AdventureChallenge|null>(null),roomIndex=ref(0),errors=ref(0),eliminated=ref(false),completed=ref(false)
const players=ref<AdventurePlayer[]>([]),events=ref<AdventureEvent[]>([]),inventory=ref<AdventureInventoryItem[]>([]),enemies=ref<AdventureEnemy[]>([])
const activeEnemies=computed(()=>enemies.value.filter(e=>e.room_index===roomIndex.value&&e.status==='active'))
const roomPlayers=computed(()=>players.value.filter(p=>p.room_index===(role.value==='teacher'?selectedRoom.value:roomIndex.value)))
const busy=ref(false),message=ref(''),announcement=ref('')
const teacherGift=ref('health_potion'),giftTarget=ref(''),eventText=ref(''),selectedRoom=ref(0),selectedEnemyType=ref('specter')
let channel:any=null,heartbeat:ReturnType<typeof setInterval>|undefined,refreshTimer:ReturnType<typeof setInterval>|undefined
const roomNames=['La puerta de las notas','El corredor de Sol mayor','La cámara de Do mayor','La sala de Mi mayor','El puente de los acordes','El tesoro de las catacumbas']
function difficultyName(v:AdventureDifficulty){return ({beginner:'Principiante',intermediate:'Intermedio',advanced:'Avanzado',mixed:'Mixto'} as const)[v]}
async function refresh(){
 if(!game.value)return
 try{players.value=await loadAdventurePlayers(game.value.id);events.value=await loadAdventureEvents(game.value.id);enemies.value=await loadAdventureEnemies(game.value.id);if(playerId.value){inventory.value=await loadAdventureInventory(playerId.value);const state=await loadAdventurePlayerState(game.value.id);challenge.value=state.challenge;roomIndex.value=state.room_index;errors.value=state.errors;eliminated.value=state.eliminated;completed.value=Boolean(state.finished_at)}
 const {data}=await requireSupabase().from('adventure_games').select('id,code,title,status,difficulty,created_at').eq('id',game.value.id).single();if(data)game.value=data as AdventureGame
 const mine=players.value.find(p=>p.id===playerId.value);if(mine&&!playerId.value){roomIndex.value=mine.room_index;errors.value=mine.errors;eliminated.value=mine.eliminated;completed.value=Boolean(mine.finished_at)}
 }catch(e){message.value=e instanceof Error?e.message:'No se pudo actualizar la partida.'}
}
function listen(){if(!game.value)return;if(channel)removeAdventureSubscription(channel);channel=subscribeAdventure(game.value.id,()=>void refresh());if(refreshTimer)clearInterval(refreshTimer);refreshTimer=setInterval(()=>void refresh(),12000)}
async function joinGame(){busy.value=true;message.value='';try{const db=requireSupabase();const {data:s}=await db.auth.getSession();if(!s.session){const {error}=await db.auth.signInAnonymously();if(error)throw error}const result=await joinAdventure(code.value,nickname.value);game.value=result.game;playerId.value=result.player_id;challenge.value=result.challenge;roomIndex.value=result.room_index;errors.value=result.errors;eliminated.value=result.eliminated;role.value='player';await refresh();listen();heartbeat=setInterval(()=>{if(game.value)void sendAdventureHeartbeat(game.value.id).catch(()=>{})},45000)}catch(e){message.value=e instanceof Error?e.message:'No se pudo ingresar a la aventura.'}finally{busy.value=false}}
async function begin(){if(!sessionId.value)return;busy.value=true;try{const {error}=await requireSupabase().rpc('start_class_session',{p_session_id:sessionId.value});if(error)throw error;await refresh();message.value='¡Las catacumbas se han abierto!'}catch(e){message.value=e instanceof Error?e.message:'No se pudo iniciar la partida.'}finally{busy.value=false}}
async function applyAnswerResult(result:any){challenge.value=result.challenge;roomIndex.value=result.room_index;errors.value=result.errors;eliminated.value=result.eliminated;completed.value=result.completed;message.value=result.message;await refresh()}
async function answer(option:string){if(!game.value||busy.value)return;busy.value=true;message.value='';try{const result=await submitAdventureAnswer(game.value.id,option);await applyAnswerResult(result)}catch(e){message.value=e instanceof Error?e.message:'No se pudo registrar la respuesta.'}finally{busy.value=false}}
async function attack(enemyId:string,option:string){if(!game.value||busy.value)return;busy.value=true;message.value='';try{const result=await attackAdventureEnemy(game.value.id,enemyId,option);await applyAnswerResult(result)}catch(e){message.value=e instanceof Error?e.message:'No se pudo enviar el ataque.'}finally{busy.value=false}}
async function useItem(item:AdventureInventoryItem){if(!game.value||busy.value)return;busy.value=true;message.value='';try{const result=await useAdventureItem(game.value.id,item.id);message.value=result.message;await refresh()}catch(e){message.value=e instanceof Error?e.message:'No se pudo utilizar el objeto.'}finally{busy.value=false}}
async function claimTreasure(){if(!game.value)return;busy.value=true;try{const r=await claimAdventureTreasure(game.value.id);message.value=r.message;await refresh()}catch(e){message.value=e instanceof Error?e.message:'No se pudo reclamar el tesoro.'}finally{busy.value=false}}
async function action(name:string,payload:Record<string,unknown>={}){if(!game.value)return;busy.value=true;try{if(name==='end_game'&&sessionId.value){const {error}=await requireSupabase().rpc('finish_class_session',{p_session_id:sessionId.value});if(error)throw error}else await teacherAction(game.value.id,name,payload);await refresh();message.value=name==='end_game'?'La aventura ha finalizado.':'Acción del maestro del juego ejecutada.'}catch(e){message.value=e instanceof Error?e.message:'No se pudo ejecutar la acción.'}finally{busy.value=false}}
async function summonEnemy(){await action('summon_enemy',{room_index:selectedRoom.value,enemy_type:selectedEnemyType.value})}
async function announce(){if(!eventText.value.trim())return;await action('announce',{message:eventText.value.trim()});eventText.value=''}
async function giveGift(){if(!giftTarget.value)return;await action('gift',{player_id:giftTarget.value,item_key:teacherGift.value,label:'Poción de vida',description:'Recupera una vida perdida al utilizarla.'});giftTarget.value=''}
async function logout(){if(channel)removeAdventureSubscription(channel);channel=null;if(heartbeat)clearInterval(heartbeat);if(refreshTimer)clearInterval(refreshTimer);game.value=null;playerId.value='';challenge.value=null;players.value=[];events.value=[];inventory.value=[];enemies.value=[];message.value='Has salido de la vista de partida.'}
onMounted(async()=>{if(!isSupabaseConfigured){message.value='Conecta Supabase para habilitar las partidas compartidas.';return}try{const gameId=String(route.query.gameId??'');sessionId.value=String(route.query.sessionId??'');if(route.query.role==='teacher'&&gameId){const {data,error}=await requireSupabase().from('adventure_games').select('id,code,title,status,difficulty,created_at').eq('id',gameId).single();if(error)throw error;game.value=data as AdventureGame;role.value='teacher';await refresh();listen();return}const incomingCode=String(route.query.code??'');const incomingNickname=String(route.query.nickname??'');if(incomingCode&&incomingNickname){code.value=incomingCode;nickname.value=incomingNickname;await joinGame();return}message.value='Esta actividad se abre desde el código habitual de una sesión de Guitar Tutor.'}catch(e){message.value=e instanceof Error?e.message:'No se pudo abrir la actividad.'}})
onUnmounted(()=>{if(channel)removeAdventureSubscription(channel);if(heartbeat)clearInterval(heartbeat);if(refreshTimer)clearInterval(refreshTimer)})
</script>
<template>
<div class="page">
 <div class="mb-6 flex items-center gap-3"><RouterLink to="/" class="secondary"><ArrowLeft :size="17"/></RouterLink><div><p class="eyebrow">Modo aventura · multijugador</p><h1 class="text-2xl font-black sm:text-3xl">Catacumbas de la Guitarra</h1></div></div>
 <section v-if="!isSupabaseConfigured" class="panel p-6"><h2 class="text-xl font-black">Aventura en preparación</h2><p class="mt-2 text-sm text-[#718078]">La partida compartida necesita Supabase y la migración de aventura.</p></section>
 <section v-else-if="!game" class="panel mx-auto max-w-xl p-6 text-center"><p class="text-sm text-[#718078]">{{message||'Preparando la actividad…'}}</p></section>
 <template v-else>
  <section class="panel mb-4 flex flex-wrap items-center justify-between gap-3 p-4"><div><p class="eyebrow">{{game.status==='lobby'?'Sala de espera':game.status==='active'?'Aventura en curso':'Partida finalizada'}}</p><h2 class="text-lg font-black">{{game.title}}</h2><p class="text-xs text-[#718078]">Código: <b class="tracking-widest">{{game.code}}</b> · {{difficultyName(game.difficulty)}}</p></div><div class="flex gap-2"><button class="secondary" @click="refresh"><RefreshCw :size="16"/></button><button class="secondary" @click="logout"><LogOut :size="16"/> Salir</button></div></section>
  <div class="grid gap-4 lg:grid-cols-[1fr_300px]">
   <div class="space-y-4">
    <section class="panel p-5 sm:p-6">
     <div v-if="role==='player'" class="flex items-center justify-between gap-3"><div><p class="eyebrow">Tu recorrido</p><h3 class="text-xl font-black">{{challenge?.room_title??roomNames[Math.min(roomIndex,5)]}}</h3></div><span class="rounded-full bg-[#edf4ee] px-3 py-1.5 text-xs font-bold text-[#34745b]">Sala {{Math.min(roomIndex+1,6)}} / 6</span></div>
     <div v-if="role==='player'" class="mt-4 flex gap-1.5"><div v-for="(name,i) in roomNames" :key="name" class="h-2 flex-1 rounded-full" :class="i<roomIndex?'bg-[#398568]':i===roomIndex?'bg-[#b6d9c1]':'bg-[#e7ece7]'"/></div>
     <div v-if="role==='teacher'" class="rounded-xl bg-[#edf4ee] p-4">
      <p class="text-sm font-bold text-[#28684f]">Panel del maestro del juego</p><p class="mt-1 text-xs text-[#718078]">Administra la partida completa. Puedes intervenir en cualquier sala y en cualquier estudiante, sin desplazarte con la expedición.</p>
      <button v-if="game.status==='lobby'" class="primary mt-3" :disabled="busy" @click="begin">Abrir las catacumbas</button>
      <div class="mt-4 border-t border-[#d7e5d9] pt-4">
       <p class="text-xs font-extrabold uppercase tracking-wide text-[#527563]">Eventos de sala</p>
       <label class="mt-2 block text-xs font-bold">Sala objetivo</label><select v-model.number="selectedRoom" class="mt-1 w-full rounded-xl border border-[#dce6dd] bg-white px-3 py-2 text-sm"><option v-for="(name,i) in roomNames.slice(0,5)" :key="i" :value="i">Sala {{i+1}} · {{name}}</option></select>
       <label class="mt-3 block text-xs font-bold">Tipo de enemigo</label><select v-model="selectedEnemyType" class="mt-1 w-full rounded-xl border border-[#dce6dd] bg-white px-3 py-2 text-sm"><option value="skeleton">Esqueleto del pentagrama · Principiante</option><option value="specter">Espectro armónico · Intermedio</option><option value="dragon">Dragón cromático · Avanzado</option><option value="random">Enemigo aleatorio</option></select>
       <button class="secondary mt-3 w-full justify-center" :disabled="busy" @click="summonEnemy"><Swords :size="15"/> Invocar enemigo en esta sala</button>
       <button class="secondary mt-2 w-full justify-center" :disabled="busy" @click="action('spawn_treasure')"><Gem :size="15"/> Habilitar tesoro de la cámara final</button>
       <p class="mt-2 text-[11px] text-[#718078]">El enemigo se asigna a la sala elegida. El tesoro, por ahora, es global y se reclama en la cámara final.</p>
      </div>
      <div class="mt-4 border-t border-[#d7e5d9] pt-4">
       <p class="text-xs font-extrabold uppercase tracking-wide text-[#527563]">Acciones sobre estudiantes</p>
       <label class="mt-2 block text-xs font-bold">Estudiante objetivo</label><select v-model="giftTarget" class="mt-1 w-full rounded-xl border border-[#dce6dd] bg-white px-3 py-2 text-sm"><option value="">Seleccionar estudiante</option><option v-for="p in players" :key="p.id" :value="p.id">{{p.nickname}}</option></select>
       <div class="mt-3 grid gap-2 sm:grid-cols-2"><button class="secondary justify-center" :disabled="!giftTarget||busy" @click="action('revive',{player_id:giftTarget})"><Heart :size="15"/> Revivir</button><button class="secondary justify-center" :disabled="!giftTarget||busy" @click="action('remove_item',{player_id:giftTarget,item_key:'health_potion'})"><ShieldAlert :size="15"/> Retirar regalo</button></div>
       <div class="mt-3 flex gap-2"><select v-model="teacherGift" class="min-w-0 flex-1 rounded-xl border border-[#dce6dd] bg-white px-3 py-2 text-sm"><option value="health_potion">Poción de vida</option></select><button class="secondary" :disabled="!giftTarget||busy" @click="giveGift">Entregar</button></div>
      </div>
      <div class="mt-4 border-t border-[#d7e5d9] pt-4">
       <p class="text-xs font-extrabold uppercase tracking-wide text-[#527563]">Comunicación</p><div class="mt-2 flex gap-2"><input v-model="eventText" class="min-w-0 flex-1 rounded-xl border border-[#dce6dd] px-3 py-2 text-sm" placeholder="Anuncio para el grupo"/><button class="secondary" :disabled="!eventText.trim()||busy" @click="announce">Anunciar</button></div>
      </div>
      <button class="mt-4 rounded-xl bg-[#8e3e36] px-4 py-2 text-sm font-bold text-white" :disabled="busy" @click="action('end_game')">Finalizar partida</button>
     </div>
     <div v-else-if="game.status==='lobby'" class="py-8 text-center"><Clock3 class="mx-auto text-[#7c9185]" :size="34"/><h3 class="mt-3 font-bold">Esperando al maestro del juego</h3><p class="mt-1 text-sm text-[#718078]">Cuando comience la partida aparecerá tu primer desafío.</p></div>
     <div v-else-if="eliminated" class="py-8 text-center"><Skull class="mx-auto text-[#9b4f3c]" :size="40"/><h3 class="mt-3 text-xl font-black">Has quedado fuera de la expedición</h3><p class="mt-2 text-sm text-[#718078]">Puedes seguir observando el recorrido de tus compañeros. El docente puede concederte una nueva oportunidad.</p></div>
     <div v-else-if="completed||roomIndex>=5" class="py-8 text-center"><Gem class="mx-auto text-[#b58a3a]" :size="42"/><h3 class="mt-3 text-2xl font-black">¡Has llegado a la cámara del tesoro!</h3><p class="mt-2 text-sm text-[#718078]">El tesoro es compartido: el primer aventurero que lo reclame lo obtiene.</p><button class="primary mt-4" :disabled="busy" @click="claimTreasure">Reclamar tesoro</button></div>
     <div v-else-if="challenge" class="mt-5">
      <p class="text-sm text-[#718078]">{{challenge.room_description}}</p>
      <div v-if="activeEnemies.length" class="mt-4 space-y-4">
       <p class="text-sm font-bold text-[#8c4936]">¡Combate! Elige a qué enemigo atacar. Cada respuesta se envía automáticamente.</p>
       <article v-for="enemy in activeEnemies" :key="enemy.id" class="rounded-2xl border border-[#d7b6a2] bg-[#fff7f1] p-4">
        <div class="flex items-center justify-between gap-3"><div class="flex items-center gap-2"><Swords class="text-[#a34e35]" :size="20"/><div><p class="eyebrow text-[#a34e35]">{{difficultyName(enemy.difficulty)}} · Sala {{enemy.room_index+1}}</p><h4 class="font-black text-[#60392e]">{{enemy.name}}</h4><p class="mt-1 text-xs text-[#8c6254]">{{enemy.weakness}}</p></div></div><span class="rounded-full bg-white px-3 py-1 text-sm font-black text-[#8c4936]">{{enemy.health}} / {{enemy.max_health}} HP</span></div>
        <div class="mt-3 h-3 overflow-hidden rounded-full bg-[#ead8ce]"><div class="h-full rounded-full bg-[#b95c43] transition-all duration-500" :style="{width:Math.max(0,Math.min(100,(enemy.health/enemy.max_health)*100))+'%'}"/></div>
        <p class="mt-3 text-sm font-bold text-[#60392e]">{{enemy.challenge?.prompt??'Preparando pregunta…'}}</p>
        <div v-if="enemy.challenge?.options?.length" class="mt-3 grid gap-2 sm:grid-cols-2"><button v-for="(option,i) in enemy.challenge.options" :key="option" class="rounded-xl border border-[#e5cfc2] bg-white p-3 text-left text-sm font-bold hover:border-[#b95c43] disabled:opacity-50" :disabled="busy" @click="attack(enemy.id,option)"><b class="mr-2 text-[#a34e35]">{{String.fromCharCode(65+i)}}.</b>{{option}}</button></div>
       </article>
      </div>
      <div v-else class="mt-4 rounded-2xl border border-[#e6ebe5] bg-[#fbfcfa] p-5">
       <p class="eyebrow">Desafío de la puerta</p><h4 class="mt-2 text-lg font-black">{{challenge.prompt}}</h4>
       <p class="mt-1 text-xs text-[#718078]">La sala está libre. Elige la respuesta correcta para abrir la puerta.</p>
       <div class="mt-4 grid gap-2 sm:grid-cols-2"><button v-for="(option,i) in challenge.options" :key="option" class="rounded-xl border border-[#e1e9e2] bg-white p-3 text-left text-sm font-bold hover:border-[#9bb9a6] disabled:opacity-50" :disabled="busy" @click="answer(option)"><b class="mr-2 text-[#8a9b90]">{{String.fromCharCode(65+i)}}.</b>{{option}}</button></div>
      </div>
      <p class="mt-3 flex items-center gap-2 text-sm text-[#718078]"><Heart :size="16" class="text-[#a85a52]"/> Vidas: <b>{{Math.max(0,3-errors)}} / 3</b></p></div>
     <div v-else class="py-8 text-center text-sm text-[#718078]">Esperando el siguiente desafío…</div>
     <p v-if="message" class="mt-4 rounded-xl bg-[#f0f5f0] p-3 text-sm text-[#37644f]" aria-live="polite">{{message}}</p>
    </section>
   </div>
   <aside class="space-y-4"><section class="panel p-4"><div class="flex items-center gap-2"><Users class="text-[#398568]"/><h3 class="font-extrabold">En esta sala</h3><span class="ml-auto text-xs text-[#718078]">{{roomPlayers.length}}</span></div><div class="mt-3 space-y-2"><div v-for="p in roomPlayers" :key="p.id" class="flex items-center gap-2 rounded-xl bg-[#f5f8f5] p-2.5"><span class="grid h-8 w-8 place-items-center rounded-lg bg-[#e5f0e8] text-xs font-black text-[#34745b]">{{p.nickname.slice(0,1).toUpperCase()}}</span><div class="min-w-0 flex-1"><p class="truncate text-sm font-bold">{{p.nickname}}</p><p class="text-[11px] text-[#718078]">{{p.eliminated?'Eliminado':p.finished_at?'Completó':'Sala '+(p.room_index+1)}} · {{Math.max(0,3-p.errors)}} vidas</p></div><Skull v-if="p.eliminated" :size="16" class="text-[#a85a52]"/></div></div></section>
    <section v-if="role==='player'" class="panel p-4"><div class="flex items-center gap-2"><BookOpen class="text-[#398568]"/><h3 class="font-extrabold">Mi inventario</h3></div><p v-if="!inventory.length" class="mt-2 text-xs text-[#718078]">Todavía no tienes objetos. El docente puede entregarte regalos.</p><div v-for="item in inventory" :key="item.id" class="mt-2 rounded-xl bg-[#f5f8f5] p-3"><p class="text-sm font-bold">{{item.label}} <span class="text-xs text-[#718078]">×{{item.quantity}}</span></p><p class="mt-1 text-xs text-[#718078]">{{item.description}}</p><button v-if="item.item_key==='health_potion'" class="secondary mt-3 w-full justify-center" :disabled="busy||errors===0||eliminated" @click="useItem(item)"><Heart :size="15"/> Usar poción · recuperar 1 vida</button></div></section>
    <section class="panel p-4"><div class="flex items-center gap-2"><Sparkles class="text-[#398568]"/><h3 class="font-extrabold">Bitácora</h3></div><div class="mt-3 space-y-3"><div v-for="event in events.slice(0,8)" :key="event.id" class="border-l-2 border-[#b6d9c1] pl-3"><p class="text-xs">{{event.message}}</p><p class="mt-1 text-[10px] text-[#8a9890]">{{new Date(event.created_at).toLocaleTimeString([], {hour:'2-digit',minute:'2-digit'})}}</p></div><p v-if="!events.length" class="text-xs text-[#718078]">Aún no hay eventos.</p></div></section>
   </aside>
  </div>
 </template>
</div>
</template>
