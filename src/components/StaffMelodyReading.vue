<script setup lang="ts">
import { computed, onBeforeUnmount, ref } from 'vue'
import { CheckCircle2, RotateCcw, XCircle } from 'lucide-vue-next'
import GuitarFretboard from './GuitarFretboard.vue'
import { fretMidi } from '../engines/guitar/fretboard'
import { playGuitarNote } from '../engines/audio/guitarSound'
import { useProgress } from '../composables/useProgress'

type Position = { string: number; fret: number; midi: number }

// Primera frase de «Estrellita, ¿dónde estás?» en Do mayor.
// El pentagrama muestra la escritura para guitarra (una octava arriba).
const melody = [72, 72, 79, 79, 81, 81, 79, 77, 77, 76, 76, 74, 74, 72]
const noteX = [70, 100, 130, 160, 225, 255, 285, 350, 380, 410, 440, 505, 535, 565]
const halfNotes = [6, 13]
const barLines = [190, 315, 470, 595]
const noteY: Record<number, number> = {
  72: 72.5, // Do5
  74: 65,   // Re5
  76: 57.5, // Mi5
  77: 50,   // Fa5
  79: 42.5, // Sol5
  81: 35,   // La5
}

const { record, complete } = useProgress()
const activeIndex = ref(0)
const selected = ref<Position | null>(null)
const completedPositions = ref<{ string: number; fret: number }[]>([])
const feedback = ref<'correct' | 'wrong' | null>(null)
let advanceTimer: ReturnType<typeof setTimeout> | undefined

const finished = computed(() => activeIndex.value >= melody.length)
const currentMidi = computed(() => melody[activeIndex.value] ?? null)
const progress = computed(() => Math.round(activeIndex.value / melody.length * 100))

function isCompleted(index: number) {
  return index < activeIndex.value
}

function choose(position: Position) {
  if (finished.value || feedback.value === 'correct' || currentMidi.value === null) return

  const isCorrect = position.midi === currentMidi.value - 12
  record(isCorrect)

  if (!isCorrect) {
    selected.value = null
    feedback.value = 'wrong'
    return
  }

  selected.value = position
  feedback.value = 'correct'
  if (!completedPositions.value.some(item => item.string === position.string && item.fret === position.fret)) {
    completedPositions.value.push({ string: position.string, fret: position.fret })
  }
  void playGuitarNote(position.midi, position.string)

  advanceTimer = setTimeout(() => {
    activeIndex.value++
    selected.value = null
    feedback.value = null
    if (activeIndex.value >= melody.length) complete(3)
  }, 550)
}

function restart() {
  if (advanceTimer) clearTimeout(advanceTimer)
  activeIndex.value = 0
  selected.value = null
  completedPositions.value = []
  feedback.value = null
}

onBeforeUnmount(() => {
  if (advanceTimer) clearTimeout(advanceTimer)
})
</script>

<template>
  <section class="panel mb-4 p-3 sm:p-4">
    <div class="mb-3">
      <p class="eyebrow">Lectura musical · Aplicación en guitarra</p>
      <h2 class="text-lg font-black">De la partitura al diapasón</h2>
      <p class="mt-1 text-sm leading-5 text-[#788780]">
        Lee la melodía en el pentagrama y encuentra cada nota en la guitarra. Cuando aciertes, la nota quedará marcada y escucharás su sonido.
      </p>
    </div>

    <div class="rounded-xl bg-[#f5f8f4] p-2 sm:p-3">
      <div class="mb-2 flex flex-wrap items-center justify-between gap-2">
        <div>
          <p class="eyebrow">Melodía de práctica</p>
          <p class="text-sm font-black text-[#365c4c]">Estrellita, ¿dónde estás?</p>
        </div>
        <span class="rounded-full bg-white px-2.5 py-1 text-[11px] font-bold text-[#426c5b]">
          {{ finished ? melody.length : activeIndex + 1 }} / {{ melody.length }} notas
        </span>
      </div>

      <div class="h-1.5 overflow-hidden rounded-full bg-[#e1e9e0]">
        <div class="h-full rounded-full bg-[#4c9c7c] transition-all duration-300" :style="{ width: progress + '%' }"></div>
      </div>

      <div class="mt-2 overflow-x-auto rounded-lg bg-[#fbfaf6] p-2">
        <svg viewBox="0 0 640 150" class="mx-auto block w-full min-w-[490px] max-w-[700px]" role="img" aria-label="Melodía Estrellita en clave de sol">
          <g stroke="#89958e" stroke-width="1.2">
            <path v-for="line in 5" :key="line" :d="'M 20 ' + (50 + (line - 1) * 15) + ' H 620'" />
          </g>
          <text x="27" y="112" font-size="72" fill="#176b5b">𝄞</text>
          <g stroke="#89958e" stroke-width="1.5">
            <path v-for="bar in barLines" :key="bar" :d="'M ' + bar + ' 50 V 110'" />
          </g>
          <g v-for="(midi, index) in melody" :key="index">
            <path
              v-if="midi === 81"
              :d="'M ' + (noteX[index] - 12) + ' 35 h 24'"
              :stroke="index < activeIndex ? '#176b5b' : index === activeIndex ? '#c07832' : '#a8b2aa'"
              stroke-width="1.4"
            />
            <path
              :d="'M ' + (noteX[index] - 7) + ' ' + noteY[midi] + ' v 34'"
              :stroke="index < activeIndex ? '#176b5b' : index === activeIndex ? '#c07832' : '#a8b2aa'"
              stroke-width="1.8"
            />
            <ellipse
              :cx="noteX[index]"
              :cy="noteY[midi]"
              rx="8"
              ry="5.5"
              :fill="halfNotes.includes(index) ? '#fbfaf6' : index < activeIndex ? '#176b5b' : index === activeIndex ? '#c07832' : '#a8b2aa'"
              :stroke="index < activeIndex ? '#176b5b' : index === activeIndex ? '#c07832' : '#a8b2aa'"
              stroke-width="1.8"
              :transform="'rotate(-18 ' + noteX[index] + ' ' + noteY[midi] + ')'"
            />
            <ellipse
              v-if="index === activeIndex && !finished"
              :cx="noteX[index]"
              :cy="noteY[midi]"
              rx="14"
              ry="11"
              fill="none"
              stroke="#c07832"
              stroke-width="1.5"
              stroke-dasharray="3 2"
            />
          </g>
        </svg>
        <p class="text-center text-[10px] text-[#829087]">Clave de sol · Do mayor · las notas completadas se colorean al tocarlas correctamente</p>
      </div>
    </div>

    <div class="mt-3 flex flex-wrap items-center justify-between gap-2">
      <div>
        <p class="eyebrow">Tu instrumento</p>
        <h3 class="text-sm font-black text-[#365c4c]">Encuentra la nota resaltada</h3>
      </div>
      <span class="text-[10px] text-[#829087]">Primera posición · trastes 0–5</span>
    </div>
    <div class="mt-2">
      <GuitarFretboard
        :start-fret="0"
        :end-fret="5"
        :selected="selected"
        :completed-positions="completedPositions"
        :disabled="finished || feedback === 'correct'"
        @select="choose"
      />
    </div>

    <div v-if="feedback === 'wrong'" class="mt-2 flex items-center gap-2 rounded-lg bg-[#fff1e9] p-2 text-[#a14f2d]">
      <XCircle :size="17" />
      <p class="text-xs font-semibold">Esa posición no corresponde a la nota resaltada. Prueba en otra cuerda o traste.</p>
    </div>
    <div v-else-if="feedback === 'correct' && !finished" class="mt-2 flex items-center gap-2 rounded-lg bg-[#e9f5ed] p-2 text-[#226447]">
      <CheckCircle2 :size="17" />
      <p class="text-xs font-semibold">¡Correcto! Escucha la nota y continúa con la siguiente.</p>
    </div>

    <div v-if="finished" class="mt-3 rounded-xl bg-[#e9f5ed] p-3 text-center text-[#226447]">
      <CheckCircle2 :size="24" class="mx-auto" />
      <h3 class="mt-1 text-base font-black">¡Melodía completada!</h3>
      <p class="mt-1 text-xs">Has llevado las 14 notas del pentagrama al diapasón.</p>
      <button class="primary mt-3 inline-flex items-center gap-2 px-4 py-2 text-xs" @click="restart">
        <RotateCcw :size="14" /> Repetir melodía
      </button>
    </div>
    <p v-else class="mt-2 text-center text-[11px] text-[#788780]">
      Haz clic directamente sobre la cuerda y el traste donde se encuentra la nota. No necesitas escribir su nombre.
    </p>
  </section>
</template>
