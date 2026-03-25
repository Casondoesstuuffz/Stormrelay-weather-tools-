-- ══════════════════════════════════════════════════════════════════
-- StormRelay — Complete Database Setup
-- Run this once in Supabase → SQL Editor → New Query → Run
-- ══════════════════════════════════════════════════════════════════


-- ── 1. REPORTS TABLE ─────────────────────────────────────────────
-- Main table. Stores all storm reports from StormRelay and StormShots.

create table if not exists reports (
  id             uuid primary key default gen_random_uuid(),
  submitted_by   text not null,
  severity       text,
  notes          text,
  lat            double precision,
  lng            double precision,
  damage_track   jsonb,
  photo_url      text,
  source         text,          -- 'stormshots' = public submission, null = StormRelay crew
  expires_at     timestamptz,   -- set by StormShots for auto-cleanup after 12 hours
  intended_channel text,        -- optional channel targeting from StormShots
  cloud_feature  text,          -- mesocyclone, shelf cloud, anvil, etc.
  damage_tag     text,          -- post-event EF rating (EF0-EF5, PDS)
  created_at     timestamptz default now()
);

alter table reports enable row level security;

-- Public can read all reports (the receive feed is public)
create policy "public read"   on reports for select to anon using (true);
-- Anyone can insert (role enforcement is handled in the app JS)
create policy "anon insert"   on reports for insert to anon with check (true);
-- Anyone can delete (role enforcement is handled in the app JS)
create policy "anon delete"   on reports for delete to anon using (true);

-- Index for fast expiry queries
create index if not exists reports_expires_at_idx
  on reports(expires_at)
  where expires_at is not null;

-- Add to realtime publication so live updates work
alter publication supabase_realtime add table reports;


-- ── 2. USERS TABLE ────────────────────────────────────────────────
-- Stores StormRelay accounts. Passwords are PBKDF2-hashed client-side.
-- Roles: viewer | sender | deleter | admin

create table if not exists sr_users (
  id             uuid primary key default gen_random_uuid(),
  username       text unique not null,
  password_hash  text not null,
  password_salt  text,
  role           text not null default 'viewer',
  created_at     timestamptz default now()
);

alter table sr_users enable row level security;

create policy "anon read"   on sr_users for select using (true);
create policy "anon insert" on sr_users for insert with check (true);
create policy "anon update" on sr_users for update using (true);
create policy "anon delete" on sr_users for delete using (true);


-- ── 3. CONTACTS TABLE ─────────────────────────────────────────────
-- Stores pinned contacts for the calls panel in StormRelay.

create table if not exists contacts (
  id         uuid primary key default gen_random_uuid(),
  name       text not null,
  handle     text not null,
  created_at timestamptz default now()
);

alter table contacts enable row level security;

create policy "anon read"   on contacts for select using (true);
create policy "anon insert" on contacts for insert with check (true);
create policy "anon delete" on contacts for delete using (true);


-- ── 4. AUTO-CLEANUP (OPTIONAL) ────────────────────────────────────
-- StormShots photos auto-delete after 12 hours.
-- This pg_cron job handles cleanup server-side every 30 minutes.
-- Requires the pg_cron extension — enable it first in
-- Supabase dashboard → Database → Extensions → pg_cron

-- create extension if not exists pg_cron;

-- select cron.schedule(
--   'stormshots-cleanup',
--   '*/30 * * * *',
--   $$
--     delete from reports
--     where expires_at is not null
--       and expires_at < now();
--   $$
-- );

-- Optional: also clean up photo files from Storage
-- select cron.schedule(
--   'stormshots-storage-cleanup',
--   '0 * * * *',
--   $$
--     delete from storage.objects
--     where bucket_id = 'photos'
--       and created_at < now() - interval '12 hours';
--   $$
-- );


-- ── 5. STORAGE BUCKET ─────────────────────────────────────────────
-- Create this manually in Supabase dashboard → Storage → New bucket
-- Name: photos
-- Public: YES (so photo URLs work without auth)
-- You also need to add a storage policy:
--   Supabase → Storage → photos → Policies → New policy
--   Allow INSERT for anon role
-- Or run:

-- insert into storage.buckets (id, name, public)
-- values ('photos', 'photos', true)
-- on conflict do nothing;

-- create policy "anon upload photos"
--   on storage.objects for insert
--   to anon
--   with check (bucket_id = 'photos');
