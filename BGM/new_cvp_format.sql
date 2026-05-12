SELECT
    dl.week_num_in_year,
    sales.analytic_business_unit,
    sum(gmv) as total_gmv
FROM
    bigfoot_external_neo.cp_bi_prod_sales__forward_unit_history_fact sales

LEFT JOIN fdp_uploads.ds_fkint_cp_santa_hyperlocal_vertical_bu_mapping_2_0 AS hl
    ON sales.analytic_vertical = hl.analytic_vertical
    AND lower(hl.bu_final) IN ('bgm','home','lifestyle','coreelectronics','emergingelectronics','furnitur   e','largeappliances','mobiles')

 inner join  (select 
 date_dim_key,week_num_in_year from 
 bigfoot_external_neo.scp_oms__date_dim_fact
 where week_num_in_year = 44) as dl
on dl.date_dim_key= sales.order_date_key

WHERE
    LOWER(sales.status) IN ('in_progress', 'undelivered', 'completed', 'delivered', 'approved', 'shipped', 'ready_to_ship', 'returned', 'return_requested', 'activated')
    AND sales.type  = 'physical'
    AND sales.replacement_for_unit IS NULL
    AND sales.exchange_for_unit IS NULL
    AND sales.is_freebie = FALSE
    AND (sales.marketplace_id IN ('FLIPKART') or (sales.marketplace_id IN ('HYPERLOCAL') AND hl.bu_final is not null))
    AND sales.is_shopsy_order = FALSE
    AND sales.order_date_key between 20251027 and 20251102
    AND lower(sales.analytic_business_unit) IN ('bgm','home','lifestyle','coreelectronics','emergingelectronics','furniture','largeappliances','mobiles')

GROUP BY
    sales.analytic_business_unit