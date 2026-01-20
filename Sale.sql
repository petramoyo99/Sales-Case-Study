SELECT
  *
FROM
  "BPLSALES"."CASE"."ANALYSIS"
LIMIT
  10;

 SELECT 
    /* =============================
       CORE IDENTIFIERS
       ============================= */
    TO_DATE("DATE", 'DD/MM/YYYY')                        AS SALE_DATE,
    DAYNAME(TO_DATE("DATE", 'DD/MM/YYYY'))               AS DAY_OF_WEEK,
    DATE_TRUNC('WEEK', TO_DATE("DATE", 'DD/MM/YYYY'))    AS WEEK_START,
    DATE_TRUNC('MONTH', TO_DATE("DATE", 'DD/MM/YYYY'))   AS MONTH_START,

    /* =============================
       RAW VALUES
       ============================= */
    "SALES"                                              AS TOTAL_SALES,
    "QUANTITY_SOLD"                                      AS QUANTITY_SOLD,

    /* =============================
       Q1: DAILY UNIT PRICE
       ============================= */
    ROUND("SALES" / NULLIF("QUANTITY_SOLD", 0), 2)       AS UNIT_PRICE,

    /* =============================
       Q3: DAILY GROSS MARGIN %
       ============================= */
    ROUND(
        CASE 
            WHEN "SALES" > 0 
            THEN (("SALES" - "COST_OF_SALES") / "SALES") * 100 
        END, 2
    )                                                     AS GROSS_MARGIN_PCT,

    /* =============================
       Q4: GROSS PROFIT PER UNIT
       ============================= */
    ROUND(
        ("SALES" - "COST_OF_SALES") / NULLIF("QUANTITY_SOLD", 0), 
        2
    )                                                     AS GROSS_PROFIT_PER_UNIT,

    /* =============================
       EXTRA METRICS
       ============================= */
    ("SALES" - "COST_OF_SALES")                           AS GROSS_PROFIT,

    /* =============================
       PRICE VS 7 DAYS AGO
       ============================= */
    LAG(
        ROUND("SALES" / NULLIF("QUANTITY_SOLD", 0), 2), 7
    ) OVER (ORDER BY TO_DATE("DATE", 'DD/MM/YYYY'))       AS UNIT_PRICE_7D_AGO,

    ROUND(
        CASE 
            WHEN LAG("SALES" / NULLIF("QUANTITY_SOLD", 0), 7)
                 OVER (ORDER BY TO_DATE("DATE", 'DD/MM/YYYY')) > 0
            THEN (
                ("SALES" / NULLIF("QUANTITY_SOLD", 0)) -
                LAG("SALES" / NULLIF("QUANTITY_SOLD", 0), 7)
                OVER (ORDER BY TO_DATE("DATE", 'DD/MM/YYYY'))
            )
            /
            LAG("SALES" / NULLIF("QUANTITY_SOLD", 0), 7)
            OVER (ORDER BY TO_DATE("DATE", 'DD/MM/YYYY')) * 100
        END, 1
    )                                                     AS PRICE_PCT_CHANGE_VS_7D_AGO,

    /* =============================
       OVERALL KPIs (WINDOWED)
       ============================= */
    COUNT(*) OVER ()                                     AS TOTAL_SELLING_DAYS,

    SUM("QUANTITY_SOLD") OVER ()                          AS TOTAL_UNITS_SOLD,

    ROUND(SUM("SALES") OVER (), 0)                        AS TOTAL_REVENUE,

    ROUND(SUM("SALES" - "COST_OF_SALES") OVER (), 0)      AS TOTAL_GROSS_PROFIT,

    ROUND(
        AVG(
            CASE 
                WHEN "SALES" > 0 
                THEN (("SALES" - "COST_OF_SALES") / "SALES") * 100 
            END
        ) OVER (), 
        2
    )                                                     AS AVG_GROSS_MARGIN_PCT,

    /* =============================
       Q2: WEIGHTED AVG UNIT PRICE
       ============================= */
    ROUND(
        SUM("SALES") OVER () /
        NULLIF(SUM("QUANTITY_SOLD") OVER (), 0),
        2
    )                                                     AS AVG_UNIT_PRICE_WEIGHTED,

    /* =============================
       PRICE EXTREMES
       ============================= */
    ROUND(
        MIN("SALES" / NULLIF("QUANTITY_SOLD", 0)) OVER (), 
        2
    )                                                     AS LOWEST_UNIT_PRICE_EVER,

    ROUND(
        MAX("SALES" / NULLIF("QUANTITY_SOLD", 0)) OVER (), 
        2
    )                                                     AS HIGHEST_UNIT_PRICE_EVER,

    /* =============================
       PROMO FLAG
       ============================= */
    CASE 
        WHEN ROW_NUMBER() OVER (
            ORDER BY ("SALES" / NULLIF("QUANTITY_SOLD", 0)) ASC
        ) <= 40 
        THEN 'LIKELY PROMO' 
        ELSE 'NORMAL' 
    END                                                   AS PRICE_CATEGORY

FROM BPLSALES.CASE.ANALYSIS

WHERE "QUANTITY_SOLD" > 0
  AND "SALES" >= "COST_OF_SALES"
  AND "DATE" IS NOT NULL

ORDER BY TO_DATE("DATE", 'DD/MM/YYYY') ASC;
