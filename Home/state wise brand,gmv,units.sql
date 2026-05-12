select
geo.state,
b.brand,
sum(sales.gmv) as total_gmv,
sum(sales.units) as total_units

FROM
    bigfoot_external_neo.cp_bi_prod_sales__forward_unit_history_fact sales

LEFT JOIN
  fdp_uploads.ds_fkint_analytics_cdo_brand_d2c_home_mapping_1_0 b
on lower(sales.analytic_super_category) = lower(b.analytic_super_category)

LEFT JOIN bigfoot_external_neo.scp_ekl__logistics_geo_hive_dim AS geo
    ON sales.pincode = geo.pincode

WHERE
    LOWER(sales.status) IN ('in_progress', 'undelivered', 'completed', 'delivered', 'approved', 'shipped', 'ready_to_ship', 'returned', 'return_requested', 'activated')
    AND sales.type = 'physical'
    AND sales.replacement_for_unit IS NULL
    AND sales.exchange_for_unit IS NULL
    AND sales.is_freebie = FALSE
    AND LOWER(sales.marketplace_id) IN ('flipkart')
    AND sales.order_date_key BETWEEN 20250601 AND 20251231
    AND sales.analytic_business_unit IN ('Home')
    AND lower(sales.analytic_super_category) IN ('household')
    AND sales.is_shopsy_order = FALSE

group by 1,2