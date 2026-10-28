-- =====================================================================
-- PokiRoom - Uygulama içi bildirimler (canlı banner + Aktivite Merkezi)
-- 01-04 numaralı dosyalardan SONRA çalıştırın.
-- =====================================================================

-- 1) Tablo
create table public.room_notifications (
  id          uuid primary key default gen_random_uuid(),
  room_id     uuid references public.rooms (id) on delete cascade,  -- 'knock' için null olabilir
  sender_id   uuid not null references public.users (id) on delete cascade,
  receiver_id uuid not null references public.users (id) on delete cascade,
  type        text not null,
  title       text not null,
  body        text not null,
  is_read     boolean not null default false,
  created_at  timestamptz not null default now(),
  constraint notif_type_check
    check (type in ('poke', 'sticker_created', 'memory_pinned', 'foggy_revealed', 'knock')),
  constraint notif_room_required check (type = 'knock' or room_id is not null),
  constraint notif_not_self check (sender_id <> receiver_id),
  constraint notif_title_len check (char_length(title) <= 80),
  constraint notif_body_len check (char_length(body) <= 200)
);

create index room_notifications_receiver_idx
  on public.room_notifications (receiver_id, created_at desc);
create index room_notifications_unread_idx
  on public.room_notifications (receiver_id) where not is_read;

-- 2) RLS
alter table public.room_notifications enable row level security;

-- Sadece alıcı kendi bildirimlerini okur (alıcı zaten oda üyesidir).
create policy "notifications_select_receiver" on public.room_notifications
  for select using (receiver_id = auth.uid());

-- Gönderen sadece KENDİ adına ve sadece aynı aktif odadaki partnerine bildirim yazabilir.
-- 'knock' istemciden yazılamaz; send_knock() fonksiyonu yazar.
create policy "notifications_insert_partner" on public.room_notifications
  for insert with check (
    sender_id = auth.uid()
    and type <> 'knock'
    and room_id is not null
    and exists (
      select 1 from public.rooms r
      where r.id = room_id
        and r.is_active
        and ((r.user1_id = sender_id and r.user2_id = receiver_id)
          or (r.user2_id = sender_id and r.user1_id = receiver_id))
    )
  );

-- Sadece alıcı okundu işaretleyebilir ve sadece is_read alanını değiştirebilir.
create policy "notifications_update_receiver" on public.room_notifications
  for update using (receiver_id = auth.uid())
  with check (receiver_id = auth.uid());

revoke update on public.room_notifications from authenticated, anon;
grant update (is_read) on public.room_notifications to authenticated;

-- 3) Realtime
alter publication supabase_realtime add table public.room_notifications;

-- 4) 'knock' bildirimi: send_knock() fonksiyonunu bildirim yazacak şekilde güncelle
create or replace function public.send_knock(p_tag text, p_message text default null)
returns uuid
language plpgsql
security definer
set search_path = public
as $$
declare
  v_me          uuid := auth.uid();
  v_target      uuid;
  v_target_room uuid;
  v_my_room     uuid;
  v_id          uuid;
  v_nick        text;
begin
  if v_me is null then raise exception 'not_authenticated'; end if;

  select id, current_room_id into v_target, v_target_room
  from public.users
  where upper(custom_tag) = upper(trim(p_tag));

  if v_target is null then raise exception 'user_not_found'; end if;
  if v_target = v_me then raise exception 'cannot_knock_self'; end if;

  select current_room_id, nickname into v_my_room, v_nick
  from public.users where id = v_me;
  if v_my_room is not null then raise exception 'sender_busy'; end if;
  if v_target_room is not null then raise exception 'receiver_busy'; end if;

  insert into public.room_requests (sender_id, receiver_id, knock_message)
  values (v_me, v_target, nullif(trim(coalesce(p_message, '')), ''))
  returning id into v_id;

  insert into public.room_notifications (room_id, sender_id, receiver_id, type, title, body)
  values (
    null, v_me, v_target, 'knock', 'Tık tık!',
    '🚪 ' || left(coalesce(v_nick, 'Biri'), 40) || ' odanın kapısını tıklattı!'
  );

  return v_id;
exception
  when unique_violation then
    raise exception 'duplicate_request';
end;
$$;

-- 5) (İsteğe bağlı) Tablo şişmesin: 30 günden eski bildirimleri temizle.
-- Supabase > Database > Extensions'dan pg_cron'u açtıysanız:
-- select cron.schedule('clean-room-notifications', '0 4 * * *',
--   $$delete from public.room_notifications where created_at < now() - interval '30 days'$$);
