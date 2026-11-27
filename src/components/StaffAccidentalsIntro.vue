<script setup lang="ts">
import { computed, ref } from 'vue'
import { CheckCircle2, XCircle } from 'lucide-vue-next'
import GuitarFretboard from './GuitarFretboard.vue'
import StaffNote from './StaffNote.vue'
import type { SpelledNote } from '../engines/music/musicTheory'
import { playGuitarNote } from '../engines/audio/guitarSound'

type Challenge = {
  title: string
  sharp: SpelledNote
  flat: SpelledNote
  writtenMidi: number
  string: number
  fret: number
  explanation: string
}

const challenges: Challenge[] = [
  {
    title: 'Fa sostenido / Sol bemol',
    sharp: { letter: 'Fa', accidental: 1, octave: 4 },
    flat: { letter: 'Sol', accidental: -1, octave: 4 },
    writtenMidi: 66,
    string: 4,
    fret: 4,
    explanation: 'Fa♯ sube Fa un semitono y Sol♭ baja Sol un semitono. Ambos nombres corresponden al mismo sonido: Fa♯3 / Sol♭3.',
  },
  {
    title: 'Re sostenido / Mi bemol',
    sharp: { letter: 'Re', accidental: 1, octave: 4 },
    flat: { letter: 'Mi', accidental: -1, octave: 4 },
    writtenMidi: 63,
    string: 4,
    fret: 1,
    explanation: 'Re♯ sube Re un semitono y Mi♭ baja Mi un semitono. Ambos nombres corresponden al mismo sonido: Re♯3 / Mi♭3.',
  },
]

const index = ref(0)
const selected = ref<{ string: number; fret: number } | null>(null)
const feedback = ref<'correct' | 'wrong' | null>(null)
const current = computed(() => challenges[index.value])
const completed = ref(false)

function choose(position: { string: number; fret: number; midi: number }) {
  if (feedback.value === 'correct') return
  selected.value = position
  void playGuitarNote(position.midi, position.string)
  feedback.value = position.string === current.value.string && position.fret === current.value.fret
    ? 'correct'
    : 'wrong'
}

function next() {
  if (index.value === challenges.length - 1) {
    completed.value = true
    return
  }
  index.value++
  selected.value = null
  feedback.value = null
}

function restart() {
  index.value = 0
  selected.value = null
  feedback.value = null
  completed.value = false
}
</script>

<template>
  <section class="panel mb-4 p-3 sm:p-4">
    <div class="mb-3">
      <p class="eyebrow">Lectura musical · Sostenidos y bemoles</p>
      <h2 class="text-lg font-black">Del signo en el pentagrama al diapasón</h2>
      <p class="mt-1 text-sm leading-5 text-[#788780]">
        El sostenido (♯) eleva una nota un semitono. El bemol (♭) la baja un semitono. Observa cómo dos escrituras distintas pueden representar la misma altura.
      </p>
    </div>

    <div class="grid gap-2 sm:grid-cols-2">
      <div class="rounded-xl bg-[#edf4ee] p-3">
        <p class="text-sm font-black text-[#426c5b]">Sostenido ♯</p>
        <p class="mt-1 text-xs leading-5 text-[#567267]">Sube la nota natural un semitono. Por ejemplo, Fa → Fa♯.</p>
      </div>
      <div class="rounded-xl bg-[#edf4ee] p-3">
        <p class="text-sm font-black text-[#426c5b]">Bemol ♭</p>
        <p class="mt-1 text-xs leading-5 text-[#567267]">Baja la nota natural un semitono. Por ejemplo, Sol → Sol♭.</p>
      </div>
    </div>

    <div class="mt-3 rounded-xl border border-[#dce7df] p-3">
      <div class="mb-3 flex items-center justify-between gap-2">
        <div>
          <p class="eyebrow">Ejemplo guiado · {{ index + 1 }} de {{ challenges.length }}</p>
          <h3 class="mt-1 text-base font-black">{{ current.title }}</h3>
        </div>
        <span class="rounded-full bg-[#edf4ee] px-2.5 py-1 text-[10px] font-bold text-[#426c5b]">4.ª cuerda</span>
      </div>

      <div class="grid gap-3 sm:grid-cols-2">
        <div class="rounded-xl bg-[#f5f8f4] p-2">
          <p class="mb-1 text-center text-[10px] font-bold uppercase tracking-wide text-[#718078]">Escritura con sostenido</p>
          <StaffNote :midi="current.writtenMidi" :spelling="current.sharp" />
          <p class="text-center text-xs font-bold text-[#176b5b]">{{ current.sharp.letter }}♯{{ current.sharp.octave }}</p>
        </div>
        <div class="rounded-xl bg-[#f5f8f4] p-2">
          <p class="mb-1 text-center text-[10px] font-bold uppercase tracking-wide text-[#718078]">Escritura con bemol</p>
          <StaffNote :midi="current.writtenMidi" :spelling="current.flat" />
          <p class="text-center text-xs font-bold text-[#176b5b]">{{ current.flat.letter }}♭{{ current.flat.octave }}</p>
        </div>
      </div>

      <p class="mt-3 rounded-lg bg-[#edf4ee] p-3 text-xs leading-5 text-[#567267]">
        {{ current.explanation }} En el pentagrama de guitarra se escribe una octava más aguda que el sonido real. Por eso estas notas escritas corresponden a la tercera octava al sonar.
      </p>

      <div class="mt-3">
        <p class="mb-2 text-center text-xs font-bold text-[#426c5b]">
          Encuentra esa altura en la guitarra: cuerda {{ current.string }}, traste {{ current.fret }}
        </p>
        <GuitarFretboard
          :start-fret="0"
          :end-fret="5"
          :selected="selected"
          :disabled="feedback === 'correct'"
          @select="choose"
        />
      </div>

      <div v-if="feedback === 'wrong'" class="mt-2 flex items-center gap-2 rounded-lg bg-[#fff1e9] p-3 text-xs font-semibold text-[#a14f2d]">
        <XCircle :size="17" />
        Esa posición produce otra altura. Recuerda que debes bajar una octava desde la nota escrita para encontrar el sonido real.
      </div>
      <div v-else-if="feedback === 'correct'" class="mt-2 flex items-center gap-2 rounded-lg bg-[#e9f5ed] p-3 text-[#226447]">
        <CheckCircle2 :size="18" />
        <div class="flex-1">
          <p class="text-xs font-bold">¡Correcto! Has relacionado la alteración escrita con su posición.</p>
          <p class="mt-0.5 text-[11px]">{{ current.explanation }}</p>
        </div>
        <button class="primary shrink-0 px-3 py-2 text-xs" @click="next">
          {{ index === challenges.length - 1 ? 'Finalizar' : 'Continuar' }}
        </button>
      </div>
      <p v-else class="mt-2 text-center text-xs text-[#788780]">Selecciona la posición correspondiente en el diapasón.</p>

      <div v-if="completed" class="mt-3 flex items-center gap-2 rounded-lg bg-[#e9f5ed] p-3 text-xs font-semibold text-[#226447]">
        <CheckCircle2 :size="18" />
        ¡Has completado los dos ejemplos! Ya puedes relacionar sostenidos y bemoles escritos con sus posiciones en la guitarra.
        <button class="secondary ml-auto shrink-0 text-xs" @click="restart">Repetir</button>
      </div>
    </div>
  </section>
</template>
