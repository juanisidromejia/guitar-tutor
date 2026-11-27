<script setup lang="ts">
import { computed, ref } from 'vue'
import { Play, CheckCircle2, XCircle, RotateCcw, ArrowRight } from 'lucide-vue-next'
import { fretMidi } from '../engines/guitar/fretboard'
import { midiName } from '../engines/music/pitch'
import { playGuitarNote } from '../engines/audio/guitarSound'

type Tone = 'Fundamental' | 'Tercera' | 'Quinta'
type Shape = {
  id: string
  title: string
  bass: string
  explanation: string
  positions: { string: number; fret: number; tone: Tone }[]
}
const shapes: Shape[] = [
  { id: 'root', title: 'Estado fundamental', bass: 'Do', explanation: 'La fundamental (Do) es la nota más grave. El orden desde el bajo es 1–3–5.', positions: [
    { string: 5, fret: 3, tone: 'Fundamental' }, { string: 4, fret: 2, tone: 'Tercera' }, { string: 3, fret: 0, tone: 'Quinta' }, { string: 2, fret: 1, tone: 'Fundamental' }, { string: 1, fret: 0, tone: 'Tercera' },
  ] },
  { id: 'first', title: 'Primera inversión', bass: 'Mi', explanation: 'La tercera (Mi) pasa al bajo. Las notas siguen siendo Do, Mi y Sol; cambia su orden y el bajo.', positions: [
    { string: 6, fret: 0, tone: 'Tercera' }, { string: 5, fret: 3, tone: 'Fundamental' }, { string: 4, fret: 2, tone: 'Tercera' }, { string: 3, fret: 0, tone: 'Quinta' }, { string: 2, fret: 1, tone: 'Fundamental' }, { string: 1, fret: 0, tone: 'Tercera' },
  ] },
  { id: 'second', title: 'Segunda inversión', bass: 'Sol', explanation: 'La quinta (Sol) pasa al bajo. El acorde conserva las mismas notas, pero ahora Sol es la más grave.', positions: [
    { string: 6, fret: 3, tone: 'Quinta' }, { string: 5, fret: 3, tone: 'Fundamental' }, { string: 4, fret: 2, tone: 'Tercera' }, { string: 3, fret: 0, tone: 'Quinta' }, { string: 2, fret: 1, tone: 'Fundamental' }, { string: 1, fret: 0, tone: 'Tercera' },
  ] },
]
const activeId = ref('root')
const active = computed(() => shapes.find(shape => shape.id === activeId.value) ?? shapes[0])
const notes = computed(() => active.value.positions.map(position => {
  const midi = fretMidi(position.string, position.fret)
  const note = midiName(midi)
  return { ...position, midi, name: note.name, octave: note.octave }
}))
const quiz = [
  { q: '¿Qué nota queda en el bajo en el estado fundamental de Do mayor?', options: ['Do', 'Mi', 'Sol'], answer: 'Do', why: 'En estado fundamental, la fundamental es la nota más grave.' },
  { q: '¿Qué nota debe quedar en el bajo para formar la primera inversión?', options: ['Do', 'Mi', 'Sol'], answer: 'Mi', why: 'La primera inversión coloca la tercera (Mi) en el bajo.' },
  { q: '¿Qué nota queda en el bajo en la segunda inversión?', options: ['Do', 'Mi', 'Sol'], answer: 'Sol', why: 'La segunda inversión coloca la quinta (Sol) en el bajo.' },
  { q: 'Al invertir Do mayor, ¿cambian las notas del acorde?', options: ['Sí, cambian las tres', 'No, siguen siendo Do, Mi y Sol', 'Solo cambia la fundamental'], answer: 'No, siguen siendo Do, Mi y Sol', why: 'La inversión cambia el orden y la nota del bajo, no la identidad del acorde.' },
  { q: '¿Qué determina el nombre de una inversión?', options: ['La nota más aguda', 'La nota del bajo', 'La cantidad de cuerdas'], answer: 'La nota del bajo', why: 'Se identifica por el grado del acorde que aparece como nota más grave.' },
]
const questionIndex = ref(0)
const answer = ref('')
const checked = ref(false)
const score = ref(0)
const done = ref(false)
const currentQuestion = computed(() => quiz[questionIndex.value])
function checkAnswer() {
  if (!answer.value || checked.value) return
  checked.value = true
  if (answer.value === currentQuestion.value.answer) score.value++
}
function nextQuestion() {
  if (questionIndex.value === quiz.length - 1) { done.value = true; return }
  questionIndex.value++
  answer.value = ''
  checked.value = false
}
function restartQuiz() {
  questionIndex.value = 0; answer.value = ''; checked.value = false; score.value = 0; done.value = false
}
function play(position: { midi: number; string: number }) {
  void playGuitarNote(position.midi, position.string)
}
function degree(tone: Tone) { return tone === 'Fundamental' ? '1' : tone === 'Tercera' ? '3' : '5' }
function noteX(fret: number) { return fret === 0 ? 58 : 77 + (fret - 1) * 90 }
</script>

<template>
  <section class="panel mb-4 p-3 sm:p-4">
    <div class="mb-3">
      <p class="eyebrow">Armonía · Guitarra</p>
      <h2 class="text-lg font-black">Inversiones de tríadas</h2>
      <p class="mt-1 text-sm leading-5 text-[#788780]">Una inversión cambia qué nota del acorde queda en el bajo. Las notas siguen siendo las mismas; cambia su orden.</p>
    </div>
    <div class="grid gap-2 sm:grid-cols-3">
      <div class="rounded-xl bg-[#edf4ee] p-3"><p class="text-xs font-black text-[#426c5b]">Estado fundamental</p><p class="mt-1 text-sm font-bold text-[#365c4c]">1 en el bajo</p><p class="mt-1 text-[11px] text-[#567267]">La fundamental está en el bajo.</p></div>
      <div class="rounded-xl bg-[#edf4ee] p-3"><p class="text-xs font-black text-[#426c5b]">Primera inversión</p><p class="mt-1 text-sm font-bold text-[#365c4c]">3 en el bajo</p><p class="mt-1 text-[11px] text-[#567267]">La tercera está en el bajo.</p></div>
      <div class="rounded-xl bg-[#edf4ee] p-3"><p class="text-xs font-black text-[#426c5b]">Segunda inversión</p><p class="mt-1 text-sm font-bold text-[#365c4c]">5 en el bajo</p><p class="mt-1 text-[11px] text-[#567267]">La quinta está en el bajo.</p></div>
    </div>

    <div class="mt-3 rounded-xl border border-[#dce7df] p-3">
      <p class="eyebrow">Explora las posiciones en guitarra</p>
      <div class="mt-2 grid gap-2 sm:grid-cols-3">
        <button v-for="shape in shapes" :key="shape.id" class="rounded-lg border-2 px-3 py-2 text-left" :class="activeId === shape.id ? 'border-[#4c9c7c] bg-[#edf4ee]' : 'border-[#e1e8e0] bg-white'" @click="activeId = shape.id">
          <span class="block text-xs font-black text-[#365c4c]">{{ shape.title }}</span><span class="mt-1 block text-[10px] text-[#718078]">Bajo: {{ shape.bass }}</span>
        </button>
      </div>
      <div class="mt-3 rounded-xl bg-[#f5f8f4] p-3">
        <div class="flex flex-wrap items-start justify-between gap-2"><div><p class="text-xs font-black text-[#426c5b]">{{ active.title }}</p><p class="mt-1 text-lg font-black text-[#365c4c]">Do mayor</p></div><span class="rounded-full bg-white px-2.5 py-1 text-[11px] font-bold text-[#426c5b]">Bajo: {{ active.bass }}</span></div>
        <p class="mt-2 text-xs leading-5 text-[#567267]">{{ active.explanation }}</p>
        <div class="mt-3 overflow-x-auto rounded-lg bg-white p-2">
          <svg viewBox="0 0 420 230" class="mx-auto block w-full min-w-[280px] max-w-[440px]" role="img" aria-label="Diagrama de la posición de Do mayor en la guitarra">
            <rect x="42" y="24" width="336" height="174" rx="8" fill="#f5ead8" /><rect x="42" y="24" width="7" height="174" rx="2" fill="#8a6748" />
            <g stroke="#b99b76" stroke-width="2"><path d="M 112 24 V 198 M 202 24 V 198 M 292 24 V 198 M 378 24 V 198" /></g>
            <g stroke="#a6a69c"><path v-for="string in 6" :key="string" :d="'M 42 ' + (34 + (string - 1) * 31) + ' H 378'" :stroke-width="string === 1 || string === 6 ? 2.5 : 1.5" /></g>
            <g fill="#68766e" font-size="10" text-anchor="end"><text v-for="string in 6" :key="string" x="34" :y="38 + (string - 1) * 31">{{ string }}</text></g>
            <text v-if="active.id === 'root'" x="58" y="193" fill="#9b5540" font-size="17" font-weight="bold" text-anchor="middle">×</text>
            <g v-for="position in active.positions" :key="position.string + '-' + position.fret">
              <circle :cx="noteX(position.fret)" :cy="34 + (position.string - 1) * 31" r="12" fill="#176b5b" stroke="white" stroke-width="2" />
              <text :x="noteX(position.fret)" :y="38 + (position.string - 1) * 31" fill="white" font-size="10" font-weight="bold" text-anchor="middle">{{ degree(position.tone) }}</text>
            </g>
            <g fill="#718078" font-size="10" text-anchor="middle"><text x="58" y="216">Al aire</text><text x="77" y="15">Tr. 1</text><text x="167" y="15">Tr. 2</text><text x="257" y="15">Tr. 3</text></g>
          </svg>
          <p class="text-center text-[10px] text-[#829087]">Los números indican el grado del acorde (1, 3 o 5). Cuerdas: primera arriba, sexta abajo.</p>
        </div>
        <div class="mt-3"><p class="text-xs font-black text-[#426c5b]">Notas de esta posición · pulsa para escuchar</p>
          <div class="mt-2 grid gap-1.5 sm:grid-cols-2">
            <button v-for="note in notes" :key="note.string + '-' + note.fret" class="flex items-center justify-between rounded-lg bg-white px-3 py-2 text-left" @click="play(note)">
              <span><span class="text-xs font-bold text-[#365c4c]">{{ note.name }}{{ note.octave }}</span><span class="ml-2 text-[10px] text-[#829087]">Cuerda {{ note.string }} · {{ note.fret === 0 ? 'al aire' : 'traste ' + note.fret }}</span></span><Play :size="14" class="text-[#4c9c7c]" />
            </button>
          </div>
        </div>
        <p class="mt-2 rounded-lg bg-white px-3 py-2 text-[11px] leading-4 text-[#718078]">La guitarra puede duplicar notas en distintas octavas. Para reconocer la inversión, identifica la nota más grave que realmente suena.</p>
      </div>
    </div>

    <div class="mt-3 rounded-xl bg-[#f7f4ed] p-3">
      <p class="eyebrow">Comprueba lo aprendido</p>
      <template v-if="!done">
        <div class="mt-1 flex items-center justify-between gap-2"><h3 class="text-sm font-black text-[#365c4c]">Pregunta {{ questionIndex + 1 }} de {{ quiz.length }}</h3><span class="text-[11px] font-bold text-[#426c5b]">{{ score }} correctas</span></div>
        <p class="mt-2 text-sm font-semibold leading-5 text-[#365c4c]">{{ currentQuestion.q }}</p>
        <div class="mt-2 grid gap-2 sm:grid-cols-3"><button v-for="option in currentQuestion.options" :key="option" class="rounded-lg border-2 bg-white px-3 py-2 text-xs font-semibold" :class="checked && option === currentQuestion.answer ? 'border-[#4c9c7c] bg-[#edf4ee]' : answer === option ? 'border-[#8aa99a]' : 'border-transparent'" :disabled="checked" @click="answer = option">{{ option }}</button></div>
        <div v-if="checked" class="mt-2 rounded-lg p-3" :class="answer === currentQuestion.answer ? 'bg-[#e9f5ed] text-[#226447]' : 'bg-[#fff1e9] text-[#a14f2d]'">
          <p class="flex items-center gap-1.5 text-xs font-black"><CheckCircle2 v-if="answer === currentQuestion.answer" :size="14" /><XCircle v-else :size="14" />{{ answer === currentQuestion.answer ? '¡Correcto!' : 'Respuesta: ' + currentQuestion.answer }}</p><p class="mt-1 text-xs leading-5">{{ currentQuestion.why }}</p>
        </div>
        <div class="mt-3 flex justify-end"><button v-if="!checked" class="primary px-4 py-2 text-xs" :disabled="!answer" @click="checkAnswer">Comprobar</button><button v-else class="primary flex items-center gap-1.5 px-4 py-2 text-xs" @click="nextQuestion">{{ questionIndex === quiz.length - 1 ? 'Ver resultado' : 'Siguiente' }} <ArrowRight :size="14" /></button></div>
      </template>
      <div v-else class="py-3 text-center"><p class="eyebrow">Práctica terminada</p><h3 class="mt-1 text-2xl font-black text-[#365c4c]">{{ score }} / {{ quiz.length }}</h3><p class="mt-2 text-sm text-[#718078]">{{ score >= 4 ? '¡Muy bien! Ya reconoces las inversiones.' : 'Repasa qué grado queda en el bajo en cada inversión y vuelve a intentarlo.' }}</p><button class="primary mt-4 inline-flex items-center gap-2 px-4 py-2 text-xs" @click="restartQuiz"><RotateCcw :size="14" /> Repetir práctica</button></div>
    </div>
  </section>
</template>
