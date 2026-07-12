-- InkBill AI PostgreSQL Schema
-- Run this in the Supabase SQL editor or as a migration.

-- 0. EXTENSIONS
create extension if not exists "pgcrypto";

-- 1. PROFILES
create table if not exists public.profiles (
  id            uuid primary key references auth.users(id) on delete cascade,
  full_name     text not null,
  phone         text,
  created_at    timestamptz not null default now(),
  updated_at    timestamptz not null default now()
);

-- 2. SHOPS
create table if not exists public.shops (
  id              uuid primary key default gen_random_uuid(),
  name            text not null,
  owner_id        uuid not null references public.profiles(id) on delete cascade,
  address         text,
  phone           text,
  tax_information text,
  receipt_settings jsonb default '{}'::jsonb,
  created_at      timestamptz not null default now(),
  updated_at      timestamptz not null default now()
);

-- 3. SHOP MEMBERS
create table if not exists public.shop_members (
  id         uuid primary key default gen_random_uuid(),
  shop_id    uuid not null references public.shops(id) on delete cascade,
  user_id    uuid not null references public.profiles(id) on delete cascade,
  role       text not null check (role in ('owner', 'manager', 'cashier')),
  is_active  boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique(shop_id, user_id)
);

-- 4. CUSTOMERS
create table if not exists public.customers (
  id         uuid primary key default gen_random_uuid(),
  shop_id    uuid not null references public.shops(id) on delete cascade,
  name       text not null,
  phone      text,
  email      text,
  address    text,
  gstin      text,
  created_by uuid references public.profiles(id),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  deleted_at timestamptz
);

-- 5. PRODUCTS
create table if not exists public.products (
  id             uuid primary key default gen_random_uuid(),
  shop_id        uuid not null references public.shops(id) on delete cascade,
  name           text not null,
  sku            text,
  barcode        text,
  selling_price  numeric(12,2) not null check (selling_price >= 0),
  stock_quantity numeric(12,2) not null default 0 check (stock_quantity >= 0),
  gst_rate       numeric(5,2) check (gst_rate >= 0 and gst_rate <= 100),
  hsn_code       text,
  unit           text,
  created_by     uuid references public.profiles(id),
  created_at     timestamptz not null default now(),
  updated_at     timestamptz not null default now(),
  deleted_at     timestamptz
);

-- 6. BILLS
create table if not exists public.bills (
  id                  uuid primary key default gen_random_uuid(),
  shop_id             uuid not null references public.shops(id) on delete cascade,
  bill_number         text not null,
  customer_id         uuid references public.customers(id),
  customer_name_snapshot text,
  subtotal            numeric(12,2) not null check (subtotal >= 0),
  discount            numeric(12,2) not null default 0 check (discount >= 0),
  tax_rate            numeric(5,2) not null default 0 check (tax_rate >= 0 and tax_rate <= 100),
  tax_amount          numeric(12,2) not null default 0 check (tax_amount >= 0),
  grand_total         numeric(12,2) not null check (grand_total >= 0),
  status              text not null default 'draft' check (status in ('draft', 'finalized', 'cancelled')),
  notes               text,
  created_by          uuid not null references public.profiles(id),
  finalized_by        uuid references public.profiles(id),
  finalized_at        timestamptz,
  cancelled_by        uuid references public.profiles(id),
  cancelled_at        timestamptz,
  cancellation_reason text,
  created_at          timestamptz not null default now(),
  updated_at          timestamptz not null default now(),
  unique(shop_id, bill_number)
);

-- 7. BILL ITEMS
create table if not exists public.bill_items (
  id         uuid primary key default gen_random_uuid(),
  bill_id    uuid not null references public.bills(id) on delete cascade,
  shop_id    uuid not null references public.shops(id) on delete cascade,
  product_id uuid references public.products(id),
  item_name  text not null,
  quantity   numeric(12,2) not null check (quantity > 0),
  rate       numeric(12,2) not null check (rate >= 0),
  amount     numeric(12,2) not null check (amount >= 0),
  gst_rate   numeric(5,2) check (gst_rate >= 0 and gst_rate <= 100),
  hsn_code   text,
  created_at timestamptz not null default now()
);

-- 8. INK DOCUMENTS
create table if not exists public.ink_documents (
  id            uuid primary key default gen_random_uuid(),
  shop_id       uuid not null references public.shops(id) on delete cascade,
  bill_id       uuid references public.bills(id),
  title         text,
  storage_path  text,
  stroke_count  integer not null default 0,
  local_version integer not null default 1,
  cloud_version integer not null default 1,
  created_by    uuid not null references public.profiles(id),
  created_at    timestamptz not null default now(),
  updated_at    timestamptz not null default now(),
  deleted_at    timestamptz
);

-- 9. AUDIT LOGS
create table if not exists public.audit_logs (
  id          uuid primary key default gen_random_uuid(),
  shop_id     uuid not null references public.shops(id) on delete cascade,
  user_id     uuid not null references public.profiles(id),
  action      text not null,
  entity_type text not null,
  entity_id   text,
  metadata    jsonb default '{}'::jsonb,
  created_at  timestamptz not null default now()
);

-- INDEXES
create index if not exists idx_customers_shop on public.customers(shop_id);
create index if not exists idx_customers_name on public.customers(shop_id, name);
create index if not exists idx_products_shop on public.products(shop_id);
create index if not exists idx_products_name on public.products(shop_id, name);
create index if not exists idx_bills_shop on public.bills(shop_id);
create index if not exists idx_bills_status on public.bills(shop_id, status);
create index if not exists idx_bills_created on public.bills(shop_id, created_at desc);
create index if not exists idx_bill_items_bill on public.bill_items(bill_id);
create index if not exists idx_ink_documents_shop on public.ink_documents(shop_id);
create index if not exists idx_audit_logs_shop on public.audit_logs(shop_id);
create index if not exists idx_audit_logs_created on public.audit_logs(shop_id, created_at desc);
create index if not exists idx_shop_members_user on public.shop_members(user_id);
create index if not exists idx_shop_members_shop on public.shop_members(shop_id);

-- AUTO-UPDATE updated_at TRIGGER
create or replace function public.update_updated_at()
returns trigger as $$
begin
  new.updated_at = now();
  return new;
end;
$$ language plpgsql;

do $$
declare
  t text;
begin
  for t in select table_name from information_schema.tables
    where table_schema = 'public' and table_name in (
      'profiles', 'shops', 'shop_members', 'customers', 'products', 'bills', 'ink_documents'
    )
  loop
    execute format('
      create trigger if not exists trg_%s_updated_at
        before update on public.%I
        for each row execute function public.update_updated_at()',
      t, t);
  end loop;
end;
$$;
