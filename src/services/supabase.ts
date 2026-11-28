import { createClient, type SupabaseClient } from '@supabase/supabase-js'

const url = import.meta.env.VITE_SUPABASE_URL
const anonKey = import.meta.env.VITE_SUPABASE_ANON_KEY

export const isSupabaseConfigured = Boolean(url && anonKey)
export const supabase = isSupabaseConfigured
  ? createClient(url, anonKey, {
      auth: { persistSession: true, autoRefreshToken: true, detectSessionInUrl: true },
    })
  : null

export function requireSupabase() {
  if (!supabase) throw new Error('Falta configurar VITE_SUPABASE_URL y VITE_SUPABASE_ANON_KEY.')
  return supabase
}


// Each adventure tab gets an isolated anonymous-auth session. sessionStorage is
// scoped to the tab, so multiple students can share one device and game link.
let adventureClient: SupabaseClient | null = null

export function getAdventureSupabase() {
  if (!url || !anonKey) throw new Error('Falta configurar Supabase para la aventura.')
  if (typeof window === 'undefined') throw new Error('La sesión de aventura solo puede abrirse en el navegador.')
  if (!adventureClient) {
    adventureClient = createClient(url, anonKey, {
      auth: {
        persistSession: true,
        autoRefreshToken: true,
        detectSessionInUrl: false,
        storage: window.sessionStorage,
        storageKey: 'guitar-tutor-adventure-auth',
      },
    })
  }
  return adventureClient
}
