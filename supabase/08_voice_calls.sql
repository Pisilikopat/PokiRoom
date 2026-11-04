-- supabase/08_voice_calls.sql
-- Sesli arama oturumu kayıtları (opsiyonel analitik + çağrı geçmişi)

CREATE TABLE IF NOT EXISTS call_sessions (
  id            uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  room_id       uuid NOT NULL REFERENCES rooms(id) ON DELETE CASCADE,
  caller_id     uuid NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  callee_id     uuid NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  status        text NOT NULL DEFAULT 'pending'
                CHECK (status IN ('pending', 'active', 'ended', 'rejected', 'missed')),
  started_at    timestamptz NOT NULL DEFAULT now(),
  connected_at  timestamptz,
  ended_at      timestamptz,
  duration_secs int GENERATED ALWAYS AS (
    CASE
      WHEN connected_at IS NOT NULL AND ended_at IS NOT NULL
      THEN EXTRACT(EPOCH FROM (ended_at - connected_at))::int
      ELSE NULL
    END
  ) STORED,
  created_at    timestamptz NOT NULL DEFAULT now()
);

-- RLS
ALTER TABLE call_sessions ENABLE ROW LEVEL SECURITY;

-- Sadece odadaki kullanıcılar görebilir / yazabilir
CREATE POLICY "call_sessions_select" ON call_sessions
  FOR SELECT USING (
    auth.uid() = caller_id OR auth.uid() = callee_id
  );

CREATE POLICY "call_sessions_insert" ON call_sessions
  FOR INSERT WITH CHECK (
    auth.uid() = caller_id
    AND EXISTS (
      SELECT 1 FROM rooms
      WHERE id = room_id
        AND (user1_id = auth.uid() OR user2_id = auth.uid())
    )
  );

CREATE POLICY "call_sessions_update" ON call_sessions
  FOR UPDATE USING (
    auth.uid() = caller_id OR auth.uid() = callee_id
  );

-- messages tablosuna 'call' type ekle (eğer zaten yoksa)
DO $$
BEGIN
  -- mevcut check kısıtlamasını kaldır
  ALTER TABLE messages DROP CONSTRAINT IF EXISTS messages_type_check;
  -- yeni genişletilmiş kısıtlamayı ekle
  ALTER TABLE messages ADD CONSTRAINT messages_type_check
    CHECK (type IN ('text', 'foggy', 'doodle', 'time_capsule', 'sticker', 'voice', 'call'));
EXCEPTION
  WHEN others THEN NULL;
END;
$$;
