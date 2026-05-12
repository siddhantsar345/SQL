select
sales.unit_creation_date_key as order_date_key,

EXTRACT(HOUR FROM PARSE_TIMESTAMP('%m/%d/%y %H:%M', unit_creation_timestamp)) A AS hour_of_day
sales.business_unit as analytic_business_unit,
sales.super_category as analytic_super_category,
case when alpha_flag = 'Alpha' then 'Diamond' else 'Rest of MP' end as is_alpha_seller,
sum(sales.amount) as gmv,
sum(sales.units) as units

from bigfoot_external_neo.cp_bi_prod_sales__forward_unit_live_hbase_snapshot_fact sales

WHERE lower(sales.unit_status) in ('in_progress','undelivered','completed','delivered','approved','shipped','ready_to_ship','returned', 'return_requested','activated')
and sales.unit_type = 'physical'
and sales.freebie_flag=false
AND sales.marketplace_id IN ('FLIPKART')
and sales.unit_creation_date_key = 20250814
and lower(sales.business_unit) IN ('bgm','home')
and Upper(sales.is_shopsy_order)='FALSE'

group by

sales.unit_creation_date_key as order_date_key,
sales.business_unit as analytic_business_unit,
sales.super_category as analytic_super_category,
case when alpha_flag = 'Alpha' then 'Diamond' else 'Rest of MP' end as is_alpha_sel