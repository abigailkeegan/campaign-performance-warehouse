-- Builds the campaign dimension, the date-to-campaign bridge, and the
-- sales-with-campaign view.

USE DATABASE MARKETING_WAREHOUSE;
USE SCHEMA ANALYTICS;

-- Campaign dimension: twelve campaigns plus a -1 Unknown member.
CREATE OR REPLACE TABLE MARKETING_WAREHOUSE.ANALYTICS.DIM_CAMPAIGN (
    campaign_key   INTEGER,
    campaign_name  VARCHAR,
    channel        VARCHAR,
    start_date     DATE,
    end_date       DATE,
    spend_usd      FLOAT
);

INSERT INTO MARKETING_WAREHOUSE.ANALYTICS.DIM_CAMPAIGN VALUES
    (-1, 'Unknown / No Campaign', 'None',        NULL,         NULL,         0),
    (1,  'Winter Gift Guide 2010', 'Email',      '2010-11-15', '2010-12-24', 8500),
    (2,  'Spring Refresh 2010',    'Paid Search', '2010-03-01', '2010-04-15', 12000),
    (3,  'Mother''s Day Promo 2010', 'Social',    '2010-04-20', '2010-05-09', 6500),
    (4,  'Summer Decor 2010',      'Display',     '2010-06-01', '2010-07-31', 9800),
    (5,  'Back to School 2010',    'Paid Search', '2010-08-15', '2010-09-15', 7200),
    (6,  'Halloween Push 2010',    'Social',      '2010-10-01', '2010-10-31', 5400),
    (7,  'New Year Sale 2011',     'Email',       '2011-01-01', '2011-01-15', 4800),
    (8,  'Valentine''s 2011',      'Display',     '2011-01-25', '2011-02-14', 6000),
    (9,  'Easter Campaign 2011',   'Email',       '2011-04-01', '2011-04-24', 5200),
    (10, 'Summer Sale 2011',       'Paid Search', '2011-06-15', '2011-07-31', 14500),
    (11, 'Back to School 2011',    'Display',     '2011-08-15', '2011-09-15', 8000),
    (12, 'Holiday Kickoff 2011',   'Social',      '2011-11-01', '2011-12-09', 11000);

-- Bridge: maps each date to its campaign. Where windows overlap, the
-- highest-spend campaign wins, so each date maps to one campaign.
CREATE OR REPLACE TABLE MARKETING_WAREHOUSE.ANALYTICS.BRIDGE_DATE_TO_CAMPAIGN AS
WITH date_campaign_matches AS (
    SELECT
        d.date_key,
        d.date_day,
        c.campaign_key,
        c.spend_usd,
        ROW_NUMBER() OVER (
            PARTITION BY d.date_day
            ORDER BY c.spend_usd DESC, c.campaign_key
        ) AS priority_rank
    FROM MARKETING_WAREHOUSE.ANALYTICS.DIM_DATE d
    JOIN MARKETING_WAREHOUSE.ANALYTICS.DIM_CAMPAIGN c
        ON d.date_day BETWEEN c.start_date AND c.end_date
    WHERE c.campaign_key != -1
)
SELECT
    date_key,
    date_day,
    campaign_key
FROM date_campaign_matches
WHERE priority_rank = 1;

-- View: sales flattened with campaign attribution (-1 if no campaign).
CREATE OR REPLACE VIEW MARKETING_WAREHOUSE.ANALYTICS.VW_SALES_WITH_CAMPAIGN AS
SELECT
    f.date_key,
    f.customer_key,
    f.product_key,
    COALESCE(b.campaign_key, -1) AS campaign_key,
    f.invoice_no,
    f.quantity,
    f.unit_price,
    f.line_revenue
FROM MARKETING_WAREHOUSE.ANALYTICS.FACT_SALES f
LEFT JOIN MARKETING_WAREHOUSE.ANALYTICS.BRIDGE_DATE_TO_CAMPAIGN b
    ON f.date_key = b.date_key;
