<script setup lang="ts">
import { onBeforeUnmount, onMounted, ref, watch } from 'vue'
import * as alphaTab from '@coderline/alphatab'
import { Pause, Play, RotateCcw, Volume2 } from 'lucide-vue-next'

const props = defineProps<{ file: File }>()
const host = ref<HTMLDivElement | null>(null)
const loadingScore = ref(true)
const playerReady = ref(false)
const isPlaying = ref(false)
const error = ref('')
const loadProgress = ref(0)
const scoreTitle = ref('')
let api: any = null
let disposed = false

async function loadScore() {
  if (!host.value) return

  loadingScore.value = true
  playerReady.value = false
  isPlaying.value = false
  error.value = ''
  loadProgress.value = 0
  scoreTitle.value = ''

  try {
    if (api) {
      api.destroy()
      api = null
    }
    host.value.innerHTML = ''

    const settings = {
      core: {
        fontDirectory: `${import.meta.env.BASE_URL}font/`,
      },
      player: {
        enablePlayer: true,
        soundFont: `${import.meta.env.BASE_URL}soundfont/sonivox.sf2`,
        scrollElement: host.value,
      },
    }

    api = new alphaTab.AlphaTabApi(host.value, settings)
    api.playerReady.on(() => {
      if (!disposed) playerReady.value = true
    })
    api.scoreLoaded.on((score: any) => {
      if (!disposed) {
        scoreTitle.value = score.title || props.file.name
        loadingScore.value = false
      }
    })
    // alphaTab names this event playerFinished (not playbackFinished).
    api.playerFinished.on(() => {
      if (!disposed) isPlaying.value = false
    })
    api.soundFontLoad?.on((event: any) => {
      if (!disposed && event.total > 0) {
        loadProgress.value = Math.round((event.loaded / event.total) * 100)
      }
    })

    const bytes = new Uint8Array(await props.file.arrayBuffer())
    if (disposed) return

    // MusicXML plain text exposes its parts; load them all instead of only the first staff.
    let trackIndexes: number[] | undefined
    if (/\\.(xml|musicxml)$/i.test(props.file.name)) {
      const xmlText = new TextDecoder().decode(bytes)
      const xmlDocument = new DOMParser().parseFromString(xmlText, 'application/xml')
      const partCount = xmlDocument.querySelectorAll('part-list > score-part').length
      if (partCount > 1) {
        trackIndexes = Array.from({ length: partCount }, (_, index) => index)
      }
    }

    const accepted = api.load(bytes, trackIndexes)
    if (!accepted) throw new Error('AlphaTab no reconoció el contenido del archivo.')
  } catch (cause) {
    error.value = cause instanceof Error ? cause.message : 'No se pudo abrir la partitura.'
    loadingScore.value = false
  }
}

function togglePlayback() {
  if (!api || !playerReady.value) return
  if (isPlaying.value) {
    api.pause()
    isPlaying.value = false
  } else if (api.play()) {
    isPlaying.value = true
  }
}

function stopPlayback() {
  if (!api) return
  api.stop()
  isPlaying.value = false
}

onMounted(loadScore)
watch(() => props.file, loadScore)
onBeforeUnmount(() => {
  disposed = true
  if (api) {
    api.destroy()
    api = null
  }
})
</script>

<template>
  <div class="space-y-4">
    <div class="flex flex-wrap items-center justify-between gap-3">
      <div class="min-w-0">
        <p class="truncate text-sm font-bold text-[#52685c]">{{ scoreTitle || file.name }}</p>
        <p class="mt-1 text-xs text-[#829087]">Partitura MusicXML</p>
      </div>
      <div class="flex items-center gap-2">
        <button
          class="primary disabled:cursor-not-allowed disabled:opacity-45"
          :disabled="!playerReady"
          @click="togglePlayback"
        >
          <Pause v-if="isPlaying" :size="17" />
          <Play v-else :size="17" />
          {{ isPlaying ? 'Pausar' : 'Reproducir' }}
        </button>
        <button class="secondary" :disabled="!playerReady" aria-label="Detener" @click="stopPlayback">
          <RotateCcw :size="17" />
        </button>
      </div>
    </div>

    <div v-if="loadingScore" class="rounded-xl bg-[#f2f6f2] px-4 py-3 text-sm text-[#63776b]">
      <div class="flex items-center gap-2">
        <Volume2 :size="16" />
        <span>Cargando partitura y preparando el sonido…</span>
      </div>
      <div v-if="loadProgress > 0" class="mt-2 h-1.5 overflow-hidden rounded-full bg-[#dce8de]">
        <div class="h-full rounded-full bg-[#43866a]" :style="{ width: loadProgress + '%' }" />
      </div>
    </div>
    <p v-if="!loadingScore && !playerReady && !error" class="rounded-xl bg-[#f2f6f2] p-3 text-sm text-[#63776b]">
      La partitura está abierta. El reproductor está preparando el instrumento…
    </p>
    <p v-if="error" class="rounded-xl bg-red-50 p-4 text-sm text-red-700">{{ error }}</p>

    <div ref="host" class="alpha-tab-host max-w-full overflow-x-auto rounded-xl bg-white" />

    <div class="flex flex-wrap items-center justify-between gap-2 border-t border-[#edf1ec] pt-3">
      <p class="text-xs text-[#829087]">El cursor sigue la música durante la reproducción.</p>
      <a
        href="https://alphatab.net"
        target="_blank"
        rel="noopener noreferrer"
        class="text-xs font-semibold text-[#638174] underline underline-offset-2"
      >Powered by alphaTab</a>
    </div>
  </div>
</template>

<style>
.alpha-tab-host .at-cursor-bar {
  background: rgb(182 229 199 / 28%);
}
.alpha-tab-host .at-cursor-beat {
  width: 3px;
  background: #176b5b;
}
.alpha-tab-host .at-highlight * {
  fill: #176b5b;
  stroke: #176b5b;
}
.alpha-tab-host svg {
  max-width: 100%;
  height: auto;
}
</style>
