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
    disabled?: boolean
  }>(),
  { selected: null, disabled: false },
)

const emit = defineEmits<{
  (event: 'select', position: FretPosition): void
}>()

const strings = [1, 2, 3, 4, 5, 6]
const frets = [0, 1, 2, 3, 4, 5]

const stringY = (index: number) => 35 + index * 35
const fretX = (fret: number) => (fret === 0 ? 38 : 38 + fret * 112)
const fretCenterX = (fret: number) => (fret === 0 ? 38 : fretX(fret) - 56)
const fretHitboxX = (fret: number) => (fret === 0 ? 25 : fretX(fret) - 105)
const fretHitboxWidth = (fret: number) => (fret === 0 ? 26 : 110)
const stringWidth = (string: number) => (string === 1 || string === 6 ? 2.8 : 1.6)

function isSelected(string: number, fret: number) {
  return props.selected !== null &&
    props.selected.string === string &&
    props.selected.fret === fret
}

function pick(string: number, fret: number) {
  if (props.disabled) return
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
    <svg
      viewBox="0 0 650 250"
      class="mx-auto block w-full min-w-[310px] max-w-[780px]"
      role="img"
      aria-label="Diapasón interactivo de guitarra"
    >
      <rect x="27" y="17" width="594" height="207" rx="12" fill="#f5ead8" />
      <rect x="27" y="17" width="12" height="207" rx="3" fill="#8a6748" />

      <g stroke="#b99b76" stroke-width="2">
        <path
          v-for="fret in frets.slice(1)"
          :key="fret"
          :d="'M ' + fretX(fret) + ' 18 V 223'"
        />
      </g>

      <g fill="#806b55" font-size="12" text-anchor="middle">
        <text
          v-for="fret in frets"
          :key="fret"
          :x="fretCenterX(fret)"
          y="12"
        >{{ fret }}</text>
      </g>

      <g v-for="(string, index) in strings" :key="string">
        <path
          :d="'M 27 ' + stringY(index) + ' H 621'"
          stroke="#a6a69c"
          :stroke-width="stringWidth(string)"
        />
        <text
          x="14"
          :y="stringY(index) + 4"
          font-size="11"
          fill="#68766e"
          text-anchor="middle"
        >{{ string }}</text>

        <g v-for="fret in frets" :key="fret">
          <circle
            v-if="isSelected(string, fret)"
            :cx="fretCenterX(fret)"
            :cy="stringY(index)"
            r="13"
            fill="#176b5b"
            stroke="white"
            stroke-width="2"
          />
          <rect
            :x="fretHitboxX(fret)"
            :y="stringY(index) - 15"
            :width="fretHitboxWidth(fret)"
            height="30"
            fill="transparent"
            @click="pick(string, fret)"
          />
        </g>
      </g>

      <g fill="#8d795f">
        <circle cx="542" cy="129" r="4" />
      </g>
    </svg>
  </div>

  <p
    v-if="selected"
    class="mt-2 text-center text-sm font-bold text-[#176b5b]"
  >{{ selectedLabel }}</p>
</template>
