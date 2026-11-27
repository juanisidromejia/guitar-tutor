<script setup lang="ts">
import { computed, ref } from 'vue'
import { CheckCircle2, XCircle, Volume2 } from 'lucide-vue-next'
import StaffNote from './StaffNote.vue'
import { playGuitarNote } from '../engines/audio/guitarSound'
import type { SpelledNote } from '../engines/music/musicTheory'

type PhraseNote = {
  id: string
  label: string
  spelling: SpelledNote
  soundingMidi: number
  sign: 'sharp' | 'natural' | 'none'
  explanation: string
}

const phrase: { measure: number; notes: PhraseNote[] }[] = [
  {
    measure: 1,
    notes: [
      { id: 'm1n1', label: 'Fa♯', spelling: { letter: 'Fa', accidental: 1, octave: 4 }, soundingMidi: 54, sign: 'sharp', explanation: 'El sostenido modifica Fa y se mantiene durante el resto del compás.' },
      { id: 'm1n2', label: 'Fa♯', spelling: { letter: 'Fa', accidental: 1, octave: 4 }, soundingMidi: 54, sign: 'none', explanation: 'No hace falta repetir el sostenido: sigue vigente para Fa en esta octava y compás.' },
      { id: 'm1n3', label: 'Fa natural', spelling: { letter: 'Fa', accidental: 0, octave: 4 }, soundingMidi: 53, sign: 'natural', explanation: 'El becuadro cancela el sostenido. Desde aquí, Fa vuelve a ser natural durante el compás.' },
      { id: 'm1n4', label: 'Fa natural', spelling: { letter: 'Fa', accidental: 0, octave: 4 }, soundingMidi: 53, sign: 'none', explanation: 'El becuadro sigue vigente: esta nota también es Fa natural.' },
    ],
  },
  {
    measure: 2,
    notes: [
      { id: 'm2n1', label: 'Fa natural', spelling: { letter: 'Fa', accidental: 0, octave: 4 }, soundingMidi: 53, sign: 'none', explanation: 'La barra de compás restablece las alteraciones. Fa vuelve a su estado natural.' },
      { id: 'm2n2', label: 'Fa♯', spelling: { letter: 'Fa', accidental: 1, octave: 4 }, soundingMidi: 54, sign: 'sharp', explanation: 'Un nuevo sostenido vuelve a elevar Fa un semitono.' },
      { id: 'm2n3', label: 'Fa♯', spelling: { letter: 'Fa', accidental: 1, octave: 4 }, soundingMidi: 54, sign: 'none', explanation: 'El sostenido continúa vigente hasta el final de este compás.' },
      { id: 'm2n4', label: 'Fa natural', spelling: { letter: 'Fa', accidental: 0, octave: 4 }, soundingMidi: 53, sign: 'natural', explanation: 'El becuadro vuelve a cancelar el sostenido.' },
    ],
  },
]

const activeNote = ref<PhraseNote | null>(null)
const quizAnswers = ref<Record<string, string>>({})
const quizSubmitted = ref(false)
const quiz = [
  { id: 'q1', question: 'En el primer compás, ¿cómo suena el segundo Fa?', options: [{ value: 'natural', label: 'Fa natural' }, { value: 'sharp', label: 'Fa sostenido' }], correct: 'sharp', explanation: 'El sostenido del primer Fa sigue vigente durante el compás.' },
  { id: 'q2', question: 'Después del becuadro del primer compás, ¿cómo suena el siguiente Fa?', options: [{ value: 'natural', label: 'Fa natural' }, { value: 'sharp', label: 'Fa sostenido' }], correct: 'natural', explanation: 'El becuadro cancela el sostenido para esa nota durante el resto del compás.' },
  { id: 'q3', question: 'Al comenzar el segundo compás, ¿qué ocurre con la alteración anterior?', options: [{ value: 'reset', label: 'Se restablece: Fa natural' }, { value: 'carry', label: 'El sostenido continúa' }], correct: 'reset', explanation: 'La alteración accidental deja de aplicarse al cruzar la barra de compás.' },
]
const score = computed(() => quiz.filter(item => quizAnswers.value[item.id] === item.correct).length)

function play(note: PhraseNote) {
  activeNote.value = note
  void playGuitarNote(note.soundingMidi, 4)
}

function submitQuiz() {
  quizSubmitted.value = true
}
</script>

<template>
  <section class="panel mb-4 p-3 sm:p-4">
    <div class="mb-3">
      <p class="eyebrow">Lectura musical · Alteraciones en el compás</p>
      <h2 class="text-lg font-black">Una alteración puede seguir vigente</h2>
      <p class="mt-1 text-sm leading-5 text-[#788780]">
        En una partitura, un sostenido o bemol escrito junto a una nota afecta a las notas del mismo nombre y octava que aparecen después, dentro de ese compás. No es necesario repetir el signo.
      </p>
    </div>

    <div class="grid gap-2 sm:grid-cols-3">
      <div class="rounded-xl bg-[#edf4ee] p-3">
        <p class="text-sm font-black text-[#426c5b]">1. Se aplica</p>
        <p class="mt-1 text-xs leading-5 text-[#567267]">Fa♯ cambia Fa a Fa sostenido.</p>
      </div>
      <div class="rounded-xl bg-[#edf4ee] p-3">
        <p class="text-sm font-black text-[#426c5b]">2. Se mantiene</p>
        <p class="mt-1 text-xs leading-5 text-[#567267]">Los Fa siguientes del mismo compás y octava conservan la alteración.</p>
      </div>
      <div class="rounded-xl bg-[#edf4ee] p-3">
        <p class="text-sm font-black text-[#426c5b]">3. Se restablece</p>
        <p class="mt-1 text-xs leading-5 text-[#567267]">Al llegar a la barra de compás, la alteración deja de aplicarse.</p>
      </div>
    </div>

    <div class="mt-3 rounded-xl border border-[#dce7df] p-3">
      <div class="mb-2 flex items-center justify-between gap-2">
        <div>
          <p class="eyebrow">Frase musical · Cuarta cuerda</p>
          <h3 class="mt-1 text-base font-black">Observa cómo cambia Fa</h3>
        </div>
        <span class="rounded-full bg-[#edf4ee] px-2.5 py-1 text-[10px] font-bold text-[#426c5b]">Sonido real: Fa3 / Fa♯3</span>
      </div>

      <div v-for="bar in phrase" :key="bar.measure" class="mb-3 last:mb-0">
        <p class="mb-1 text-[10px] font-bold uppercase tracking-wide text-[#718078]">Compás {{ bar.measure }}</p>
        <div class="grid grid-cols-4 gap-1.5 sm:gap-2">
          <button
            v-for="(note, index) in bar.notes"
            :key="note.id"
            class="min-w-0 rounded-lg border-2 p-1.5 text-center transition active:scale-[0.98]"
            :class="activeNote?.id === note.id ? 'border-[#4c9c7c] bg-[#edf4ee]' : 'border-transparent bg-[#f7f4ed] hover:bg-[#f0f4ed]'"
            @click="play(note)"
          >
            <StaffNote
              :midi="note.soundingMidi + 12"
              :spelling="note.spelling"
              :accidental-display="note.sign"
            />
            <span class="mt-1 block text-[11px] font-black text-[#176b5b]">{{ note.label }}</span>
            <span class="block text-[9px] text-[#788780]">{{ note.sign === 'sharp' ? '♯ escrito' : note.sign === 'natural' ? '♮ escrito' : 'sin signo' }}</span>
            <span class="mt-1 block text-[9px] font-bold text-[#8a795f]">{{ index + 1 }}</span>
          </button>
        </div>
        <div class="mt-1 flex items-center gap-2 px-1 text-[10px] text-[#8a795f]">
          <span class="h-px flex-1 bg-[#cbbda8]"></span>
          <span>Barra de compás {{ bar.measure }}</span>
          <span class="h-px flex-1 bg-[#cbbda8]"></span>
        </div>
      </div>

      <div v-if="activeNote" class="mt-2 rounded-lg bg-[#edf4ee] p-3">
        <div class="flex items-start gap-2">
          <Volume2 :size="16" class="mt-0.5 shrink-0 text-[#426c5b]" />
          <div>
            <p class="text-xs font-bold text-[#426c5b]">Escuchaste {{ activeNote.label }}</p>
            <p class="mt-1 text-xs leading-5 text-[#567267]">{{ activeNote.explanation }}</p>
            <p class="mt-1 text-[10px] text-[#718078]">Toca la nota en el pentagrama para escucharla en la guitarra. El sonido real está una octava por debajo de la escritura.</p>
          </div>
        </div>
      </div>
      <p v-else class="mt-2 text-center text-xs text-[#788780]">Selecciona las notas para escucharlas y observar qué signo aparece en cada una.</p>
    </div>

    <div class="mt-3 rounded-xl bg-[#f7f4ed] p-3">
      <h3 class="text-base font-black">Comprueba si entendiste</h3>
      <div v-for="item in quiz" :key="item.id" class="mt-3">
        <p class="text-xs font-bold text-[#426c5b]">{{ item.question }}</p>
        <div class="mt-2 grid gap-2 sm:grid-cols-2">
          <button
            v-for="option in item.options"
            :key="option.value"
            class="rounded-lg border-2 bg-white px-3 py-2 text-left text-xs font-semibold transition"
            :class="quizAnswers[item.id] === option.value ? 'border-[#4c9c7c] bg-[#edf4ee]' : 'border-transparent'"
            :disabled="quizSubmitted"
            @click="quizAnswers[item.id] = option.value"
          >
            {{ option.label }}
          </button>
        </div>
        <p v-if="quizSubmitted" class="mt-1 flex items-start gap-1.5 text-[11px]" :class="quizAnswers[item.id] === item.correct ? 'text-[#226447]' : 'text-[#a14f2d]'">
          <CheckCircle2 v-if="quizAnswers[item.id] === item.correct" :size="14" />
          <XCircle v-else :size="14" />
          {{ item.explanation }}
        </p>
      </div>
      <div class="mt-3 flex items-center justify-between gap-2">
        <p v-if="quizSubmitted" class="text-xs font-bold text-[#426c5b]">Resultado: {{ score }} de {{ quiz.length }}</p>
        <span v-else class="text-[10px] text-[#788780]">{{ Object.keys(quizAnswers).length }} de {{ quiz.length }} respondidas</span>
        <button v-if="!quizSubmitted" class="primary px-3 py-2 text-xs" :disabled="Object.keys(quizAnswers).length !== quiz.length" @click="submitQuiz">Comprobar</button>
        <button v-else class="secondary px-3 py-2 text-xs" @click="quizAnswers = {}; quizSubmitted = false">Repetir</button>
      </div>
    </div>
  </section>
</template>
