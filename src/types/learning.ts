/** Metadatos comunes para rutas, lecciones y ejercicios de Guitar Tutor. */

export type LearningLevel = 'beginner' | 'intermediate' | 'advanced'
export type LearningArea = 'fretboard' | 'staff' | 'harmony' | 'rhythm' | 'sight-reading'
export type ExerciseFormat =
  | 'multiple-choice'
  | 'fretboard-location'
  | 'staff-identification'
  | 'audio-identification'
  | 'sequence-completion'
  | 'rhythm-performance'
  | 'music-reading'

export interface LearningMetadata {
  level: LearningLevel
  area: LearningArea
  topic: string
  subtopic?: string
  prerequisites?: string[]
}

export interface ExerciseDefinition extends LearningMetadata {
  id: string
  format: ExerciseFormat
  prompt: string
  explanation: string
  /** Parámetros visuales o musicales; nunca debe contener la respuesta privada. */
  config?: Record<string, string | number | boolean | string[] | number[]>
}

export interface FretboardRegion {
  id: string
  label: string
  startFret: number
  endFret: number
  level: LearningLevel
}

export const DEFAULT_FRETBOARD_REGIONS: readonly FretboardRegion[] = [
  { id: 'beginner-1-5', label: 'Posición inicial · 1–5', startFret: 1, endFret: 5, level: 'beginner' },
  { id: 'intermediate-5-9', label: 'Posición media · 5–9', startFret: 5, endFret: 9, level: 'intermediate' },
  { id: 'advanced-7-11', label: 'Posición · 7–11', startFret: 7, endFret: 11, level: 'advanced' },
  { id: 'advanced-8-12', label: 'Posición · 8–12', startFret: 8, endFret: 12, level: 'advanced' },
  { id: 'advanced-9-13', label: 'Posición · 9–13', startFret: 9, endFret: 13, level: 'advanced' },
  { id: 'advanced-10-14', label: 'Posición · 10–14', startFret: 10, endFret: 14, level: 'advanced' },
]

export function isValidFretboardRegion(region: Pick<FretboardRegion, 'startFret' | 'endFret'>): boolean {
  return Number.isInteger(region.startFret)
    && Number.isInteger(region.endFret)
    && region.startFret >= 0
    && region.endFret <= 24
    && region.endFret >= region.startFret
    && region.endFret - region.startFret === 4
}
