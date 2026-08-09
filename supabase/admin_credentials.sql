-- Admin credential management for Fixit GH
-- Run this in the Supabase SQL Editor once.

-- 1) Store login password for admin visibility / edits (dev / coursework use).
alter table public.users
  add column if not exists password text;

-- 2) Admin-only RPC: update profile + Auth email/password together.
create or replace function public.admin_update_account(
  p_user_id text,
  p_name text,
  p_email text,
  p_phone text,
  p_location text,
  p_role text,
  p_password text default null,
  p_is_suspended boolean default null
)
returns void
language plpgsql
security definer
set search_path = public, auth, extensions
as $$
declare
  caller_id text := auth.uid()::text;
  new_password text;
begin
  if caller_id is null or not exists (
    select 1 from public.users
    where id = caller_id and role = 'admin'
  ) then
    raise exception 'Only signed-in admins can update accounts';
  end if;

  if p_user_id is null or length(trim(p_user_id)) = 0 then
    raise exception 'User id is required';
  end if;

  new_password := nullif(trim(coalesce(p_password, '')), '');

  update public.users
  set
    name = coalesce(nullif(trim(p_name), ''), name),
    email = coalesce(nullif(trim(p_email), ''), email),
    phone = nullif(trim(coalesce(p_phone, '')), ''),
    location = nullif(trim(coalesce(p_location, '')), ''),
    role = coalesce(nullif(trim(p_role), ''), role),
    password = case
      when new_password is not null and length(new_password) >= 6
        then new_password
      else password
    end,
    "isSuspended" = coalesce(p_is_suspended, "isSuspended"),
    "updatedAt" = now()
  where id = p_user_id;

  if not found then
    raise exception 'User not found';
  end if;

  -- Keep artisan profile display fields in sync when present.
  update public.artisans
  set
    name = coalesce(nullif(trim(p_name), ''), name),
    email = coalesce(nullif(trim(p_email), ''), email),
    phone = nullif(trim(coalesce(p_phone, '')), ''),
    location = nullif(trim(coalesce(p_location, '')), ''),
    "updatedAt" = now()
  where id = p_user_id or "userId" = p_user_id;

  -- Sync Auth email / password so login still works.
  begin
    update auth.users
    set
      email = coalesce(nullif(trim(p_email), ''), email),
      encrypted_password = case
        when new_password is not null and length(new_password) >= 6
          then crypt(new_password, gen_salt('bf'))
        else encrypted_password
      end,
      email_confirmed_at = coalesce(email_confirmed_at, now()),
      updated_at = now()
    where id = p_user_id::uuid;
  exception
    when others then
      -- Profile row still updated even if Auth sync fails on some projects.
      raise notice 'Auth sync skipped: %', SQLERRM;
  end;
end;
$$;

grant execute on function public.admin_update_account(
  text, text, text, text, text, text, text, boolean
) to authenticated, anon;
