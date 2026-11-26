<script setup lang="ts">
import { computed, onUnmounted, ref } from 'vue'
import { ArrowLeft, CheckCircle2, Volume2 } from 'lucide-vue-next'
import { RouterLink } from 'vue-router'
import StaffNote from '../components/StaffNote.vue'
import { midiHz, midiName } from '../engines/music/pitch'
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
const selected = ref(strings[0])
const visited = ref<number[]>([])
const note = computed(() => midiName(selected.value.midi))
const writtenNote = computed(() => midiName(selected.value.midi + 12))

let audioContext: AudioContext | null = null

function selectString(string: typeof strings[number]) {
  selected.value = string
  if (!visited.value.includes(string.number)) visited.value.push(string.number)
  if (visited.value.length === strings.length) complete(1)
}

// Síntesis de cuerda pulsada (Karplus–Strong), con transitorio de púa
// y resonancias suaves que evocan el cuerpo de una guitarra acústica.
function createRoomImpulse(context: AudioContext, duration = 0.72) {
  const sampleRate = context.sampleRate
  const frameCount = Math.floor(sampleRate * duration)
  const impulse = context.createBuffer(2, frameCount, sampleRate)

  for (let channel = 0; channel < impulse.numberOfChannels; channel++) {
    const samples = impulse.getChannelData(channel)
    for (let i = 0; i < frameCount; i++) {
      const decay = Math.pow(1 - i / frameCount, 2.8)
      samples[i] = (Math.random() * 2 - 1) * decay
    }
  }

  return impulse
}

function createPluckedStringBuffer(context: AudioContext, frequency: number, stringNumber: number) {
  const duration = 1.8
  const sampleRate = context.sampleRate
  const frameCount = Math.floor(sampleRate * duration)
  const buffer = context.createBuffer(1, frameCount, sampleRate)
  const samples = buffer.getChannelData(0)
  const delayLength = Math.max(2, Math.round(sampleRate / frequency))
  const delay = new Float32Array(delayLength)
  const pickPosition = 0.18 + stringNumber * 0.012

  // Excitación inicial con un pequeño filtrado según el punto de pulsación.
  for (let i = 0; i < delayLength; i++) {
    const pluckShape = Math.sin(Math.PI * (i / delayLength + pickPosition))
    delay[i] = (Math.random() * 2 - 1) * pluckShape
  }

  let index = 0
  const damping = 0.9961 + (stringNumber - 1) * 0.00013

  for (let i = 0; i < frameCount; i++) {
    const next = (index + 1) % delayLength
    const filtered = (delay[index] + delay[next]) * 0.5 * damping
    delay[index] = filtered
    samples[i] = filtered
    index = next
  }

  return buffer
}

async function play() {
  const AudioContextClass = window.AudioContext
  if (!AudioContextClass) return

  audioContext ??= new AudioContextClass()
  if (audioContext.state === 'suspended') await audioContext.resume()

  const context = audioContext
  const now = context.currentTime
  const duration = 1.8
  const frequency = midiHz(selected.value.midi)
  const source = context.createBufferSource()
  const bodyFilter = context.createBiquadFilter()
  const toneFilter = context.createBiquadFilter()
  const lowShelf = context.createBiquadFilter()
  const convolver = context.createConvolver()
  const dryGain = context.createGain()
  const wetGain = context.createGain()
  const envelope = context.createGain()

  source.buffer = createPluckedStringBuffer(context, frequency, selected.value.number)
  toneFilter.type = 'lowpass'
  toneFilter.frequency.value = selected.value.number >= 4 ? 4200 : 6200
  toneFilter.Q.value = 0.55
  bodyFilter.type = 'peaking'
  bodyFilter.frequency.value = selected.value.number >= 4 ? 185 : 230
  bodyFilter.Q.value = 0.9
  bodyFilter.gain.value = 2.2
  lowShelf.type = 'lowshelf'
  lowShelf.frequency.value = 155
  lowShelf.gain.value = 2.8
  convolver.buffer = createRoomImpulse(context)
  dryGain.gain.value = 0.9
  wetGain.gain.value = 0.18
  envelope.gain.setValueAtTime(0.0001, now)
  envelope.gain.linearRampToValueAtTime(0.24, now + 0.008)
  envelope.gain.setValueAtTime(0.19, now + 0.045)
  envelope.gain.exponentialRampToValueAtTime(0.0001, now + duration)

  source.connect(toneFilter)
  toneFilter.connect(lowShelf)
  lowShelf.connect(bodyFilter)
  bodyFilter.connect(envelope)
  envelope.connect(dryGain)
  dryGain.connect(context.destination)
  envelope.connect(convolver)
  convolver.connect(wetGain)
  wetGain.connect(context.destination)
  source.start(now)
  source.stop(now + duration)

  // Ruido muy breve y filtrado: reproduce el pequeño ataque de la uña o púa.
  const transientBuffer = context.createBuffer(1, Math.floor(context.sampleRate * 0.025), context.sampleRate)
  const transientSamples = transientBuffer.getChannelData(0)
  for (let i = 0; i < transientSamples.length; i++) {
    transientSamples[i] = (Math.random() * 2 - 1) * (1 - i / transientSamples.length)
  }
  const transient = context.createBufferSource()
  const transientFilter = context.createBiquadFilter()
  const transientGain = context.createGain()
  transient.buffer = transientBuffer
  transientFilter.type = 'highpass'
  transientFilter.frequency.value = 1700
  transientGain.gain.setValueAtTime(0.035, now)
  transientGain.gain.exponentialRampToValueAtTime(0.0001, now + 0.025)
  transient.connect(transientFilter)
  transientFilter.connect(transientGain)
  transientGain.connect(context.destination)
  transient.start(now)
}

onUnmounted(() => {
  if (audioContext) {
    void audioContext.close()
    audioContext = null
  }
})
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
            :class="selected.number === string.number ? 'bg-[#dcebe0] ring-1 ring-[#7ca68d]' : 'hover:bg-white/70'"
            @click="selectString(string)"
          >
            <span class="grid h-8 w-8 shrink-0 place-items-center rounded-full bg-white text-xs font-black text-[#547260]">{{ string.number }}</span>
            <span class="relative flex h-7 flex-1 items-center">
              <span class="block w-full rounded-full bg-gradient-to-b from-[#c9c7bd] via-[#77766f] to-[#e4e0d5]" :style="{ height: string.thickness + 'px' }"></span>
              <span v-if="selected.number === string.number" class="absolute left-1/2 h-5 w-5 -translate-x-1/2 rounded-full border-2 border-white bg-[#176b5b] shadow"></span>
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
          <p class="text-[10px] font-bold uppercase tracking-wide text-[#718078]">Cuerda {{ selected.number }} · Al aire</p>
          <p class="mt-1 text-3xl font-black text-[#176b5b]">{{ note.name }}<sub class="ml-0.5 text-base">{{ note.octave }}</sub></p>
          <p class="mt-1 text-xs text-[#75827b]">{{ midiHz(selected.midi).toFixed(1) }} Hz · Sonido real</p>
          <button class="secondary mt-3 flex items-center gap-2" @click="play">
            <Volume2 :size="17" /> Escuchar cuerda
          </button>
        </div>
        <div class="rounded-xl bg-[#f5f8f4] p-2">
          <p class="mb-1 text-center text-[10px] font-bold uppercase tracking-wide text-[#718078]">Así se escribe para guitarra</p>
          <StaffNote :midi="selected.midi + 12" />
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
