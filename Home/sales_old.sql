SELECT 
    date_dim.yearmo,
    sum(case when lower(b.type) = 'branded' then sales.units end) branded_units,
    sum(case when lower(b.type) = 'd2c' then sales.units end) d2c_units,
    sum(case when lower(b.brandtier) = 'premium' then sales.units end) premium_units,
    sum(case when lower(b.type) = 'branded' then sales.gmv end) branded_gmv,
    sum(case when lower(b.type) = 'd2c' then sales.gmv end) d2c_gmv,
    sum(case when lower(b.brandtier) = 'premium' then sales.gmv end) premium_gmv,
    sum(case when sales.gmv/sales.units <= 300 then sales.units end) 0_300_units,
    sum(case when sales.gmv/sales.units > 300 and sales.gmv/sales.units <= 500 then sales.units end) 300_500_units,
    sum(case when sales.gmv/sales.units > 500 and sales.gmv/sales.units <=1000 then sales.units end) 500_1000_units,
    sum(case when sales.gmv/sales.units > 1000 then sales.units end) 1000_plus_units,
    sum(case when sales.gmv/sales.units <= 300 then sales.gmv end) 0_300_gmv,
    sum(case when sales.gmv/sales.units > 300 and sales.gmv/sales.units <= 500 then sales.gmv end) 300_500_gmv,
    sum(case when sales.gmv/sales.units > 500 and sales.gmv/sales.units <=1000 then sales.gmv end) 500_1000_gmv,
    sum(case when sales.gmv/sales.units > 1000 then sales.gmv end) 1000_plus_gmv,
    sum(case when sales.gmv/sales.units <= 300 and sales.is_alpha_seller = TRUE then sales.units end) alpha_0_300_units,
    sum(case when sales.gmv/sales.units > 300 and sales.gmv/sales.units <= 500 and sales.is_alpha_seller = TRUE  then sales.units end) alpha_300_500_units,
    sum(case when sales.gmv/sales.units > 500 and sales.gmv/sales.units <= 1000 and sales.is_alpha_seller = TRUE then sales.units end) alpha_500_1000_units,
    sum(case when sales.gmv/sales.units > 1000 and sales.is_alpha_seller = TRUE then sales.units end) alpha_1000_plus_units,
    sum(case when sales.gmv/sales.units <= 300 and sales.is_alpha_seller = TRUE then sales.gmv end) alpha_0_300_gmv,
    sum(case when sales.gmv/sales.units > 300 and sales.gmv/sales.units <= 500 and sales.is_alpha_seller = TRUE then sales.gmv end) alpha_300_500_gmv,
    sum(case when sales.gmv/sales.units > 500 and sales.gmv/sales.units <= 1000 and sales.is_alpha_seller = TRUE then sales.gmv end) alpha_500_1000_gmv,
    sum(case when sales.gmv/sales.units > 1000 and sales.is_alpha_seller = TRUE then sales.gmv end) alpha_1000_plus_gmv,
    count(distinct(sales.account_id)) customers,
    count(distinct(case when c.new_cust_flag = 1 then sales.account_id end)) NN_customers,
    count(distinct(case when c.new_cust_flag <> 1 and c.new_to_bu = 1 then sales.account_id end)) ON_customers,
    count(distinct(case when c.new_cust_flag is null and c.new_to_bu is null then sales.account_id end)) OO_customers,
    count(distinct(sales.order_external_id)) orders,
    count(distinct(sales.shipment_id)) shipments,
    sum(sales.gmv) gmv,
    sum(sales.units) units,
    avg(sales.sla_in_days) sla,
    avg(datediff(sales.delivered_date_time, sales.order_date_time)) O2D,
    sum(case when sales.is_alpha_seller = TRUE then sales.units end) alpha_units,
    sum(case when sales.service_profile = 'FBF' and sales.sla_in_days <= 2 then sales.units end) fbf_d2_units,
    sum(case when sales.service_profile = 'FBF' then sales.units end) fbf_units,
    sum(case when sales.service_profile = 'FBF' and sales.is_alpha_seller = TRUE then sales.units end) alpha_fbf_units,
    sum(ret.return_item_quantity) RVP_units,
    sum(ret.return_amount) RVP_gmv,
    sum(case when sales.unit_is_rtod =1 then sales.units end) RTO_units,
    sum(case when sales.unit_is_rtod =1 then sales.gmv end) RTO_gmv,
    count(distinct(case when sales.order_payment_type = 'Prepaid' then sales.order_external_id end)) prepaid_orders,
    sum(case when lower(sales.status) = 'cancelled' then sales.units end) cancelled_units,
    sum(sales.units) gross_units
FROM bigfoot_external_neo.cp_bi_prod_sales__forward_unit_history_fact sales
LEFT JOIN fdp_uploads.ds_fkint_cp_santa_hyperlocal_vertical_bu_mapping_2_0 AS hl 
    ON sales.analytic_vertical = hl.analytic_vertical 
    AND LOWER(hl.bu_final) = 'home'
LEFT JOIN fdp_uploads.ds_fkint_analytics_cdo_brand_home_mapping_1_0 b
    ON lower(sales.analytic_super_category) = lower(b.analytic_super_category)
    AND lower(sales.brand) = lower(b.brand)
    AND lower(sales.analytic_vertical) = lower(b.analytic_vertical)
LEFT JOIN bigfoot_common.date_dim_cal date_dim 
    ON sales.order_date_key = date_dim.date_dim_key
LEFT JOIN
(
    SELECT
        forward_unit_id,
        sum(return_item_quantity) return_item_quantity,
        sum(return_amount) return_amount
    FROM bigfoot_external_neo.scp_rrr__return_l2_id_level_hive_ss_fact
    WHERE upper(return_type) = 'CUSTOMER_RETURN' 
    and ((order_item_approve_date_key between 20250101 and 20250727) or (order_item_approve_date_key between 20240101 and 20240727))
    and order_item_approve_date_key not in (20240229)
    and upper(return_item_status) in ('INIT', 'COMPLETED', 'APPROVED')
    GROUP BY
        forward_unit_id
) ret
ON ret.forward_unit_id = sales.id
LEFT JOIN 
(
    SELECT 
        order_item_id,
        max(new_cust_flag) new_cust_flag,
        max(new_to_bu) new_to_bu
    FROM bigfoot_external_neo.analytics_cdo__customer_insight_hive_fact  
    WHERE ((approve_date_key between 20250101 and 20250727) or (approve_date_key between 20240101 and 20240727))
    and approve_date_key not in (20240229)
    and (new_cust_flag = 1 or new_to_bu = 1)
    GROUP BY
        order_item_id
) c
ON c.order_item_id = sales.order_item_id
WHERE lower(sales.status) in ('in_progress', 'undelivered', 'cancelled', 'completed', 'delivered', 'approved', 'shipped', 'ready_to_ship', 'returned', 'return_requested', 'activated')
    and sales.type != 'service'
    and sales.replacement_for_unit IS NULL
    and sales.exchange_for_unit IS NULL
    and sales.is_freebie = FALSE
    AND (sales.marketplace_id IN ('FLIPKART') OR (sales.marketplace_id = 'HYPERLOCAL' AND  hl.analytic_vertical IS NOT NULL))
    and sales.analytic_business_unit IN ('Home')
    and lower(sales.analytic_super_category) in ('homedecor', 'homefurnishing', 'homeimprovementtool', 'household')
    and ((sales.order_date_key between 20250101 and 20250727) or (sales.order_date_key between 20240101 and 20240727))
    and sales.order_date_key not in (20240229)
    and sales.is_shopsy_order = FALSE
GROUP BY
    date_dim.yearmo;