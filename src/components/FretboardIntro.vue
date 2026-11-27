<script setup lang="ts">
import { computed, ref } from 'vue'
import { ArrowRight, CheckCircle2, Volume2, XCircle } from 'lucide-vue-next'
import GuitarFretboard from './GuitarFretboard.vue'
import { fretMidi } from '../engines/guitar/fretboard'
import { midiName } from '../engines/music/pitch'
import { playGuitarNote } from '../engines/audio/guitarSound'

const lessons = [
  { string: 1, fret: 1, explanation: 'La primera cuerda al aire es Mi. Al subir un traste llegamos a Fa.', hint: 'Primera cuerda · traste 1' },
  { string: 1, fret: 3, explanation: 'Desde Fa avanzamos dos semitonos: Fa♯ y después Sol.', hint: 'Primera cuerda · traste 3' },
  { string: 2, fret: 1, explanation: 'La segunda cuerda al aire es Si. Su primer traste produce Do.', hint: 'Segunda cuerda · traste 1' },
  { string: 3, fret: 2, explanation: 'La tercera cuerda al aire es Sol. Dos trastes más arriba encontramos La.', hint: 'Tercera cuerda · traste 2' },
  { string: 6, fret: 3, explanation: 'La sexta cuerda al aire es Mi grave. En el tercer traste encontramos Sol.', hint: 'Sexta cuerda · traste 3' },
] as const

const sameNoteLessons = [
  { name: 'Do4', source: { string: 2, fret: 1 }, target: { string: 3, fret: 5 }, explanation: 'El Do4 que ya conoces está en la segunda cuerda, traste 1. La misma altura también aparece en la tercera cuerda, traste 5.' },
  { name: 'Mi4', source: { string: 1, fret: 0 }, target: { string: 2, fret: 5 }, explanation: 'El Mi4 de la primera cuerda al aire también se encuentra en la segunda cuerda, traste 5. Escucha cómo ambas posiciones producen la misma altura.' },
  { name: 'Sol3', source: { string: 3, fret: 0 }, target: { string: 4, fret: 5 }, explanation: 'El Sol3 de la tercera cuerda al aire también aparece en la cuarta cuerda, traste 5. Cambia la cuerda, pero la altura se conserva.' },
] as const

const index = ref(0)
const selected = ref<{ string: number; fret: number } | null>(null)
const feedback = ref<'correct' | 'wrong' | null>(null)
const finished = ref(false)
const sameStarted = ref(false)
const sameIndex = ref(0)
const sameSelected = ref<{ string: number; fret: number } | null>(null)
const sameFeedback = ref<'correct' | 'wrong' | null>(null)
const sameFinished = ref(false)
const current = computed(() => lessons[index.value])
const targetMidi = computed(() => fretMidi(current.value.string, current.value.fret))
const targetName = computed(() => midiName(targetMidi.value))
const sameCurrent = computed(() => sameNoteLessons[sameIndex.value])
const sameTargetMidi = computed(() => fretMidi(sameCurrent.value.target.string, sameCurrent.value.target.fret))
const sameTargetName = computed(() => midiName(sameTargetMidi.value))

function choose(position: { string: number; fret: number; midi: number }) {
  if (feedback.value === 'correct' || finished.value) return
  selected.value = position
  void playGuitarNote(position.midi, position.string)
  feedback.value = position.string === current.value.string && position.fret === current.value.fret
    ? 'correct'
    : 'wrong'
}

function listen() {
  void playGuitarNote(targetMidi.value, current.value.string)
}

function next() {
  if (index.value === lessons.length - 1) {
    finished.value = true
    return
  }
  index.value++
  selected.value = null
  feedback.value = null
}

function startSameNotes() {
  sameStarted.value = true
  sameIndex.value = 0
  sameSelected.value = null
  sameFeedback.value = null
  sameFinished.value = false
}

function listenSameSource() {
  void playGuitarNote(fretMidi(sameCurrent.value.source.string, sameCurrent.value.source.fret), sameCurrent.value.source.string)
}

function listenSameTarget() {
  void playGuitarNote(sameTargetMidi.value, sameCurrent.value.target.string)
}

function chooseSame(position: { string: number; fret: number; midi: number }) {
  if (sameFeedback.value === 'correct' || sameFinished.value) return
  sameSelected.value = position
  void playGuitarNote(position.midi, position.string)
  sameFeedback.value = position.string === sameCurrent.value.target.string && position.fret === sameCurrent.value.target.fret
    ? 'correct'
    : 'wrong'
}

function nextSame() {
  if (sameIndex.value === sameNoteLessons.length - 1) {
    sameFinished.value = true
    return
  }
  sameIndex.value++
  sameSelected.value = null
  sameFeedback.value = null
}
</script>

<template>
  <section class="panel mb-4 p-3 sm:p-4">
    <div class="mb-3">
      <p class="eyebrow">Módulo 02 · Lección guiada</p>
      <h2 class="mt-1 text-xl font-black">Aprende a ubicar las primeras notas</h2>
      <p class="mt-1 max-w-2xl text-sm leading-5 text-[#788780]">
        Usaremos las cuerdas al aire como puntos de referencia. Cada traste que avanzas sube un semitono. Observa el ejemplo, escucha la nota y encuentra su posición.
      </p>
    </div>

    <div v-if="!finished">
      <div class="mb-3 flex items-center justify-between gap-3">
        <span class="rounded-full bg-[#edf4ee] px-3 py-1 text-[11px] font-bold text-[#426c5b]">Paso {{ index + 1 }} de {{ lessons.length }}</span>
        <div class="flex gap-1" aria-label="Progreso de la lección">
          <span v-for="step in lessons.length" :key="step" class="h-1.5 w-7 rounded-full" :class="step <= index + 1 ? 'bg-[#4c9c7c]' : 'bg-[#e5ebe5]'"></span>
        </div>
      </div>

      <div class="grid gap-3 lg:grid-cols-[minmax(0,0.85fr)_minmax(0,1.4fr)]">
        <div class="rounded-xl bg-[#f5f8f4] p-3">
          <p class="text-[10px] font-bold uppercase tracking-wide text-[#718078]">Punto de referencia</p>
          <p class="mt-1 text-sm font-extrabold text-[#365c4c]">{{ current.explanation }}</p>
          <div class="mt-3 flex items-center justify-between rounded-lg bg-white p-3">
            <div>
              <p class="text-[10px] font-bold uppercase text-[#829087]">Encuentra</p>
              <p class="text-2xl font-black text-[#176b5b]">{{ targetName.name }}<sub class="ml-0.5 text-sm">{{ targetName.octave }}</sub></p>
              <p class="text-[10px] text-[#829087]">{{ current.hint }}</p>
            </div>
            <button class="secondary flex items-center gap-2" @click="listen"><Volume2 :size="18"/> Escuchar</button>
          </div>
          <p class="mt-2 text-xs leading-5 text-[#718078]">En esta primera actividad buscamos la nota en la cuerda indicada. Más adelante aprenderás a encontrar la misma altura en otras cuerdas.</p>
        </div>

        <div class="min-w-0 rounded-xl bg-[#f7f4ed] p-2 sm:p-3">
          <div class="mb-1 flex items-center justify-between gap-2">
            <h3 class="text-sm font-extrabold">Selecciona la posición</h3>
            <span class="text-[10px] text-[#829087]">Trastes 1–5</span>
          </div>
          <GuitarFretboard
            :start-fret="1"
            :end-fret="5"
            :selected="selected"
            :disabled="feedback === 'correct'"
            @select="choose"
          />
        </div>
      </div>

      <div v-if="feedback === 'wrong'" class="mt-3 flex items-center gap-2 rounded-lg bg-[#fff1e9] p-3 text-[#a14f2d]">
        <XCircle :size="18"/>
        <p class="text-xs font-semibold">Esa no es la posición indicada. Usa la cuerda y el traste del ejemplo e inténtalo otra vez.</p>
      </div>
      <div v-else-if="feedback === 'correct'" class="mt-3 flex items-center gap-2 rounded-lg bg-[#e9f5ed] p-3 text-[#226447]">
        <CheckCircle2 :size="19"/>
        <div class="flex-1">
          <p class="text-sm font-bold">¡Correcto! {{ targetName.name }}{{ targetName.octave }} está en esa posición.</p>
          <p class="mt-0.5 text-xs">Has relacionado el nombre de la nota con su lugar en el mástil.</p>
        </div>
        <button class="primary flex shrink-0 items-center gap-1.5 px-3 py-2 text-xs" @click="next">
          {{ index === lessons.length - 1 ? 'Terminar' : 'Continuar' }} <ArrowRight :size="15"/>
        </button>
      </div>
      <p v-else class="mt-3 text-center text-xs text-[#788780]">Selecciona una posición en el diapasón para comprobarla.</p>
    </div>

    <div v-else class="rounded-xl bg-[#e9f5ed] p-4 text-center">
      <CheckCircle2 :size="30" class="mx-auto text-[#34795d]"/>
      <h3 class="mt-2 text-lg font-black text-[#226447]">¡Primera exploración completada!</h3>
      <p class="mx-auto mt-1 max-w-xl text-sm leading-5 text-[#567267]">Ya relacionaste cinco notas naturales con sus posiciones. El siguiente paso es descubrir que una misma nota puede tocarse en más de una cuerda.</p>
      <div class="mt-3 flex flex-wrap justify-center gap-2">
        <button class="primary" @click="startSameNotes">Aprender la misma nota en otra cuerda <ArrowRight :size="15"/></button>
        <button class="secondary" @click="index = 0; selected = null; feedback = null; finished = false; sameStarted = false">Repetir la lección</button>
      </div>
    </div>

    <div v-if="sameStarted && !sameFinished" class="mt-4 rounded-xl border border-[#dce7df] p-3 sm:p-4">
      <div class="mb-3 flex items-center justify-between gap-3">
        <div>
          <p class="eyebrow">Lección guiada · Equivalencias</p>
          <h3 class="mt-1 text-lg font-black">La misma nota en otra cuerda</h3>
        </div>
        <span class="rounded-full bg-[#edf4ee] px-3 py-1 text-[11px] font-bold text-[#426c5b]">Ejemplo {{ sameIndex + 1 }} de {{ sameNoteLessons.length }}</span>
      </div>

      <div class="grid gap-3 lg:grid-cols-[minmax(0,0.85fr)_minmax(0,1.4fr)]">
        <div class="rounded-xl bg-[#f5f8f4] p-3">
          <p class="text-[10px] font-bold uppercase tracking-wide text-[#718078]">Observa y escucha</p>
          <p class="mt-1 text-sm leading-5 text-[#365c4c]">{{ sameCurrent.explanation }}</p>
          <div class="mt-3 grid grid-cols-2 gap-2">
            <button class="secondary flex flex-col items-center gap-1 p-3 text-center" @click="listenSameSource">
              <span class="text-[10px] font-bold uppercase text-[#829087]">Posición conocida</span>
              <span class="text-xl font-black">{{ sameCurrent.name }}</span>
              <span class="text-xs">Cuerda {{ sameCurrent.source.string }} · traste {{ sameCurrent.source.fret }}</span>
              <Volume2 :size="17"/>
            </button>
            <button class="secondary flex flex-col items-center gap-1 p-3 text-center" @click="listenSameTarget">
              <span class="text-[10px] font-bold uppercase text-[#829087]">Otra posición</span>
              <span class="text-xl font-black">{{ sameCurrent.name }}</span>
              <span class="text-xs">Cuerda {{ sameCurrent.target.string }} · traste {{ sameCurrent.target.fret }}</span>
              <Volume2 :size="17"/>
            </button>
          </div>
          <p class="mt-2 text-xs leading-5 text-[#718078]">Las dos posiciones producen la misma altura. Escúchalas y luego localiza la segunda en el diapasón.</p>
        </div>

        <div class="min-w-0 rounded-xl bg-[#f7f4ed] p-2 sm:p-3">
          <div class="mb-1 flex items-center justify-between gap-2">
            <h4 class="text-sm font-extrabold">Encuentra {{ sameCurrent.name }} en la otra cuerda</h4>
            <span class="text-[10px] text-[#829087]">Trastes 0–5</span>
          </div>
          <GuitarFretboard
            :start-fret="0"
            :end-fret="5"
            :selected="sameSelected"
            :disabled="sameFeedback === 'correct'"
            @select="chooseSame"
          />
        </div>
      </div>

      <div v-if="sameFeedback === 'wrong'" class="mt-3 flex items-center gap-2 rounded-lg bg-[#fff1e9] p-3 text-[#a14f2d]">
        <XCircle :size="18"/>
        <p class="text-xs font-semibold">Esa posición no produce la misma nota. Compara la cuerda y el traste con el ejemplo e inténtalo de nuevo.</p>
      </div>
      <div v-else-if="sameFeedback === 'correct'" class="mt-3 flex items-center gap-2 rounded-lg bg-[#e9f5ed] p-3 text-[#226447]">
        <CheckCircle2 :size="19"/>
        <div class="flex-1">
          <p class="text-sm font-bold">¡Exacto! Encontraste {{ sameCurrent.name }} en otra cuerda.</p>
          <p class="mt-0.5 text-xs">La cuerda cambia, pero la altura de la nota es la misma.</p>
        </div>
        <button class="primary flex shrink-0 items-center gap-1.5 px-3 py-2 text-xs" @click="nextSame">
          {{ sameIndex === sameNoteLessons.length - 1 ? 'Terminar' : 'Continuar' }} <ArrowRight :size="15"/>
        </button>
      </div>
      <p v-else class="mt-3 text-center text-xs text-[#788780]">Selecciona la segunda posición para comprobarla.</p>
    </div>

    <div v-if="sameFinished" class="mt-4 rounded-xl bg-[#e9f5ed] p-4 text-center">
      <CheckCircle2 :size="30" class="mx-auto text-[#34795d]"/>
      <h3 class="mt-2 text-lg font-black text-[#226447]">¡Ya reconoces notas en más de una cuerda!</h3>
      <p class="mx-auto mt-1 max-w-xl text-sm leading-5 text-[#567267]">Comprobaste tres equivalencias: Do4, Mi4 y Sol3. Una misma altura puede aparecer en diferentes cuerdas y posiciones. Continúa ahora con los ejercicios de identificación.</p>
      <button class="secondary mt-3" @click="startSameNotes">Repetir esta parte</button>
    </div>
  </section>
</template>
