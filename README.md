# Sales Performance Analysis – Snowflake SQL Pipeline

**End-to-end daily sales analytics query** that transforms raw sales data into actionable KPIs: unit price trends, gross margin %, gross profit per unit, 7-day price change, weighted average price, historical extremes, and basic promo detection.

Overall purpose: Monitor pricing behavior, profitability, and detect promotional periods from daily transaction data.

## Project Highlights

- Clean, commented Snowflake SQL query
- Handles edge cases (zero quantity, negative margins, missing dates)
- Calculates **core retail KPIs** used in real-world reporting
- Uses window functions for overall aggregates without subqueries
- Includes **7-day price change %** for trend detection
- Flags likely promotional days based on lowest unit prices

## Key Metrics Calculated

- **Sale Date** + day/week/month grouping
- **Unit Price** (daily & weighted average across all time)
- **Gross Margin %** (daily & overall average)
- **Gross Profit** (total & per unit)
- **Price change vs 7 days ago** (%)
- **Historical extremes** (lowest & highest unit price ever)
- **Promo likelihood flag** (bottom 40 lowest-price days marked "LIKELY PROMO")
- **Total aggregates** — selling days, units sold, revenue, gross profit

## SQL Query Overview

The main query is located in → [`sales_kpi_analysis.sql`](./sales_kpi_analysis.sql)

Main features:
- Date parsing & truncation
- Safe division (`NULLIF`)
- Window functions (`LAG`, `SUM/AVG/MIN/MAX OVER()`, `COUNT(*) OVER()`)
- Conditional logic for margin & price change
- Row-level promo flagging using ranked unit prices

```sql
-- Example snippet (full query in file)
ROUND("SALES" / NULLIF("QUANTITY_SOLD", 0), 2) AS UNIT_PRICE,

LAG(..., 7) OVER (ORDER BY ...) AS UNIT_PRICE_7D_AGO,

ROUND( ... price change logic ... , 1) AS PRICE_PCT_CHANGE_VS_7D_AGO,

CASE WHEN ROW_NUMBER() OVER (ORDER BY unit_price ASC) <= 40 THEN 'LIKELY PROMO' END
