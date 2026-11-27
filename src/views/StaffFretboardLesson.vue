<script setup lang="ts">
import { computed, ref, watch } from 'vue'
import { ArrowRight, CheckCircle2, XCircle } from 'lucide-vue-next'
import GuitarFretboard from '../components/GuitarFretboard.vue'
import StaffNote from '../components/StaffNote.vue'
import StaffAccidentalsIntro from '../components/StaffAccidentalsIntro.vue'
import StaffMeasureAccidentals from '../components/StaffMeasureAccidentals.vue'
import StaffAccidentalMelody from '../components/StaffAccidentalMelody.vue'
import StaffKeySignatureIntro from '../components/StaffKeySignatureIntro.vue'
import StaffKeySignaturePractice from '../components/StaffKeySignaturePractice.vue'
import { fretMidi } from '../engines/guitar/fretboard'
import { playGuitarNote } from '../engines/audio/guitarSound'
import { useProgress } from '../composables/useProgress'
import { DEFAULT_FRETBOARD_REGIONS } from '../types/learning'

const { record, complete } = useProgress()
const regionId = ref('beginner-1-5')
const selectedRegion = computed(() =>
  DEFAULT_FRETBOARD_REGIONS.find(region => region.id === regionId.value)
  ?? DEFAULT_FRETBOARD_REGIONS[0],
)

/**
 * El pentagrama muestra la nota escrita para guitarra.
 * La posición física se calcula una octava por debajo (MIDI - 12).
 * Los objetivos se derivan de las posiciones reales disponibles en la región.
 */
const writtenNotePool = computed(() => {
  const pitches = new Set<number>()
  for (let string = 1; string <= 6; string++) {
    for (let fret = selectedRegion.value.startFret; fret <= selectedRegion.value.endFret; fret++) {
      pitches.add(fretMidi(string, fret) + 12)
    }
  }
  return [...pitches].sort((a, b) => a - b)
})

const round = ref(1)
const target = ref(writtenNotePool.value[0] ?? 60)
const selected = ref<{ string: number; fret: number } | null>(null)
const feedback = ref<'correct' | 'wrong' | null>(null)
const recentTargets = ref<number[]>([])

function chooseNextTarget() {
  const pool = writtenNotePool.value
  const available = pool.filter(note => !recentTargets.value.includes(note))
  const choices = available.length ? available : pool
  const nextTarget = choices[Math.floor(Math.random() * choices.length)] ?? pool[0] ?? 60
  target.value = nextTarget
  recentTargets.value = [...recentTargets.value, nextTarget].slice(-Math.max(1, Math.floor(pool.length / 2)))
}

function resetExercise() {
  round.value = 1
  selected.value = null
  feedback.value = null
  recentTargets.value = []
  chooseNextTarget()
}

watch(regionId, resetExercise)

function next() {
  round.value++
  selected.value = null
  feedback.value = null
  chooseNextTarget()
}

function choose(position: { string: number; fret: number; midi: number }) {
  if (feedback.value === 'correct') return
  selected.value = position
  void playGuitarNote(position.midi, position.string)
  const soundingMidi = target.value - 12
  const isCorrect = fretMidi(position.string, position.fret) === soundingMidi
  record(isCorrect)
  feedback.value = isCorrect ? 'correct' : 'wrong'

  if (isCorrect) complete(3)
}
</script>

<template>
  <div class="page">
    <div class="mb-3">
      <p class="eyebrow">Lectura musical · Nivel {{ selectedRegion.level === 'beginner' ? '1' : selectedRegion.level === 'intermediate' ? '2' : '3' }}</p>
      <h1 class="mt-0.5 text-xl font-black">Notas en el pentagrama</h1>
      <p class="mt-0.5 max-w-2xl text-xs leading-4 text-[#788780]">
        Lee la nota en clave de sol y encuentra su lugar en el diapasón. Los ejercicios recorren una extensión más amplia de notas y evitan repetirlas continuamente.
      </p>
    </div>

    <StaffAccidentalsIntro />
    <StaffMeasureAccidentals />
    <StaffAccidentalMelody />
    <StaffKeySignatureIntro />
    <StaffKeySignaturePractice />

    <section class="panel p-3 sm:p-4">
      <div class="mb-3 grid gap-2 sm:grid-cols-[minmax(0,1fr)_minmax(0,1.2fr)] sm:items-end">
        <label class="block">
          <span class="mb-1 block text-[11px] font-bold uppercase tracking-wide text-[#718078]">Nivel y región del diapasón</span>
          <select v-model="regionId" class="w-full rounded-lg border border-[#dce5dc] bg-white px-3 py-2 text-sm font-semibold text-[#365c4c]">
            <option v-for="region in DEFAULT_FRETBOARD_REGIONS" :key="region.id" :value="region.id">
              {{ region.level === 'beginner' ? 'Principiante' : region.level === 'intermediate' ? 'Intermedio' : 'Avanzado' }} · Trastes {{ region.startFret }}–{{ region.endFret }}
            </option>
          </select>
        </label>
        <p class="rounded-lg bg-[#f3f7f2] px-3 py-2 text-xs leading-5 text-[#718078]">
          {{ writtenNotePool.length }} alturas disponibles en esta región. La nota escrita se convierte a sonido real una octava más grave para comprobar la posición.
        </p>
      </div>

      <div class="mb-2 flex items-center justify-between gap-3">
        <div>
          <p class="eyebrow">Lee y encuentra</p>
          <h2 class="mt-0.5 text-lg font-black">¿Dónde está esta nota?</h2>
        </div>
        <span class="rounded-full bg-[#eef4ef] px-2.5 py-1 text-[11px] font-bold text-[#426c5b]">Ejercicio {{ round }}</span>
      </div>

      <div class="grid grid-cols-1 items-center gap-3 lg:grid-cols-[minmax(230px,0.75fr)_minmax(0,1.5fr)] lg:gap-5">
        <div class="rounded-xl bg-[#f5f8f4] p-2">
          <p class="mb-0.5 text-center text-[10px] font-bold uppercase tracking-wide text-[#718078]">Nota escrita para guitarra</p>
          <StaffNote :midi="target" />
          <p class="mt-0.5 text-center text-[11px] font-semibold text-[#176b5b]">
            Busca la nota en el instrumento.
          </p>
        </div>

        <div class="min-w-0">
          <div class="mb-1 flex items-center justify-between gap-2">
            <h3 class="text-sm font-extrabold">Diapasón de guitarra</h3>
            <span class="text-[10px] text-[#829087]">Trastes {{ selectedRegion.startFret }}–{{ selectedRegion.endFret }}</span>
          </div>
          <GuitarFretboard
            :start-fret="selectedRegion.startFret"
            :end-fret="selectedRegion.endFret"
            :selected="selected"
            :disabled="feedback === 'correct'"
            @select="choose"
          />
        </div>
      </div>

      <div v-if="feedback === 'wrong'" class="mt-2 flex items-center gap-2 rounded-lg bg-[#fff1e9] p-2 text-[#a14f2d]">
        <XCircle :size="18" />
        <p class="text-xs font-semibold">Esa posición produce otra nota. ¡Inténtalo de nuevo!</p>
      </div>
      <div v-else-if="feedback === 'correct'" class="mt-2 flex items-center gap-2 rounded-lg bg-[#e9f5ed] p-2 text-[#226447]">
        <CheckCircle2 :size="18" />
        <div class="flex-1">
          <p class="text-xs font-semibold">¡Correcto! Has relacionado el pentagrama con la guitarra.</p>
          <p class="mt-0.5 text-[11px]">Cuando estés listo, continúa con la siguiente nota.</p>
        </div>
        <button class="primary flex shrink-0 items-center gap-1.5 px-3 py-2 text-xs" @click="next">
          Continuar <ArrowRight :size="15" />
        </button>
      </div>
      <p v-else class="mt-2 text-center text-xs text-[#788780]">
        Selecciona una cuerda y un traste. La respuesta se comprueba automáticamente.
      </p>
    </section>

    <div class="mt-2 rounded-xl bg-[#edf4ee] p-2.5 text-[11px] leading-4 text-[#567267]">
      <b>Recuerda:</b> el pentagrama de guitarra escribe las notas una octava por encima de su sonido real. Por ejemplo, un Sol4 escrito corresponde al Sol3 que suena en la tercera cuerda al aire.
    </div>
  </div>
</template>
