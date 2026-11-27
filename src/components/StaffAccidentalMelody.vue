<script setup lang="ts">
import { computed, ref } from 'vue'
import { CheckCircle2, XCircle, Volume2 } from 'lucide-vue-next'
import StaffNote from './StaffNote.vue'
import { noteToMidi } from '../engines/music/musicTheory'
import type { SpelledNote } from '../engines/music/musicTheory'
import { playGuitarNote } from '../engines/audio/guitarSound'

type MelodyEvent = {
  id: string
  spelling: SpelledNote
  sign: 'sharp' | 'flat' | 'natural' | 'none'
  label: string
  string: number
  fret: number
  explanation: string
}

function event(
  id: string,
  letter: SpelledNote['letter'],
  accidental: SpelledNote['accidental'],
  sign: MelodyEvent['sign'],
  string: number,
  fret: number,
  explanation: string,
): MelodyEvent {
  return {
    id,
    spelling: { letter, accidental, octave: 4 },
    sign,
    label: `${letter}${accidental === 1 ? '♯' : accidental === -1 ? '♭' : ''}`,
    string,
    fret,
    explanation,
  }
}

const measures: { number: number; notes: MelodyEvent[] }[] = [
  {
    number: 1,
    notes: [
      event('m1-1', 'Re', 0, 'none', 4, 0, 'Re comienza natural.'),
      event('m1-2', 'Mi', -1, 'flat', 4, 1, 'El bemol baja Mi un semitono.'),
      event('m1-3', 'Mi', -1, 'none', 4, 1, 'El bemol continúa vigente para Mi durante este compás.'),
      event('m1-4', 'Mi', 0, 'natural', 4, 2, 'El becuadro cancela el bemol: Mi vuelve a ser natural.'),
      event('m1-5', 'Mi', 0, 'none', 4, 2, 'Mi sigue natural después del becuadro.'),
      event('m1-6', 'Fa', 1, 'sharp', 4, 4, 'El sostenido eleva Fa un semitono.'),
      event('m1-7', 'Fa', 1, 'none', 4, 4, 'Fa sigue sostenido hasta el final del compás.'),
      event('m1-8', 'Sol', 0, 'none', 4, 5, 'Sol no ha sido alterado en este compás.'),
    ],
  },
  {
    number: 2,
    notes: [
      event('m2-1', 'Si', -1, 'flat', 3, 3, 'Al comenzar el nuevo compás, las alteraciones anteriores se restablecen. Aquí aparece un nuevo bemol para Si.'),
      event('m2-2', 'Si', -1, 'none', 3, 3, 'El bemol de Si continúa vigente en este compás.'),
      event('m2-3', 'Si', 0, 'natural', 3, 4, 'El becuadro cancela el bemol y devuelve Si a su altura natural.'),
      event('m2-4', 'Sol', 1, 'sharp', 3, 1, 'El sostenido eleva Sol un semitono.'),
      event('m2-5', 'Sol', 1, 'none', 3, 1, 'Sol continúa sostenido durante el compás.'),
      event('m2-6', 'Sol', 0, 'natural', 3, 0, 'El becuadro cancela el sostenido: Sol vuelve a ser natural.'),
      event('m2-7', 'Fa', 0, 'none', 4, 3, 'Fa es natural: el sostenido del compás anterior ya no está vigente.'),
      event('m2-8', 'Mi', 0, 'none', 4, 2, 'Mi también vuelve a su estado natural al comenzar este compás.'),
    ],
  },
]

const activeNote = ref<MelodyEvent | null>(null)
const answers = ref<Record<string, string>>({})
const submitted = ref(false)

const questions = [
  {
    id: 'q1',
    prompt: 'En el primer compás, ¿cómo se interpreta el segundo Mi?',
    options: [{ value: 'flat', label: 'Mi bemol' }, { value: 'natural', label: 'Mi natural' }],
    correct: 'flat',
    explanation: 'El bemol del primer Mi sigue vigente para el siguiente Mi del mismo compás y octava.',
  },
  {
    id: 'q2',
    prompt: '¿Qué hace el becuadro que aparece después?',
    options: [{ value: 'cancel', label: 'Cancela el bemol y deja Mi natural' }, { value: 'keep', label: 'Mantiene Mi bemol' }],
    correct: 'cancel',
    explanation: 'El becuadro cancela la alteración anterior para esa nota.',
  },
  {
    id: 'q3',
    prompt: 'Al comenzar el segundo compás, ¿el Si sigue bemol por lo ocurrido antes?',
    options: [{ value: 'yes', label: 'Sí, continúa' }, { value: 'no', label: 'No, se restablece' }],
    correct: 'no',
    explanation: 'La barra de compás restablece las alteraciones accidentales del compás anterior.',
  },
  {
    id: 'q4',
    prompt: 'En el segundo compás, ¿cómo suena el segundo Sol?',
    options: [{ value: 'sharp', label: 'Sol sostenido' }, { value: 'natural', label: 'Sol natural' }],
    correct: 'sharp',
    explanation: 'El sostenido del primer Sol sigue vigente hasta que aparece el becuadro.',
  },
]

const score = computed(() => questions.filter(q => answers.value[q.id] === q.correct).length)

function writtenMidi(note: MelodyEvent) {
  return noteToMidi(note.spelling)
}

function play(note: MelodyEvent) {
  activeNote.value = note
  // La guitarra suena una octava por debajo de la nota escrita.
  void playGuitarNote(writtenMidi(note) - 12, note.string)
}

function checkAnswers() {
  submitted.value = true
}
</script>

<template>
  <section class="panel mb-4 p-3 sm:p-4">
    <div class="mb-3">
      <p class="eyebrow">Lectura musical · Aplicación en una melodía</p>
      <h2 class="text-lg font-black">Lee y escucha una pequeña melodía</h2>
      <p class="mt-1 text-sm leading-5 text-[#788780]">
        Ahora aparecen alteraciones en distintas notas. Sigue cada signo a lo largo del compás y escucha cómo cambia la melodía al tocar sus notas.
      </p>
    </div>

    <div class="mb-3 grid gap-2 sm:grid-cols-3">
      <div class="rounded-xl bg-[#edf4ee] p-3">
        <p class="text-sm font-black text-[#426c5b]">Bemol ♭</p>
        <p class="mt-1 text-xs leading-5 text-[#567267]">Baja la nota un semitono.</p>
      </div>
      <div class="rounded-xl bg-[#edf4ee] p-3">
        <p class="text-sm font-black text-[#426c5b]">Sostenido ♯</p>
        <p class="mt-1 text-xs leading-5 text-[#567267]">Sube la nota un semitono.</p>
      </div>
      <div class="rounded-xl bg-[#edf4ee] p-3">
        <p class="text-sm font-black text-[#426c5b]">Becuadro ♮</p>
        <p class="mt-1 text-xs leading-5 text-[#567267]">Cancela el sostenido o bemol anterior.</p>
      </div>
    </div>

    <div class="rounded-xl border border-[#dce7df] p-3">
      <div class="mb-3 flex flex-wrap items-center justify-between gap-2">
        <div>
          <p class="eyebrow">Melodía interactiva · Dos compases</p>
          <h3 class="mt-1 text-base font-black">Toca las notas para escucharlas</h3>
        </div>
        <span class="rounded-full bg-[#edf4ee] px-2.5 py-1 text-[10px] font-bold text-[#426c5b]">Sonido real: una octava abajo</span>
      </div>

      <div v-for="bar in measures" :key="bar.number" class="mb-4 last:mb-0">
        <p class="mb-1 text-[10px] font-bold uppercase tracking-wide text-[#718078]">Compás {{ bar.number }}</p>
        <div class="grid grid-cols-4 gap-1.5 sm:grid-cols-8 sm:gap-2">
          <button
            v-for="(note, index) in bar.notes"
            :key="note.id"
            class="min-w-0 rounded-lg border-2 p-1 text-center transition active:scale-[0.98]"
            :class="activeNote?.id === note.id ? 'border-[#4c9c7c] bg-[#edf4ee]' : 'border-transparent bg-[#f7f4ed] hover:bg-[#f0f4ed]'"
            :aria-label="`Escuchar ${note.label} del compás ${bar.number}`"
            @click="play(note)"
          >
            <StaffNote :midi="writtenMidi(note)" :spelling="note.spelling" :accidental-display="note.sign" />
            <span class="mt-1 block text-[10px] font-black text-[#176b5b]">{{ note.label }}</span>
            <span class="block text-[9px] text-[#788780]">{{ note.sign === 'sharp' ? '♯' : note.sign === 'flat' ? '♭' : note.sign === 'natural' ? '♮' : '—' }}</span>
            <span class="mt-1 block text-[9px] font-bold text-[#8a795f]">{{ index + 1 }}</span>
          </button>
        </div>
        <div class="mt-2 flex items-center gap-2 px-1 text-[10px] text-[#8a795f]">
          <span class="h-px flex-1 bg-[#cbbda8]"></span>
          <span>Barra de compás {{ bar.number }}</span>
          <span class="h-px flex-1 bg-[#cbbda8]"></span>
        </div>
      </div>

      <div v-if="activeNote" class="mt-2 flex items-start gap-2 rounded-lg bg-[#edf4ee] p-3">
        <Volume2 :size="16" class="mt-0.5 shrink-0 text-[#426c5b]" />
        <div>
          <p class="text-xs font-bold text-[#426c5b]">Escuchaste {{ activeNote.label }}</p>
          <p class="mt-1 text-xs leading-5 text-[#567267]">{{ activeNote.explanation }}</p>
          <p class="mt-1 text-[10px] text-[#718078]">Posición: cuerda {{ activeNote.string }}, traste {{ activeNote.fret }}. La nota escrita para guitarra suena una octava más grave.</p>
        </div>
      </div>
      <p v-else class="mt-2 text-center text-xs text-[#788780]">Selecciona cualquier nota de la melodía para escucharla y leer su explicación.</p>
    </div>

    <div class="mt-3 rounded-xl bg-[#f7f4ed] p-3">
      <h3 class="text-base font-black">Comprueba lo que aprendiste</h3>
      <p class="mt-1 text-xs leading-5 text-[#788780]">Responde según los signos y las barras de compás de la melodía.</p>
      <div v-for="item in questions" :key="item.id" class="mt-3">
        <p class="text-xs font-bold text-[#426c5b]">{{ item.prompt }}</p>
        <div class="mt-2 grid gap-2 sm:grid-cols-2">
          <button
            v-for="option in item.options"
            :key="option.value"
            class="rounded-lg border-2 bg-white px-3 py-2 text-left text-xs font-semibold transition"
            :class="answers[item.id] === option.value ? 'border-[#4c9c7c] bg-[#edf4ee]' : 'border-transparent'"
            :disabled="submitted"
            @click="answers[item.id] = option.value"
          >
            {{ option.label }}
          </button>
        </div>
        <p v-if="submitted" class="mt-1 flex items-start gap-1.5 text-[11px]" :class="answers[item.id] === item.correct ? 'text-[#226447]' : 'text-[#a14f2d]'">
          <CheckCircle2 v-if="answers[item.id] === item.correct" :size="14" />
          <XCircle v-else :size="14" />
          {{ item.explanation }}
        </p>
      </div>
      <div class="mt-3 flex items-center justify-between gap-2">
        <p v-if="submitted" class="text-xs font-bold text-[#426c5b]">Resultado: {{ score }} de {{ questions.length }}</p>
        <span v-else class="text-[10px] text-[#788780]">{{ Object.keys(answers).length }} de {{ questions.length }} respondidas</span>
        <button v-if="!submitted" class="primary px-3 py-2 text-xs" :disabled="Object.keys(answers).length !== questions.length" @click="checkAnswers">Comprobar</button>
        <button v-else class="secondary px-3 py-2 text-xs" @click="answers = {}; submitted = false">Repetir</button>
      </div>
    </div>
  </section>
</template>
