SELECT
    AVG(T.count_of)
FROM
    (
        SELECT
            sales.account_id,
            COUNT(DISTINCT sales.analytic_vertical) AS count_of
        FROM
            bigfoot_external_neo.cp_bi_prod_sales__forward_unit_history_fact sales
        LEFT JOIN
            fdp_uploads.ds_fkint_cp_santa_hyperlocal_vertical_bu_mapping_2_0 AS hl
            ON sales.analytic_vertical = hl.analytic_vertical
            AND LOWER(hl.bu_final) in ('bgm')
        WHERE
            LOWER(sales.status) IN ('in_progress', 'undelivered', 'completed', 'delivered', 'approved', 'shipped', 'ready_to_ship', 'returned', 'return_requested', 'activated')
            AND sales.type = 'physical'
            AND sales.replacement_for_unit IS NULL
            AND sales.exchange_for_unit IS NULL
            AND sales.is_freebie = FALSE
            AND (sales.marketplace_id IN ('FLIPKART') OR (sales.marketplace_id = 'HYPERLOCAL' AND hl.analytic_vertical IS NOT NULL))
            AND (sales.order_date_key BETWEEN 20250101 AND 20250831)
            AND sales.analytic_business_unit IN ('BGM')
            AND LOWER(sales.analytic_super_category) IN ('autoaccessorys')
            AND sales.is_shopsy_order = FALSE
        GROUP BY
            sales.account_id
    ) AS T;