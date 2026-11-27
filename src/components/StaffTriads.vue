<script setup lang="ts">
import { computed, ref } from 'vue'
import { ArrowRight, CheckCircle2, RotateCcw, XCircle } from 'lucide-vue-next'
import { buildTriad, type TriadQuality } from '../engines/music/musicTheory'

type Chord = {
  quality: TriadQuality
  name: string
  symbol: string
  notes: string[]
  degrees: string[]
  intervals: number[]
  formula: string
  structure: string
  description: string
}
const chords: Chord[] = [
  {
    quality: 'major',
    name: 'Tríada mayor',
    symbol: 'Do',
    notes: ['Do', 'Mi', 'Sol'],
    degrees: ['1', '3', '5'],
    intervals: [0, 4, 7],
    formula: '3.ª mayor + 3.ª menor',
    structure: '4 + 3 semitonos',
    description: 'Tiene una tercera mayor desde la fundamental y una tercera menor desde la tercera hasta la quinta. Es la estructura básica del acorde mayor.',
  },
  {
    quality: 'minor',
    name: 'Tríada menor',
    symbol: 'Dom',
    notes: ['Do', 'Mi♭', 'Sol'],
    degrees: ['1', '♭3', '5'],
    intervals: [0, 3, 7],
    formula: '3.ª menor + 3.ª mayor',
    structure: '3 + 4 semitonos',
    description: 'Se forma con una tercera menor y luego una tercera mayor. Respecto de la tríada mayor, la tercera baja un semitono.',
  },
  {
    quality: 'diminished',
    name: 'Tríada disminuida',
    symbol: 'Do°',
    notes: ['Do', 'Mi♭', 'Sol♭'],
    degrees: ['1', '♭3', '♭5'],
    intervals: [0, 3, 6],
    formula: '3.ª menor + 3.ª menor',
    structure: '3 + 3 semitonos',
    description: 'Tiene dos terceras menores superpuestas. La quinta queda disminuida, a seis semitonos de la fundamental.',
  },
  {
    quality: 'augmented',
    name: 'Tríada aumentada',
    symbol: 'Do+',
    notes: ['Do', 'Mi', 'Sol♯'],
    degrees: ['1', '3', '♯5'],
    intervals: [0, 4, 8],
    formula: '3.ª mayor + 3.ª mayor',
    structure: '4 + 4 semitonos',
    description: 'Tiene dos terceras mayores superpuestas. La quinta se eleva un semitono y se convierte en quinta aumentada.',
  },
]
const selectedQuality = ref<TriadQuality>('major')
const current = computed(() => chords.find(chord => chord.quality === selectedQuality.value) ?? chords[0])
const generatedMidi = computed(() => buildTriad(60, selectedQuality.value))
const questionBank = [
  { prompt: '¿Qué intervalos forman una tríada mayor desde la fundamental?', options: ['Tercera mayor y tercera menor', 'Dos terceras menores', 'Dos terceras mayores', 'Tercera menor y tercera mayor'], correct: 'Tercera mayor y tercera menor', explanation: 'La tríada mayor se construye con 4 semitonos y luego 3: Do–Mi–Sol.' },
  { prompt: '¿Qué nota cambia entre Do mayor y Do menor?', options: ['Do', 'Mi', 'Sol', 'Cambian las tres'], correct: 'Mi', explanation: 'La tercera baja de Mi a Mi♭. La fundamental y la quinta permanecen iguales.' },
  { prompt: '¿Cuántos semitonos separan la fundamental de la quinta disminuida?', options: ['5', '6', '7', '8'], correct: '6', explanation: 'La quinta disminuida se encuentra a seis semitonos de la fundamental.' },
  { prompt: '¿Qué estructura tiene la tríada aumentada?', options: ['3 + 3', '3 + 4', '4 + 3', '4 + 4'], correct: '4 + 4', explanation: 'Está formada por dos terceras mayores superpuestas: Do–Mi y Mi–Sol♯.' },
  { prompt: '¿Qué grados forman una tríada menor?', options: ['1–3–5', '1–♭3–5', '1–♭3–♭5', '1–3–♯5'], correct: '1–♭3–5', explanation: 'La tríada menor conserva la quinta justa y tiene tercera menor.' },
  { prompt: '¿Qué símbolo suele representar una tríada disminuida?', options: ['m', '°', '+', 'maj7'], correct: '°', explanation: 'El círculo pequeño (°) indica acorde disminuido.' },
  { prompt: 'Si apilamos una tercera menor y otra tercera menor desde Do, ¿qué acorde obtenemos?', options: ['Do mayor', 'Do menor', 'Do disminuido', 'Do aumentado'], correct: 'Do disminuido', explanation: 'Do–Mi♭ y Mi♭–Sol♭ son dos terceras menores.' },
  { prompt: '¿Cuál es la fórmula de una tríada mayor en grados?', options: ['1–♭3–5', '1–3–5', '1–♭3–♭5', '1–3–♯5'], correct: '1–3–5', explanation: 'La tríada mayor contiene fundamental, tercera mayor y quinta justa.' },
]
const questions = ref<typeof questionBank>([])
const index = ref(0)
const chosen = ref('')
const checked = ref(false)
const score = ref(0)
const finished = ref(false)
const currentQuestion = computed(() => questions.value[index.value])
const progress = computed(() => questions.value.length
  ? Math.round(((index.value + (checked.value ? 1 : 0)) / questions.value.length) * 100)
  : 0)
const shuffle = <T,>(items: readonly T[]): T[] => [...items].sort(() => Math.random() - 0.5)

function start() {
  questions.value = shuffle(questionBank)
  index.value = 0
  chosen.value = ''
  checked.value = false
  score.value = 0
  finished.value = false
}
function check() {
  if (!currentQuestion.value || !chosen.value || checked.value) return
  checked.value = true
  if (chosen.value === currentQuestion.value.correct) score.value++
}
function next() {
  if (index.value + 1 >= questions.value.length) {
    finished.value = true
    return
  }
  index.value++
  chosen.value = ''
  checked.value = false
}
start()
</script>

<template>
  <section class="panel mb-4 p-3 sm:p-4">
    <div class="mb-3">
      <p class="eyebrow">Armonía · Construcción de acordes</p>
      <h2 class="text-lg font-black">Tríadas: acordes de tres notas</h2>
      <p class="mt-1 text-sm leading-5 text-[#788780]">
        Una tríada se construye superponiendo dos terceras. La combinación de terceras determina su cualidad: mayor, menor, disminuida o aumentada.
      </p>
    </div>

    <div class="grid gap-2 sm:grid-cols-2">
      <div class="rounded-xl bg-[#edf4ee] p-3">
        <p class="text-sm font-black text-[#426c5b]">Fundamental (1)</p>
        <p class="mt-1 text-xs leading-5 text-[#567267]">Es la nota que da nombre al acorde y funciona como punto de partida.</p>
      </div>
      <div class="rounded-xl bg-[#edf4ee] p-3">
        <p class="text-sm font-black text-[#426c5b]">Tercera y quinta</p>
        <p class="mt-1 text-xs leading-5 text-[#567267]">La tercera define principalmente si el acorde es mayor o menor. La quinta puede ser justa, disminuida o aumentada.</p>
      </div>
    </div>

    <div class="mt-3 rounded-xl border border-[#dce7df] p-3">
      <p class="eyebrow">Explora las cuatro cualidades</p>
      <div class="mt-2 grid grid-cols-2 gap-2 sm:grid-cols-4">
        <button
          v-for="chord in chords"
          :key="chord.quality"
          class="rounded-lg border-2 px-2.5 py-2 text-left transition"
          :class="selectedQuality === chord.quality ? 'border-[#4c9c7c] bg-[#edf4ee]' : 'border-[#e1e8e0] bg-white'"
          @click="selectedQuality = chord.quality"
        >
          <span class="block text-xs font-black text-[#365c4c]">{{ chord.name.replace('Tríada ', '') }}</span>
          <span class="mt-1 block text-[10px] text-[#718078]">{{ chord.symbol }}</span>
        </button>
      </div>

      <div class="mt-3 rounded-xl bg-[#f5f8f4] p-3">
        <div class="flex flex-wrap items-start justify-between gap-2">
          <div>
            <p class="text-xs font-black text-[#426c5b]">{{ current.name }}</p>
            <p class="mt-1 text-xl font-black tracking-wide text-[#365c4c]">{{ current.notes.join(' – ') }}</p>
          </div>
          <span class="rounded-full bg-white px-2.5 py-1 text-[11px] font-bold text-[#426c5b]">{{ current.symbol }}</span>
        </div>
        <div class="mt-3 grid grid-cols-3 gap-2">
          <div v-for="(note, i) in current.notes" :key="note" class="rounded-lg bg-white p-2 text-center">
            <p class="text-[10px] font-semibold text-[#829087]">{{ ['Fundamental', 'Tercera', 'Quinta'][i] }}</p>
            <p class="mt-1 text-sm font-black text-[#365c4c]">{{ note }}</p>
            <p class="mt-0.5 text-[10px] text-[#718078]">Grado {{ current.degrees[i] }}</p>
          </div>
        </div>
        <div class="mt-3 grid gap-2 sm:grid-cols-2">
          <div class="rounded-lg bg-white p-2.5">
            <p class="text-[10px] font-bold uppercase tracking-wide text-[#829087]">Terceras superpuestas</p>
            <p class="mt-1 text-sm font-black text-[#365c4c]">{{ current.formula }}</p>
            <p class="mt-0.5 text-[10px] text-[#718078]">{{ current.structure }}</p>
          </div>
          <div class="rounded-lg bg-white p-2.5">
            <p class="text-[10px] font-bold uppercase tracking-wide text-[#829087]">Distancias desde Do</p>
            <p class="mt-1 text-sm font-black text-[#365c4c]">{{ current.intervals.join(' – ') }} semitonos</p>
            <p class="mt-0.5 text-[10px] text-[#718078]">Fundamental · tercera · quinta</p>
          </div>
        </div>
        <p class="mt-3 text-xs leading-5 text-[#567267]">{{ current.description }}</p>
        <p class="mt-2 rounded-lg bg-white px-3 py-2 text-[10px] leading-4 text-[#718078]">
          El motor musical genera las alturas MIDI de esta tríada: {{ generatedMidi.join(', ') }}. La raíz del ejemplo es Do4.
        </p>
      </div>
    </div>

    <div class="mt-3 rounded-xl bg-[#f7f4ed] p-3">
      <p class="text-xs font-black text-[#426c5b]">Resumen de fórmulas</p>
      <div class="mt-2 overflow-x-auto">
        <table class="w-full min-w-[360px] text-left text-xs">
          <thead>
            <tr class="border-b border-[#e5ebe4] text-[10px] uppercase tracking-wide text-[#829087]">
              <th class="px-2 py-2">Acorde</th>
              <th class="px-2 py-2">Grados</th>
              <th class="px-2 py-2">Semitonos</th>
            </tr>
          </thead>
          <tbody>
            <tr v-for="chord in chords" :key="chord.quality" class="border-b border-[#e8e9e1]">
              <td class="px-2 py-2 font-bold text-[#365c4c]">{{ chord.name }}</td>
              <td class="px-2 py-2 text-[#567267]">{{ chord.degrees.join(' – ') }}</td>
              <td class="px-2 py-2 text-[#567267]">{{ chord.intervals.join(' – ') }}</td>
            </tr>
          </tbody>
        </table>
      </div>
      <p class="mt-2 text-[10px] leading-4 text-[#829087]">Los números de semitonos se cuentan desde la fundamental. Para formar el acorde, también se puede sumar la distancia entre cada nota consecutiva.</p>
    </div>

    <div class="mt-3 rounded-xl bg-[#f7f4ed] p-3">
      <template v-if="!finished">
        <div class="mb-3 flex items-center justify-between gap-2">
          <div>
            <p class="eyebrow">Práctica de construcción</p>
            <h3 class="text-base font-black">Pregunta {{ index + 1 }} de {{ questions.length }}</h3>
          </div>
          <span class="rounded-full bg-white px-2.5 py-1 text-[11px] font-bold text-[#426c5b]">{{ score }} correctas</span>
        </div>
        <div class="mb-3 h-1.5 overflow-hidden rounded-full bg-[#e4e9e2]">
          <div class="h-full rounded-full bg-[#4c9c7c] transition-all" :style="{ width: progress + '%' }"></div>
        </div>
        <p class="text-sm font-bold leading-6 text-[#365c4c]">{{ currentQuestion?.prompt }}</p>
        <div class="mt-3 grid gap-2 sm:grid-cols-2">
          <button
            v-for="option in currentQuestion?.options"
            :key="option"
            class="rounded-lg border-2 bg-white px-3 py-2.5 text-left text-xs font-semibold transition"
            :class="checked && option === currentQuestion?.correct ? 'border-[#4c9c7c] bg-[#edf4ee] text-[#226447]' : chosen === option ? 'border-[#8aa99a] bg-[#eef4ef]' : 'border-transparent'"
            :disabled="checked"
            @click="chosen = option"
          >
            {{ option }}
          </button>
        </div>
        <div v-if="checked" class="mt-3 rounded-lg p-3" :class="chosen === currentQuestion?.correct ? 'bg-[#e9f5ed] text-[#226447]' : 'bg-[#fff1e9] text-[#a14f2d]'">
          <p class="flex items-center gap-1.5 text-xs font-black">
            <CheckCircle2 v-if="chosen === currentQuestion?.correct" :size="15" />
            <XCircle v-else :size="15" />
            {{ chosen === currentQuestion?.correct ? '¡Correcto!' : 'La respuesta correcta es: ' + currentQuestion?.correct + '.' }}
          </p>
          <p class="mt-1 text-xs leading-5">{{ currentQuestion?.explanation }}</p>
        </div>
        <div class="mt-3 flex justify-end">
          <button v-if="!checked" class="primary px-4 py-2 text-xs" :disabled="!chosen" @click="check">Comprobar</button>
          <button v-else class="primary flex items-center gap-1.5 px-4 py-2 text-xs" @click="next">
            {{ index + 1 === questions.length ? 'Ver resultado' : 'Siguiente' }} <ArrowRight :size="14" />
          </button>
        </div>
      </template>
      <div v-else class="py-3 text-center">
        <p class="eyebrow">Práctica terminada</p>
        <h3 class="mt-1 text-2xl font-black text-[#365c4c]">{{ score }} / {{ questions.length }}</h3>
        <p class="mt-2 text-sm text-[#718078]">{{ score >= 6 ? '¡Excelente! Reconoces las estructuras de las cuatro tríadas.' : 'Repasa cómo se superponen las terceras y vuelve a intentarlo.' }}</p>
        <button class="primary mt-4 inline-flex items-center gap-2 px-4 py-2 text-xs" @click="start">
          <RotateCcw :size="14" /> Repetir práctica
        </button>
      </div>
    </div>
  </section>
</template>
