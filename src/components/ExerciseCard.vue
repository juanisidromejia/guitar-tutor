<script setup lang="ts">
import { computed, ref } from 'vue'
import { ArrowRight, CheckCircle2, Volume2, XCircle } from 'lucide-vue-next'
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

const name = computed(() => midiName(target.value))

function next() {
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
    complete(2)
  }
}

async function play() {
  const AudioContextClass = window.AudioContext
  if (!AudioContextClass) return

  const context = new AudioContextClass()
  if (context.state === 'suspended') await context.resume()

  const now = context.currentTime
  const duration = 2.4
  const fundamental = midiHz(target.value)
  const master = context.createGain()
  master.gain.setValueAtTime(0.0001, now)
  master.gain.linearRampToValueAtTime(0.18, now + 0.018)
  master.gain.exponentialRampToValueAtTime(0.0001, now + duration)
  master.connect(context.destination)

  // Suma de armónicos con decaimiento: una cuerda pulsada suena más
  // natural que un oscilador sinusoidal aislado.
  for (let harmonic = 1; harmonic <= 9; harmonic++) {
    const oscillator = context.createOscillator()
    const partialGain = context.createGain()
    const amplitude = 1 / Math.pow(harmonic, 1.35)
    const partialDuration = duration / (1 + (harmonic - 1) * 0.14)

    oscillator.type = 'sine'
    oscillator.frequency.value = fundamental * harmonic
    partialGain.gain.setValueAtTime(amplitude, now)
    partialGain.gain.exponentialRampToValueAtTime(0.0001, now + partialDuration)
    oscillator.connect(partialGain)
    partialGain.connect(master)
    oscillator.start(now)
    oscillator.stop(now + duration)
  }

  window.setTimeout(() => void context.close(), (duration + 0.15) * 1000)
}
</script>

<template>
  <section class="panel p-3 sm:p-4">
    <div class="flex justify-between gap-2">
      <div>
        <p class="eyebrow">Reto de notas · Nivel 1</p>
        <h2 class="mt-0.5 text-xl font-black">Encuentra la nota</h2>
        <p class="mt-0.5 text-xs text-[#788780]">Escucha y localiza la nota en el diapasón.</p>
      </div>
      <span class="rounded-full bg-[#eef4ef] px-2.5 py-1 text-[11px] font-bold text-[#426c5b]">Ronda {{ round }}</span>
    </div>

    <div class="my-2 flex items-center justify-center gap-3 rounded-xl bg-[#f5f8f4] p-2 sm:p-3">
      <div class="text-center">
        <p class="text-[10px] font-bold uppercase text-[#718078]">Busca esta nota</p>
        <p class="mt-0.5 text-2xl font-black text-[#176b5b]">{{ name.name }}</p>
        <p class="text-xs text-[#75827b]">Octava {{ name.octave }}</p>
      </div>
      <button class="secondary flex items-center gap-2" @click="play">
        <Volume2 :size="19" /> Escuchar
      </button>
    </div>

    <GuitarFretboard :selected="selected" :disabled="answered" @select="choose" />

    <p class="mt-2 text-center text-xs text-[#788780]">
      Toca directamente la cuerda y el traste que corresponden a la nota.
    </p>

    <div v-if="selected && !correct" class="mt-2 flex items-center gap-2 rounded-lg bg-[#fff1e9] p-2.5 text-[#a14f2d]">
      <XCircle />
      <p class="flex-1 text-sm font-semibold">Todavía no. Prueba otra posición.</p>
    </div>
    <div v-if="correct" class="mt-2 flex items-center gap-2 rounded-lg bg-[#e9f5ed] p-2.5 text-[#226447]">
      <CheckCircle2 />
      <div class="flex-1">
        <p class="text-xs font-semibold">¡Muy bien! Has encontrado la nota.</p>
        <p class="mt-0.5 text-[11px]">Cuando estés listo, continúa con el siguiente reto.</p>
      </div>
      <button class="primary flex shrink-0 items-center gap-2" @click="next">
        Continuar <ArrowRight :size="17" />
      </button>
    </div>
  </section>
</template>
