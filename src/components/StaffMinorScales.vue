<script setup lang="ts">
import { computed, ref } from 'vue'
import { CheckCircle2, XCircle, ArrowRight, RotateCcw } from 'lucide-vue-next'

type ScaleKind = 'natural' | 'harmonic' | 'melodic'
type MinorScale = {
  id: ScaleKind
  name: string
  degrees: string[]
  notes: string[]
  semitones: number[]
  description: string
  character: string
}

const scales: MinorScale[] = [
  {
    id: 'natural',
    name: 'Menor natural',
    degrees: ['1', '2', '♭3', '4', '5', '♭6', '♭7'],
    notes: ['La', 'Si', 'Do', 'Re', 'Mi', 'Fa', 'Sol', 'La'],
    semitones: [2, 1, 2, 2, 1, 2, 2],
    description: 'Es la forma básica de la escala menor. Comparte la armadura con Do mayor, su tonalidad relativa.',
    character: 'Su sonido se apoya en la séptima menor (Sol), sin sensible que conduzca por semitono hacia La.',
  },
  {
    id: 'harmonic',
    name: 'Menor armónica',
    degrees: ['1', '2', '♭3', '4', '5', '♭6', '7'],
    notes: ['La', 'Si', 'Do', 'Re', 'Mi', 'Fa', 'Sol♯', 'La'],
    semitones: [2, 1, 2, 2, 1, 3, 1],
    description: 'Se obtiene elevando el séptimo grado de la menor natural: Sol pasa a Sol♯.',
    character: 'La sensible (Sol♯) queda a un semitono de la tónica. Entre el sexto y el séptimo grado aparece una segunda aumentada.',
  },
  {
    id: 'melodic',
    name: 'Menor melódica',
    degrees: ['1', '2', '♭3', '4', '5', '6', '7'],
    notes: ['La', 'Si', 'Do', 'Re', 'Mi', 'Fa♯', 'Sol♯', 'La'],
    semitones: [2, 1, 2, 2, 2, 2, 1],
    description: 'En la forma clásica ascendente se elevan el sexto y el séptimo grado respecto de la menor natural.',
    character: 'Al subir, Fa pasa a Fa♯ y Sol a Sol♯. En la forma clásica, al bajar se recupera la menor natural.',
  },
]

type Question = { prompt: string; options: string[]; correct: string; explanation: string }
const shuffle = <T,>(items: T[]): T[] => [...items].sort(() => Math.random() - 0.5)
const questionBank: Question[] = [
  { prompt: '¿Qué grado distingue principalmente a la menor armónica de la menor natural?', options: ['El tercer grado', 'El sexto grado', 'El séptimo grado', 'El segundo grado'], correct: 'El séptimo grado', explanation: 'La menor armónica eleva el séptimo grado: en La menor, Sol se convierte en Sol♯.' },
  { prompt: '¿Qué grados se elevan en la menor melódica clásica ascendente?', options: ['El segundo y el tercero', 'El sexto y el séptimo', 'El tercero y el quinto', 'El cuarto y el sexto'], correct: 'El sexto y el séptimo', explanation: 'En La menor melódica ascendente, Fa pasa a Fa♯ y Sol pasa a Sol♯.' },
  { prompt: '¿Qué notas forman La menor natural?', options: ['La–Si–Do–Re–Mi–Fa–Sol–La', 'La–Si–Do–Re–Mi–Fa–Sol♯–La', 'La–Si–Do–Re–Mi–Fa♯–Sol♯–La', 'La–Si–Do♯–Re–Mi–Fa–Sol–La'], correct: 'La–Si–Do–Re–Mi–Fa–Sol–La', explanation: 'La menor natural utiliza las notas naturales de Do mayor, comenzando y terminando en La.' },
  { prompt: '¿Qué nota funciona como sensible en La menor armónica?', options: ['Fa', 'Sol', 'Sol♯', 'Si'], correct: 'Sol♯', explanation: 'Sol♯ está a un semitono por debajo de La y tiende a resolver hacia la tónica.' },
  { prompt: '¿Qué intervalo aparece entre el sexto y el séptimo grado de la menor armónica?', options: ['Segunda menor', 'Segunda mayor', 'Segunda aumentada', 'Tercera menor'], correct: 'Segunda aumentada', explanation: 'En La menor armónica, Fa–Sol♯ forma una segunda aumentada de tres semitonos.' },
  { prompt: 'En la forma clásica de la menor melódica, ¿qué sucede al descender?', options: ['Se mantienen elevados los grados 6 y 7', 'Se desciende como menor natural', 'Se baja solo el séptimo grado', 'Se baja solo el sexto grado'], correct: 'Se desciende como menor natural', explanation: 'La forma clásica utiliza los grados 6 y 7 elevados al subir y recupera los grados naturales al bajar.' },
  { prompt: '¿Cuál es la relativa mayor de La menor natural?', options: ['Sol mayor', 'Fa mayor', 'Do mayor', 'Mi mayor'], correct: 'Do mayor', explanation: 'La menor y Do mayor comparten la misma armadura: ninguna alteración.' },
  { prompt: '¿Qué patrón de tonos y semitonos corresponde a la menor natural?', options: ['T–S–T–T–S–T–T', 'T–S–T–T–S–3S–S', 'T–S–T–T–T–T–S', 'S–T–T–T–S–T–T'], correct: 'T–S–T–T–S–T–T', explanation: 'La menor natural sigue el patrón tono–semitono–tono–tono–semitono–tono–tono.' },
]

const selected = ref<ScaleKind>('natural')
const current = computed(() => scales.find(scale => scale.id === selected.value) ?? scales[0])
const questions = ref<Question[]>([])
const index = ref(0)
const chosen = ref('')
const checked = ref(false)
const score = ref(0)
const finished = ref(false)
const currentQuestion = computed(() => questions.value[index.value])
const progress = computed(() => questions.value.length
  ? Math.round(((index.value + (checked.value ? 1 : 0)) / questions.value.length) * 100)
  : 0)

function start() {
  questions.value = shuffle(questionBank).slice(0, 8)
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
      <p class="eyebrow">Lectura musical · Escalas menores</p>
      <h2 class="text-lg font-black">Menor natural, armónica y melódica</h2>
      <p class="mt-1 text-sm leading-5 text-[#788780]">
        Las tres formas parten de una misma escala menor. Los cambios en el sexto y el séptimo grado modifican su sonido y la fuerza con que la melodía conduce hacia la tónica.
      </p>
    </div>

    <div class="rounded-xl bg-[#edf4ee] p-3">
      <p class="text-sm font-black text-[#426c5b]">Construcción a partir de La menor</p>
      <p class="mt-1 text-xs leading-5 text-[#567267]">
        La menor natural comparte armadura con Do mayor. Para estudiar sus otras formas, conservamos la tónica La y modificamos algunos grados de la escala.
      </p>
    </div>

    <div class="mt-3 grid gap-2 sm:grid-cols-3">
      <button
        v-for="scale in scales"
        :key="scale.id"
        class="rounded-lg border-2 px-3 py-2.5 text-left transition"
        :class="selected === scale.id ? 'border-[#4c9c7c] bg-[#edf4ee]' : 'border-[#e1e8e0] bg-white'"
        @click="selected = scale.id"
      >
        <span class="block text-xs font-black text-[#365c4c]">{{ scale.name }}</span>
        <span class="mt-1 block text-[10px] text-[#718078]">{{ scale.id === 'natural' ? 'Sin alteraciones añadidas' : scale.id === 'harmonic' ? 'Séptimo grado elevado' : 'Sexto y séptimo elevados' }}</span>
      </button>
    </div>

    <div class="mt-3 rounded-xl border border-[#dce7df] p-3">
      <p class="eyebrow">Escala seleccionada</p>
      <h3 class="mt-1 text-base font-black text-[#365c4c]">{{ current.name }}</h3>
      <p class="mt-1 text-xs leading-5 text-[#718078]">{{ current.description }}</p>

      <div class="mt-3 overflow-x-auto">
        <table class="w-full min-w-[430px] border-separate border-spacing-1 text-center">
          <thead>
            <tr>
              <th class="rounded bg-[#f3f6f1] px-2 py-2 text-[10px] text-[#718078]">Grado</th>
              <th v-for="(degree, i) in current.degrees" :key="i" class="rounded bg-[#f3f6f1] px-2 py-2 text-xs font-bold text-[#567267]">{{ degree }}</th>
              <th class="rounded bg-[#f3f6f1] px-2 py-2 text-xs font-bold text-[#567267]">1</th>
            </tr>
          </thead>
          <tbody>
            <tr>
              <th class="rounded bg-[#f3f6f1] px-2 py-2 text-[10px] text-[#718078]">Nota</th>
              <td v-for="(note, i) in current.notes.slice(0, 7)" :key="i" class="rounded bg-[#edf4ee] px-2 py-2 text-xs font-black text-[#365c4c]">{{ note }}</td>
              <td class="rounded bg-[#edf4ee] px-2 py-2 text-xs font-black text-[#365c4c]">La</td>
            </tr>
            <tr>
              <th class="rounded bg-[#f3f6f1] px-2 py-2 text-[10px] text-[#718078]">Distancia</th>
              <td v-for="(step, i) in current.semitones" :key="i" class="rounded bg-[#f7f4ed] px-2 py-2 text-[10px] font-bold text-[#718078]">{{ step === 1 ? 'S' : step === 2 ? 'T' : '3S' }}</td>
              <td class="rounded bg-[#f7f4ed] px-2 py-2 text-[10px] text-[#718078]">—</td>
            </tr>
          </tbody>
        </table>
      </div>
      <p class="mt-2 text-[10px] text-[#829087]">T = tono (2 semitonos) · S = semitono · 3S = tres semitonos.</p>
      <div v-if="selected === 'melodic'" class="mt-3 rounded-lg bg-[#edf4ee] p-3">
        <p class="text-xs font-black text-[#426c5b]">Descenso en la forma clásica</p>
        <p class="mt-1 text-sm font-bold tracking-wide text-[#365c4c]">La – Sol – Fa – Mi – Re – Do – Si – La</p>
        <p class="mt-1 text-[10px] leading-4 text-[#718078]">Al descender se utilizan el sexto y el séptimo grado naturales. En el enfoque moderno de menor melódica (jazz), suele conservarse la misma forma ascendente en ambas direcciones.</p>
      </div>

      <div class="mt-3 rounded-lg bg-[#f7f4ed] p-3">
        <p class="text-xs font-black text-[#426c5b]">¿Qué debes escuchar y reconocer?</p>
        <p class="mt-1 text-xs leading-5 text-[#567267]">{{ current.character }}</p>
      </div>
    </div>

    <div class="mt-3 rounded-xl bg-[#f7f4ed] p-3">
      <template v-if="!finished">
        <div class="mb-3 flex items-center justify-between gap-2">
          <div>
            <p class="eyebrow">Práctica de reconocimiento</p>
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
        <p class="mt-2 text-sm text-[#718078]">{{ score >= 7 ? '¡Excelente! Distingues las tres formas de la escala menor.' : 'Repasa los grados modificados y vuelve a intentarlo.' }}</p>
        <button class="primary mt-4 inline-flex items-center gap-2 px-4 py-2 text-xs" @click="start">
          <RotateCcw :size="14" /> Repetir práctica
        </button>
      </div>
    </div>
  </section>
</template>
