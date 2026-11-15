-- ============================================================================
-- BOARD GAME TOOLS (BGameT) - SUPABASE DATABASE SCHEMA & POLICIES
-- ============================================================================

-- 1. USERS TABLE
create table if not exists public.users (
    id uuid primary key default gen_random_uuid(),
    email text unique not null,
    confirmed boolean default false,
    created_at timestamp with time zone default timezone('utc'::text, now()) not null
);

-- 2. GAMES (STORE & CATALOG)
create table if not exists public.games (
    id text primary key,
    author_id text not null,
    title text not null,
    description text default '',
    config jsonb not null,
    is_public boolean default true,
    lang text default 'uk',
    likes integer default 0,
    created_at timestamp with time zone default timezone('utc'::text, now()) not null
);

-- 3. GAME SESSIONS (MULTIPLAYER ROOMS)
create table if not exists public.game_sessions (
    id text primary key,
    game_config_id text,
    host_id text not null,
    state jsonb not null default '{}'::jsonb,
    updated_at timestamp with time zone default timezone('utc'::text, now()) not null,
    is_active boolean default true
);

-- 4. GAME STATE EVENTS (AUDIT / EVENT LOG)
create table if not exists public.game_state_events (
    id uuid primary key default gen_random_uuid(),
    session_id text not null references public.game_sessions(id) on delete cascade,
    player_id text not null,
    event_type text not null,
    payload jsonb not null default '{}'::jsonb,
    created_at timestamp with time zone default timezone('utc'::text, now()) not null
);

-- INDEXES FOR PERFORMANCE
create index if not exists idx_games_lang on public.games(lang);
create index if not exists idx_games_public on public.games(is_public);
create index if not exists idx_sessions_active on public.game_sessions(is_active);
create index if not exists idx_state_events_session on public.game_state_events(session_id);

-- ENABLE ROW LEVEL SECURITY (RLS)
alter table public.users enable row level security;
alter table public.games enable row level security;
alter table public.game_sessions enable row level security;
alter table public.game_state_events enable row level security;

-- OPEN POLICIES (FOR ANON ACCESS AS PER ARCHITECTURE)
create policy "Allow read games for all" on public.games for select using (true);
create policy "Allow insert games for all" on public.games for insert with check (true);
create policy "Allow update games for all" on public.games for update using (true);

create policy "Allow read game_sessions for all" on public.game_sessions for select using (true);
create policy "Allow insert game_sessions for all" on public.game_sessions for insert with check (true);
create policy "Allow update game_sessions for all" on public.game_sessions for update using (true);

create policy "Allow all game_state_events" on public.game_state_events for all using (true) with check (true);
create policy "Allow all users" on public.users for all using (true) with check (true);

-- REALTIME REPLICATION SETUP
-- In Supabase SQL Editor run:
-- alter publication supabase_realtime add table public.game_sessions;
-- alter publication supabase_realtime add table public.game_state_events;
