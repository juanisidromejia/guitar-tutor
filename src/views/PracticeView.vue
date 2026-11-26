<script setup lang="ts">
import { ArrowLeft, Lightbulb, Guitar } from 'lucide-vue-next'
import { RouterLink } from 'vue-router'
import ExerciseCard from '../components/ExerciseCard.vue'
</script>

<template>
  <div class="page">
    <RouterLink to="/" class="mb-4 inline-flex items-center gap-2 text-sm font-bold text-[#698077]"><ArrowLeft :size="17"/>Volver al inicio</RouterLink>
    <div class="mb-4">
      <p class="eyebrow">Módulo 02 · Orientación en el instrumento</p>
      <h1 class="mt-1 text-2xl font-black">Notas en el diapasón</h1>
      <p class="mt-1 max-w-2xl text-sm leading-5 text-[#788780]">Encuentra en el mástil la nota que escuchas o que aparece indicada. Explora distintas cuerdas y posiciones.</p>
    </div>
    <ExerciseCard/>
    <div class="mt-3 flex gap-3 rounded-xl bg-[#edf4ee] p-3 text-xs leading-5 text-[#567267]"><Lightbulb class="shrink-0"/><p><b>Recuerda:</b> cada traste aumenta la nota un semitono. Una misma nota puede aparecer en más de una cuerda y posición.</p></div>
    <div class="panel mt-3 p-4">
      <div class="flex items-center gap-3"><Guitar class="text-[#43836a]"/><h2 class="font-extrabold">Afinación estándar</h2></div>
      <p class="mt-1 text-sm text-[#788780]">De la sexta cuerda (la más gruesa) a la primera: Mi – La – Re – Sol – Si – Mi.</p>
    </div>
  </div>
</template>
