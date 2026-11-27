<script setup lang="ts">
import { computed } from 'vue'
import { midiToNote, noteToMidi } from '../engines/music/musicTheory'
import type { SpelledNote } from '../engines/music/musicTheory'

const props = defineProps<{
  /** Altura sonora en MIDI. Se conserva como propiedad principal por compatibilidad. */
  midi: number
  /** Grafía musical opcional. Permite distinguir, por ejemplo, Do♯ de Re♭. */
  spelling?: SpelledNote
  /** Controla el signo visible cuando una alteración ya está vigente en el compás. */
  accidentalDisplay?: 'auto' | 'sharp' | 'flat' | 'natural' | 'none'
}>()

const note = computed(() =>
  props.spelling && noteToMidi(props.spelling) === props.midi
    ? props.spelling
    : midiToNote(props.midi),
)
const letterIndex = computed(() => ['Do', 'Re', 'Mi', 'Fa', 'Sol', 'La', 'Si'].indexOf(note.value.letter))
const diatonicStep = computed(() => note.value.octave * 7 + letterIndex.value)
const y = computed(() => 147 - (diatonicStep.value - 30) * 9)
const accidentalSymbol = computed(() => {
  if (props.accidentalDisplay === 'none') return ''
  if (props.accidentalDisplay === 'sharp') return '♯'
  if (props.accidentalDisplay === 'flat') return '♭'
  if (props.accidentalDisplay === 'natural') return '♮'
  switch (note.value.accidental) {
    case 1: return '♯'
    case -1: return '♭'
    case 2: return '𝄪'
    case -2: return '𝄫'
    default: return ''
  }
})
const ledgerLines = computed(() => {
  const lines: number[] = []
  // Líneas adicionales por debajo del pentagrama, desde Do4.
  if (diatonicStep.value <= 28) {
    for (let step = 28; step >= diatonicStep.value; step -= 2) {
      lines.push(147 + (30 - step) * 9)
    }
  }
  // Líneas adicionales por encima del pentagrama, desde La5.
  if (diatonicStep.value >= 40) {
    for (let step = 40; step <= diatonicStep.value; step += 2) {
      lines.push(75 - (step - 38) * 9)
    }
  }
  return lines
})
</script>

<template>
  <div class="rounded-2xl bg-[#fbfaf6] p-1.5 sm:p-2">
    <svg
      viewBox="0 0 310 240"
      class="mx-auto block w-full max-w-[250px]"
      role="img"
      :aria-label="`Nota ${note.letter}${accidentalSymbol}${note.octave} en pentagrama con clave de sol`"
    >
      <g stroke="#89958e" stroke-width="1.3">
        <path v-for="i in 5" :key="i" :d="'M 35 ' + (75 + (i - 1) * 18) + ' H 285'" />
      </g>
      <text x="47" y="139" font-size="70" fill="#176b5b">𝄞</text>
      <path
        v-for="lineY in ledgerLines"
        :key="lineY"
        :d="'M 150 ' + lineY + ' h 44'"
        stroke="#68766f"
        stroke-width="1.4"
      />
      <text
        v-if="accidentalSymbol"
        x="145"
        :y="y + 5"
        font-size="22"
        text-anchor="middle"
        fill="#176b5b"
      >{{ accidentalSymbol }}</text>
      <ellipse cx="172" :cy="y" rx="9" ry="6.5" fill="#176b5b" :transform="'rotate(-18 172 ' + y + ')'" />
      <path :d="'M 180 ' + y + ' v -43'" stroke="#176b5b" stroke-width="2" />
    </svg>
    <p class="text-center text-xs font-semibold text-[#718078]">Clave de sol · pentagrama</p>
  </div>
</template>
