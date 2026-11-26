import { midiHz } from '../music/pitch'

let audioContext: AudioContext | null = null

function getAudioContext() {
  if (typeof window === 'undefined' || !window.AudioContext) return null
  audioContext ??= new window.AudioContext()
  return audioContext
}

function createRoomImpulse(context: AudioContext, duration = 0.72) {
  const frameCount = Math.floor(context.sampleRate * duration)
  const impulse = context.createBuffer(2, frameCount, context.sampleRate)
  for (let channel = 0; channel < impulse.numberOfChannels; channel++) {
    const samples = impulse.getChannelData(channel)
    for (let i = 0; i < frameCount; i++) {
      samples[i] = (Math.random() * 2 - 1) * Math.pow(1 - i / frameCount, 2.8)
    }
  }
  return impulse
}

function createPluckedStringBuffer(context: AudioContext, frequency: number, stringNumber: number, duration: number) {
  const frameCount = Math.floor(context.sampleRate * duration)
  const buffer = context.createBuffer(1, frameCount, context.sampleRate)
  const samples = buffer.getChannelData(0)
  const delayLength = Math.max(2, Math.round(context.sampleRate / frequency))
  const delay = new Float32Array(delayLength)
  const pickPosition = 0.18 + stringNumber * 0.012
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

/** Reproduce una nota con el timbre de cuerda pulsada compartido por todos los módulos. */
export async function playGuitarNote(midi: number, stringNumber = 3) {
  const context = getAudioContext()
  if (!context || !Number.isFinite(midi)) return
  if (context.state === 'suspended') await context.resume()
  const now = context.currentTime
  const duration = 1.8
  const source = context.createBufferSource()
  const toneFilter = context.createBiquadFilter()
  const lowShelf = context.createBiquadFilter()
  const bodyFilter = context.createBiquadFilter()
  const envelope = context.createGain()
  const convolver = context.createConvolver()
  const dryGain = context.createGain()
  const wetGain = context.createGain()
  source.buffer = createPluckedStringBuffer(context, midiHz(midi), stringNumber, duration)
  toneFilter.type = 'lowpass'
  toneFilter.frequency.value = stringNumber >= 4 ? 4200 : 6200
  toneFilter.Q.value = 0.55
  lowShelf.type = 'lowshelf'
  lowShelf.frequency.value = 155
  lowShelf.gain.value = 2.8
  bodyFilter.type = 'peaking'
  bodyFilter.frequency.value = stringNumber >= 4 ? 185 : 230
  bodyFilter.Q.value = 0.9
  bodyFilter.gain.value = 2.2
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
