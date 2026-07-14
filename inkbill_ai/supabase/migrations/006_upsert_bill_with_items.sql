-- Atomic bill + bill_items upsert
-- Ensures bill and its items are always inserted/updated together

create or replace function public.upsert_bill_with_items(
  p_bill   jsonb,
  p_items  jsonb
)
returns jsonb
language plpgsql
security definer
as $$
declare
  v_bill_id   uuid;
  v_shop_id   uuid;
  v_result    jsonb;
begin
  -- Verify caller is a member of the target shop
  v_shop_id := (p_bill ->> 'shop_id')::uuid;
  if not public.is_shop_member(v_shop_id) then
    raise exception 'Not a member of this shop';
  end if;

  -- Upsert bill
  insert into public.bills (
    id, shop_id, bill_number, customer_id, customer_name_snapshot,
    subtotal, discount, tax_rate, tax_amount, grand_total,
    status, notes, created_by, created_at, updated_at
  )
  select
    (p_bill ->> 'id')::uuid,
    v_shop_id,
    p_bill ->> 'bill_number',
    (p_bill ->> 'customer_id')::uuid,
    p_bill ->> 'customer_name_snapshot',
    (p_bill ->> 'subtotal')::numeric,
    (p_bill ->> 'discount')::numeric,
    (p_bill ->> 'tax_rate')::numeric,
    (p_bill ->> 'tax_amount')::numeric,
    (p_bill ->> 'grand_total')::numeric,
    p_bill ->> 'status',
    p_bill ->> 'notes',
    (p_bill ->> 'created_by')::uuid,
    now(),
    now()
  on conflict (id) do update set
    customer_name_snapshot = excluded.customer_name_snapshot,
    subtotal = excluded.subtotal,
    discount = excluded.discount,
    tax_rate = excluded.tax_rate,
    tax_amount = excluded.tax_amount,
    grand_total = excluded.grand_total,
    status = excluded.status,
    notes = excluded.notes,
    updated_at = now()
  returning row_to_json(bills) into v_result;

  v_bill_id := (p_bill ->> 'id')::uuid;

  -- Delete existing items for this bill, then re-insert
  delete from public.bill_items where bill_id = v_bill_id;

  insert into public.bill_items (id, bill_id, shop_id, item_name, quantity, rate, amount, gst_rate, hsn_code)
  select
    (item ->> 'id')::uuid,
    v_bill_id,
    v_shop_id,
    item ->> 'item_name',
    (item ->> 'quantity')::numeric,
    (item ->> 'rate')::numeric,
    (item ->> 'amount')::numeric,
    (item ->> 'gst_rate')::numeric,
    item ->> 'hsn_code'
  from jsonb_array_elements(p_items) as item;

  return v_result;
end;
$$;
