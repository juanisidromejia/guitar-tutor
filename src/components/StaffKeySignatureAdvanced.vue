<script setup lang="ts">
import { computed, ref } from 'vue'
import { CheckCircle2, XCircle } from 'lucide-vue-next'
import { playGuitarNote } from '../engines/audio/guitarSound'
import StaffNote from './StaffNote.vue'
import type { SpelledNote } from '../engines/music/musicTheory'

type KeyExample = 'E' | 'B' | 'Ab' | 'Db'

const examples = {
  E: {
    name: 'Mi mayor',
    signature: 'Cuatro sostenidos: Fa♯, Do♯, Sol♯ y Re♯',
    family: 'Sostenidos',
    order: 'Fa → Do → Sol → Re',
    symbols: [
      { x: 142, y: 45, symbol: '♯' },
      { x: 174, y: 72, symbol: '♯' },
      { x: 206, y: 36, symbol: '♯' },
      { x: 238, y: 63, symbol: '♯' },
    ],
    altered: 'Todos los Fa, Do, Sol y Re se interpretan sostenidos.',
    melody: 'Mi · Fa♯ · Sol♯ · La · Si · Do♯ · Re♯ · Mi',
    noteName: 'Re sostenido',
    writtenMidi: 75,
    soundingMidi: 63,
    spelling: { letter: 'Re', accidental: 1, octave: 5 },
    string: 2,
    fret: 4,
    explanation: 'Mi mayor incorpora cuatro sostenidos. Re sostenido se encuentra en la segunda cuerda, traste 4; recuerda que la guitarra suena una octava debajo de lo escrito.',
  },
  B: {
    name: 'Si mayor',
    signature: 'Cinco sostenidos: Fa♯, Do♯, Sol♯, Re♯ y La♯',
    family: 'Sostenidos',
    order: 'Fa → Do → Sol → Re → La',
    symbols: [
      { x: 142, y: 45, symbol: '♯' },
      { x: 174, y: 72, symbol: '♯' },
      { x: 206, y: 36, symbol: '♯' },
      { x: 238, y: 63, symbol: '♯' },
      { x: 270, y: 90, symbol: '♯' },
    ],
    altered: 'Todos los Fa, Do, Sol, Re y La se interpretan sostenidos.',
    melody: 'Si · Do♯ · Re♯ · Mi · Fa♯ · Sol♯ · La♯ · Si',
    noteName: 'La sostenido',
    writtenMidi: 82,
    soundingMidi: 70,
    spelling: { letter: 'La', accidental: 1, octave: 5 },
    string: 1,
    fret: 6,
    explanation: 'Si mayor añade La sostenido como quinto signo. La sostenido suena en la primera cuerda, traste 6.',
  },
  Ab: {
    name: 'La bemol mayor',
    signature: 'Cuatro bemoles: Si♭, Mi♭, La♭ y Re♭',
    family: 'Bemoles',
    order: 'Si → Mi → La → Re',
    symbols: [
      { x: 142, y: 81, symbol: '♭' },
      { x: 174, y: 54, symbol: '♭' },
      { x: 206, y: 90, symbol: '♭' },
      { x: 238, y: 63, symbol: '♭' },
    ],
    altered: 'Todos los Si, Mi, La y Re se interpretan bemoles.',
    melody: 'La♭ · Si♭ · Do · Re♭ · Mi♭ · Fa · Sol · La♭',
    noteName: 'Re bemol',
    writtenMidi: 73,
    soundingMidi: 61,
    spelling: { letter: 'Re', accidental: -1, octave: 5 },
    string: 2,
    fret: 2,
    explanation: 'La bemol mayor tiene cuatro bemoles. Re bemol se toca en la segunda cuerda, traste 2; en sonido es enarmónico de Do sostenido.',
  },
  Db: {
    name: 'Re bemol mayor',
    signature: 'Cinco bemoles: Si♭, Mi♭, La♭, Re♭ y Sol♭',
    family: 'Bemoles',
    order: 'Si → Mi → La → Re → Sol',
    symbols: [
      { x: 142, y: 81, symbol: '♭' },
      { x: 174, y: 54, symbol: '♭' },
      { x: 206, y: 90, symbol: '♭' },
      { x: 238, y: 63, symbol: '♭' },
      { x: 270, y: 99, symbol: '♭' },
    ],
    altered: 'Todos los Si, Mi, La, Re y Sol se interpretan bemoles.',
    melody: 'Re♭ · Mi♭ · Fa · Sol♭ · La♭ · Si♭ · Do · Re♭',
    noteName: 'Re bemol',
    writtenMidi: 73,
    soundingMidi: 61,
    spelling: { letter: 'Re', accidental: -1, octave: 5 },
    string: 2,
    fret: 2,
    explanation: 'Re bemol mayor añade Sol bemol como quinto signo. La armadura mantiene el orden Si, Mi, La, Re y Sol.',
  },
} as const

const selectedKey = ref<KeyExample>('E')
const current = computed(() => examples[selectedKey.value])
const activeNote = ref(false)
const answers = ref<Record<string, string>>({})
const submitted = ref(false)

const quiz = [
  {
    id: 'q1',
    prompt: '¿Qué sostenido se añade en cuarto lugar?',
    options: [{ value: 'a', label: 'Re♯' }, { value: 'b', label: 'La♯' }],
    correct: 'a',
    explanation: 'El orden es Fa, Do, Sol y Re; por eso Re sostenido es el cuarto.',
  },
  {
    id: 'q2',
    prompt: '¿Cuántos bemoles tiene La bemol mayor?',
    options: [{ value: 'a', label: 'Tres' }, { value: 'b', label: 'Cuatro' }],
    correct: 'b',
    explanation: 'La bemol mayor tiene Si♭, Mi♭, La♭ y Re♭.',
  },
  {
    id: 'q3',
    prompt: '¿Qué nota se añade en quinto lugar al orden de bemoles?',
    options: [{ value: 'a', label: 'Sol♭' }, { value: 'b', label: 'Do♭' }],
    correct: 'a',
    explanation: 'El quinto bemol es Sol bemol. Así se completa la armadura de Re bemol mayor.',
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
      <h2 class="text-lg font-black">Cuatro y cinco alteraciones</h2>
      <p class="mt-1 text-sm leading-5 text-[#788780]">
        Seguimos el mismo orden: cada nueva alteración se suma a las anteriores. Observa cómo crece la armadura sin cambiar la secuencia.
      </p>
    </div>

    <div class="grid gap-2 sm:grid-cols-2">
      <div class="rounded-xl bg-[#edf4ee] p-3">
        <p class="text-sm font-black text-[#426c5b]">Sostenidos · cuarto y quinto</p>
        <p class="mt-1 text-sm font-bold text-[#365c4c]">Re♯ → La♯</p>
        <p class="mt-1 text-xs leading-5 text-[#567267]">Fa – Do – Sol – Re – La</p>
      </div>
      <div class="rounded-xl bg-[#edf4ee] p-3">
        <p class="text-sm font-black text-[#426c5b]">Bemoles · cuarto y quinto</p>
        <p class="mt-1 text-sm font-bold text-[#365c4c]">Re♭ → Sol♭</p>
        <p class="mt-1 text-xs leading-5 text-[#567267]">Si – Mi – La – Re – Sol</p>
      </div>
    </div>

    <div class="mt-3 rounded-xl border border-[#dce7df] p-3">
      <label class="block">
        <span class="mb-1 block text-[10px] font-bold uppercase tracking-wide text-[#718078]">Explora las armaduras</span>
        <select v-model="selectedKey" class="w-full rounded-lg border border-[#dce5dc] bg-white px-3 py-2 text-sm font-semibold text-[#365c4c]" @change="activeNote = false">
          <option value="E">Mi mayor · cuatro sostenidos</option>
          <option value="B">Si mayor · cinco sostenidos</option>
          <option value="Ab">La bemol mayor · cuatro bemoles</option>
          <option value="Db">Re bemol mayor · cinco bemoles</option>
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
          <p class="text-xs font-bold uppercase tracking-wide text-[#718078]">{{ current.family }} · orden acumulado</p>
          <p class="mt-1 text-base font-black text-[#426c5b]">{{ current.order }}</p>
          <p class="mt-2 text-sm font-black text-[#426c5b]">{{ current.altered }}</p>
          <p class="mt-2 text-xs leading-5 text-[#718078]">Melodía de referencia:</p>
          <p class="mt-1 rounded-lg bg-[#edf4ee] p-2 text-center text-sm font-bold leading-6 text-[#365c4c]">{{ current.melody }}</p>
          <p class="mt-2 text-xs leading-5 text-[#718078]">Cada signo se coloca en una posición específica del pentagrama y afecta a todas las octavas de esa nota.</p>
        </div>
      </div>

      <div class="mt-3 flex flex-wrap items-center justify-between gap-3 rounded-lg bg-[#edf4ee] p-3">
        <div>
          <p class="text-xs font-bold text-[#426c5b]">Escucha una nota característica</p>
          <p class="mt-1 text-xs text-[#567267]">{{ current.noteName }} · cuerda {{ current.string }}, traste {{ current.fret }}</p>
        </div>
        <button class="primary px-3 py-2 text-xs" @click="playExample">{{ activeNote ? 'Escuchar otra vez' : 'Escuchar nota' }}</button>
      </div>
      <p v-if="activeNote" class="mt-2 text-xs leading-5 text-[#567267]">{{ current.explanation }}</p>
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
