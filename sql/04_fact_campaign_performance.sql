-- Builds the campaign performance fact at the campaign-by-date grain.
-- Spend is the real budget split evenly across active days. Revenue and
-- conversions are real, attributed at 3% of window sales. Clicks and
-- impressions are synthetic, derived from spend at a believable CPC and CTR.

USE DATABASE MARKETING_WAREHOUSE;
USE SCHEMA ANALYTICS;

CREATE OR REPLACE TABLE MARKETING_WAREHOUSE.ANALYTICS.FACT_CAMPAIGN_PERFORMANCE AS
WITH active_days AS (
    -- Active dates per campaign, used to split the budget.
    SELECT
        CAMPAIGN_KEY,
        COUNT(DISTINCT DATE_KEY) AS n_days
    FROM MARKETING_WAREHOUSE.ANALYTICS.BRIDGE_DATE_TO_CAMPAIGN
    WHERE CAMPAIGN_KEY <> -1
    GROUP BY CAMPAIGN_KEY
),
daily AS (
    -- Roll sales up to campaign-by-date. LEFT JOIN keeps days with no sales.
    SELECT
        b.CAMPAIGN_KEY,
        b.DATE_KEY,
        b.DATE_DAY,
        c.SPEND_USD / ad.n_days       AS daily_spend,
        SUM(f.LINE_REVENUE)           AS gross_revenue,
        COUNT(DISTINCT f.INVOICE_NO)  AS gross_orders
    FROM MARKETING_WAREHOUSE.ANALYTICS.BRIDGE_DATE_TO_CAMPAIGN b
    JOIN MARKETING_WAREHOUSE.ANALYTICS.DIM_CAMPAIGN c
        ON b.CAMPAIGN_KEY = c.CAMPAIGN_KEY
    JOIN active_days ad
        ON b.CAMPAIGN_KEY = ad.CAMPAIGN_KEY
    LEFT JOIN MARKETING_WAREHOUSE.ANALYTICS.FACT_SALES f
        ON b.DATE_KEY = f.DATE_KEY
    WHERE b.CAMPAIGN_KEY <> -1
    GROUP BY b.CAMPAIGN_KEY, b.DATE_KEY, b.DATE_DAY, c.SPEND_USD, ad.n_days
),
params AS (
    SELECT
        CAMPAIGN_KEY,
        DATE_KEY,
        DATE_DAY,
        daily_spend,
        COALESCE(gross_revenue, 0) * 0.03 AS revenue,        -- 3% attribution
        COALESCE(gross_orders, 0)  * 0.03 AS conversions_raw,
        0.50 + UNIFORM(0, 200, RANDOM()) / 100.0    AS cpc,   -- $0.50 to $2.50
        0.01 + UNIFORM(0, 300, RANDOM()) / 10000.0  AS ctr    -- 1% to 4%
    FROM daily
)
SELECT
    CAMPAIGN_KEY,
    DATE_KEY,
    DATE_DAY,
    ROUND(daily_spend, 2)             AS SPEND,
    ROUND(revenue, 2)                 AS REVENUE,
    ROUND(conversions_raw)            AS CONVERSIONS,
    ROUND(daily_spend / cpc)          AS CLICKS,
    ROUND((daily_spend / cpc) / ctr)  AS IMPRESSIONS
FROM params;
