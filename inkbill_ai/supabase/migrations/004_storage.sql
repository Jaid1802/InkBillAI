-- Supabase Storage buckets and policies for InkBill AI

-- Create private storage buckets
insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values
  ('ink-documents', 'ink-documents', false, 52428800, null),
  ('receipts', 'receipts', false, 10485760, null),
  ('shop-assets', 'shop-assets', false, 5242880, null)
on conflict (id) do nothing;

-- ============================================================
-- INK DOCUMENTS STORAGE POLICIES
-- ============================================================

create policy "Members can view ink documents in their shop"
  on storage.objects for select
  using (
    bucket_id = 'ink-documents'
    and exists (
      select 1 from public.shop_members sm
      where sm.user_id = auth.uid()
        and sm.is_active = true
        and storage.foldername(name)[1] = sm.shop_id::text
    )
  );

create policy "Members can upload ink documents to their shop"
  on storage.objects for insert
  with check (
    bucket_id = 'ink-documents'
    and exists (
      select 1 from public.shop_members sm
      where sm.user_id = auth.uid()
        and sm.is_active = true
        and storage.foldername(name)[1] = sm.shop_id::text
    )
  );

create policy "Members can update ink documents in their shop"
  on storage.objects for update
  using (
    bucket_id = 'ink-documents'
    and exists (
      select 1 from public.shop_members sm
      where sm.user_id = auth.uid()
        and sm.is_active = true
        and storage.foldername(name)[1] = sm.shop_id::text
    )
  );

create policy "Owner and manager can delete ink documents"
  on storage.objects for delete
  using (
    bucket_id = 'ink-documents'
    and exists (
      select 1 from public.shop_members sm
      where sm.user_id = auth.uid()
        and sm.is_active = true
        and sm.role in ('owner', 'manager')
        and storage.foldername(name)[1] = sm.shop_id::text
    )
  );

-- ============================================================
-- RECEIPTS STORAGE POLICIES
-- ============================================================

create policy "Members can view receipts in their shop"
  on storage.objects for select
  using (
    bucket_id = 'receipts'
    and exists (
      select 1 from public.shop_members sm
      where sm.user_id = auth.uid()
        and sm.is_active = true
        and storage.foldername(name)[1] = sm.shop_id::text
    )
  );

create policy "Members can upload receipts to their shop"
  on storage.objects for insert
  with check (
    bucket_id = 'receipts'
    and exists (
      select 1 from public.shop_members sm
      where sm.user_id = auth.uid()
        and sm.is_active = true
        and storage.foldername(name)[1] = sm.shop_id::text
    )
  );

create policy "Owner and manager can delete receipts"
  on storage.objects for delete
  using (
    bucket_id = 'receipts'
    and exists (
      select 1 from public.shop_members sm
      where sm.user_id = auth.uid()
        and sm.is_active = true
        and sm.role in ('owner', 'manager')
        and storage.foldername(name)[1] = sm.shop_id::text
    )
  );

-- ============================================================
-- SHOP ASSETS STORAGE POLICIES
-- ============================================================

create policy "Members can view shop assets"
  on storage.objects for select
  using (
    bucket_id = 'shop-assets'
    and exists (
      select 1 from public.shop_members sm
      where sm.user_id = auth.uid()
        and sm.is_active = true
        and storage.foldername(name)[1] = sm.shop_id::text
    )
  );

create policy "Owner can manage shop assets"
  on storage.objects for insert
  with check (
    bucket_id = 'shop-assets'
    and exists (
      select 1 from public.shop_members sm
      where sm.user_id = auth.uid()
        and sm.is_active = true
        and sm.role = 'owner'
        and storage.foldername(name)[1] = sm.shop_id::text
    )
  );

create policy "Owner can update and delete shop assets"
  on storage.objects for update
  using (
    bucket_id = 'shop-assets'
    and exists (
      select 1 from public.shop_members sm
      where sm.user_id = auth.uid()
        and sm.is_active = true
        and sm.role = 'owner'
        and storage.foldername(name)[1] = sm.shop_id::text
    )
  );

create policy "Owner can delete shop assets"
  on storage.objects for delete
  using (
    bucket_id = 'shop-assets'
    and exists (
      select 1 from public.shop_members sm
      where sm.user_id = auth.uid()
        and sm.is_active = true
        and sm.role = 'owner'
        and storage.foldername(name)[1] = sm.shop_id::text
    )
  );
