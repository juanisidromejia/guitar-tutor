<script setup lang="ts">
import { Lightbulb } from 'lucide-vue-next'
import ExerciseCard from '../components/ExerciseCard.vue'
</script>

<template>
  <div class="page">
    <div class="mb-4">
      <p class="eyebrow">Módulo 02 · Orientación en el instrumento</p>
      <h1 class="mt-1 text-2xl font-black">Notas en el diapasón</h1>
      <p class="mt-1 max-w-2xl text-sm leading-5 text-[#788780]">Encuentra en el mástil la nota que escuchas o que aparece indicada. Explora distintas cuerdas y posiciones.</p>
    </div>
    <ExerciseCard/>
    <div class="mt-3 flex gap-3 rounded-xl bg-[#edf4ee] p-3 text-xs leading-5 text-[#567267]"><Lightbulb class="shrink-0"/><p><b>Recuerda:</b> cada traste aumenta la nota un semitono. Una misma nota puede aparecer en más de una cuerda y posición.</p></div>
  </div>
</template>
