# Nashville Housing Data Cleaning in SQL

A data-cleaning project in **PostgreSQL**. It takes a raw export of Nashville, Tennessee property sales and turns it into an analysis-ready table: consistent dates and prices, filled-in addresses, standardized categories, no duplicate sales and a split owner address. Every step is a runnable SQL script, followed by a validation script that checks the result.

## The data

`data/raw/NashvilleHousingData.csv` holds **56,477 property sales** (19 columns) from **2 January 2013 to 13 December 2019**: parcel ID, land use, property and owner address, sale date and price, legal reference, whether the property was sold as vacant, and, where available, acreage, tax district, land, building and total value, year built, bedrooms and bathrooms.

## Problems found and how they were fixed

| # | Problem in the raw data | Fix | Rows affected |
|---|---|---|---|
| 1 | Dates stored as text (`April 9, 2013`) | Converted the column to `DATE` with `ALTER COLUMN ... USING to_date()` | all rows |
| 1 | Sale prices stored as text, some as `$120,000 ` or `120,000` | Stripped `$`, commas and spaces, converted to `NUMERIC(12,2)` | 12 prices |
| 2 | Missing property addresses | Copied from another sale of the same `parcel_id` (self-join `UPDATE`) | 29 (all recovered) |
| 3 | `Y` / `N` mixed with `Yes` / `No` in `sold_as_vacant` | `CASE` expression | 451 |
| 4 | Inconsistent land-use labels | `VACANT RES LAND` → `VACANT RESIDENTIAL LAND`, `CONDO` → `RESIDENTIAL CONDO` | 1,549 + 247 |
| 5 | Duplicate sales (same parcel, address, price, date and legal reference) | Kept the lowest `unique_id` of each group and deleted the rest | 104 |
| 6 | Owner address held in one column | Split into `owner_split_address`, `owner_split_city`, `owner_split_state` with `SPLIT_PART` and `TRIM`; dropped the combined column | 25,969 owner addresses |

**Result:** 56,373 rows and 21 columns, with no missing property addresses and no duplicate sales left.

## Repository structure

```
.
├── README.md
├── data/
│   ├── raw/NashvilleHousingData.csv              # original data
│   └── cleaned/NashvilleHousingData_cleaned.csv  # output of the pipeline
└── sql/
    ├── 01_schema_and_load.sql   # create the table and load the raw CSV
    ├── 02_cleaning.sql          # the six cleaning steps, with a preview before each change
    ├── 03_checks.sql            # nine validation checks (all should pass)
    └── 04_export_cleaned.sql    # write the cleaned table back to CSV
```

## How to run

Requires PostgreSQL 13 or later. Run every command from the repository root, because `\copy` uses paths relative to it.

```bash
createdb nashville
psql -d nashville -f sql/01_schema_and_load.sql
psql -d nashville -v ON_ERROR_STOP=1 -f sql/02_cleaning.sql
psql -d nashville -f sql/03_checks.sql          # every row should show passed = t
psql -d nashville -f sql/04_export_cleaned.sql  # optional: regenerate the cleaned CSV
```

To start over, run `01_schema_and_load.sql` again; it drops and recreates the table from the raw CSV.

## SQL techniques used

- `ALTER TABLE ... ALTER COLUMN ... TYPE ... USING` for safe type conversion
- Self-join `UPDATE ... FROM` to fill missing values from related rows
- `CASE` expressions for standardizing categories
- Subquery with `GROUP BY` / `MIN()` to remove duplicates
- String functions: `SPLIT_PART`, `TRIM`, `regexp_replace`
- Validation queries combined with `UNION ALL`

## Notes and limitations

- About half of the sales (30,404 rows) have no owner address, and the acreage, tax district and valuation columns are blank for about the same share of rows in the source data.
- Sale prices were not filtered for outliers; they range from $50 to $54,278,060.
- A few land-use labels still contain spelling variants that were not standardized: `VACANT RESIENTIAL LAND`, `RESTURANT/CAFETERIA` and `GREENBELT/RES` followed by a line break and `GRRENBELT/RES` (3, 2 and 3 rows in the raw data).

## Possible next steps

- Split `property_address` into street and city, as was done for the owner address.
- Collapse repeated spaces in addresses (for example `1808  FOX CHASE DR`).
- Fix the remaining land-use spelling variants.
- Analyse the cleaned data: median sale price by year and city, vacant versus occupied sales, price per acre.
