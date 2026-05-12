SELECT
    tbl.brand,
    tbl.analytic_super_category
FROM fdp_uploads.ds_fkint_analytics_cdo_final_central_consolidated_sc_brand_list_fact_1_0 tbl

WHERE tbl.brand IN (
    SELECT DISTINCT brand
    FROM bigfoot_external_neo.cp_bi_prod_sales__forward_unit_history_fact
    WHERE LOWER(status) IN ('in_progress','undelivered','completed','delivered','approved','shipped','ready_to_ship','returned','return_requested','activated')
      AND type!= 'service'
      AND replacement_for_unit IS NULL
      AND exchange_for_unit IS NULL
      AND is_freebie= FALSE
      AND marketplace_id IN ('FLIPKART')
      AND is_shopsy_order = FALSE
      AND LOWER(analytic_business_unit) IN ('bgm','home','lifestyle','furniture')
      AND order_date_key <= 20260427
)

GROUP BY 
tbl.brand, 
tbl.analytic_super_category