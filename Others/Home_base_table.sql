create table adhoc_ttl_90days.household_on_base_till_16th_sep2025_base as 
with fk_tpc as(
    select distinct
        account_id
    from(
        select 
            sales.account_id,
            COUNT(distinct sales.order_external_id) as orders
        FROM bigfoot_external_neo.cp_bi_prod_sales__forward_unit_history_fact sales

        WHERE LOWER(sales.status) IN ('in_progress', 'undelivered', 'completed', 'delivered', 'approved', 'shipped', 'ready_to_ship', 'returned', 'return_requested', 'activated')
            AND sales.type != 'service'
            AND sales.replacement_for_unit IS NULL
            AND sales.exchange_for_unit IS NULL
            AND sales.is_freebie = FALSE
            AND sales.is_shopsy_order = FALSE
            AND sales.marketplace_id IN ('FLIPKART')
            AND sales.order_date_key BETWEEN 20240914 and 20250915 
            
        group by sales.account_id
    )a
    where orders >= 4
),
exclude_sc AS (
    SELECT DISTINCT sales.account_id
    FROM bigfoot_external_neo.cp_bi_prod_sales__forward_unit_history_fact sales
    LEFT JOIN bigfoot_external_neo.sp_product__product_categorization_hive_dim pc 
        ON sales.product_id = pc.product_id 
    LEFT JOIN fdp_uploads.ds_fkint_cp_santa_hyperlocal_vertical_bu_mapping_2_0 AS hl 
        ON sales.analytic_vertical = hl.analytic_vertical 
    WHERE LOWER(sales.status) IN ('in_progress', 'undelivered', 'completed', 'delivered', 'approved', 'shipped', 'ready_to_ship', 'returned', 'return_requested', 'activated')
        AND sales.type = 'physical'
        AND sales.replacement_for_unit IS NULL
        AND sales.exchange_for_unit IS NULL
        AND sales.is_freebie = FALSE
        AND (sales.marketplace_id IN ('FLIPKART') OR (sales.marketplace_id = 'HYPERLOCAL' AND hl.analytic_vertical IS NOT NULL))
        AND sales.order_date_key BETWEEN 20240914 AND 20250915
        AND sales.is_shopsy_order = FALSE
        AND lower(pc.analytic_super_category) IN ('household')
)
SELECT DISTINCT sales.account_id
FROM bigfoot_external_neo.cp_bi_prod_sales__forward_unit_history_fact sales
LEFT JOIN bigfoot_external_neo.sp_product__product_categorization_hive_dim pc 
    ON sales.product_id = pc.product_id 
LEFT JOIN fdp_uploads.ds_fkint_cp_santa_hyperlocal_vertical_bu_mapping_2_0 AS hl 
    ON sales.analytic_vertical = hl.analytic_vertical 
INNER JOIN fk_tpc AS fk 
    ON fk.account_id = sales.account_id
LEFT JOIN exclude_sc AS sc 
    ON sc.account_id = sales.account_id
WHERE LOWER(sales.status) IN ('in_progress', 'undelivered', 'completed', 'delivered', 'approved', 'shipped', 'ready_to_ship', 'returned', 'return_requested', 'activated')
    AND sales.type = 'physical'
    AND sales.replacement_for_unit IS NULL
    AND sales.exchange_for_unit IS NULL
    AND sales.is_freebie = FALSE
    AND (sales.marketplace_id IN ('FLIPKART') OR (sales.marketplace_id = 'HYPERLOCAL' AND hl.analytic_vertical IS NOT NULL))
    AND sales.order_date_key BETWEEN 20250315 AND 20250915
    AND sales.is_shopsy_order = FALSE
    AND lower(sales.analytic_vertical) IN ('fashionmangalsutratanmaniya', 'eyeshadow', 'womenmessengerbag', 'fashionjewelleryset', 'brushapplicator', 'blush', 'babypillow', 'nappy', 'makeupkit', 'fashionnoseringstud', 'fashionmaangtikka', 'collapsiblewardrobe', 'kamarband')
    AND sc.account_id IS NULL