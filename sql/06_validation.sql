-- Validation checks. Run each block and compare against the notes.

USE DATABASE MARKETING_WAREHOUSE;
USE SCHEMA ANALYTICS;

-- Row counts. None should be zero; DIM_CAMPAIGN should be 13.
SELECT 'FACT_SALES'                AS table_name, COUNT(*) AS row_count FROM FACT_SALES
UNION ALL SELECT 'DIM_DATE',                       COUNT(*) FROM DIM_DATE
UNION ALL SELECT 'DIM_CUSTOMER',                   COUNT(*) FROM DIM_CUSTOMER
UNION ALL SELECT 'DIM_PRODUCT',                    COUNT(*) FROM DIM_PRODUCT
UNION ALL SELECT 'DIM_CAMPAIGN',                   COUNT(*) FROM DIM_CAMPAIGN
UNION ALL SELECT 'BRIDGE_DATE_TO_CAMPAIGN',        COUNT(*) FROM BRIDGE_DATE_TO_CAMPAIGN
UNION ALL SELECT 'FACT_CAMPAIGN_PERFORMANCE',      COUNT(*) FROM FACT_CAMPAIGN_PERFORMANCE;

-- DATE_DAY should be populated (no nulls).
SELECT CAMPAIGN_KEY, DATE_KEY, DATE_DAY, SPEND, REVENUE
FROM FACT_CAMPAIGN_PERFORMANCE
ORDER BY DATE_DAY
LIMIT 5;

-- Campaign metrics. total_spend matches budget_check; roas ~1.7x to 6.8x;
-- ctr ~1-4%; cpc ~$0.50-$2.50.
SELECT
    c.CAMPAIGN_NAME,
    c.CHANNEL,
    SUM(p.SPEND)                                                 AS total_spend,
    c.SPEND_USD                                                  AS budget_check,
    SUM(p.REVENUE)                                               AS total_revenue,
    ROUND(SUM(p.REVENUE) / NULLIF(SUM(p.SPEND), 0), 2)           AS roas,
    ROUND(100 * SUM(p.CLICKS) / NULLIF(SUM(p.IMPRESSIONS), 0), 2) AS ctr_pct,
    ROUND(SUM(p.SPEND) / NULLIF(SUM(p.CLICKS), 0), 2)            AS cpc
FROM FACT_CAMPAIGN_PERFORMANCE p
JOIN DIM_CAMPAIGN c ON p.CAMPAIGN_KEY = c.CAMPAIGN_KEY
GROUP BY c.CAMPAIGN_NAME, c.CHANNEL, c.SPEND_USD
ORDER BY roas DESC;

-- Channel rollup. Expect Social and Email highest, Paid Search lowest.
SELECT * FROM VW_CHANNEL_SUMMARY ORDER BY ROAS DESC;
