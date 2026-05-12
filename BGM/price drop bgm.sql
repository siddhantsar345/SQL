select 


order_date_key  as order_date_key,
analytic_business_unit, 
analytic_super_category,
analytic_vertical,
brand, 
branded_flag,
price_bucket,
is_alpha_seller,
service_profile,
kam_nkam_flag, 


cast(output_fes_weighted_asp as float64) as output_fes_weighted_asp,
cast(output_bau_weighted_asp as float64) as output_bau_weighted_asp,
cast(input_bau_weighted_asp as float64) as input_bau_weighted_asp,
cast(input_fes_weighted_asp as float64) as input_fes_weighted_asp,

cast(input_fes_weighted_fsp as float64) as input_fes_weighted_fsp,
cast(input_bau_weighted_fsp as float64) as input_bau_weighted_fsp,
cast(output_fes_weighted_fsp as float64) as output_fes_weighted_fsp,
cast(output_bau_weighted_fsp as float64) as output_bau_weighted_fsp

from 

(

SELECT 
    
    sales.order_date_key as order_date_key,
  
    sales.analytic_business_unit as analytic_business_unit,
    sales.analytic_super_category as analytic_super_category,
    sales.analytic_vertical as analytic_vertical,
    case when lower(b.branded_flag)='branded' then b.brand else 'Others' end as brand,
    b.branded_flag as branded_flag,
    sales.price_bucket as price_bucket,
    sales.is_alpha_seller as is_alpha_seller,
    sales.service_profile as service_profile,
    case when t5.owner is not null then t5.owner else 'NKAM - UM' end as kam_nkam_flag,
    
    




    SUM(sales.output_fes_weighted_asp) as output_fes_weighted_asp,
    SUM(sales.output_bau_weighted_asp) as output_bau_weighted_asp,
    SUM(sales.input_bau_weighted_asp) as  input_bau_weighted_asp,
    SUM(sales.input_fes_weighted_asp) as  input_fes_weighted_asp,

    SUM(sales.input_fes_weighted_fsp) as  input_fes_weighted_fsp,
    SUM(sales.input_bau_weighted_fsp) as  input_bau_weighted_fsp,
    SUM(sales.output_fes_weighted_fsp) as output_fes_weighted_fsp,
    SUM(sales.output_bau_weighted_fsp) as  output_bau_weighted_fsp



FROM

(
    SELECT
        a.order_date_key as order_date_key,
        a.marketplace as marketplace,
        a.analytic_business_unit as analytic_business_unit,
        a.analytic_super_category as analytic_super_category,
        a.analytic_vertical as analytic_vertical,
        
        a.seller_id as seller_id, 
        a.brand as brand, 
       
        a.is_alpha_seller as is_alpha_seller,
        a.service_profile as service_profile,
        a.price_bucket as price_bucket,
       

        a.output_fes_weighted_asp as output_fes_weighted_asp,
       a.output_bau_weighted_asp as output_bau_weighted_asp,
       a.input_bau_weighted_asp as input_bau_weighted_asp,
       a.input_fes_weighted_asp as input_fes_weighted_asp,

       a.input_fes_weighted_fsp as input_fes_weighted_fsp,
       a.input_bau_weighted_fsp as input_bau_weighted_fsp,
       a.output_fes_weighted_fsp as output_fes_weighted_fsp,
       a.output_bau_weighted_fsp as output_bau_weighted_fsp,

       a.bau_listing_price as bau_listing_price, 
       a.festive_listing_price as festive_listing_price, 

       a.bau_units as bau_units, 
       a.fes_units as fes_units, 

       a.bau_gmv as bau_gmv,
       a.fes_gmv as fes_gmv,
       a.minoq_flag as minoq_flag


    FROM


    (
        SELECT
            fes.order_date_key as order_date_key,
            bau.marketplace as marketplace,
            bau.analytic_business_unit as analytic_business_unit,
            bau.analytic_super_category as analytic_super_category,
            bau.analytic_vertical as analytic_vertical,
            bau.cms_vertical as cms_vertical,
            bau.seller_id as seller_id,
            bau.brand as brand,
            
            
            bau.is_alpha_seller as is_alpha_seller,
            bau.service_profile as service_profile,
            bau.price_bucket as price_bucket,
            case when bau.listing_id is not null then bau.listing_id else "Uncommon listings" end as listing_id,
          


            CASE WHEN bau.listing_id IS NOT NULL AND fes.units > 0 THEN (fes.gmv / fes.units) * fes.units ELSE 0 END AS output_fes_weighted_asp,
            CASE WHEN bau.listing_id IS NOT NULL AND bau.units > 0 THEN (bau.gmv / bau.units) * fes.units ELSE 0 END AS output_bau_weighted_asp,
            CASE WHEN bau.listing_id IS NOT NULL AND bau.units > 0 THEN (bau.gmv / bau.units) * bau.units ELSE 0 END AS input_bau_weighted_asp,
            CASE WHEN bau.listing_id IS NOT NULL AND fes.units > 0 THEN (fes.gmv / fes.units) * bau.units  ELSE 0 END AS input_fes_weighted_asp,

            
            CASE WHEN bau.listing_id IS NOT NULL AND fes.units > 0 THEN (fes.lp / fes.units) * bau.units  ELSE 0 END AS input_fes_weighted_fsp,
            CASE WHEN bau.listing_id IS NOT NULL AND bau.units > 0 THEN (bau.lp / bau.units) * bau.units ELSE 0 END AS input_bau_weighted_fsp,
            CASE WHEN bau.listing_id IS NOT NULL AND fes.units > 0 THEN (fes.lp / fes.units) * fes.units  ELSE 0 END AS output_fes_weighted_fsp,
            CASE WHEN bau.listing_id IS NOT NULL AND bau.units > 0 THEN (bau.lp / bau.units) * fes.units ELSE 0 END AS output_bau_weighted_fsp,




            

            case when bau.listing_id is not null then bau.lp else 0 end as bau_listing_price, 
            case when bau.listing_id is not null then fes.lp else 0 end as festive_listing_price, 
            case when bau.listing_id is not null then bau.units else 0 end as bau_units, 
            case when bau.listing_id is not null then fes.units else 0 end as fes_units,
            case when bau.listing_id is not null then bau.gmv else 0 end as bau_gmv, 
            case when bau.listing_id is not null then fes.gmv else 0 end as fes_gmv,
            case when bau.listing_id is not null and bau.units > 0 then bau.gmv/bau.units else 0 end as bau_asp,
            CASE WHEN bau.bau_minoq_flag = 1 or fes.fes_minoq_flag = 1 then 'Minoq' else 'Non Minoq' end as minoq_flag,

            fes.gmv as overall_fes_gmv

        FROM
        (
            SELECT
                CAST(substring(CAST(sales.order_date_key AS STRING), 1, 6) AS BIGINT) as YearMo,
                sales.marketplace_id as marketplace,
                sales.analytic_business_unit as analytic_business_unit, 
                sales.analytic_super_category as analytic_super_category,
                sales.analytic_vertical as analytic_vertical,
                sales.cms_vertical as cms_vertical,
                sales.seller_id as seller_id,
                sales.brand as brand,
               
                case when sales.is_alpha_seller = TRUE then 'Diamond' else 'Rest of MP' end as is_alpha_seller, 
                
                max(case 
                    when is_alpha_seller = TRUE and ((lower(sales.source_facility_id) like '%\\_alite\\_%') or (lower(sales.source_facility_id) like '%\\_al\\_%')) then 'Alite'
                    when sales.service_profile = 'FBF' then 'FBF' 
                    when sales.service_profile in ('NON_FBF','FBF_LITE') then 'NFBF'
                    else 'null' end)  as service_profile,


                CASE 
                    WHEN sum(sales.gmv) / sum(sales.units) <= 300 THEN '0-300'
                    WHEN sum(sales.gmv) / sum(sales.units) > 300 AND sum(sales.gmv) / sum(sales.units) <= 500 then '301-500'
                    WHEN sum(sales.gmv) / sum(sales.units) > 500 AND sum(sales.gmv) / sum(sales.units) <= 1000 then '501-1000'
                    WHEN sum(sales.gmv) / sum(sales.units) > 1000 THEN '1000+'
                End as price_bucket,

                sales.product_id as product_id,
                sales.listing_id as listing_id,
                SUM(units) as units,
                SUM(gmv) as gmv,
                ( SUM(listing_price) + SUM( coalesce( cast( nullif( regexp_extract( construct_fee_adjustments, '"amount":([0-9.]+)[^}]*?"referenceId":"iks:001"', 1 ), '' ) as FLOAT64 ), 0 ) ) ) as lp,

                MAX(CASE WHEN minimum_quantity >= 2 then 1 else 0 end) as bau_minoq_flag


            FROM bigfoot_external_neo.cp_bi_prod_sales__forward_unit_history_fact sales
            
        
            

            WHERE lower(sales.status) in ('in_progress','undelivered','completed','delivered','approved','shipped','ready_to_ship','returned', 'return_requested','activated')
                AND sales.type != 'service'
                AND sales.replacement_for_unit IS NULL
                AND sales.exchange_for_unit IS NULL
                AND sales.is_freebie = FALSE
                AND (sales.marketplace_id IN ('FLIPKART'))
                AND sales.is_shopsy_order = FALSE
                AND sales.analytic_business_unit IN ('BGM')
                AND (
                    (order_date_key BETWEEN 20250609 AND 20250611) 
                    OR 
                    (order_date_key BETWEEN 20250619 AND 20250630)
                )
            GROUP BY
                 CAST(substring(CAST(sales.order_date_key AS STRING), 1, 6) AS BIGINT) ,
                sales.marketplace_id ,
                sales.analytic_business_unit ,
                sales.analytic_super_category ,
                sales.analytic_vertical ,
                sales.cms_vertical ,
                sales.seller_id ,
                sales.brand ,
               
                case when sales.is_alpha_seller = TRUE then 'Diamond' else 'Rest of MP' end ,
                
              


               

                sales.product_id ,
                sales.listing_id 
        ) as  bau

        inner join 
        (
            SELECT
                sales.listing_id,
                order_date_key as order_date_key,
                SUM(units) as units,
                SUM(gmv) as gmv,
                ( SUM(listing_price) + SUM( coalesce( cast( nullif( regexp_extract( construct_fee_adjustments, '"amount":([0-9.]+)[^}]*?"referenceId":"iks:001"', 1 ), '' ) as FLOAT64 ), 0 ) ) ) as lp,
                 MAX(CASE WHEN minimum_quantity >= 2 then 1 else 0 end) as fes_minoq_flag
            FROM bigfoot_external_neo.cp_bi_prod_sales__forward_unit_history_fact sales
            
            WHERE lower(sales.status) in ('in_progress','undelivered','completed','delivered','approved','shipped','ready_to_ship','returned', 'return_requested','activated')
                AND sales.type != 'service'
                AND sales.replacement_for_unit IS NULL
                AND sales.exchange_for_unit IS NULL
                AND sales.is_freebie = FALSE
                AND (sales.marketplace_id IN ('FLIPKART'))
                AND sales.is_shopsy_order = FALSE
                AND sales.analytic_business_unit IN ('BGM')
                AND order_date_key between 20250701 AND 20250831
            GROUP BY
                sales.listing_id,
                order_date_key
        ) as fes
        ON bau.listing_id = fes.listing_id 
    ) as a

) as sales


LEFT JOIN
    (
    SELECT
        seller_id,
        MIN(managed_by) AS owner
    FROM fdp_uploads.ds_fkint_analytics_cdo_seller_kam_ukam_mapping_1_0
    GROUP BY seller_id
    ) AS t5 
    on sales.seller_id = t5.seller_id

left join bigfoot_external_neo.sp_seller__seller_hive_dim  as slr_dim

on t5.seller_id = slr_dim.seller_id 

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
    ) b
    ON LOWER(sales.analytic_super_category) = LOWER(b.analytic_super_category)
    AND LOWER(sales.brand) = LOWER(b.brand)

GROUP BY 
    sales.order_date_key,
   
    sales.analytic_business_unit,
    sales.analytic_super_category,
    sales.analytic_vertical,
    sales.service_profile,
    sales.is_alpha_seller,
    case when lower(b.branded_flag)='branded' then b.brand else 'Others' end,
    sales.price_bucket,
    b.branded_flag,
    case when t5.owner is not null then t5.owner else 'NKAM - UM' end 


)