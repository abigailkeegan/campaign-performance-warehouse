# Marketing Campaign Performance Warehouse

A dimensional data warehouse that turns raw ecommerce transactions into a multi-channel marketing analysis. Built on Snowflake, with the analysis in
Python.

The goal was to take a real transactional dataset and model it into something that answers a marketing team's recurring question: which channels and campaigns return the most per dollar, and where should the next dollar go?

## Architecture

```
UCI Online Retail II  ->  Star schema (Snowflake)  ->  Campaign         ->  Python
(real transactions)       DIM_* / FACT_SALES           performance fact      analysis
                          + date-to-campaign bridge    (campaign x date)
```

The real transactional data provides genuine revenue and order volume. A campaign layer sits on top of it, attributing sales to campaigns through a date bridge and adding the marketing metrics the source data doesn't contain.

## Star schema

| Table | Grain | Role |
|-------|-------|------|
| `FACT_SALES` | transaction line | real revenue base (Online Retail II) |
| `FACT_CAMPAIGN_PERFORMANCE` | campaign x date | marketing metrics (built here) |
| `DIM_CAMPAIGN` | campaign | campaign name, channel, budget |
| `BRIDGE_DATE_TO_CAMPAIGN` | date | maps each date to its active campaign |
| `DIM_CUSTOMER`, `DIM_PRODUCT`, `DIM_DATE` | customer / product / date | conformed dimensions |
| `VW_SALES_WITH_CAMPAIGN` | transaction line | flattened sales with campaign attribution |
| `RAW.RAW_TRANSACTIONS` | transaction line | raw Online Retail II source (separate RAW schema) |

## Metrics

All ratio metrics are computed as a sum divided by a sum:

| Metric | Definition |
|--------|------------|
| ROAS | total revenue / total spend |
| CTR | total clicks / total impressions |
| CPC | total spend / total clicks |
| Conversion rate | total conversions / total clicks |

## Analysis

`analysis/snowflake_campaign_analysis.ipynb` connects to the warehouse with key-pair
authentication and explores the data:

- ROAS by channel, the headline view for budget decisions
- Spend vs revenue over time, with a 7-day moving average
- Campaign ROAS ranking, colored by channel
- Conversion funnel from impressions to clicks to conversions
- Spend vs revenue per campaign, against a break-even line

It reads the summary views and the daily performance fact directly, so the
metric definitions stay in the warehouse rather than being redefined in
Python. Findings are written up at the end of the notebook.

## Tech stack

- **Snowflake** for the warehouse and SQL transformations
- **Python** (pandas, matplotlib, seaborn) for the analysis
- **SQL** for dimensional modeling and the performance fact build

## Running the pipeline

The `RAW.RAW_TRANSACTIONS` table (Online Retail II) is the source of truth. The `ANALYTICS` layer is built from it by running the SQL files in order:

```
01_dimensions.sql              -- DIM_DATE, DIM_CUSTOMER, DIM_PRODUCT
02_fact_sales.sql              -- FACT_SALES from raw + dimensions
03_campaigns_and_bridge.sql    -- DIM_CAMPAIGN, bridge, attribution view
04_fact_campaign_performance.sql -- the marketing performance fact
05_summary_views.sql           -- campaign + channel rollups
06_validation.sql              -- health checks
```

Then run the notebook (see `analysis/requirements.txt` for dependencies).

## Repo structure

```
.
├── README.md
├── sql/
│   ├── 01_dimensions.sql
│   ├── 02_fact_sales.sql
│   ├── 03_campaigns_and_bridge.sql
│   ├── 04_fact_campaign_performance.sql
│   ├── 05_summary_views.sql
│   └── 06_validation.sql
└── analysis/
    ├── snowflake_campaign_analysis.ipynb
    └── requirements.txt
```

## Data source

Transactional data is the Online Retail II dataset from the UCI Machine Learning Repository: https://archive.ics.uci.edu/dataset/502/online+retail+ii

