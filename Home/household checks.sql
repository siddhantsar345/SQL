WITH sales_agg AS (
  SELECT
    SUBSTR(CAST(sales.order_date_key AS STRING), 1, 6) AS month_key,
    sales.analytic_business_unit,
    sales.analytic_super_category,
    sales.analytic_vertical,
    sales.listing_id,
    sales.product_id,
    CASE WHEN sales.is_alpha_seller = TRUE  THEN 'diamond'
         WHEN sales.is_alpha_seller = FALSE THEN 'mp' END AS alpha_flag,
    sales.brand,
    SUM(sales.gmv) AS total_gmv,
    SUM(sales.units) AS total_units,
    SUM(sales.gmv) / SUM(sales.units) AS asp
  FROM bigfoot_external_neo.cp_bi_prod_sales__forward_unit_history_fact AS sales
  WHERE LOWER(sales.status) IN ('in_progress', 'undelivered', 'completed', 'delivered','approved', 'shipped', 'ready_to_ship', 'returned', 'return_requested', 'activated')
    AND sales.type = 'physical'
    AND sales.replacement_for_unit IS NULL
    AND sales.exchange_for_unit IS NULL
    AND sales.is_freebie = FALSE
    AND sales.marketplace_id = 'FLIPKART'
    AND sales.is_shopsy_order = FALSE
    AND sales.order_date_key BETWEEN 20260401 AND 20260628
    AND LOWER(sales.analytic_business_unit)  = 'home'
    AND LOWER(sales.analytic_super_category) = 'household'
  GROUP BY 1, 2, 3, 4, 5, 6, 7, 8
),

ppvs_agg AS (
  SELECT
    SUBSTR(CAST(date_key AS STRING), 1, 6) AS month_key,
    listing_id,
    SUM(primary_ppvs) AS ppvs
  FROM bigfoot_external_neo.cp_santa__listing_performance_at_day_level_with_sales_90d_fact
  WHERE date_key BETWEEN 20260401 AND 20260628
  AND lower(analytic_business_unit)= 'home'
  AND lower(analytic_super_category)= 'household'
  GROUP BY 1, 2
),

settlement_agg AS (
  SELECT
    SUBSTR(CAST(sp.order_date_key AS STRING), 1, 6) AS month_key,
    sp.listing_id,
    SUM(sp.settlement_price * sp.units) AS settlement_value,
    SUM(sp.units) AS settlement_units
  FROM bigfoot_external_neo.cp_santa__mp_seller_pre_settlement_fact sp
  LEFT JOIN bigfoot_external_neo.sp_product__product_categorization_hive_dim cat
    ON sp.product_id = cat.product_id
  WHERE sp.order_date_key BETWEEN 20260401 AND 20260628
    AND sp.units > 0 AND sp.listing_price > 0
    AND LOWER(sp.analytic_business_unit)   = 'home'
    AND LOWER(cat.analytic_super_category) = 'household'
  GROUP BY 1, 2
),

burn_agg AS (
  SELECT
    bmain.month_key,
    bmain.listing_id,
    SUM(bmain.abs_jira_burn) AS abs_jira_burn,
    SUM(bmain.abs_fk_insta_burn) AS abs_insta_burn,
    SUM(COALESCE(coupon.gross_burn_amount, 0)) AS coupon_burn
  FROM (
    SELECT
      SUBSTR(CAST(a.order_date_key AS STRING), 1, 6) AS month_key,
      a.order_date_key,
      a.listing_id,
      SUM(COALESCE(a.abs_fk_insta_burn, 0)) AS abs_fk_insta_burn,
      SUM(COALESCE(a.ideal_abs_commission_fee, 0) - COALESCE(a.actual_commission, 0)
          + COALESCE(a.ideal_abs_closing_fee, 0) - COALESCE(a.actual_closing_fee, 0)) AS abs_jira_burn
    FROM bigfoot_external_neo.analytics_cdo__festive_listing_level_current_rpc_fact a
    WHERE a.platform_fee_exists >= 1
      AND a.base_rate_flag = '1'
      AND a.ap_exists_flag = 1
      AND a.order_date_key BETWEEN 20260401 AND 20260628
      AND LOWER(a.analytic_business_unit)  = 'home'
      AND LOWER(a.analytic_super_category) = 'household'
    GROUP BY 1, 2, 3
  ) bmain
  LEFT JOIN (
    SELECT
      b.order_date_key AS unit_creation_date,
      b.listing_id,
      SUM(CASE WHEN a.offer_id IS NOT NULL AND a.gross_units IS NOT NULL
            THEN (a.gross_units / a.total_units)
                 * a.order_item_offers_snapshot_effective_price_change
                 * a.fkmp_burn_share / 100
            ELSE 0 END) AS gross_burn_amount
    FROM (
      SELECT
        fuf.order_date_key,
        fuf.order_item_id,
        fuf.listing_id
      FROM bigfoot_external_neo.cp_bi_prod_sales__forward_unit_history_fact fuf
      WHERE fuf.order_date_key BETWEEN 20260401 AND 20260628
        AND (fuf.replacement_for_unit IS NULL OR fuf.replacement_for_unit = 'not_replacement')
        AND (fuf.exchange_for_unit  IS NULL OR fuf.exchange_for_unit  = 'not_exchange')
        AND fuf.category_id NOT IN (21651, 21726)
        AND fuf.marketplace_id = 'FLIPKART'
        AND fuf.type = 'physical'
        AND fuf.is_freebie = FALSE
        AND fuf.is_shopsy_order = FALSE
        AND fuf.is_alpha_seller = FALSE
        AND LOWER(fuf.status) IN ('in_progress','undelivered','completed','delivered','approved','shipped','ready_to_ship','returned','return_requested','activated')
      GROUP BY 1, 2, 3
    ) b
    LEFT JOIN (
      SELECT
        order_item_id, offer_id, gross_units, net_units, total_units,
        order_item_offers_snapshot_effective_price_change, fkmp_burn_share
      FROM bigfoot_external_neo.cp_santa__offer_sales_cancellations_365_incr_fact
      WHERE CAST(FORMAT_TIMESTAMP('%Y%m%d', order_date_time) AS INT64) BETWEEN 20260401 AND 20260628
        AND is_first_party_seller = FALSE
      GROUP BY 1, 2, 3, 4, 5, 6, 7
    ) a
      ON a.order_item_id = b.order_item_id
    GROUP BY 1, 2
  ) coupon
    ON coupon.listing_id = bmain.listing_id
   AND coupon.unit_creation_date = bmain.order_date_key
  GROUP BY 1, 2
)

SELECT
  s.month_key,
  s.analytic_business_unit,
  s.analytic_super_category,
  s.analytic_vertical,
  s.listing_id,
  s.product_id,
  s.alpha_flag,
  s.brand,
  s.total_gmv,
  s.total_units,
  s.asp,
  p.ppvs,
  st.settlement_value,
  st.settlement_units,
  bn.abs_jira_burn,
  bn.abs_insta_burn,
  bn.coupon_burn
FROM sales_agg s
LEFT JOIN ppvs_agg p
  ON  s.month_key  = p.month_key
  AND s.listing_id = p.listing_id
LEFT JOIN settlement_agg st
  ON  s.month_key  = st.month_key
  AND s.listing_id = st.listing_id
LEFT JOIN burn_agg bn
  ON  s.month_key  = bn.month_key
  AND s.listing_id = bn.listing_id;