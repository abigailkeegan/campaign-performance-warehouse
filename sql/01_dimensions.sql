-- Builds the date, customer, and product dimensions.

USE DATABASE MARKETING_WAREHOUSE;
USE SCHEMA ANALYTICS;

-- Date dimension: a generated calendar from 2009-01-01 with attributes.
CREATE OR REPLACE TABLE MARKETING_WAREHOUSE.ANALYTICS.DIM_DATE AS
SELECT
    ROW_NUMBER() OVER (ORDER BY date_day)                          AS date_key,
    date_day,
    YEAR(date_day)                                                AS year,
    QUARTER(date_day)                                             AS quarter,
    MONTH(date_day)                                               AS month,
    MONTHNAME(date_day)                                           AS month_name,
    DAY(date_day)                                                 AS day,
    DAYOFWEEK(date_day)                                           AS day_of_week_num,
    DAYNAME(date_day)                                             AS day_of_week_name,
    CASE WHEN DAYOFWEEK(date_day) IN (0, 6) THEN TRUE ELSE FALSE END AS is_weekend
FROM (
    SELECT DATEADD(day, SEQ4(), '2009-01-01'::DATE) AS date_day
    FROM TABLE(GENERATOR(ROWCOUNT => 1500))
);

-- Customer dimension: one row per customer, with a region rollup.
CREATE OR REPLACE TABLE MARKETING_WAREHOUSE.ANALYTICS.DIM_CUSTOMER AS
SELECT
    ROW_NUMBER() OVER (ORDER BY CUSTOMER_ID) AS customer_key,
    CUSTOMER_ID                              AS customer_id,
    COUNTRY                                  AS customer_country,
    CASE
        WHEN COUNTRY = 'United Kingdom' THEN 'UK'
        WHEN COUNTRY IN (
            'France', 'Germany', 'Spain', 'Italy', 'Netherlands', 'Belgium',
            'Portugal', 'Austria', 'Switzerland', 'Sweden', 'Norway',
            'Finland', 'Denmark', 'Greece', 'Ireland', 'Poland', 'Czech Republic'
        ) THEN 'Europe (non-UK)'
        WHEN COUNTRY IN ('USA', 'Canada') THEN 'North America'
        ELSE 'Other'
    END AS region
FROM (
    SELECT DISTINCT CUSTOMER_ID, COUNTRY
    FROM MARKETING_WAREHOUSE.RAW.RAW_TRANSACTIONS
    WHERE CUSTOMER_ID IS NOT NULL
);

INSERT INTO MARKETING_WAREHOUSE.ANALYTICS.DIM_CUSTOMER
VALUES (-1, NULL, 'Unknown', 'Unknown');

-- Product dimension: one row per stock code.
CREATE OR REPLACE TABLE MARKETING_WAREHOUSE.ANALYTICS.DIM_PRODUCT AS
SELECT
    ROW_NUMBER() OVER (ORDER BY stock_code) AS product_key,
    stock_code,
    description
FROM (
    SELECT
        STOCKCODE          AS stock_code,
        MAX(DESCRIPTION)   AS description
    FROM MARKETING_WAREHOUSE.RAW.RAW_TRANSACTIONS
    WHERE STOCKCODE IS NOT NULL
    GROUP BY STOCKCODE
);

INSERT INTO MARKETING_WAREHOUSE.ANALYTICS.DIM_PRODUCT
VALUES (-1, NULL, 'Unknown Product');
