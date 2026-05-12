--- Speed ---


select 
sales.order_date_key,
sales.analytic_business_unit,
SUM(CASE WHEN sales.sla_in_days <= 0 THEN 1 ELSE 0 END) AS d0_units,
SUM(CASE WHEN sales.sla_in_days <= 1 THEN 1 ELSE 0 END) AS d1_units,
SUM(CASE WHEN sales.sla_in_days <= 2 THEN 1 ELSE 0 END) AS d2_units,
SUM(CASE WHEN sales.sla_in_days <= 4 THEN 1 ELSE 0 END) AS d4_units,
SUM(CASE WHEN sales.sla_in_days <= 6 THEN 1 ELSE 0 END) AS d6_units,
SUM(CASE WHEN sales.sla_in_days <= 8 THEN 1 ELSE 0 END) AS d8_units,
SUM(CASE WHEN sales.sla_in_days <= 10 THEN 1 ELSE 0 END) AS d10_units
 
FROM  bigfoot_external_neo.cp_bi_prod_sales__forward_unit_history_fact sales

WHERE LOWER(sales.status) IN ('in_progress', 'undelivered', 'completed', 'delivered', 'approved', 'shipped', 'ready_to_ship', 'returned', 'return_requested', 'activated')
    AND sales.type  = 'physical'
    AND sales.replacement_for_unit IS NULL
    AND sales.exchange_for_unit IS NULL
    AND sales.is_freebie = FALSE
    AND sales.marketplace_id IN ('FLIPKART')
    AND lower(sales.analytic_business_unit) IN ('bgm','home','lifestyle','coreelectronics','emergingelectronics','furniture','mobile','largeappliances','electronics')
    AND sales.order_date_key between 20240701 and 20260406
    AND sales.is_shopsy_order = FALSE
        
group by 
sales.order_date_key,
sales.analytic_business_unit



-- Meesho PI CI --

SELECT
comp.date_key as date_key,
comp.analytic_business_unit as analytic_business_unit,
mpp,
sum(comp.m_dw) as m_dw,
sum(comp.cdw) as cdw,
sum(comp.cdw_fee) as cdw_fee,
sum(comp.dw) as dw,
sum(comp.fk_comp_display) as fk_comp_display,
sum(comp.ms_comp_display) as ms_comp_display,
sum(comp.fk_comp_display_fee) as fk_comp_display_fee,
sum(comp.ms_comp_display_fee) as ms_comp_display_fee,
      
FROM bigfoot_external_neo.cp_santa__meesho_pi_2__sc_level_fact AS comp

WHERE lower(comp.analytic_business_unit) in ('bgm','home','lifestyle','coreelectronics','emergingelectronics','furniture','mobile','largeappliances','electronics')
    AND CAST(date_key AS BIGINT) >= 20240701

GROUP BY 
comp.date_key as date_key
comp.analytic_business_unit as analytic_business_unit,
mpp


-- AZ PI CI --

select
    a.date_key,
    a.analytic_business_unit,
    sum(search_ppvs) as search_ppvs,
    sum(fk_price * search_ppvs) AS fk_price_npi,
    sum(comp_price * search_ppvs) AS comp_price_npi,
    sum(case when fsn_landscape = 'FK_Comp' then search_ppvs end) fk_comp,
    sum(case when fsn_landscape = 'AI_Comp' then search_ppvs end) az_comp,
    sum(case when fsn_coupon_landscape= "FK_Comp" then search_ppvs else 0 end ) as fk_cd,
    sum(case when fsn_coupon_landscape= "AI_Comp" then search_ppvs else 0 end ) as az_cd,
    sum(fk_price_post_coupon * search_ppvs) as wfcp,
    sum(comp_price_post_coupon * search_ppvs) as wccp,
    -- comp_price_cd= fk_cd-az_cd
    (sum(case when fsn_coupon_landscape= "FK_Comp" then search_ppvs else 0 end ) - sum(case when fsn_coupon_landscape= "AI_Comp" then search_ppvs else 0 end )) as comp_price_cd
from
    ( select
        a.date_key,
        a.analytic_business_unit,
        a.mcat_tag,
        a.fk_seller_type,
        a.az_seller_type,
        search_ppvs,
        fsn_landscape,
        fk_price,comp_price,
        fk_price_post_coupon,
        fsn,
        (comp_price-coalesce(comp_coupon_discount,0)) as comp_price_post_coupon,
        CASE
            WHEN fk_price_post_coupon < 1000 AND (comp_price-coalesce(comp_coupon_discount,0))/NULLIF(fk_price_post_coupon,0) > 1.02 THEN "FK_Comp"
            WHEN fk_price_post_coupon < 1000 AND (comp_price-coalesce(comp_coupon_discount,0))/NULLIF(fk_price_post_coupon,0) < 0.98 THEN "AI_Comp"
            WHEN fk_price_post_coupon >= 1000 AND (comp_price-coalesce(comp_coupon_discount,0))/NULLIF(fk_price_post_coupon,0) > 1.01 THEN "FK_Comp"
            WHEN fk_price_post_coupon >= 1000 AND (comp_price-coalesce(comp_coupon_discount,0))/NULLIF(fk_price_post_coupon,0) < 0.99 THEN "AI_Comp"
            ELSE "Parity"
        END as fsn_coupon_landscape
    from bigfoot_external_neo.analytics_cdo__unweighted_comp_base_hist_fact as a
    where lower(competitor) in ("ai")
    and CAST(date_key as INT64) >= 20240701
    and lower(ci_business_unit) in ('bgm','home','lifestyle','coreelectronics','emergingelectronics','furniture','mobile','largeappliances','electronics')
    ) as a
group by
    a.date_key,
    a.analytic_business_unit



-- selection A+I --

SELECT 
    
    list_dim.process_date_key,
    prod_dim.analytic_business_unit,

    count(distinct list_dim.listing_id) as a_listings,
    count(distinct list_dim.product_id) as a_products,

    count(distinct case when list_dim.final_atp > 0 then list_dim.listing_id end) as ai_listings,
    count(distinct case when list_dim.final_atp > 0 then list_dim.product_id end) as ai_products,
    

    count(distinct case when list_dim.service_profile = 'FBF' then list_dim.listing_id end) as a_fbf_lids,
    count(distinct case when list_dim.service_profile = 'FBF' then list_dim.product_id end) as a_fbf_pids,


    count(distinct case when (lower(list_dim.service_profile) in ("non_fbf","fbf_and_non_fbf") and list_dim.final_atp > 0) then list_dim.listing_id end) as ai_nfbf_lids,
    count(distinct case when (lower(list_dim.service_profile) in ("non_fbf","fbf_and_non_fbf") and list_dim.final_atp > 0) then list_dim.product_id end) as ai_nfbf_pids,


    count(distinct case when (lower(list_dim.service_profile) in ("fbf","fbf_and_fbf_lite","fbf_and_non_fbf","fbf_lite") and list_dim.final_atp > 0) then list_dim.listing_id end) as ai_fbf_lids,
    count(distinct case when (lower(list_dim.service_profile) in ("fbf","fbf_and_fbf_lite","fbf_and_non_fbf","fbf_lite") and list_dim.final_atp > 0) then list_dim.product_id end) as ai_fbf_pids

FROM bigfoot_external_neo.sp_analytics__listing_history_90d_fact as list_dim

LEFT JOIN bigfoot_external_neo.sp_product__product_attribute_hive_dim prod_dim
    on list_dim.product_id = prod_dim.product_id

WHERE
    list_dim.marketplace_id = 'FLIPKART'
    and lower(prod_dim.analytic_business_unit) in  ('bgm','home','lifestyle','coreelectronics','emergingelectronics','furniture','mobile','largeappliances','electronics')
    and list_dim.process_date_key >= 20240701

GROUP BY 1,2



--- Overall query with all the above queries ---


select 


speed.order_date_key as order_date_key, 
speed.analytic_business_unit as analytic_business_unit, 

speed.total_units as total_units, 
speed.d0_units as d0_units, 
speed.d1_units as d1_units, 
speed.d2_units as d2_units,
speed.d4_units as d4_units, 
speed.d6_units as d6_units,


a_listings as a_listings,
a_products as a_products, 
ai_listings as ai_listings,
ai_products as ai_products,


ai_myntra.ai_search_ppvs as ai_search_ppvs,
ai_myntra.ai_fk_cd as ai_fk_cd, 
ai_myntra.ai_az_cd as ai_az_cd,
ai_myntra.ai_wfcp as ai_wfcp,
ai_myntra.ai_wccp as ai_wccp,
ai_myntra.myntra_search_ppvs as myntra_search_ppvs,
ai_myntra.myntra_fk_cd as myntra_fk_cd,
ai_myntra.myntra_az_cd as myntra_az_cd,
ai_myntra.myntra_wfcp as myntra_wfcp,
ai_myntra.myntra_wccp as myntra_wccp,

meesho.m_dw_0_300 as m_dw_0_300,
meesho.m_dw_301_500 as m_dw_301_500,
meesho.m_dw_500_plus as m_dw_500_plus,
meesho.cdw_0_300 as cdw_0_300,
meesho.cdw_301_500 as cdw_301_500,
meesho.cdw_500_plus as cdw_500_plus,
meesho.cdw_fee_0_300 as cdw_fee_0_300,
meesho.cdw_fee_301_500 as cdw_fee_301_500,
meesho.cdw_fee_500_plus as cdw_fee_500_plus,
meesho.dw_0_300 as dw_0_300,
meesho.dw_301_500 as dw_301_500,
meesho.dw_500_plus as dw_500_plus,
meesho.fk_comp_display_0_300 as fk_comp_display_0_300,
meesho.fk_comp_display_301_500 as fk_comp_display_301_500,
meesho.fk_comp_display_500_plus as fk_comp_display_500_plus,
meesho.ms_comp_display_0_300 as ms_comp_display_0_300,
meesho.ms_comp_display_301_500 as ms_comp_display_301_500,
meesho.ms_comp_display_500_plus as ms_comp_display_500_plus,
meesho.fk_comp_display_fee_0_300 as fk_comp_display_fee_0_300,
meesho.fk_comp_display_fee_301_500 as fk_comp_display_fee_301_500,
meesho.fk_comp_display_fee_500_plus as fk_comp_display_fee_500_plus,
meesho.ms_comp_display_fee_0_300 as ms_comp_display_fee_0_300,
meesho.ms_comp_display_fee_301_500 as ms_comp_display_fee_301_500,
meesho.ms_comp_display_fee_500_plus as ms_comp_display_fee_500_plus,

price_drop.input_bau_weighted_asp as input_bau_weighted_asp,
price_drop.input_fes_weighted_asp as input_fes_weighted_asp,
price_drop.output_bau_weighted_asp as output_bau_weighted_asp,
price_drop.output_fes_weighted_asp as output_fes_weighted_asp


from 


(
   
select 
sales.order_date_key,
sales.analytic_business_unit,
sum(sales.units) as total_units, 
SUM(CASE WHEN sales.sla_in_days <= 0 THEN sales.units ELSE 0 END) AS d0_units,
SUM(CASE WHEN sales.sla_in_days <= 1 THEN sales.units ELSE 0 END) AS d1_units,
SUM(CASE WHEN sales.sla_in_days <= 2 THEN sales.units ELSE 0 END) AS d2_units,
SUM(CASE WHEN sales.sla_in_days <= 4 THEN sales.units ELSE 0 END) AS d4_units,
SUM(CASE WHEN sales.sla_in_days <= 6 THEN sales.units ELSE 0 END) AS d6_units
 
FROM  bigfoot_external_neo.cp_bi_prod_sales__forward_unit_history_fact sales

WHERE LOWER(sales.status) IN ('in_progress', 'undelivered', 'completed', 'delivered', 'approved', 'shipped', 'ready_to_ship', 'returned', 'return_requested', 'activated')
    AND sales.type  !='service'
    AND sales.replacement_for_unit IS NULL
    AND sales.exchange_for_unit IS NULL
    AND sales.is_freebie = FALSE
    AND sales.marketplace_id IN ('FLIPKART')
    AND lower(sales.analytic_business_unit) IN ('bgm','home','lifestyle','coreelectronics','emergingelectronics','furniture','mobile','largeappliances','electronics')
    AND sales.order_date_key between 20260101 and 20260406
    AND sales.is_shopsy_order = FALSE
        
group by 
sales.order_date_key,
sales.analytic_business_unit
) as speed

left join 



(
   
   SELECT 
    
    list_dim.process_date_key as order_date_key,
    prod_dim.analytic_business_unit as analytic_business_unit,

    count(distinct list_dim.listing_id) as a_listings,
    count(distinct list_dim.product_id) as a_products,

    count(distinct case when list_dim.final_atp > 0 then list_dim.listing_id end) as ai_listings,
    count(distinct case when list_dim.final_atp > 0 then list_dim.product_id end) as ai_products,
    

FROM bigfoot_external_neo.sp_analytics__listing_history_90d_fact as list_dim

LEFT JOIN bigfoot_external_neo.sp_product__product_categorization_hive_dim prod_dim
    on list_dim.product_id = prod_dim.product_id

WHERE
    list_dim.marketplace_id = 'FLIPKART'
    and lower(prod_dim.analytic_business_unit) in  ('bgm','home','lifestyle','coreelectronics','emergingelectronics','furniture','mobile','largeappliances','electronics')
    and list_dim.process_date_key between 20260101 and 20260406

GROUP BY 
 list_dim.process_date_key,
    prod_dim.analytic_business_unit

) as instock


on 
instock.order_date_key = speed.order_date_key and 
instock.analytic_business_unit = speed.analytic_business_unit

left join 


   (

select   
   a.order_date_key as order_date_key,
   a.analytic_business_unit as analytic_business_unit,   
  
sum(case when lower(a.competitor) in ('ai') and ci_business_unit not in ("BGM(Books)" , "Electronics") then search_ppvs else 0 end) as ai_search_ppvs,
sum (case when fsn_coupon_landscape= "FK_Comp" and lower(a.competitor) in ('ai') and ci_business_unit not in ("BGM(Books)" , "Electronics") then search_ppvs else 0 end) as ai_fk_cd,
sum(case when fsn_coupon_landscape= "AI_Comp" and lower(a.competitor) in ('ai') and ci_business_unit not in ("BGM(Books)" , "Electronics") then search_ppvs else 0 end) as ai_az_cd,
sum(case when lower(a.competitor) in ('ai') and ci_business_unit not in ("BGM(Books)" , "Electronics") then fk_price_post_coupon * search_ppvs else 0 end) as ai_wfcp, 
sum (case when lower(a.competitor) in ('ai') and ci_business_unit not in ("BGM(Books)" , "Electronics") then comp_price_post_coupon * search_ppvs else 0 end) as ai_wccp,

sum(case when lower(competitor) in ("myntra") and ci_business_unit in ("lifestyle-Non_Apparel","lifestyle-Apparel") then search_ppvs else 0 end ) as myntra_search_ppvs,
sum(case when fsn_coupon_landscape= "FK_Comp" and lower(competitor) in ("myntra") and ci_business_unit in ("lifestyle-Non_Apparel","lifestyle-Apparel") then search_ppvs else 0 end ) as myntra_fk_cd,
sum(case when fsn_coupon_landscape= "AI_Comp" and lower(competitor) in ("myntra") and ci_business_unit in ("lifestyle-Non_Apparel","lifestyle-Apparel") then search_ppvs else 0 end ) as myntra_az_cd,
sum(case when lower(competitor) in ("myntra") and ci_business_unit in ("lifestyle-Non_Apparel","lifestyle-Apparel") then fk_price_post_coupon * search_ppvs else 0 end ) as myntra_wfcp, 
sum(case when lower(competitor) in ("myntra") and ci_business_unit in ("lifestyle-Non_Apparel","lifestyle-Apparel") then comp_price_post_coupon * search_ppvs else 0 end ) as myntra_wccp
FROM   
   (
   select   
   cast(date_key as int64) as order_date_key,
       a.competitor,   
       a.yearmo,   
       b.week_num_in_year,   
       a.analytic_business_unit,   
       a.ci_business_unit,   
       a.analytic_super_category,   
        case when lower(prod.analytic_business_unit) = 'lifestyle' then prod.cms_vertical else prod.analytic_vertical end as analytic_vertical,
       a.mcat_tag,
       a.fk_seller_type,   
       a.az_seller_type,   
       is_branded,   
       a.brand,   
       search_ppvs,   
       fsn_landscape,   
       fk_price, comp_price,   
       fk_price_post_coupon,   
       (comp_price - coalesce(comp_coupon_discount, 0)) as comp_price_post_coupon,
        CASE
            WHEN fk_price_post_coupon < 1000 AND (comp_price-coalesce(comp_coupon_discount,0))/NULLIF(fk_price_post_coupon,0) > 1.02 THEN "FK_Comp"
            WHEN fk_price_post_coupon < 1000 AND (comp_price-coalesce(comp_coupon_discount,0))/NULLIF(fk_price_post_coupon,0) < 0.98 THEN "AI_Comp"
            WHEN fk_price_post_coupon >= 1000 AND (comp_price-coalesce(comp_coupon_discount,0))/NULLIF(fk_price_post_coupon,0) > 1.01 THEN "FK_Comp"
            WHEN fk_price_post_coupon >= 1000 AND (comp_price-coalesce(comp_coupon_discount,0))/NULLIF(fk_price_post_coupon,0) < 0.99 THEN "AI_Comp"
            ELSE "Parity"
        END as fsn_coupon_landscape
  
   from bigfoot_external_neo.analytics_cdo__unweighted_comp_base_hist_fact as a   
   left join bigfoot_external_neo.sp_product__product_categorization_hive_dim prod
       on prod.product_id = a.fsn
   left join bigfoot_external_neo.scp_oms__date_dim_fact as b   
       on cast(date_dim_key as string) = a.date_key   
   where
       (cast(date_key as int64) between 20260101 and 20260406)
       AND
       (
           (lower(competitor) in ("ai") and ci_business_unit not in ("BGM(Books)", "Electronics"))
           OR
           (lower(competitor) in ("myntra") and ci_business_unit in ("lifestyle-Non_Apparel","lifestyle-Apparel"))
       )
   ) as a
GROUP BY
   a.order_date_key,
   a.analytic_business_unit

   ) as ai_myntra 

on 

ai_myntra.order_date_key = speed.order_date_key and 
ai_myntra.analytic_business_unit = speed.analytic_business_unit


left join 



(
   
SELECT

comp.date_key as order_date_key,
comp.analytic_business_unit as analytic_business_unit,

sum(case when comp.mpp = '0 - 300' then comp.m_dw else 0 end ) as m_dw_0_300,
sum(case when comp.mpp = '300 - 500' then comp.m_dw else 0 end ) as m_dw_301_500,
sum(case when comp.mpp = '500+' then comp.m_dw else 0 end ) as m_dw_500_plus,


sum(case when comp.mpp = '0 - 300' then comp.cdw else 0 end ) as cdw_0_300,
sum(case when comp.mpp = '300 - 500' then comp.cdw else 0 end ) as cdw_301_500,
sum(case when comp.mpp = '500+' then comp.cdw else 0 end ) as cdw_500_plus,

sum(case when comp.mpp = '0 - 300' then comp.cdw_fee else 0 end ) as cdw_fee_0_300,
sum(case when comp.mpp = '300 - 500' then comp.cdw_fee else 0 end ) as cdw_fee_301_500,
sum(case when comp.mpp = '500+' then comp.cdw_fee else 0 end ) as cdw_fee_500_plus,

sum(case when comp.mpp = '0 - 300' then comp.dw else 0 end ) as dw_0_300,
sum(case when comp.mpp = '300 - 500' then comp.dw else 0 end ) as dw_301_500,
sum(case when comp.mpp = '500+' then comp.dw else 0 end ) as dw_500_plus,

sum(case when comp.mpp = '0 - 300' then comp.fk_comp_display else 0 end ) as fk_comp_display_0_300,
sum(case when comp.mpp = '300 - 500' then comp.fk_comp_display else 0 end ) as fk_comp_display_301_500,
sum(case when comp.mpp = '500+' then comp.fk_comp_display else 0 end ) as fk_comp_display_500_plus,

sum(case when comp.mpp = '0 - 300' then comp.ms_comp_display else 0 end ) as ms_comp_display_0_300,
sum(case when comp.mpp = '300 - 500' then comp.ms_comp_display else 0 end ) as ms_comp_display_301_500,
sum(case when comp.mpp = '500+' then comp.ms_comp_display else 0 end ) as ms_comp_display_500_plus,

sum(case when comp.mpp = '0 - 300' then comp.fk_comp_display_fee else 0 end ) as fk_comp_display_fee_0_300,
sum(case when comp.mpp = '300 - 500' then comp.fk_comp_display_fee else 0 end ) as fk_comp_display_fee_301_500,
sum(case when comp.mpp = '500+' then comp.fk_comp_display_fee else 0 end ) as fk_comp_display_fee_500_plus,

sum(case when comp.mpp = '0 - 300' then comp.ms_comp_display else 0 end ) as ms_comp_display_fee_0_300,
sum(case when comp.mpp = '300 - 500' then comp.ms_comp_display else 0 end ) as ms_comp_display_fee_301_500,
sum(case when comp.mpp = '500+' then comp.ms_comp_display else 0 end ) as ms_comp_display_fee_500_plus

      
FROM bigfoot_external_neo.cp_santa__meesho_pi_2__sc_level_fact AS comp

WHERE lower(comp.analytic_business_unit) in ('bgm','home','lifestyle','coreelectronics','emergingelectronics','furniture','mobile','largeappliances','electronics')
    AND CAST(date_key AS BIGINT) between 20260101 and 20260406

GROUP BY 
comp.date_key ,
comp.analytic_business_unit 

) as meesho

on 

meesho.order_date_key =  speed.order_date_key and 
meesho.analytic_business_unit = speed.analytic_business_unit 

left join 


(
   

SELECT
order_date_key,
analytic_business_unit,

SUM(input_bau_weighted_asp) as input_bau_weighted_asp,
SUM(input_fes_weighted_asp) as input_fes_weighted_asp,

SUM(output_bau_weighted_asp) as output_bau_weighted_asp,
SUM(output_fes_weighted_asp) as output_fes_weighted_asp

FROM
(
SELECT
  fes.order_date_key as order_date_key,
   bau.analytic_business_unit,
 

  bau.product_id as product_id,
  bau.listing_id as listing_id,
 

  (bau.gmv/bau.units)*bau.units as input_bau_weighted_asp,
  (fes.gmv/fes.units)*bau.units as input_fes_weighted_asp,
  (bau.gmv/bau.units)*fes.units as output_bau_weighted_asp,
  (fes.gmv/fes.units)*fes.units as output_fes_weighted_asp
FROM
(
SELECT

  sales.analytic_super_category,
  analytic_business_unit,
  sales.product_id,
  sales.listing_id,
   case when sales.is_alpha_seller = TRUE then 'Diamond' else 'Rest of MP' end as is_alpha_seller, 
  SUM(units) as units,
  SUM(gmv) as gmv,
  SUM(listing_price) as lp

FROM bigfoot_external_neo.cp_bi_prod_sales__forward_unit_history_fact sales

WHERE lower(sales.status) in ('in_progress','undelivered','completed','delivered','approved','shipped','ready_to_ship','returned', 'return_requested','activated')
  AND sales.type !='service'
  AND sales.replacement_for_unit IS NULL
  AND sales.exchange_for_unit IS NULL
  AND sales.is_freebie =FALSE
  AND sales.marketplace_id IN ('FLIPKART')
  AND sales.is_shopsy_order =FALSE
  AND lower(sales.analytic_business_unit) IN ('bgm','home','lifestyle','coreelectronics','emergingelectronics','furniture','mobile','largeappliances','electronics')
  AND ((order_date_key between 20250701 and 20250831))

GROUP BY
 sales.analytic_super_category,
  analytic_business_unit,
  sales.product_id,
  sales.listing_id,
case when sales.is_alpha_seller = TRUE then 'Diamond' else 'Rest of MP' end

) bau

INNER JOIN

(
SELECT
  sales.listing_id,
  order_date_key,
  SUM(units) as units,
  SUM(gmv) as gmv,
  SUM(listing_price) as lp
 
FROM bigfoot_external_neo.cp_bi_prod_sales__forward_unit_history_fact sales

WHERE lower(sales.status) in ('in_progress','undelivered','completed','delivered','approved','shipped','ready_to_ship','returned', 'return_requested','activated')
  AND sales.type !='service'
  AND sales.replacement_for_unit IS NULL
  AND sales.exchange_for_unit IS NULL
  AND sales.is_freebie =FALSE
  AND sales.marketplace_id IN ('FLIPKART')
  AND sales.is_shopsy_order =FALSE
  AND lower(sales.analytic_business_unit) IN ('bgm','home','lifestyle','coreelectronics','emergingelectronics','furniture','mobile','largeappliances','electronics')
  AND order_date_key between 20260101 and 20260406

GROUP BY
  sales.listing_id,
  order_date_key
) fes
ON bau.listing_id = fes.listing_id

) sub

GROUP BY
order_date_key,
analytic_business_unit

) as price_drop



on
price_drop.order_date_key = speed.order_date_key and 
price_drop.analytic_business_unit = speed.analytic_business_unit