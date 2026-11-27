<script setup lang="ts">
import { computed, ref, watch } from 'vue'
import { ArrowRight, CheckCircle2, Volume2, XCircle } from 'lucide-vue-next'
import GuitarFretboard from './GuitarFretboard.vue'
import { fretMidi } from '../engines/guitar/fretboard'
import { midiName } from '../engines/music/pitch'
import { playGuitarNote } from '../engines/audio/guitarSound'
import { useProgress } from '../composables/useProgress'
import { DEFAULT_FRETBOARD_REGIONS } from '../types/learning'

const { record, complete } = useProgress()
const regionId = ref('beginner-1-5')
const selectedRegion = computed(() =>
  DEFAULT_FRETBOARD_REGIONS.find(region => region.id === regionId.value)
  ?? DEFAULT_FRETBOARD_REGIONS[0],
)
const targetPool = computed(() => {
  const pitches = new Set<number>()
  for (let string = 1; string <= 6; string++) {
    for (let fret = selectedRegion.value.startFret; fret <= selectedRegion.value.endFret; fret++) {
      pitches.add(fretMidi(string, fret))
    }
  }
  return [...pitches].sort((a, b) => a - b)
})

const round = ref(1)
const target = ref(45)
const selected = ref<{ string: number; fret: number } | null>(null)
const answered = ref(false)
const correct = ref(false)
const name = computed(() => midiName(target.value))

watch(regionId, () => {
  round.value = 1
  target.value = targetPool.value[0] ?? 45
  selected.value = null
  answered.value = false
  correct.value = false
})

function next() {
  round.value++
  const pool = targetPool.value
  const currentIndex = pool.indexOf(target.value)
  const offset = 1 + ((round.value * 7 + 3) % Math.max(pool.length - 1, 1))
  target.value = pool[(currentIndex + offset) % pool.length] ?? pool[0] ?? 45
  selected.value = null
  answered.value = false
  correct.value = false
}

function choose(position: { string: number; fret: number; midi: number }) {
  if (answered.value) return
  selected.value = position
  void playGuitarNote(position.midi, position.string)
  correct.value = fretMidi(position.string, position.fret) === target.value
  record(correct.value)

  if (correct.value) {
    answered.value = true
    complete(2)
  }
}
</script>

<template>
  <section class="panel p-3 sm:p-4">
    <div class="flex justify-between gap-2">
      <div>
        <p class="eyebrow">Reto de notas · {{ selectedRegion.level === 'beginner' ? 'Principiante' : selectedRegion.level === 'intermediate' ? 'Intermedio' : 'Avanzado' }}</p>
        <h2 class="mt-0.5 text-xl font-black">Encuentra la nota</h2>
        <p class="mt-0.5 text-xs text-[#788780]">La nota indicada corresponde al sonido real de la guitarra. Escúchala y localízala en la región seleccionada.</p>
      </div>
      <span class="rounded-full bg-[#eef4ef] px-2.5 py-1 text-[11px] font-bold text-[#426c5b]">Ronda {{ round }}</span>
    </div>

    <div class="mt-3 grid gap-2 sm:grid-cols-[minmax(0,1fr)_minmax(0,1.4fr)] sm:items-end">
      <label class="block">
        <span class="mb-1 block text-[11px] font-bold uppercase tracking-wide text-[#718078]">Nivel y región</span>
        <select v-model="regionId" class="w-full rounded-lg border border-[#dce5dc] bg-white px-3 py-2 text-sm font-semibold text-[#365c4c]">
          <option v-for="region in DEFAULT_FRETBOARD_REGIONS" :key="region.id" :value="region.id">
            {{ region.level === 'beginner' ? 'Principiante' : region.level === 'intermediate' ? 'Intermedio' : 'Avanzado' }} · Trastes {{ region.startFret }}–{{ region.endFret }}
          </option>
        </select>
      </label>
      <p class="rounded-lg bg-[#f3f7f2] px-3 py-2 text-xs leading-5 text-[#718078]">
        {{ selectedRegion.level === 'beginner'
          ? 'Comienza ubicando notas naturales en la primera posición.'
          : selectedRegion.level === 'intermediate'
            ? 'Amplía tu orientación hacia la región media del mástil.'
            : 'Practica el desplazamiento por distintas posiciones del diapasón.' }}
      </p>
    </div>

    <div class="my-3 flex items-center justify-center gap-3 rounded-xl bg-[#f5f8f4] p-2 sm:p-3">
      <div class="text-center">
        <p class="text-[10px] font-bold uppercase text-[#718078]">Busca esta nota</p>
        <p class="mt-0.5 text-2xl font-black text-[#176b5b]">{{ name.name }}</p>
        <p class="text-xs text-[#75827b]">Octava {{ name.octave }}</p>
      </div>
      <button class="secondary flex items-center gap-2" @click="playGuitarNote(target)">
        <Volume2 :size="19" /> Escuchar
      </button>
    </div>

    <div class="mb-1 flex items-center justify-between gap-2">
      <h3 class="text-sm font-extrabold">Diapasón de guitarra</h3>
      <span class="text-[10px] text-[#829087]">Trastes {{ selectedRegion.startFret }}–{{ selectedRegion.endFret }}</span>
    </div>
    <GuitarFretboard
      :start-fret="selectedRegion.startFret"
      :end-fret="selectedRegion.endFret"
      :selected="selected"
      :disabled="answered"
      @select="choose"
    />

    <p class="mt-2 text-center text-xs text-[#788780]">
      Las etiquetas muestran la altura que suena. En el pentagrama de guitarra esa misma altura se escribe una octava más arriba.
    </p>

    <div v-if="selected && !correct" class="mt-2 flex items-center gap-2 rounded-lg bg-[#fff1e9] p-2.5 text-[#a14f2d]">
      <XCircle />
      <p class="flex-1 text-sm font-semibold">Todavía no. Prueba otra posición.</p>
    </div>
    <div v-if="correct" class="mt-2 flex items-center gap-2 rounded-lg bg-[#e9f5ed] p-2.5 text-[#226447]">
      <CheckCircle2 />
      <div class="flex-1">
        <p class="text-xs font-semibold">¡Muy bien! Has encontrado la nota.</p>
        <p class="mt-0.5 text-[11px]">Cuando estés listo, continúa con el siguiente reto.</p>
      </div>
      <button class="primary flex shrink-0 items-center gap-2" @click="next">
        Continuar <ArrowRight :size="17" />
      </button>
    </div>
  </section>
</template>
