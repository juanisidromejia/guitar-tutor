import { requireSupabase } from '../../services/supabase'
import type { AdventureAnswerResult, AdventureChallenge, AdventureDifficulty, AdventureGame, AdventureJoinResult, AdventurePlayer, AdventureEvent, AdventureInventoryItem, AdventureEnemy, AdventurePlayerState } from './types'

const db = () => requireSupabase()
export async function createAdventure(title:string,difficulty:AdventureDifficulty) {
  const {data,error}=await db().rpc('create_adventure_game',{p_title:title,p_difficulty:difficulty})
  if(error) throw error
  return data as AdventureGame
}
export async function joinAdventure(code:string,nickname:string) {
  const {data,error}=await db().rpc('join_adventure_game',{p_code:code,p_nickname:nickname})
  if(error) throw error
  return data as AdventureJoinResult
}
export async function startAdventure(gameId:string) {
  const {error}=await db().rpc('start_adventure_game',{p_game_id:gameId})
  if(error) throw error
}
export async function attackAdventureEnemy(gameId:string,enemyId:string,answer:string) {
  const {data,error}=await db().rpc('attack_adventure_enemy',{p_game_id:gameId,p_enemy_id:enemyId,p_answer:answer})
  if(error) throw error
  return data as AdventureAnswerResult
}
export async function submitAdventureAnswer(gameId:string,answer:string) {
  const {data,error}=await db().rpc('submit_adventure_answer',{p_game_id:gameId,p_answer:answer})
  if(error) throw error
  return data as AdventureAnswerResult
}
export async function claimAdventureTreasure(gameId:string) {
  const {data,error}=await db().rpc('claim_adventure_treasure',{p_game_id:gameId})
  if(error) throw error
  return data as {claimed:boolean;message:string;item_label?:string}
}
export async function sendAdventureHeartbeat(gameId:string) {
  const {error}=await db().rpc('adventure_heartbeat',{p_game_id:gameId})
  if(error) throw error
}
export async function teacherAction(gameId:string,action:string,payload:Record<string,unknown>={}) {
  const {data,error}=await db().rpc('adventure_teacher_action',{p_game_id:gameId,p_action:action,p_payload:payload})
  if(error) throw error
  return data
}
export async function loadAdventurePlayerState(gameId:string) {
  const {data,error}=await db().rpc('adventure_get_player_state',{p_game_id:gameId})
  if(error) throw error
  return data as AdventurePlayerState
}
export async function loadAdventureEnemies(gameId:string) {
  const {data,error}=await db().from('adventure_enemies').select('id,room_index,name,weakness,health,max_health,status').eq('game_id',gameId).order('created_at',{ascending:false})
  if(error) throw error
  return (data??[]) as AdventureEnemy[]
}
export async function loadAdventurePlayers(gameId:string) {
  const {data,error}=await db().from('adventure_players').select('id,nickname,room_index,errors,eliminated,finished_at,last_seen_at').eq('game_id',gameId).order('joined_at')
  if(error) throw error
  return (data??[]) as AdventurePlayer[]
}
export async function loadAdventureEvents(gameId:string) {
  const {data,error}=await db().from('adventure_events').select('id,event_type,message,created_at').eq('game_id',gameId).order('created_at',{ascending:false}).limit(30)
  if(error) throw error
  return (data??[]) as AdventureEvent[]
}
export async function loadAdventureInventory(playerId:string) {
  const {data,error}=await db().from('adventure_inventory').select('id,item_key,label,description,quantity').eq('player_id',playerId)
  if(error) throw error
  return (data??[]) as AdventureInventoryItem[]
}
export function subscribeAdventure(gameId:string,onChange:()=>void) {
  return db().channel('adventure-'+gameId)
    .on('postgres_changes',{event:'*',schema:'public',table:'adventure_players',filter:'game_id=eq.'+gameId},onChange)
    .on('postgres_changes',{event:'*',schema:'public',table:'adventure_events',filter:'game_id=eq.'+gameId},onChange)
    .on('postgres_changes',{event:'*',schema:'public',table:'adventure_enemies',filter:'game_id=eq.'+gameId},onChange)
    .on('postgres_changes',{event:'*',schema:'public',table:'adventure_games',filter:'id=eq.'+gameId},onChange)
    .subscribe()
}
export function removeAdventureSubscription(channel:ReturnType<typeof subscribeAdventure>) { void db().removeChannel(channel) }
export type { AdventureChallenge, AdventureDifficulty, AdventureGame, AdventureJoinResult, AdventurePlayer, AdventureEvent, AdventureInventoryItem, AdventureEnemy, AdventurePlayerState }
