<script setup lang="ts">
import { computed, ref } from 'vue'
import { CheckCircle2, XCircle } from 'lucide-vue-next'
import { playGuitarNote } from '../engines/audio/guitarSound'
import StaffNote from './StaffNote.vue'
import type { SpelledNote } from '../engines/music/musicTheory'

type KeyExample = 'D' | 'Bb' | 'A' | 'Eb'

const examples = {
  D: {
    name: 'Re mayor',
    signature: 'Dos sostenidos: Fa♯ y Do♯',
    family: 'Sostenidos',
    order: 'Fa → Do',
    symbols: [
      { x: 142, y: 45, symbol: '♯' },
      { x: 174, y: 72, symbol: '♯' },
    ],
    altered: 'Todos los Fa y todos los Do se interpretan sostenidos.',
    melody: 'Re · Mi · Fa♯ · Sol · La · Si · Do♯ · Re',
    noteName: 'Do sostenido',
    writtenMidi: 73,
    soundingMidi: 61,
    spelling: { letter: 'Do', accidental: 1, octave: 5 },
    string: 2,
    fret: 2,
    explanation: 'En Re mayor, Fa y Do llevan sostenido por la armadura. El Do sostenido se toca en la segunda cuerda, traste 2.',
  },
  Bb: {
    name: 'Si bemol mayor',
    signature: 'Dos bemoles: Si♭ y Mi♭',
    family: 'Bemoles',
    order: 'Si → Mi',
    symbols: [
      { x: 142, y: 81, symbol: '♭' },
      { x: 174, y: 54, symbol: '♭' },
    ],
    altered: 'Todos los Si y todos los Mi se interpretan bemoles.',
    melody: 'Si♭ · Do · Re · Mi♭ · Fa · Sol · La · Si♭',
    noteName: 'Si bemol',
    writtenMidi: 70,
    soundingMidi: 58,
    spelling: { letter: 'Si', accidental: -1, octave: 4 },
    string: 3,
    fret: 3,
    explanation: 'En Si bemol mayor, Si y Mi llevan bemol por la armadura. El Si bemol se toca en la tercera cuerda, traste 3.',
  },
  A: {
    name: 'La mayor',
    signature: 'Tres sostenidos: Fa♯, Do♯ y Sol♯',
    family: 'Sostenidos',
    order: 'Fa → Do → Sol',
    symbols: [
      { x: 142, y: 45, symbol: '♯' },
      { x: 174, y: 72, symbol: '♯' },
      { x: 206, y: 36, symbol: '♯' },
    ],
    altered: 'Todos los Fa, Do y Sol se interpretan sostenidos.',
    melody: 'La · Si · Do♯ · Re · Mi · Fa♯ · Sol♯ · La',
    noteName: 'Sol sostenido',
    writtenMidi: 80,
    soundingMidi: 68,
    spelling: { letter: 'Sol', accidental: 1, octave: 5 },
    string: 1,
    fret: 4,
    explanation: 'En La mayor se añade Sol sostenido al orden de sostenidos. En la guitarra, esta nota suena en la primera cuerda, traste 4.',
  },
  Eb: {
    name: 'Mi bemol mayor',
    signature: 'Tres bemoles: Si♭, Mi♭ y La♭',
    family: 'Bemoles',
    order: 'Si → Mi → La',
    symbols: [
      { x: 142, y: 81, symbol: '♭' },
      { x: 174, y: 54, symbol: '♭' },
      { x: 206, y: 90, symbol: '♭' },
    ],
    altered: 'Todos los Si, Mi y La se interpretan bemoles.',
    melody: 'Mi♭ · Fa · Sol · La♭ · Si♭ · Do · Re · Mi♭',
    noteName: 'La bemol',
    writtenMidi: 80,
    soundingMidi: 68,
    spelling: { letter: 'La', accidental: -1, octave: 5 },
    string: 1,
    fret: 4,
    explanation: 'En Mi bemol mayor se añade La bemol al orden de bemoles. La bemol y Sol sostenido suenan igual en la guitarra, aunque se escriben distinto.',
  },
} as const

const selectedKey = ref<KeyExample>('D')
const current = computed(() => examples[selectedKey.value])
const activeNote = ref(false)
const answers = ref<Record<string, string>>({})
const submitted = ref(false)

const quiz = [
  {
    id: 'q1',
    prompt: '¿Cuál es el orden en que aparecen los sostenidos en la armadura?',
    options: [{ value: 'sharp', label: 'Fa – Do – Sol' }, { value: 'flat', label: 'Si – Mi – La' }],
    correct: 'sharp',
    explanation: 'Los sostenidos se incorporan siguiendo el orden Fa, Do, Sol, Re, La, Mi y Si.',
  },
  {
    id: 'q2',
    prompt: '¿Qué dos alteraciones tiene la armadura de Si bemol mayor?',
    options: [{ value: 'a', label: 'Fa♯ y Do♯' }, { value: 'b', label: 'Si♭ y Mi♭' }],
    correct: 'b',
    explanation: 'Si bemol mayor tiene dos bemoles: Si y Mi.',
  },
  {
    id: 'q3',
    prompt: '¿Qué tonalidad tiene tres sostenidos?',
    options: [{ value: 'a', label: 'Re mayor' }, { value: 'b', label: 'La mayor' }],
    correct: 'b',
    explanation: 'La mayor tiene Fa♯, Do♯ y Sol♯.',
  },
]

const score = computed(() => quiz.filter(q => answers.value[q.id] === q.correct).length)

function playExample() {
  activeNote.value = true
  void playGuitarNote(current.value.soundingMidi, current.value.string)
}
</script>

<template>
  <section class="panel mb-4 p-3 sm:p-4">
    <div class="mb-3">
      <p class="eyebrow">Lectura musical · Armaduras de tonalidad</p>
      <h2 class="text-lg font-black">Dos y tres alteraciones</h2>
      <p class="mt-1 text-sm leading-5 text-[#788780]">
        Las armaduras siguen un orden fijo. Cada nuevo sostenido o bemol se añade al anterior; no se colocan al azar.
      </p>
    </div>

    <div class="grid gap-2 sm:grid-cols-2">
      <div class="rounded-xl bg-[#edf4ee] p-3">
        <p class="text-sm font-black text-[#426c5b]">Orden de sostenidos</p>
        <p class="mt-1 text-sm font-bold tracking-wide text-[#365c4c]">Fa → Do → Sol → Re → La → Mi → Si</p>
        <p class="mt-1 text-xs leading-5 text-[#567267]">Cada sostenido nuevo aparece a la derecha del anterior.</p>
      </div>
      <div class="rounded-xl bg-[#edf4ee] p-3">
        <p class="text-sm font-black text-[#426c5b]">Orden de bemoles</p>
        <p class="mt-1 text-sm font-bold tracking-wide text-[#365c4c]">Si → Mi → La → Re → Sol → Do → Fa</p>
        <p class="mt-1 text-xs leading-5 text-[#567267]">Los bemoles también conservan siempre esta secuencia.</p>
      </div>
    </div>

    <div class="mt-3 rounded-xl border border-[#dce7df] p-3">
      <label class="block">
        <span class="mb-1 block text-[10px] font-bold uppercase tracking-wide text-[#718078]">Explora las armaduras</span>
        <select v-model="selectedKey" class="w-full rounded-lg border border-[#dce5dc] bg-white px-3 py-2 text-sm font-semibold text-[#365c4c]" @change="activeNote = false">
          <option value="D">Re mayor · dos sostenidos</option>
          <option value="Bb">Si bemol mayor · dos bemoles</option>
          <option value="A">La mayor · tres sostenidos</option>
          <option value="Eb">Mi bemol mayor · tres bemoles</option>
        </select>
      </label>

      <div class="mt-3 grid items-center gap-3 sm:grid-cols-[minmax(0,1fr)_minmax(0,1.1fr)]">
        <div class="rounded-xl bg-[#f7f4ed] p-2">
          <p class="text-center text-[10px] font-bold uppercase tracking-wide text-[#718078]">Armadura seleccionada</p>
          <svg viewBox="0 0 310 145" class="mx-auto block w-full max-w-[300px]" role="img" :aria-label="`Clave de sol y armadura de ${current.name}: ${current.signature}`">
            <g stroke="#89958e" stroke-width="1.3">
              <path v-for="i in 5" :key="i" :d="`M 12 ${45 + (i - 1) * 18} H 292`" />
            </g>
            <text x="18" y="112" font-size="66" fill="#176b5b">𝄞</text>
            <text
              v-for="(item, index) in current.symbols"
              :key="index"
              :x="item.x"
              :y="item.y + 10"
              font-size="32"
              text-anchor="middle"
              fill="#176b5b"
            >{{ item.symbol }}</text>
          </svg>
          <StaffNote :midi="current.writtenMidi" :spelling="current.spelling as SpelledNote" />
          <p class="text-center text-sm font-black text-[#176b5b]">{{ current.name }}</p>
          <p class="text-center text-xs text-[#718078]">{{ current.signature }}</p>
        </div>

        <div>
          <p class="text-xs font-bold uppercase tracking-wide text-[#718078]">{{ current.family }} · orden</p>
          <p class="mt-1 text-lg font-black text-[#426c5b]">{{ current.order }}</p>
          <p class="mt-2 text-sm font-black text-[#426c5b]">{{ current.altered }}</p>
          <p class="mt-2 text-xs leading-5 text-[#718078]">Melodía de referencia:</p>
          <p class="mt-1 rounded-lg bg-[#edf4ee] p-2 text-center text-sm font-bold leading-6 text-[#365c4c]">{{ current.melody }}</p>
          <p class="mt-2 text-xs leading-5 text-[#718078]">La armadura afecta a todas las octavas de esas notas, aunque el signo aparezca escrito una sola vez al comienzo del pentagrama.</p>
        </div>
      </div>

      <div class="mt-3 flex flex-wrap items-center justify-between gap-3 rounded-lg bg-[#edf4ee] p-3">
        <div>
          <p class="text-xs font-bold text-[#426c5b]">Escucha una nota de esta tonalidad</p>
          <p class="mt-1 text-xs text-[#567267]">{{ current.noteName }} · cuerda {{ current.string }}, traste {{ current.fret }}</p>
        </div>
        <button class="primary px-3 py-2 text-xs" @click="playExample">{{ activeNote ? 'Escuchar otra vez' : 'Escuchar nota' }}</button>
      </div>
      <p v-if="activeNote" class="mt-2 text-xs leading-5 text-[#567267]">{{ current.explanation }} La nota escrita para guitarra suena una octava más grave.</p>
    </div>

    <div class="mt-3 rounded-xl bg-[#f7f4ed] p-3">
      <h3 class="text-base font-black">Comprueba lo que aprendiste</h3>
      <div v-for="item in quiz" :key="item.id" class="mt-3">
        <p class="text-xs font-bold text-[#426c5b]">{{ item.prompt }}</p>
        <div class="mt-2 grid gap-2 sm:grid-cols-2">
          <button
            v-for="option in item.options"
            :key="option.value"
            class="rounded-lg border-2 bg-white px-3 py-2 text-left text-xs font-semibold transition"
            :class="answers[item.id] === option.value ? 'border-[#4c9c7c] bg-[#edf4ee]' : 'border-transparent'"
            :disabled="submitted"
            @click="answers[item.id] = option.value"
          >
            {{ option.label }}
          </button>
        </div>
        <p v-if="submitted" class="mt-1 flex items-start gap-1.5 text-[11px]" :class="answers[item.id] === item.correct ? 'text-[#226447]' : 'text-[#a14f2d]'">
          <CheckCircle2 v-if="answers[item.id] === item.correct" :size="14" />
          <XCircle v-else :size="14" />
          {{ item.explanation }}
        </p>
      </div>
      <div class="mt-3 flex items-center justify-between gap-2">
        <p v-if="submitted" class="text-xs font-bold text-[#426c5b]">Resultado: {{ score }} de {{ quiz.length }}</p>
        <span v-else class="text-[10px] text-[#788780]">{{ Object.keys(answers).length }} de {{ quiz.length }} respondidas</span>
        <button v-if="!submitted" class="primary px-3 py-2 text-xs" :disabled="Object.keys(answers).length !== quiz.length" @click="submitted = true">Comprobar</button>
        <button v-else class="secondary px-3 py-2 text-xs" @click="answers = {}; submitted = false">Repetir</button>
      </div>
    </div>
  </section>
</template>
