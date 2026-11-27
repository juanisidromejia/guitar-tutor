# Configuración de sesiones de clase

## 1. Crear el proyecto Supabase
Crea un proyecto en Supabase. En Authentication:
- Activa **Anonymous sign-ins** para estudiantes.
- Activa el proveedor **Email** para docentes.
- En URL Configuration agrega la URL pública de Guitar Tutor y la URL local de desarrollo como Redirect URLs.

## 2. Aplicar las migraciones
Abre SQL Editor y ejecuta, en orden, todos los archivos de `supabase/migrations/`:
1. `202611260001_class_sessions.sql`
2. `202611260002_api_grants.sql`
3. `202611260003_server_question_bank.sql`
4. `202611260004_teacher_email_allowlist.sql`
5. `202611260005_hide_student_answer_feedback.sql`
6. `202611260006_session_question_count_and_teacher_review.sql`
7. `202611270001_expand_question_bank_and_levels.sql`

Las migraciones crean las sesiones, preguntas, participantes y respuestas; activan RLS y publican las tablas necesarias en Realtime. El campo `correct_answer` no tiene permiso de lectura desde el navegador. La corrección y puntuación se calculan en una función del servidor.

## 3. Variables de entorno
Copia `.env.example` como `.env.local` y completa:
- `VITE_SUPABASE_URL`: Project URL.
- `VITE_SUPABASE_ANON_KEY`: publishable key (o anon key legacy).

Nunca coloques `service_role` ni una secret key en variables `VITE_*` o en el navegador.

## 4. Vercel
En Project Settings → Environment Variables agrega las dos variables anteriores para Preview y Production. Después vuelve a desplegar `feature/phase-1-foundation`.

## 5. Acceso docente restringido (fase inicial)
El panel docente está limitado a `juanisidromejia@gmail.com`. La interfaz solo permite solicitar el enlace mágico para ese correo y no crea usuarios nuevos desde el formulario. Además, la migración `202611260004_teacher_email_allowlist.sql` aplica la misma restricción en las funciones y políticas de la base de datos. Ejecuta esa migración después de las tres anteriores antes de utilizar el panel. Para autorizar otros docentes más adelante, habrá que ampliar la lista de permitidos y revisar el mecanismo de invitación.

## 6. Flujo disponible
- El docente entra con enlace mágico enviado por correo.
- El estudiante entra desde un enlace directo o escribe el código manualmente; luego elige un nickname, sin crear una cuenta.
- **A su ritmo:** el docente abre la prueba y cada estudiante responde de forma independiente.
- **En vivo:** el docente inicia la sesión y avanza las preguntas para todos; el estado se sincroniza en tiempo real.
- Al crear la sesión, el docente elige el nivel (principiante, intermedio, avanzado o mixto) y la cantidad de preguntas (5, 8, 10, 12, 15 o 20). En nivel mixto, la selección intenta repartir las preguntas entre los tres niveles. El panel docente muestra el avance de la pregunta en vivo y permite revisar, por estudiante, sus respuestas, errores, respuesta correcta y explicación. Los estudiantes no reciben feedback de corrección durante la prueba.

## Alcance de esta primera versión
El banco de aula contiene 60 preguntas: 20 principiantes, 20 intermedias y 20 avanzadas. Incluye pentagrama, diapasón, ritmo y armonía (accidentales, armaduras, escalas menores, intervalos, tríadas e inversiones). Cada sesión selecciona preguntas al azar sin repetirlas dentro de esa sesión. El nivel y la dificultad de cada pregunta se muestran a los estudiantes, pero la respuesta correcta permanece en el servidor. Todavía no hay editor para crear cuestionarios propios, temporizador/bonus por velocidad, equipos, exportación CSV, control de asistencia institucional ni presencia en línea diferenciada de participantes registrados. La lista del panel refleja participantes que ingresaron, no garantiza que sigan conectados en ese instante.

## Nota sobre la evaluación individual existente
La ruta `/evaluacion` que ya tenía Guitar Tutor continúa siendo una prueba local del navegador. Su banco de respuestas forma parte del código del cliente y no debe usarse como examen supervisado o de alto impacto. Las sesiones nuevas califican en el servidor y no exponen la columna `correct_answer` en las consultas de estudiantes.
