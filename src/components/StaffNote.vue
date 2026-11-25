<script setup lang="ts">
import { computed } from 'vue'

const props = defineProps<{ midi: number }>()
const pitchClass = computed(() => ((props.midi % 12) + 12) % 12)

const step = computed(() => {
  const diatonicSteps = [0, 0, 1, 1, 2, 3, 3, 4, 4, 5, 5, 6]
  return Math.floor(props.midi / 12) * 7 + diatonicSteps[pitchClass.value]
})

const y = computed(() => 150 - (step.value - 35) * 7.5)
</script>

<template><div class="rounded-2xl bg-[#fbfaf6] p-4"><svg viewBox="0 0 310 180" class="mx-auto block w-full max-w-[360px]" role="img" aria-label="Pentagrama en clave de sol"><g stroke="#89958e" stroke-width="1.3"><path v-for="i in 5" :key="i" :d="'M 35 '+(75+(i-1)*18)+' H 285'"/></g><text x="42" y="137" font-size="70" fill="#176b5b">𝄞</text><path v-if="y>=150||y<=75" :d="'M 150 '+y+' h 44'" stroke="#68766f" stroke-width="1.4"/><ellipse cx="172" :cy="y" rx="9" ry="6.5" fill="#176b5b" transform="rotate(-18 172 150)"/><path :d="'M 180 '+y+' v -43'" stroke="#176b5b" stroke-width="2"/></svg><p class="text-center text-xs font-semibold text-[#718078]">Clave de sol · referencia visual</p></div></template>