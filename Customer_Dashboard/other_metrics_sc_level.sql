select 
substring(cast(sales.order_date_key as string),1,6),
sales.analytic_business_unit,
sales.analytic_super_category,
sales.user_lockin_state,
count(distinct sales.order_external_id) as orders,
count(distinct sales.account_id) as customers,
sum(sales.gmv) as gmv,
sum(sales.units) as units

FROM bigfoot_external_neo.cp_bi_prod_sales__forward_unit_history_fact sales

WHERE
lower(sales.status) in ('in_progress','undelivered','completed','delivered','approved','shipped','ready_to_ship','returned', 'return_requested','activated')
AND sales.type !='service'
AND sales.category_id !=21726
AND sales.category_id !=21651
AND sales.replacement_for_unit IS NULL
AND sales.exchange_for_unit IS NULL
AND sales.is_freebie =FALSE
AND sales.marketplace_id IN ('FLIPKART')
AND sales.analytic_business_unit IN ('BGM','Home')
AND sales.order_date_key between 20251101 and 20251130
AND sales.is_shopsy_order =FALSE

group by
substring(cast(sales.order_date_key as string),1,6),
sales.analytic_business_unit,
sales.analytic_super_category,
sales.user_lockin_state