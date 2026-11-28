export type AdventureDifficulty = 'beginner' | 'intermediate' | 'advanced' | 'mixed'
export type AdventureStatus = 'lobby' | 'active' | 'finished'
export type AdventureRole = 'teacher' | 'player'
export interface AdventureGame { id:string; code:string; title:string; status:AdventureStatus; difficulty:AdventureDifficulty; created_at:string }
export interface AdventureChallenge { room_index:number; room_title:string; room_description:string; prompt:string; options:string[]; challenge_id:string; challenge_type?:'normal'|'enemy'|'trap'; }
export interface AdventurePlayer { id:string; nickname:string; room_index:number; errors:number; eliminated:boolean; finished_at:string|null; last_seen_at:string; }
export interface AdventureEvent { id:string; event_type:string; message:string; created_at:string; }
export interface AdventureInventoryItem { id:string; item_key:string; label:string; description:string; quantity:number; }
export interface AdventureEnemy { id:string; room_index:number; name:string; weakness:string; health:number; max_health:number; status:'active'|'defeated'; }
export interface AdventurePlayerState { player_id:string; room_index:number; errors:number; eliminated:boolean; finished_at:string|null; challenge:AdventureChallenge|null; }
export interface AdventureJoinResult { game:AdventureGame; player_id:string; challenge:AdventureChallenge|null; room_index:number; errors:number; eliminated:boolean; }
export interface AdventureAnswerResult { correct:boolean; eliminated:boolean; room_index:number; errors:number; completed:boolean; challenge:AdventureChallenge|null; message:string; }
