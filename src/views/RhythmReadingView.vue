<script setup lang="ts">
import { computed, onUnmounted, ref } from 'vue'
import { Activity, CheckCircle2, Play, RotateCcw, Volume2 } from 'lucide-vue-next'
import { playRhythm, type RhythmEvent } from '../engines/audio/rhythmSound'

const storageKey = 'guitar-tutor-rhythm-progress-v1'
const completed = ref(localStorage.getItem(storageKey) === 'completed')
const bpm = ref(80)
const meter = ref(4)
const playing = ref(false)
const activeUnit = ref(-1)
const stage = ref(0)
const answer = ref('')
const feedback = ref('')
let stopPlayback: (() => void) | null = null

const pattern: RhythmEvent[] = [
  { label: 'Negra', units: 2 },
  { label: 'Negra', units: 2 },
  { label: 'Corchea', units: 1 },
  { label: 'Corchea', units: 1 },
  { label: 'Negra', units: 2 },
]
const extraLessons = [
  { title: 'Negras y silencios', description: 'Combina sonidos y pausas. Cuando aparece un silencio de negra, mantén el pulso, pero no des ninguna palmada.', pattern: [{label:'Negra',units:2},{label:'Silencio',units:2,rest:true},{label:'Negra',units:2},{label:'Silencio',units:2,rest:true}], question: '¿Qué debes hacer durante un silencio de negra?', options: ['Detener el pulso','Mantener el pulso sin sonar','Acelerar'], correct: 'Mantener el pulso sin sonar', explanation: '¡Exacto! El silencio ocupa un pulso igual que la negra, pero no produce sonido.' },
  { title: 'Corcheas y subdivisión', description: 'Una negra puede dividirse en dos partes iguales: dos corcheas. Cuenta «1 y 2 y 3 y 4 y» y procura que todas las subdivisiones sean regulares.', pattern: [{label:'Corchea',units:1},{label:'Corchea',units:1},{label:'Corchea',units:1},{label:'Corchea',units:1},{label:'Negra',units:2},{label:'Corchea',units:1},{label:'Corchea',units:1},{label:'Negra',units:2}], question: '¿Cuántas corcheas equivalen a una negra?', options: ['Una','Dos','Cuatro'], correct: 'Dos', explanation: '¡Correcto! Dos corcheas tienen la misma duración que una negra.' },
  { title: 'Blancas y redondas', description: 'La blanca dura dos pulsos y la redonda cuatro. Aprende a sostener el sonido durante toda su duración, sin adelantar la siguiente figura.', pattern: [{label:'Blanca',units:4},{label:'Blanca',units:4}], question: '¿Cuántos pulsos dura una blanca?', options: ['1 pulso','2 pulsos','4 pulsos'], correct: '2 pulsos', explanation: '¡Muy bien! La blanca dura dos pulsos; la redonda dura cuatro.' },
  { title: 'Lectura combinada', description: 'Combina negras, corcheas, blancas y silencios. Lee de izquierda a derecha y conserva siempre el pulso interno.', pattern: [{label:'Negra',units:2},{label:'Corchea',units:1},{label:'Corchea',units:1},{label:'Silencio',units:2,rest:true},{label:'Negra',units:2}], question: '¿Cuántas unidades de corchea forman una blanca?', options: ['2','3','4'], correct: '4', explanation: '¡Excelente! Una blanca dura dos negras, es decir, cuatro corcheas.' }
]
const activePattern = computed(() => stage.value >= 3 ? extraLessons[stage.value - 3].pattern : pattern)
const totalUnits = computed(() => activePattern.value.reduce((sum, event) => sum + event.units, 0))
const positions = computed(() => {
  const result: { label: string; symbol: string; start: number; units: number; rest: boolean }[] = []
  let start = 0
  for (const event of activePattern.value) {
    result.push({
      label: event.label,
      symbol: event.label === 'Negra' ? '♩' : event.label === 'Corchea' ? '♪' : event.label === 'Blanca' ? '𝅗𝅥' : event.label === 'Silencio' ? '𝄽' : '𝅝',
      start,
      units: event.units,
      rest: !!event.rest,
    })
    start += event.units
  }
  return result
})
const stages = ['El pulso', 'Figuras y silencios', 'Primer patrón', ...extraLessons.map(lesson => lesson.title)]

function play() {
  stop()
  playing.value = true
  activeUnit.value = -1
  const events = stage.value === 0
    ? Array.from({ length: meter.value }, () => ({ label: 'Negra', units: 2 }))
    : activePattern.value
  stopPlayback = playRhythm(events, bpm.value, stage.value === 0 ? meter.value : 4, unit => {
    activeUnit.value = unit
  }, () => {
    playing.value = false
    activeUnit.value = -1
    stopPlayback = null
  }, stage.value === 0)
}
function stop() {
  stopPlayback?.()
  stopPlayback = null
  playing.value = false
  activeUnit.value = -1
}
function checkAnswer(value: string) {
  answer.value = value
  const correct = stage.value >= 3 ? extraLessons[stage.value - 3].correct : '1 pulso'
  feedback.value = value === correct
    ? (stage.value >= 3 ? extraLessons[stage.value - 3].explanation : '¡Correcto! La negra ocupa un pulso en estos compases.')
    : 'Inténtalo otra vez. Revisa la duración de la figura y vuelve a escuchar.'
}
function finish() {
  completed.value = true
  localStorage.setItem(storageKey, 'completed')
}
function reset() {
  completed.value = false
  localStorage.removeItem(storageKey)
  stage.value = 0
  answer.value = ''
  feedback.value = ''
}
onUnmounted(stop)
</script>

<template>
  <div class="page">
    <div class="mb-6 flex items-center gap-3">
      <span class="grid h-12 w-12 place-items-center rounded-2xl bg-[#e8f2eb] text-[#26745a]"><Activity :size="25"/></span>
      <div><p class="eyebrow">Módulo 04 · Ritmo</p><h1 class="text-2xl font-black sm:text-3xl">Lectura rítmica</h1></div>
    </div>

    <section class="panel p-5 sm:p-7">
      <div class="flex flex-wrap items-start justify-between gap-3">
        <div><p class="text-sm font-bold text-[#648174]">Aprende paso a paso</p><h2 class="mt-1 text-xl font-black">{{stages[stage]}}</h2></div>
        <span class="rounded-full bg-[#edf4ee] px-3 py-1 text-xs font-bold text-[#34745b]">{{stage === 0 ? 'Fundamentos' : `Lección ${stage + 1} de ${stages.length}`}}</span>
      </div>
      <div class="mt-5 flex gap-2" aria-label="Progreso de la lección">
        <span v-for="(item, index) in stages" :key="item" class="h-1.5 flex-1 rounded-full" :class="index <= stage ? 'bg-[#398568]' : 'bg-[#e8eee9]'"/>
      </div>

      <div v-if="stage === 0" class="mt-6">
        <p class="text-sm leading-6 text-[#687970]">El pulso es el latido regular de la música. Primero escucha el metrónomo y acompáñalo con palmadas, sin preocuparte todavía por las notas.</p>
        <div class="mt-5 grid gap-4 sm:grid-cols-[1fr_auto] sm:items-end">
          <label class="block"><span class="text-sm font-bold">Velocidad: {{bpm}} BPM</span><input v-model.number="bpm" type="range" min="40" max="160" step="1" class="mt-3 w-full accent-[#28785e]"></label>
          <label class="block"><span class="mb-2 block text-sm font-bold">Compás</span><select v-model.number="meter" class="w-full rounded-xl border border-[#dce6de] bg-white px-4 py-3 sm:w-32"><option :value="2">2/4</option><option :value="3">3/4</option><option :value="4">4/4</option></select></label>
        </div>
        <div class="mt-5 rounded-2xl bg-[#f3f7f3] p-5">
          <div class="flex items-center justify-center gap-3">
            <span v-for="beat in meter" :key="beat" class="grid h-12 w-12 place-items-center rounded-full text-lg font-black transition" :class="activeUnit >= (beat-1)*2 && activeUnit < beat*2 ? 'scale-110 bg-[#26765b] text-white' : 'bg-white text-[#527264]'">{{beat}}</span>
          </div>
          <div class="mt-4 flex justify-center"><button class="primary min-w-32 justify-center" @click="playing ? stop() : play()"><component :is="playing ? RotateCcw : Play" :size="17"/>{{playing ? 'Detener' : 'Escuchar pulso'}}</button></div>
          <p class="mt-3 text-center text-xs text-[#7b8981]">Sigue los números y marca cada pulso con una palmada.</p>
        </div>
      </div>

      <div v-else-if="stage === 1" class="mt-6">
        <p class="text-sm leading-6 text-[#687970]">Las figuras indican cuánto dura un sonido. En esta primera lección trabajaremos con redonda, blanca, negra y corchea. Los silencios tienen la misma duración que sus figuras equivalentes.</p>
        <div class="mt-5 grid grid-cols-2 gap-3 sm:grid-cols-4">
          <div v-for="figure in [{symbol:'𝅝',name:'Redonda',value:'4 pulsos'},{symbol:'𝅗𝅥',name:'Blanca',value:'2 pulsos'},{symbol:'♩',name:'Negra',value:'1 pulso'},{symbol:'♪',name:'Corchea',value:'½ pulso'}]" :key="figure.name" class="rounded-2xl border border-[#e5ece6] bg-[#fbfcfa] p-4 text-center">
            <div class="text-4xl text-[#244d3e]">{{figure.symbol}}</div><p class="mt-2 font-extrabold">{{figure.name}}</p><p class="mt-1 text-xs text-[#7a8980]">{{figure.value}}</p>
          </div>
        </div>
        <h3 class="mt-6 font-extrabold">Y estos son sus silencios</h3>
        <div class="mt-3 grid grid-cols-2 gap-3 sm:grid-cols-4">
          <div v-for="rest in [{symbol:'𝄻',name:'Silencio de redonda',value:'4 pulsos'},{symbol:'𝄼',name:'Silencio de blanca',value:'2 pulsos'},{symbol:'𝄽',name:'Silencio de negra',value:'1 pulso'},{symbol:'𝄾',name:'Silencio de corchea',value:'½ pulso'}]" :key="rest.name" class="rounded-2xl bg-[#f3f7f3] p-3 text-center">
            <div class="text-3xl">{{rest.symbol}}</div><p class="mt-2 text-xs font-bold">{{rest.name}}</p><p class="mt-1 text-xs text-[#7a8980]">{{rest.value}}</p>
          </div>
        </div>
        <div class="mt-5 rounded-xl bg-[#fff8e9] p-4 text-sm leading-6 text-[#78633a]"><strong>Recuerda:</strong> dos corcheas equivalen a una negra. Puedes contar «1 y 2 y» para sentir la subdivisión.</div>
        <div class="mt-5 flex items-center gap-2 text-sm text-[#64766c]"><Volume2 :size="17"/> Escucha el patrón de ejemplo en la siguiente etapa.</div>
      </div>

      <div v-else-if="stage === 2" class="mt-6">
        <p class="text-sm leading-6 text-[#687970]">Observa este compás de 4/4. Cada casilla pequeña representa media pulsación. Escucha el patrón y sigue el resaltado de izquierda a derecha.</p>
        <div class="mt-5 rounded-2xl bg-[#f3f7f3] p-4 sm:p-6">
          <div class="flex justify-center gap-1">
            <div v-for="(event, index) in positions" :key="index" class="flex h-20 min-w-0 flex-col items-center justify-center rounded-xl border transition" :style="{ flex: event.units }" :class="activeUnit >= event.start && activeUnit < event.start + event.units ? 'border-[#28785e] bg-[#d8eee0]' : 'border-[#e3ebe4] bg-white'">
              <span class="text-3xl font-semibold">{{event.symbol}}</span>
              <span class="mt-1 text-[10px] text-[#7c8982]">{{event.label}}</span>
            </div>
          </div>
          <div class="mt-4 flex flex-wrap items-center justify-between gap-3">
            <label class="flex items-center gap-2 text-sm font-bold">Tempo <input v-model.number="bpm" type="number" min="40" max="160" class="w-20 rounded-lg border border-[#dce6de] px-2 py-1.5"></label>
            <button class="primary min-w-32 justify-center" @click="playing ? stop() : play()"><component :is="playing ? RotateCcw : Play" :size="17"/>{{playing ? 'Detener' : 'Reproducir'}}</button>
          </div>
        </div>
        <div class="mt-4 flex flex-wrap justify-center gap-2 text-sm">
          <span class="rounded-lg bg-[#edf4ee] px-3 py-2 font-bold">1</span><span class="rounded-lg bg-[#edf4ee] px-3 py-2 font-bold">2</span><span class="rounded-lg bg-[#edf4ee] px-3 py-2 font-bold">3 y</span><span class="rounded-lg bg-[#edf4ee] px-3 py-2 font-bold">4</span>
        </div>
        <div class="mt-6 rounded-2xl border border-[#e5ece6] p-4">
          <p class="font-extrabold">Comprueba lo aprendido</p>
          <p class="mt-2 text-sm text-[#687970]">¿Cuánto dura una negra en un compás de 4/4?</p>
          <div class="mt-3 flex flex-wrap gap-2">
            <button v-for="option in ['½ pulso','1 pulso','2 pulsos']" :key="option" class="rounded-xl border px-4 py-2 text-sm font-bold transition" :class="answer === option ? 'border-[#28785e] bg-[#eaf4ed] text-[#23664d]' : 'border-[#e1e9e2]'" @click="checkAnswer(option)">{{option}}</button>
          </div>
          <p v-if="feedback" class="mt-3 text-sm font-semibold" :class="answer === '1 pulso' ? 'text-[#28785e]' : 'text-[#9b6a2d]'">{{feedback}}</p>
        </div>
        <div v-if="answer === '1 pulso' && stage === 2" class="mt-4 rounded-xl bg-[#eaf4ed] p-4"><p class="font-bold text-[#23664d]">¡Muy bien! Continúa con las siguientes lecciones para completar el módulo.</p></div>
      </div>

      <div v-else class="mt-6">
        <p class="text-sm leading-6 text-[#687970]">{{extraLessons[stage - 3].description}}</p>
        <div class="mt-5 rounded-2xl bg-[#f3f7f3] p-4 sm:p-6">
          <div class="flex justify-center gap-1">
            <div v-for="(event, index) in positions" :key="index" class="flex h-20 min-w-0 flex-col items-center justify-center rounded-xl border transition" :style="{ flex: event.units }" :class="activeUnit >= event.start && activeUnit < event.start + event.units ? 'border-[#28785e] bg-[#d8eee0]' : 'border-[#e3ebe4] bg-white'">
              <span class="text-3xl font-semibold">{{event.symbol}}</span><span class="mt-1 text-[10px] text-[#7c8982]">{{event.label}}</span>
            </div>
          </div>
          <div class="mt-4 flex flex-wrap items-center justify-between gap-3">
            <label class="flex items-center gap-2 text-sm font-bold">Tempo <input v-model.number="bpm" type="number" min="40" max="160" class="w-20 rounded-lg border border-[#dce6de] px-2 py-1.5"></label>
            <button class="primary min-w-32 justify-center" @click="playing ? stop() : play()"><component :is="playing ? RotateCcw : Play" :size="17"/>{{playing ? 'Detener' : 'Reproducir'}}</button>
          </div>
        </div>
        <div class="mt-6 rounded-2xl border border-[#e5ece6] p-4">
          <p class="font-extrabold">Comprueba lo aprendido</p><p class="mt-2 text-sm text-[#687970]">{{extraLessons[stage - 3].question}}</p>
          <div class="mt-3 flex flex-wrap gap-2">
            <button v-for="option in extraLessons[stage - 3].options" :key="option" class="rounded-xl border px-4 py-2 text-sm font-bold transition" :class="answer === option ? 'border-[#28785e] bg-[#eaf4ed] text-[#23664d]' : 'border-[#e1e9e2]'" @click="checkAnswer(option)">{{option}}</button>
          </div>
          <p v-if="feedback" class="mt-3 text-sm font-semibold" :class="answer === extraLessons[stage - 3].correct ? 'text-[#28785e]' : 'text-[#9b6a2d]'">{{feedback}}</p>
        </div>
        <div v-if="answer === extraLessons[stage - 3].correct && stage === stages.length - 1" class="mt-4 rounded-xl bg-[#eaf4ed] p-4">
          <p class="font-bold text-[#23664d]">¡Excelente trabajo! Has completado el recorrido de lectura rítmica.</p>
          <button class="mt-3 rounded-xl bg-[#26765b] px-4 py-2.5 text-sm font-bold text-white" @click="finish">Completar módulo</button>
        </div>
      </div>

      <div class="mt-7 flex flex-wrap items-center justify-between gap-3 border-t border-[#edf1ed] pt-5">
        <button class="secondary" :disabled="stage === 0" @click="stage--; answer=''; feedback=''">Anterior</button>
        <button v-if="stage < stages.length - 1" class="primary" @click="stop(); stage++; answer=''; feedback=''">Continuar</button>
        <span v-else-if="completed" class="inline-flex items-center gap-2 text-sm font-bold text-[#28785e]"><CheckCircle2 :size="18"/> Lección completada</span>
      </div>
    </section>

    <div class="mt-4 flex items-center justify-between gap-3 text-xs text-[#819087]">
      <span>El avance rítmico se guarda por separado de los demás módulos.</span>
      <button v-if="completed" class="inline-flex shrink-0 items-center gap-1 font-bold text-[#527264]" @click="reset"><RotateCcw :size="13"/> Reiniciar</button>
    </div>
  </div>
</template>
