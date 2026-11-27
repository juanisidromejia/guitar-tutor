-- Guitar staff-reading questions display written pitch on the octave-transposing
-- treble clef, but ask students to identify the guitar's sounding (real) pitch.
-- Keep midi unchanged: StaffNote needs the written pitch to place the note visually.

update public.class_question_bank
set
  prompt = '¿Qué nota suena realmente en la guitarra según la nota escrita en el pentagrama?',
  options = case id
    when 1 then '["Do3","Mi3","Sol3","La3"]'::jsonb
    when 2 then '["Re3","Fa3","Sol3","Si3"]'::jsonb
    when 3 then '["Do3","Re3","Mi3","Fa3"]'::jsonb
    when 4 then '["Do4","Re4","Fa4","Sol4"]'::jsonb
    when 13 then '["Do3","Fa3","La3","Do4"]'::jsonb
    when 14 then '["Mi3","Sol3","Si3","Re4"]'::jsonb
    when 15 then '["Fa3","Sol3","La3","Do4"]'::jsonb
    else options
  end,
  correct_answer = case id
    when 1 then 'Mi3'
    when 2 then 'Sol3'
    when 3 then 'Do3'
    when 4 then 'Do4'
    when 13 then 'Fa3'
    when 14 then 'Re4'
    when 15 then 'La3'
    else correct_answer
  end,
  explanation = case id
    when 1 then 'La nota está escrita como Mi4 en el pentagrama, pero la guitarra suena una octava más grave: Mi3.'
    when 2 then 'La nota está escrita como Sol4 en la segunda línea, pero la guitarra suena una octava más grave: Sol3.'
    when 3 then 'La nota está escrita como Do4 en la línea adicional inferior, pero la guitarra suena una octava más grave: Do3.'
    when 4 then 'La nota está escrita como Do5 en el tercer espacio, pero la guitarra suena una octava más grave: Do4.'
    when 13 then 'La nota está escrita como Fa4 en el primer espacio, pero la guitarra suena una octava más grave: Fa3.'
    when 14 then 'La nota está escrita como Re5 en la cuarta línea, pero la guitarra suena una octava más grave: Re4.'
    when 15 then 'La nota está escrita como La4 en el segundo espacio, pero la guitarra suena una octava más grave: La3.'
    else explanation
  end
where id in (1,2,3,4,13,14,15);
