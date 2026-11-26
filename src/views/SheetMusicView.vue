<script setup lang="ts">
import { defineAsyncComponent, onMounted, ref } from 'vue'
import { Upload, FileMusic, Trash2, Library, LoaderCircle } from 'lucide-vue-next'
import { deleteScore, listScores, saveScore, getScore, type ScoreRecord } from '../services/scoreLibrary'

const Viewer = defineAsyncComponent(() => import('../components/AlphaTabViewer.vue'))
const file = ref<File | null>(null)
const activeScoreId = ref<string | null>(null)
const scores = ref<ScoreRecord[]>([])
const error = ref('')
const saving = ref(false)
const openingId = ref<string | null>(null)

async function refreshLibrary() {
  try {
    scores.value = await listScores()
  } catch {
    error.value = 'No se pudo acceder a la biblioteca de este navegador.'
  }
}

async function choose(event: Event) {
  const input = event.target as HTMLInputElement
  const selected = input.files?.[0]
  error.value = ''
  if (!selected) return
  if (!/\.(xml|musicxml|mxl)$/i.test(selected.name)) {
    error.value = 'Selecciona un archivo .xml, .musicxml o .mxl'
    input.value = ''
    return
  }

  file.value = selected
  activeScoreId.value = null
  saving.value = true
  try {
    const saved = await saveScore(selected)
    activeScoreId.value = saved.id
    await refreshLibrary()
  } catch (cause) {
    error.value = cause instanceof Error
      ? `La partitura se abrió, pero no se pudo guardar: ${cause.message}`
      : 'La partitura se abrió, pero no se pudo guardar en la biblioteca.'
  } finally {
    saving.value = false
    input.value = ''
  }
}

async function openSavedScore(id: string) {
  openingId.value = id
  error.value = ''
  try {
    const record = await getScore(id)
    if (!record) throw new Error('No se encontró el archivo guardado.')
    file.value = new File([record.blob], record.name, {
      type: record.type || 'application/xml',
      lastModified: record.lastModified,
    })
    activeScoreId.value = record.id
  } catch (cause) {
    error.value = cause instanceof Error ? cause.message : 'No se pudo abrir la partitura.'
  } finally {
    openingId.value = null
  }
}

async function removeScore(id: string) {
  try {
    await deleteScore(id)
    if (activeScoreId.value === id) {
      file.value = null
      activeScoreId.value = null
    }
    await refreshLibrary()
  } catch {
    error.value = 'No se pudo eliminar la partitura de la biblioteca.'
  }
}

function formatSize(bytes: number) {
  if (bytes < 1024) return `${bytes} B`
  if (bytes < 1024 * 1024) return `${(bytes / 1024).toFixed(1)} KB`
  return `${(bytes / (1024 * 1024)).toFixed(1)} MB`
}

onMounted(refreshLibrary)
</script>

<template>
  <div class="page">
    <div class="mb-6">
      <p class="eyebrow">Lectura y escucha musical</p>
      <h1 class="mt-1 text-3xl font-black">Mis partituras</h1>
      <p class="mt-2 text-sm text-[#788780]">
        Tu biblioteca de partituras MusicXML, disponible en este navegador.
      </p>
    </div>

    <section class="panel p-5 sm:p-7">
      <label class="flex min-h-[150px] cursor-pointer flex-col items-center justify-center rounded-2xl border-2 border-dashed border-[#cbd9ce] bg-[#f7faf6] p-6 text-center">
        <span class="mb-3 grid h-12 w-12 place-items-center rounded-2xl bg-[#e7f1e8] text-[#36785e]">
          <Upload />
        </span>
        <b>Agregar una partitura</b>
        <span class="mt-1 text-sm text-[#849087]">XML, MusicXML o MXL desde tu dispositivo</span>
        <input class="sr-only" type="file" accept=".xml,.musicxml,.mxl" @change="choose">
      </label>
      <p v-if="saving" class="mt-3 flex items-center gap-2 text-sm text-[#34785d]">
        <LoaderCircle :size="16" class="animate-spin" /> Guardando en tu biblioteca…
      </p>
      <p v-if="error" class="mt-3 text-sm text-red-600">{{ error }}</p>
    </section>

    <section class="panel mt-5 p-5 sm:p-6">
      <div class="mb-4 flex items-center gap-2">
        <Library :size="19" class="text-[#43866a]" />
        <h2 class="text-lg font-bold">Biblioteca</h2>
        <span class="ml-auto rounded-full bg-[#edf3ed] px-2.5 py-1 text-xs font-semibold text-[#60766a]">{{ scores.length }}</span>
      </div>
      <div v-if="scores.length" class="divide-y divide-[#edf1ec]">
        <div v-for="score in scores" :key="score.id" class="flex items-center gap-3 py-3 first:pt-0 last:pb-0">
          <span class="grid h-10 w-10 shrink-0 place-items-center rounded-xl bg-[#eef4ef] text-[#43866a]">
            <FileMusic :size="19" />
          </span>
          <div class="min-w-0 flex-1">
            <p class="truncate text-sm font-semibold text-[#34483c]">{{ score.name }}</p>
            <p class="mt-0.5 text-xs text-[#87938a]">{{ formatSize(score.size) }} · {{ new Date(score.savedAt).toLocaleDateString() }}</p>
          </div>
          <button class="primary shrink-0" :disabled="openingId === score.id" @click="openSavedScore(score.id)">
            {{ openingId === score.id ? 'Abriendo…' : 'Abrir' }}
          </button>
          <button class="secondary shrink-0" title="Eliminar de la biblioteca" aria-label="Eliminar partitura" @click="removeScore(score.id)">
            <Trash2 :size="16" />
          </button>
        </div>
      </div>
      <p v-else class="rounded-xl bg-[#f5f8f5] p-4 text-sm leading-6 text-[#788780]">
        Todavía no hay partituras guardadas. Cuando agregues un archivo, aparecerá aquí automáticamente.
      </p>
      <p class="mt-4 text-xs leading-5 text-[#8a968e]">
        Los archivos se guardan en el almacenamiento local de este navegador y dispositivo. No se sincronizan con otros equipos.
      </p>
    </section>

    <section v-if="file" class="panel mt-5 overflow-hidden p-3 sm:p-5">
      <Viewer :key="activeScoreId || file.name" :file="file" />
    </section>
    <p v-else class="mt-5 rounded-2xl bg-[#eef3ef] p-4 text-sm leading-6 text-[#65776d]">
      El reproductor se carga al abrir una partitura. Puedes volver a abrir cualquier archivo de tu biblioteca cuando lo necesites.
    </p>
  </div>
</template>
