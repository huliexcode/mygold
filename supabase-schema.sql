-- Run this file once in Supabase Dashboard > SQL Editor.
-- Also enable Authentication > Providers > Anonymous before opening the platform.

create table if not exists public.ai_portfolio_data (
    user_id uuid primary key references auth.users(id) on delete cascade,
    data jsonb not null default '{}'::jsonb,
    updated_at timestamptz not null default now()
);

alter table public.ai_portfolio_data enable row level security;

drop policy if exists "Users can read their portfolio" on public.ai_portfolio_data;
create policy "Users can read their portfolio"
on public.ai_portfolio_data
for select
to authenticated
using ((select auth.uid()) = user_id);

drop policy if exists "Users can insert their portfolio" on public.ai_portfolio_data;
create policy "Users can insert their portfolio"
on public.ai_portfolio_data
for insert
to authenticated
with check ((select auth.uid()) = user_id);

drop policy if exists "Users can update their portfolio" on public.ai_portfolio_data;
create policy "Users can update their portfolio"
on public.ai_portfolio_data
for update
to authenticated
using ((select auth.uid()) = user_id)
with check ((select auth.uid()) = user_id);

create or replace function public.set_ai_portfolio_updated_at()
returns trigger
language plpgsql
security invoker
set search_path = ''
as $$
begin
    new.updated_at = now();
    return new;
end;
$$;

drop trigger if exists set_ai_portfolio_updated_at on public.ai_portfolio_data;
create trigger set_ai_portfolio_updated_at
before update on public.ai_portfolio_data
for each row execute function public.set_ai_portfolio_updated_at();

do $$
begin
    alter publication supabase_realtime add table public.ai_portfolio_data;
exception
    when duplicate_object then null;
end;
$$;
