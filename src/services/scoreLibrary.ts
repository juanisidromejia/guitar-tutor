export interface ScoreRecord {
  id: string
  name: string
  type: string
  size: number
  lastModified: number
  savedAt: number
  blob: Blob
}

const DATABASE_NAME = 'guitar-tutor-library'
const DATABASE_VERSION = 1
const STORE_NAME = 'scores'

function openDatabase(): Promise<IDBDatabase> {
  return new Promise((resolve, reject) => {
    const request = indexedDB.open(DATABASE_NAME, DATABASE_VERSION)
    request.onupgradeneeded = () => {
      const database = request.result
      if (!database.objectStoreNames.contains(STORE_NAME)) {
        const store = database.createObjectStore(STORE_NAME, { keyPath: 'id' })
        store.createIndex('savedAt', 'savedAt')
      }
    }
    request.onsuccess = () => resolve(request.result)
    request.onerror = () => reject(request.error || new Error('No se pudo abrir la biblioteca.'))
  })
}

export async function listScores(): Promise<ScoreRecord[]> {
  const database = await openDatabase()
  return new Promise((resolve, reject) => {
    const request = database.transaction(STORE_NAME, 'readonly').objectStore(STORE_NAME).getAll()
    request.onsuccess = () => {
      database.close()
      resolve((request.result as ScoreRecord[]).sort((a, b) => b.savedAt - a.savedAt))
    }
    request.onerror = () => {
      database.close()
      reject(request.error || new Error('No se pudo leer la biblioteca.'))
    }
  })
}

export async function saveScore(file: File): Promise<ScoreRecord> {
  const database = await openDatabase()
  const records = await new Promise<ScoreRecord[]>((resolve, reject) => {
    const request = database.transaction(STORE_NAME, 'readonly').objectStore(STORE_NAME).getAll()
    request.onsuccess = () => resolve(request.result as ScoreRecord[])
    request.onerror = () => reject(request.error)
  })

  const existing = records.find((record) =>
    record.name === file.name && record.size === file.size && record.lastModified === file.lastModified,
  )
  const record: ScoreRecord = {
    id: existing?.id || crypto.randomUUID(),
    name: file.name,
    type: file.type,
    size: file.size,
    lastModified: file.lastModified,
    savedAt: Date.now(),
    blob: file,
  }

  await new Promise<void>((resolve, reject) => {
    const transaction = database.transaction(STORE_NAME, 'readwrite')
    transaction.objectStore(STORE_NAME).put(record)
    transaction.oncomplete = () => resolve()
    transaction.onerror = () => reject(transaction.error || new Error('No se pudo guardar la partitura.'))
    transaction.onabort = () => reject(transaction.error || new Error('Se canceló el guardado.'))
  }).finally(() => database.close())

  return record
}

export async function getScore(id: string): Promise<ScoreRecord | undefined> {
  const database = await openDatabase()
  return new Promise((resolve, reject) => {
    const request = database.transaction(STORE_NAME, 'readonly').objectStore(STORE_NAME).get(id)
    request.onsuccess = () => {
      database.close()
      resolve(request.result as ScoreRecord | undefined)
    }
    request.onerror = () => {
      database.close()
      reject(request.error || new Error('No se pudo abrir la partitura.'))
    }
  })
}

export async function deleteScore(id: string): Promise<void> {
  const database = await openDatabase()
  return new Promise((resolve, reject) => {
    const transaction = database.transaction(STORE_NAME, 'readwrite')
    transaction.objectStore(STORE_NAME).delete(id)
    transaction.oncomplete = () => {
      database.close()
      resolve()
    }
    transaction.onerror = () => {
      database.close()
      reject(transaction.error || new Error('No se pudo eliminar la partitura.'))
    }
  })
}
