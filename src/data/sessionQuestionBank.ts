export type SessionQuestion = {
  id: number
  category: 'Pentagrama' | 'Diapasón' | 'Ritmo'
  prompt: string
  explanation: string
  options: string[]
  correct: string
  midi?: number
}

export const sessionQuestionBank: SessionQuestion[] = [
  { id: 1, category: 'Pentagrama', prompt: '¿Qué nota aparece en el pentagrama?', midi: 64, options: ['Do4', 'Mi4', 'Sol4', 'La4'], correct: 'Mi4', explanation: 'Mi4 se escribe en la primera línea. En guitarra suena una octava más grave.' },
  { id: 2, category: 'Pentagrama', prompt: '¿Qué nota aparece en el pentagrama?', midi: 67, options: ['Re4', 'Fa4', 'Sol4', 'Si4'], correct: 'Sol4', explanation: 'Sol4 se escribe en la segunda línea. En guitarra suena una octava más grave.' },
  { id: 3, category: 'Pentagrama', prompt: '¿Qué nota aparece en el pentagrama?', midi: 60, options: ['Do4', 'Re4', 'Mi4', 'Fa4'], correct: 'Do4', explanation: 'Do4 se escribe en la línea adicional inferior. En guitarra suena una octava más grave: Do3.' },
  { id: 4, category: 'Pentagrama', prompt: '¿Qué nota aparece en el pentagrama?', midi: 72, options: ['Do5', 'Re5', 'Fa5', 'Sol5'], correct: 'Do5', explanation: 'Do5 está en el tercer espacio. En guitarra suena una octava más grave: Do4.' },
  { id: 5, category: 'Diapasón', prompt: '¿En qué posición encuentras la nota Sol4?', options: ['1.ª cuerda, traste 3', '2.ª cuerda, traste 8', '3.ª cuerda, traste 12', '4.ª cuerda, traste 5'], correct: '1.ª cuerda, traste 3', explanation: 'La primera cuerda, traste 3, produce Sol4 real.' },
  { id: 6, category: 'Diapasón', prompt: '¿Dónde se encuentra la nota La3?', options: ['3.ª cuerda, traste 2', '4.ª cuerda, traste 7', '5.ª cuerda, traste 0', '6.ª cuerda, traste 5'], correct: '3.ª cuerda, traste 2', explanation: 'La tercera cuerda al aire produce Sol3; el segundo traste produce La3.' },
  { id: 7, category: 'Diapasón', prompt: '¿Qué nota suena en la segunda cuerda al aire?', options: ['Mi4', 'Si3', 'Sol3', 'Re4'], correct: 'Si3', explanation: 'En afinación estándar, la segunda cuerda al aire produce Si3 real.' },
  { id: 8, category: 'Diapasón', prompt: '¿Qué nota obtienes en la quinta cuerda, traste 3?', options: ['Do3', 'Re3', 'Mi3', 'Fa3'], correct: 'Do3', explanation: 'La quinta cuerda al aire produce La2; en el tercer traste encontramos Do3.' },
  { id: 9, category: 'Ritmo', prompt: '¿Cuántas negras equivalen a una redonda?', options: ['Dos', 'Tres', 'Cuatro', 'Ocho'], correct: 'Cuatro', explanation: 'La redonda equivale a cuatro negras.' },
  { id: 10, category: 'Ritmo', prompt: '¿Cuántas corcheas equivalen a una negra?', options: ['Una', 'Dos', 'Tres', 'Cuatro'], correct: 'Dos', explanation: 'Dos corcheas tienen la misma duración que una negra.' },
  { id: 11, category: 'Ritmo', prompt: '¿Qué debes hacer durante un silencio de negra?', options: ['Detener el pulso', 'Mantener el pulso sin sonar', 'Tocar una corchea', 'Acelerar'], correct: 'Mantener el pulso sin sonar', explanation: 'El silencio ocupa el tiempo de una negra, pero no produce sonido.' },
  { id: 12, category: 'Ritmo', prompt: 'En un compás de 3/4, ¿cuántas negras completan el compás?', options: ['Dos', 'Tres', 'Cuatro', 'Seis'], correct: 'Tres', explanation: 'En 3/4 hay tres pulsos de negra por compás.' },
]
