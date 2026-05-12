select
sales1.order_date_key,
sum(sales.primary_ppvs) as ppvs,
sum(sales1.gmv) as gmv

FROM bigfoot_external_neo.cp_santa__listing_performance_at_day_level_with_sales_90d_fact sales

left join bigfoot_external_neo.cp_bi_prod_sales__forward_unit_history_fact sales1
on sales.date_key=sales1.order_date_key

    WHERE sales1.marketplace_id='FLIPKART'
    and sales1.order_date_key between 20251101 and 20251103
    and lower(sales1.analytic_business_unit) in ('home')

group by
sales1.order_date_key