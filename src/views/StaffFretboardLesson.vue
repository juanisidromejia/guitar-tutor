<script setup lang="ts">
import StaffAccidentalsIntro from '../components/StaffAccidentalsIntro.vue'
import StaffMeasureAccidentals from '../components/StaffMeasureAccidentals.vue'
import StaffAccidentalMelody from '../components/StaffAccidentalMelody.vue'
import StaffKeySignatureIntro from '../components/StaffKeySignatureIntro.vue'
import StaffKeySignaturePractice from '../components/StaffKeySignaturePractice.vue'
import StaffKeySignatureAdvanced from '../components/StaffKeySignatureAdvanced.vue'
import StaffKeySignatureComplete from '../components/StaffKeySignatureComplete.vue'
import StaffKeySignatureReview from '../components/StaffKeySignatureReview.vue'
import StaffRelativeKeys from '../components/StaffRelativeKeys.vue'
import StaffMinorScales from '../components/StaffMinorScales.vue'
import StaffIntervals from '../components/StaffIntervals.vue'
import StaffTriads from '../components/StaffTriads.vue'
import StaffTriadInversions from '../components/StaffTriadInversions.vue'
import StaffMelodyReading from '../components/StaffMelodyReading.vue'
</script>

<template>
  <div class="page">
    <div class="mb-3">
      <p class="eyebrow">Lectura musical · Pentagrama y guitarra</p>
      <h1 class="mt-0.5 text-xl font-black">Notas en el pentagrama</h1>
      <p class="mt-0.5 max-w-2xl text-xs leading-4 text-[#788780]">
        Aprende a leer las notas, comprender las alteraciones y reconocer cómo se ubican en el instrumento.
      </p>
    </div>

    <StaffMelodyReading />
    <StaffAccidentalsIntro />
    <StaffMeasureAccidentals />
    <StaffAccidentalMelody />
    <StaffKeySignatureIntro />
    <StaffKeySignaturePractice />
    <StaffKeySignatureAdvanced />
    <StaffKeySignatureComplete />
    <StaffKeySignatureReview />
    <StaffRelativeKeys />
    <StaffMinorScales />
    <StaffIntervals />
    <StaffTriads />
    <StaffTriadInversions />
  </div>
</template>
