/**
 * Modelo musical compartido de Guitar Tutor.
 *
 * Las alturas se representan internamente con MIDI. La escritura (Do♯/Re♭)
 * se conserva como información separada: una misma altura puede escribirse
 * de distintas maneras según el contexto musical.
 */

export type NoteLetter = 'Do' | 'Re' | 'Mi' | 'Fa' | 'Sol' | 'La' | 'Si'
export type Accidental = -2 | -1 | 0 | 1 | 2
export type NoteSpellingPreference = 'sharp' | 'flat'

export interface SpelledNote {
  letter: NoteLetter
  accidental: Accidental
  octave: number
}

export interface MusicalNote extends SpelledNote {
  midi: number
  name: string
}

const NATURAL_PITCH_CLASS: Record<NoteLetter, number> = {
  Do: 0,
  Re: 2,
  Mi: 4,
  Fa: 5,
  Sol: 7,
  La: 9,
  Si: 11,
}

const SHARP_NAMES: readonly { letter: NoteLetter; accidental: Accidental }[] = [
  { letter: 'Do', accidental: 0 },
  { letter: 'Do', accidental: 1 },
  { letter: 'Re', accidental: 0 },
  { letter: 'Re', accidental: 1 },
  { letter: 'Mi', accidental: 0 },
  { letter: 'Fa', accidental: 0 },
  { letter: 'Fa', accidental: 1 },
  { letter: 'Sol', accidental: 0 },
  { letter: 'Sol', accidental: 1 },
  { letter: 'La', accidental: 0 },
  { letter: 'La', accidental: 1 },
  { letter: 'Si', accidental: 0 },
]

const FLAT_NAMES: readonly { letter: NoteLetter; accidental: Accidental }[] = [
  { letter: 'Do', accidental: 0 },
  { letter: 'Re', accidental: -1 },
  { letter: 'Re', accidental: 0 },
  { letter: 'Mi', accidental: -1 },
  { letter: 'Mi', accidental: 0 },
  { letter: 'Fa', accidental: 0 },
  { letter: 'Sol', accidental: -1 },
  { letter: 'Sol', accidental: 0 },
  { letter: 'La', accidental: -1 },
  { letter: 'La', accidental: 0 },
  { letter: 'Si', accidental: -1 },
  { letter: 'Si', accidental: 0 },
]

const LETTER_ALIASES: Record<string, NoteLetter> = {
  do: 'Do', c: 'Do',
  re: 'Re', d: 'Re',
  mi: 'Mi', e: 'Mi',
  fa: 'Fa', f: 'Fa',
  sol: 'Sol', g: 'Sol',
  la: 'La', a: 'La',
  si: 'Si', b: 'Si',
}

function normalizeAccidental(value: string): Accidental | null {
  if (!value) return 0
  if (value === '# ' || value === '#' || value === '♯') return 1
  if (value === 'b' || value === '♭') return -1
  if (value === 'x' || value === '𝄪') return 2
  if (value === '𝄫') return -2
  return null
}

export function noteToMidi(note: SpelledNote): number {
  const pitchClass = NATURAL_PITCH_CLASS[note.letter] + note.accidental
  return (note.octave + 1) * 12 + pitchClass
}

export function midiToNote(
  midi: number,
  preference: NoteSpellingPreference = 'sharp',
): MusicalNote {
  if (!Number.isInteger(midi)) throw new Error('La altura MIDI debe ser un número entero.')
  const pitchClass = ((midi % 12) + 12) % 12
  const spelling = (preference === 'flat' ? FLAT_NAMES : SHARP_NAMES)[pitchClass]
  const octave = Math.floor(midi / 12) - 1
  const accidentalSymbol = spelling.accidental === 1
    ? '♯'
    : spelling.accidental === -1
      ? '♭'
      : spelling.accidental === 2
        ? '𝄪'
        : spelling.accidental === -2
          ? '𝄫'
          : ''
  return {
    ...spelling,
    octave,
    midi,
    name: `${spelling.letter}${accidentalSymbol}${octave}`,
  }
}

/** Convierte nombres españoles o anglosajones, por ejemplo Do♯4, Reb4, F#3 o Bb2. */
export function parseNoteName(value: string): SpelledNote | null {
  const match = value.trim().match(/^(Do|Re|Mi|Fa|Sol|La|Si|[CDEFGAB])([#♯b♭x𝄪𝄫]?)(-?\d+)$/i)
  if (!match) return null
  const letter = LETTER_ALIASES[match[1].toLowerCase()]
  const accidental = normalizeAccidental(match[2])
  if (!letter || accidental === null) return null
  return { letter, accidental, octave: Number(match[3]) }
}

export function formatSpelledNote(note: SpelledNote): string {
  const symbol = note.accidental === 1
    ? '♯'
    : note.accidental === -1
      ? '♭'
      : note.accidental === 2
        ? '𝄪'
        : note.accidental === -2
          ? '𝄫'
          : ''
  return `${note.letter}${symbol}${note.octave}`
}

/** Devuelve la misma altura con una grafía preferida (sostenidos o bemoles). */
export function respellNote(
  note: SpelledNote,
  preference: NoteSpellingPreference,
): MusicalNote {
  return midiToNote(noteToMidi(note), preference)
}

export function pitchClass(midi: number): number {
  return ((midi % 12) + 12) % 12
}

/** Distancia cromática ascendente entre dos alturas, expresada en semitonos (0–11). */
export function pitchClassDistance(fromMidi: number, toMidi: number): number {
  return (pitchClass(toMidi) - pitchClass(fromMidi) + 12) % 12
}

export type TriadQuality = 'major' | 'minor' | 'diminished' | 'augmented'

const TRIAD_INTERVALS: Record<TriadQuality, readonly [number, number, number]> = {
  major: [0, 4, 7],
  minor: [0, 3, 7],
  diminished: [0, 3, 6],
  augmented: [0, 4, 8],
}

/** Construye una tríada en disposición fundamental a partir de una altura MIDI. */
export function buildTriad(rootMidi: number, quality: TriadQuality): number[] {
  return TRIAD_INTERVALS[quality].map(interval => rootMidi + interval)
}
