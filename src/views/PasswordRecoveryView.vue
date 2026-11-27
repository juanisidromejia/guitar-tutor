<script setup lang="ts">
import { computed, onMounted, onUnmounted, ref } from 'vue'
import { RouterLink, useRouter } from 'vue-router'
import { ArrowLeft, KeyRound } from 'lucide-vue-next'
import { isSupabaseConfigured, requireSupabase } from '../services/supabase'

const router = useRouter()
const password = ref('')
const confirmation = ref('')
const busy = ref(false)
const ready = ref(false)
const message = ref('')
const error = ref('')
let authSubscription: { unsubscribe: () => void } | undefined

const passwordsMatch = computed(() => password.value === confirmation.value)

async function savePassword() {
  message.value = ''
  error.value = ''
  if (password.value.length < 8) {
    error.value = 'La contraseña debe tener al menos 8 caracteres.'
    return
  }
  if (!passwordsMatch.value) {
    error.value = 'Las contraseñas no coinciden.'
    return
  }

  busy.value = true
  try {
    const { error: updateError } = await requireSupabase().auth.updateUser({ password: password.value })
    if (updateError) throw updateError
    password.value = ''
    confirmation.value = ''
    message.value = 'Contraseña actualizada. Ya puedes entrar al panel docente.'
    window.setTimeout(() => router.replace('/panel-docente'), 1600)
  } catch (e) {
    error.value = e instanceof Error ? e.message : 'No se pudo actualizar la contraseña. Solicita un enlace nuevo.'
  } finally {
    busy.value = false
  }
}

onMounted(async () => {
  if (!isSupabaseConfigured) {
    error.value = 'Supabase no está configurado.'
    return
  }

  const db = requireSupabase()
  const { data } = await db.auth.getSession()
  ready.value = Boolean(data.session)

  const { data: listener } = db.auth.onAuthStateChange((event, session) => {
    if (event === 'PASSWORD_RECOVERY' || session) ready.value = true
    if (!session && event === 'SIGNED_OUT') ready.value = false
  })
  authSubscription = listener.subscription
})

onUnmounted(() => authSubscription?.unsubscribe())
</script>

<template>
  <div class="page">
    <div class="mb-6 flex items-center gap-3">
      <RouterLink to="/panel-docente" class="secondary" aria-label="Volver al acceso docente"><ArrowLeft :size="17" /></RouterLink>
      <div>
        <p class="eyebrow">Cuenta docente</p>
        <h1 class="text-2xl font-black sm:text-3xl">Recuperar contraseña</h1>
      </div>
    </div>

    <section class="panel mx-auto max-w-xl p-6 sm:p-8">
      <div class="grid h-12 w-12 place-items-center rounded-2xl bg-[#e8f2eb] text-[#26745a]"><KeyRound /></div>
      <h2 class="mt-4 text-xl font-black">Crear una contraseña nueva</h2>
      <p class="mt-2 text-sm leading-6 text-[#718078]">Este formulario solo funciona después de abrir el enlace de recuperación que enviamos a tu correo.</p>

      <div v-if="!isSupabaseConfigured" class="mt-5 rounded-xl bg-[#fff4e5] p-4 text-sm text-[#80551d]">Supabase no está configurado.</div>
      <div v-else-if="!ready" class="mt-5 rounded-xl bg-[#f5f8f5] p-4 text-sm text-[#52645a]" aria-live="polite">
        Verificando el enlace de recuperación…
        <p class="mt-2 text-xs">Si esta pantalla no avanza, el enlace puede haber caducado o no haberse validado. Solicita uno nuevo desde el acceso docente.</p>
      </div>
      <form v-else class="mt-5 space-y-3" @submit.prevent="savePassword">
        <label class="block text-sm font-bold" for="new-password">Nueva contraseña</label>
        <input id="new-password" v-model="password" type="password" required minlength="8" autocomplete="new-password" class="w-full rounded-xl border border-[#dce6dd] bg-white px-4 py-3" placeholder="Mínimo 8 caracteres" />
        <label class="block text-sm font-bold" for="confirm-password">Confirmar contraseña</label>
        <input id="confirm-password" v-model="confirmation" type="password" required minlength="8" autocomplete="new-password" class="w-full rounded-xl border border-[#dce6dd] bg-white px-4 py-3" placeholder="Repite la contraseña" />
        <button class="primary w-full justify-center" :disabled="busy || !passwordsMatch">{{ busy ? 'Guardando…' : 'Guardar contraseña nueva' }}</button>
      </form>

      <p v-if="message" class="mt-4 rounded-xl bg-[#edf6ef] p-3 text-sm text-[#28684f]" aria-live="polite">{{ message }}</p>
      <p v-if="error" class="mt-4 rounded-xl bg-[#fff1ef] p-3 text-sm text-[#9b3e32]" role="alert">{{ error }}</p>
      <RouterLink to="/panel-docente" class="mt-5 inline-block text-sm font-bold text-[#26745a] underline">Volver al acceso docente</RouterLink>
    </section>
  </div>
</template>
