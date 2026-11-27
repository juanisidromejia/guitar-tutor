export {
  buildTriad,
  formatSpelledNote,
  midiToNote,
  noteToMidi,
  parseNoteName,
  pitchClass,
  pitchClassDistance,
  respellNote,
} from './musicTheory'

export type {
  Accidental,
  MusicalNote,
  NoteLetter,
  NoteSpellingPreference,
  SpelledNote,
  TriadQuality,
} from './musicTheory'

export const OPEN_MIDI = [40, 45, 50, 55, 59, 64] as const

const NAMES = ['Do', 'Do♯', 'Re', 'Re♯', 'Mi', 'Fa', 'Fa♯', 'Sol', 'Sol♯', 'La', 'La♯', 'Si']

/** Nombre cromático compatible con los módulos existentes. */
export function midiName(midi: number) {
  return {
    name: NAMES[((midi % 12) + 12) % 12],
    octave: Math.floor(midi / 12) - 1,
  }
}

/** Frecuencia en Hz correspondiente a una altura MIDI. */
export function midiHz(midi: number) {
  return 440 * 2 ** ((midi - 69) / 12)
}
