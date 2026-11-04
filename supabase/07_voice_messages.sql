-- =====================================================================
-- PokiRoom - 07: Sesli Mesajlar (Voice Messages)
-- Supabase SQL Editor üzerinden çalıştırın.
-- =====================================================================

-- 1) messages tablosu constraint güncellemesi: 'voice' türünü ekle
alter table public.messages drop constraint if exists messages_type_check;
alter table public.messages
  add constraint messages_type_check
  check (message_type in ('text', 'foggy', 'doodle', 'time_capsule', 'sticker', 'voice'));

-- 2) Storage bucket: 'voice_messages' oluştur
insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values (
  'voice_messages',
  'voice_messages',
  true,
  10485760, -- 10 MB limit
  array['audio/m4a', 'audio/aac', 'audio/mp4', 'audio/webm', 'audio/ogg', 'audio/mpeg']
)
on conflict (id) do nothing;

-- 3) Storage RLS politikaları (Giriş yapmış kullanıcılar ses yükleyebilir ve dinleyebilir)
create policy "Authenticated users can upload voice notes"
  on storage.objects for insert
  to authenticated
  with check (bucket_id = 'voice_messages');

create policy "Public voice notes are viewable by all"
  on storage.objects for select
  to public
  using (bucket_id = 'voice_messages');
