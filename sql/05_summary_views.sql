-- Campaign-level and channel-level summary views.
-- Ratios are computed as sum over sum. CTR and conversion rate are
-- returned as ratios (0 to 1); format as percentages in the BI layer.

USE DATABASE MARKETING_WAREHOUSE;
USE SCHEMA ANALYTICS;

-- One row per campaign.
CREATE OR REPLACE VIEW MARKETING_WAREHOUSE.ANALYTICS.VW_CAMPAIGN_SUMMARY AS
SELECT
    c.CAMPAIGN_KEY,
    c.CAMPAIGN_NAME,
    c.CHANNEL,
    SUM(p.SPEND)                                              AS TOTAL_SPEND,
    SUM(p.REVENUE)                                            AS TOTAL_REVENUE,
    SUM(p.CONVERSIONS)                                        AS TOTAL_CONVERSIONS,
    SUM(p.CLICKS)                                             AS TOTAL_CLICKS,
    SUM(p.IMPRESSIONS)                                        AS TOTAL_IMPRESSIONS,
    ROUND(SUM(p.REVENUE) / NULLIF(SUM(p.SPEND), 0), 2)        AS ROAS,
    ROUND(SUM(p.CLICKS) / NULLIF(SUM(p.IMPRESSIONS), 0), 4)   AS CTR,
    ROUND(SUM(p.SPEND) / NULLIF(SUM(p.CLICKS), 0), 2)         AS CPC,
    ROUND(SUM(p.CONVERSIONS) / NULLIF(SUM(p.CLICKS), 0), 4)   AS CONVERSION_RATE
FROM MARKETING_WAREHOUSE.ANALYTICS.FACT_CAMPAIGN_PERFORMANCE p
JOIN MARKETING_WAREHOUSE.ANALYTICS.DIM_CAMPAIGN c
    ON p.CAMPAIGN_KEY = c.CAMPAIGN_KEY
WHERE c.CAMPAIGN_KEY <> -1
GROUP BY c.CAMPAIGN_KEY, c.CAMPAIGN_NAME, c.CHANNEL;

-- One row per channel.
CREATE OR REPLACE VIEW MARKETING_WAREHOUSE.ANALYTICS.VW_CHANNEL_SUMMARY AS
SELECT
    c.CHANNEL,
    COUNT(DISTINCT c.CAMPAIGN_KEY)                           AS CAMPAIGNS,
    SUM(p.SPEND)                                             AS TOTAL_SPEND,
    SUM(p.REVENUE)                                           AS TOTAL_REVENUE,
    SUM(p.CONVERSIONS)                                       AS TOTAL_CONVERSIONS,
    ROUND(SUM(p.REVENUE) / NULLIF(SUM(p.SPEND), 0), 2)       AS ROAS,
    ROUND(SUM(p.CLICKS) / NULLIF(SUM(p.IMPRESSIONS), 0), 4)  AS CTR,
    ROUND(SUM(p.SPEND) / NULLIF(SUM(p.CLICKS), 0), 2)        AS CPC,
    ROUND(SUM(p.CONVERSIONS) / NULLIF(SUM(p.CLICKS), 0), 4)  AS CONVERSION_RATE
FROM MARKETING_WAREHOUSE.ANALYTICS.FACT_CAMPAIGN_PERFORMANCE p
JOIN MARKETING_WAREHOUSE.ANALYTICS.DIM_CAMPAIGN c
    ON p.CAMPAIGN_KEY = c.CAMPAIGN_KEY
WHERE c.CAMPAIGN_KEY <> -1
GROUP BY c.CHANNEL;
