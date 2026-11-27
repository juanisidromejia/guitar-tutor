<script setup lang="ts">
import { computed, ref } from 'vue'
import { CheckCircle2, XCircle, ArrowRight, RotateCcw } from 'lucide-vue-next'

type RelativePair = {
  major: string
  minor: string
  count: number
  signs: string
  family: 'sin alteraciones' | 'sostenidos' | 'bemoles'
}

const pairs: RelativePair[] = [
  { major: 'Do mayor', minor: 'La menor', count: 0, signs: 'ninguna', family: 'sin alteraciones' },
  { major: 'Sol mayor', minor: 'Mi menor', count: 1, signs: 'Fa♯', family: 'sostenidos' },
  { major: 'Re mayor', minor: 'Si menor', count: 2, signs: 'Fa♯, Do♯', family: 'sostenidos' },
  { major: 'La mayor', minor: 'Fa♯ menor', count: 3, signs: 'Fa♯, Do♯, Sol♯', family: 'sostenidos' },
  { major: 'Mi mayor', minor: 'Do♯ menor', count: 4, signs: 'Fa♯, Do♯, Sol♯, Re♯', family: 'sostenidos' },
  { major: 'Si mayor', minor: 'Sol♯ menor', count: 5, signs: 'Fa♯, Do♯, Sol♯, Re♯, La♯', family: 'sostenidos' },
  { major: 'Fa♯ mayor', minor: 'Re♯ menor', count: 6, signs: 'Fa♯, Do♯, Sol♯, Re♯, La♯, Mi♯', family: 'sostenidos' },
  { major: 'Do♯ mayor', minor: 'La♯ menor', count: 7, signs: 'Fa♯, Do♯, Sol♯, Re♯, La♯, Mi♯, Si♯', family: 'sostenidos' },
  { major: 'Fa mayor', minor: 'Re menor', count: 1, signs: 'Si♭', family: 'bemoles' },
  { major: 'Si♭ mayor', minor: 'Sol menor', count: 2, signs: 'Si♭, Mi♭', family: 'bemoles' },
  { major: 'Mi♭ mayor', minor: 'Do menor', count: 3, signs: 'Si♭, Mi♭, La♭', family: 'bemoles' },
  { major: 'La♭ mayor', minor: 'Fa menor', count: 4, signs: 'Si♭, Mi♭, La♭, Re♭', family: 'bemoles' },
  { major: 'Re♭ mayor', minor: 'Si♭ menor', count: 5, signs: 'Si♭, Mi♭, La♭, Re♭, Sol♭', family: 'bemoles' },
  { major: 'Sol♭ mayor', minor: 'Mi♭ menor', count: 6, signs: 'Si♭, Mi♭, La♭, Re♭, Sol♭, Do♭', family: 'bemoles' },
  { major: 'Do♭ mayor', minor: 'La♭ menor', count: 7, signs: 'Si♭, Mi♭, La♭, Re♭, Sol♭, Do♭, Fa♭', family: 'bemoles' },
]

type Question = { prompt: string; options: string[]; correct: string; explanation: string }
const shuffle = <T,>(items: T[]): T[] => [...items].sort(() => Math.random() - 0.5)
const allTonalities = pairs.flatMap(pair => [pair.major, pair.minor])
const questionBank = computed<Question[]>(() => pairs.flatMap(pair => [
  {
    prompt: `¿Cuál es la tonalidad relativa menor de ${pair.major}?`,
    options: shuffle([pair.minor, ...shuffle(allTonalities.filter(name => name !== pair.minor)).slice(0, 3)]),
    correct: pair.minor,
    explanation: `${pair.major} y ${pair.minor} comparten la misma armadura (${pair.signs}). La tónica menor está una tercera menor por debajo de la mayor.`,
  },
  {
    prompt: `¿Cuál es la tonalidad relativa mayor de ${pair.minor}?`,
    options: shuffle([pair.major, ...shuffle(allTonalities.filter(name => name !== pair.major)).slice(0, 3)]),
    correct: pair.major,
    explanation: `${pair.minor} y ${pair.major} comparten la misma armadura (${pair.signs}). La tónica mayor está una tercera menor por encima de la menor.`,
  },
]))

const questions = ref<Question[]>([])
const index = ref(0)
const chosen = ref('')
const checked = ref(false)
const score = ref(0)
const finished = ref(false)
const current = computed(() => questions.value[index.value])
const progress = computed(() => questions.value.length ? Math.round(((index.value + (checked.value ? 1 : 0)) / questions.value.length) * 100) : 0)

function start() {
  questions.value = shuffle(questionBank.value).slice(0, 10)
  index.value = 0
  chosen.value = ''
  checked.value = false
  score.value = 0
  finished.value = false
}
function check() {
  if (!current.value || !chosen.value || checked.value) return
  checked.value = true
  if (chosen.value === current.value.correct) score.value++
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
      <p class="eyebrow">Lectura musical · Tonalidades relativas</p>
      <h2 class="text-lg font-black">Mayor y menor: una misma armadura</h2>
      <p class="mt-1 text-sm leading-5 text-[#788780]">
        Cada tonalidad mayor tiene una relativa menor. Ambas utilizan exactamente los mismos sostenidos o bemoles; lo que cambia es la nota que funciona como centro tonal.
      </p>
    </div>

    <div class="grid gap-2 sm:grid-cols-2">
      <div class="rounded-xl bg-[#edf4ee] p-3">
        <p class="text-sm font-black text-[#426c5b]">De mayor a menor</p>
        <p class="mt-1 text-xs leading-5 text-[#567267]">Baja una tercera menor (3 semitonos) desde la tónica mayor. Do mayor → La menor.</p>
      </div>
      <div class="rounded-xl bg-[#edf4ee] p-3">
        <p class="text-sm font-black text-[#426c5b]">De menor a mayor</p>
        <p class="mt-1 text-xs leading-5 text-[#567267]">Sube una tercera menor (3 semitonos) desde la tónica menor. La menor → Do mayor.</p>
      </div>
    </div>

    <div class="mt-3 rounded-xl border border-[#dce7df] p-3">
      <p class="text-xs font-bold uppercase tracking-wide text-[#718078]">Tabla de tonalidades relativas</p>
      <div class="mt-2 grid grid-cols-1 gap-1.5 sm:grid-cols-2">
        <div v-for="pair in pairs" :key="pair.major" class="flex items-center justify-between gap-2 rounded-lg bg-[#f5f8f4] px-3 py-2">
          <span class="text-xs font-bold text-[#365c4c]">{{ pair.major }}</span>
          <span class="text-[10px] text-[#829087]">↔</span>
          <span class="text-xs font-semibold text-[#567267]">{{ pair.minor }}</span>
          <span class="ml-auto rounded bg-white px-1.5 py-0.5 text-[10px] text-[#718078]">{{ pair.count }}</span>
        </div>
      </div>
      <p class="mt-2 text-[10px] text-[#829087]">El número indica cuántas alteraciones tiene la armadura compartida.</p>
    </div>

    <div class="mt-3 rounded-xl bg-[#f7f4ed] p-3">
      <template v-if="!finished">
        <div class="mb-3 flex items-center justify-between gap-2">
          <div>
            <p class="eyebrow">Ejercicio mixto</p>
            <h3 class="text-base font-black">Pregunta {{ index + 1 }} de {{ questions.length }}</h3>
          </div>
          <span class="rounded-full bg-white px-2.5 py-1 text-[11px] font-bold text-[#426c5b]">{{ score }} correctas</span>
        </div>
        <div class="mb-3 h-1.5 overflow-hidden rounded-full bg-[#e4e9e2]">
          <div class="h-full rounded-full bg-[#4c9c7c] transition-all" :style="{ width: progress + '%' }"></div>
        </div>
        <p class="text-sm font-bold leading-6 text-[#365c4c]">{{ current?.prompt }}</p>
        <div class="mt-3 grid gap-2 sm:grid-cols-2">
          <button
            v-for="option in current?.options"
            :key="option"
            class="rounded-lg border-2 bg-white px-3 py-2.5 text-left text-sm font-semibold transition"
            :class="checked && option === current?.correct ? 'border-[#4c9c7c] bg-[#edf4ee] text-[#226447]' : chosen === option ? 'border-[#8aa99a] bg-[#eef4ef]' : 'border-transparent'"
            :disabled="checked"
            @click="chosen = option"
          >
            {{ option }}
          </button>
        </div>
        <div v-if="checked" class="mt-3 rounded-lg p-3" :class="chosen === current?.correct ? 'bg-[#e9f5ed] text-[#226447]' : 'bg-[#fff1e9] text-[#a14f2d]'">
          <p class="flex items-center gap-1.5 text-xs font-black">
            <CheckCircle2 v-if="chosen === current?.correct" :size="15" />
            <XCircle v-else :size="15" />
            {{ chosen === current?.correct ? '¡Correcto!' : 'La respuesta correcta es ' + current?.correct + '.' }}
          </p>
          <p class="mt-1 text-xs leading-5">{{ current?.explanation }}</p>
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
        <p class="mt-2 text-sm text-[#718078]">{{ score >= 8 ? '¡Excelente! Ya relacionas las tonalidades mayores y menores.' : 'Repasa la distancia de tercera menor y vuelve a intentarlo.' }}</p>
        <button class="primary mt-4 inline-flex items-center gap-2 px-4 py-2 text-xs" @click="start">
          <RotateCcw :size="14" /> Repetir práctica
        </button>
      </div>
    </div>
  </section>
</template>
