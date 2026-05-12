select
sales_query.yearmo,
branded_units,
d2c_units,
premium_units,
mass_premium_units,
mass_units,
branded_gmv,
d2c_gmv,
premium_gmv,
mass_premium_gmv,
mass_gmv,
0_300_units,
300_500_units,
500_1000_units,
1000_plus_units,
0_150_gmv,
150_300_gmv,
300_500_gmv,
500_1000_gmv,
1000_plus_gmv,
alpha_0_300_units,
alpha_300_500_units,
alpha_500_1000_units,
alpha_1000_plus_units,
alpha_0_300_gmv,
alpha_300_500_gmv,
alpha_500_1000_gmv,
alpha_1000_plus_gmv,
torsotail_gmv,
torsotail_units,
customers,
nn_customers,
on_customers,
oo_customers,
orders,
shipments,
gmv,
units,
sla,
o2d,
alpha_units,
fbf_d2_units,
fbf_units,
alpha_fbf_units,
rvp_units,
rvp_gmv,
rto_units,
rto_gmv,
prepaid_orders,
premium_active_gmv,
premium_active_units,
classic_active_gmv,
classic_active_units,
cancelled_units,
gross_units,
mp_gmv,
mp_units,
alpha_gmv,
nfbf_units,
fbf_orders,
fbf_shipments,
nfbf_orders,
nfbf_shipments,
mp_fbf_units,
0.0 as ru_percentage,
d0_units,
d1_units,
d2_units,
ru_num,
ru_den,
fk_units,
fk_orders,
fk_shipments,
fk_fbf_units,
fk_fbf_orders,
fk_fbf_shipments,
fk_nfbf_units,
fk_nfbf_orders,
fk_nfbf_shipments,
fbf_ru_percentage

from

(
(SELECT 
    date_dim.yearmo,
    SUM(CASE WHEN LOWER(b.branded_flag) = 'branded' THEN sales.units END) AS branded_units,
    SUM(CASE WHEN lower(b.branded_flag)='branded' and LOWER(b2.brand_type) = 'd2c' THEN sales.units END) AS d2c_units,
    SUM(CASE WHEN lower(b.branded_flag)='branded' and LOWER(b.brand_tier) = 'premium' THEN sales.units END) AS premium_units,
    SUM(CASE WHEN lower(b.branded_flag)='branded' and LOWER(b.brand_tier) = 'masstige' THEN sales.units END) AS mass_premium_units,
    SUM(CASE WHEN lower(b.branded_flag)='branded' and LOWER(b.brand_tier) = 'mass' THEN sales.units END) AS mass_units,
    SUM(CASE WHEN LOWER(b.branded_flag) = 'branded' THEN sales.gmv END) AS branded_gmv,
    SUM(CASE WHEN lower(b.branded_flag)='branded' and LOWER(b2.brand_type) = 'd2c' THEN sales.gmv END) AS d2c_gmv,
    SUM(CASE WHEN lower(b.branded_flag)='branded' and LOWER(b.brand_tier) = 'premium' THEN sales.gmv END) AS premium_gmv,
    SUM(CASE WHEN lower(b.branded_flag)='branded' and LOWER(b.brand_tier) = 'masstige' THEN sales.gmv END) AS mass_premium_gmv,
    SUM(CASE WHEN lower(b.branded_flag)='branded' and LOWER(b.brand_tier) = 'mass' THEN sales.gmv END) AS mass_gmv,
    SUM(CASE WHEN sales.gmv / sales.units <= 300 THEN sales.units END) AS 0_300_units,
    SUM(CASE WHEN sales.gmv / sales.units > 300 AND sales.gmv / sales.units <= 500 THEN sales.units END) AS 300_500_units,
    SUM(CASE WHEN sales.gmv / sales.units > 500 AND sales.gmv / sales.units <= 1000 THEN sales.units END) AS 500_1000_units,
    SUM(CASE WHEN sales.gmv / sales.units > 1000 THEN sales.units END) AS 1000_plus_units,
    SUM(CASE WHEN sales.gmv / sales.units <= 150 THEN sales.gmv END) AS 0_150_gmv,
    SUM(CASE WHEN sales.gmv / sales.units > 150 AND sales.gmv / sales.units <= 300 THEN sales.gmv END) AS 150_300_gmv,
    SUM(CASE WHEN sales.gmv / sales.units > 300 AND sales.gmv / sales.units <= 500 THEN sales.gmv END) AS 300_500_gmv,
    SUM(CASE WHEN sales.gmv / sales.units > 500 AND sales.gmv / sales.units <= 1000 THEN sales.gmv END) AS 500_1000_gmv,
    SUM(CASE WHEN sales.gmv / sales.units > 1000 THEN sales.gmv END) AS 1000_plus_gmv,
    SUM(CASE WHEN sales.gmv / sales.units <= 300 AND sales.is_alpha_seller = TRUE THEN sales.units END) AS alpha_0_300_units,
    SUM(CASE WHEN sales.gmv / sales.units > 300 AND sales.gmv / sales.units <= 500 AND sales.is_alpha_seller = TRUE THEN sales.units END) AS alpha_300_500_units,
    SUM(CASE WHEN sales.gmv / sales.units > 500 AND sales.gmv / sales.units <= 1000 AND sales.is_alpha_seller = TRUE THEN sales.units END) AS alpha_500_1000_units,
    SUM(CASE WHEN sales.gmv / sales.units > 1000 AND sales.is_alpha_seller = TRUE THEN sales.units END) AS alpha_1000_plus_units,
    SUM(CASE WHEN sales.gmv / sales.units <= 300 AND sales.is_alpha_seller = TRUE THEN sales.gmv END) AS alpha_0_300_gmv,
    SUM(CASE WHEN sales.gmv / sales.units > 300 AND sales.gmv / sales.units <= 500 AND sales.is_alpha_seller = TRUE THEN sales.gmv END) AS alpha_300_500_gmv,
    SUM(CASE WHEN sales.gmv / sales.units > 500 AND sales.gmv / sales.units <= 1000 AND sales.is_alpha_seller = TRUE THEN sales.gmv END) AS alpha_500_1000_gmv,
    SUM(CASE WHEN sales.gmv / sales.units > 1000 AND sales.is_alpha_seller = TRUE THEN sales.gmv END) AS alpha_1000_plus_gmv,
    SUM(CASE WHEN t.analytic_vertical IS NOT NULL THEN sales.gmv END) AS torsotail_gmv,
    SUM(CASE WHEN t.analytic_vertical IS NOT NULL THEN sales.units END) AS torsotail_units,
    COUNT(DISTINCT sales.account_id) AS customers,
    COUNT(DISTINCT CASE WHEN c.new_cust_flag = 1 THEN sales.account_id END) AS nn_customers,
    COUNT(DISTINCT CASE WHEN c.new_cust_flag <> 1 AND c.new_to_bu = 1 THEN sales.account_id END) AS on_customers,
    COUNT(DISTINCT CASE WHEN c.new_cust_flag is null AND c.new_to_bu is null THEN sales.account_id END) AS oo_customers,
    COUNT(DISTINCT sales.order_external_id) AS orders,
    COUNT(DISTINCT sales.shipment_id) AS shipments,
    SUM(sales.gmv) AS gmv,
    SUM(sales.units) AS units,
    AVG(sales.sla_in_days) AS sla,
    AVG(DATEDIFF(sales.delivered_date_time, sales.order_date_time)) AS o2d,
    SUM(CASE WHEN sales.is_alpha_seller = TRUE THEN sales.units END) AS alpha_units,
        
    SUM(CASE WHEN sales.service_profile = 'FBF' AND sales.sla_in_days <= 2 and lower(sales.source_facility_id) not like '%\\_alite\\_%' and lower(sales.source_facility_id) not like '%\\_al\\_%' THEN sales.units END) AS fbf_d2_units,

    sum(case when sales.service_profile = 'FBF' and lower(sales.source_facility_id) not like '%\\_alite\\_%' and lower(sales.source_facility_id) not like '%\\_al\\_%' then sales.units end) as fbf_units,

    SUM(CASE WHEN sales.service_profile = 'FBF' AND sales.is_alpha_seller = TRUE and lower(sales.source_facility_id) not like '%\\_alite\\_%' and lower(sales.source_facility_id) not like '%\\_al\\_%' THEN sales.units END) AS alpha_fbf_units,
        
    SUM(ret.return_item_quantity) AS rvp_units,
    -- SUM(ret.return_amount) AS rvp_gmv,
        CAST(SUM(ret.return_amount) AS INT) AS rvp_gmv,
    SUM(CASE WHEN sales.unit_is_rtod = 1 THEN sales.units END) AS rto_units,
    SUM(CASE WHEN sales.unit_is_rtod = 1 THEN sales.gmv END) AS rto_gmv,
    COUNT(DISTINCT CASE WHEN sales.order_payment_type = 'Prepaid' THEN sales.order_external_id END) as prepaid_orders,
    SUM(CASE WHEN UPPER(sales.lockin_context) = 'PREMIUM_ACTIVE' THEN sales.gmv END) AS premium_active_gmv,
    SUM(CASE WHEN UPPER(sales.lockin_context) = 'PREMIUM_ACTIVE' THEN sales.units END) AS premium_active_units,
    SUM(CASE WHEN UPPER(sales.lockin_context) = 'CLASSIC_ACTIVE' THEN sales.gmv END) AS classic_active_gmv,
    SUM(CASE WHEN UPPER(sales.lockin_context) = 'CLASSIC_ACTIVE' THEN sales.units END) AS classic_active_units,
    can.cancelled_units,
    can.gross_units,
        SUM(CASE WHEN sales.is_alpha_seller = FALSE THEN sales.gmv END) as mp_gmv,
        SUM(CASE WHEN sales.is_alpha_seller = FALSE THEN sales.units END) AS  mp_units,
        SUM(CASE WHEN sales.is_alpha_seller = TRUE THEN sales.gmv END) as alpha_gmv,
SUM(CASE WHEN sales.service_profile = 'NON_FBF' or sales.service_profile = 'FBF_LITE' THEN sales.units END) AS nfbf_units,
COUNT(DISTINCT case when sales.service_profile = 'FBF' then sales.order_external_id end) AS fbf_orders,
    COUNT(DISTINCT case when sales.service_profile = 'FBF' then sales.shipment_id end) AS fbf_shipments,
        COUNT(DISTINCT CASE WHEN sales.service_profile = 'NON_FBF' or sales.service_profile = 'FBF_LITE' THEN sales.order_external_id end) AS nfbf_orders,
    COUNT(DISTINCT CASE WHEN sales.service_profile = 'NON_FBF' or sales.service_profile = 'FBF_LITE' THEN sales.shipment_id end) AS nfbf_shipments,

sum(case when sales.service_profile = 'FBF' and lower(sales.source_facility_id) not like '%\\_alite\\_%' and lower(sales.source_facility_id) not like '%\\_al\\_%' and sales.is_alpha_seller = FALSE then sales.units end) as mp_fbf_units,
-- (SUM(rudata.ru_num) * 1.0) / NULLIF(SUM(rudata.ru_den), 0) AS ru_percentage,
SUM(CASE WHEN sales.sla_in_days <= 0 THEN 1 ELSE 0 END) AS d0_units,
SUM(CASE WHEN sales.sla_in_days <= 1 THEN 1 ELSE 0 END) AS d1_units,
SUM(CASE WHEN sales.sla_in_days <= 2 THEN 1 ELSE 0 END) AS d2_units,
CAST(SUM(rudata.ru_num) AS INT) AS ru_num,
CAST(SUM(rudata.ru_den) AS INT) AS ru_den,
(SUM(CASE WHEN sales.service_profile = 'FBF' THEN rudata.ru_num END) * 1.0) 
/ NULLIF(SUM(CASE WHEN sales.service_profile = 'FBF' THEN rudata.ru_den END), 0) AS fbf_ru_percentage

FROM bigfoot_external_neo.cp_bi_prod_sales__forward_unit_history_fact sales
LEFT JOIN  fdp_uploads.ds_fkint_cp_santa_hyperlocal_vertical_bu_mapping_2_0 AS hl 
    ON sales.analytic_vertical = hl.analytic_vertical 
    AND LOWER(hl.bu_final) = 'bgm' 

LEFT JOIN 
        (
        SELECT 
                LOWER(analytic_super_category) as analytic_super_category,
                LOWER(brand) as brand,
                MIN(branded_flag) as branded_flag,
                MIN(brand_type) as brand_type,
                MIN(brand_tier) as brand_tier,
                MIN(is_priority_brand) AS is_priority_brand

        FROM  fdp_uploads.ds_fkint_analytics_cdo_bgm_sc_brand_mapping_analytics_1_0

        GROUP BY
                LOWER(analytic_super_category),
                LOWER(brand)
        ) b
    ON LOWER(sales.analytic_super_category) = LOWER(b.analytic_super_category)
    AND LOWER(sales.brand) = LOWER(b.brand)

LEFT JOIN 
        (
        SELECT 
                LOWER(brand) as brand,
                MIN(brand_type) as brand_type

        FROM  fdp_uploads.ds_fkint_analytics_cdo_bgm_sc_brand_mapping_analytics_1_0
        GROUP BY
                LOWER(brand)
        ) b2
    ON LOWER(sales.brand) = LOWER(b2.brand)

LEFT JOIN bigfoot_common.date_dim_cal date_dim 
    ON sales.order_date_key = date_dim.date_dim_key

LEFT JOIN 
    (
    SELECT 
        forward_unit_id,
        SUM(return_item_quantity) as return_item_quantity,
        SUM(return_amount) as return_amount
    FROM bigfoot_external_neo.scp_rrr__return_l2_id_level_hive_ss_fact
    WHERE UPPER(return_type) = 'CUSTOMER_RETURN' 
            AND (
             (order_item_approve_date_key BETWEEN 20240701 AND 20240803)
            OR (order_item_approve_date_key BETWEEN 20250701 AND 20250803)
            )
            AND order_item_approve_date_key not in (20240229)
            AND UPPER(return_item_status) IN ('INIT', 'COMPLETED', 'APPROVED')
    GROUP BY
            forward_unit_id
    ) ret
    ON ret.forward_unit_id = sales.id

LEFT JOIN 
    (
    SELECT 
        date_dim.yearmo AS yearmo,
        SUM(CASE WHEN LOWER(sales.status) = 'cancelled' THEN units END) AS cancelled_units,
        SUM(units) AS gross_units

    FROM bigfoot_external_neo.cp_bi_prod_sales__forward_unit_history_fact sales
          LEFT JOIN  fdp_uploads.ds_fkint_cp_santa_hyperlocal_vertical_bu_mapping_2_0 AS hl 
    ON sales.analytic_vertical = hl.analytic_vertical 
    AND LOWER(hl.bu_final) = 'bgm'  
    LEFT JOIN bigfoot_common.date_dim_cal date_dim 
        ON sales.order_date_key = date_dim.date_dim_key
    WHERE sales.type IN ('physical')
            AND sales.replacement_for_unit IS NULL
            AND sales.exchange_for_unit IS NULL
            AND sales.is_freebie = FALSE
            AND (sales.marketplace_id IN ('FLIPKART') OR (sales.marketplace_id = 'HYPERLOCAL' AND  hl.analytic_vertical IS NOT NULL))
            AND sales.analytic_business_unit IN ('BGM')
            AND (
           (sales.order_date_key BETWEEN 20240701 AND 20240803)
            OR (sales.order_date_key BETWEEN 20250701 AND 20250803)
            )
            AND sales.order_date_key not in (20240229)
            AND sales.is_shopsy_order = FALSE
    GROUP BY date_dim.yearmo
    ) can 
    ON can.yearmo = date_dim.yearmo

LEFT JOIN fdp_uploads.ds_fkint_analytics_cdo_torso_tail_verticals_bgm_1_0 t 
    ON t.analytic_vertical = sales.analytic_vertical

LEFT JOIN 
        (
        SELECT 
                order_item_id,
                MAX(new_cust_flag) as new_cust_flag,
                MAX(new_to_bu) as new_to_bu

        FROM bigfoot_external_neo.analytics_cdo__customer_insight_hive_fact
         
          WHERE  (
      
         (approve_date_key BETWEEN 20240701 AND 20240803)
          OR (approve_date_key BETWEEN 20250701 AND 20250803)
          )
          AND approve_date_key not in (20240229)
          AND (new_cust_flag = 1 or new_to_bu = 1)

        GROUP BY 
                order_item_id
        ) c
    ON c.order_item_id = sales.order_item_id

LEFT JOIN
  (
    SELECT
        ff.fulfill_item_unit_id,
        COUNT(DISTINCT CASE WHEN fulfill_item_unit_granular_shipment_movement_type IN ('L1', 'L2', 'Z1', 'Z2') THEN fulfill_item_unit_id END) AS ru_num,
        COUNT(DISTINCT CASE WHEN fulfill_item_unit_granular_shipment_movement_type IN ('L1', 'L2', 'Z1', 'Z2','N1','N2') THEN fulfill_item_unit_id END) AS ru_den

    FROM bigfoot_external_neo.scp_fulfillment__fulfillment_unit_hive_365_fact ff

    LEFT JOIN bigfoot_external_neo.sp_product__product_categorization_hive_dim cat
        ON  ff.fulfill_item_product_id = cat.product_id
      
    WHERE
       (
        (ff.fulfill_item_unit_order_date_key BETWEEN 20240701 AND 20240803)
       OR (ff.fulfill_item_unit_order_date_key BETWEEN 20250701 AND 20250803)
       )
       AND ff.fulfill_item_unit_order_date_key not in (20240229)
        AND cat.analytic_business_unit IN ('BGM')
     
    GROUP BY
        ff.fulfill_item_unit_id
    ) rudata
    ON sales.fulfill_item_unit_id = rudata.fulfill_item_unit_id

WHERE LOWER(sales.status) IN ('in_progress', 'undelivered', 'completed', 'delivered', 'approved', 'shipped', 'ready_to_ship', 'returned', 'return_requested', 'activated')
        AND sales.type IN ('physical')
        AND sales.replacement_for_unit IS NULL
        AND sales.exchange_for_unit IS NULL
        AND sales.is_freebie = FALSE
        AND (sales.marketplace_id IN ('FLIPKART') OR (sales.marketplace_id = 'HYPERLOCAL' AND  hl.analytic_vertical IS NOT NULL))
        AND sales.analytic_business_unit IN ('BGM')
        AND 
        (
         (sales.order_date_key BETWEEN 20240701 AND 20240803)
         OR (sales.order_date_key BETWEEN 20250701 AND 20250803)
         )
        AND sales.order_date_key not in (20240229)
        AND sales.is_shopsy_order = FALSE

GROUP BY
    date_dim.yearmo,
    can.cancelled_units,
    can.gross_units) sales_query


LEFT JOIN
  (
    select 
        substring(cast(sales.order_date_key as string),0,6) as YearMo,
        sum(sales.units) as fk_units, 
        count(distinct(sales.order_external_id)) as fk_orders, 
        count(distinct(sales.shipment_id)) as fk_shipments, 
        sum(case when sales.service_profile = 'FBF' then sales.units end) AS fk_fbf_units,
        COUNT(DISTINCT case when sales.service_profile = 'FBF' then sales.order_external_id end) AS fk_fbf_orders,
        COUNT(DISTINCT case when sales.service_profile = 'FBF' then sales.shipment_id end) AS fk_fbf_shipments,
        sum(CASE WHEN sales.service_profile = 'NON_FBF' or sales.service_profile = 'FBF_LITE' then sales.units end) AS fk_nfbf_units,
        COUNT(DISTINCT(CASE WHEN sales.service_profile = 'NON_FBF' or sales.service_profile = 'FBF_LITE' then sales.order_external_id end)) AS fk_nfbf_orders,
        COUNT(DISTINCT(CASE WHEN sales.service_profile = 'NON_FBF' or sales.service_profile = 'FBF_LITE' then sales.shipment_id end)) AS fk_nfbf_shipments

        FROM bigfoot_external_neo.cp_bi_prod_sales__forward_unit_history_fact sales

        WHERE LOWER(sales.status) IN ('in_progress', 'undelivered', 'completed', 'delivered', 'approved', 'shipped', 'ready_to_ship', 'returned', 'return_requested', 'activated')
        AND sales.type = 'physical'
        AND sales.replacement_for_unit IS NULL
        AND sales.exchange_for_unit IS NULL
        AND sales.is_freebie = FALSE
        AND sales.marketplace_id = 'FLIPKART'
        AND sales.analytic_business_unit = 'BGM'
        AND (
     
        (sales.order_date_key BETWEEN 20240701 AND 20240803)
        OR
        (sales.order_date_key BETWEEN 20250701 AND 20250803)
        )
        and sales.order_date_key not in (20240229)
        AND sales.is_shopsy_order = FALSE

        group by 
        substring(cast(sales.order_date_key as string),0,6)
    ) fk_metrics 
    ON fk_metrics.YearMo = sales_query.YearMo )