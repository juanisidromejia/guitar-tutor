export type RhythmEvent = { label: string; units: number; rest?: boolean }

let context: AudioContext | null = null

function getContext() {
  if (!context) context = new AudioContext()
  if (context.state === 'suspended') void context.resume()
  return context
}

function click(time: number, accented: boolean) {
  if (!context) return
  const oscillator = context.createOscillator()
  const gain = context.createGain()
  oscillator.type = 'sine'
  oscillator.frequency.setValueAtTime(accented ? 1250 : 850, time)
  gain.gain.setValueAtTime(0.0001, time)
  gain.gain.exponentialRampToValueAtTime(accented ? 0.22 : 0.13, time + 0.004)
  gain.gain.exponentialRampToValueAtTime(0.0001, time + 0.055)
  oscillator.connect(gain)
  gain.connect(context.destination)
  oscillator.start(time)
  oscillator.stop(time + 0.06)
}

/** Reproduce un patrón con clic de metrónomo y golpes de percusión suaves. */
export function playRhythm(
  events: RhythmEvent[],
  bpm: number,
  beatsPerBar: number,
  onPosition: (eighthIndex: number) => void,
  onEnd: () => void,
) {
  const audio = getContext()
  const secondsPerEighth = 30 / bpm
  const totalUnits = events.reduce((sum, event) => sum + event.units, 0)
  const start = audio.currentTime + 0.08
  const timers: number[] = []

  for (let beat = 0; beat < beatsPerBar; beat++) {
    click(start + beat * secondsPerEighth * 2, beat === 0)
  }

  let position = 0
  for (const event of events) {
    if (!event.rest) click(start + position * secondsPerEighth, false)
    position += event.units
  }

  for (let unit = 0; unit < totalUnits; unit++) {
    timers.push(window.setTimeout(() => onPosition(unit), 80 + unit * secondsPerEighth * 1000))
  }
  timers.push(window.setTimeout(onEnd, 100 + totalUnits * secondsPerEighth * 1000))

  return () => timers.forEach(window.clearTimeout)
}
