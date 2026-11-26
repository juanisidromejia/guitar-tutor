<script setup lang="ts">
import { computed, ref } from 'vue'
import { ArrowLeft, ArrowRight, CheckCircle2, Volume2, XCircle } from 'lucide-vue-next'
import { RouterLink } from 'vue-router'
import GuitarFretboard from '../components/GuitarFretboard.vue'
import StaffNote from '../components/StaffNote.vue'
import { fretMidi } from '../engines/guitar/fretboard'
import { midiName } from '../engines/music/pitch'
import { playGuitarNote } from '../engines/audio/guitarSound'
import { useProgress } from '../composables/useProgress'

const { record, complete } = useProgress()
const phrase = [60, 62, 64, 67]
const labels = ['Do', 'Re', 'Mi', 'Sol']
const index = ref(0)
const selected = ref<{ string: number; fret: number } | null>(null)
const feedback = ref<'correct' | 'wrong' | null>(null)
const finished = ref(false)
const target = computed(() => phrase[index.value] ?? phrase[phrase.length - 1])
const targetName = computed(() => midiName(target.value))

function choose(position: { string: number; fret: number; midi: number }) {
  if (feedback.value === 'correct' || finished.value) return
  selected.value = position
  void playGuitarNote(position.midi, position.string)
  const ok = fretMidi(position.string, position.fret) === target.value - 12
  record(ok)
  feedback.value = ok ? 'correct' : 'wrong'
}

function next() {
  if (index.value === phrase.length - 1) {
    finished.value = true
    complete(4)
    return
  }
  index.value++
  selected.value = null
  feedback.value = null
}

function restart() {
  index.value = 0
  selected.value = null
  feedback.value = null
  finished.value = false
}


</script>

<template>
  <div class="page">
    <RouterLink to="/" class="mb-3 inline-flex items-center gap-2 text-xs font-bold text-[#698077]">
      <ArrowLeft :size="15" /> Volver al inicio
    </RouterLink>
    <header class="mb-4">
      <p class="eyebrow">Lectura e interpretación · Nivel 1</p>
      <h1 class="mt-1 text-2xl font-black">Del papel a la guitarra</h1>
      <p class="mt-1 max-w-2xl text-sm leading-5 text-[#788780]">
        Lee una pequeña melodía y toca sus notas en orden. Cada acierto te permite avanzar por la frase.
      </p>
    </header>

    <section class="panel p-3 sm:p-4">
      <div class="mb-3 flex items-center justify-between gap-3">
        <div>
          <p class="eyebrow">Frase 1 · Cuatro notas</p>
          <h2 class="text-lg font-black">Pequeña melodía en Do mayor</h2>
        </div>
        <span class="rounded-full bg-[#eef4ef] px-2.5 py-1 text-[11px] font-bold text-[#426c5b]">{{ finished ? 'Completada' : 'Nota ' + (index + 1) + ' de 4' }}</span>
      </div>

      <div class="mb-3 grid grid-cols-4 gap-2">
        <div v-for="(midi, i) in phrase" :key="midi" class="rounded-lg p-2 text-center" :class="i < index || finished ? 'bg-[#e9f5ed] text-[#226447]' : i === index ? 'bg-[#dcebe0] text-[#176b5b] ring-1 ring-[#7ca68d]' : 'bg-[#f3f5f1] text-[#829087]'">
          <CheckCircle2 v-if="i < index || finished" :size="15" class="mx-auto mb-1" />
          <span class="mx-auto mb-1 block h-3.5 w-3.5 rounded-full bg-current opacity-50"></span>
          <p class="text-xs font-extrabold">{{ labels[i] }}</p>
        </div>
      </div>

      <div v-if="!finished" class="grid grid-cols-1 items-center gap-3 lg:grid-cols-[minmax(230px,0.75fr)_minmax(0,1.5fr)] lg:gap-5">
        <div class="rounded-xl bg-[#f5f8f4] p-2">
          <p class="mb-1 text-center text-[10px] font-bold uppercase tracking-wide text-[#718078]">Lee esta nota</p>
          <StaffNote :midi="target" />
          <p class="mt-1 text-center text-sm font-black text-[#176b5b]">{{ targetName.name }}{{ targetName.octave }}</p>
          <button class="secondary mx-auto mt-2 flex items-center gap-2" @click="playGuitarNote(target - 12)">
            <Volume2 :size="16" /> Escuchar nota
          </button>
        </div>
        <div class="min-w-0">
          <div class="mb-1 flex items-center justify-between gap-2">
            <h3 class="text-sm font-extrabold">Encuentra dónde tocarla</h3>
            <span class="text-[10px] text-[#829087]">Trastes 0–5</span>
          </div>
          <GuitarFretboard :selected="selected" :disabled="feedback === 'correct'" @select="choose" />
        </div>
      </div>

      <div v-if="feedback === 'wrong' && !finished" class="mt-3 flex items-center gap-2 rounded-lg bg-[#fff1e9] p-2.5 text-[#a14f2d]">
        <XCircle :size="18" />
        <p class="text-xs font-semibold">Esa posición produce otra nota. Inténtalo de nuevo.</p>
      </div>
      <div v-else-if="feedback === 'correct' && !finished" class="mt-3 flex items-center gap-2 rounded-lg bg-[#e9f5ed] p-2.5 text-[#226447]">
        <CheckCircle2 :size="18" />
        <p class="flex-1 text-xs font-semibold">¡Correcto! Has encontrado {{ labels[index] }}. Continúa con la siguiente nota.</p>
        <button class="primary flex shrink-0 items-center gap-1.5 px-3 py-2 text-xs" @click="next">
          {{ index === phrase.length - 1 ? 'Terminar frase' : 'Continuar' }} <ArrowRight :size="15" />
        </button>
      </div>
      <p v-else-if="!finished" class="mt-2 text-center text-xs text-[#788780]">
        Toca la cuerda y el traste que producen la nota escrita. La guitarra suena una octava más grave.
      </p>

      <div v-if="finished" class="rounded-xl bg-[#e9f5ed] p-4 text-center text-[#226447]">
        <CheckCircle2 :size="30" class="mx-auto" />
        <h3 class="mt-2 text-lg font-black">¡Frase completada!</h3>
        <p class="mt-1 text-sm">Has leído y localizado las cuatro notas en la guitarra, respetando su orden.</p>
        <button class="primary mx-auto mt-3 flex items-center gap-2" @click="restart">Repetir ejercicio</button>
      </div>
    </section>
    <div class="mt-3 rounded-xl bg-[#edf4ee] p-3 text-xs leading-5 text-[#567267]">
      <b>Objetivo:</b> pasar de la lectura de notas aisladas a una secuencia musical. En esta primera versión trabajamos cuatro notas naturales y su ubicación; las figuras rítmicas y la interpretación de frases más largas se incorporarán en niveles posteriores.
    </div>
  </div>
</template>
