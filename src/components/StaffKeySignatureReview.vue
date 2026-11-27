<script setup lang="ts">
import { computed, ref } from 'vue'
import { CheckCircle2, XCircle, ArrowRight, RotateCcw } from 'lucide-vue-next'

type Signature = {
  tonic: string
  count: number
  family: 'sostenidos' | 'bemoles' | 'sin alteraciones'
  signs: string[]
  rule: string
}

const signatures: Signature[] = [
  { tonic: 'Do mayor', count: 0, family: 'sin alteraciones', signs: [], rule: 'No tiene sostenidos ni bemoles.' },
  { tonic: 'Sol mayor', count: 1, family: 'sostenidos', signs: ['Fa♯'], rule: 'Fa♯ es el último sostenido; un semitono por encima está Sol.' },
  { tonic: 'Re mayor', count: 2, family: 'sostenidos', signs: ['Fa♯', 'Do♯'], rule: 'Do♯ es el último sostenido; un semitono por encima está Re.' },
  { tonic: 'La mayor', count: 3, family: 'sostenidos', signs: ['Fa♯', 'Do♯', 'Sol♯'], rule: 'Sol♯ es el último sostenido; un semitono por encima está La.' },
  { tonic: 'Mi mayor', count: 4, family: 'sostenidos', signs: ['Fa♯', 'Do♯', 'Sol♯', 'Re♯'], rule: 'Re♯ es el último sostenido; un semitono por encima está Mi.' },
  { tonic: 'Si mayor', count: 5, family: 'sostenidos', signs: ['Fa♯', 'Do♯', 'Sol♯', 'Re♯', 'La♯'], rule: 'La♯ es el último sostenido; un semitono por encima está Si.' },
  { tonic: 'Fa♯ mayor', count: 6, family: 'sostenidos', signs: ['Fa♯', 'Do♯', 'Sol♯', 'Re♯', 'La♯', 'Mi♯'], rule: 'Mi♯ es el último sostenido; un semitono por encima está Fa♯.' },
  { tonic: 'Do♯ mayor', count: 7, family: 'sostenidos', signs: ['Fa♯', 'Do♯', 'Sol♯', 'Re♯', 'La♯', 'Mi♯', 'Si♯'], rule: 'Si♯ es el último sostenido; un semitono por encima está Do♯.' },
  { tonic: 'Fa mayor', count: 1, family: 'bemoles', signs: ['Si♭'], rule: 'Fa mayor tiene un bemol: Si♭. Es la excepción a la regla del penúltimo bemol.' },
  { tonic: 'Si♭ mayor', count: 2, family: 'bemoles', signs: ['Si♭', 'Mi♭'], rule: 'El penúltimo bemol es Si♭, que da nombre a la tonalidad.' },
  { tonic: 'Mi♭ mayor', count: 3, family: 'bemoles', signs: ['Si♭', 'Mi♭', 'La♭'], rule: 'El penúltimo bemol es Mi♭, que da nombre a la tonalidad.' },
  { tonic: 'La♭ mayor', count: 4, family: 'bemoles', signs: ['Si♭', 'Mi♭', 'La♭', 'Re♭'], rule: 'El penúltimo bemol es La♭, que da nombre a la tonalidad.' },
  { tonic: 'Re♭ mayor', count: 5, family: 'bemoles', signs: ['Si♭', 'Mi♭', 'La♭', 'Re♭', 'Sol♭'], rule: 'El penúltimo bemol es Re♭, que da nombre a la tonalidad.' },
  { tonic: 'Sol♭ mayor', count: 6, family: 'bemoles', signs: ['Si♭', 'Mi♭', 'La♭', 'Re♭', 'Sol♭', 'Do♭'], rule: 'El penúltimo bemol es Sol♭, que da nombre a la tonalidad.' },
  { tonic: 'Do♭ mayor', count: 7, family: 'bemoles', signs: ['Si♭', 'Mi♭', 'La♭', 'Re♭', 'Sol♭', 'Do♭', 'Fa♭'], rule: 'El penúltimo bemol es Do♭, que da nombre a la tonalidad.' },
]

type Question = { prompt: string; options: string[]; correct: string; explanation: string }
const shuffle = <T,>(items: T[]): T[] => [...items].sort(() => Math.random() - 0.5)
const questionBank = computed<Question[]>(() => {
  const bank: Question[] = []
  for (const signature of signatures) {
    const label = signature.count === 0
      ? 'ninguna alteración'
      : `${signature.count} ${signature.count === 1 ? (signature.family === 'sostenidos' ? 'sostenido' : 'bemol') : signature.family}`
    const countOptions = signature.count === 0
      ? ['0', '1', '2', '3']
      : shuffle([String(signature.count), ...shuffle(Array.from({ length: 8 }, (_, value) => String(value)).filter(value => value !== String(signature.count))).slice(0, 3)])
    bank.push({
      prompt: `¿Qué tonalidad mayor corresponde a una armadura con ${label}?`,
      options: shuffle([signature.tonic, ...shuffle(signatures.filter(item => item.tonic !== signature.tonic).map(item => item.tonic)).slice(0, 3)]),
      correct: signature.tonic,
      explanation: `${signature.tonic}: ${signature.signs.length ? signature.signs.join(', ') : 'sin alteraciones'}. ${signature.rule}`,
    })
    bank.push({
      prompt: `¿Cuántas alteraciones tiene la armadura de ${signature.tonic}?`,
      options: shuffle(countOptions),
      correct: String(signature.count),
      explanation: `${signature.tonic} tiene ${signature.count} ${signature.count === 1 ? 'alteración' : 'alteraciones'}${signature.signs.length ? `: ${signature.signs.join(', ')}` : ''}.`,
    })
  }
  return bank
})

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
      <p class="eyebrow">Lectura musical · Práctica de armaduras</p>
      <h2 class="text-lg font-black">Reconoce la tonalidad</h2>
      <p class="mt-1 text-sm leading-5 text-[#788780]">
        Ahora combina lo aprendido: identifica la tonalidad a partir de sus alteraciones y también deduce cuántos signos lleva una tonalidad conocida.
      </p>
    </div>

    <div class="grid gap-2 sm:grid-cols-2">
      <div class="rounded-xl bg-[#edf4ee] p-3">
        <p class="text-sm font-black text-[#426c5b]">Si la armadura tiene sostenidos</p>
        <p class="mt-1 text-xs leading-5 text-[#567267]">Busca el último sostenido. La tónica mayor está un semitono por encima. Ejemplo: Fa♯, Do♯, Sol♯ → La mayor.</p>
      </div>
      <div class="rounded-xl bg-[#edf4ee] p-3">
        <p class="text-sm font-black text-[#426c5b]">Si la armadura tiene bemoles</p>
        <p class="mt-1 text-xs leading-5 text-[#567267]">Con dos o más bemoles, el penúltimo bemol da el nombre de la tonalidad. Ejemplo: Si♭, Mi♭, La♭ → Mi♭ mayor. Con un bemol: Fa mayor.</p>
      </div>
    </div>

    <div class="mt-3 rounded-xl border border-[#dce7df] p-3">
      <p class="text-xs font-bold uppercase tracking-wide text-[#718078]">Referencia rápida</p>
      <div class="mt-2 grid gap-2 sm:grid-cols-2">
        <div>
          <p class="text-xs font-black text-[#426c5b]">Sostenidos</p>
          <div class="mt-1 flex flex-wrap gap-1">
            <span v-for="item in signatures.filter(s => s.family === 'sostenidos')" :key="item.tonic" class="rounded-md bg-[#f2f6f1] px-2 py-1 text-[11px] text-[#365c4c]">{{ item.count }}: {{ item.tonic }}</span>
          </div>
        </div>
        <div>
          <p class="text-xs font-black text-[#426c5b]">Bemoles</p>
          <div class="mt-1 flex flex-wrap gap-1">
            <span v-for="item in signatures.filter(s => s.family === 'bemoles')" :key="item.tonic" class="rounded-md bg-[#f2f6f1] px-2 py-1 text-[11px] text-[#365c4c]">{{ item.count }}: {{ item.tonic }}</span>
          </div>
        </div>
      </div>
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
            {{ option }}{{ current?.prompt.startsWith('¿Cuántas') ? (option === '1' ? ' alteración' : ' alteraciones') : '' }}
          </button>
        </div>
        <div v-if="checked" class="mt-3 rounded-lg p-3" :class="chosen === current?.correct ? 'bg-[#e9f5ed] text-[#226447]' : 'bg-[#fff1e9] text-[#a14f2d]'">
          <p class="flex items-center gap-1.5 text-xs font-black">
            <CheckCircle2 v-if="chosen === current?.correct" :size="15" />
            <XCircle v-else :size="15" />
            {{ chosen === current?.correct ? '¡Correcto!' : 'Todavía no. La respuesta correcta es ' + current?.correct + '.' }}
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
        <p class="mt-2 text-sm text-[#718078]">{{ score >= 8 ? '¡Muy bien! Reconoces las armaduras con seguridad.' : 'Conviene repasar las reglas y volver a intentarlo.' }}</p>
        <button class="primary mt-4 inline-flex items-center gap-2 px-4 py-2 text-xs" @click="start">
          <RotateCcw :size="14" /> Repetir práctica
        </button>
      </div>
    </div>
  </section>
</template>
