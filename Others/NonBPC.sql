select

sum(sales.units) as units,
sum(sales.gmv) as gmv,
count(distinct sales.order_external_id) as orders,
count(distinct sales.account_id) as total_customers,
count(distinct case when cust.new_to_bu =1 then sales.account_id end) as nn_on_customers

from bigfoot_external_neo.cp_bi_prod_sales__forward_unit_history_fact sales


LEFT JOIN fdp_uploads.ds_fkint_cp_santa_hyperlocal_vertical_bu_mapping_2_0 AS hl
ON sales.analytic_vertical = hl.analytic_vertical
AND LOWER(hl.bu_final) = 'bgm'
and sales.marketplace_id='HYPERLOCAL'

Left join

(select order_item_id,
max(new_cust_flag) as new_cust_flag,
max(new_to_bu) as new_to_bu,
max(new_to_sc) as new_to_sc
from bigfoot_external_neo.analytics_cdo__customer_insight_hive_fact
group by order_item_id ) as cust

on sales.order_item_id = cust.order_item_id

WHERE
LOWER(sales.status) IN ('in_progress', 'undelivered', 'completed', 'delivered', 'approved', 'shipped', 'ready_to_ship', 'returned', 'return_requested', 'activated')
AND sales.type = 'physical'
AND sales.replacement_for_unit IS NULL
AND sales.exchange_for_unit IS NULL
AND sales.is_freebie = FALSE
AND (sales.marketplace_id IN ('FLIPKART') OR (sales.marketplace_id = 'HYPERLOCAL' AND hl.analytic_vertical IS NOT NULL))
AND (sales.order_date_key BETWEEN 20250101 AND 20250831)
AND sales.analytic_business_unit IN ('BGM')
AND lower(sales.analytic_super_category) in ('toysandss','healthcare','booksmedia','sportfitness','babycare','autoaccessorys','householdsupplies','pets','industrial&scientific','digitalsubscription','foodandnutrition')
AND sales.is_shopsy_order = FALSE