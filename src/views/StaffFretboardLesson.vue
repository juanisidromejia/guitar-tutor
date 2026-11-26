<script setup lang="ts">
import { ref } from 'vue'
import { ArrowRight, CheckCircle2, XCircle } from 'lucide-vue-next'
import GuitarFretboard from '../components/GuitarFretboard.vue'
import StaffNote from '../components/StaffNote.vue'
import { fretMidi } from '../engines/guitar/fretboard'
import { playGuitarNote } from '../engines/audio/guitarSound'
import { useProgress } from '../composables/useProgress'

const { record, complete } = useProgress()
const notes = [60, 62, 64, 65, 67, 69]
const round = ref(1)
const target = ref(64)
const selected = ref<{ string: number; fret: number } | null>(null)
const feedback = ref<'correct' | 'wrong' | null>(null)

function next() {
  round.value++
  target.value = notes[(round.value * 5 + 2) % notes.length]
  selected.value = null
  feedback.value = null
}

function choose(position: { string: number; fret: number; midi: number }) {
  if (feedback.value === 'correct') return
  selected.value = position
  void playGuitarNote(position.midi, position.string)
  const soundingMidi = target.value - 12
  const isCorrect = fretMidi(position.string, position.fret) === soundingMidi
  record(isCorrect)
  feedback.value = isCorrect ? 'correct' : 'wrong'

  if (isCorrect) {
    complete(3)
  }
}

</script>

<template>
  <div class="page">
    <div class="mb-3">
      <p class="eyebrow">Lectura musical · Nivel 1</p>
      <h1 class="mt-0.5 text-xl font-black">Notas en el pentagrama</h1>
      <p class="mt-0.5 max-w-2xl text-xs leading-4 text-[#788780]">
        Lee la nota en clave de sol y encuentra su lugar en el diapasón de la guitarra.
      </p>
    </div>

    <section class="panel p-3 sm:p-4">
      <div class="mb-2 flex items-center justify-between gap-3">
        <div>
          <p class="eyebrow">Lee y encuentra</p>
          <h2 class="mt-0.5 text-lg font-black">¿Dónde está esta nota?</h2>
        </div>
        <span class="rounded-full bg-[#eef4ef] px-2.5 py-1 text-[11px] font-bold text-[#426c5b]">Ejercicio {{ round }}</span>
      </div>

      <div class="grid grid-cols-1 items-center gap-3 lg:grid-cols-[minmax(230px,0.75fr)_minmax(0,1.5fr)] lg:gap-5">
        <div class="rounded-xl bg-[#f5f8f4] p-2">
          <p class="mb-0.5 text-center text-[10px] font-bold uppercase tracking-wide text-[#718078]">Nota en clave de sol</p>
          <StaffNote :midi="target" />
          <p class="mt-0.5 text-center text-[11px] font-semibold text-[#176b5b]">
            Busca la nota en el instrumento.
          </p>
        </div>

        <div class="min-w-0">
          <div class="mb-1 flex items-center justify-between gap-2">
            <h3 class="text-sm font-extrabold">Diapasón de guitarra</h3>
            <span class="text-[10px] text-[#829087]">Cuerdas 1–6 · Trastes 0–5</span>
          </div>
          <GuitarFretboard :selected="selected" :disabled="feedback === 'correct'" @select="choose" />
        </div>
      </div>

      <div v-if="feedback === 'wrong'" class="mt-2 flex items-center gap-2 rounded-lg bg-[#fff1e9] p-2 text-[#a14f2d]">
        <XCircle :size="18" />
        <p class="text-xs font-semibold">Esa posición produce otra nota. ¡Inténtalo de nuevo!</p>
      </div>
      <div v-else-if="feedback === 'correct'" class="mt-2 flex items-center gap-2 rounded-lg bg-[#e9f5ed] p-2 text-[#226447]">
        <CheckCircle2 :size="18" />
        <div class="flex-1">
          <p class="text-xs font-semibold">¡Correcto! Has relacionado el pentagrama con la guitarra.</p>
          <p class="mt-0.5 text-[11px]">Cuando estés listo, continúa con la siguiente nota.</p>
        </div>
        <button class="primary flex shrink-0 items-center gap-1.5 px-3 py-2 text-xs" @click="next">
          Continuar <ArrowRight :size="15" />
        </button>
      </div>
      <p v-else class="mt-2 text-center text-xs text-[#788780]">
        Selecciona una cuerda y un traste. La respuesta se comprueba automáticamente.
      </p>
    </section>

    <div class="mt-2 rounded-xl bg-[#edf4ee] p-2.5 text-[11px] leading-4 text-[#567267]">
      <b>Consejo:</b> la nota del pentagrama es la nota escrita. Para encontrarla en la guitarra, busca el sonido una octava más grave. Por ejemplo, un Sol4 escrito corresponde al Sol3 que suena en la tercera cuerda al aire.
    </div>
  </div>
</template>
