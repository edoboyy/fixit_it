-- Fixit GH – Supabase schema
-- Run this once in: Supabase Dashboard → SQL Editor → New query → Run

-- USERS
create table if not exists public.users (
  id text primary key,
  name text not null,
  email text not null unique,
  phone text,
  role text not null default 'customer',
  "photoUrl" text,
  location text,
  password text,
  "isSuspended" boolean not null default false,
  "createdAt" timestamptz default now(),
  "updatedAt" timestamptz default now()
);

-- ARTISANS
create table if not exists public.artisans (
  id text primary key,
  "userId" text not null,
  name text not null,
  email text not null,
  phone text,
  category text not null default '',
  skills jsonb not null default '[]'::jsonb,
  bio text,
  "photoUrl" text,
  location text,
  latitude double precision,
  longitude double precision,
  rating double precision not null default 0,
  "reviewCount" integer not null default 0,
  "hourlyRate" double precision not null default 0,
  "isAvailable" boolean not null default true,
  "isVerified" boolean not null default false,
  experience text,
  "nationalId" text,
  "certificateUrl" text,
  "createdAt" timestamptz default now(),
  "updatedAt" timestamptz default now()
);

-- BOOKINGS
create table if not exists public.bookings (
  id text primary key,
  "customerId" text not null,
  "artisanId" text not null,
  "serviceCategory" text not null,
  description text not null default '',
  status text not null default 'pending',
  "scheduledDate" timestamptz not null,
  location text not null default '',
  latitude double precision,
  longitude double precision,
  "estimatedPrice" double precision not null default 0,
  "finalPrice" double precision,
  notes text,
  "customerConfirmedAt" timestamptz,
  "paymentReleasedAt" timestamptz,
  "hasReviewed" boolean not null default false,
  "createdAt" timestamptz default now(),
  "updatedAt" timestamptz default now()
);

-- REVIEWS
create table if not exists public.reviews (
  id text primary key,
  "bookingId" text not null,
  "customerId" text not null,
  "artisanId" text not null,
  rating double precision not null,
  comment text,
  "customerName" text,
  "createdAt" timestamptz default now(),
  "updatedAt" timestamptz default now()
);

-- PAYMENTS
create table if not exists public.payments (
  id text primary key,
  "bookingId" text not null,
  "customerId" text not null,
  "artisanId" text not null,
  amount double precision not null,
  currency text not null default 'GHS',
  status text not null default 'pending',
  method text not null default 'mobileMoney',
  "transactionId" text,
  reference text,
  "createdAt" timestamptz default now(),
  "updatedAt" timestamptz default now()
);

-- NOTIFICATIONS
create table if not exists public.notifications (
  id text primary key,
  "userId" text not null,
  title text not null,
  body text not null,
  type text not null,
  "bookingId" text,
  "isRead" boolean not null default false,
  "createdAt" timestamptz default now()
);

-- Open access for school/dev (tighten later for production)
alter table public.users disable row level security;
alter table public.artisans disable row level security;
alter table public.bookings disable row level security;
alter table public.reviews disable row level security;
alter table public.payments disable row level security;
alter table public.notifications disable row level security;

-- Also allow all via policies if RLS gets turned back on by the dashboard
drop policy if exists "fixit_dev_users" on public.users;
create policy "fixit_dev_users" on public.users for all to anon, authenticated using (true) with check (true);
drop policy if exists "fixit_dev_artisans" on public.artisans;
create policy "fixit_dev_artisans" on public.artisans for all to anon, authenticated using (true) with check (true);
drop policy if exists "fixit_dev_bookings" on public.bookings;
create policy "fixit_dev_bookings" on public.bookings for all to anon, authenticated using (true) with check (true);
drop policy if exists "fixit_dev_reviews" on public.reviews;
create policy "fixit_dev_reviews" on public.reviews for all to anon, authenticated using (true) with check (true);
drop policy if exists "fixit_dev_payments" on public.payments;
create policy "fixit_dev_payments" on public.payments for all to anon, authenticated using (true) with check (true);
drop policy if exists "fixit_dev_notifications" on public.notifications;
create policy "fixit_dev_notifications" on public.notifications for all to anon, authenticated using (true) with check (true);

-- Realtime for live booking/notification updates
alter publication supabase_realtime add table public.bookings;
alter publication supabase_realtime add table public.notifications;

-- Storage bucket for artisan certificates
insert into storage.buckets (id, name, public)
values ('certificates', 'certificates', true)
on conflict (id) do nothing;

create policy "Public read certificates"
on storage.objects for select
using (bucket_id = 'certificates');

create policy "Auth upload certificates"
on storage.objects for insert
with check (bucket_id = 'certificates');

create policy "Auth update certificates"
on storage.objects for update
using (bucket_id = 'certificates');
