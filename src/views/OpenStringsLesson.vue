<script setup lang="ts">
import { computed, ref } from 'vue'
import { ArrowLeft, CheckCircle2 } from 'lucide-vue-next'
import { RouterLink } from 'vue-router'
import StaffNote from '../components/StaffNote.vue'
import { midiHz, midiName } from '../engines/music/pitch'
import { playGuitarNote } from '../engines/audio/guitarSound'
import { useProgress } from '../composables/useProgress'

const { complete } = useProgress()
const strings = [
  { number: 1, name: 'Mi', midi: 64, thickness: 1, register: 'Aguda' },
  { number: 2, name: 'Si', midi: 59, thickness: 1.5, register: 'Aguda' },
  { number: 3, name: 'Sol', midi: 55, thickness: 2, register: 'Media' },
  { number: 4, name: 'Re', midi: 50, thickness: 3, register: 'Media' },
  { number: 5, name: 'La', midi: 45, thickness: 4, register: 'Grave' },
  { number: 6, name: 'Mi', midi: 40, thickness: 5, register: 'Grave' },
]
const selected = ref<typeof strings[number] | null>(null)
const selectedString = computed(() => selected.value ?? strings[0])
const visited = ref<number[]>([])
const note = computed(() => midiName(selectedString.value.midi))
const writtenNote = computed(() => midiName(selectedString.value.midi + 12))

function selectString(string: typeof strings[number]) {
  selected.value = string
  if (!visited.value.includes(string.number)) visited.value.push(string.number)
  if (visited.value.length === strings.length) complete(1)
  void playGuitarNote(string.midi, string.number)
}


</script>

<template>
  <div class="page">
    <RouterLink to="/" class="mb-3 inline-flex items-center gap-2 text-xs font-bold text-[#698077]">
      <ArrowLeft :size="15" /> Volver al inicio
    </RouterLink>

    <header class="mb-4">
      <p class="eyebrow">Fundamentos · Nivel 1</p>
      <h1 class="mt-1 text-2xl font-black">Conoce las seis cuerdas</h1>
      <p class="mt-1 max-w-2xl text-sm leading-5 text-[#788780]">
        Explora las cuerdas al aire, escucha sus sonidos y descubre cómo se escriben en el pentagrama.
      </p>
    </header>

    <section class="panel p-3 sm:p-4">
      <div class="mb-3 flex items-center justify-between gap-3">
        <div>
          <p class="eyebrow">Guitarra en afinación estándar</p>
          <h2 class="text-lg font-black">Pulsa una cuerda</h2>
        </div>
        <span class="rounded-full bg-[#eef4ef] px-2.5 py-1 text-[11px] font-bold text-[#426c5b]">{{ visited.length }} / 6 exploradas</span>
      </div>

      <div class="rounded-xl bg-[#f7f4ed] p-3 sm:p-4">
        <div class="mb-2 flex items-center justify-between gap-2 px-1 text-[10px] font-bold uppercase tracking-wider text-[#8a795f]">
          <span>Arriba · 1.ª cuerda · Aguda</span><span>Abajo · 6.ª cuerda · Grave</span>
        </div>
        <p class="mb-3 rounded-lg bg-white/70 px-3 py-2 text-[11px] leading-4 text-[#766d5f]">
          Mira la guitarra como si la inclinaras hacia ti para ver sus cuerdas: la más aguda queda arriba y la más grave abajo.
        </p>
        <div class="space-y-2">
          <button
            v-for="string in strings"
            :key="string.number"
            class="group flex w-full items-center gap-3 rounded-lg px-2 py-2 text-left transition"
            :class="selected?.number === string.number ? 'bg-[#dcebe0] ring-1 ring-[#7ca68d]' : 'hover:bg-white/70'"
            @click="selectString(string)"
          >
            <span class="grid h-8 w-8 shrink-0 place-items-center rounded-full bg-white text-xs font-black text-[#547260]">{{ string.number }}</span>
            <span class="relative flex h-7 flex-1 items-center">
              <span class="block w-full rounded-full bg-gradient-to-b from-[#c9c7bd] via-[#77766f] to-[#e4e0d5]" :style="{ height: string.thickness + 'px' }"></span>
              <span v-if="selected?.number === string.number" class="absolute left-1/2 h-5 w-5 -translate-x-1/2 rounded-full border-2 border-white bg-[#176b5b] shadow"></span>
            </span>
            <span class="w-12 text-right text-sm font-extrabold text-[#456653]">{{ string.name }}</span>
            <span class="grid h-4 w-4 shrink-0 place-items-center">
              <CheckCircle2 v-if="visited.includes(string.number)" :size="16" class="text-[#4c9c7c]" />
            </span>
          </button>
        </div>
        <p class="mt-3 text-center text-[10px] text-[#8b806f]">Vista orientativa: primera cuerda arriba, sexta cuerda abajo</p>
      </div>

      <div class="mt-3 grid gap-3 sm:grid-cols-[minmax(0,0.8fr)_minmax(0,1.2fr)]">
        <div class="flex flex-col items-center justify-center rounded-xl bg-[#f5f8f4] p-3 text-center">
          <p class="text-[10px] font-bold uppercase tracking-wide text-[#718078]">Cuerda {{ selectedString.number }} · Al aire</p>
          <p class="mt-1 text-3xl font-black text-[#176b5b]">{{ note.name }}<sub class="ml-0.5 text-base">{{ note.octave }}</sub></p>
          <p class="mt-1 text-xs text-[#75827b]">{{ midiHz(selectedString.midi).toFixed(1) }} Hz · Sonido real</p>
        </div>
        <div class="rounded-xl bg-[#f5f8f4] p-2">
          <p class="mb-1 text-center text-[10px] font-bold uppercase tracking-wide text-[#718078]">Así se escribe para guitarra</p>
          <StaffNote :midi="selectedString.midi + 12" />
          <p class="mt-1 text-center text-[11px] font-semibold text-[#176b5b]">
            {{ writtenNote.name }}{{ writtenNote.octave }} · escritura una octava arriba
          </p>
        </div>
      </div>
    </section>

    <div class="mt-3 grid gap-2 sm:grid-cols-2">
      <div class="rounded-xl bg-[#edf4ee] p-3 text-xs leading-5 text-[#567267]">
        <b>¿Por qué hay dos cuerdas Mi?</b>
        La sexta y la primera tienen el mismo nombre, pero la primera suena dos octavas más aguda.
      </div>
      <div class="rounded-xl bg-[#edf4ee] p-3 text-xs leading-5 text-[#567267]">
        <b>¿Qué ocurre al pisar un traste?</b>
        Cada traste sube la nota un semitono. Por ejemplo, Mi pasa a Fa en el primer traste.
      </div>
    </div>

    <div v-if="visited.length === 6" class="mt-3 flex items-center gap-2 rounded-xl bg-[#e9f5ed] p-3 text-sm font-semibold text-[#226447]">
      <CheckCircle2 :size="19" />
      ¡Has explorado las seis cuerdas! Ya conoces sus notas al aire.
    </div>
  </div>
</template>
