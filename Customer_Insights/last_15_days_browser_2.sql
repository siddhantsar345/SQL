SELECT
    COUNT(DISTINCT t1.accountid) AS unique_accounts
FROM
    bigfoot_external_neo.cp_cdm_consumer__incr_agg_consumer_session_id_listing_fact AS t1
INNER JOIN
    bigfoot_external_neo.sp_product__product_categorization_hive_dim AS t2
ON
    t1.productid = t2.product_id
WHERE
    t1.primarylistingppvs > 0
    AND t1.datekey BETWEEN 20250827 AND 20250910
    AND lower(t2.analytic_vertical) IN ('walldecoration', 'artificialflower', 'artificialplant', 'painting')
    AND t1.accountid NOT IN (
        SELECT sales.account_id
        FROM
            bigfoot_external_neo.cp_bi_prod_sales__forward_unit_history_fact sales
        LEFT JOIN
            fdp_uploads.ds_fkint_cp_santa_hyperlocal_vertical_bu_mapping_2_0 AS hl
        ON
            sales.analytic_vertical = hl.analytic_vertical
        WHERE
            LOWER(sales.status) IN ('in_progress', 'undelivered', 'completed', 'delivered', 'approved', 'shipped', 'ready_to_ship', 'returned', 'return_requested', 'activated')
            AND sales.type = 'physical'
            AND sales.replacement_for_unit IS NULL
            AND sales.exchange_for_unit IS NULL
            AND sales.is_freebie = FALSE
            AND (sales.marketplace_id IN ('FLIPKART') OR (sales.marketplace_id = 'HYPERLOCAL' AND hl.analytic_vertical IS NOT NULL))
            AND sales.order_date_key BETWEEN 20250310 AND 20250910
            AND sales.is_shopsy_order = FALSE
            AND lower(sales.analytic_vertical) IN ('walldecoration', 'artificialflower', 'artificialplant', 'painting')
    )