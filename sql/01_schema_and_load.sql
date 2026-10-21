-- =====================================================================
-- 01_schema_and_load.sql  |  Create the table and load the raw CSV
-- Target: PostgreSQL 13+   |  Run from the repository root:
--     psql -d nashville -f sql/01_schema_and_load.sql
--
-- Re-running this file resets the table to the raw, uncleaned state.
-- =====================================================================

drop table if exists nashville_housing;

create table nashville_housing (
    unique_id         integer primary key,
    parcel_id         text,
    land_use          text,
    property_address  text,
    sale_date         text,      -- raw text such as 'April 9, 2013'; converted to DATE in 02_cleaning.sql
    sale_price        text,      -- raw text; a few rows contain '$' and ',' (e.g. '$120,000 ')
    legal_reference   text,
    sold_as_vacant    text,      -- contains Yes / No / Y / N
    owner_name        text,
    owner_address     text,
    acreage           numeric,
    tax_district      text,
    land_value        numeric,
    building_value    numeric,
    total_value       numeric,
    year_built        integer,
    bedrooms          integer,
    full_bath         integer,
    half_bath         integer
);

-- Column order matches the CSV; the CSV header row (UniqueID, ParcelID, ...)
-- is skipped, so the snake_case names above are the ones used from here on.
\copy nashville_housing from 'data/raw/NashvilleHousingData.csv' with (format csv, header true, null '')

-- Sanity check: expect 56,477 rows
select count(*) as raw_row_count from nashville_housing;
