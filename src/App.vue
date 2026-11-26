<script setup lang="ts">
import { BookOpen, ClipboardCheck, Guitar, Home, Music2, Users } from 'lucide-vue-next'
import { RouterLink, RouterView } from 'vue-router'
</script>
<template>
  <div class="min-h-screen">
    <header class="sticky top-0 z-30 border-b border-[#e6ebe5] bg-[#f7f8f5]/95 backdrop-blur">
      <div class="mx-auto flex h-[66px] max-w-[1100px] items-center justify-between px-5">
        <RouterLink to="/" class="flex items-center gap-3"><span class="grid h-10 w-10 place-items-center rounded-[14px] bg-[#176b5b] text-white"><Guitar /></span><b class="text-xl tracking-tight">guitar<span class="text-[#278a72]">tutor</span></b></RouterLink>
        <nav class="hidden sm:flex">
          <RouterLink class="nav" to="/"><Home :size="17" />Inicio</RouterLink><RouterLink class="nav" to="/practicar"><Guitar :size="17" />Practicar</RouterLink><RouterLink class="nav" to="/partitura"><Music2 :size="17" />Partituras</RouterLink><RouterLink class="nav" to="/evaluacion"><ClipboardCheck :size="17" />Evaluaciones</RouterLink><RouterLink class="nav" to="/docente/sesiones"><Users :size="17"/>Docentes</RouterLink>
        </nav>
        <span class="rounded-full bg-[#e8f1eb] px-3 py-1.5 text-xs font-bold text-[#286451]">Mi aprendizaje</span>
      </div>
    </header>
    <main><RouterView /></main>
    <nav class="fixed inset-x-0 bottom-0 z-40 flex justify-around border-t border-[#e4e9e3] bg-white/95 px-3 py-2 pb-[max(9px,env(safe-area-inset-bottom))] backdrop-blur sm:hidden">
      <RouterLink to="/" class="nav flex-col gap-1 text-xs"><Home :size="19" />Inicio</RouterLink><RouterLink to="/practicar" class="nav flex-col gap-1 text-xs"><Guitar :size="19" />Practicar</RouterLink><RouterLink to="/partitura" class="nav flex-col gap-1 text-xs"><BookOpen :size="19" />Partituras</RouterLink><RouterLink to="/evaluacion" class="nav flex-col gap-1 text-xs"><ClipboardCheck :size="19" />Pruebas</RouterLink><RouterLink to="/docente/sesiones" class="nav flex-col gap-1 text-xs"><Users :size="19"/>Docentes</RouterLink>
    </nav>
  </div>
</template>
