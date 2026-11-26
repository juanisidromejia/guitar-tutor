<script setup lang="ts">
import { ArrowRight, CheckCircle2, Music2, Sparkles } from 'lucide-vue-next'
import { RouterLink } from 'vue-router'
import { useProgress } from '../composables/useProgress'

const { data, accuracy } = useProgress()

const modules = [
  { id: '01', title: 'Las seis cuerdas', description: 'Explora las cuerdas al aire, sus sonidos, octavas y escritura en el pentagrama.', tag: 'Fundamentos', to: '/fundamentos', progressId: 1 },
  { id: '02', title: 'Notas en el diapasón', description: 'Encuentra notas en distintas cuerdas y posiciones del mástil.', tag: 'Orientación en el instrumento', to: '/practicar', progressId: 2 },
  { id: '03', title: 'Notas en el pentagrama', description: 'Lee notas en clave de sol y localízalas en la guitarra.', tag: 'Lectura musical', to: '/notas-pentagrama', progressId: 3 },
  { id: '04', title: 'Del papel a la guitarra', description: 'Lee pequeñas frases musicales y tócalas en el instrumento.', tag: 'Lectura e interpretación', to: '/del-papel-a-la-guitarra', progressId: 4 },
]
</script>

<template>
  <div class="page">
    <section class="relative overflow-hidden rounded-[28px] bg-[#173f36] px-6 py-9 text-white sm:px-10 sm:py-12">
      <div class="relative z-10 max-w-[590px]">
        <p class="text-xs font-extrabold uppercase tracking-[.18em] text-[#a6d6bf]">Tu aventura musical comienza aquí</p>
        <h1 class="mt-3 text-4xl font-black leading-tight sm:text-5xl">Aprende guitarra.<br><span class="text-[#9dd9b7]">Lee música.</span></h1>
        <p class="mt-4 max-w-[470px] text-[15px] leading-7 text-[#d3e3da]">Conoce tu instrumento, descubre las notas y aprende a transformar la lectura musical en interpretación.</p>
        <RouterLink to="/fundamentos" class="mt-7 inline-flex items-center gap-2 rounded-xl bg-[#b6e5c7] px-5 py-3 font-extrabold text-[#174638]">Comenzar a aprender <ArrowRight :size="18"/></RouterLink>
      </div>
      <Music2 class="pointer-events-none absolute bottom-5 right-12 hidden text-[#9dd9b7]/20 sm:block" :size="170" :stroke-width="1"/>
    </section>

    <section class="mt-7 grid gap-4 sm:grid-cols-3">
      <div class="panel p-5">
        <p class="text-xs font-bold uppercase text-[#829087]">Lecciones completadas</p>
        <p class="mt-2 text-3xl font-black">{{data.completed.length}}<span class="ml-1 text-sm text-[#89958e]">/ 4</span></p>
        <div class="mt-3 h-2 overflow-hidden rounded-full bg-[#edf1ec]"><div class="h-full rounded-full bg-[#4c9c7c]" :style="{width:data.completed.length/4*100+'%'}"/></div>
      </div>
      <div class="panel p-5">
        <p class="text-xs font-bold uppercase text-[#829087]">Precisión</p>
        <p class="mt-2 text-3xl font-black">{{accuracy}}%</p>
        <p class="mt-2 text-xs text-[#89958e]">En tus ejercicios evaluados</p>
      </div>
      <div class="panel flex items-center gap-3 p-5">
        <span class="grid h-11 w-11 place-items-center rounded-2xl bg-[#edf5ee] text-[#34795d]"><Sparkles/></span>
        <div><p class="font-extrabold">¡Sigue avanzando!</p><p class="mt-1 text-xs text-[#829087]">Un poco de práctica cada día.</p></div>
      </div>
    </section>

    <section class="mt-9">
      <div class="mb-4"><p class="eyebrow">Tu camino musical</p><h2 class="mt-1 text-2xl font-black">Ruta de aprendizaje</h2></div>
      <div class="grid gap-3 sm:grid-cols-2">
        <RouterLink v-for="module in modules" :key="module.id" :to="module.to" class="panel group flex gap-4 p-4 transition hover:-translate-y-0.5 hover:shadow-md focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-[#176b5b] sm:p-5">
          <span class="grid h-11 w-11 shrink-0 place-items-center rounded-2xl bg-[#edf4ee] text-base font-black text-[#39765c]">{{module.id}}</span>
          <div class="min-w-0 flex-1">
            <div class="flex items-center gap-2">
              <h3 class="font-extrabold">{{module.title}}</h3>
              <CheckCircle2 v-if="data.completed.includes(module.progressId)" class="shrink-0 text-[#4c9c7c]" :size="16"/>
            </div>
            <p class="mt-1 text-sm leading-5 text-[#7b8981]">{{module.description}}</p>
            <span class="mt-3 inline-block text-[10px] font-bold uppercase tracking-wider text-[#5b8b73]">{{module.tag}}</span>
          </div>
          <ArrowRight class="self-center shrink-0 text-[#4a8068] transition-transform group-hover:translate-x-1" :size="20" />
        </RouterLink>
      </div>
    </section>
  </div>
</template>
