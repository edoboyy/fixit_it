-- Fixit GH – fix Row Level Security (run this in SQL Editor)
-- This stops the "violates row-level security policy for table users" error

-- Option A (simplest for school projects): turn RLS off
alter table if exists public.users disable row level security;
alter table if exists public.artisans disable row level security;
alter table if exists public.bookings disable row level security;
alter table if exists public.reviews disable row level security;
alter table if exists public.payments disable row level security;
alter table if exists public.notifications disable row level security;

-- Option B policies (if you prefer RLS on, uncomment below and comment Option A)
-- alter table public.users enable row level security;
-- drop policy if exists "fixit_dev_users" on public.users;
-- create policy "fixit_dev_users" on public.users for all to anon, authenticated using (true) with check (true);
--
-- alter table public.artisans enable row level security;
-- drop policy if exists "fixit_dev_artisans" on public.artisans;
-- create policy "fixit_dev_artisans" on public.artisans for all to anon, authenticated using (true) with check (true);
--
-- alter table public.bookings enable row level security;
-- drop policy if exists "fixit_dev_bookings" on public.bookings;
-- create policy "fixit_dev_bookings" on public.bookings for all to anon, authenticated using (true) with check (true);
--
-- alter table public.reviews enable row level security;
-- drop policy if exists "fixit_dev_reviews" on public.reviews;
-- create policy "fixit_dev_reviews" on public.reviews for all to anon, authenticated using (true) with check (true);
--
-- alter table public.payments enable row level security;
-- drop policy if exists "fixit_dev_payments" on public.payments;
-- create policy "fixit_dev_payments" on public.payments for all to anon, authenticated using (true) with check (true);
--
-- alter table public.notifications enable row level security;
-- drop policy if exists "fixit_dev_notifications" on public.notifications;
-- create policy "fixit_dev_notifications" on public.notifications for all to anon, authenticated using (true) with check (true);
