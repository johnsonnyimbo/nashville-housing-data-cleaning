-- =====================================================================
-- 02_cleaning.sql  |  Cleaning the Nashville housing data in SQL
-- Prerequisite: run sql/01_schema_and_load.sql first (it resets the table).
--     psql -d nashville -v ON_ERROR_STOP=1 -f sql/02_cleaning.sql
--
-- Steps
--   1. Standardize the date and price formats
--   2. Populate missing property addresses
--   3. Standardize the "sold as vacant" field (Y/N -> Yes/No)
--   4. Standardize land use categories
--   5. Remove duplicate rows
--   6. Split the owner address into street, city and state
-- =====================================================================

-- Look at the data before changing anything
select *
from nashville_housing
limit 20;


-- ---------------------------------------------------------------------
-- 1. Standardize date and price formats
-- ---------------------------------------------------------------------
-- sale_date was loaded as text ('April 9, 2013'). Casting text to date
-- inside an UPDATE would leave the column as text, so change the column type.
alter table nashville_housing
    alter column sale_date type date
    using to_date(sale_date, 'FMMonth FMDD, YYYY');

-- sale_price was loaded as text; 12 rows look like '$120,000 ' or '120,000'.
-- Strip everything except digits and the decimal point, then store as numeric.
alter table nashville_housing
    alter column sale_price type numeric(12,2)
    using nullif(regexp_replace(sale_price, '[^0-9.]', '', 'g'), '')::numeric;


-- ---------------------------------------------------------------------
-- 2. Populate missing property addresses
-- ---------------------------------------------------------------------
-- The same parcel_id always refers to the same property, so a missing
-- address can be copied from another sale of the same parcel.

-- Preview: rows with a missing address and the address available for them
select a.unique_id,
       a.parcel_id,
       a.property_address as missing_address,
       b.property_address as address_from_other_sale
from nashville_housing a
join nashville_housing b
  on a.parcel_id = b.parcel_id
 and a.unique_id <> b.unique_id
where a.property_address is null
  and b.property_address is not null;

update nashville_housing a
set property_address = b.property_address
from nashville_housing b
where a.parcel_id = b.parcel_id
  and a.unique_id <> b.unique_id
  and a.property_address is null
  and b.property_address is not null;

-- Rows still missing an address (no other sale of that parcel exists)
select count(*) as addresses_still_missing
from nashville_housing
where property_address is null;


-- ---------------------------------------------------------------------
-- 3. Standardize sold_as_vacant (Y / N -> Yes / No)
-- ---------------------------------------------------------------------
select sold_as_vacant, count(*)
from nashville_housing
group by sold_as_vacant
order by 2 desc;

update nashville_housing
set sold_as_vacant = case
        when sold_as_vacant = 'Y' then 'Yes'
        when sold_as_vacant = 'N' then 'No'
        else sold_as_vacant
    end
where sold_as_vacant in ('Y', 'N');


-- ---------------------------------------------------------------------
-- 4. Standardize land use categories
-- ---------------------------------------------------------------------
select land_use, count(*)
from nashville_housing
group by land_use
order by 2 desc;

update nashville_housing
set land_use = case
        when land_use = 'VACANT RES LAND' then 'VACANT RESIDENTIAL LAND'
        when land_use = 'CONDO'           then 'RESIDENTIAL CONDO'
        else land_use
    end
where land_use in ('VACANT RES LAND', 'CONDO');


-- ---------------------------------------------------------------------
-- 5. Remove duplicates
-- ---------------------------------------------------------------------
-- Rows that share parcel, address, price, date and legal reference are the
-- same sale recorded more than once; keep the row with the lowest unique_id.

-- Preview: the rows that will be deleted
select *
from nashville_housing
where unique_id not in (
    select min(unique_id)
    from nashville_housing
    group by parcel_id,
             property_address,
             sale_price,
             sale_date,
             legal_reference
);

delete from nashville_housing
where unique_id not in (
    select min(unique_id)
    from nashville_housing
    group by parcel_id,
             property_address,
             sale_price,
             sale_date,
             legal_reference
);


-- ---------------------------------------------------------------------
-- 6. Split owner_address into street, city and state
-- ---------------------------------------------------------------------
-- Add the new columns
alter table nashville_housing
    add column if not exists owner_split_address varchar(255),
    add column if not exists owner_split_city    varchar(255),
    add column if not exists owner_split_state   varchar(50);

-- Fill them from owner_address ("street, city, state")
update nashville_housing
set owner_split_address = trim(split_part(owner_address, ',', 1)),
    owner_split_city    = trim(split_part(owner_address, ',', 2)),
    owner_split_state   = trim(split_part(owner_address, ',', 3))
where owner_address is not null;

-- The original combined column is no longer needed
alter table nashville_housing
    drop column if exists owner_address;
