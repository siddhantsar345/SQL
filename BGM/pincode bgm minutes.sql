select distinct sales.pincode 
    from bigfoot_external_neo.cp_bi_prod_sales__forward_unit_history_fact sales
    where 
        LOWER(sales.status) IN ('in_progress', 'undelivered', 'completed', 'delivered', 'approved', 'shipped', 'ready_to_ship', 'returned', 'return_requested', 'activated')
        AND sales.type = 'physical'
        AND sales.replacement_for_unit IS NULL
        AND sales.exchange_for_unit IS NULL
        AND sales.is_freebie = FALSE
        AND lower(sales.marketplace_id) IN ('hyperlocal')
        AND (sales.order_date_key BETWEEN 20251001 AND 20260121)
        AND sales.analytic_business_unit IN ('BGM')
        AND sales.is_shopsy_order = FALSE