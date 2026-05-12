    WITH May_Aug_Buyers AS (
        SELECT DISTINCT
            sales.account_id
        FROM
            bigfoot_external_neo.cp_bi_prod_sales__forward_unit_history_fact sales
        LEFT JOIN
            fdp_uploads.ds_fkint_cp_santa_hyperlocal_vertical_bu_mapping_2_0 AS hl
            ON sales.analytic_vertical = hl.analytic_vertical
            AND LOWER(hl.bu_final) IN ('bgm')
        WHERE
            LOWER(sales.status) IN ('in_progress', 'undelivered', 'completed', 'delivered', 'approved', 'shipped', 'ready_to_ship', 'returned', 'return_requested', 'activated')
            AND sales.type = 'physical'
            AND sales.replacement_for_unit IS NULL
            AND sales.exchange_for_unit IS NULL
            AND sales.is_freebie = FALSE
            AND (sales.marketplace_id IN ('FLIPKART') OR (sales.marketplace_id = 'HYPERLOCAL' AND hl.analytic_vertical IS NOT NULL))
            AND sales.analytic_business_unit IN ('BGM')
            AND sales.is_shopsy_order = FALSE
            AND sales.order_date_key BETWEEN 20250501 AND 20250831
            AND sales.product_id IN (
                'DPRG6GR2TQARYQEW', 'DPRGY9EMWNNMCQ9Q', 'DPRG6GR2ZJNRRVHU', 'DPRH3FNQXZ9BNDBU',
                'DPRGJMZAD5PG9AT6', 'DPRGDQ95VXTNGSMN', 'DPRGJMZ7GM8XFYDK', 'DPRH3FNQ9RGCRNTG',
                'DPRGTDYWGMPPF9K2', 'DPRG6GR2Z25GNADH', 'DPRGY9EMZ3PUKFHH', 'DPRGT78XJTDYNPQH',
                'DPRGD6TBRMUU8UZJ', 'DPRHBJ6KJYVX7DPU', 'DPRG6GR2FTMQGNZY', 'DPRGY9EMWHGYFJJF',
                'DPRHBJ6KHKEU9K3F', 'DPRGJMZAYZSJJWNF', 'DPRGJMZBPHVT6JDN', 'DPRGY9EMYTYY4ZYG',
                'DPRGJMZ7ZJHX4QXM', 'DPRHBJ6K2FVERZJR', 'DPRH3FNQUJZBYGZT', 'DPRHBJ6KWDQEEYGU'
            )
    ),
    Sept_Oct_Buyers AS (
        SELECT DISTINCT
            sales.account_id
        FROM
            bigfoot_external_neo.cp_bi_prod_sales__forward_unit_history_fact sales
        LEFT JOIN
            fdp_uploads.ds_fkint_cp_santa_hyperlocal_vertical_bu_mapping_2_0 AS hl
            ON sales.analytic_vertical = hl.analytic_vertical
            AND LOWER(hl.bu_final) IN ('bgm')
        WHERE
            LOWER(sales.status) IN ('in_progress', 'undelivered', 'completed', 'delivered', 'approved', 'shipped', 'ready_to_ship', 'returned', 'return_requested', 'activated')
            AND sales.type = 'physical'
            AND sales.replacement_for_unit IS NULL
            AND sales.exchange_for_unit IS NULL
            AND sales.is_freebie = FALSE
            AND (sales.marketplace_id IN ('FLIPKART') OR (sales.marketplace_id = 'HYPERLOCAL' AND hl.analytic_vertical IS NOT NULL))
            AND sales.analytic_business_unit IN ('BGM')
            AND sales.is_shopsy_order = FALSE
            AND sales.order_date_key BETWEEN 20250901 AND 20251031
            AND sales.product_id IN (
                'DPRG6GR2TQARYQEW', 'DPRGY9EMWNNMCQ9Q', 'DPRG6GR2ZJNRRVHU', 'DPRH3FNQXZ9BNDBU',
                'DPRGJMZAD5PG9AT6', 'DPRGDQ95VXTNGSMN', 'DPRGJMZ7GM8XFYDK', 'DPRH3FNQ9RGCRNTG',
                'DPRGTDYWGMPPF9K2', 'DPRG6GR2Z25GNADH', 'DPRGY9EMZ3PUKFHH', 'DPRGT78XJTDYNPQH',
                'DPRGD6TBRMUU8UZJ', 'DPRHBJ6KJYVX7DPU', 'DPRG6GR2FTMQGNZY', 'DPRGY9EMWHGYFJJF',
                'DPRHBJ6KHKEU9K3F', 'DPRGJMZAYZSJJWNF', 'DPRGJMZBPHVT6JDN', 'DPRGY9EMYTYY4ZYG',
                'DPRGJMZ7ZJHX4QXM', 'DPRHBJ6K2FVERZJR', 'DPRH3FNQUJZBYGZT', 'DPRHBJ6KWDQEEYGU'
            )
    )
    SELECT
        t1.account_id
    FROM
        May_Aug_Buyers t1
    LEFT JOIN
        Sept_Oct_Buyers t2
        ON t1.account_id = t2.account_id
    WHERE
        t2.account_id IS NULL;