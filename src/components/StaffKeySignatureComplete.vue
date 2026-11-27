<script setup lang="ts">
import { computed, ref } from 'vue'
import { CheckCircle2, XCircle } from 'lucide-vue-next'
import { playGuitarNote } from '../engines/audio/guitarSound'
import StaffNote from './StaffNote.vue'
import type { SpelledNote } from '../engines/music/musicTheory'

type KeyExample = 'Fsharp' | 'Csharp' | 'Gb' | 'Cb'

const examples = {
  Fsharp: {
    name: 'Fa sostenido mayor',
    signature: 'Seis sostenidos: Fa♯, Do♯, Sol♯, Re♯, La♯ y Mi♯',
    family: 'Sostenidos',
    order: 'Fa → Do → Sol → Re → La → Mi',
    symbols: [
      { x: 142, y: 45 }, { x: 174, y: 72 }, { x: 206, y: 36 },
      { x: 238, y: 63 }, { x: 270, y: 90 }, { x: 302, y: 54 },
    ],
    altered: 'Todos los Fa, Do, Sol, Re, La y Mi se interpretan sostenidos.',
    melody: 'Fa♯ · Sol♯ · La♯ · Si · Do♯ · Re♯ · Mi♯ · Fa♯',
    noteName: 'Fa sostenido',
    writtenMidi: 78,
    soundingMidi: 66,
    spelling: { letter: 'Fa', accidental: 1, octave: 5 },
    string: 1,
    fret: 2,
    explanation: 'Fa sostenido suena en la primera cuerda, traste 2. Mi sostenido también forma parte de esta armadura.',
  },
  Csharp: {
    name: 'Do sostenido mayor',
    signature: 'Siete sostenidos: Fa♯, Do♯, Sol♯, Re♯, La♯, Mi♯ y Si♯',
    family: 'Sostenidos',
    order: 'Fa → Do → Sol → Re → La → Mi → Si',
    symbols: [
      { x: 142, y: 45 }, { x: 174, y: 72 }, { x: 206, y: 36 },
      { x: 238, y: 63 }, { x: 270, y: 90 }, { x: 302, y: 54 },
      { x: 334, y: 81 },
    ],
    altered: 'Todos los Fa, Do, Sol, Re, La, Mi y Si se interpretan sostenidos.',
    melody: 'Do♯ · Re♯ · Mi♯ · Fa♯ · Sol♯ · La♯ · Si♯ · Do♯',
    noteName: 'Si sostenido',
    writtenMidi: 84,
    soundingMidi: 72,
    spelling: { letter: 'Si', accidental: 1, octave: 5 },
    string: 1,
    fret: 8,
    explanation: 'Si sostenido suena en la primera cuerda, traste 8. Enarmónicamente tiene la misma altura que Do natural.',
  },
  Gb: {
    name: 'Sol bemol mayor',
    signature: 'Seis bemoles: Si♭, Mi♭, La♭, Re♭, Sol♭ y Do♭',
    family: 'Bemoles',
    order: 'Si → Mi → La → Re → Sol → Do',
    symbols: [
      { x: 142, y: 81 }, { x: 174, y: 54 }, { x: 206, y: 90 },
      { x: 238, y: 63 }, { x: 270, y: 99 }, { x: 302, y: 72 },
    ],
    altered: 'Todos los Si, Mi, La, Re, Sol y Do se interpretan bemoles.',
    melody: 'Sol♭ · La♭ · Si♭ · Do♭ · Re♭ · Mi♭ · Fa · Sol♭',
    noteName: 'Do bemol',
    writtenMidi: 71,
    soundingMidi: 59,
    spelling: { letter: 'Do', accidental: -1, octave: 5 },
    string: 2,
    fret: 0,
    explanation: 'Do bemol se toca en la segunda cuerda al aire: suena como Si natural. Es el sexto bemol de la secuencia.',
  },
  Cb: {
    name: 'Do bemol mayor',
    signature: 'Siete bemoles: Si♭, Mi♭, La♭, Re♭, Sol♭, Do♭ y Fa♭',
    family: 'Bemoles',
    order: 'Si → Mi → La → Re → Sol → Do → Fa',
    symbols: [
      { x: 142, y: 81 }, { x: 174, y: 54 }, { x: 206, y: 90 },
      { x: 238, y: 63 }, { x: 270, y: 99 }, { x: 302, y: 72 },
      { x: 334, y: 108 },
    ],
    altered: 'Todos los Si, Mi, La, Re, Sol, Do y Fa se interpretan bemoles.',
    melody: 'Do♭ · Re♭ · Mi♭ · Fa♭ · Sol♭ · La♭ · Si♭ · Do♭',
    noteName: 'Fa bemol',
    writtenMidi: 76,
    soundingMidi: 64,
    spelling: { letter: 'Fa', accidental: -1, octave: 5 },
    string: 1,
    fret: 0,
    explanation: 'Fa bemol se toca en la primera cuerda al aire: suena como Mi natural. Con él se completa el orden de siete bemoles.',
  },
} as const

const selectedKey = ref<KeyExample>('Fsharp')
const current = computed(() => examples[selectedKey.value])
const activeNote = ref(false)
const answers = ref<Record<string, string>>({})
const submitted = ref(false)

const quiz = [
  {
    id: 'q1',
    prompt: '¿Cuál es el sexto sostenido que se añade a la armadura?',
    options: [{ value: 'a', label: 'Mi♯' }, { value: 'b', label: 'Si♯' }],
    correct: 'a',
    explanation: 'El orden de sostenidos es Fa, Do, Sol, Re, La, Mi y Si.',
  },
  {
    id: 'q2',
    prompt: '¿Qué alteración completa la armadura de siete bemoles?',
    options: [{ value: 'a', label: 'Do♭' }, { value: 'b', label: 'Fa♭' }],
    correct: 'b',
    explanation: 'Fa bemol es el séptimo y último bemol del orden.',
  },
  {
    id: 'q3',
    prompt: '¿Qué nota suena en la guitarra al tocar Fa♭4 escrito?',
    options: [{ value: 'a', label: 'Mi4' }, { value: 'b', label: 'Fa4' }],
    correct: 'a',
    explanation: 'Fa bemol es enarmónico de Mi natural; en la primera cuerda al aire suena Mi4.',
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
      <h2 class="text-lg font-black">Seis y siete alteraciones</h2>
      <p class="mt-1 text-sm leading-5 text-[#788780]">
        La secuencia sigue creciendo: no cambia el orden, solo se incorpora el siguiente sostenido o bemol. Con siete signos se completa la serie.
      </p>
    </div>

    <div class="grid gap-2 sm:grid-cols-2">
      <div class="rounded-xl bg-[#edf4ee] p-3">
        <p class="text-sm font-black text-[#426c5b]">Sostenidos · sexto y séptimo</p>
        <p class="mt-1 text-sm font-bold text-[#365c4c]">Mi♯ → Si♯</p>
        <p class="mt-1 text-xs leading-5 text-[#567267]">Fa – Do – Sol – Re – La – Mi – Si</p>
      </div>
      <div class="rounded-xl bg-[#edf4ee] p-3">
        <p class="text-sm font-black text-[#426c5b]">Bemoles · sexto y séptimo</p>
        <p class="mt-1 text-sm font-bold text-[#365c4c]">Do♭ → Fa♭</p>
        <p class="mt-1 text-xs leading-5 text-[#567267]">Si – Mi – La – Re – Sol – Do – Fa</p>
      </div>
    </div>

    <div class="mt-3 rounded-xl border border-[#dce7df] p-3">
      <label class="block">
        <span class="mb-1 block text-[10px] font-bold uppercase tracking-wide text-[#718078]">Explora las armaduras</span>
        <select v-model="selectedKey" class="w-full rounded-lg border border-[#dce5dc] bg-white px-3 py-2 text-sm font-semibold text-[#365c4c]" @change="activeNote = false">
          <option value="Fsharp">Fa sostenido mayor · seis sostenidos</option>
          <option value="Csharp">Do sostenido mayor · siete sostenidos</option>
          <option value="Gb">Sol bemol mayor · seis bemoles</option>
          <option value="Cb">Do bemol mayor · siete bemoles</option>
        </select>
      </label>

      <div class="mt-3 grid items-center gap-3 sm:grid-cols-[minmax(0,1fr)_minmax(0,1.1fr)]">
        <div class="rounded-xl bg-[#f7f4ed] p-2">
          <p class="text-center text-[10px] font-bold uppercase tracking-wide text-[#718078]">Armadura seleccionada</p>
          <svg viewBox="0 0 350 145" class="mx-auto block w-full max-w-[340px]" role="img" :aria-label="`Clave de sol y armadura de ${current.name}: ${current.signature}`">
            <g stroke="#89958e" stroke-width="1.3">
              <path v-for="i in 5" :key="i" :d="`M 12 ${45 + (i - 1) * 18} H 340`" />
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
            >{{ selectedKey === 'Fsharp' || selectedKey === 'Csharp' ? '♯' : '♭' }}</text>
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
          <p class="mt-2 text-xs leading-5 text-[#718078]">Cada signo ocupa una posición fija del pentagrama y afecta a todas las octavas de esa nota.</p>
        </div>
      </div>

      <div class="mt-3 flex flex-wrap items-center justify-between gap-3 rounded-lg bg-[#edf4ee] p-3">
        <div>
          <p class="text-xs font-bold text-[#426c5b]">Escucha una nota característica</p>
          <p class="mt-1 text-xs text-[#567267]">{{ current.noteName }} · cuerda {{ current.string }}, {{ current.fret === 0 ? 'al aire' : `traste ${current.fret}` }}</p>
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
