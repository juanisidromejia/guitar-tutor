<script setup lang="ts">
import { computed, ref } from 'vue'
import { ArrowLeft, CheckCircle2, ClipboardCheck, RotateCcw, Trophy } from 'lucide-vue-next'
import { RouterLink } from 'vue-router'
import StaffNote from '../components/StaffNote.vue'
import { isSupabaseConfigured, requireSupabase } from '../services/supabase'

type Difficulty = 'beginner' | 'intermediate' | 'advanced' | 'mixed'
type Question = {
  id: number
  position: number
  difficulty: Exclude<Difficulty, 'mixed'>
  category: string
  prompt: string
  options: string[]
  midi: number | null
}
type ReviewQuestion = Question & {
  selected_answer: string
  correct_answer: string
  is_correct: boolean
  explanation: string
}
type CategoryResult = { category: string; correct: number; total: number }
type DiagnosticResult = {
  attempt_id: string
  difficulty: Difficulty
  correct_count: number
  total: number
  percentage: number
  category_results: CategoryResult[]
  review: ReviewQuestion[]
}

const difficulty = ref<Difficulty>('beginner')
const questionCount = ref(12)
const attemptId = ref('')
const questions = ref<Question[]>([])
const index = ref(0)
const selected = ref('')
const answers = ref<Record<number, string>>({})
const result = ref<DiagnosticResult | null>(null)
const busy = ref(false)
const error = ref('')
const started = ref(false)

const current = computed(() => questions.value[index.value] ?? null)
const answered = computed(() => Object.keys(answers.value).length)
const difficultyLabels: Record<Difficulty, string> = {
  beginner: 'Principiante',
  intermediate: 'Intermedio',
  advanced: 'Avanzado',
  mixed: 'Mixto',
}
const progress = computed(() => questions.value.length
  ? Math.round(answered.value / questions.value.length * 100)
  : 0)

async function ensureStudentSession() {
  const db = requireSupabase()
  const { data, error: sessionError } = await db.auth.getSession()
  if (sessionError) throw sessionError
  if (!data.session) {
    const { error: authError } = await db.auth.signInAnonymously()
    if (authError) throw authError
  }
}

async function begin() {
  busy.value = true
  error.value = ''
  try {
    if (!isSupabaseConfigured) {
      throw new Error('El diagnóstico necesita conexión con Supabase. Comprueba la configuración del proyecto.')
    }
    await ensureStudentSession()
    const { data, error: rpcError } = await requireSupabase().rpc('start_diagnostic_attempt', {
      p_difficulty: difficulty.value,
      p_question_count: questionCount.value,
    })
    if (rpcError) throw rpcError

    const payload = data as {
      attempt_id: string
      questions: Question[]
    }
    attemptId.value = payload.attempt_id
    questions.value = payload.questions
    answers.value = {}
    index.value = 0
    selected.value = ''
    result.value = null
    started.value = true
  } catch (cause) {
    error.value = cause instanceof Error ? cause.message : 'No se pudo iniciar el diagnóstico.'
  } finally {
    busy.value = false
  }
}

async function submit() {
  if (!current.value || !selected.value || !attemptId.value || busy.value) return
  busy.value = true
  error.value = ''
  try {
    if (answers.value[current.value.id] !== selected.value) {
      const { error: rpcError } = await requireSupabase().rpc('submit_diagnostic_answer', {
        p_attempt_id: attemptId.value,
        p_question_id: current.value.id,
        p_answer: selected.value,
      })
      if (rpcError) throw rpcError
      answers.value[current.value.id] = selected.value
    }

    if (index.value === questions.value.length - 1) {
      const { data, error: finishError } = await requireSupabase().rpc('finish_diagnostic_attempt', {
        p_attempt_id: attemptId.value,
      })
      if (finishError) throw finishError
      result.value = data as DiagnosticResult
    } else {
      index.value += 1
      selected.value = ''
    }
  } catch (cause) {
    error.value = cause instanceof Error ? cause.message : 'No se pudo guardar la respuesta.'
  } finally {
    busy.value = false
  }
}

function restart() {
  started.value = false
  attemptId.value = ''
  questions.value = []
  index.value = 0
  selected.value = ''
  answers.value = {}
  result.value = null
  error.value = ''
}

function difficultyLabel(value: Difficulty) {
  return difficultyLabels[value]
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
      <h2 class="mt-2 text-2xl font-black">Prepara tu diagnóstico</h2>
      <p class="mt-3 max-w-2xl text-sm leading-6 text-[#687970]">
        Selecciona el nivel y la cantidad de preguntas. El diagnóstico combina lectura en el pentagrama,
        orientación en el diapasón, ritmo y contenidos de armonía según el nivel elegido.
        En la notación de guitarra, las notas se escriben una octava por encima de su sonido real.
      </p>

      <div class="mt-6 grid gap-4 sm:grid-cols-2">
        <label class="block">
          <span class="mb-2 block text-sm font-bold">Nivel de dificultad</span>
          <select v-model="difficulty" class="w-full rounded-xl border border-[#dce6dd] bg-white px-3 py-3">
            <option value="beginner">Principiante</option>
            <option value="intermediate">Intermedio</option>
            <option value="advanced">Avanzado</option>
            <option value="mixed">Mixto · los tres niveles</option>
          </select>
          <span class="mt-1 block text-xs text-[#718078]">En nivel mixto se combinan preguntas de los tres niveles.</span>
        </label>
        <label class="block">
          <span class="mb-2 block text-sm font-bold">Número de preguntas</span>
          <select v-model.number="questionCount" class="w-full rounded-xl border border-[#dce6dd] bg-white px-3 py-3">
            <option :value="5">5 preguntas</option>
            <option :value="8">8 preguntas</option>
            <option :value="10">10 preguntas</option>
            <option :value="12">12 preguntas</option>
            <option :value="15">15 preguntas</option>
            <option :value="20">20 preguntas</option>
          </select>
          <span class="mt-1 block text-xs text-[#718078]">Las preguntas se seleccionan al azar sin repetir.</span>
        </label>
      </div>

      <div class="mt-6 grid gap-3 sm:grid-cols-3">
        <div class="rounded-2xl bg-[#f3f7f3] p-4">
          <span class="text-xs font-black text-[#5d8b73]">01</span>
          <h3 class="mt-2 font-extrabold">Pentagrama</h3>
          <p class="mt-1 text-xs text-[#7b8981]">Lectura de notas y alteraciones</p>
        </div>
        <div class="rounded-2xl bg-[#f3f7f3] p-4">
          <span class="text-xs font-black text-[#5d8b73]">02</span>
          <h3 class="mt-2 font-extrabold">Diapasón y armonía</h3>
          <p class="mt-1 text-xs text-[#7b8981]">Notas, intervalos y acordes</p>
        </div>
        <div class="rounded-2xl bg-[#f3f7f3] p-4">
          <span class="text-xs font-black text-[#5d8b73]">03</span>
          <h3 class="mt-2 font-extrabold">Ritmo</h3>
          <p class="mt-1 text-xs text-[#7b8981]">Figuras, silencios y compases</p>
        </div>
      </div>

      <div class="mt-6 flex flex-wrap items-center justify-between gap-3 border-t border-[#edf1ed] pt-5">
        <p class="text-xs text-[#819087]">Sin límite de tiempo · Resultados al finalizar</p>
        <button class="primary" :disabled="busy || !isSupabaseConfigured" @click="begin">
          {{ busy ? 'Preparando…' : 'Comenzar diagnóstico' }} <ClipboardCheck :size="17"/>
        </button>
      </div>
      <p v-if="!isSupabaseConfigured" class="mt-3 text-sm text-[#9b4f3c]">El diagnóstico necesita que Supabase esté configurado.</p>
      <p v-if="error" class="mt-3 rounded-xl bg-[#fff1ed] p-3 text-sm text-[#9b4f3c]">{{ error }}</p>
    </section>

    <section v-else-if="!result && current" class="panel p-5 sm:p-7">
      <div class="flex flex-wrap items-center justify-between gap-3">
        <span class="rounded-full bg-[#edf4ee] px-3 py-1.5 text-xs font-bold text-[#34745b]">{{ current.category }} · {{ difficultyLabel(current.difficulty) }}</span>
        <span class="text-sm font-bold text-[#718078]">Pregunta {{ index + 1 }} de {{ questions.length }}</span>
      </div>
      <div class="mt-4 h-2 overflow-hidden rounded-full bg-[#edf1ec]"><div class="h-full rounded-full bg-[#398568] transition-all" :style="{width: progress + '%'}"/></div>
      <h2 class="mt-7 text-xl font-black sm:text-2xl">{{ current.prompt }}</h2>

      <div v-if="current.midi !== null" class="mt-5 max-w-sm">
        <StaffNote :midi="current.midi"/>
      </div>
      <div class="mt-6 grid gap-3 sm:grid-cols-2">
        <button
          v-for="(option, optionIndex) in current.options"
          :key="option"
          class="rounded-xl border px-4 py-4 text-left text-sm font-bold transition"
          :class="selected === option ? 'border-[#28785e] bg-[#eaf4ed] text-[#23664d] ring-2 ring-[#28785e]/20' : 'border-[#e1e9e2] bg-white hover:border-[#9bb9a6]'"
          :disabled="busy"
          @click="selected = option"
        >
          <span class="mr-2 inline-grid h-6 w-6 place-items-center rounded-full bg-[#f0f4f0] text-xs">{{ String.fromCharCode(65 + optionIndex) }}</span>{{ option }}
        </button>
      </div>
      <p v-if="error" class="mt-3 rounded-xl bg-[#fff1ed] p-3 text-sm text-[#9b4f3c]">{{ error }}</p>
      <div class="mt-7 flex items-center justify-between border-t border-[#edf1ed] pt-5">
        <span class="text-xs text-[#819087]">{{ answered }} respuestas registradas</span>
        <button class="primary" :disabled="!selected || busy" :class="!selected || busy ? 'cursor-not-allowed opacity-40' : ''" @click="submit">
          {{ busy ? 'Guardando…' : index === questions.length - 1 ? 'Finalizar diagnóstico' : 'Confirmar y continuar' }}
        </button>
      </div>
    </section>

    <section v-else-if="result" class="space-y-4">
      <div class="panel p-6 text-center sm:p-8">
        <span class="mx-auto grid h-14 w-14 place-items-center rounded-2xl bg-[#e8f2eb] text-[#26745a]"><Trophy :size="28"/></span>
        <p class="eyebrow mt-4">Evaluación finalizada · {{ difficultyLabel(result.difficulty) }}</p>
        <h2 class="mt-2 text-3xl font-black">{{ result.percentage }}%</h2>
        <p class="mt-1 text-sm text-[#718078]">Respuestas correctas: {{ result.correct_count }} de {{ result.total }}</p>
        <div class="mx-auto mt-5 h-3 max-w-md overflow-hidden rounded-full bg-[#edf1ec]"><div class="h-full rounded-full bg-[#398568]" :style="{width: result.percentage + '%'}"/></div>
      </div>

      <div class="panel p-5 sm:p-6">
        <h3 class="text-lg font-black">Resultado por área</h3>
        <div class="mt-4 grid gap-3 sm:grid-cols-3">
          <div v-for="item in result.category_results" :key="item.category" class="rounded-xl bg-[#f3f7f3] p-4">
            <p class="text-sm font-bold">{{ item.category }}</p>
            <p class="mt-1 text-2xl font-black">{{ Math.round(item.correct / item.total * 100) }}%</p>
            <p class="text-xs text-[#7b8981]">{{ item.correct }} de {{ item.total }} correctas</p>
          </div>
        </div>
      </div>

      <div class="panel p-5 sm:p-6">
        <h3 class="text-lg font-black">Revisión de respuestas</h3>
        <div class="mt-4 space-y-3">
          <article
            v-for="(question, i) in result.review"
            :key="question.id"
            class="rounded-xl border p-4"
            :class="question.is_correct ? 'border-[#dcebe0]' : 'border-[#f0dfd8]'"
          >
            <div class="flex items-start gap-2">
              <CheckCircle2 v-if="question.is_correct" class="mt-0.5 shrink-0 text-[#398568]" :size="18"/>
              <span v-else class="mt-0.5 shrink-0 font-black text-[#b66b50]">×</span>
              <div class="min-w-0 flex-1">
                <p class="text-xs font-bold uppercase tracking-wide text-[#718078]">{{ i + 1 }} · {{ question.category }} · {{ difficultyLabel(question.difficulty) }}</p>
                <p class="mt-1 text-sm font-bold">{{ question.prompt }}</p>
                <p class="mt-2 text-xs text-[#718078]">Tu respuesta: <strong>{{ question.selected_answer }}</strong></p>
                <p v-if="!question.is_correct" class="mt-1 text-xs text-[#28745a]">Respuesta correcta: <strong>{{ question.correct_answer }}</strong></p>
                <p class="mt-2 text-sm leading-5 text-[#687970]">{{ question.explanation }}</p>
              </div>
            </div>
          </article>
        </div>
      </div>
      <div class="flex flex-wrap justify-between gap-3">
        <RouterLink to="/" class="secondary inline-flex items-center gap-2"><ArrowLeft :size="16"/> Volver al inicio</RouterLink>
        <button class="primary" @click="restart"><RotateCcw :size="16"/> Nuevo diagnóstico</button>
      </div>
    </section>
  </div>
</template>
