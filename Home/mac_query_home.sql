SELECT
    substr(cast(sales.order_date_key as string), 1, 6) as year_mo,
    COUNT(DISTINCT account_id) AS monthly_active_customers
FROM
    bigfoot_external_neo.cp_bi_prod_sales__forward_unit_history_fact sales

    LEFT JOIN  fdp_uploads.ds_fkint_cp_santa_hyperlocal_vertical_bu_mapping_2_0 AS hl 
    ON sales.analytic_vertical = hl.analytic_vertical 
    AND LOWER(hl.bu_final) = 'home'  
    and sales.marketplace_id='HYPERLOCAL'
    
WHERE
lower(sales.status) in ('in_progress', 'undelivered', 'completed', 'delivered', 'approved', 'shipped', 'ready_to_ship', 'returned', 'return_requested', 'activated')
    and sales.type != 'service'
    and sales.replacement_for_unit IS NULL
    and sales.exchange_for_unit IS NULL
    and sales.is_freebie = FALSE
    and sales.order_date_key between 20250101 and 20250930
    AND (sales.marketplace_id IN ('FLIPKART') OR (sales.marketplace_id = 'HYPERLOCAL' AND  hl.analytic_vertical IS NOT NULL))
    and sales.analytic_business_unit = 'Home'
    and sales.is_shopsy_order = FALSE 