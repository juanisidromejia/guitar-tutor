# Guitar Tutor — arquitectura pedagógica y modelo común

## Objetivo

Construir una plataforma progresiva de aprendizaje musical, desde fundamentos absolutos hasta contenidos avanzados, priorizando el trabajo asincrónico y la reutilización de componentes existentes.

## Principios

1. Una única representación de alturas musicales basada en MIDI.
2. Separar altura sonora de escritura musical: Do♯ y Re♭ pueden compartir MIDI, pero no son la misma grafía ni necesariamente la misma función teórica.
3. Reutilizar los motores actuales de guitarra, pentagrama, audio, ritmo y AlphaTab.
4. Separar contenido, presentación y evaluación.
5. Los ejercicios se describen con metadatos (nivel, área, tema, formato y prerrequisitos) y parámetros configurables.
6. Las respuestas correctas y reglas de calificación de evaluaciones supervisadas permanecen en Supabase, protegidas por RLS/RPC; nunca se incluyen en el bundle del estudiante.

## Inventario actual

| Área | Implementación existente | Evolución prevista |
|---|---|---|
| Alturas | `src/engines/music/pitch.ts` | Mantener MIDI y ampliar grafías/enarmonía en el modelo común |
| Diapasón | `src/engines/guitar/fretboard.ts`, `GuitarFretboard.vue` | Hacer configurable el rango de trastes sin duplicar el componente |
| Pentagrama | `StaffNote.vue` | Acepta grafía explícita de sostenidos, bemoles y dobles alteraciones, conservando la altura MIDI y la transposición de octava de guitarra |
| Audio | `guitarSound.ts` | Reutilizar reproducción de notas |
| Ritmo | `rhythmSound.ts`, `RhythmReadingView.vue` | Ampliar catálogo de patrones y figuras sobre el motor actual |
| Partituras | AlphaTab y biblioteca MusicXML | Crear actividades que reutilicen el reproductor |
| Evaluaciones | `AssessmentView.vue`, sesiones Supabase | Banco etiquetado y selección configurable por nivel/área |

## Modelo musical compartido

Se incorpora `src/engines/music/musicTheory.ts` como capa de dominio ligera, no como un motor de audio o visualización nuevo.

- `SpelledNote`: letra, alteración y octava.
- `noteToMidi` / `midiToNote`: conversión entre grafía y altura sonora.
- `parseNoteName`: lectura de nombres en español o cifrado anglosajón.
- `respellNote`: representación preferida con sostenidos o bemoles.
- `pitchClassDistance`: distancia cromática.
- `buildTriad`: construcción básica de tríadas.

La API anterior `midiName` y `midiHz` de `pitch.ts` se conserva para no romper los módulos actuales. `StaffNote.vue` mantiene su propiedad `midi` y acepta además `spelling` cuando se necesita fijar una grafía concreta (por ejemplo, Re♭4 en lugar de Do♯4); la grafía explícita solo se utiliza si coincide con la altura MIDI indicada.

## Modelo de aprendizaje

`src/types/learning.ts` define metadatos comunes para niveles, áreas, formatos de ejercicio y regiones del diapasón.

### Niveles y secuencia

**Principiante**
- Cuerdas al aire y notas naturales.
- Pentagrama en clave de sol: líneas, espacios y notas sencillas.
- Figuras básicas y silencios.
- Escala mayor, tonos/semitonos y tríadas mayores/menores iniciales.

**Intermedio**
- Notas alteradas, sostenidos, bemoles y enarmonía.
- Regiones del diapasón 5–9.
- Intervalos, escalas y armaduras iniciales.
- Grados, acordes diatónicos, progresiones e inversiones.
- Semicorcheas, puntillos, ligaduras y síncopas.

**Avanzado**
- Ventanas móviles de cinco espacios (por ejemplo 7–11, 8–12, 9–13, 10–14).
- Armaduras, lectura de acordes y fragmentos más complejos.
- Acordes de séptima y cuatro voces, conducción de voces y armonía avanzada.
- Compases compuestos, tresillos, cambios de compás y dictado.

Los niveles no deben ser etiquetas arbitrarias: cada lección declarará prerrequisitos y el docente podrá asignar actividades de refuerzo aunque el estudiante ya tenga un nivel global superior.

## Regiones del diapasón

La región se configura mediante las propiedades `startFret` y `endFret` del componente reutilizable `GuitarFretboard.vue`, con validación de cinco trastes consecutivos. La vista de lectura pentagrama–diapasón ya utiliza 1–5. La presentación heredada de cuerdas al aire más trastes 1–5 se conserva como valor predeterminado para no alterar los módulos existentes. La lista inicial de regiones es editable como datos. El primer sector pedagógico queda fijado en 1–5, el segundo en 5–9 y las regiones avanzadas son ventanas móviles.

## Arquitectura de ejercicios

Un ejercicio común tiene:
- Identificador y metadatos pedagógicos.
- Formato de interacción.
- Enunciado y explicación.
- Parámetros de visualización/generación.
- Clave de respuesta separada y protegida cuando se trata de una evaluación supervisada.

Los formatos reutilizan visualizadores existentes: pentagrama, diapasón, audio, patrón rítmico y AlphaTab. Añadir una dificultad o una nueva región debe ser principalmente una modificación de datos/configuración.

## Alcance implementado hasta ahora

- El diapasón existente acepta `startFret` y `endFret` para mostrar cualquier ventana válida de cinco trastes.
- `StaffNote.vue` acepta una grafía explícita mediante `spelling`, sin romper los usos existentes que solo proporcionan `midi`.
- La lección de relación pentagrama–diapasón utiliza la región principiante 1–5.
- Se conserva la vista anterior de cuerdas al aire y trastes 1–5 como valor predeterminado para mantener compatibilidad.
- No se altera el comportamiento de `StaffNote.vue`.
- No se reemplazan las 12 preguntas actuales.
- No se modifica el esquema Supabase ni las migraciones de sesiones.
- No se cambia la navegación ni el diseño de módulos existentes.

## Próximas etapas

1. Incorporar un selector de regiones y ejercicios configurables para las ventanas del diapasón.
2. Crear ejercicios pedagógicos de reconocimiento de notas alteradas usando la nueva propiedad `spelling` y el modelo común.
3. Ampliar el banco de preguntas con etiquetas de nivel, área, tema y prerrequisitos.
4. Incorporar armonía y reconocimiento de acordes reutilizando el modelo de notas.
5. Ampliar ritmo y lectura con los motores existentes.
