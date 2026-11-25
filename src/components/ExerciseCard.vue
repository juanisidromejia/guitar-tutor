<script setup lang="ts">
import { computed, onBeforeUnmount, ref } from 'vue'
import { CheckCircle2, Volume2, XCircle } from 'lucide-vue-next'
import GuitarFretboard from './GuitarFretboard.vue'
import { fretMidi } from '../engines/guitar/fretboard'
import { midiName, midiHz } from '../engines/music/pitch'
import { useProgress } from '../composables/useProgress'

const { record, complete } = useProgress()
const pool = [40, 42, 45, 47, 50, 52, 55, 57, 59, 60, 62, 64, 65, 67, 69]
const round = ref(1)
const target = ref(52)
const selected = ref<{ string: number; fret: number } | null>(null)
const answered = ref(false)
const correct = ref(false)
let advanceTimer: ReturnType<typeof setTimeout> | undefined

const name = computed(() => midiName(target.value))

function next() {
  if (advanceTimer) clearTimeout(advanceTimer)
  round.value++
  target.value = pool[(round.value * 7 + 3) % pool.length]
  selected.value = null
  answered.value = false
  correct.value = false
}

function choose(position: { string: number; fret: number; midi: number }) {
  if (answered.value) return
  selected.value = position
  correct.value = fretMidi(position.string, position.fret) === target.value
  record(correct.value)

  if (correct.value) {
    answered.value = true
    complete(1)
    advanceTimer = setTimeout(next, 1100)
  }
}

function play() {
  const context = new AudioContext()
  const oscillator = context.createOscillator()
  const gain = context.createGain()
  oscillator.frequency.value = midiHz(target.value)
  oscillator.type = 'sine'
  gain.gain.setValueAtTime(0.14, context.currentTime)
  gain.gain.exponentialRampToValueAtTime(0.001, context.currentTime + 1)
  oscillator.connect(gain)
  gain.connect(context.destination)
  oscillator.start()
  oscillator.stop(context.currentTime + 1)
  oscillator.onended = () => context.close()
}

onBeforeUnmount(() => {
  if (advanceTimer) clearTimeout(advanceTimer)
})
</script>

<template>
  <section class="panel p-5 sm:p-7">
    <div class="flex justify-between gap-3">
      <div>
        <p class="eyebrow">Reto de notas · Nivel 1</p>
        <h2 class="mt-1 text-2xl font-black">Encuentra la nota</h2>
        <p class="mt-1 text-sm text-[#788780]">Escucha y localiza la nota en el diapasón.</p>
      </div>
      <span class="rounded-full bg-[#eef4ef] px-3 py-1.5 text-xs font-bold text-[#426c5b]">Ronda {{ round }}</span>
    </div>

    <div class="my-6 flex items-center justify-center gap-4 rounded-2xl bg-[#f5f8f4] p-5">
      <div class="text-center">
        <p class="text-xs font-bold uppercase text-[#718078]">Busca esta nota</p>
        <p class="mt-1 text-4xl font-black text-[#176b5b]">{{ name.name }}</p>
        <p class="text-sm text-[#75827b]">Octava {{ name.octave }}</p>
      </div>
      <button class="secondary flex items-center gap-2" @click="play">
        <Volume2 :size="19" /> Escuchar
      </button>
    </div>

    <GuitarFretboard :selected="selected" :disabled="answered" @select="choose" />

    <p class="mt-5 text-center text-sm text-[#788780]">
      Toca directamente la cuerda y el traste que corresponden a la nota.
    </p>

    <div v-if="selected && !correct" class="mt-4 flex items-center gap-3 rounded-xl bg-[#fff1e9] p-4 text-[#a14f2d]">
      <XCircle />
      <p class="flex-1 text-sm font-semibold">Todavía no. Prueba otra posición.</p>
    </div>
    <div v-if="correct" class="mt-4 flex items-center gap-3 rounded-xl bg-[#e9f5ed] p-4 text-[#226447]">
      <CheckCircle2 />
      <p class="text-sm font-semibold">¡Muy bien! Nota encontrada. Vamos con la siguiente…</p>
    </div>
  </section>
</template>
