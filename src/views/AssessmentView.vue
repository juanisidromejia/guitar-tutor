<script setup lang="ts">
import { computed, ref } from 'vue'
import { ArrowLeft, CheckCircle2, ClipboardCheck, RotateCcw, Trophy } from 'lucide-vue-next'
import { RouterLink } from 'vue-router'
import StaffNote from '../components/StaffNote.vue'

type Category = 'Pentagrama' | 'Diapasón' | 'Ritmo'
type Question = {
  id: number
  category: Category
  prompt: string
  explanation: string
  options: string[]
  correct: string
  midi?: number
}

const questions: Question[] = [
  { id: 1, category: 'Pentagrama', prompt: '¿Qué nota aparece en el pentagrama?', midi: 64, options: ['Do4', 'Mi4', 'Sol4', 'La4'], correct: 'Mi4', explanation: 'Mi4 se escribe en la primera línea del pentagrama en clave de sol.' },
  { id: 2, category: 'Pentagrama', prompt: '¿Qué nota aparece en el pentagrama?', midi: 67, options: ['Re4', 'Fa4', 'Sol4', 'Si4'], correct: 'Sol4', explanation: 'Sol4 se escribe en la segunda línea del pentagrama en clave de sol.' },
  { id: 3, category: 'Pentagrama', prompt: '¿Qué nota aparece en el pentagrama?', midi: 60, options: ['Do4', 'Re4', 'Mi4', 'Fa4'], correct: 'Do4', explanation: 'Do4 se escribe en la línea adicional inferior del pentagrama.' },
  { id: 4, category: 'Pentagrama', prompt: '¿Qué nota aparece en el pentagrama?', midi: 72, options: ['Do5', 'Re5', 'Fa5', 'Sol5'], correct: 'Do5', explanation: 'Do5 está en el tercer espacio del pentagrama en clave de sol.' },
  { id: 5, category: 'Diapasón', prompt: '¿En qué posición encuentras la nota Sol4?', options: ['1.ª cuerda, traste 3', '2.ª cuerda, traste 8', '3.ª cuerda, traste 12', '4.ª cuerda, traste 5'], correct: '1.ª cuerda, traste 3', explanation: 'La primera cuerda al aire es Mi4. En el tercer traste encontramos Sol4.' },
  { id: 6, category: 'Diapasón', prompt: '¿Dónde se encuentra la nota La3?', options: ['3.ª cuerda, traste 2', '4.ª cuerda, traste 7', '5.ª cuerda, traste 0', '6.ª cuerda, traste 5'], correct: '3.ª cuerda, traste 2', explanation: 'La tercera cuerda al aire es Sol3; el segundo traste produce La3.' },
  { id: 7, category: 'Diapasón', prompt: '¿Qué nota suena en la segunda cuerda al aire?', options: ['Mi4', 'Si3', 'Sol3', 'Re4'], correct: 'Si3', explanation: 'En la afinación estándar, la segunda cuerda al aire corresponde a Si3.' },
  { id: 8, category: 'Diapasón', prompt: '¿Qué nota obtienes en la quinta cuerda, traste 3?', options: ['Do3', 'Re3', 'Mi3', 'Fa3'], correct: 'Do3', explanation: 'La quinta cuerda al aire es La2. Tres semitonos por encima encontramos Do3.' },
  { id: 9, category: 'Ritmo', prompt: '¿Cuántas negras equivalen a una redonda?', options: ['Dos', 'Tres', 'Cuatro', 'Ocho'], correct: 'Cuatro', explanation: 'La redonda equivale a cuatro negras.' },
  { id: 10, category: 'Ritmo', prompt: '¿Cuántas corcheas equivalen a una negra?', options: ['Una', 'Dos', 'Tres', 'Cuatro'], correct: 'Dos', explanation: 'Dos corcheas tienen la misma duración que una negra.' },
  { id: 11, category: 'Ritmo', prompt: '¿Qué debes hacer durante un silencio de negra?', options: ['Detener el pulso', 'Mantener el pulso sin sonar', 'Tocar una corchea', 'Acelerar'], correct: 'Mantener el pulso sin sonar', explanation: 'El silencio ocupa el tiempo de una negra, pero no produce sonido.' },
  { id: 12, category: 'Ritmo', prompt: 'En un compás de 3/4, ¿cuántas negras completan el compás?', options: ['Dos', 'Tres', 'Cuatro', 'Seis'], correct: 'Tres', explanation: 'El numerador 3 indica tres pulsos de negra por compás en 3/4.' },
]

const started = ref(false)
const finished = ref(false)
const index = ref(0)
const questionOrder = ref<Question[]>([])
const selected = ref('')
const answers = ref<Record<number, string>>({})
const current = computed(() => questionOrder.value[index.value])
const correctCount = computed(() => questionOrder.value.filter(q => answers.value[q.id] === q.correct).length)
const percentage = computed(() => Math.round((correctCount.value / questions.length) * 100))
const categoryResults = computed(() => (['Pentagrama', 'Diapasón', 'Ritmo'] as Category[]).map(category => {
  const group = questionOrder.value.filter(q => q.category === category)
  return { category, correct: group.filter(q => answers.value[q.id] === q.correct).length, total: group.length }
}))
const answered = computed(() => Object.keys(answers.value).length)

function shuffleQuestions(items: Question[]) {
  const shuffled = [...items]
  for (let i = shuffled.length - 1; i > 0; i -= 1) {
    const j = Math.floor(Math.random() * (i + 1))
    ;[shuffled[i], shuffled[j]] = [shuffled[j], shuffled[i]]
  }
  return shuffled
}

function begin() {
  questionOrder.value = shuffleQuestions(questions)
  started.value = true
  finished.value = false
  index.value = 0
  selected.value = ''
  answers.value = {}
}
function submit() {
  if (!selected.value) return
  answers.value[current.value.id] = selected.value
  if (index.value === questions.length - 1) finished.value = true
  else {
    index.value += 1
    selected.value = ''
  }
}
function restart() {
  started.value = false
  finished.value = false
  index.value = 0
  selected.value = ''
  answers.value = {}
}
</script>

<template>
  <div class="page">
    <div class="mb-6 flex items-center gap-3">
      <span class="grid h-12 w-12 place-items-center rounded-2xl bg-[#e8f2eb] text-[#26745a]"><ClipboardCheck :size="25"/></span>
      <div><p class="eyebrow">Evaluación · Diagnóstico</p><h1 class="text-2xl font-black sm:text-3xl">Prueba de conocimientos</h1></div>
    </div>

    <section v-if="!started" class="panel p-6 sm:p-8">
      <p class="text-sm font-bold text-[#648174]">Comprueba lo que has aprendido</p>
      <h2 class="mt-2 text-2xl font-black">Una prueba, tres áreas musicales</h2>
      <p class="mt-3 max-w-2xl text-sm leading-6 text-[#687970]">Responde las preguntas sobre lectura en el pentagrama, ubicación de notas en la guitarra y ritmo. Al terminar verás tu porcentaje, el resultado por área y la explicación de cada respuesta.</p>
      <div class="mt-6 grid gap-3 sm:grid-cols-3">
        <div v-for="item in [{n:'01',title:'Pentagrama',desc:'Identificación de notas'},{n:'02',title:'Diapasón',desc:'Cuerdas, notas y trastes'},{n:'03',title:'Ritmo',desc:'Figuras, silencios y compás'}]" :key="item.n" class="rounded-2xl bg-[#f3f7f3] p-4">
          <span class="text-xs font-black text-[#5d8b73]">{{item.n}}</span><h3 class="mt-2 font-extrabold">{{item.title}}</h3><p class="mt-1 text-xs text-[#7b8981]">{{item.desc}}</p>
        </div>
      </div>
      <div class="mt-6 flex flex-wrap items-center justify-between gap-3 border-t border-[#edf1ed] pt-5">
        <p class="text-xs text-[#819087]">12 preguntas · Sin límite de tiempo · 1 intento por pregunta</p>
        <button class="primary" @click="begin">Comenzar prueba <ClipboardCheck :size="17"/></button>
      </div>
    </section>

    <section v-else-if="!finished" class="panel p-5 sm:p-7">
      <div class="flex flex-wrap items-center justify-between gap-3">
        <span class="rounded-full bg-[#edf4ee] px-3 py-1.5 text-xs font-bold text-[#34745b]">{{current.category}}</span>
        <span class="text-sm font-bold text-[#718078]">Pregunta {{index + 1}} de {{questions.length}}</span>
      </div>
      <div class="mt-4 h-2 overflow-hidden rounded-full bg-[#edf1ec]"><div class="h-full rounded-full bg-[#398568] transition-all" :style="{width: ((index + 1) / questions.length * 100) + '%'}"/></div>
      <h2 class="mt-7 text-xl font-black sm:text-2xl">{{current.prompt}}</h2>

      <div v-if="current.midi" class="mt-5 max-w-sm">
        <StaffNote :midi="current.midi"/>
      </div>
      <div class="mt-6 grid gap-3 sm:grid-cols-2">
        <button v-for="option in current.options" :key="option" class="rounded-xl border px-4 py-4 text-left text-sm font-bold transition" :class="selected === option ? 'border-[#28785e] bg-[#eaf4ed] text-[#23664d] ring-2 ring-[#28785e]/20' : 'border-[#e1e9e2] bg-white hover:border-[#9bb9a6]'" @click="selected = option">
          <span class="mr-2 inline-grid h-6 w-6 place-items-center rounded-full bg-[#f0f4f0] text-xs">{{String.fromCharCode(65 + current.options.indexOf(option))}}</span>{{option}}
        </button>
      </div>
      <div class="mt-7 flex items-center justify-between border-t border-[#edf1ed] pt-5">
        <span class="text-xs text-[#819087]">{{answered}} respuestas registradas</span>
        <button class="primary" :disabled="!selected" :class="!selected ? 'cursor-not-allowed opacity-40' : ''" @click="submit">{{index === questions.length - 1 ? 'Finalizar prueba' : 'Confirmar y continuar'}}</button>
      </div>
    </section>

    <section v-else class="space-y-4">
      <div class="panel p-6 text-center sm:p-8">
        <span class="mx-auto grid h-14 w-14 place-items-center rounded-2xl bg-[#e8f2eb] text-[#26745a]"><Trophy :size="28"/></span>
        <p class="eyebrow mt-4">Evaluación finalizada</p>
        <h2 class="mt-2 text-3xl font-black">{{percentage}}%</h2>
        <p class="mt-1 text-sm text-[#718078]">Respuestas correctas: {{correctCount}} de {{questions.length}}</p>
        <div class="mx-auto mt-5 h-3 max-w-md overflow-hidden rounded-full bg-[#edf1ec]"><div class="h-full rounded-full bg-[#398568]" :style="{width: percentage + '%'}"/></div>
      </div>
      <div class="panel p-5 sm:p-6">
        <h3 class="text-lg font-black">Resultado por área</h3>
        <div class="mt-4 grid gap-3 sm:grid-cols-3">
          <div v-for="item in categoryResults" :key="item.category" class="rounded-xl bg-[#f3f7f3] p-4">
            <p class="text-sm font-bold">{{item.category}}</p><p class="mt-1 text-2xl font-black">{{Math.round(item.correct / item.total * 100)}}%</p><p class="text-xs text-[#7b8981]">{{item.correct}} de {{item.total}} correctas</p>
          </div>
        </div>
      </div>
      <div class="panel p-5 sm:p-6">
        <h3 class="text-lg font-black">Revisión de respuestas</h3>
        <div class="mt-4 space-y-3">
          <article v-for="(question, i) in questionOrder" :key="question.id" class="rounded-xl border p-4" :class="answers[question.id] === question.correct ? 'border-[#dcebe0]' : 'border-[#f0dfd8]'">
            <div class="flex items-start gap-2">
              <CheckCircle2 v-if="answers[question.id] === question.correct" class="mt-0.5 shrink-0 text-[#398568]" :size="18"/>
              <span v-else class="mt-0.5 shrink-0 font-black text-[#b66b50]">×</span>
              <div class="min-w-0 flex-1">
                <p class="text-xs font-bold uppercase tracking-wide text-[#718078]">{{i + 1}} · {{question.category}}</p>
                <p class="mt-1 text-sm font-bold">{{question.prompt}}</p>
                <p class="mt-2 text-xs text-[#718078]">Tu respuesta: <strong>{{answers[question.id]}}</strong></p>
                <p v-if="answers[question.id] !== question.correct" class="mt-1 text-xs text-[#28745a]">Respuesta correcta: <strong>{{question.correct}}</strong></p>
                <p class="mt-2 text-sm leading-5 text-[#687970]">{{question.explanation}}</p>
              </div>
            </div>
          </article>
        </div>
      </div>
      <div class="flex flex-wrap justify-between gap-3">
        <RouterLink to="/" class="secondary inline-flex items-center gap-2"><ArrowLeft :size="16"/> Volver al inicio</RouterLink>
        <button class="primary" @click="restart"><RotateCcw :size="16"/> Repetir prueba</button>
      </div>
    </section>
  </div>
</template>
