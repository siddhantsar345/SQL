SELECT 
   YEAR(DATE_ADD(base.month,1)) as year,
   MONTH(DATE_ADD(base.month,1)) as month,
   COUNT(DISTINCT base.account_id) as base,
   COUNT(DISTINCT ret.account_id) as fk_repeat,
   COUNT(DISTINCT CASE WHEN lower(ret.analytic_business_unit) = 'home' then ret.account_id end) as home_repeat
FROM
    (
    SELECT
        sales.account_id,
        to_date(last_day(sales.order_date_time)) as month
    FROM bigfoot_external_neo.cp_bi_prod_sales__forward_unit_history_fact sales
        
    left join bigfoot_external_neo.scp_oms__date_dim_fact d
        on sales.order_date_key = d.date_dim_key
    WHERE lower(status) in ('in_progress','undelivered','completed','delivered','approved','shipped','ready_to_ship','returned', 'return_requested','activated')
        AND type !='service'
        AND replacement_for_unit IS NULL
        AND exchange_for_unit IS NULL
        AND is_freebie =FALSE
        AND marketplace_id IN ('FLIPKART')
        AND lower(analytic_business_unit) in ('home')
        AND is_shopsy_order =FALSE
        AND order_date_key BETWEEN 20241201 and 20250727
    GROUP BY 
        sales.account_id,
        to_date(last_day(sales.order_date_time))
    ) base
LEFT JOIN
    (
    SELECT 
        sales.account_id,
        to_date(last_day(order_date_time)) as month,
        sales.analytic_business_unit
    FROM bigfoot_external_neo.cp_bi_prod_sales__forward_unit_history_fact sales
        
    left join bigfoot_external_neo.scp_oms__date_dim_fact d
        on sales.order_date_key = d.date_dim_key
    WHERE lower(status) in ('in_progress','undelivered','completed','delivered','approved','shipped','ready_to_ship','returned', 'return_requested','activated')
        AND type !='service'
        AND replacement_for_unit IS NULL
        AND exchange_for_unit IS NULL
        AND is_freebie =FALSE
        AND marketplace_id IN ('FLIPKART')
        AND is_shopsy_order =FALSE
        AND order_date_key BETWEEN 20241201 and 20250727
    GROUP BY  
        sales.account_id,
        to_date(last_day(order_date_time)),
        sales.analytic_business_unit
    ) ret
    on base.account_id = ret.account_id
    and months_between(ret.month,base.month) = 1
GROUP BY 
   YEAR(DATE_ADD(base.month,1)),
   MONTH(DATE_ADD(base.month,1))
;