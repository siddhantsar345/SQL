select
SUBSTR(CAST(date_key AS STRING), 1, 6) AS month_key,
sales.analytic_business_unit,
sales.analytic_super_category,
CASE 
    WHEN sales.net_gmv / sales.net_units > 0 AND sales.net_gmv / sales.net_units <= 150 then "0 - 150"
    WHEN sales.net_gmv / sales.net_units > 151 AND sales.net_gmv / sales.net_units <= 300 then "151 - 300"
    WHEN sales.net_gmv / sales.net_units > 301 AND sales.net_gmv / sales.net_units <= 500 then "301 - 500"
    WHEN sales.net_gmv / sales.net_units > 501 AND sales.net_gmv / sales.net_units <= 1000 then "501 - 1000"
 End as price_bucket,
 case when sales.is_first_party_seller = TRUE then 'Diamond' else 'Rest of MP' end as is_alpha_seller, 
 sum(primary_ppvs) as ppvs

FROM bigfoot_external_neo.cp_santa__listing_performance_at_day_level_with_sales_90d_fact sales
    WHERE sales.marketplace_id='FLIPKART' 
    and sales.date_key between 20250301 and 20251231
    and lower(sales.analytic_business_unit) in ('home')
    and lower(sales.analytic_super_category) in ('household')


group by
SUBSTR(CAST(date_key AS STRING), 1, 6),
sales.analytic_business_unit,
sales.analytic_super_category,
CASE 
    WHEN sales.net_gmv / sales.net_units > 0 AND sales.net_gmv / sales.net_units <= 150 then "0 - 150"
    WHEN sales.net_gmv / sales.net_units > 151 AND sales.net_gmv / sales.net_units <= 300 then "151 - 300"
    WHEN sales.net_gmv / sales.net_units > 301 AND sales.net_gmv / sales.net_units <= 500 then "301 - 500"
    WHEN sales.net_gmv / sales.net_units > 501 AND sales.net_gmv / sales.net_units <= 1000 then "501 - 1000"
End,
case when sales.is_first_party_seller = TRUE then 'Diamond' else 'Rest of MP' end