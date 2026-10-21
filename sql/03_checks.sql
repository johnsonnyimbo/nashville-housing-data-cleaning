-- =====================================================================
-- 03_checks.sql  |  Validate the cleaned table
-- Prerequisite: run 01_schema_and_load.sql and 02_cleaning.sql first.
--     psql -d nashville -f sql/03_checks.sql
--
-- Every row should show passed = true. The expected row count (56,373)
-- applies to the dataset in this repository.
-- =====================================================================

select 'row count is 56,373 (56,477 raw - 104 duplicates)' as check_name,
       count(*) = 56373 as passed,
       count(*)::text   as actual
from nashville_housing

union all
select 'unique_id is unique',
       count(*) = count(distinct unique_id),
       count(*) - count(distinct unique_id) || ' repeated ids'
from nashville_housing

union all
select 'no duplicate sales left (parcel, address, price, date, legal reference)',
       count(*) = 0,
       count(*)::text || ' duplicate groups'
from (
    select 1
    from nashville_housing
    group by parcel_id, property_address, sale_price, sale_date, legal_reference
    having count(*) > 1
) d

union all
select 'no missing property addresses',
       count(*) = 0,
       count(*)::text || ' missing'
from nashville_housing
where property_address is null

union all
select 'sold_as_vacant contains only Yes / No',
       count(*) = 0,
       count(*)::text || ' other values'
from nashville_housing
where sold_as_vacant not in ('Yes', 'No') or sold_as_vacant is null

union all
select 'no CONDO or VACANT RES LAND labels left in land_use',
       count(*) = 0,
       count(*)::text || ' left'
from nashville_housing
where land_use in ('CONDO', 'VACANT RES LAND')

union all
select 'sale_date is a date between 2013 and 2019',
       min(sale_date) >= date '2013-01-01' and max(sale_date) <= date '2019-12-31',
       min(sale_date)::text || ' to ' || max(sale_date)::text
from nashville_housing

union all
select 'every sale has a price greater than zero',
       count(*) = 0,
       count(*)::text || ' missing or zero'
from nashville_housing
where sale_price is null or sale_price <= 0

union all
select 'owner state is TN whenever an owner address exists',
       count(*) = 0,
       count(*)::text || ' other'
from nashville_housing
where owner_split_state is not null and owner_split_state <> 'TN';
