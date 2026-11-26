import { computed, ref, watch } from 'vue'

type Progress = { completed: number[]; correct: number; attempts: number }
const key = 'guitar-tutor-progress-v2'
const previousKey = 'guitar-tutor-progress-v1'

function load(): Progress {
  const empty: Progress = { completed: [], correct: 0, attempts: 0 }
  try {
    const current = localStorage.getItem(key)
    if (current) return { ...empty, ...JSON.parse(current) }

    const previous = localStorage.getItem(previousKey)
    if (!previous) return empty

    const oldData = JSON.parse(previous) as Progress
    // En la versión anterior, el identificador 1 correspondía al ejercicio
    // de localizar notas en el diapasón. Ahora ese ejercicio es el módulo 02.
    const completed = (oldData.completed || []).map(id => id === 1 ? 2 : id)
    return {
      completed: [...new Set(completed)],
      correct: oldData.correct || 0,
      attempts: oldData.attempts || 0,
    }
  } catch {
    return empty
  }
}

const data = ref<Progress>(load())
watch(data, value => localStorage.setItem(key, JSON.stringify(value)), { deep: true })

export function useProgress() {
  const accuracy = computed(() => data.value.attempts
    ? Math.round(data.value.correct / data.value.attempts * 100)
    : 0)

  function record(ok: boolean) {
    data.value.attempts++
    if (ok) data.value.correct++
  }

  function complete(id: number) {
    if (!data.value.completed.includes(id)) data.value.completed.push(id)
  }

  return { data, accuracy, record, complete }
}
