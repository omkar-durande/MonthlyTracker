-- ============================================================
-- MonthlyGoals — Supabase Postgres Schema + Row Level Security
-- Run this in Supabase SQL Editor (Dashboard → SQL Editor → New query)
-- ============================================================

-- ----------------------------------------------------------------
-- 1. PROFILES
-- ----------------------------------------------------------------
create table public.profiles (
  id         uuid references auth.users on delete cascade primary key,
  full_name  text not null,
  created_at timestamptz default now()
);

-- Auto-create profile on sign-up
create or replace function public.handle_new_user()
returns trigger language plpgsql security definer as $$
begin
  insert into public.profiles (id, full_name)
  values (
    new.id,
    coalesce(new.raw_user_meta_data->>'full_name', new.email)
  )
  on conflict (id) do nothing;
  return new;
end;
$$;

create or replace trigger on_auth_user_created
  after insert on auth.users
  for each row execute function public.handle_new_user();

alter table public.profiles enable row level security;
create policy "profiles_own" on public.profiles
  for all using (auth.uid() = id);

-- ----------------------------------------------------------------
-- 2. GOALS
-- ----------------------------------------------------------------
create table public.goals (
  id            uuid default gen_random_uuid() primary key,
  user_id       uuid references auth.users on delete cascade not null,
  title         text not null,
  description   text,
  emoji         text default '🎯',
  color         text default '#6366F1',
  target_value  numeric,
  current_value numeric default 0,
  deadline      date,
  status        text default 'active'
                  check (status in ('active','achieved','missed')),
  month         text not null,       -- 'YYYY-MM'
  is_recurring  boolean default false,
  created_at    timestamptz default now(),
  updated_at    timestamptz default now()
);

create index goals_user_month on public.goals(user_id, month);

alter table public.goals enable row level security;
create policy "goals_own" on public.goals
  for all using (auth.uid() = user_id);

-- ----------------------------------------------------------------
-- 3. TASKS
-- ----------------------------------------------------------------
create table public.tasks (
  id           uuid default gen_random_uuid() primary key,
  user_id      uuid references auth.users on delete cascade not null,
  goal_id      uuid references public.goals(id) on delete set null,
  title        text not null,
  description  text,
  deadline     timestamptz,
  priority     text default 'medium'
                 check (priority in ('low','medium','high')),
  status       text default 'pending'
                 check (status in ('pending','in_progress','completed')),
  category     text,
  month        text not null,        -- 'YYYY-MM'
  carried_from uuid references public.tasks(id) on delete set null,
  is_recurring boolean default false,
  completed_at timestamptz,
  created_at   timestamptz default now(),
  updated_at   timestamptz default now()
);

create index tasks_user_month on public.tasks(user_id, month);
create index tasks_user_status on public.tasks(user_id, status);

alter table public.tasks enable row level security;
create policy "tasks_own" on public.tasks
  for all using (auth.uid() = user_id);

-- ----------------------------------------------------------------
-- 4. HABIT CHECK-INS
-- ----------------------------------------------------------------
create table public.habit_checkins (
  id       uuid default gen_random_uuid() primary key,
  user_id  uuid references auth.users on delete cascade not null,
  goal_id  uuid references public.goals(id) on delete cascade not null,
  date     date not null,
  unique(user_id, goal_id, date)
);

create index checkins_goal on public.habit_checkins(goal_id, date);

alter table public.habit_checkins enable row level security;
create policy "checkins_own" on public.habit_checkins
  for all using (auth.uid() = user_id);

-- ----------------------------------------------------------------
-- 5. MONTHLY REPORTS
-- ----------------------------------------------------------------
create table public.monthly_reports (
  id           uuid default gen_random_uuid() primary key,
  user_id      uuid references auth.users on delete cascade not null,
  month        text not null,         -- 'YYYY-MM'
  total        int default 0,
  completed    int default 0,
  on_time      int default 0,
  efficiency   numeric default 0,
  summary_json jsonb default '{}'::jsonb,
  created_at   timestamptz default now(),
  unique(user_id, month)
);

alter table public.monthly_reports enable row level security;
create policy "reports_own" on public.monthly_reports
  for all using (auth.uid() = user_id);

-- ----------------------------------------------------------------
-- 6. ENABLE REALTIME (optional)
-- ----------------------------------------------------------------
-- In Supabase dashboard: Database → Replication → Add tables:
-- tasks, goals, habit_checkins
--
-- Or run:
-- alter publication supabase_realtime add table public.tasks;
-- alter publication supabase_realtime add table public.goals;
-- alter publication supabase_realtime add table public.habit_checkins;

-- ----------------------------------------------------------------
-- 7. STORAGE (optional, for future profile pictures)
-- ----------------------------------------------------------------
-- insert into storage.buckets (id, name, public) values ('avatars', 'avatars', true);
-- create policy "Avatar public read" on storage.objects
--   for select using (bucket_id = 'avatars');
-- create policy "Avatar own upload" on storage.objects
--   for insert with check (bucket_id = 'avatars' and auth.uid()::text = (storage.foldername(name))[1]);
