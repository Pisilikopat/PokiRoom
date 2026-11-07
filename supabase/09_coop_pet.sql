-- =====================================================================
-- PokiRoom - Ortak Sanal Kedi (Co-op Virtual Pet)
-- Arda & Yuna'nın gerçek zamanlı ortak baktığı cozy sanal kedi altyapısı.
-- 01-08 numaralı dosyalardan SONRA çalıştırın.
-- =====================================================================

-- 1) room_pets tablosu (Ana Kedi Durumu)
create table if not exists public.room_pets (
  room_id            uuid primary key references public.rooms (id) on delete cascade,
  pet_name           text not null default 'Mırnav',
  hunger             int not null default 70 check (hunger >= 0 and hunger <= 100),
  affection          int not null default 70 check (affection >= 0 and affection <= 100),
  energy             int not null default 80 check (energy >= 0 and energy <= 100),
  stats_updated_at   timestamptz not null default now(),
  is_sleeping        boolean not null default false,
  sleep_note         text,
  sleep_started_at   timestamptz,
  current_action     text not null default 'idle' check (current_action in ('idle', 'eating', 'petting')),
  action_ends_at     timestamptz,
  last_action_by     uuid references public.users (id) on delete set null,
  last_action_type   text,
  last_action_at     timestamptz
);

-- 2) pet_events tablosu (Olay Geçmişi)
create table if not exists public.pet_events (
  id          uuid primary key default gen_random_uuid(),
  room_id     uuid not null references public.rooms (id) on delete cascade,
  actor_id    uuid references public.users (id) on delete set null,
  type        text not null check (type in ('feed', 'pet', 'sleep', 'wake')),
  note        text,
  created_at  timestamptz not null default now()
);

create index if not exists pet_events_room_idx on public.pet_events (room_id, created_at desc);

-- 3) Realtime Publication'a Ekleme
alter publication supabase_realtime add table public.room_pets;
alter publication supabase_realtime add table public.pet_events;

-- 4) RLS (Row Level Security)
alter table public.room_pets enable row level security;
alter table public.pet_events enable row level security;

-- Odanın iki üyesi de kedi verisini okuyabilir
drop policy if exists "Oda üyeleri evcil hayvanı görebilir" on public.room_pets;
create policy "Oda üyeleri evcil hayvanı görebilir"
  on public.room_pets for select
  using (
    exists (
      select 1 from public.rooms r
      where r.id = room_pets.room_id
        and (r.user1_id = auth.uid() or r.user2_id = auth.uid())
    )
  );

drop policy if exists "Oda üyeleri pet olaylarını görebilir" on public.pet_events;
create policy "Oda üyeleri pet olaylarını görebilir"
  on public.pet_events for select
  using (
    exists (
      select 1 from public.rooms r
      where r.id = pet_events.room_id
        and (r.user1_id = auth.uid() or r.user2_id = auth.uid())
    )
  );

-- Güvenlik gereği doğrudan UPDATE engellenir, tüm değişiklikler atomik RPC ile yapılır.
-- Ancak gerektiğinde oda üyelerinin insert/update yapabilmesi için:
drop policy if exists "Oda üyeleri evcil hayvanı güncelleyebilir" on public.room_pets;
create policy "Oda üyeleri evcil hayvanı güncelleyebilir"
  on public.room_pets for update
  using (
    exists (
      select 1 from public.rooms r
      where r.id = room_pets.room_id
        and (r.user1_id = auth.uid() or r.user2_id = auth.uid())
    )
  );

-- 5) ATOMİK RPC FONKSİYONLARI (Security Definer + FOR UPDATE)

-- Decay Hesaplama Yardımcı Fonksiyonu
create or replace function public.pet_compute_decay(p_pet public.room_pets, p_now timestamptz default now())
returns public.room_pets as $$
declare
  v_delta_mins double precision;
  v_res public.room_pets;
begin
  v_res := p_pet;
  v_delta_mins := extract(epoch from (p_now - p_pet.stats_updated_at)) / 60.0;
  if v_delta_mins <= 0 then
    return v_res;
  end if;

  if p_pet.is_sleeping then
    -- Uyurken: enerji dolar (+1 / 1.5 dk), tokluk hafif azalır (-1 / 20 dk), mutluluk sabit
    v_res.energy := least(100, greatest(0, p_pet.energy + floor(v_delta_mins / 1.5)::int));
    v_res.hunger := least(100, greatest(0, p_pet.hunger - floor(v_delta_mins / 20.0)::int));
  else
    -- Uyanıkken: tokluk -1/6 dk, mutluluk -1/8 dk, enerji -1/10 dk
    v_res.hunger := least(100, greatest(0, p_pet.hunger - floor(v_delta_mins / 6.0)::int));
    v_res.affection := least(100, greatest(0, p_pet.affection - floor(v_delta_mins / 8.0)::int));
    v_res.energy := least(100, greatest(0, p_pet.energy - floor(v_delta_mins / 10.0)::int));
  end if;

  v_res.stats_updated_at := p_now;
  return v_res;
end;
$$ language plpgsql security definer;

-- Kediyi Getir veya Varsayılanlarla Oluştur
create or replace function public.pet_get_or_create(p_room_id uuid)
returns public.room_pets as $$
declare
  v_pet public.room_pets;
  v_decayed public.room_pets;
begin
  select * into v_pet from public.room_pets where room_id = p_room_id for update;
  if not found then
    insert into public.room_pets (room_id, pet_name, hunger, affection, energy, stats_updated_at)
    values (p_room_id, 'Mırnav', 70, 70, 80, now())
    returning * into v_pet;
    return v_pet;
  end if;

  -- Zaman farkı decay uygula
  v_decayed := public.pet_compute_decay(v_pet, now());
  if v_decayed.hunger <> v_pet.hunger or v_decayed.affection <> v_pet.affection or v_decayed.energy <> v_pet.energy then
    update public.room_pets
    set hunger = v_decayed.hunger,
        affection = v_decayed.affection,
        energy = v_decayed.energy,
        stats_updated_at = v_decayed.stats_updated_at
    where room_id = p_room_id
    returning * into v_pet;
  end if;

  return v_pet;
end;
$$ language plpgsql security definer;

-- Eylemi Başlat (Besle veya Sev - 3 saniye kilit)
create or replace function public.pet_start_action(p_room_id uuid, p_kind text)
returns public.room_pets as $$
declare
  v_pet public.room_pets;
  v_caller uuid := auth.uid();
begin
  select * into v_pet from public.room_pets where room_id = p_room_id for update;
  if not found then
    v_pet := public.pet_get_or_create(p_room_id);
  end if;

  if v_pet.is_sleeping then
    raise exception 'Kedi uyurken beslenemez veya sevilemez!';
  end if;

  if v_pet.current_action <> 'idle' and v_pet.action_ends_at is not null and v_pet.action_ends_at > now() then
    raise exception 'Zaten devam eden bir işlem var!';
  end if;

  -- Önce decay uygula
  v_pet := public.pet_compute_decay(v_pet, now());

  update public.room_pets
  set current_action = p_kind,
      action_ends_at = now() + interval '3 seconds',
      last_action_by = v_caller,
      last_action_type = p_kind,
      last_action_at = now(),
      hunger = v_pet.hunger,
      affection = v_pet.affection,
      energy = v_pet.energy,
      stats_updated_at = v_pet.stats_updated_at
  where room_id = p_room_id
  returning * into v_pet;

  return v_pet;
end;
$$ language plpgsql security definer;

-- Eylemi Tamamla (3 saniye dolunca bonus verilir, idempotent)
create or replace function public.pet_finish_action(p_room_id uuid)
returns public.room_pets as $$
declare
  v_pet public.room_pets;
  v_event_type text;
begin
  select * into v_pet from public.room_pets where room_id = p_room_id for update;
  if not found then
    return null;
  end if;

  if v_pet.current_action = 'idle' then
    return v_pet;
  end if;

  if v_pet.action_ends_at is null or v_pet.action_ends_at <= (now() + interval '1 second') then
    if v_pet.current_action = 'eating' then
      v_pet.hunger := least(100, v_pet.hunger + 25);
      v_event_type := 'feed';
    elsif v_pet.current_action = 'petting' then
      v_pet.affection := least(100, v_pet.affection + 20);
      v_event_type := 'pet';
    end if;

    if v_event_type is not null then
      insert into public.pet_events (room_id, actor_id, type)
      values (p_room_id, v_pet.last_action_by, v_event_type);
    end if;

    update public.room_pets
    set hunger = v_pet.hunger,
        affection = v_pet.affection,
        current_action = 'idle',
        action_ends_at = null,
        stats_updated_at = now()
    where room_id = p_room_id
    returning * into v_pet;
  end if;

  return v_pet;
end;
$$ language plpgsql security definer;

-- Kediyi Uyut (Başucu notu ile birlikte)
create or replace function public.pet_sleep(p_room_id uuid, p_note text default null)
returns public.room_pets as $$
declare
  v_pet public.room_pets;
  v_caller uuid := auth.uid();
  v_sanitized_note text;
begin
  select * into v_pet from public.room_pets where room_id = p_room_id for update;
  if not found then
    v_pet := public.pet_get_or_create(p_room_id);
  end if;

  if v_pet.is_sleeping then
    return v_pet;
  end if;

  -- Decay uygula
  v_pet := public.pet_compute_decay(v_pet, now());
  v_sanitized_note := substring(trim(p_note) from 1 for 120);

  update public.room_pets
  set is_sleeping = true,
      sleep_note = v_sanitized_note,
      sleep_started_at = now(),
      current_action = 'idle',
      action_ends_at = null,
      last_action_by = v_caller,
      last_action_type = 'sleep',
      last_action_at = now(),
      hunger = v_pet.hunger,
      affection = v_pet.affection,
      energy = v_pet.energy,
      stats_updated_at = now()
  where room_id = p_room_id
  returning * into v_pet;

  insert into public.pet_events (room_id, actor_id, type, note)
  values (p_room_id, v_caller, 'sleep', v_sanitized_note);

  return v_pet;
end;
$$ language plpgsql security definer;

-- Kediyi Uyandır (Uykuda geçen süreye göre enerji dolar)
create or replace function public.pet_wake(p_room_id uuid)
returns public.room_pets as $$
declare
  v_pet public.room_pets;
  v_caller uuid := auth.uid();
begin
  select * into v_pet from public.room_pets where room_id = p_room_id for update;
  if not found then
    return null;
  end if;

  if not v_pet.is_sleeping then
    return v_pet;
  end if;

  -- Uyku süresi decay & enerji dolumunu hesapla
  v_pet := public.pet_compute_decay(v_pet, now());

  update public.room_pets
  set is_sleeping = false,
      sleep_note = null,
      sleep_started_at = null,
      current_action = 'idle',
      action_ends_at = null,
      last_action_by = v_caller,
      last_action_type = 'wake',
      last_action_at = now(),
      hunger = v_pet.hunger,
      affection = v_pet.affection,
      energy = v_pet.energy,
      stats_updated_at = now()
  where room_id = p_room_id
  returning * into v_pet;

  insert into public.pet_events (room_id, actor_id, type)
  values (p_room_id, v_caller, 'wake');

  return v_pet;
end;
$$ language plpgsql security definer;
