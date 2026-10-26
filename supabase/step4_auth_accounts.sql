-- =====================================================================
-- PokiRoom - Hesap Sistemi: SQL Eklemeleri
-- =====================================================================

-- 1) users tablosuna avatar_url kolonu ekle
ALTER TABLE public.users ADD COLUMN IF NOT EXISTS avatar_url text;

-- 2) Kullanıcıların avatar_url alanını güncelleyebilmesi
REVOKE UPDATE ON public.users FROM authenticated, anon;
GRANT UPDATE (custom_tag, nickname, mood_emoji, mood_text, is_online, fcm_token, avatar_url)
  ON public.users TO authenticated;

-- 3) Avatarlar için storage bucket oluştur
INSERT INTO storage.buckets (id, name, public)
VALUES ('avatars', 'avatars', true)
ON CONFLICT (id) DO NOTHING;

-- 4) Storage politikaları: herkes okuyabilir, sadece kendi dosyasını yükleyebilir
CREATE POLICY "Avatar images are publicly accessible"
  ON storage.objects FOR SELECT
  USING (bucket_id = 'avatars');

CREATE POLICY "Users can upload their own avatar"
  ON storage.objects FOR INSERT
  WITH CHECK (
    bucket_id = 'avatars'
    AND auth.uid() IS NOT NULL
    AND (storage.foldername(name))[1] = 'avatars'
  );

CREATE POLICY "Users can update their own avatar"
  ON storage.objects FOR UPDATE
  USING (
    bucket_id = 'avatars'
    AND auth.uid() IS NOT NULL
  );

-- 5) Yeni kullanıcı kayıt olunca otomatik users satırı oluştur
--    (auth.users tablosuna trigger bağlar)
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_nickname text;
  v_tag text;
BEGIN
  v_nickname := COALESCE(
    NEW.raw_user_meta_data ->> 'nickname',
    'Poki'
  );

  -- Rastgele 6 haneli PokiCode üret
  v_tag := '#POKI-' || UPPER(SUBSTRING(MD5(RANDOM()::text) FROM 1 FOR 6));

  INSERT INTO public.users (id, nickname, custom_tag)
  VALUES (NEW.id, v_nickname, v_tag)
  ON CONFLICT (id) DO NOTHING;

  RETURN NEW;
END;
$$;

-- Trigger (varsa düşür ve yeniden oluştur)
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();
