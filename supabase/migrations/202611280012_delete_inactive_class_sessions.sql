-- Safely delete an owned, inactive class session and its linked adventure.
create or replace function public.delete_class_session(p_session_id uuid)
returns void language plpgsql security definer set search_path=public
as $$
declare v_session public.sessions; v_game_id uuid;
begin
 if auth.uid() is null or not public.is_authorized_teacher() then raise exception 'Solo el docente autorizado puede eliminar sesiones.'; end if;
 select * into v_session from public.sessions where id=p_session_id and owner_id=auth.uid() for update;
 if not found then raise exception 'La sesión no existe o no te pertenece.'; end if;
 if v_session.status='active' then raise exception 'Finaliza la sesión antes de eliminarla.'; end if;
 v_game_id:=v_session.adventure_game_id;
 delete from public.sessions where id=v_session.id;
 if v_game_id is not null then delete from public.adventure_games where id=v_game_id and owner_id=auth.uid(); end if;
end;
$$;
revoke all on function public.delete_class_session(uuid) from public,anon;
grant execute on function public.delete_class_session(uuid) to authenticated;