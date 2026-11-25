<script setup lang="ts">
import { computed } from 'vue'

const props = defineProps<{ midi: number }>()
const pitchClass = computed(() => ((props.midi % 12) + 12) % 12)
const noteIndex = computed(() => {
  const naturalIndex = [0, 0, 1, 1, 2, 3, 3, 4, 4, 5, 5, 6]
  return naturalIndex[pitchClass.value]
})
const octave = computed(() => Math.floor(props.midi / 12) - 1)
const diatonicStep = computed(() => octave.value * 7 + noteIndex.value)
const y = computed(() => 147 - (diatonicStep.value - 30) * 9)
const isSharp = computed(() => [1, 3, 6, 8, 10].includes(pitchClass.value))
const hasLedgerLine = computed(() => diatonicStep.value <= 28)
</script>

<template>
  <div class="rounded-2xl bg-[#fbfaf6] p-1.5 sm:p-2">
    <svg viewBox="0 0 310 180" class="mx-auto block w-full max-w-[250px]" role="img" aria-label="Nota en pentagrama con clave de sol">
      <g stroke="#89958e" stroke-width="1.3">
        <path v-for="i in 5" :key="i" :d="'M 35 ' + (75 + (i - 1) * 18) + ' H 285'" />
      </g>
      <text x="47" y="139" font-size="70" fill="#176b5b">𝄞</text>
      <path v-if="hasLedgerLine" :d="'M 150 ' + y + ' h 44'" stroke="#68766f" stroke-width="1.4" />
      <text v-if="isSharp" x="145" :y="y + 5" font-size="22" text-anchor="middle" fill="#176b5b">♯</text>
      <ellipse cx="172" :cy="y" rx="9" ry="6.5" fill="#176b5b" :transform="'rotate(-18 172 ' + y + ')'" />
      <path :d="'M 180 ' + y + ' v -43'" stroke="#176b5b" stroke-width="2" />
    </svg>
    <p class="text-center text-xs font-semibold text-[#718078]">Clave de sol · pentagrama</p>
  </div>
</template>
