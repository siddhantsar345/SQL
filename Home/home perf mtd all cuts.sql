SELECT * FROM (

WITH
combined_events AS (
    SELECT
        customer_user_id AS account_id,
        event_time,
        CAST(REPLACE(SUBSTR(event_time, 1, 10), '-', '') AS INT64) AS event_date,
        event_name,
        campaign
    FROM bigfoot_common.fdp_prod_appsflyer_inapps_retargeting_v1
    WHERE CAST(REPLACE(SUBSTR(event_time, 1, 10), '-', '') AS INT64)
        BETWEEN 20251201 AND 20260622
      AND event_name = 'af_content_view'

    UNION ALL

    SELECT
        customer_user_id AS account_id,
        event_time,
        CAST(REPLACE(SUBSTR(event_time, 1, 10), '-', '') AS INT64) AS event_date,
        event_name,
        campaign
    FROM bigfoot_common.fdp_prod_appsflyer_inapps_v1
    WHERE CAST(REPLACE(SUBSTR(event_time, 1, 10), '-', '') AS INT64)
        BETWEEN 20251201 AND 20260622
      AND event_name = 'af_content_view'
),

base AS (
   SELECT
       sales.account_id,
       DATE(sales.order_date_time) AS order_date,
       MIN(sales.order_date_time) AS first_order_date_time,
       COUNT(DISTINCT sales.order_external_id) AS orders,
       SUM(sales.units) AS units,
       SUM(sales.gmv) AS gmv,
       MAX(CASE WHEN new_customer_flag = TRUE THEN 1 ELSE 0 END) AS nc_flag

   FROM bigfoot_external_neo.cp_bi_prod_sales__forward_unit_history_fact sales

   LEFT JOIN fdp_uploads.ds_fkint_cp_santa_hyperlocal_vertical_bu_mapping_2_0 AS hl
    ON sales.analytic_vertical = hl.analytic_vertical
    AND LOWER(hl.bu_final) = 'home'

   WHERE
    LOWER(sales.status) IN ('in_progress', 'undelivered', 'completed', 'delivered', 'approved', 'shipped', 'ready_to_ship', 'returned', 'return_requested', 'activated')
    AND sales.type = 'physical'
    AND sales.replacement_for_unit IS NULL
    AND sales.exchange_for_unit IS NULL
    AND sales.is_freebie = FALSE
    AND (sales.marketplace_id IN ('FLIPKART') OR (sales.marketplace_id = 'HYPERLOCAL' AND hl.analytic_vertical IS NOT NULL))
    AND sales.order_date_key BETWEEN 20251201 AND 20260622
    AND sales.analytic_business_unit IN ('Home')
    AND sales.is_shopsy_order = FALSE

    GROUP BY
    sales.account_id,
    DATE(sales.order_date_time)
),

order_events AS (
   SELECT
       o.*,
       e.event_time,
       e.event_date,
       e.campaign,
       RANK() OVER (
           PARTITION BY o.account_id, o.order_date
           ORDER BY e.event_time DESC
       ) AS rn
   FROM base o
   LEFT JOIN combined_events e
       ON o.account_id = e.account_id
      AND e.event_name = 'af_content_view'
      AND TIMESTAMP(e.event_time) BETWEEN
           TIMESTAMP(o.first_order_date_time) - INTERVAL 24 HOUR
       AND TIMESTAMP(o.first_order_date_time)
),

attributed AS (
   SELECT *
   FROM order_events
   WHERE rn = 1
    AND event_time IS NOT NULL
    AND campaign IN (
        'DPA_HomeBU_Adv_New – Copy', 'DPA_RT_HomeBU_Catchall_Prospecting – Copy', 'DPA_RT_HomeBU_HomeDecor_Adv',
        'DPA_RT_HomeBU_HomeFurnishing_Adv – Copy', 'DPA_RT_HomeBU_HomeImprovementTool – Copy 2', 'DPA_RT_HomeBU_HouseHold_Adv',
        'DPA_RT_HomeBU_LTPC-Purchasers_L45Day', 'HomeBU_AAA_MAC', 'HomeBU_CreatorPA_demandgen_LTPC--_NonAOP', 'HomeBU_CreatorPA_demandgen_nonaop',
        'HomeBU_GMV_PSO_New_GMV', 'HomeBU_GMV_PSO_New_tr', 'HomeBU_GMV_PSO+Installed', 'HomeBU_ReelAds_NonAOP_APP_Landing', 'HomeBU_Shopping_CatchAll_MaxClick',
        'Perf Max::SmartShopping:HomeBU:Purchase_Firebase', 'Perf Max::SmartShopping:HomeBU:Session_Firebase', 'UACE_HomeBU_MAC_NonAOP', 'UACI_HomeBU_MAC_NN_NonAOP',
        'UACI_HomeBU_MAC_NN_NonAOP_2', 'UACI_HomeBU_MAC_NN_NonAOP_FTP_Event', 'DPA_RT_HomeBU_Catchall_Prospecting', 'HomeBU_DemandGen_MAC_NonAOP',
        'DPA_RT_HomeBU_HomeDecor_Adv – Copy', 'DPA_RT_HomeBU_HouseHold – Copy', 'DPA_RT_HomeBU_HomeImprovementTool – Copy 1', 'DPA_RT_HomeBU_HomeFurnishing_Adv',
        'DPA_HomeBU_Adv_New', 'DPA_HomeBU_Adv', 'DPA_RT_HomeBU_Conversion value', 'DPA_RT_HomeBU_All', 'DPA_RT_HomeBU_All _Traffic', 'Fk_Home_UAC_LTPC–'
    )
),

react_30 AS (
SELECT
    a.account_id,
    a.order_date,
    CASE
        WHEN COUNT(DISTINCT sales.order_external_id) BETWEEN 1 AND 3 THEN 'c.LTPC'
        WHEN COUNT(DISTINCT sales.order_external_id) BETWEEN 4 AND 7 THEN 'd.MTPC'
        WHEN COUNT(DISTINCT sales.order_external_id) BETWEEN 8 AND 12 THEN 'e.HTPC'
        WHEN COUNT(DISTINCT sales.order_external_id) BETWEEN 13 AND 29 THEN 'f.VHTPC'
        WHEN COUNT(DISTINCT sales.order_external_id) >= 30 THEN 'g.VVHTPC'
    END AS tpc_bucket

FROM attributed a

LEFT JOIN bigfoot_external_neo.cp_bi_prod_sales__forward_unit_history_fact sales
    ON a.account_id = sales.account_id
    AND sales.order_date_key BETWEEN CAST(FORMAT_DATE('%Y%m%d', DATE_SUB(CURRENT_DATE(), INTERVAL 367 DAY)) AS INT64) AND CAST(FORMAT_DATE('%Y%m%d', DATE_SUB(CURRENT_DATE(), INTERVAL 3 DAY)) AS INT64)
    AND LOWER(sales.status) IN ('in_progress', 'undelivered', 'completed', 'delivered', 'approved', 'shipped', 'ready_to_ship', 'returned', 'return_requested', 'activated')
    AND sales.type = 'physical'
    AND sales.replacement_for_unit IS NULL
    AND sales.exchange_for_unit IS NULL
    AND sales.is_freebie = FALSE
    AND sales.analytic_business_unit IN ('Home')
    AND sales.is_shopsy_order = FALSE

LEFT JOIN fdp_uploads.ds_fkint_cp_santa_hyperlocal_vertical_bu_mapping_2_0 AS hl
    ON sales.analytic_vertical = hl.analytic_vertical
    AND LOWER(hl.bu_final) = 'home'

WHERE
    (sales.marketplace_id IN ('FLIPKART') OR (sales.marketplace_id = 'HYPERLOCAL' AND hl.analytic_vertical IS NOT NULL))

GROUP BY
    a.account_id,
    a.order_date

HAVING COUNT(sales.order_external_id) > 0
),

segmented AS (
 SELECT
     a.account_id,
     a.orders,
     a.order_date,
     a.units,
     a.gmv,
     a.event_date,
     a.campaign,
     CASE
         WHEN a.nc_flag = 1 THEN 'NN'
         WHEN r.account_id IS NULL THEN 'ON+REACT'
         ELSE tpc_bucket
     END AS segment
 FROM attributed a
 LEFT JOIN react_30 r
     ON r.account_id = a.account_id
    AND r.order_date = a.order_date
),

bu_level AS (
   SELECT
       DATE(sales.order_date_time) AS order_date,
       sales.account_id,
       sales.analytic_super_category,
       COUNT(DISTINCT sales.order_external_id) AS orders,
       SUM(sales.units) AS units,
       SUM(sales.gmv) AS gmv

   FROM bigfoot_external_neo.cp_bi_prod_sales__forward_unit_history_fact sales

    LEFT JOIN fdp_uploads.ds_fkint_cp_santa_hyperlocal_vertical_bu_mapping_2_0 AS hl
    ON sales.analytic_vertical = hl.analytic_vertical
    AND LOWER(hl.bu_final) = 'home'

    WHERE
    LOWER(sales.status) IN ('in_progress', 'undelivered', 'completed', 'delivered', 'approved', 'shipped', 'ready_to_ship', 'returned', 'return_requested', 'activated')
    AND sales.type = 'physical'
    AND sales.replacement_for_unit IS NULL
    AND sales.exchange_for_unit IS NULL
    AND sales.is_freebie = FALSE
    AND (sales.marketplace_id IN ('FLIPKART') OR (sales.marketplace_id = 'HYPERLOCAL' AND hl.analytic_vertical IS NOT NULL))
    AND sales.order_date_key BETWEEN 20251201 AND 20260622
    AND sales.analytic_business_unit IN ('Home')
    AND sales.is_shopsy_order = FALSE

    GROUP BY
    DATE(sales.order_date_time),
    sales.account_id,
    sales.analytic_super_category
)


SELECT
   analytic_super_category AS cohort,
   SUBSTR(CAST(s.event_date AS STRING), 1, 6) AS year_month,
   segment,
   COUNT(DISTINCT s.account_id) AS distinct_customers,
   SUM(b.orders) AS distinct_orders,
   SUM(b.units)  AS units,
   SUM(b.gmv)    AS gmv
FROM segmented s
LEFT JOIN bu_level b
  ON s.account_id = b.account_id
  AND s.order_date = b.order_date
GROUP BY analytic_super_category, SUBSTR(CAST(s.event_date AS STRING), 1, 6), segment

UNION ALL

SELECT
   campaign AS cohort,
   SUBSTR(CAST(event_date AS STRING), 1, 6) AS year_month,
   segment,
   COUNT(DISTINCT account_id) AS distinct_customers,
   SUM(orders) AS distinct_orders,
   SUM(units)  AS units,
   SUM(gmv)    AS gmv
FROM segmented
GROUP BY campaign, SUBSTR(CAST(event_date AS STRING), 1, 6), segment

UNION ALL

SELECT
   'Home' AS cohort,
   SUBSTR(CAST(s.event_date AS STRING), 1, 6) AS year_month,
   segment,
   COUNT(DISTINCT s.account_id) AS distinct_customers,
   SUM(b.orders) AS distinct_orders,
   SUM(b.units)  AS units,
   SUM(b.gmv)    AS gmv
FROM segmented s
LEFT JOIN bu_level b
  ON s.account_id = b.account_id
  AND s.order_date = b.order_date
GROUP BY SUBSTR(CAST(s.event_date AS STRING), 1, 6), segment

) AS ss;