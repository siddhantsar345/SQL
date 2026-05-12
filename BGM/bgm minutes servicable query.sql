SELECT
    sales.pincode AS Pincode,
    CASE 
        WHEN hyper.pincode IS NOT NULL THEN 'Serviceable'
        ELSE 'Non-Serviceable'
    END AS serviceability_status
FROM bigfoot_external_neo.cp_bi_prod_sales__forward_unit_history_fact sales
LEFT JOIN fdp_uploads.ds_fkint_analytics_cdo_pincodes_bgm_minutes_2_0 AS hyper
    ON CAST(sales.pincode AS STRING) = CAST(hyper.pincode AS STRING)
WHERE 
        sales.order_date_key BETWEEN 20251001 AND 20260121
        AND LOWER(sales.status) IN ('in_progress', 'undelivered', 'completed', 'delivered', 'approved', 'shipped', 'ready_to_ship', 'returned', 'return_requested', 'activated')
        AND sales.type = 'physical'
        AND lower(sales.marketplace_id) = 'hyperlocal'
        AND sales.is_shopsy_order = FALSE
        AND sales.replacement_for_unit IS NULL
        AND sales.exchange_for_unit IS NULL
        AND sales.is_freebie = FALSE