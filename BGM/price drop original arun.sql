with vertical_gmv_table as 
(select
sales.analytic_super_category,
sales.analytic_vertical,
sum(gmv) as vertical_gmv
    
FROM bigfoot_external_neo.cp_bi_prod_sales__forward_unit_history_fact sales

WHERE lower(sales.status) in ('in_progress','undelivered','completed','delivered','approved','shipped','ready_to_ship','returned', 'return_requested','activated')
    AND sales.type !='service'
    AND sales.replacement_for_unit IS NULL
    AND sales.exchange_for_unit IS NULL
    AND sales.is_freebie =FALSE
    AND sales.marketplace_id IN ('FLIPKART')
    AND sales.is_shopsy_order =FALSE
    AND sales.analytic_business_unit in ('BGM')
    AND order_date_key between 20250701 and 20250831
    
group by 
sales.analytic_super_category,
sales.analytic_vertical),

cum_sum_vertical as
(select
analytic_super_category,
analytic_vertical,
sum(vertical_gmv) over (partition by analytic_super_category order by vertical_gmv desc ROWS UNBOUNDED PRECEDING) as vert_gmv_cumilative,
sum(vertical_gmv) over (partition by analytic_super_category) as total_sc_gmv,
sum(vertical_gmv) over (partition by analytic_super_category order by vertical_gmv desc)/sum(vertical_gmv) over (partition by analytic_super_category) as percentage_value

from vertical_gmv_table
),

top_80_percent_vertical_bgm as
(
   select analytic_super_category, analytic_vertical
   from cum_sum_vertical
   where percentage_value <= 0.8
),


brand_gmv_table as 
(
select
sales.analytic_vertical,
sales.brand,
sum(gmv) as brand_gmv
    
FROM bigfoot_external_neo.cp_bi_prod_sales__forward_unit_history_fact sales

WHERE lower(sales.status) in ('in_progress','undelivered','completed','delivered','approved','shipped','ready_to_ship','returned', 'return_requested','activated')
    AND sales.type !='service'
    AND sales.replacement_for_unit IS NULL
    AND sales.exchange_for_unit IS NULL
    AND sales.is_freebie =FALSE
    AND sales.marketplace_id IN ('FLIPKART')
    AND sales.is_shopsy_order =FALSE
    AND order_date_key between 20250701 and 20250831
    
group by 
sales.analytic_vertical,
sales.brand 
),

rank_brands as
(
select
analytic_vertical,
brand,
brand_gmv,
row_number() over (partition by analytic_vertical order by brand_gmv desc) as rank_number

from brand_gmv_table
),

top_10_brands_from_pareto_verticals as
(
select
a.analytic_vertical,
brand

from rank_brands a
inner join top_80_percent_vertical_bgm b
on a.analytic_vertical = b.analytic_vertical

where 
rank_number<=10
)




SELECT
t1.analytic_category,
t1.analytic_super_category,
case when top_verticals.analytic_vertical is not null then t1.analytic_vertical end as analytic_vertical,
case when top_verticals.brand is not null then t1.brand end as brand,
asp_bucket,
case when t1.is_alpha_seller = 'alpha' then 'alpha' else 'MP' end as is_alpha_seller,
t1.order_date_key,
case when (lower(bgm.branded_flag) = 'branded' and t1.analytic_business_unit='BGM') then 'Branded' else 'Non-Branded' end as branded_flag,
case when t5.owner = 'KAM' then 'KAM' else 'N-KAM' end as managed_seller_flag,


SUM(t1.input_fes_weighted_asp) as input_festive_weighted_asp_sum,
SUM(t1.input_bau_weighted_asp) as input_bau_weighted_asp_sum,

SUM(t1.output_fes_weighted_asp) as output_festive_weighted_asp_sum,
SUM(t1.output_bau_weighted_asp) as output_bau_weighted_asp_sum,

SUM(t1.fes_units_sum) as units_purchased_in_a_fest_day,
(SUM(t1.bau_units_sum)/25) as units_purchased_in_a_BAU_day,

SUM(t1.input_fes_weighted_fsp) as input_festive_weighted_fsp_sum,
SUM(t1.input_bau_weighted_fsp) as input_bau_weighted_fsp_sum,

SUM(t1.fest_gmv) as gmv_in_a_fest_day,
(SUM(t1.tot_bau_gmv)/25) as gmv_in_a_BAU_day,

SUM(t1.output_fes_weighted_fsp) as output_fes_weighted_fsp_sum,
SUM(t1.outut_bau_weighted_fsp) as outut_bau_weighted_fsp_sum,

minoq_flag

from

(SELECT
a.analytic_business_unit,
a.analytic_category,
a.analytic_super_category,
a.analytic_vertical,
a.product_id,
a.listing_id,
a.seller_id,
a.brand as brand,
a.is_alpha_seller,
a.order_date_key,
a.bau_units_sum,
a.fes_units_sum,
a.input_bau_weighted_asp,
a.output_bau_weighted_asp,
a.input_fes_weighted_asp,
a.output_fes_weighted_asp,

input_fes_weighted_fsp,
input_bau_weighted_fsp,
output_fes_weighted_fsp,
outut_bau_weighted_fsp,

fest_gmv,
tot_bau_gmv,
case 
   when bau_asp between 0 and 300 then '0-300'
   when bau_asp between 300 and 500 then '300-500'
   when bau_asp between 500 and 1000 then '500-1000'
   else '1000_plus' end as asp_bucket,

minoq_flag
 

FROM

(SELECT
   bau.analytic_business_unit as analytic_business_unit,
   bau.analytic_category as analytic_category,
   bau.analytic_super_category as analytic_super_category,
   bau.analytic_vertical as analytic_vertical,
   bau.product_id as product_id,
   bau.listing_id as listing_id,
   bau.seller_id as seller_id,
   bau.brand as brand,
   bau.is_alpha_seller as is_alpha_seller,
   fes.order_date_key as order_date_key,
   bau.units as bau_units_sum,
   fes.units as fes_units_sum,
   (bau.gmv/bau.units)*bau.units as input_bau_weighted_asp,
   (bau.gmv/bau.units)*fes.units as output_bau_weighted_asp,
   (fes.gmv/fes.units)*bau.units as input_fes_weighted_asp,
   (fes.gmv/fes.units)*fes.units as output_fes_weighted_asp,

   (fes.lp/fes.units)*bau.units as input_fes_weighted_fsp,
   (bau.lp/bau.units)*bau.units as input_bau_weighted_fsp,
   (fes.lp/fes.units)*fes.units as output_fes_weighted_fsp,
   (bau.lp/bau.units)*fes.units as outut_bau_weighted_fsp,
 
    fes.gmv as fest_gmv,
    bau.gmv as tot_bau_gmv,

    bau.gmv/bau.units as bau_asp,

    CASE WHEN bau_minoq_flag = 1 or fes_minoq_flag = 1 then 'Minoq' else 'Non Minoq' end as minoq_flag

FROM
(
SELECT
   sales.analytic_business_unit,
   sales.analytic_category,
   sales.analytic_super_category,
   sales.analytic_vertical,
   sales.product_id,
   sales.listing_id,
   sales.seller_id,
   sales.brand as brand,
   case when sales.is_alpha_seller = TRUE then 'alpha' else 'MP' end as is_alpha_seller,
   SUM(units) as units,
   SUM(gmv) as gmv,
   SUM(listing_price)+SUM(coalesce((cast(regexp_extract(construct_fee_adjustments, '"amount":([0-9.]+)[^}]*?"referenceId":"iks:001"', 1) as numeric)),0)) as lp,
   MAX(CASE WHEN minimum_quantity >= 2 then 1 else 0 end) as bau_minoq_flag

FROM bigfoot_external_neo.cp_bi_prod_sales__forward_unit_history_fact sales

WHERE lower(sales.status) in ('in_progress','undelivered','completed','delivered','approved','shipped','ready_to_ship','returned', 'return_requested','activated')
   AND sales.type !='service'
   AND sales.replacement_for_unit IS NULL
   AND sales.exchange_for_unit IS NULL
   AND sales.is_freebie =FALSE
   AND sales.marketplace_id IN ('FLIPKART')
   AND sales.is_shopsy_order =FALSE
   AND sales.analytic_business_unit IN ('BGM')
   AND order_date_key between 20251201 and 20251225

GROUP BY
   sales.analytic_business_unit,
   sales.analytic_category,
   sales.analytic_super_category,
   sales.analytic_vertical,
   sales.product_id,
   sales.listing_id,
   sales.seller_id,
   sales.brand,
   case when sales.is_alpha_seller = TRUE then 'alpha' else 'MP' end
) bau

INNER JOIN

(
SELECT
   sales.listing_id,
   order_date_key,
   SUM(units) as units,
   SUM(net_amount) as gmv,
   SUM(listing_price)+SUM(coalesce((cast(regexp_extract(construct_fee_adjustments, '"amount":([0-9.]+)[^}]*?"referenceId":"iks:001"', 1) as numeric)),0)) as lp,
   MAX(CASE WHEN minimum_quantity >= 2 then 1 else 0 end) as fes_minoq_flag
  
FROM bigfoot_external_neo.cp_bi_prod_sales__forward_unit_live_hbase_snapshot_fact sales

WHERE lower(sales.unit_status) in ('in_progress','undelivered','completed','delivered','approved','shipped','ready_to_ship','returned', 'return_requested','activated')
   AND sales.unit_type !='service'
   AND sales.marketplace_id IN ('FLIPKART')
   AND lower(sales.is_shopsy_order) = 'false'
   AND sales.business_unit IN ('BGM')
   AND order_date_key BETWEEN CAST(DATE_FORMAT(DATE_SUB(CURRENT_DATE(), 16), 'yyyyMMdd') AS BIGINT) AND CAST(DATE_FORMAT(CURRENT_DATE(), 'yyyyMMdd') AS BIGINT)

GROUP BY
   sales.listing_id,
   order_date_key
) fes
ON bau.listing_id = fes.listing_id) as a
) as t1

LEFT JOIN 
    (
        SELECT 
            LOWER(analytic_super_category) AS analytic_super_category,
            LOWER(brand) AS brand,
            MIN(branded_flag) AS branded_flag,
            MIN(brand_type) AS brand_type,
            MIN(brand_tier) AS brand_tier,
            MIN(is_priority_brand) AS is_priority_brand
        FROM  
            fdp_uploads.ds_fkint_analytics_cdo_bgm_sc_brand_mapping_analytics_1_0
        GROUP BY 
            LOWER(analytic_super_category),
            LOWER(brand)
    ) bgm
    ON LOWER(t1.analytic_super_category) = LOWER(bgm.analytic_super_category)
    AND LOWER(t1.brand) = LOWER(bgm.brand)


LEFT JOIN (select * from fdp_uploads.ds_fkint_analytics_cdo_bgm_pareto_verticas_and_top_10_brands_1_0) as top_verticals
on top_verticals.analytic_vertical = t1.analytic_vertical and top_verticals.brand=t1.brand


LEFT JOIN
(
SELECT
seller_id,
MIN(owner) as owner
FROM fdp_uploads.ds_fkint_mp_sp_sellers_owners_mapping_fact_1_2
GROUP BY
seller_id
) as t5
on t1.seller_id = t5.seller_id



GROUP BY
t1.analytic_category,
t1.analytic_super_category,
case when top_verticals.analytic_vertical is not null then t1.analytic_vertical end,
case when top_verticals.brand is not null then t1.brand end,
asp_bucket,
case when t1.is_alpha_seller = 'alpha' then 'alpha' else 'MP' end,
t1.order_date_key,
case when (lower(bgm.branded_flag) = 'branded' and t1.analytic_business_unit='BGM') then 'Branded' else 'Non-Branded' end,
case when t5.owner = 'KAM' then 'KAM' else 'N-KAM' end,
minoq_flag