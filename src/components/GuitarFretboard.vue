<script setup lang="ts">
import { computed } from 'vue'
import { fretMidi } from '../engines/guitar/fretboard'
import { midiName } from '../engines/music/pitch'

interface FretPosition {
  string: number
  fret: number
  midi: number
}

const props = withDefaults(
  defineProps<{
    selected: { string: number; fret: number } | null
    completedPositions?: { string: number; fret: number }[]
    disabled?: boolean
    startFret?: number
    endFret?: number
  }>(),
  { selected: null, completedPositions: () => [], disabled: false, startFret: 0, endFret: 5 },
)

const emit = defineEmits<{
  (event: 'select', position: FretPosition): void
}>()

const strings = [1, 2, 3, 4, 5, 6]
const regionIsValid = computed(() =>
  Number.isInteger(props.startFret)
  && Number.isInteger(props.endFret)
  && props.startFret >= 0
  && props.endFret <= 24
  && props.endFret >= props.startFret
  && (props.endFret - props.startFret === 4 || (props.startFret === 0 && props.endFret === 5)),
)
const legacyOpenStringView = computed(() => props.startFret === 0 && props.endFret === 5)
const frets = computed(() =>
  regionIsValid.value
    ? Array.from({ length: legacyOpenStringView.value ? 6 : 5 }, (_, index) => props.startFret + index)
    : [],
)

const stringY = (index: number) => 35 + index * 35
const fretCenterX = (fret: number) =>
  fret === 0 ? 38 : 94 + (fret - Math.max(props.startFret, 1)) * 112
const fretWireX = (fret: number) => fretCenterX(fret) + 56
const fretHitboxX = (fret: number) => fret === 0 ? 25 : fretCenterX(fret) - 55
const fretHitboxWidth = (fret: number) => fret === 0 ? 26 : 110
const stringWidth = (string: number) => string === 1 || string === 6 ? 2.8 : 1.6
const markerFrets = [3, 5, 7, 9, 12, 15, 17, 19, 21, 24]

function isCompleted(string: number, fret: number) {
  return props.completedPositions.some(position => position.string === string && position.fret === fret)
}

function isSelected(string: number, fret: number) {
  return props.selected !== null
    && props.selected.string === string
    && props.selected.fret === fret
}

function pick(string: number, fret: number) {
  if (props.disabled || !regionIsValid.value) return
  emit('select', { string, fret, midi: fretMidi(string, fret) })
}

const selectedLabel = computed(() => {
  if (!props.selected) return ''
  const note = midiName(fretMidi(props.selected.string, props.selected.fret))
  return `Cuerda ${props.selected.string} · Traste ${props.selected.fret} · ${note.name}${note.octave}`
})
</script>

<template>
  <div class="w-full overflow-x-auto">
    <p v-if="!regionIsValid" class="rounded-lg bg-amber-50 p-3 text-center text-sm text-amber-800">
      La región del diapasón debe comprender cinco espacios consecutivos entre los trastes 0 y 24.
    </p>
    <template v-else>
      <svg
        viewBox="0 0 650 250"
        class="mx-auto block w-full min-w-[310px] max-w-[620px]"
        role="img"
        :aria-label="`Diapasón interactivo de guitarra, trastes ${startFret} a ${endFret}`"
      >
        <rect x="27" y="17" width="594" height="207" rx="12" fill="#f5ead8" />
        <rect v-if="startFret === 0" x="27" y="17" width="12" height="207" rx="3" fill="#8a6748" />

        <g stroke="#b99b76" stroke-width="2">
          <path
            v-for="fret in frets.filter(value => value > 0)"
            :key="fret"
            :d="`M ${fretWireX(fret)} 18 V 223`"
          />
        </g>

        <g fill="#806b55" font-size="12" text-anchor="middle">
          <text v-for="fret in frets" :key="fret" :x="fretCenterX(fret)" y="12">{{ fret }}</text>
        </g>

        <g v-for="(string, index) in strings" :key="string">
          <path
            :d="`M 27 ${stringY(index)} H 621`"
            stroke="#a6a69c"
            :stroke-width="stringWidth(string)"
          />
          <text x="14" :y="stringY(index) + 4" font-size="11" fill="#68766e" text-anchor="middle">{{ string }}</text>

          <g v-for="fret in frets" :key="fret">
            <circle
              v-if="isSelected(string, fret) || isCompleted(string, fret)"
              :cx="fretCenterX(fret)"
              :cy="stringY(index)"
              r="13"
              :fill="isCompleted(string, fret) ? '#176b5b' : '#c07832'"
              stroke="white"
              stroke-width="2"
            />
            <rect
              :x="fretHitboxX(fret)"
              :y="stringY(index) - 15"
              :width="fretHitboxWidth(fret)"
              height="30"
              fill="transparent"
              class="cursor-pointer"
              @click="pick(string, fret)"
            />
          </g>
        </g>

        <g fill="#8d795f">
          <circle
            v-for="fret in frets.filter(value => markerFrets.includes(value))"
            :key="fret"
            :cx="fretCenterX(fret)"
            cy="129"
            r="4"
          />
        </g>
      </svg>
    </template>
  </div>

  <p v-if="selected && regionIsValid" class="mt-2 text-center text-sm font-bold text-[#176b5b]">
    {{ selectedLabel }}
  </p>
</template>
