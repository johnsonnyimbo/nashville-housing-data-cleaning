-- =====================================================================
-- 04_export_cleaned.sql  |  Export the cleaned table to CSV
-- Prerequisite: run 01_schema_and_load.sql and 02_cleaning.sql first.
--     psql -d nashville -f sql/04_export_cleaned.sql
-- Run from the repository root so the relative path below works.
-- =====================================================================

\copy (select * from nashville_housing order by unique_id) to 'data/cleaned/NashvilleHousingData_cleaned.csv' with (format csv, header true)
