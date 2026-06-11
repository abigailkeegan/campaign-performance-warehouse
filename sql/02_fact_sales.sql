-- Builds the sales fact table from raw transactions, resolving each row
-- to its date, customer, and product keys.

USE DATABASE MARKETING_WAREHOUSE;
USE SCHEMA ANALYTICS;

CREATE OR REPLACE TABLE MARKETING_WAREHOUSE.ANALYTICS.FACT_SALES AS
WITH transactions AS (
    SELECT
        INVOICE              AS invoice_no,
        STOCKCODE            AS stock_code,
        CUSTOMER_ID          AS customer_id,
        DATE(INVOICEDATE)    AS transaction_date,
        QUANTITY             AS quantity,
        PRICE                AS unit_price,
        QUANTITY * PRICE     AS line_revenue
    FROM MARKETING_WAREHOUSE.RAW.RAW_TRANSACTIONS
)
SELECT
    COALESCE(d.date_key, -1)     AS date_key,
    COALESCE(c.customer_key, -1) AS customer_key,
    COALESCE(p.product_key, -1)  AS product_key,
    t.invoice_no,
    t.quantity,
    t.unit_price,
    t.line_revenue
FROM transactions t
LEFT JOIN MARKETING_WAREHOUSE.ANALYTICS.DIM_DATE d
    ON t.transaction_date = d.date_day
LEFT JOIN MARKETING_WAREHOUSE.ANALYTICS.DIM_CUSTOMER c
    ON t.customer_id = c.customer_id
LEFT JOIN MARKETING_WAREHOUSE.ANALYTICS.DIM_PRODUCT p
    ON t.stock_code = p.stock_code;
