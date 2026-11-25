<script setup lang="ts">
import { fretMidi } from '../engines/guitar/fretboard'
import { midiName } from '../engines/music/pitch'

interface FretPosition {
  string: number
  fret: number
  midi: number
}

const props = withDefaults(
  defineProps<{
    selected: { string: number; fret: number } | null
    disabled?: boolean
  }>(),
  { selected: null, disabled: false },
)

const emit = defineEmits<{
  (event: 'select', position: FretPosition): void
}>()

const strings = [6, 5, 4, 3, 2, 1]
const frets = [0, 1, 2, 3, 4, 5]
const yy = (index: number) => 35 + index * 35
const xx = (fret: number) => (fret === 0 ? 38 : 38 + fret * 112)

function pick(string: number, fret: number) {
  if (props.disabled) return
  emit('select', { string, fret, midi: fretMidi(string, fret) })
}
</script>

<template><div class="w-full overflow-x-auto"><svg viewBox="0 0 650 250" class="mx-auto block w-full min-w-[310px]" role="img" aria-label="Diapasón interactivo de guitarra"><rect x="27" y="17" width="594" height="207" rx="12" fill="#f5ead8"/><rect x="27" y="17" width="12" height="207" rx="3" fill="#8a6748"/><g stroke="#b99b76" stroke-width="2"><path v-for="f in frets.slice(1)" :key="f" :d="'M '+xx(f)+' 18 V 223'"/></g><g fill="#806b55" font-size="12" text-anchor="middle"><text v-for="f in frets" :key="f" :x="f===0?38:xx(f)-56" y="12">{{f}}</text></g><g v-for="(s,i) in strings" :key="s"><path :d="'M 27 '+yy(i)+' H 621" stroke="#a6a69c" :stroke-width="(s === 1 || s === 6) ? 2.8 : 1.6"/><text x="14" :y="yy(i)+4" font-size="11" fill="#68766e" text-anchor="middle">{{s}}</text><g v-for="f in frets" :key="f"><circle v-if="selected && selected.string === s && selected.fret === f" :cx="f===0?38:xx(f)-56" :cy="yy(i)" r="13" fill="#176b5b" stroke="white" stroke-width="2"/><rect :x="f===0?25:xx(f)-105" :y="yy(i)-15" :width="f===0?26:110" height="30" fill="transparent" @click="pick(s,f)"/></g></g><g fill="#8d795f"><circle cx="206" cy="129" r="4"/><circle cx="430" cy="129" r="4"/></g></svg></div><p v-if="selected" class="mt-2 text-center text-sm font-bold text-[#176b5b]">Cuerda {{selected.string}} · Traste {{selected.fret}} · {{midiName(fretMidi(selected.string,selected.fret)).name}}{{midiName(fretMidi(selected.string,selected.fret)).octave}}</p></template>
