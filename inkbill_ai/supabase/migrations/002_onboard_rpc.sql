-- Secure onboarding transaction
-- Called by the Flutter app after successful Supabase Auth signup.
-- Creates profile, shop, and shop_membership in a single transaction.

create or replace function public.onboard_new_user(
  p_user_id    uuid,
  p_full_name  text,
  p_shop_name  text,
  p_phone      text default '',
  p_email      text default ''
)
returns void
language plpgsql
security definer
as $$
declare
  v_shop_id uuid;
begin
  -- 1. Create profile
  insert into public.profiles (id, full_name, phone)
  values (p_user_id, p_full_name, nullif(p_phone, ''));

  -- 2. Create shop
  insert into public.shops (name, owner_id)
  values (p_shop_name, p_user_id)
  returning id into v_shop_id;

  -- 3. Create owner membership
  insert into public.shop_members (shop_id, user_id, role)
  values (v_shop_id, p_user_id, 'owner');

exception
  when unique_violation then
    raise exception 'User or shop already exists';
  when others then
    raise exception 'Failed to complete account setup: %', sqlerrm;
end;
$$;
