<script setup lang="ts">
import { computed, ref } from 'vue'
import { ArrowRight, CheckCircle2, RotateCcw, XCircle } from 'lucide-vue-next'

type Interval = {
  name: string
  short: string
  semitones: number
  family: string
  example: string
  explanation: string
}

const intervals: Interval[] = [
  { name: 'Unísono justo', short: '1.ª justa', semitones: 0, family: 'Justos', example: 'Do–Do', explanation: 'Dos notas con el mismo nombre y altura.' },
  { name: 'Segunda menor', short: '2.ª menor', semitones: 1, family: 'Segundos', example: 'Do–Re♭', explanation: 'Una segunda que abarca un semitono.' },
  { name: 'Segunda mayor', short: '2.ª mayor', semitones: 2, family: 'Segundos', example: 'Do–Re', explanation: 'Una segunda que abarca dos semitonos.' },
  { name: 'Tercera menor', short: '3.ª menor', semitones: 3, family: 'Terceros', example: 'Do–Mi♭', explanation: 'Una tercera que abarca tres semitonos.' },
  { name: 'Tercera mayor', short: '3.ª mayor', semitones: 4, family: 'Terceros', example: 'Do–Mi', explanation: 'Una tercera que abarca cuatro semitonos.' },
  { name: 'Cuarta justa', short: '4.ª justa', semitones: 5, family: 'Justos', example: 'Do–Fa', explanation: 'Una cuarta que abarca cinco semitonos.' },
  { name: 'Cuarta aumentada', short: '4.ª aumentada', semitones: 6, family: 'Aumentados / disminuidos', example: 'Do–Fa♯', explanation: 'Una cuarta ampliada: seis semitonos.' },
  { name: 'Quinta disminuida', short: '5.ª disminuida', semitones: 6, family: 'Aumentados / disminuidos', example: 'Do–Sol♭', explanation: 'Una quinta reducida: también seis semitonos. Suena igual que la cuarta aumentada, pero se escribe como quinta.' },
  { name: 'Quinta justa', short: '5.ª justa', semitones: 7, family: 'Justos', example: 'Do–Sol', explanation: 'Una quinta que abarca siete semitonos.' },
  { name: 'Sexta menor', short: '6.ª menor', semitones: 8, family: 'Sextos', example: 'Do–La♭', explanation: 'Una sexta que abarca ocho semitonos.' },
  { name: 'Sexta mayor', short: '6.ª mayor', semitones: 9, family: 'Sextos', example: 'Do–La', explanation: 'Una sexta que abarca nueve semitonos.' },
  { name: 'Séptima menor', short: '7.ª menor', semitones: 10, family: 'Séptimos', example: 'Do–Si♭', explanation: 'Una séptima que abarca diez semitonos.' },
  { name: 'Séptima mayor', short: '7.ª mayor', semitones: 11, family: 'Séptimos', example: 'Do–Si', explanation: 'Una séptima que abarca once semitonos.' },
  { name: 'Octava justa', short: '8.ª justa', semitones: 12, family: 'Justos', example: 'Do–Do', explanation: 'La nota superior repite el nombre de la inferior en la octava siguiente.' },
]

const families = [
  { name: 'Justos', description: 'Unísono, cuarta, quinta y octava.' },
  { name: 'Mayores y menores', description: 'Segundas, terceras, sextas y séptimas.' },
]
const selectedFamily = ref('Todos')
const visibleIntervals = computed(() => selectedFamily.value === 'Todos'
  ? intervals
  : intervals.filter(interval => interval.family === selectedFamily.value))

type Question = { prompt: string; options: string[]; correct: string; explanation: string }
const bank: Question[] = [
  { prompt: '¿Cuántos semitonos tiene una tercera mayor?', options: ['2', '3', '4', '5'], correct: '4', explanation: 'La tercera mayor abarca cuatro semitonos. Por ejemplo, Do–Mi.' },
  { prompt: '¿Qué intervalo hay entre Do y Mi♭?', options: ['Tercera menor', 'Tercera mayor', 'Segunda aumentada', 'Cuarta justa'], correct: 'Tercera menor', explanation: 'Do–Mi abarca una tercera por sus nombres; al bajar Mi a Mi♭, quedan tres semitonos: tercera menor.' },
  { prompt: '¿Cuántos semitonos tiene una quinta justa?', options: ['5', '6', '7', '8'], correct: '7', explanation: 'La quinta justa tiene siete semitonos, como Do–Sol.' },
  { prompt: '¿Qué intervalo tiene 1 semitono?', options: ['Segunda menor', 'Segunda mayor', 'Tercera menor', 'Unísono'], correct: 'Segunda menor', explanation: 'La segunda menor es la distancia más pequeña entre dos notas con nombres consecutivos.' },
  { prompt: 'Do–Fa♯ y Do–Sol♭ tienen la misma cantidad de semitonos. ¿Cómo se llaman, respectivamente?', options: ['Cuarta aumentada y quinta disminuida', 'Quinta disminuida y cuarta aumentada', 'Cuarta justa y quinta justa', 'Dos cuartas aumentadas'], correct: 'Cuarta aumentada y quinta disminuida', explanation: 'La cantidad de semitonos coincide (6), pero el nombre depende de la distancia entre las letras: Do–Fa es cuarta y Do–Sol es quinta.' },
  { prompt: '¿Cuál es la diferencia entre una tercera menor y una tercera mayor?', options: ['1 semitono', '2 semitonos', '3 semitonos', 'No hay diferencia'], correct: '1 semitono', explanation: 'La tercera menor tiene 3 semitonos y la mayor 4: se diferencian por un semitono.' },
  { prompt: '¿Cuántos semitonos tiene una séptima menor?', options: ['9', '10', '11', '12'], correct: '10', explanation: 'La séptima menor abarca diez semitonos, como Do–Si♭.' },
  { prompt: '¿Qué intervalo se forma entre Do y La?', options: ['Sexta menor', 'Sexta mayor', 'Quinta justa', 'Séptima menor'], correct: 'Sexta mayor', explanation: 'Do–La es una sexta por los nombres de las notas y contiene nueve semitonos.' },
  { prompt: '¿Cuál es el intervalo de 12 semitonos?', options: ['Séptima mayor', 'Octava justa', 'Quinta justa', 'Sexta mayor'], correct: 'Octava justa', explanation: 'Do–Do en la octava superior abarca doce semitonos.' },
  { prompt: 'Para nombrar un intervalo, además de contar semitonos, ¿qué debemos observar?', options: ['La distancia entre los nombres de las notas', 'La cuerda utilizada', 'La tonalidad del instrumento', 'La velocidad de ejecución'], correct: 'La distancia entre los nombres de las notas', explanation: 'Primero se determina el número (segunda, tercera, cuarta, etc.) contando nombres de nota; luego se determina la cualidad con los semitonos.' },
]

const questions = ref<Question[]>([])
const index = ref(0)
const chosen = ref('')
const checked = ref(false)
const score = ref(0)
const finished = ref(false)
const current = computed(() => questions.value[index.value])
const progress = computed(() => questions.value.length
  ? Math.round(((index.value + (checked.value ? 1 : 0)) / questions.value.length) * 100)
  : 0)
const shuffle = <T,>(items: T[]): T[] => [...items].sort(() => Math.random() - 0.5)

function start() {
  questions.value = shuffle(bank).slice(0, 8)
  index.value = 0
  chosen.value = ''
  checked.value = false
  score.value = 0
  finished.value = false
}
function check() {
  if (!current.value || !chosen.value || checked.value) return
  checked.value = true
  if (chosen.value === current.value.correct) score.value++
}
function next() {
  if (index.value + 1 >= questions.value.length) {
    finished.value = true
    return
  }
  index.value++
  chosen.value = ''
  checked.value = false
}
start()
</script>

<template>
  <section class="panel mb-4 p-3 sm:p-4">
    <div class="mb-3">
      <p class="eyebrow">Lectura musical · Fundamentos de armonía</p>
      <h2 class="text-lg font-black">Intervalos musicales</h2>
      <p class="mt-1 text-sm leading-5 text-[#788780]">
        Un intervalo es la distancia entre dos notas. Para identificarlo correctamente necesitamos dos datos: el número (segunda, tercera, cuarta…) y la cualidad (mayor, menor, justo, aumentado o disminuido).
      </p>
    </div>

    <div class="grid gap-2 sm:grid-cols-2">
      <div class="rounded-xl bg-[#edf4ee] p-3">
        <p class="text-sm font-black text-[#426c5b]">1. Cuenta los nombres</p>
        <p class="mt-1 text-xs leading-5 text-[#567267]">Do–Mi es una tercera: Do, Re, Mi. Se cuentan ambas notas, incluida la inicial.</p>
      </div>
      <div class="rounded-xl bg-[#edf4ee] p-3">
        <p class="text-sm font-black text-[#426c5b]">2. Cuenta los semitonos</p>
        <p class="mt-1 text-xs leading-5 text-[#567267]">Do–Mi tiene cuatro semitonos, por eso es una tercera mayor. Do–Mi♭ tiene tres y es menor.</p>
      </div>
    </div>

    <div class="mt-3 rounded-xl border border-[#dce7df] p-3">
      <div class="flex flex-wrap items-center justify-between gap-2">
        <div>
          <p class="eyebrow">Tabla de referencia</p>
          <h3 class="text-base font-black text-[#365c4c]">Intervalos simples</h3>
        </div>
        <select v-model="selectedFamily" class="rounded-lg border border-[#dce5dc] bg-white px-2.5 py-2 text-xs font-semibold text-[#365c4c]">
          <option>Todos</option>
          <option>Justos</option>
          <option>Segundos</option>
          <option>Terceros</option>
          <option>Aumentados / disminuidos</option>
          <option>Sextos</option>
          <option>Séptimos</option>
        </select>
      </div>
      <div class="mt-2 overflow-x-auto">
        <table class="w-full min-w-[390px] text-left text-xs">
          <thead>
            <tr class="border-b border-[#e5ebe4] text-[10px] uppercase tracking-wide text-[#829087]">
              <th class="px-2 py-2">Intervalo</th>
              <th class="px-2 py-2">Semitonos</th>
              <th class="px-2 py-2">Ejemplo desde Do</th>
            </tr>
          </thead>
          <tbody>
            <tr v-for="item in visibleIntervals" :key="item.name" class="border-b border-[#eef1ec]">
              <td class="px-2 py-2 font-bold text-[#365c4c]">{{ item.name }}</td>
              <td class="px-2 py-2 font-semibold text-[#567267]">{{ item.semitones }}</td>
              <td class="px-2 py-2 text-[#718078]">{{ item.example }}</td>
            </tr>
          </tbody>
        </table>
      </div>
      <p class="mt-2 text-[10px] leading-4 text-[#829087]">La cuarta aumentada (Do–Fa♯) y la quinta disminuida (Do–Sol♭) son enarmónicas: suenan con seis semitonos, aunque se escriben y nombran de forma diferente.</p>
    </div>

    <div class="mt-3 rounded-xl bg-[#f7f4ed] p-3">
      <p class="text-xs font-black text-[#426c5b]">Dos familias que debes recordar</p>
      <div class="mt-2 grid gap-2 sm:grid-cols-2">
        <div v-for="family in families" :key="family.name" class="rounded-lg bg-white p-2.5">
          <p class="text-xs font-bold text-[#365c4c]">{{ family.name }}</p>
          <p class="mt-1 text-[11px] leading-4 text-[#718078]">{{ family.description }}</p>
        </div>
      </div>
      <p class="mt-2 text-[11px] leading-5 text-[#718078]">Las segundas, terceras, sextas y séptimas se clasifican como mayores o menores. El unísono, la cuarta, la quinta y la octava pertenecen a la familia de los intervalos justos; también pueden modificarse y ser aumentados o disminuidos.</p>
    </div>

    <div class="mt-3 rounded-xl bg-[#f7f4ed] p-3">
      <template v-if="!finished">
        <div class="mb-3 flex items-center justify-between gap-2">
          <div>
            <p class="eyebrow">Comprueba lo aprendido</p>
            <h3 class="text-base font-black">Pregunta {{ index + 1 }} de {{ questions.length }}</h3>
          </div>
          <span class="rounded-full bg-white px-2.5 py-1 text-[11px] font-bold text-[#426c5b]">{{ score }} correctas</span>
        </div>
        <div class="mb-3 h-1.5 overflow-hidden rounded-full bg-[#e4e9e2]">
          <div class="h-full rounded-full bg-[#4c9c7c] transition-all" :style="{ width: progress + '%' }"></div>
        </div>
        <p class="text-sm font-bold leading-6 text-[#365c4c]">{{ current?.prompt }}</p>
        <div class="mt-3 grid gap-2 sm:grid-cols-2">
          <button
            v-for="option in current?.options"
            :key="option"
            class="rounded-lg border-2 bg-white px-3 py-2.5 text-left text-xs font-semibold transition"
            :class="checked && option === current?.correct ? 'border-[#4c9c7c] bg-[#edf4ee] text-[#226447]' : chosen === option ? 'border-[#8aa99a] bg-[#eef4ef]' : 'border-transparent'"
            :disabled="checked"
            @click="chosen = option"
          >
            {{ option }}
          </button>
        </div>
        <div v-if="checked" class="mt-3 rounded-lg p-3" :class="chosen === current?.correct ? 'bg-[#e9f5ed] text-[#226447]' : 'bg-[#fff1e9] text-[#a14f2d]'">
          <p class="flex items-center gap-1.5 text-xs font-black">
            <CheckCircle2 v-if="chosen === current?.correct" :size="15" />
            <XCircle v-else :size="15" />
            {{ chosen === current?.correct ? '¡Correcto!' : 'La respuesta correcta es: ' + current?.correct + '.' }}
          </p>
          <p class="mt-1 text-xs leading-5">{{ current?.explanation }}</p>
        </div>
        <div class="mt-3 flex justify-end">
          <button v-if="!checked" class="primary px-4 py-2 text-xs" :disabled="!chosen" @click="check">Comprobar</button>
          <button v-else class="primary flex items-center gap-1.5 px-4 py-2 text-xs" @click="next">
            {{ index + 1 === questions.length ? 'Ver resultado' : 'Siguiente' }} <ArrowRight :size="14" />
          </button>
        </div>
      </template>
      <div v-else class="py-3 text-center">
        <p class="eyebrow">Práctica terminada</p>
        <h3 class="mt-1 text-2xl font-black text-[#365c4c]">{{ score }} / {{ questions.length }}</h3>
        <p class="mt-2 text-sm text-[#718078]">{{ score >= 7 ? '¡Muy bien! Reconoces los intervalos y sus distancias.' : 'Repasa la relación entre número de intervalo y semitonos, y vuelve a intentarlo.' }}</p>
        <button class="primary mt-4 inline-flex items-center gap-2 px-4 py-2 text-xs" @click="start">
          <RotateCcw :size="14" /> Repetir práctica
        </button>
      </div>
    </div>
  </section>
</template>
