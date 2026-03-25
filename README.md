# StormRelay

A real-time severe weather ops platform for storm spotters, chasers, and weather content creators.
Three standalone HTML files — no build step, no framework, no server required.

Built by CasonWX. Open-sourced for the weather community.

---

## What's included

| File | Purpose |
|------|---------|
| `stormrelay.html` | Full ops dashboard — submit reports, live feed, map, user auth, admin panel, WebRTC calls |
| `stormview.html` | Public read-only feed — live reports, map, photo lightbox, channel filter |
| `stormshots.html` | Public photo submission — EXIF verification, 48hr window, cloud/damage tagging |
| `setup.sql` | Complete Supabase database setup — run once and you're ready |

---

## Stack

- **Backend:** Supabase (Postgres + Realtime + Storage)
- **Maps:** Leaflet.js with CartoDB dark tiles
- **EXIF parsing:** exifr (CDN)
- **Auth:** Custom PBKDF2 hashed passwords stored in Postgres
- **Hosting:** Any static file host (Netlify, Vercel, GitHub Pages, etc.)

Everything runs in the browser. No Node.js, no build tools, no dependencies to install.

---

## Setup

### Step 1 — Create a Supabase project

1. Go to [supabase.com](https://supabase.com) and create a free account
2. Create a new project — note your **Project URL** and **anon public key**
   (both found in Settings → API)

### Step 2 — Run the database setup

1. In your Supabase project, go to **SQL Editor → New Query**
2. Paste the contents of `setup.sql` and click **Run**
3. You should see "Success. No rows returned"

### Step 3 — Create the photos storage bucket

1. Go to **Storage → New bucket**
2. Name: `photos`
3. Toggle **Public bucket** to ON
4. Go to the bucket → **Policies → New policy**
5. Choose "Give users access to a folder" → select **INSERT** for **anon** role

### Step 4 — Add your Supabase credentials

Open all three HTML files and replace the two placeholder values near the top of each `<script>` block:

```javascript
const SUPA_URL = 'YOUR_SUPABASE_URL';   // e.g. https://abcdefgh.supabase.co
const SUPA_KEY = 'YOUR_SUPABASE_ANON_KEY'; // starts with eyJ...
```

### Step 5 — Deploy

Drag and drop any or all of the HTML files onto [Netlify Drop](https://app.netlify.com/drop)
or any static file host. Each file is fully self-contained.

You can also run locally with:
```bash
python3 -m http.server 8080
# Then open http://localhost:8080/stormrelay.html
```

---

## Creating your admin account

1. Open StormRelay and click **Sign In → Create Account**
2. After signing up, go to Supabase → **Table Editor → sr_users**
3. Find your username and change the `role` column to `admin`
4. Sign out and back in — the ⚙ Admin panel will now appear

---

## Roles

| Role | Can do |
|------|--------|
| `viewer` | View the receive feed only |
| `sender` | Submit reports |
| `deleter` | Submit and delete reports |
| `admin` | Everything + manage all user roles |

The legacy invite code system allows quick sender access without an account.
Set `LEGACY_HASH` and `LEGACY_SALT` in stormrelay.html to use this feature
(see the code comments for how to generate a PBKDF2 hash).

---

## Participating channels (StormShots)

The "Participating Channels" drawer in StormShots is hardcoded in the HTML.
To update it with your own channels, find the `#creators-body` div and replace
the creator rows with your own channel names, handles, and avatar images.

Avatars can be:
- Base64 embedded (recommended for reliability): use a tool like squoosh.app to resize to 80×80 and convert to base64
- External URL: any publicly accessible image URL

---

## Auto-cleanup for StormShots

Photos submitted through StormShots are tagged with a 12-hour expiry.
To enable automatic cleanup, uncomment the pg_cron section at the bottom
of `setup.sql` and run it after enabling the pg_cron extension in
Supabase → Database → Extensions.

---

## Realtime

For live report updates to work, make sure the reports table is added to the
Supabase Realtime publication. The setup.sql does this automatically, but if
you run into issues you can run this manually:

```sql
alter publication supabase_realtime add table reports;
```

---

## Wipe all reports (keep user accounts)

```sql
-- Wipe reports only — user accounts untouched
delete from reports;

-- Also wipe photo files from storage (via Supabase dashboard)
-- Storage → photos bucket → select all → Delete
```

---

## License

MIT License — free to use, modify, and distribute.
Credit appreciated but not required.

If you build something cool with this, tag @CasonWX.
