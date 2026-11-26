<script setup lang="ts">
import { defineAsyncComponent, ref } from 'vue'
import { Upload, FileMusic } from 'lucide-vue-next'

const Viewer = defineAsyncComponent(() => import('../components/AlphaTabViewer.vue'))
const file = ref<File | null>(null)
const error = ref('')

function choose(event: Event) {
  const selected = (event.target as HTMLInputElement).files?.[0]
  error.value = ''
  if (!selected) return
  if (!/\.(xml|musicxml|mxl)$/i.test(selected.name)) {
    error.value = 'Selecciona un archivo .xml, .musicxml o .mxl'
    return
  }
  file.value = selected
}
</script>

<template>
  <div class="page">
    <div class="mb-6">
      <p class="eyebrow">Lectura y escucha musical</p>
      <h1 class="mt-1 text-3xl font-black">Mis partituras</h1>
      <p class="mt-2 text-sm text-[#788780]">
        Abre una partitura MusicXML y escúchala con el cursor sincronizado.
      </p>
    </div>

    <section class="panel p-5 sm:p-7">
      <label class="flex min-h-[170px] cursor-pointer flex-col items-center justify-center rounded-2xl border-2 border-dashed border-[#cbd9ce] bg-[#f7faf6] p-6 text-center">
        <span class="mb-3 grid h-12 w-12 place-items-center rounded-2xl bg-[#e7f1e8] text-[#36785e]">
          <Upload />
        </span>
        <b>Selecciona tu archivo</b>
        <span class="mt-1 text-sm text-[#849087]">XML, MusicXML o MXL desde tu dispositivo</span>
        <input class="sr-only" type="file" accept=".xml,.musicxml,.mxl" @change="choose">
      </label>
      <p v-if="error" class="mt-3 text-sm text-red-600">{{ error }}</p>
      <p v-if="file" class="mt-3 flex items-center gap-2 text-sm font-semibold text-[#34785d]">
        <FileMusic :size="17" /> {{ file.name }}
      </p>
    </section>

    <section v-if="file" class="panel mt-5 overflow-hidden p-3 sm:p-5">
      <Viewer :file="file" />
    </section>
    <p v-else class="mt-5 rounded-2xl bg-[#eef3ef] p-4 text-sm leading-6 text-[#65776d]">
      El motor musical se carga únicamente al abrir una partitura para mantener ligera la aplicación.
      El sonido inicial utiliza el SoundFont compacto SONiVOX incluido con alphaTab.
    </p>
  </div>
</template>
