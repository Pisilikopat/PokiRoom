-- =====================================================================
-- PokiRoom - Push Bildirimleri (FCM Trigger Kurulumu)
-- 01-05 numaralı dosyalardan SONRA Supabase SQL Editor'da çalıştırın.
-- =====================================================================

-- 1) HTTP istekleri gönderebilmek için pg_net eklentisini etkinleştir
create extension if not exists pg_net with schema extensions;

-- 2) Edge Function'ı tetikleyen fonksiyon
create or replace function public.trig_push_notification()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  v_payload jsonb;
begin
  -- Webhook payload'ı oluştur
  v_payload := jsonb_build_object(
    'type', TG_OP,
    'table', TG_TABLE_NAME,
    'schema', TG_TABLE_SCHEMA,
    'record', row_to_json(NEW)
  );

  -- Supabase Edge Function 'send-push'a asenkron HTTP POST yap
  perform net.http_post(
    url := 'https://bqfbatewvgzoidkonshd.supabase.co/functions/v1/send-push',
    headers := jsonb_build_object(
      'Content-Type', 'application/json',
      'Authorization', 'Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImJxZmJhdGV3dmd6b2lka29uc2hkIiwicm9sZSI6ImFub24iLCJpYXQiOjE3OTI4Mjc2MjIsImV4cCI6MjEwODQwMzYyMn0.DMgdBFt-RqbPLAHVUfKVKHwtVRdkVTCkmJBbsFZdV10'
    ),
    body := v_payload
  );

  return NEW;
exception
  when others then
    -- Push hatası asıl mesajın veya bildirimin kaydedilmesini ASLA engellemez
    return NEW;
end;
$$;

-- 3) 'room_notifications' tablosu için tetikleyici (Dürtmeler, Tıklatmalar, Çıkartmalar, Anılar)
drop trigger if exists push_room_notifications_trig on public.room_notifications;
create trigger push_room_notifications_trig
  after insert on public.room_notifications
  for each row execute function public.trig_push_notification();

-- 4) 'messages' tablosu için tetikleyici (Yeni sohbet mesajları)
drop trigger if exists push_messages_trig on public.messages;
create trigger push_messages_trig
  after insert on public.messages
  for each row execute function public.trig_push_notification();
