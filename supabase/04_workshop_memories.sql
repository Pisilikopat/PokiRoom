-- =====================================================================
-- PokiRoom - Atölye (çıkartmalar) + Anılar (mantar pano)
-- 01, 02, 03 numaralı dosyalardan SONRA çalıştırın.
-- =====================================================================

-- 1) messages: 'sticker' mesaj türünü kabul et (content = room_stickers.id)
alter table public.messages drop constraint if exists messages_type_check;
alter table public.messages
  add constraint messages_type_check
  check (message_type in ('text', 'foggy', 'doodle', 'time_capsule', 'sticker'));

-- 2) Storage bucket (özel: sadece oda üyeleri okuyabilir)
insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values ('stickers', 'stickers', false, 1048576, array['image/png'])
on conflict (id) do nothing;

-- 3) room_stickers
create table public.room_stickers (
  id           uuid primary key default gen_random_uuid(),
  room_id      uuid not null references public.rooms (id) on delete cascade,
  creator_id   uuid not null references public.users (id) on delete cascade,
  storage_path text not null unique,
  width        int  not null check (width > 0),
  height       int  not null check (height > 0),
  created_at   timestamptz not null default now()
);

create index room_stickers_room_idx on public.room_stickers (room_id, created_at desc);

-- 4) memories
create table public.memories (
  id         uuid primary key default gen_random_uuid(),
  room_id    uuid not null references public.rooms (id) on delete cascade,
  author_id  uuid not null references public.users (id) on delete cascade,
  kind       text not null check (kind in ('sticker', 'foggy', 'note')),
  content    text,
  sticker_id uuid references public.room_stickers (id) on delete cascade,
  created_at timestamptz not null default now(),
  constraint memories_payload check (
    (kind = 'sticker' and sticker_id is not null)
    or (kind in ('foggy', 'note') and content is not null
        and char_length(content) between 1 and 1000)
  )
);

create index memories_room_idx on public.memories (room_id, created_at desc);

-- 5) RLS
alter table public.room_stickers enable row level security;
alter table public.memories      enable row level security;

create policy "stickers_select_members" on public.room_stickers
  for select using (public.is_room_member(room_id));

create policy "stickers_insert_active_members" on public.room_stickers
  for insert with check (
    creator_id = auth.uid()
    and exists (
      select 1 from public.rooms r
      where r.id = room_id and r.is_active
        and (r.user1_id = auth.uid() or r.user2_id = auth.uid())
    )
  );

create policy "stickers_delete_creator" on public.room_stickers
  for delete using (creator_id = auth.uid());

create policy "memories_select_members" on public.memories
  for select using (public.is_room_member(room_id));

create policy "memories_insert_active_members" on public.memories
  for insert with check (
    author_id = auth.uid()
    and exists (
      select 1 from public.rooms r
      where r.id = room_id and r.is_active
        and (r.user1_id = auth.uid() or r.user2_id = auth.uid())
    )
  );

create policy "memories_delete_author" on public.memories
  for delete using (author_id = auth.uid());

-- 6) Storage RLS: dosya yolu = {room_id}/{uuid}.png
create policy "stickers_storage_read" on storage.objects
  for select to authenticated
  using (
    bucket_id = 'stickers'
    and public.is_room_member(((storage.foldername(name))[1])::uuid)
  );

create policy "stickers_storage_insert" on storage.objects
  for insert to authenticated
  with check (
    bucket_id = 'stickers'
    and exists (
      select 1 from public.rooms r
      where r.id = ((storage.foldername(name))[1])::uuid
        and r.is_active
        and (r.user1_id = auth.uid() or r.user2_id = auth.uid())
    )
  );

create policy "stickers_storage_delete_owner" on storage.objects
  for delete to authenticated
  using (bucket_id = 'stickers' and owner_id = auth.uid()::text);

-- 7) Realtime
alter publication supabase_realtime add table public.room_stickers;
alter publication supabase_realtime add table public.memories;
