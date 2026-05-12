
select 
        domain_name, 
        order_date_key,
        marketplace,
        analytic_business_unit,
        analytic_super_category,
        analytic_vertical,
       is_alpha_seller,
       brand,
       city_tier, 
        zone,  
        price_point,
        kam_nkam_flag,
        branded_flag,
        
        cy_gmv,
        cy_units, 
        ly_gmv,
        ly_units,
        cy_ja_gmv,
        cy_ja_units,
        ly_ja_gmv, 
        ly_ja_units,

        cy_search_ppvs,
        cy_primary_ppvs,
        cy_net_units,

        ly_search_ppvs,
        ly_primary_ppvs,
        ly_net_units ,

        cy_ja_search_ppvs,
        cy_ja_primary_ppvs,
        cy_ja_net_units ,

        ly_ja_search_ppvs,
        ly_ja_primary_ppvs,
        ly_ja_net_units,

        cy_input_bau_weighted_asp,
        cy_input_fes_weighted_asp,
        cy_output_bau_weighted_asp,
        cy_output_fes_weighted_asp,

        ly_input_bau_weighted_asp,
        ly_input_fes_weighted_asp,
        ly_output_bau_weighted_asp,
        ly_output_fes_weighted_asp,
        event_type,
        service_profile

from 

(

select 
        'current_year_festive_sales' as domain_name,
        sales.order_date_key as order_date_key,
        sales.marketplace_id as marketplace,
        cat.analytic_business_unit as analytic_business_unit,
        cat.analytic_super_category as analytic_super_category,
        cat.analytic_vertical as analytic_vertical,
        case when sales.is_alpha_seller = TRUE then 'Diamond' else 'Rest of MP' end as is_alpha_seller,

        case when cat.analytic_business_unit = 'BGM' and lower(bgm_b.branded_flag)='branded' then  bgm_b.brand
             when cat.analytic_business_unit = 'Home' and  (lower(home_b.type)='branded' or lower(home_b.type)='d2c') then home_b.brand 
             when cat.analytic_business_unit = 'Furniture' and lower(fur_b.branded_flag)='branded' then fur_b.brand else 'Unbranded' end as brand,

        geo.city_tier as city_tier, 
        geo.zone as zone,  



        CASE 
    WHEN sales.analytic_business_unit IN ('BGM', 'Home') THEN 
        (CASE 
            WHEN sales.gmv / sales.units <= 300 THEN '0-300'
            WHEN sales.gmv / sales.units <= 500 THEN '301-500'
            WHEN sales.gmv / sales.units <= 1000 THEN '501-1000'
            ELSE '1000+'
        END)
    WHEN sales.analytic_business_unit IN ('Furniture') THEN 
        (CASE 
            WHEN sales.gmv / sales.units <= 500 THEN '0-500'
            WHEN sales.gmv / sales.units <= 1000 THEN '501-1k'
            WHEN sales.gmv / sales.units <= 2500 THEN '1k-2.5k'
            WHEN sales.gmv / sales.units <= 5000 THEN '2.5k-5k'
            WHEN sales.gmv / sales.units <= 7500 THEN '5k-7.5k'
            WHEN sales.gmv / sales.units <= 10000 THEN '7.5k-10k'
            WHEN sales.gmv / sales.units <= 15000 THEN '10k-15k'
            ELSE '15k+'
        END)
END AS price_point,

case when t5.owner = 'KAM' then 'KAM' else 'N-KAM' end as kam_nkam_flag,

 case when cat.analytic_business_unit = 'BGM' and lower(bgm_b.branded_flag)='branded' then  'Branded'
             when cat.analytic_business_unit = 'Home' and  (lower(home_b.type)='branded' or lower(home_b.type)='d2c') then 'Branded' 
             when cat.analytic_business_unit = 'Furniture' and lower(fur_b.branded_flag)='branded' then 'Branded' else 'Unbranded' end as branded_flag,

case 
     when sales.is_alpha_seller = TRUE and (lower(sales.source_facility_id)  like '%\\alite\\%') or (lower(sales.source_facility_id) like '%\\al\\%') then 'Alite'
        when sales.service_profile = 'FBF' then 'FBF' 
        when sales.service_profile in ('NON_FBF','FBF_LITE') then 'NFBF'
        else 'null' 
    end as service_profile,

        SUM(sales.gmv) AS cy_gmv,
        SUM(sales.units) AS cy_units, 
        0.0 AS ly_gmv,
        0.0 as ly_units,
        0.0 as cy_ja_gmv,
        0.0 as cy_ja_units,
        0.0 as ly_ja_gmv, 
        0.0 as ly_ja_units,

         0.0 as cy_search_ppvs,
        0.0 as cy_primary_ppvs,
        0.0 as cy_net_units,
         0.0 as ly_search_ppvs,
        0.0 as ly_primary_ppvs,
        0.0 as ly_net_units ,

        0.0 as cy_ja_search_ppvs,
        0.0 as cy_ja_primary_ppvs,
        0.0 as cy_ja_net_units ,

        0.0 as ly_ja_search_ppvs,
        0.0 as ly_ja_primary_ppvs,
        0.0 as ly_ja_net_units,

         0.0 as cy_input_bau_weighted_asp,
0.0 as cy_input_fes_weighted_asp,
0.0 as cy_output_bau_weighted_asp,
0.0 as cy_output_fes_weighted_asp,

0.0 as ly_input_bau_weighted_asp,
0.0 as ly_input_fes_weighted_asp,
0.0 as ly_output_bau_weighted_asp,
0.0 as ly_output_fes_weighted_asp,
date_map.event_type as event_type


 
from  bigfoot_external_neo.cp_bi_prod_sales__forward_unit_history_fact sales

left join  fdp_uploads.ds_fkint_analytics_cdo_festive_date_mapping_1_1 as date_map
        on sales.order_date_key = date_map.dates_current_year	



LEFT JOIN bigfoot_external_neo.sp_product__product_categorization_hive_dim cat
       ON  sales.product_id = cat.product_id
	   left join

(
SELECT 
 seller_id,
 MIN(managed_by) as owner
 FROM fdp_uploads.ds_fkint_analytics_cdo_seller_kam_ukam_mapping_1_0
 GROUP BY
 seller_id
) as t5
on sales.seller_id = t5.seller_id

LEFT JOIN
  fdp_uploads.ds_fkint_analytics_cdo_furniture_brand_mapping_analytics_1_0 fur_b
on lower(sales.analytic_super_category) = lower(fur_b.analytic_super_category)
and lower(sales.brand) = lower(fur_b.brand)
and lower(sales.analytic_vertical) = lower(fur_b.analytic_vertical)

LEFT JOIN  fdp_uploads.ds_fkint_cp_santa_hyperlocal_vertical_bu_mapping_2_0 AS hl 

    ON sales.analytic_vertical = hl.analytic_vertical 
    AND LOWER(hl.bu_final) in ('bgm','home','furniture')  
    and sales.marketplace_id='HYPERLOCAL'

  LEFT JOIN bigfoot_external_neo.scp_ekl__logistics_geo_hive_dim geo 
        on sales.shipping_address_pincode_key =  geo.logistics_geo_hive_dim_key 

      
        LEFT JOIN
        fdp_uploads.ds_fkint_analytics_cdo_brand_d2c_home_mapping_1_0 home_b
        on lower(sales.analytic_super_category) = lower(home_b.analytic_super_category)
        and lower(sales.brand) = lower(home_b.brand)
     
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
    ) bgm_b
    ON LOWER(sales.analytic_super_category) = LOWER(bgm_b.analytic_super_category)
    AND LOWER(sales.brand) = LOWER(bgm_b.brand)

WHERE 
        LOWER(sales.status) IN ('in_progress', 'undelivered', 'completed', 'delivered', 'approved', 'shipped', 'ready_to_ship', 'returned', 'return_requested', 'activated')
        AND sales.type  = 'physical'
        AND sales.replacement_for_unit IS NULL
        AND sales.exchange_for_unit IS NULL
        AND sales.is_freebie = FALSE
        AND (sales.marketplace_id IN ('FLIPKART') OR (sales.marketplace_id = 'HYPERLOCAL' AND  hl.analytic_vertical IS NOT NULL))
        AND (sales.order_date_key BETWEEN 20250823 AND CAST(FORMAT_DATE('%Y%m%d', DATE_SUB(CURRENT_DATE(), INTERVAL 1 DAY)) AS INT64) )
        AND sales.analytic_business_unit IN ('BGM','Home','Furniture')
        AND sales.is_shopsy_order = FALSE

group by 

        sales.order_date_key ,
        sales.marketplace_id ,
        cat.analytic_business_unit ,
        cat.analytic_super_category ,
        cat.analytic_vertical ,
        case when sales.is_alpha_seller = TRUE then 'Diamond' else 'Rest of MP' end ,

       case when cat.analytic_business_unit = 'BGM' and lower(bgm_b.branded_flag)='branded' then  bgm_b.brand
             when cat.analytic_business_unit = 'Home' and  (lower(home_b.type)='branded' or lower(home_b.type)='d2c') then home_b.brand 
             when cat.analytic_business_unit = 'Furniture' and lower(fur_b.branded_flag)='branded' then fur_b.brand else 'Unbranded' end ,
        geo.city_tier ,
        geo.zone ,



        CASE 
    WHEN sales.analytic_business_unit IN ('BGM', 'Home') THEN 
        (CASE 
            WHEN sales.gmv / sales.units <= 300 THEN '0-300'
            WHEN sales.gmv / sales.units <= 500 THEN '301-500'
            WHEN sales.gmv / sales.units <= 1000 THEN '501-1000'
            ELSE '1000+'
        END)
    WHEN sales.analytic_business_unit IN ('Furniture') THEN 
        (CASE 
            WHEN sales.gmv / sales.units <= 500 THEN '0-500'
            WHEN sales.gmv / sales.units <= 1000 THEN '501-1k'
            WHEN sales.gmv / sales.units <= 2500 THEN '1k-2.5k'
            WHEN sales.gmv / sales.units <= 5000 THEN '2.5k-5k'
            WHEN sales.gmv / sales.units <= 7500 THEN '5k-7.5k'
            WHEN sales.gmv / sales.units <= 10000 THEN '7.5k-10k'
            WHEN sales.gmv / sales.units <= 15000 THEN '10k-15k'
            ELSE '15k+'  end)
			
        END,

case when t5.owner = 'KAM' then 'KAM' else 'N-KAM' end ,
 case when cat.analytic_business_unit = 'BGM' and lower(bgm_b.branded_flag)='branded' then  'Branded'
             when cat.analytic_business_unit = 'Home' and  (lower(home_b.type)='branded' or lower(home_b.type)='d2c') then 'Branded' 
             when cat.analytic_business_unit = 'Furniture' and lower(fur_b.branded_flag)='branded' then 'Branded' else 'Unbranded' end ,
             date_map.event_type,
    case 
     when sales.is_alpha_seller = TRUE and (lower(sales.source_facility_id)  like '%\\alite\\%') or (lower(sales.source_facility_id) like '%\\al\\%') then 'Alite'
        when sales.service_profile = 'FBF' then 'FBF' 
        when sales.service_profile in ('NON_FBF','FBF_LITE') then 'NFBF'
        else 'null'
        end

union all 

select 

        'last_year_festive_sales' as domain_name,
        date_map.dates_current_year as order_date_key,
        sales.marketplace_id as marketplace,
        cat.analytic_business_unit as analytic_business_unit,
        cat.analytic_super_category as analytic_super_category,
        cat.analytic_vertical as analytic_vertical,
        case when sales.is_alpha_seller = TRUE then 'Diamond' else 'Rest of MP' end as is_alpha_seller,

        case when sales.analytic_business_unit = 'BGM' and lower(bgm_b.branded_flag)='branded' then  bgm_b.brand
             when sales.analytic_business_unit = 'Home' and  (lower(home_b.type)='branded' or lower(home_b.type)='d2c') then home_b.brand 
             when sales.analytic_business_unit = 'Furniture' and lower(fur_b.branded_flag)='branded' then fur_b.brand else 'Unbranded' end as brand,
        geo.city_tier as city_tier, 
        geo.zone as zone,  



        CASE 
    WHEN sales.analytic_business_unit IN ('BGM', 'Home') THEN 
        (CASE 
            WHEN sales.gmv / sales.units <= 300 THEN '0-300'
            WHEN sales.gmv / sales.units <= 500 THEN '301-500'
            WHEN sales.gmv / sales.units <= 1000 THEN '501-1000'
            ELSE '1000+'
        END)
    WHEN sales.analytic_business_unit IN ('Furniture') THEN 
        (CASE 
            WHEN sales.gmv / sales.units <= 500 THEN '0-500'
            WHEN sales.gmv / sales.units <= 1000 THEN '501-1k'
            WHEN sales.gmv / sales.units <= 2500 THEN '1k-2.5k'
            WHEN sales.gmv / sales.units <= 5000 THEN '2.5k-5k'
            WHEN sales.gmv / sales.units <= 7500 THEN '5k-7.5k'
            WHEN sales.gmv / sales.units <= 10000 THEN '7.5k-10k'
            WHEN sales.gmv / sales.units <= 15000 THEN '10k-15k'
            ELSE '15k+'
        END)
END AS price_point,

case when t5.owner = 'KAM' then 'KAM' else 'N-KAM' end as kam_nkam_flag,

             case when cat.analytic_business_unit = 'BGM' and lower(bgm_b.branded_flag)='branded' then  'Branded'
             when cat.analytic_business_unit = 'Home' and  (lower(home_b.type)='branded' or lower(home_b.type)='d2c') then 'Branded' 
             when cat.analytic_business_unit = 'Furniture' and lower(fur_b.branded_flag)='branded' then 'Branded' else 'Unbranded' end  as branded_flag,

    case 
     when sales.is_alpha_seller = TRUE and (lower(sales.source_facility_id)  like '%\\alite\\%') or (lower(sales.source_facility_id) like '%\\al\\%') then 'Alite'
        when sales.service_profile = 'FBF' then 'FBF' 
        when sales.service_profile in ('NON_FBF','FBF_LITE') then 'NFBF'
        else 'null' 
    end as service_profile,



        0.0 AS cy_gmv,
        0.0 AS cy_units,
        SUM(sales.gmv) AS ly_gmv,
        SUM(sales.units) as ly_units,
         0.0 as cy_ja_gmv,
        0.0 as cy_ja_units,
        0.0 as ly_ja_gmv, 
        0.0 as ly_ja_units,

         0.0 as cy_search_ppvs,
        0.0 as cy_primary_ppvs,
        0.0 as cy_net_units,
         0.0 as ly_search_ppvs,
        0.0 as ly_primary_ppvs,
        0.0 as ly_net_units ,

        0.0 as cy_ja_search_ppvs,
        0.0 as cy_ja_primary_ppvs,
        0.0 as cy_ja_net_units ,

        0.0 as ly_ja_search_ppvs,
        0.0 as ly_ja_primary_ppvs,
        0.0 as ly_ja_net_units,

         0.0 as cy_input_bau_weighted_asp,
        0.0 as cy_input_fes_weighted_asp,
        0.0 as cy_output_bau_weighted_asp,
        0.0 as cy_output_fes_weighted_asp,

        0.0 as ly_input_bau_weighted_asp,
        0.0 as ly_input_fes_weighted_asp,
        0.0 as ly_output_bau_weighted_asp,
        0.0 as ly_output_fes_weighted_asp,
        date_map.event_type as event_type


        from  bigfoot_external_neo.cp_bi_prod_sales__forward_unit_history_fact sales

        left join  fdp_uploads.ds_fkint_analytics_cdo_festive_date_mapping_1_1 as date_map

        on sales.order_date_key = date_map.dates_last_year	

        LEFT JOIN bigfoot_external_neo.sp_product__product_categorization_hive_dim cat
       ON  sales.product_id = cat.product_id
	   left join

(
SELECT 
 seller_id,
 MIN(managed_by) as owner
 FROM fdp_uploads.ds_fkint_analytics_cdo_seller_kam_ukam_mapping_1_0
 GROUP BY
 seller_id
) as t5
on sales.seller_id = t5.seller_id

LEFT JOIN
  fdp_uploads.ds_fkint_analytics_cdo_furniture_brand_mapping_analytics_1_0 fur_b
on lower(sales.analytic_super_category) = lower(fur_b.analytic_super_category)
and lower(sales.brand) = lower(fur_b.brand)
and lower(sales.analytic_vertical) = lower(fur_b.analytic_vertical)




        LEFT JOIN  fdp_uploads.ds_fkint_cp_santa_hyperlocal_vertical_bu_mapping_2_0 AS hl 

    ON sales.analytic_vertical = hl.analytic_vertical 
    AND LOWER(hl.bu_final) in ('bgm','home','furniture')  
    and sales.marketplace_id='HYPERLOCAL'

  LEFT JOIN bigfoot_external_neo.scp_ekl__logistics_geo_hive_dim geo 
        on sales.shipping_address_pincode_key =  geo.logistics_geo_hive_dim_key 

      
        LEFT JOIN
        fdp_uploads.ds_fkint_analytics_cdo_brand_d2c_home_mapping_1_0 home_b
        on lower(sales.analytic_super_category) = lower(home_b.analytic_super_category)
        and lower(sales.brand) = lower(home_b.brand)
     
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
    ) bgm_b
    ON LOWER(sales.analytic_super_category) = LOWER(bgm_b.analytic_super_category)
    AND LOWER(sales.brand) = LOWER(bgm_b.brand)


       
WHERE 
        LOWER(sales.status) IN ('in_progress', 'undelivered', 'completed', 'delivered', 'approved', 'shipped', 'ready_to_ship', 'returned', 'return_requested', 'activated')
        AND sales.type != 'service'
        AND sales.replacement_for_unit IS NULL
        AND sales.exchange_for_unit IS NULL
        AND sales.is_freebie = FALSE
        AND (sales.marketplace_id IN ('FLIPKART') OR (sales.marketplace_id = 'HYPERLOCAL' AND  hl.analytic_vertical IS NOT NULL))
        AND (sales.order_date_key BETWEEN 20240901 AND 20241031 )
        AND sales.analytic_business_unit IN ('BGM','Home','Furniture')
        AND sales.is_shopsy_order = FALSE

group by 
        date_map.dates_current_year,
        sales.marketplace_id ,
        cat.analytic_business_unit ,
        cat.analytic_super_category ,
        cat.analytic_vertical ,
        case when sales.is_alpha_seller = TRUE then 'Diamond' else 'Rest of MP' end ,

        case when sales.analytic_business_unit = 'BGM' and lower(bgm_b.branded_flag)='branded' then  bgm_b.brand
             when sales.analytic_business_unit = 'Home' and  (lower(home_b.type)='branded' or lower(home_b.type)='d2c') then home_b.brand 
             when sales.analytic_business_unit = 'Furniture' and lower(fur_b.branded_flag)='branded' then fur_b.brand else 'Unbranded' end ,
        geo.city_tier ,
        geo.zone ,



        CASE 
    WHEN sales.analytic_business_unit IN ('BGM', 'Home') THEN 
        (CASE 
            WHEN sales.gmv / sales.units <= 300 THEN '0-300'
            WHEN sales.gmv / sales.units <= 500 THEN '301-500'
            WHEN sales.gmv / sales.units <= 1000 THEN '501-1000'
            ELSE '1000+'
        END)
    WHEN sales.analytic_business_unit IN ('Furniture') THEN 
        (CASE 
            WHEN sales.gmv / sales.units <= 500 THEN '0-500'
            WHEN sales.gmv / sales.units <= 1000 THEN '501-1k'
            WHEN sales.gmv / sales.units <= 2500 THEN '1k-2.5k'
            WHEN sales.gmv / sales.units <= 5000 THEN '2.5k-5k'
            WHEN sales.gmv / sales.units <= 7500 THEN '5k-7.5k'
            WHEN sales.gmv / sales.units <= 10000 THEN '7.5k-10k'
            WHEN sales.gmv / sales.units <= 15000 THEN '10k-15k'
            ELSE '15k+'
        END)
END ,

case when t5.owner = 'KAM' then 'KAM' else 'N-KAM' end,

case when cat.analytic_business_unit = 'BGM' and lower(bgm_b.branded_flag)='branded' then  'Branded'
             when cat.analytic_business_unit = 'Home' and  (lower(home_b.type)='branded' or lower(home_b.type)='d2c') then 'Branded' 
             when cat.analytic_business_unit = 'Furniture' and lower(fur_b.branded_flag)='branded' then 'Branded' else 'Unbranded' end ,
             date_map.event_type,

    case 
     when sales.is_alpha_seller = TRUE and (lower(sales.source_facility_id)  like '%\\alite\\%') or (lower(sales.source_facility_id) like '%\\al\\%') then 'Alite'
        when sales.service_profile = 'FBF' then 'FBF' 
        when sales.service_profile in ('NON_FBF','FBF_LITE') then 'NFBF'
        else 'null'
        end


            
            union all 


            select 

            domain_name, 
        ss.order_date_key,
        marketplace,
        analytic_business_unit,
        analytic_super_category,
        analytic_vertical,
       is_alpha_seller,
       brand,
       city_tier, 
        zone,  
         price_point,

        kam_nkam_flag,
        branded_flag,
        0.0 as cy_gmv,
        0.0 as cy_units, 
        0.0 as ly_gmv,
        0.0 as ly_units,

        cy_ja_gmv,
        cy_ja_units,
        ly_ja_gmv, 
        ly_ja_units,


         0.0 as cy_search_ppvs,
        0.0 as cy_primary_ppvs,
        0.0 as cy_net_units,
         0.0 as ly_search_ppvs,
        0.0 as ly_primary_ppvs,
        0.0 as ly_net_units ,

        cy_ja_search_ppvs,
        cy_ja_primary_ppvs,
        cy_ja_net_units ,

        ly_ja_search_ppvs,
        ly_ja_primary_ppvs,
        ly_ja_net_units,

        0.0 as cy_input_bau_weighted_asp,
0.0 as cy_input_fes_weighted_asp,
0.0 as cy_output_bau_weighted_asp,
0.0 as cy_output_fes_weighted_asp,

0.0 as ly_input_bau_weighted_asp,
0.0 as ly_input_fes_weighted_asp,
0.0 as ly_output_bau_weighted_asp,
0.0 as ly_output_fes_weighted_asp,
date_map.event_type as event_type

        
        from bigfoot_external_neo.analytics_cdo__festive_rca_bau_ja_base_summary_fact as ss

        left join  fdp_uploads.ds_fkint_analytics_cdo_festive_date_mapping_1_1 as date_map
        on ss.order_date_key = date_map.dates_current_year

        

        union all 


        
        

        select 
        'current_year_festive_traffic' as domain_name,
        date_key as order_date_key, 
        base.marketplace_id as marketplace,
        cat.analytic_business_unit as analytic_business_unit,
        cat.analytic_super_category as analytic_super_category,
        cat.analytic_vertical as analytic_vertical,
        case when is_first_party_seller = TRUE then "Alpha" else "Mp" end as is_alpha_seller,

      case when cat.analytic_business_unit = 'BGM' and lower(bgm_b.branded_flag)='branded' then  bgm_b.brand
             when cat.analytic_business_unit = 'Home' and  (lower(home_b.type)='branded' or lower(home_b.type)='d2c') then home_b.brand 
             when cat.analytic_business_unit = 'Furniture' and lower(fur_b.branded_flag)='branded' then fur_b.brand else 'Unbranded' end  as brand,
        '' as city_tier, 
        '' as zone, 

     CASE 
    WHEN cat.analytic_business_unit IN ('BGM', 'Home') THEN 
        (CASE 
            WHEN base.fsp <= 300  THEN '0-300'
            WHEN base.fsp <= 500  THEN '301-500'
            WHEN base.fsp <= 1000  THEN '501-1000'
            ELSE '1000+'
        END)
    WHEN cat.analytic_business_unit IN ('Furniture') THEN 
        (CASE 
            WHEN base.fsp <= 500 THEN '0-500'
            WHEN base.fsp <= 1000 THEN '501-1k'
            WHEN base.fsp <= 2500 THEN '1k-2.5k'
            WHEN base.fsp <= 5000 THEN '2.5k-5k'
            WHEN base.fsp <= 7500 THEN '5k-7.5k'
            WHEN base.fsp <= 10000 THEN '7.5k-10k'
            WHEN base.fsp <= 15000 THEN '10k-15k'
            ELSE '15k+'
        END) end as price_point,

       case when t5.owner = 'KAM' then 'KAM' else 'N-KAM' end as kam_nkam_flag,

        case when cat.analytic_business_unit = 'BGM' and lower(bgm_b.branded_flag)='branded' then  "Branded"
             when cat.analytic_business_unit = 'Home' and  (lower(home_b.type)='branded' or lower(home_b.type)='d2c') then 'Branded' 
             when cat.analytic_business_unit = 'Furniture' and lower(fur_b.branded_flag)='branded' then 'Branded' else 'Unbranded' end  as brand,

        case 
        when base.service_profile = 'FBF' then 'FBF' 
        when base.service_profile in ('NON_FBF','FBF_LITE') then 'NFBF'
        else 'null' 
        end as service_profile,

        0.0 AS cy_gmv,
        0.0 AS cy_units,
        0.0 AS ly_gmv,
        0.0 as ly_units,
        0.0 as cy_ja_gmv,
        0.0 as cy_ja_units,
        0.0 as ly_ja_gmv, 
        0.0 as ly_ja_units,
        sum(search_ppvs) as cy_search_ppvs,
        sum(primary_ppvs) as cy_primary_ppvs,
        sum(net_units) as cy_net_units,
        0.0 as ly_search_ppvs,
        0.0 as ly_primary_ppvs,
        0.0 as ly_net_units ,

         0.0 as cy_ja_search_ppvs,
        0.0 as cy_ja_primary_ppvs,
        0.0 as cy_ja_net_units ,

        0.0 as ly_ja_search_ppvs,
        0.0 as ly_ja_primary_ppvs,
        0.0 as ly_ja_net_units,

        0.0 as cy_input_bau_weighted_asp,
0.0 as cy_input_fes_weighted_asp,
0.0 as cy_output_bau_weighted_asp,
0.0 as cy_output_fes_weighted_asp,

0.0 as ly_input_bau_weighted_asp,
0.0 as ly_input_fes_weighted_asp,
0.0 as ly_output_bau_weighted_asp,
0.0 as ly_output_fes_weighted_asp,
date_map.event_type as event_type


        from bigfoot_external_neo.cp_santa__listing_performance_at_day_level_with_sales_90d_fact base 

         left join  fdp_uploads.ds_fkint_analytics_cdo_festive_date_mapping_1_1 as date_map
        on base.date_key = date_map.dates_current_year

                LEFT JOIN bigfoot_external_neo.sp_product__product_categorization_hive_dim cat
       ON  base.product_id = cat.product_id
	   left join

(
SELECT 
 seller_id,
 MIN(managed_by) as owner
 FROM fdp_uploads.ds_fkint_analytics_cdo_seller_kam_ukam_mapping_1_0
 GROUP BY
 seller_id
) as t5
on base.seller_id = t5.seller_id

LEFT JOIN
  fdp_uploads.ds_fkint_analytics_cdo_furniture_brand_mapping_analytics_1_0 fur_b
on lower(base.analytic_super_category) = lower(fur_b.analytic_super_category)
and lower(base.brand) = lower(fur_b.brand)
and lower(base.analytic_vertical) = lower(fur_b.analytic_vertical)



        LEFT JOIN  fdp_uploads.ds_fkint_cp_santa_hyperlocal_vertical_bu_mapping_2_0 AS hl 

    ON base.analytic_vertical = hl.analytic_vertical 
    AND LOWER(hl.bu_final) in ('bgm','home','furniture')  
    and base.marketplace_id='HYPERLOCAL'

        LEFT JOIN
        fdp_uploads.ds_fkint_analytics_cdo_brand_d2c_home_mapping_1_0 home_b
        on lower(base.analytic_super_category) = lower(home_b.analytic_super_category)
        and lower(base.brand) = lower(home_b.brand)
     
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
    ) bgm_b

    ON LOWER(base.analytic_super_category) = LOWER(bgm_b.analytic_super_category)
    AND LOWER(base.brand) = LOWER(bgm_b.brand)


WHERE base.analytic_business_unit IN ('Home','BGM','Furniture')
AND (base.marketplace_id IN ('FLIPKART') OR (base.marketplace_id = 'HYPERLOCAL' AND  hl.analytic_vertical IS NOT NULL))
AND (date_key between 20250823 and CAST(FORMAT_DATE('%Y%m%d', DATE_SUB(CURRENT_DATE(), INTERVAL 1 DAY)) AS INT64) )

GROUP BY

       date_key ,
        base.marketplace_id ,
        cat.analytic_business_unit ,
        cat.analytic_super_category ,
        cat.analytic_vertical ,
        case when is_first_party_seller = TRUE then "Alpha" else "Mp" end ,

      case when cat.analytic_business_unit = 'BGM' and lower(bgm_b.branded_flag)='branded' then  bgm_b.brand
             when cat.analytic_business_unit = 'Home' and  (lower(home_b.type)='branded' or lower(home_b.type)='d2c') then home_b.brand 
             when cat.analytic_business_unit = 'Furniture' and lower(fur_b.branded_flag)='branded' then fur_b.brand else 'Unbranded' end ,

     CASE 
    WHEN cat.analytic_business_unit IN ('BGM', 'Home') THEN 
        (CASE 
            WHEN base.fsp <= 300  THEN '0-300'
            WHEN base.fsp <= 500  THEN '301-500'
            WHEN base.fsp <= 1000  THEN '501-1000'
            ELSE '1000+'
        END)
    WHEN cat.analytic_business_unit IN ('Furniture') THEN 
        (CASE 
            WHEN base.fsp <= 500 THEN '0-500'
            WHEN base.fsp <= 1000 THEN '501-1k'
            WHEN base.fsp <= 2500 THEN '1k-2.5k'
            WHEN base.fsp <= 5000 THEN '2.5k-5k'
            WHEN base.fsp <= 7500 THEN '5k-7.5k'
            WHEN base.fsp <= 10000 THEN '7.5k-10k'
            WHEN base.fsp <= 15000 THEN '10k-15k'
            ELSE '15k+'
        END) end ,

       case when t5.owner = 'KAM' then 'KAM' else 'N-KAM' end ,

       case when cat.analytic_business_unit = 'BGM' and lower(bgm_b.branded_flag)='branded' then  "Branded"
             when cat.analytic_business_unit = 'Home' and  (lower(home_b.type)='branded' or lower(home_b.type)='d2c') then 'Branded' 
             when cat.analytic_business_unit = 'Furniture' and lower(fur_b.branded_flag)='branded' then 'Branded' else 'Unbranded' end,
             event_type,
        case 
        when base.service_profile = 'FBF' then 'FBF' 
        when base.service_profile in ('NON_FBF','FBF_LITE') then 'NFBF'
        else 'null'
        end


        union all 

select 
        'last_year_festive_traffic' as domain_name,
       date_map.dates_current_year as order_date_key, 
         base.marketplace_id as marketplace,
        cat.analytic_business_unit as analytic_business_unit,
        cat.analytic_super_category as analytic_super_category,
        cat.analytic_vertical as analytic_vertical,
        case when is_first_party_seller = TRUE then "Alpha" else "Mp" end as is_alpha_seller,

      case when cat.analytic_business_unit = 'BGM' and lower(bgm_b.branded_flag)='branded' then  bgm_b.brand
             when cat.analytic_business_unit = 'Home' and  (lower(home_b.type)='branded' or lower(home_b.type)='d2c') then home_b.brand 
             when cat.analytic_business_unit = 'Furniture' and lower(fur_b.branded_flag)='branded' then fur_b.brand else 'Unbranded' end  as brand,
        '' as city_tier, 
        '' as zone, 

        CASE 
    WHEN cat.analytic_business_unit IN ('BGM', 'Home') THEN 
        (CASE 
            WHEN base.fsp <= 300  THEN '0-300'
            WHEN base.fsp <= 500  THEN '301-500'
            WHEN base.fsp <= 1000  THEN '501-1000'
            ELSE '1000+'
        END)
    WHEN cat.analytic_business_unit IN ('Furniture') THEN 
        (CASE 
            WHEN base.fsp <= 500 THEN '0-500'
            WHEN base.fsp <= 1000 THEN '501-1k'
            WHEN base.fsp <= 2500 THEN '1k-2.5k'
            WHEN base.fsp <= 5000 THEN '2.5k-5k'
            WHEN base.fsp <= 7500 THEN '5k-7.5k'
            WHEN base.fsp <= 10000 THEN '7.5k-10k'
            WHEN base.fsp <= 15000 THEN '10k-15k'
            ELSE '15k+'
        END) end as price_point,

       case when t5.owner = 'KAM' then 'KAM' else 'N-KAM' end as kam_nkam_flag,

       case when cat.analytic_business_unit = 'BGM' and lower(bgm_b.branded_flag)='branded' then  'Branded'
             when cat.analytic_business_unit = 'Home' and  (lower(home_b.type)='branded' or lower(home_b.type)='d2c') then 'Branded' 
             when cat.analytic_business_unit = 'Furniture' and lower(fur_b.branded_flag)='branded' then 'Branded' else 'Unbranded' end as branded_flag,

        case 
        when base.service_profile = 'FBF' then 'FBF' 
        when base.service_profile in ('NON_FBF','FBF_LITE') then 'NFBF'
        else 'null' 
        end as service_profile,


        0.0 AS cy_gmv,
        0.0 AS cy_units,
        0.0 AS ly_gmv,
        0.0 as ly_units,
        0.0 as cy_ja_gmv,
        0.0 as cy_ja_units,
        0.0 as ly_ja_gmv, 
        0.0 as ly_ja_units,

        0.0 as cy_search_ppvs,
        0.0 as cy_primary_ppvs,
        0.0 as cy_net_units,
    
        sum(search_ppvs) as ly_search_ppvs,
        sum(primary_ppvs) as ly_primary_ppvs,
        sum(net_units) as ly_net_units ,

         0.0 as cy_ja_search_ppvs,
        0.0 as cy_ja_primary_ppvs,
        0.0 as cy_ja_net_units ,

        0.0 as ly_ja_search_ppvs,
        0.0 as ly_ja_primary_ppvs,
        0.0 as ly_ja_net_units,

        0.0 as cy_input_bau_weighted_asp,
0.0 as cy_input_fes_weighted_asp,
0.0 as cy_output_bau_weighted_asp,
0.0 as cy_output_fes_weighted_asp,

0.0 as ly_input_bau_weighted_asp,
0.0 as ly_input_fes_weighted_asp,
0.0 as ly_output_bau_weighted_asp,
0.0 as ly_output_fes_weighted_asp,
date_map.event_type as event_type


from bigfoot_external_neo.cp_santa__listing_performance_at_day_level_with_sales_90d_fact base 

 left join  fdp_uploads.ds_fkint_analytics_cdo_festive_date_mapping_1_1 as date_map

        on base.date_key = date_map.dates_last_year	

             LEFT JOIN bigfoot_external_neo.sp_product__product_categorization_hive_dim cat
       ON  base.product_id = cat.product_id
	   left join

(
SELECT 
 seller_id,
 MIN(managed_by) as owner
 FROM fdp_uploads.ds_fkint_analytics_cdo_seller_kam_ukam_mapping_1_0
 GROUP BY
 seller_id
) as t5
on base.seller_id = t5.seller_id

LEFT JOIN
  fdp_uploads.ds_fkint_analytics_cdo_furniture_brand_mapping_analytics_1_0 fur_b
on lower(base.analytic_super_category) = lower(fur_b.analytic_super_category)
and lower(base.brand) = lower(fur_b.brand)
and lower(base.analytic_vertical) = lower(fur_b.analytic_vertical)



    LEFT JOIN  fdp_uploads.ds_fkint_cp_santa_hyperlocal_vertical_bu_mapping_2_0 AS hl 

    ON base.analytic_vertical = hl.analytic_vertical 
    AND LOWER(hl.bu_final) in ('bgm','home','furniture')  
    and base.marketplace_id='HYPERLOCAL'

        LEFT JOIN
        fdp_uploads.ds_fkint_analytics_cdo_brand_d2c_home_mapping_1_0 home_b
        on lower(base.analytic_super_category) = lower(home_b.analytic_super_category)
        and lower(base.brand) = lower(home_b.brand)
     
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
    ) bgm_b

    ON LOWER(base.analytic_super_category) = LOWER(bgm_b.analytic_super_category)
    AND LOWER(base.brand) = LOWER(bgm_b.brand)


WHERE base.analytic_business_unit IN ('Home','BGM','Furniture')
AND (base.marketplace_id IN ('FLIPKART') OR (base.marketplace_id = 'HYPERLOCAL' AND  hl.analytic_vertical IS NOT NULL))
AND date_key between 20240901 and 20241031 

GROUP BY
       date_map.dates_current_year ,
         base.marketplace_id ,
        cat.analytic_business_unit ,
        cat.analytic_super_category ,
        cat.analytic_vertical ,
        case when is_first_party_seller = TRUE then "Alpha" else "Mp" end ,

      case when cat.analytic_business_unit = 'BGM' and lower(bgm_b.branded_flag)='branded' then  bgm_b.brand
             when cat.analytic_business_unit = 'Home' and  (lower(home_b.type)='branded' or lower(home_b.type)='d2c') then home_b.brand 
             when cat.analytic_business_unit = 'Furniture' and lower(fur_b.branded_flag)='branded' then fur_b.brand else 'Unbranded' end  ,
    
        CASE 
    WHEN cat.analytic_business_unit IN ('BGM', 'Home') THEN 
        (CASE 
            WHEN base.fsp <= 300  THEN '0-300'
            WHEN base.fsp <= 500  THEN '301-500'
            WHEN base.fsp <= 1000  THEN '501-1000'
            ELSE '1000+'
        END)
    WHEN cat.analytic_business_unit IN ('Furniture') THEN 
        (CASE 
            WHEN base.fsp <= 500 THEN '0-500'
            WHEN base.fsp <= 1000 THEN '501-1k'
            WHEN base.fsp <= 2500 THEN '1k-2.5k'
            WHEN base.fsp <= 5000 THEN '2.5k-5k'
            WHEN base.fsp <= 7500 THEN '5k-7.5k'
            WHEN base.fsp <= 10000 THEN '7.5k-10k'
            WHEN base.fsp <= 15000 THEN '10k-15k'
            ELSE '15k+'
        END) end ,

       case when t5.owner = 'KAM' then 'KAM' else 'N-KAM' end ,

       case when cat.analytic_business_unit = 'BGM' and lower(bgm_b.branded_flag)='branded' then  'Branded'
             when cat.analytic_business_unit = 'Home' and  (lower(home_b.type)='branded' or lower(home_b.type)='d2c') then 'Branded' 
             when cat.analytic_business_unit = 'Furniture' and lower(fur_b.branded_flag)='branded' then 'Branded' else 'Unbranded' end ,
             date_map.event_type,
        case 
        when base.service_profile = 'FBF' then 'FBF' 
        when base.service_profile in ('NON_FBF','FBF_LITE') then 'NFBF'
        else 'null'
        end



        union all 


        

SELECT
'current_year_pricing' as domain_flag,
order_date_key as order_date_key,
marketplace as marketplace,
analytic_business_unit as analytic_business_unit,
analytic_super_category as analytic_super_category,
analytic_vertical as analytic_vertical,
is_alpha_seller as is_alpha_seller,
brand, 
city_tier, 
zone, 

       CASE 
    WHEN analytic_business_unit IN ('BGM', 'Home') THEN 
        (CASE 
            WHEN bau_price_point <= 300  THEN '0-300'
            WHEN bau_price_point <= 500  THEN '301-500'
            WHEN bau_price_point<= 1000  THEN '501-1000'
            ELSE '1000+'
        END)
    WHEN analytic_business_unit IN ('Furniture') THEN 
        (CASE 
            WHEN bau_price_point <= 500 THEN '0-500'
            WHEN bau_price_point <= 1000 THEN '501-1k'
            WHEN bau_price_point <= 2500 THEN '1k-2.5k'
            WHEN bau_price_point <= 5000 THEN '2.5k-5k'
            WHEN bau_price_point <= 7500 THEN '5k-7.5k'
            WHEN bau_price_point <= 10000 THEN '7.5k-10k'
            WHEN bau_price_point <= 15000 THEN '10k-15k'
            ELSE '15k+'
        END) end as price_point,
        kam_nkam_flag,
        branded_flag,

        0.0 AS cy_gmv,
        0.0 AS cy_units,

        0.0 AS ly_gmv,
        0.0 as ly_units,

        0.0 as cy_ja_gmv,
        0.0 as cy_ja_units,

        0.0 as ly_ja_gmv, 
        0.0 as ly_ja_units,

        0.0 as cy_search_ppvs,
        0.0 as cy_primary_ppvs,
        0.0 as cy_net_units,
    
        0.0 as ly_search_ppvs,
        0.0 as ly_primary_ppvs,
        0.0 as ly_net_units,

        0.0 as cy_ja_search_ppvs,
        0.0 as cy_ja_primary_ppvs,
        0.0 as cy_ja_net_units ,

        0.0 as ly_ja_search_ppvs,
        0.0 as ly_ja_primary_ppvs,
        0.0 as ly_ja_net_units,


SUM(input_bau_weighted_asp) as cy_input_bau_weighted_asp,
SUM(input_fes_weighted_asp) as cy_input_fes_weighted_asp,
SUM(output_bau_weighted_asp) as cy_output_bau_weighted_asp,
SUM(output_fes_weighted_asp) as cy_output_fes_weighted_asp,


0.0 as ly_input_bau_weighted_asp,
0.0 as ly_input_fes_weighted_asp,
0.0 as ly_output_bau_weighted_asp,
0.0 as ly_output_fes_weighted_asp,
event_type as event_type



FROM
(
SELECT
    bau.marketplace,
    bau.analytic_business_unit as analytic_business_unit,
    bau.analytic_super_category as analytic_super_category,
    bau.analytic_vertical as analytic_vertical,
    bau.is_alpha_seller as is_alpha_seller, 
    bau.brand as brand, 
    bau.city_tier as city_tier, 
    bau.zone as zone, 
    bau.kam_nkam_flag as kam_nkam_flag,
    bau.branded_flag as branded_flag,
    fes.event_type as event_type,
  
  bau.product_id as product_id,
  bau.listing_id as listing_id,
  fes.order_date_key as order_date_key,
  bau.gmv/bau.units as bau_price_point,

  (bau.gmv/bau.units)*bau.units as input_bau_weighted_asp,
  (fes.gmv/fes.units)*bau.units as input_fes_weighted_asp,
  (bau.gmv/bau.units)*fes.units as output_bau_weighted_asp,
  (fes.gmv/fes.units)*fes.units as output_fes_weighted_asp

FROM
(
SELECT
sales.marketplace_id as marketplace,
  cat.analytic_business_unit,
  cat.analytic_super_category,
  cat.analytic_vertical,
   case when sales.is_alpha_seller = TRUE then 'Diamond' else 'Rest of MP' end as is_alpha_seller,

  
      case when cat.analytic_business_unit = 'BGM' and lower(bgm_b.branded_flag)='branded' then  bgm_b.brand
             when cat.analytic_business_unit = 'Home' and  (lower(home_b.type)='branded' or lower(home_b.type)='d2c') then home_b.brand 
             when cat.analytic_business_unit = 'Furniture' and lower(fur_b.branded_flag)='branded' then fur_b.brand else 'Unbranded' end brand,

              case when cat.analytic_business_unit = 'BGM' and lower(bgm_b.branded_flag)='branded' then  'Branded'
             when cat.analytic_business_unit = 'Home' and  (lower(home_b.type)='branded' or lower(home_b.type)='d2c') then 'Branded' 
             when cat.analytic_business_unit = 'Furniture' and lower(fur_b.branded_flag)='branded' then 'Branded' else 'Unbranded' end branded_flag,

    case when sales.is_alpha_seller = TRUE and (lower(sales.source_facility_id)  like '%\\alite\\%') or (lower(sales.source_facility_id) like '%\\al\\%') then 'Alite'
        when sales.service_profile = 'FBF' then 'FBF' 
        when sales.service_profile in ('NON_FBF','FBF_LITE') then 'NFBF'
        else 'null' 
    end as service_profile,

    geo.city_tier as city_tier, 
    geo.zone as zone,  
    case when t5.owner = 'KAM' then 'KAM' else 'N-KAM' end as kam_nkam_flag,
  sales.product_id,
  sales.listing_id,


  SUM(units)/62 as units,
  SUM(gmv)/62 as gmv,
  SUM(listing_price) as lp

FROM bigfoot_external_neo.cp_bi_prod_sales__forward_unit_history_fact sales

             LEFT JOIN bigfoot_external_neo.sp_product__product_categorization_hive_dim cat
       ON  sales.product_id = cat.product_id
	   left join

(
SELECT 
 seller_id,
 MIN(managed_by) as owner
 FROM fdp_uploads.ds_fkint_analytics_cdo_seller_kam_ukam_mapping_1_0
 GROUP BY
 seller_id
) as t5
on sales.seller_id = t5.seller_id

LEFT JOIN
  fdp_uploads.ds_fkint_analytics_cdo_furniture_brand_mapping_analytics_1_0 as fur_b
on lower(cat.analytic_super_category) = lower(fur_b.analytic_super_category)
and lower(cat.brand) = lower(fur_b.brand)
and lower(cat.analytic_vertical) = lower(fur_b.analytic_vertical)



  LEFT JOIN bigfoot_external_neo.scp_ekl__logistics_geo_hive_dim geo 
        on sales.shipping_address_pincode_key =  geo.logistics_geo_hive_dim_key 

      
        LEFT JOIN
        fdp_uploads.ds_fkint_analytics_cdo_brand_d2c_home_mapping_1_0 home_b
        on lower(sales.analytic_super_category) = lower(home_b.analytic_super_category)
        and lower(sales.brand) = lower(home_b.brand)
     
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
    ) bgm_b
    ON LOWER(sales.analytic_super_category) = LOWER(bgm_b.analytic_super_category)
    AND LOWER(sales.brand) = LOWER(bgm_b.brand)


    WHERE lower(sales.status) in ('in_progress','undelivered','completed','delivered','approved','shipped','ready_to_ship','returned', 'return_requested','activated')
    AND sales.type !='service'
    AND sales.replacement_for_unit IS NULL
    AND sales.exchange_for_unit IS NULL
    AND sales.is_freebie =FALSE
    AND (sales.marketplace_id IN ('FLIPKART'))
    AND sales.is_shopsy_order =FALSE
    AND sales.analytic_business_unit IN ('BGM','Home','Furniture')
    AND order_date_key between 20250701 and 20250831

GROUP BY
   sales.marketplace_id ,
  cat.analytic_business_unit,
  cat.analytic_super_category,
  cat.analytic_vertical,
   case when sales.is_alpha_seller = TRUE then 'Diamond' else 'Rest of MP' end ,
      case when cat.analytic_business_unit = 'BGM' and lower(bgm_b.branded_flag)='branded' then  bgm_b.brand
             when cat.analytic_business_unit = 'Home' and  (lower(home_b.type)='branded' or lower(home_b.type)='d2c') then home_b.brand 
             when cat.analytic_business_unit = 'Furniture' and lower(fur_b.branded_flag)='branded' then fur_b.brand else 'Unbranded' end ,

             case when cat.analytic_business_unit = 'BGM' and lower(bgm_b.branded_flag)='branded' then  'Branded'
             when cat.analytic_business_unit = 'Home' and  (lower(home_b.type)='branded' or lower(home_b.type)='d2c') then 'Branded' 
             when cat.analytic_business_unit = 'Furniture' and lower(fur_b.branded_flag)='branded' then 'Branded' else 'Unbranded' end,

    geo.city_tier,
    geo.zone , 
    case when t5.owner = 'KAM' then 'KAM' else 'N-KAM' end ,
  sales.product_id,
  sales.listing_id,
  case when sales.is_alpha_seller = TRUE and (lower(sales.source_facility_id)  like '%\\alite\\%') or (lower(sales.source_facility_id) like '%\\al\\%') then 'Alite'
        when sales.service_profile = 'FBF' then 'FBF' 
        when sales.service_profile in ('NON_FBF','FBF_LITE') then 'NFBF'
        else 'null' end


)   bau

INNER JOIN

(
SELECT
  sales.listing_id,
  order_date_key,
   SUM(units) as units,
  SUM(gmv) as gmv,
  SUM(listing_price) as lp,

 date_map.event_type as event_type
 
FROM bigfoot_external_neo.cp_bi_prod_sales__forward_unit_history_fact sales

left join  fdp_uploads.ds_fkint_analytics_cdo_festive_date_mapping_1_1 as date_map
        on sales.order_date_key = date_map.dates_current_year



WHERE lower(sales.status) in ('in_progress','undelivered','completed','delivered','approved','shipped','ready_to_ship','returned', 'return_requested','activated')
  AND sales.type !='service'
  AND sales.replacement_for_unit IS NULL
  AND sales.exchange_for_unit IS NULL
  AND sales.is_freebie =FALSE
AND (sales.marketplace_id IN ('FLIPKART'))
  AND sales.is_shopsy_order =FALSE
  AND sales.analytic_business_unit IN ('BGM','Home','Furniture')
  AND order_date_key between 20250823 and CAST(FORMAT_DATE('%Y%m%d', DATE_SUB(CURRENT_DATE(), INTERVAL 1 DAY)) AS INT64)


GROUP BY
  sales.listing_id,
  order_date_key,
   date_map.event_type
) fes
ON bau.listing_id = fes.listing_id

) sub

GROUP BY

order_date_key ,
marketplace ,
analytic_business_unit,
analytic_super_category,
analytic_vertical ,
is_alpha_seller ,
brand, 
city_tier, 
zone, 

       CASE 
    WHEN analytic_business_unit IN ('BGM', 'Home') THEN 
        (CASE 
            WHEN bau_price_point <= 300  THEN '0-300'
            WHEN bau_price_point <= 500  THEN '301-500'
            WHEN bau_price_point<= 1000  THEN '501-1000'
            ELSE '1000+'
        END)
    WHEN analytic_business_unit IN ('Furniture') THEN 
        (CASE 
            WHEN bau_price_point <= 500 THEN '0-500'
            WHEN bau_price_point <= 1000 THEN '501-1k'
            WHEN bau_price_point <= 2500 THEN '1k-2.5k'
            WHEN bau_price_point <= 5000 THEN '2.5k-5k'
            WHEN bau_price_point <= 7500 THEN '5k-7.5k'
            WHEN bau_price_point <= 10000 THEN '7.5k-10k'
            WHEN bau_price_point <= 15000 THEN '10k-15k'
            ELSE '15k+'
        END) end ,
        kam_nkam_flag,
        branded_flag,
        event_type



        
        union all 




SELECT
'last_year_pricing' as domain_flag,
order_date_key as order_date_key,
marketplace as marketplace,
analytic_business_unit as analytic_business_unit,
analytic_super_category as analytic_super_category,
analytic_vertical as analytic_vertical,
is_alpha_seller as is_alpha_seller,
brand, 
city_tier, 
zone, 
   CASE 
    WHEN analytic_business_unit IN ('BGM', 'Home') THEN 
        (CASE 
            WHEN bau_price_point <= 300  THEN '0-300'
            WHEN bau_price_point <= 500  THEN '301-500'
            WHEN bau_price_point<= 1000  THEN '501-1000'
            ELSE '1000+'
        END)
    WHEN analytic_business_unit IN ('Furniture') THEN 
        (CASE 
            WHEN bau_price_point <= 500 THEN '0-500'
            WHEN bau_price_point <= 1000 THEN '501-1k'
            WHEN bau_price_point <= 2500 THEN '1k-2.5k'
            WHEN bau_price_point <= 5000 THEN '2.5k-5k'
            WHEN bau_price_point <= 7500 THEN '5k-7.5k'
            WHEN bau_price_point <= 10000 THEN '7.5k-10k'
            WHEN bau_price_point <= 15000 THEN '10k-15k'
            ELSE '15k+'
        END) end  as price_point,
         kam_nkam_flag,
         branded_flag,

        0.0 AS cy_gmv,
        0.0 AS cy_units,

        0.0 AS ly_gmv,
        0.0 as ly_units,

        0.0 as cy_ja_gmv,
        0.0 as cy_ja_units,

        0.0 as ly_ja_gmv, 
        0.0 as ly_ja_units,

        0.0 as cy_search_ppvs,
        0.0 as cy_primary_ppvs,
        0.0 as cy_net_units,
    
        0.0 as ly_search_ppvs,
        0.0 as ly_primary_ppvs,
        0.0 as ly_net_units,

        0.0 as cy_ja_search_ppvs,
        0.0 as cy_ja_primary_ppvs,
        0.0 as cy_ja_net_units ,

        0.0 as ly_ja_search_ppvs,
        0.0 as ly_ja_primary_ppvs,
        0.0 as ly_ja_net_units,


0.0 as cy_input_bau_weighted_asp,
0.0 as cy_input_fes_weighted_asp,
0.0 as cy_output_bau_weighted_asp,
0.0 as cy_output_fes_weighted_asp,

SUM(input_bau_weighted_asp) as ly_input_bau_weighted_asp,
SUM(input_fes_weighted_asp) as ly_input_fes_weighted_asp,
SUM(output_bau_weighted_asp) as ly_output_bau_weighted_asp,
SUM(output_fes_weighted_asp) as ly_output_fes_weighted_asp,
event_type as event_type



FROM
(
SELECT
    bau.marketplace as marketplace,
    bau.analytic_business_unit as analytic_business_unit,
    bau.analytic_super_category as analytic_super_category,
    bau.analytic_vertical as analytic_vertical,
    bau.is_alpha_seller as is_alpha_seller, 
    bau.brand as brand, 
    bau.city_tier as city_tier, 
    bau.zone as zone, 
    bau.kam_nkam_flag,
    bau.branded_flag as branded_flag,
    fes.event_type as event_type,
    
  
  bau.product_id as product_id,
  bau.listing_id as listing_id,
  fes.order_date_key as order_date_key,
  bau.gmv/bau.units as bau_price_point,

  (bau.gmv/bau.units)*bau.units as input_bau_weighted_asp,
  (fes.gmv/fes.units)*bau.units as input_fes_weighted_asp,
  (bau.gmv/bau.units)*fes.units as output_bau_weighted_asp,
  (fes.gmv/fes.units)*fes.units as output_fes_weighted_asp

FROM
(
SELECT
sales.marketplace_id as marketplace,
   cat.analytic_business_unit as analytic_business_unit,
  cat.analytic_super_category as analytic_super_category,
  cat.analytic_vertical as analytic_vertical,
   case when sales.is_alpha_seller = TRUE then 'Diamond' else 'Rest of MP' end as is_alpha_seller,
      case when cat.analytic_business_unit = 'BGM' and lower(bgm_b.branded_flag)='branded' then  bgm_b.brand
             when cat.analytic_business_unit = 'Home' and  (lower(home_b.type)='branded' or lower(home_b.type)='d2c') then home_b.brand 
             when cat.analytic_business_unit = 'Furniture' and lower(fur_b.branded_flag)='branded' then fur_b.brand else 'Unbranded' end as brand ,

              case when cat.analytic_business_unit = 'BGM' and lower(bgm_b.branded_flag)='branded' then  'Branded'
             when cat.analytic_business_unit = 'Home' and  (lower(home_b.type)='branded' or lower(home_b.type)='d2c') then 'Branded' 
             when cat.analytic_business_unit = 'Furniture' and lower(fur_b.branded_flag)='branded' then 'Branded' else 'Unbranded' end as branded_flag,

    case 
     when sales.is_alpha_seller = TRUE and (lower(sales.source_facility_id)  like '%\\alite\\%') or (lower(sales.source_facility_id) like '%\\al\\%') then 'Alite'
        when sales.service_profile = 'FBF' then 'FBF' 
        when sales.service_profile in ('NON_FBF','FBF_LITE') then 'NFBF'
        else 'null' 
    end as service_profile,

    geo.city_tier as city_tier,
    geo.zone as zone , 
    case when t5.owner = 'KAM' then 'KAM' else 'N-KAM' end as kam_nkam_flag, 
  sales.product_id,
  sales.listing_id,


  SUM(units)/62 as units,
  SUM(gmv)/62 as gmv,
  SUM(listing_price) as lp

FROM bigfoot_external_neo.cp_bi_prod_sales__forward_unit_history_fact sales


LEFT JOIN bigfoot_external_neo.sp_product__product_categorization_hive_dim cat
       ON  sales.product_id = cat.product_id
	   left join

(
SELECT 
 seller_id,
 MIN(managed_by) as owner
 FROM fdp_uploads.ds_fkint_analytics_cdo_seller_kam_ukam_mapping_1_0
 GROUP BY
 seller_id
) as t5
on sales.seller_id = t5.seller_id

LEFT JOIN
  fdp_uploads.ds_fkint_analytics_cdo_furniture_brand_mapping_analytics_1_0 as fur_b
on lower(cat.analytic_super_category) = lower(fur_b.analytic_super_category)
and lower(cat.brand) = lower(fur_b.brand)
and lower(cat.analytic_vertical) = lower(fur_b.analytic_vertical)



  LEFT JOIN bigfoot_external_neo.scp_ekl__logistics_geo_hive_dim geo 
        on sales.shipping_address_pincode_key =  geo.logistics_geo_hive_dim_key 

      
        LEFT JOIN
        fdp_uploads.ds_fkint_analytics_cdo_brand_d2c_home_mapping_1_0 home_b
        on lower(sales.analytic_super_category) = lower(home_b.analytic_super_category)
        and lower(sales.brand) = lower(home_b.brand)
     
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
    ) bgm_b
    ON LOWER(sales.analytic_super_category) = LOWER(bgm_b.analytic_super_category)
    AND LOWER(sales.brand) = LOWER(bgm_b.brand)


    WHERE lower(sales.status) in ('in_progress','undelivered','completed','delivered','approved','shipped','ready_to_ship','returned', 'return_requested','activated')
    AND sales.type !='service'
    AND sales.replacement_for_unit IS NULL
    AND sales.exchange_for_unit IS NULL
    AND sales.is_freebie =FALSE
    AND (sales.marketplace_id IN ('FLIPKART'))
    AND sales.is_shopsy_order =FALSE
    AND sales.analytic_business_unit IN ('BGM','Home','Furniture')
    AND order_date_key between 20240701 and 20240831

GROUP BY
    sales.marketplace_id ,
       cat.analytic_business_unit,
  cat.analytic_super_category,
  cat.analytic_vertical,
   case when sales.is_alpha_seller = TRUE then 'Diamond' else 'Rest of MP' end,
      case when cat.analytic_business_unit = 'BGM' and lower(bgm_b.branded_flag)='branded' then  bgm_b.brand
             when cat.analytic_business_unit = 'Home' and  (lower(home_b.type)='branded' or lower(home_b.type)='d2c') then home_b.brand 
             when cat.analytic_business_unit = 'Furniture' and lower(fur_b.branded_flag)='branded' then fur_b.brand else 'Unbranded' end,

    case when cat.analytic_business_unit = 'BGM' and lower(bgm_b.branded_flag)='branded' then  'Branded'
             when cat.analytic_business_unit = 'Home' and  (lower(home_b.type)='branded' or lower(home_b.type)='d2c') then 'Branded' 
             when cat.analytic_business_unit = 'Furniture' and lower(fur_b.branded_flag)='branded' then 'Branded' else 'Unbranded' end,

    geo.city_tier,
    geo.zone,
    case when t5.owner = 'KAM' then 'KAM' else 'N-KAM' end ,
  sales.product_id,
  sales.listing_id,
    case 
     when sales.is_alpha_seller = TRUE and (lower(sales.source_facility_id)  like '%\\alite\\%') or (lower(sales.source_facility_id) like '%\\al\\%') then 'Alite'
        when sales.service_profile = 'FBF' then 'FBF' 
        when sales.service_profile in ('NON_FBF','FBF_LITE') then 'NFBF'
        else 'null' 
    end 


)   bau

INNER JOIN

(
SELECT
  sales.listing_id,
  date_map.dates_current_year as order_date_key,
  
   SUM(units) as units,
  SUM(gmv) as gmv,
  SUM(listing_price) as lp,
  date_map.event_type as event_type

 
FROM bigfoot_external_neo.cp_bi_prod_sales__forward_unit_history_fact sales


 left join fdp_uploads.ds_fkint_analytics_cdo_festive_date_mapping_1_1 as date_map

        on sales.order_date_key = date_map.dates_last_year	

WHERE lower(sales.status) in ('in_progress','undelivered','completed','delivered','approved','shipped','ready_to_ship','returned', 'return_requested','activated')
  AND sales.type !='service'
  AND sales.replacement_for_unit IS NULL
  AND sales.exchange_for_unit IS NULL
  AND sales.is_freebie =FALSE
  AND sales.marketplace_id IN ('FLIPKART')
  AND sales.is_shopsy_order =FALSE
  AND sales.analytic_business_unit IN ('BGM','Home','Furniture')
  AND order_date_key between 20240901 and 20241031


GROUP BY
  sales.listing_id,
  date_map.dates_current_year,
  date_map.event_type

) fes
ON bau.listing_id = fes.listing_id

) sub

GROUP BY
order_date_key ,
marketplace,
analytic_business_unit ,
analytic_super_category ,
analytic_vertical ,
is_alpha_seller ,
brand, 
city_tier, 
zone, 
   CASE 
    WHEN analytic_business_unit IN ('BGM', 'Home') THEN 
        (CASE 
            WHEN bau_price_point <= 300  THEN '0-300'
            WHEN bau_price_point <= 500  THEN '301-500'
            WHEN bau_price_point<= 1000  THEN '501-1000'
            ELSE '1000+'
        END)
    WHEN analytic_business_unit IN ('Furniture') THEN 
        (CASE 
            WHEN bau_price_point <= 500 THEN '0-500'
            WHEN bau_price_point <= 1000 THEN '501-1k'
            WHEN bau_price_point <= 2500 THEN '1k-2.5k'
            WHEN bau_price_point <= 5000 THEN '2.5k-5k'
            WHEN bau_price_point <= 7500 THEN '5k-7.5k'
            WHEN bau_price_point <= 10000 THEN '7.5k-10k'
            WHEN bau_price_point <= 15000 THEN '10k-15k'
            ELSE '15k+'
        END) end  ,
         kam_nkam_flag,
         branded_flag,
         event_type

  ) as festive_dates