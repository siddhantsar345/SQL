SELECT
*
FROM
(
SELECT
analytic_business_unit,
analytic_super_category,
is_alpha_seller,
order_date_key,
SUM(input_bau_weighted_asp) AS input_bau_weighted_asp,
SUM(input_fes_weighted_asp) AS input_fes_weighted_asp,
SUM(output_bau_weighted_asp) AS output_bau_weighted_asp,
SUM(output_fes_weighted_asp) AS output_fes_weighted_asp
FROM
(
SELECT
bau.analytic_super_category AS analytic_super_category,
bau.analytic_business_unit,
bau.product_id AS product_id,
bau.listing_id AS listing_id,
bau.is_alpha_seller AS is_alpha_seller,
fes.order_date_key AS order_date_key,
(bau.gmv / bau.units) * bau.units AS input_bau_weighted_asp,
(fes.gmv / fes.units) * bau.units AS input_fes_weighted_asp,
(bau.gmv / bau.units) * fes.units AS output_bau_weighted_asp,
(fes.gmv / fes.units) * fes.units AS output_fes_weighted_asp
FROM
(
SELECT
sales.analytic_super_category,
analytic_business_unit,
sales.product_id,
sales.listing_id,
CASE 
WHEN UPPER(sales.is_alpha_seller) = 'TRUE' THEN 'Diamond' 
ELSE 'Rest of MP' 
END AS is_alpha_seller,
SUM(units)/61 AS units,
SUM(gmv)/61 AS gmv,
SUM(listing_price) AS lp
FROM
bigfoot_external_neo.cp_bi_prod_sales__forward_unit_history_fact sales
WHERE
LOWER(sales.status) IN (
'in_progress',
'undelivered',
'completed',
'delivered',
'approved',
'shipped',
'ready_to_ship',
'returned',
'return_requested',
'activated'
)
AND sales.type != 'service'
AND sales.replacement_for_unit IS NULL
AND sales.exchange_for_unit IS NULL
AND sales.is_freebie = FALSE
AND sales.marketplace_id IN ('FLIPKART')
AND sales.is_shopsy_order = FALSE
AND sales.analytic_business_unit IN ('BGM', 'Home', 'Furniture')
AND order_date_key BETWEEN 20250701 AND 20250831
GROUP BY
sales.analytic_super_category,
analytic_business_unit,
sales.product_id,
sales.listing_id,
CASE 
WHEN UPPER(sales.is_alpha_seller) = 'TRUE' THEN 'Diamond' 
ELSE 'Rest of MP' 
END
) bau
INNER JOIN (
SELECT
sales.listing_id,
order_date_key,
SUM(units) AS units,
SUM(net_amount) AS gmv,
SUM(listing_price) AS lp
FROM
bigfoot_external_neo.cp_bi_prod_sales__forward_unit_live_hbase_snapshot_fact sales
WHERE
LOWER(sales.unit_status) IN (
'in_progress',
'undelivered',
'completed',
'delivered',
'approved',
'shipped',
'ready_to_ship',
'returned',
'return_requested',
'activated'
)
AND sales.unit_type != 'service'
AND sales.marketplace_id IN ('FLIPKART')
AND LOWER(sales.is_shopsy_order) = 'false'
AND sales.business_unit IN ('BGM', 'Home', 'Furniture')
AND order_date_key BETWEEN 20250801 AND 20250810
GROUP BY
sales.listing_id,
order_date_key
) fes ON bau.listing_id = fes.listing_id
) sub
GROUP BY
analytic_business_unit,
analytic_super_category,
is_alpha_seller,
order_date_key
) AS final_output;