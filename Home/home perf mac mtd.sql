Select * from (

WITH
combined_events AS (
 SELECT distinct
     account_id,
     event_time,
     event_date,
     event_name,
     af_c_id,
     campaign

 FROM bigfoot_external_neo.analytics_cdo__appsflyer_fact
),


base AS (
   SELECT
       sales.account_id,
       DATE(sales.order_date_time) AS order_date,
       min(sales.order_date_time) as first_order_date_time,
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
    AND sales.order_date_key BETWEEN CAST(FORMAT_DATE('%Y%m%d', DATE_SUB(CURRENT_DATE(), INTERVAL 2 DAY)) AS INT64) AND CAST(FORMAT_DATE('%Y%m%d', DATE_SUB(CURRENT_DATE(), INTERVAL 1 DAY)) AS INT64) 
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
    AND campaign IN ('DPA_HomeBU_Adv_New – Copy', 'DPA_RT_HomeBU_Catchall_Prospecting – Copy', 'DPA_RT_HomeBU_HomeDecor_Adv', 
    'DPA_RT_HomeBU_HomeFurnishing_Adv – Copy', 'DPA_RT_HomeBU_HomeImprovementTool – Copy 2', 'DPA_RT_HomeBU_HouseHold_Adv', 
    'DPA_RT_HomeBU_LTPC-Purchasers_L45Day', 'HomeBU_AAA_MAC', 'HomeBU_CreatorPA_demandgen_LTPC--_NonAOP', 'HomeBU_CreatorPA_demandgen_nonaop', 
    'HomeBU_GMV_PSO_New_GMV', 'HomeBU_GMV_PSO_New_tr', 'HomeBU_GMV_PSO+Installed', 'HomeBU_ReelAds_NonAOP_APP_Landing', 'HomeBU_Shopping_CatchAll_MaxClick', 
    'Perf Max::SmartShopping:HomeBU:Purchase_Firebase', 'Perf Max::SmartShopping:HomeBU:Session_Firebase', 'UACE_HomeBU_MAC_NonAOP', 'UACI_HomeBU_MAC_NN_NonAOP', 
    'UACI_HomeBU_MAC_NN_NonAOP_2', 'UACI_HomeBU_MAC_NN_NonAOP_FTP_Event', 'DPA_RT_HomeBU_Catchall_Prospecting', 'HomeBU_DemandGen_MAC_NonAOP', 
    'DPA_RT_HomeBU_HomeDecor_Adv – Copy', 'DPA_RT_HomeBU_HouseHold – Copy', 'DPA_RT_HomeBU_HomeImprovementTool – Copy 1', 'DPA_RT_HomeBU_HomeFurnishing_Adv', 
    'DPA_HomeBU_Adv_New', 'DPA_HomeBU_Adv', 'DPA_RT_HomeBU_Conversion value', 'DPA_RT_HomeBU_All', 'DPA_RT_HomeBU_All _Traffic', 'Fk_Home_UAC_LTPC–')

),


bu_level AS (
   SELECT
       DATE(sales.order_date_time) AS order_date,
       sales.account_id,
       analytic_super_category

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
    AND sales.order_date_key BETWEEN CAST(FORMAT_DATE('%Y%m%d', DATE_SUB(CURRENT_DATE(), INTERVAL 2 DAY)) AS INT64) AND CAST(FORMAT_DATE('%Y%m%d', DATE_SUB(CURRENT_DATE(), INTERVAL 1 DAY)) AS INT64) 
    AND sales.analytic_business_unit IN ('Home')
    AND sales.is_shopsy_order = FALSE

    GROUP BY 
    DATE(sales.order_date_time),
    sales.account_id,
    sales.analytic_super_category
)


-- ===============================
-- FINAL OUTPUT (Overall + Campaign)
-- ===============================

SELECT
   analytic_super_category AS cohort,
   SUBSTR(CAST(event_date AS STRING), 1, 6) as year_month,
   COUNT(DISTINCT s.account_id) AS distinct_customers
FROM attributed s
left join bu_level b
on s.account_id = b.account_id
and s.order_date = b.order_date
GROUP BY analytic_super_category, SUBSTR(CAST(event_date AS STRING), 1, 6)


UNION ALL


SELECT
   'Home' AS cohort,
   SUBSTR(CAST(event_date AS STRING), 1, 6) as year_month,
   COUNT(DISTINCT s.account_id) AS distinct_customers
FROM attributed s
left join bu_level b
on s.account_id = b.account_id
and s.order_date = b.order_date
GROUP BY
SUBSTR(CAST(event_date AS STRING), 1, 6)  ) as ss