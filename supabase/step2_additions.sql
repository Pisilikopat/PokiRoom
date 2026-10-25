-- =====================================================================
-- PokiRoom - Adım 2: SQL Eklemeleri (Step 1 kurulumundan SONRA çalıştırın)
-- =====================================================================

-- 1) Güvenlik: istemci users tablosunda sadece bu kolonları güncelleyebilsin
--    (current_room_id gibi alanlar sadece sunucu fonksiyonlarıyla değişir)
revoke update on public.users from authenticated, anon;
grant update (custom_tag, nickname, mood_emoji, mood_text, is_online, fcm_token)
  on public.users to authenticated;

-- 2) İstek ekleme artık sadece send_knock() üzerinden olsun
drop policy if exists "requests_insert_as_sender" on public.room_requests;

-- 3) Odaya Tıklat: PokiCode ile istek gönder
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
begin
  if v_me is null then raise exception 'not_authenticated'; end if;

  select id, current_room_id into v_target, v_target_room
  from public.users
  where upper(custom_tag) = upper(trim(p_tag));

  if v_target is null then raise exception 'user_not_found'; end if;
  if v_target = v_me then raise exception 'cannot_knock_self'; end if;

  select current_room_id into v_my_room from public.users where id = v_me;
  if v_my_room is not null then raise exception 'sender_busy'; end if;
  if v_target_room is not null then raise exception 'receiver_busy'; end if;

  insert into public.room_requests (sender_id, receiver_id, knock_message)
  values (v_me, v_target, nullif(trim(coalesce(p_message, '')), ''))
  returning id into v_id;

  return v_id;
exception
  when unique_violation then
    raise exception 'duplicate_request';
end;
$$;

-- 4) İsteği kabul et: oda oluştur, iki kullanıcıyı odaya bağla
create or replace function public.accept_room_request(p_request_id uuid)
returns uuid
language plpgsql
security definer
set search_path = public
as $$
declare
  v_me   uuid := auth.uid();
  v_req  public.room_requests;
  v_room uuid;
begin
  select * into v_req
  from public.room_requests
  where id = p_request_id and receiver_id = v_me and status = 'pending'
  for update;

  if not found then raise exception 'request_not_found'; end if;

  if exists (
    select 1 from public.users
    where id in (v_req.sender_id, v_me) and current_room_id is not null
  ) then
    raise exception 'user_busy';
  end if;

  insert into public.rooms (user1_id, user2_id)
  values (v_req.sender_id, v_me)
  returning id into v_room;

  update public.users set current_room_id = v_room
  where id in (v_req.sender_id, v_me);

  update public.room_requests set status = 'accepted' where id = p_request_id;

  -- Artık meşgul olan iki kişiyle ilgili diğer bekleyen istekleri kapat
  update public.room_requests set status = 'rejected'
  where status = 'pending'
    and id <> p_request_id
    and (receiver_id in (v_req.sender_id, v_me) or sender_id in (v_req.sender_id, v_me));

  return v_room;
end;
$$;
