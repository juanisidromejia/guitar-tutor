<script setup lang="ts">
import { onBeforeUnmount, ref } from 'vue'
import { ArrowLeft, CheckCircle2, XCircle } from 'lucide-vue-next'
import { RouterLink } from 'vue-router'
import GuitarFretboard from '../components/GuitarFretboard.vue'
import StaffNote from '../components/StaffNote.vue'
import { fretMidi } from '../engines/guitar/fretboard'
import { useProgress } from '../composables/useProgress'

const { record, complete } = useProgress()
const notes = [60, 62, 64, 65, 67, 69]
const round = ref(1)
const target = ref(64)
const selected = ref<{ string: number; fret: number } | null>(null)
const feedback = ref<'correct' | 'wrong' | null>(null)
let advanceTimer: ReturnType<typeof setTimeout> | undefined

function next() {
  if (advanceTimer) clearTimeout(advanceTimer)
  round.value++
  target.value = notes[(round.value * 5 + 2) % notes.length]
  selected.value = null
  feedback.value = null
}

function choose(position: { string: number; fret: number; midi: number }) {
  if (feedback.value === 'correct') return
  selected.value = position
  const soundingMidi = target.value - 12
  const isCorrect = fretMidi(position.string, position.fret) === soundingMidi
  record(isCorrect)
  feedback.value = isCorrect ? 'correct' : 'wrong'

  if (isCorrect) {
    // Programa el avance antes de actualizar el progreso para que la
    // siguiente prueba no dependa de operaciones secundarias.
    if (advanceTimer) clearTimeout(advanceTimer)
    advanceTimer = setTimeout(next, 1300)
    complete(3)
  }
}

onBeforeUnmount(() => {
  if (advanceTimer) clearTimeout(advanceTimer)
})
</script>

<template>
  <div class="page">
    <RouterLink to="/" class="mb-3 inline-flex items-center gap-2 text-sm font-bold text-[#698077]">
      <ArrowLeft :size="17" /> Volver al inicio
    </RouterLink>

    <div class="mb-4">
      <p class="eyebrow">Lectura musical · Nivel 1</p>
      <h1 class="mt-1 text-2xl font-black">Notas en el pentagrama</h1>
      <p class="mt-1 max-w-2xl text-sm leading-5 text-[#788780]">
        Lee la nota en clave de sol y encuentra su lugar en el diapasón de la guitarra.
      </p>
    </div>

    <section class="panel p-4 sm:p-5">
      <div class="flex items-center justify-between gap-3">
        <div>
          <p class="eyebrow">Lee y encuentra</p>
          <h2 class="mt-1 text-xl font-black">¿Dónde está esta nota?</h2>
        </div>
        <span class="rounded-full bg-[#eef4ef] px-3 py-1.5 text-xs font-bold text-[#426c5b]">Ejercicio {{ round }}</span>
      </div>

      <div class="my-3 rounded-2xl bg-[#f5f8f4] p-2 sm:p-3">
        <p class="mb-1 text-center text-xs font-bold uppercase tracking-wide text-[#718078]">Nota en clave de sol</p>
        <StaffNote :midi="target" />
        <p class="mt-1 text-center text-xs font-semibold text-[#176b5b]">
          Busca la nota en el instrumento, no por su nombre.
        </p>
      </div>

      <div class="mb-2 flex items-center justify-between gap-3">
        <h3 class="font-extrabold">Diapasón de guitarra</h3>
        <span class="text-xs text-[#829087]">Cuerdas 1 a 6 · Trastes 0 a 5</span>
      </div>
      <GuitarFretboard :selected="selected" :disabled="feedback === 'correct'" @select="choose" />

      <div v-if="feedback === 'wrong'" class="mt-3 flex items-center gap-3 rounded-xl bg-[#fff1e9] p-3 text-[#a14f2d]">
        <XCircle />
        <p class="text-sm font-semibold">Esa posición produce otra nota. ¡Inténtalo de nuevo!</p>
      </div>
      <div v-else-if="feedback === 'correct'" class="mt-3 flex items-center gap-3 rounded-xl bg-[#e9f5ed] p-3 text-[#226447]">
        <CheckCircle2 />
        <p class="text-sm font-semibold">¡Correcto! Has relacionado el pentagrama con la guitarra. Siguiente nota…</p>
      </div>
      <p v-else class="mt-3 text-center text-sm text-[#788780]">
        Selecciona una cuerda y un traste. La respuesta se comprueba automáticamente.
      </p>
    </section>

    <div class="mt-3 rounded-2xl bg-[#edf4ee] p-3 text-xs leading-5 text-[#567267]">
      <b>Consejo:</b> recuerda que la guitarra suena una octava más grave de lo que se escribe.
      Por eso, la posición correcta del diapasón corresponde a una octava más grave que la nota escrita.
    </div>
  </div>
</template>
