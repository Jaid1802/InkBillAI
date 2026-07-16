-- Validate bill amounts before insert or update
-- Prevents client-side tampering of financial totals

create or replace function validate_bill_amounts()
returns trigger
language plpgsql
as $$
begin
  if new.subtotal is null or new.subtotal < 0 then
    raise exception 'subtotal must be non-negative';
  end if;

  if new.grand_total is null or new.grand_total < 0 then
    raise exception 'grand_total must be non-negative';
  end if;

  if new.tax_rate is not null and (new.tax_rate < 0 or new.tax_rate > 100) then
    raise exception 'tax_rate must be between 0 and 100';
  end if;

  if new.discount is not null and new.discount < 0 then
    raise exception 'discount must be non-negative';
  end if;

  if new.grand_total > new.subtotal + coalesce(new.tax_amount, 0) then
    raise exception 'grand_total cannot exceed subtotal + tax without discount';
  end if;

  return new;
end;
$$;

create or replace trigger validate_bill_amounts_trigger
  before insert or update on bills
  for each row
  execute function validate_bill_amounts();

-- Validate bill_item amounts
create or replace function validate_bill_item_amount()
returns trigger
language plpgsql
as $$
begin
  if new.quantity is not null and new.quantity <= 0 then
    raise exception 'quantity must be positive';
  end if;

  if new.rate is not null and new.rate < 0 then
    raise exception 'rate must be non-negative';
  end if;

  if new.amount is not null and new.amount < 0 then
    raise exception 'amount must be non-negative';
  end if;

  return new;
end;
$$;

create or replace trigger validate_bill_item_amount_trigger
  before insert or update on bill_items
  for each row
  execute function validate_bill_item_amount();
