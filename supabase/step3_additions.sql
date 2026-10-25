-- =====================================================================
-- PokiRoom - Adım 3: SQL Eklemeleri (Adım 1 ve 2'den SONRA çalıştırın)
-- =====================================================================

-- 1) rooms: istemci doğrudan güncelleyemesin (streak/aktiflik sadece sunucudan)
drop policy if exists "rooms_update_members" on public.rooms;
revoke update on public.rooms from authenticated, anon;

-- 2) messages: istemci sadece is_read alanını güncelleyebilsin
revoke update on public.messages from authenticated, anon;
grant update (is_read) on public.messages to authenticated;

-- 3) Mesaj yazma: sadece AKTİF odada
drop policy if exists "messages_insert_members" on public.messages;
create policy "messages_insert_active_members" on public.messages
  for insert with check (
    sender_id = auth.uid()
    and exists (
      select 1 from public.rooms r
      where r.id = room_id
        and r.is_active
        and (r.user1_id = auth.uid() or r.user2_id = auth.uid())
    )
  );

-- 4) Cebi Kapat: odayı kapat, iki kullanıcının bağlantısını temizle
create or replace function public.close_room()
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  v_room uuid;
begin
  select current_room_id into v_room from public.users where id = auth.uid();
  if v_room is null then return; end if;

  update public.rooms set is_active = false where id = v_room;
  update public.users set current_room_id = null where current_room_id = v_room;
end;
$$;

-- 5) PokiPet (streak): her yeni mesajda günlük seriyi güncelle
--    Not: gün sınırı veritabanı saat dilimine (varsayılan UTC) göre hesaplanır.
create or replace function public.bump_room_streak()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  v_last date;
begin
  select last_interaction_date into v_last from public.rooms where id = new.room_id;

  if v_last = current_date then
    return new;
  elsif v_last = current_date - 1 then
    update public.rooms
      set streak_count = streak_count + 1, last_interaction_date = current_date
      where id = new.room_id;
  else
    update public.rooms
      set streak_count = 1, last_interaction_date = current_date
      where id = new.room_id;
  end if;
  return new;
end;
$$;

drop trigger if exists messages_bump_streak on public.messages;
create trigger messages_bump_streak
  after insert on public.messages
  for each row execute function public.bump_room_streak();
