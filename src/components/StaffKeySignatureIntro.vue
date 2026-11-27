<script setup lang="ts">
import { computed, ref } from 'vue'
import { CheckCircle2, XCircle } from 'lucide-vue-next'
import StaffNote from './StaffNote.vue'
import { playGuitarNote } from '../engines/audio/guitarSound'

type KeyExample = 'C' | 'G' | 'F'

const selectedKey = ref<KeyExample>('G')
const examples = {
  C: {
    name: 'Do mayor',
    signature: 'Sin alteraciones',
    symbol: '',
    altered: 'Ninguna nota queda alterada por la armadura.',
    melody: 'Do · Re · Mi · Fa · Sol · La · Si · Do',
    noteName: 'Fa natural',
    writtenMidi: 77,
    soundingMidi: 65,
    string: 1,
    fret: 1,
    explanation: 'En Do mayor no hay sostenidos ni bemoles en la armadura. Fa se toca natural, salvo que aparezca una alteración accidental.',
  },
  G: {
    name: 'Sol mayor',
    signature: 'Un sostenido: Fa♯',
    symbol: '♯',
    altered: 'Todos los Fa de la pieza se interpretan como Fa sostenido, en cualquier octava.',
    melody: 'Sol · La · Si · Do · Re · Mi · Fa♯ · Sol',
    noteName: 'Fa sostenido',
    writtenMidi: 78,
    soundingMidi: 66,
    string: 1,
    fret: 2,
    explanation: 'La armadura coloca un sostenido en Fa. Por eso, aunque no veas un ♯ junto a cada Fa, debes tocar Fa sostenido.',
  },
  F: {
    name: 'Fa mayor',
    signature: 'Un bemol: Si♭',
    symbol: '♭',
    altered: 'Todos los Si de la pieza se interpretan como Si bemol, en cualquier octava.',
    melody: 'Fa · Sol · La · Si♭ · Do · Re · Mi · Fa',
    noteName: 'Si bemol',
    writtenMidi: 70,
    soundingMidi: 58,
    string: 2,
    fret: 1,
    explanation: 'La armadura coloca un bemol en Si. Por eso, aunque no veas un ♭ junto a cada Si, debes tocar Si bemol.',
  },
} as const

const current = computed(() => examples[selectedKey.value])
const activeNote = ref(false)
const answers = ref<Record<string, string>>({})
const submitted = ref(false)

const quiz = [
  {
    id: 'q1',
    prompt: 'En Sol mayor, ¿cómo se interpreta un Fa aunque no tenga un signo junto a él?',
    options: [{ value: 'natural', label: 'Fa natural' }, { value: 'sharp', label: 'Fa sostenido' }],
    correct: 'sharp',
    explanation: 'El sostenido de la armadura afecta a todos los Fa de la pieza.',
  },
  {
    id: 'q2',
    prompt: '¿Durante cuánto tiempo funciona una armadura?',
    options: [{ value: 'measure', label: 'Solo durante un compás' }, { value: 'piece', label: 'Durante toda la pieza, salvo indicación contraria' }],
    correct: 'piece',
    explanation: 'La armadura se mantiene durante la pieza o hasta que cambie la tonalidad indicada.',
  },
  {
    id: 'q3',
    prompt: 'Si aparece un becuadro delante de Fa en Sol mayor, ¿qué sucede?',
    options: [{ value: 'natural', label: 'Ese Fa se toca natural en ese compás' }, { value: 'sharp', label: 'Sigue siendo Fa sostenido' }],
    correct: 'natural',
    explanation: 'El becuadro cancela temporalmente el efecto de la armadura para esa nota en ese compás; al siguiente compás vuelve a regir la armadura.',
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
      <h2 class="text-lg font-black">La armadura cambia la lectura de toda la pieza</h2>
      <p class="mt-1 text-sm leading-5 text-[#788780]">
        La armadura aparece junto a la clave, al comienzo del pentagrama. Indica qué notas se interpretan alteradas durante toda la pieza, sin tener que escribir el signo cada vez.
      </p>
    </div>

    <div class="grid gap-2 sm:grid-cols-2">
      <div class="rounded-xl bg-[#edf4ee] p-3">
        <p class="text-sm font-black text-[#426c5b]">Alteración accidental</p>
        <p class="mt-1 text-xs leading-5 text-[#567267]">Se escribe junto a una nota y, en la notación tradicional, afecta a esa nota y octava durante el compás.</p>
      </div>
      <div class="rounded-xl bg-[#edf4ee] p-3">
        <p class="text-sm font-black text-[#426c5b]">Armadura</p>
        <p class="mt-1 text-xs leading-5 text-[#567267]">Se escribe junto a la clave y establece las alteraciones para toda la pieza y en todas las octavas.</p>
      </div>
    </div>

    <div class="mt-3 rounded-xl border border-[#dce7df] p-3">
      <label class="block">
        <span class="mb-1 block text-[10px] font-bold uppercase tracking-wide text-[#718078]">Explora tres armaduras básicas</span>
        <select v-model="selectedKey" class="w-full rounded-lg border border-[#dce5dc] bg-white px-3 py-2 text-sm font-semibold text-[#365c4c]" @change="activeNote = false">
          <option value="C">Do mayor · sin alteraciones</option>
          <option value="G">Sol mayor · un sostenido</option>
          <option value="F">Fa mayor · un bemol</option>
        </select>
      </label>

      <div class="mt-3 grid items-center gap-3 sm:grid-cols-[minmax(0,1fr)_minmax(0,1.1fr)]">
        <div class="rounded-xl bg-[#f7f4ed] p-2">
          <p class="text-center text-[10px] font-bold uppercase tracking-wide text-[#718078]">Armadura seleccionada</p>
          <svg viewBox="0 0 260 150" class="mx-auto block w-full max-w-[300px]" role="img" :aria-label="`Clave de sol y armadura de ${current.name}: ${current.signature}`">
            <g stroke="#89958e" stroke-width="1.3">
              <path v-for="i in 5" :key="i" :d="`M 12 ${35 + (i - 1) * 18} H 248`" />
            </g>
            <text x="20" y="101" font-size="66" fill="#176b5b">𝄞</text>
            <text v-if="selectedKey === 'G'" x="112" y="42" font-size="34" fill="#176b5b">♯</text>
            <text v-if="selectedKey === 'F'" x="112" y="75" font-size="34" fill="#176b5b">♭</text>
          </svg>
          <p class="text-center text-sm font-black text-[#176b5b]">{{ current.name }}</p>
          <p class="text-center text-xs text-[#718078]">{{ current.signature }}</p>
        </div>

        <div>
          <p class="text-sm font-black text-[#426c5b]">{{ current.altered }}</p>
          <p class="mt-2 text-xs leading-5 text-[#718078]">Melodía de referencia:</p>
          <p class="mt-1 rounded-lg bg-[#edf4ee] p-2 text-center text-sm font-bold leading-6 text-[#365c4c]">{{ current.melody }}</p>
          <p class="mt-2 text-xs leading-5 text-[#718078]">Observa que el signo de la armadura no necesita repetirse cada vez que aparece la nota afectada.</p>
        </div>
      </div>

      <div class="mt-3 flex flex-wrap items-center justify-between gap-3 rounded-lg bg-[#edf4ee] p-3">
        <div>
          <p class="text-xs font-bold text-[#426c5b]">Escucha una nota característica</p>
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
