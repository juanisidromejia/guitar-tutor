<script setup lang="ts">
import { computed, ref } from 'vue'
import { CheckCircle2 } from 'lucide-vue-next'
import StaffNote from '../components/StaffNote.vue'
import { midiHz, midiName } from '../engines/music/pitch'
import { playGuitarNote } from '../engines/audio/guitarSound'
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
const selected = ref<typeof strings[number] | null>(null)
const selectedString = computed(() => selected.value ?? strings[0])
const visited = ref<number[]>([])
const selectedFret = ref(0)
const visitedFrets = ref<number[]>([])
const visitedNaturalNotes = ref<string[]>([])
const selectedNaturalNote = ref<{ key: string; midi: number; stringNumber: number; stringName: string; fret: number; name: string } | null>(null)
const totalNaturalNotes = computed(() => naturalNotesByString.value.reduce((total, string) => total + string.notes.length, 0))
const fretNote = computed(() => midiName(strings[0].midi + selectedFret.value))
const note = computed(() => midiName(selectedString.value.midi))
const writtenNote = computed(() => midiName(selectedString.value.midi + 12))
const naturalNotesByString = computed(() => strings.map(string => ({
  ...string,
  notes: [0, 1, 2, 3].map(fret => ({
    fret,
    midi: string.midi + fret,
    note: midiName(string.midi + fret),
  })).filter(item => !item.note.name.includes('♯')),
})))

function maybeComplete() {
  const exploredStrings = visited.value.length === strings.length
  const exploredFrets = [0, 1, 2, 3].every(value => visitedFrets.value.includes(value))
  const exploredNaturalNotes = visitedNaturalNotes.value.length === totalNaturalNotes.value
  if (exploredStrings && exploredFrets && exploredNaturalNotes) complete(1)
}

function selectString(string: typeof strings[number]) {
  selected.value = string
  if (!visited.value.includes(string.number)) visited.value.push(string.number)
  maybeComplete()
  void playGuitarNote(string.midi, string.number)
}

function selectFret(fret: number) {
  selectedFret.value = fret
  if (!visitedFrets.value.includes(fret)) visitedFrets.value.push(fret)
  maybeComplete()
  void playGuitarNote(strings[0].midi + fret, 1)
}

function playNaturalNote(midi: number, stringNumber: number, fret: number, name: string) {
  const string = strings.find(item => item.number === stringNumber)
  if (!string) return
  const key = `${stringNumber}-${fret}`
  selectedNaturalNote.value = { key, midi, stringNumber, stringName: string.name, fret, name }
  if (!visitedNaturalNotes.value.includes(key)) visitedNaturalNotes.value.push(key)
  maybeComplete()
  void playGuitarNote(midi, stringNumber)
}
</script>

<template>
  <div class="page">
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
            :class="selected?.number === string.number ? 'bg-[#dcebe0] ring-1 ring-[#7ca68d]' : 'hover:bg-white/70'"
            @click="selectString(string)"
          >
            <span class="grid h-8 w-8 shrink-0 place-items-center rounded-full bg-white text-xs font-black text-[#547260]">{{ string.number }}</span>
            <span class="relative flex h-7 flex-1 items-center">
              <span class="block w-full rounded-full bg-gradient-to-b from-[#c9c7bd] via-[#77766f] to-[#e4e0d5]" :style="{ height: string.thickness + 'px' }"></span>
              <span v-if="selected?.number === string.number" class="absolute left-1/2 h-5 w-5 -translate-x-1/2 rounded-full border-2 border-white bg-[#176b5b] shadow"></span>
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
          <p class="text-[10px] font-bold uppercase tracking-wide text-[#718078]">Cuerda {{ selectedString.number }} · Al aire</p>
          <p class="mt-1 text-3xl font-black text-[#176b5b]">{{ note.name }}<sub class="ml-0.5 text-base">{{ note.octave }}</sub></p>
          <p class="mt-1 text-xs text-[#75827b]">{{ midiHz(selectedString.midi).toFixed(1) }} Hz · Sonido real</p>
        </div>
        <div class="rounded-xl bg-[#f5f8f4] p-2">
          <p class="mb-1 text-center text-[10px] font-bold uppercase tracking-wide text-[#718078]">Así se escribe para guitarra</p>
          <StaffNote :midi="selectedString.midi + 12" />
          <p class="mt-1 text-center text-[11px] font-semibold text-[#176b5b]">
            {{ writtenNote.name }}{{ writtenNote.octave }} · escritura una octava arriba
          </p>
        </div>
      </div>
    </section>

    <section class="panel mt-4 p-3 sm:p-4">
      <div class="mb-3">
        <p class="eyebrow">Siguiente paso · Altura de las notas</p>
        <h2 class="text-lg font-black">¿Qué ocurre cuando pisamos un traste?</h2>
        <p class="mt-1 text-sm leading-5 text-[#788780]">
          Al presionar una cuerda contra un traste, acortamos la parte que vibra. Cuanto más avanzamos hacia el cuerpo de la guitarra, más agudo es el sonido.
        </p>
      </div>
      <div class="rounded-xl bg-[#f7f4ed] p-3 sm:p-4">
        <p class="text-center text-xs font-bold uppercase tracking-wide text-[#8a795f]">Primera cuerda · Mi al aire</p>
        <div class="mt-3 grid grid-cols-4 gap-2">
          <button
            v-for="fret in [0, 1, 2, 3]"
            :key="fret"
            class="rounded-xl border-2 px-2 py-3 text-center transition active:scale-95"
            :class="selectedFret === fret ? 'border-[#4c9c7c] bg-[#dcebe0]' : 'border-transparent bg-white hover:bg-[#f0f4ed]'"
            @click="selectFret(fret)"
          >
            <span class="block text-[10px] font-bold uppercase text-[#788780]">{{ fret === 0 ? 'Al aire' : 'Traste ' + fret }}</span>
            <span class="mt-1 block text-xl font-black text-[#176b5b]">{{ ['Mi', 'Fa', 'Fa♯', 'Sol'][fret] }}</span>
            <span class="mt-1 block text-[10px] text-[#788780]">{{ fret === 0 ? '0 semitonos' : fret + ' semitono' + (fret === 1 ? '' : 's') }}</span>
          </button>
        </div>
        <div class="mt-3 rounded-lg bg-white/80 p-3 text-center">
          <p class="text-[10px] font-bold uppercase tracking-wide text-[#718078]">Nota seleccionada · Sonido real</p>
          <p class="mt-1 text-3xl font-black text-[#176b5b]">{{ fretNote.name }}<sub class="ml-0.5 text-base">{{ fretNote.octave }}</sub></p>
          <p class="mt-1 text-xs text-[#75827b]">Pulsa cada posición para escuchar cómo cambia la altura.</p>
        </div>
      </div>
      <div class="mt-3 grid gap-2 sm:grid-cols-2">
        <div class="rounded-xl bg-[#edf4ee] p-3 text-xs leading-5 text-[#567267]">
          <b>Un traste = un semitono.</b>
          Cada vez que avanzas un traste, la nota sube un semitono. Mi–Fa es un semitono; Fa–Sol son dos.
        </div>
        <div class="rounded-xl bg-[#edf4ee] p-3 text-xs leading-5 text-[#567267]">
          <b>Dos trastes = un tono.</b>
          Un tono equivale a dos semitonos. Por eso, desde Fa hasta Sol avanzamos dos trastes: Fa, Fa♯, Sol.
        </div>
      </div>
      <p class="mt-3 text-xs leading-5 text-[#788780]">
        Observa que entre Mi y Fa no aparece una nota natural intermedia. En cambio, entre Fa y Sol encontramos Fa♯. Más adelante aprenderás cómo se escriben y utilizan los sostenidos y bemoles.
      </p>
    </section>

    <section class="panel mt-4 p-3 sm:p-4">
      <div class="mb-3">
        <p class="eyebrow">Exploración guiada · Primera posición</p>
        <h2 class="text-lg font-black">Conoce las notas naturales</h2>
        <p class="mt-1 text-sm leading-5 text-[#788780]">
          Explora las notas naturales de cada cuerda. Selecciona cada posición, escucha su sonido y observa cómo cambia el nombre de la nota al avanzar por el diapasón.
        </p>
      </div>
      <div class="mb-3 flex items-center justify-between gap-3 rounded-lg bg-[#edf4ee] px-3 py-2">
        <div>
          <p class="text-xs font-bold text-[#567267]">Notas naturales exploradas</p>
          <p class="text-[10px] text-[#788780]">Selecciona todas las posiciones para completar esta parte</p>
        </div>
        <span class="text-sm font-black text-[#176b5b]">{{ visitedNaturalNotes.length }} / {{ totalNaturalNotes }}</span>
      </div>
      <div class="grid gap-2 sm:grid-cols-2 lg:grid-cols-3">
        <div v-for="string in naturalNotesByString" :key="string.number" class="rounded-xl bg-[#f7f4ed] p-3">
          <p class="mb-2 text-xs font-extrabold uppercase tracking-wide text-[#8a795f]">Cuerda {{ string.number }} · {{ string.name }} al aire</p>
          <div class="flex flex-wrap gap-2">
            <button
              v-for="item in string.notes"
              :key="item.fret"
              class="min-w-[64px] flex-1 rounded-lg border-2 px-2 py-2 text-center transition hover:bg-[#dcebe0] active:scale-95"
              :class="selectedNaturalNote?.key === `${string.number}-${item.fret}` ? 'border-[#4c9c7c] bg-[#dcebe0]' : 'border-transparent bg-white'"
              @click="playNaturalNote(item.midi, string.number, item.fret, item.note.name)"
            >
              <span class="block text-lg font-black text-[#176b5b]">{{ item.note.name }}</span>
              <span class="block text-[10px] text-[#788780]">{{ item.fret === 0 ? 'Al aire' : 'Traste ' + item.fret }}</span>
              <span v-if="visitedNaturalNotes.includes(`${string.number}-${item.fret}`)" class="mt-1 block text-[9px] font-bold text-[#4c9c7c]">Explorada ✓</span>
            </button>
          </div>
        </div>
      </div>
      <div v-if="selectedNaturalNote" class="mt-3 rounded-xl bg-[#f5f8f4] p-3 text-center">
        <p class="text-[10px] font-bold uppercase tracking-wide text-[#718078]">Nota que acabas de escuchar</p>
        <p class="mt-1 text-2xl font-black text-[#176b5b]">{{ selectedNaturalNote.name }}{{ midiName(selectedNaturalNote.midi).octave }}</p>
        <p class="mt-1 text-xs text-[#75827b]">Cuerda {{ selectedNaturalNote.stringNumber }} ({{ selectedNaturalNote.stringName }}) · {{ selectedNaturalNote.fret === 0 ? 'al aire' : 'traste ' + selectedNaturalNote.fret }} · Sonido real</p>
      </div>
      <p class="mt-3 rounded-lg bg-[#edf4ee] p-3 text-xs leading-5 text-[#567267]">
        Algunas posiciones se omiten porque producen notas alteradas, como sostenidos. Por ejemplo, en la primera cuerda encontramos Mi al aire, Fa en el primer traste y Sol en el tercero. El segundo traste produce Fa♯; lo estudiaremos en la siguiente lección sobre alteraciones.
      </p>
    </section>

    <div class="mt-3 grid gap-2 sm:grid-cols-2">
      <div class="rounded-xl bg-[#edf4ee] p-3 text-xs leading-5 text-[#567267]">
        <b>¿Por qué hay dos cuerdas Mi?</b>
        La sexta y la primera tienen el mismo nombre, pero la primera suena dos octavas más aguda. Por ejemplo, la primera cuerda al aire suena Mi4 y se escribe Mi5 en el pentagrama de guitarra.
      </div>
      <div class="rounded-xl bg-[#edf4ee] p-3 text-xs leading-5 text-[#567267]">
        <b>¿Qué ocurre al pisar un traste?</b>
        Cada traste sube la nota un semitono. Por ejemplo, Mi pasa a Fa en el primer traste.
      </div>
    </div>

    <div v-if="visited.length === 6 && [0, 1, 2, 3].every(value => visitedFrets.includes(value)) && visitedNaturalNotes.length === totalNaturalNotes" class="mt-3 flex items-center gap-2 rounded-xl bg-[#e9f5ed] p-3 text-sm font-semibold text-[#226447]">
      <CheckCircle2 :size="19" />
      ¡Has explorado las seis cuerdas y las primeras posiciones! Ya conoces las cuerdas al aire y cómo suben las notas.
    </div>
  </div>
</template>
