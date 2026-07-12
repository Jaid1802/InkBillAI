-- Row Level Security for InkBill AI
-- CRITICAL: These policies enforce shop-level data isolation.

-- Helper function: get the shop_ids the current user has active membership in
create or replace function public.user_shops()
returns setof uuid
language sql
stable
security definer
as $$
  select shop_id from public.shop_members
  where user_id = auth.uid()
    and is_active = true;
$$;

-- Helper function: check if current user has a given role in a shop
create or replace function public.has_role(p_shop_id uuid, p_role text)
returns boolean
language sql
stable
security definer
as $$
  select exists (
    select 1 from public.shop_members
    where shop_id = p_shop_id
      and user_id = auth.uid()
      and role = p_role
      and is_active = true
  );
$$;

-- Helper function: check if current user is a member of a shop (any role)
create or replace function public.is_shop_member(p_shop_id uuid)
returns boolean
language sql
stable
security definer
as $$
  select exists (
    select 1 from public.shop_members
    where shop_id = p_shop_id
      and user_id = auth.uid()
      and is_active = true
  );
$$;

-- ============================================================
-- ENABLE RLS ON ALL TABLES
-- ============================================================

alter table public.profiles enable row level security;
alter table public.shops enable row level security;
alter table public.shop_members enable row level security;
alter table public.customers enable row level security;
alter table public.products enable row level security;
alter table public.bills enable row level security;
alter table public.bill_items enable row level security;
alter table public.ink_documents enable row level security;
alter table public.audit_logs enable row level security;

-- ============================================================
-- PROFILES
-- ============================================================

create policy "Users can view their own profile"
  on public.profiles for select
  using (id = auth.uid());

create policy "Users can update their own profile"
  on public.profiles for update
  using (id = auth.uid())
  with check (id = auth.uid());

create policy "Users can insert their own profile"
  on public.profiles for insert
  with check (id = auth.uid());

create policy "Only super admins can delete profiles"
  on public.profiles for delete
  using (false);

-- ============================================================
-- SHOPS
-- ============================================================

create policy "Members can view their shops"
  on public.shops for select
  using (public.is_shop_member(id));

create policy "Owner can update their shop"
  on public.shops for update
  using (owner_id = auth.uid())
  with check (owner_id = auth.uid());

create policy "Owner can delete their shop"
  on public.shops for delete
  using (owner_id = auth.uid());

create policy "Authenticated users can create shops"
  on public.shops for insert
  with check (auth.role() = 'authenticated');

-- ============================================================
-- SHOP MEMBERS
-- ============================================================

create policy "Members can view shop_members of their shops"
  on public.shop_members for select
  using (public.is_shop_member(shop_id));

create policy "Owner can manage shop_members"
  on public.shop_members for insert
  with check (public.has_role(shop_id, 'owner'));

create policy "Owner can update shop_members"
  on public.shop_members for update
  using (public.has_role(shop_id, 'owner'))
  with check (public.has_role(shop_id, 'owner'));

create policy "Owner can delete shop_members"
  on public.shop_members for delete
  using (public.has_role(shop_id, 'owner'));

-- Allow onboard_new_user RPC to insert (security definer handles this)

-- ============================================================
-- CUSTOMERS
-- ============================================================

create policy "Members can view customers in their shop"
  on public.customers for select
  using (public.is_shop_member(shop_id));

create policy "Members can create customers in their shop"
  on public.customers for insert
  with check (public.is_shop_member(shop_id));

create policy "Members can update customers in their shop"
  on public.customers for update
  using (public.is_shop_member(shop_id))
  with check (public.is_shop_member(shop_id));

create policy "Owner and manager can delete customers"
  on public.customers for delete
  using (public.has_role(shop_id, 'owner') or public.has_role(shop_id, 'manager'));

-- ============================================================
-- PRODUCTS
-- ============================================================

create policy "Members can view products in their shop"
  on public.products for select
  using (public.is_shop_member(shop_id));

create policy "Members can create products in their shop"
  on public.products for insert
  with check (public.is_shop_member(shop_id));

create policy "Members can update products in their shop"
  on public.products for update
  using (public.is_shop_member(shop_id))
  with check (public.is_shop_member(shop_id));

create policy "Owner and manager can delete products"
  on public.products for delete
  using (public.has_role(shop_id, 'owner') or public.has_role(shop_id, 'manager'));

-- ============================================================
-- BILLS
-- ============================================================

create policy "Members can view bills in their shop"
  on public.bills for select
  using (public.is_shop_member(shop_id));

create policy "Members can create bills in their shop"
  on public.bills for insert
  with check (public.is_shop_member(shop_id));

create policy "Draft bills can be updated by members"
  on public.bills for update
  using (public.is_shop_member(shop_id) and status = 'draft')
  with check (public.is_shop_member(shop_id));

create policy "Only owner and manager can delete bills"
  on public.bills for delete
  using (public.has_role(shop_id, 'owner') or public.has_role(shop_id, 'manager'));

-- ============================================================
-- BILL ITEMS
-- ============================================================

create policy "Members can view bill_items in their shop"
  on public.bill_items for select
  using (public.is_shop_member(shop_id));

create policy "Members can create bill_items in their shop"
  on public.bill_items for insert
  with check (public.is_shop_member(shop_id));

create policy "Members can update bill_items in their shop"
  on public.bill_items for update
  using (public.is_shop_member(shop_id))
  with check (public.is_shop_member(shop_id));

create policy "Owner and manager can delete bill_items"
  on public.bill_items for delete
  using (public.has_role(shop_id, 'owner') or public.has_role(shop_id, 'manager'));

-- ============================================================
-- INK DOCUMENTS
-- ============================================================

create policy "Members can view ink_documents in their shop"
  on public.ink_documents for select
  using (public.is_shop_member(shop_id));

create policy "Members can create ink_documents in their shop"
  on public.ink_documents for insert
  with check (public.is_shop_member(shop_id));

create policy "Members can update ink_documents in their shop"
  on public.ink_documents for update
  using (public.is_shop_member(shop_id))
  with check (public.is_shop_member(shop_id));

create policy "Owner and manager can delete ink_documents"
  on public.ink_documents for delete
  using (public.has_role(shop_id, 'owner') or public.has_role(shop_id, 'manager'));

-- ============================================================
-- AUDIT LOGS
-- ============================================================

create policy "Members can view audit_logs in their shop"
  on public.audit_logs for select
  using (public.is_shop_member(shop_id));

create policy "Authenticated users can create audit_logs"
  on public.audit_logs for insert
  with check (auth.role() = 'authenticated');

create policy "Audit logs cannot be updated"
  on public.audit_logs for update
  using (false);

create policy "Audit logs cannot be deleted"
  on public.audit_logs for delete
  using (false);
