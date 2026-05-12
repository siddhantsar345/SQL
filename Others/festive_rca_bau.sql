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
        service_profile

from
(

(
select 
        'current_year_july_august_sales' as domain_name,
        festive.order_date_key as order_date_key,
        base.marketplace as marketplace,
        base.analytic_business_unit as analytic_business_unit,
        base.analytic_super_category as analytic_super_category,
        analytic_vertical as analytic_vertical,
        is_alpha_seller as is_alpha_seller,
        brand as brand,
        city_tier as city_tier, 
        zone as zone,  
        price_point as price_point,
        kam_nkam_flag as kam_nkam_flag,
        branded_flag as branded_flag,
        base.service_profile as service_profile, 
        0.0 AS cy_gmv,
        0.0 AS cy_units,
        0.0 AS ly_gmv,
        0.0 as ly_units,
        base.ja_gmv as cy_ja_gmv,
        base.ja_units as cy_ja_units,
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

        0.0  as ly_ja_search_ppvs,
        0.0  as ly_ja_primary_ppvs,
         0.0  as ly_ja_net_units


  from

    (

   Select 
   date_dim_key as order_date_key
   from 
  bigfoot_external_neo.scp_oms__date_dim_fact date_dim

  where date_dim_key BETWEEN 20250823 AND 20251022

    ) as festive

 cross join

(
select
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
        
        SUM(sales.gmv / 62) AS ja_gmv,
        SUM(sales.units / 62) AS ja_units
    FROM 
        bigfoot_external_neo.cp_bi_prod_sales__forward_unit_history_fact sales


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
        AND (sales.order_date_key BETWEEN 20250701 AND 20250831)
        AND sales.analytic_business_unit IN ('BGM','Home','Furniture')
        AND sales.is_shopsy_order = FALSE


    GROUP BY
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
            ELSE '15k+'
        END)
END ,

case when t5.owner = 'KAM' then 'KAM' else 'N-KAM' end ,

 case when cat.analytic_business_unit = 'BGM' and lower(bgm_b.branded_flag)='branded' then  'Branded'
             when cat.analytic_business_unit = 'Home' and  (lower(home_b.type)='branded' or lower(home_b.type)='d2c') then 'Branded' 
             when cat.analytic_business_unit = 'Furniture' and lower(fur_b.branded_flag)='branded' then 'Branded' else 'Unbranded' end ,
    case 
     when sales.is_alpha_seller = TRUE and (lower(sales.source_facility_id)  like '%\\alite\\%') or (lower(sales.source_facility_id) like '%\\al\\%') then 'Alite'
        when sales.service_profile = 'FBF' then 'FBF' 
        when sales.service_profile in ('NON_FBF','FBF_LITE') then 'NFBF'
        else 'null' 
    end 
) 
 as base 
)


union all 



(

select 
        'last_year_july_august_sales' as domain_name,
        festive.order_date_key as order_date_key,
        base.marketplace as marketplace,
        base.analytic_business_unit as analytic_business_unit,
        base.analytic_super_category as analytic_super_category,
        base.analytic_vertical as analytic_vertical,
        base.is_alpha_seller as is_alpha_seller,
        base.brand as brand,
        base.city_tier as city_tier, 
        base.zone as zone,  
        base.price_point as price_point,
        base.kam_nkam_flag as kam_nkam_flag,
        base.branded_flag as branded_flag,
        base.service_profile as service_profile,
        0.0 AS cy_gmv,
        0.0 AS cy_units,
        0.0 AS ly_gmv,
        0.0 as ly_units,
        0.0 as cy_ja_gmv,
        0.0 as cy_ja_units,
        base.ja_gmv as ly_ja_gmv, 
        base.ja_units as ly_ja_units,
        0.0 as cy_search_ppvs,
        0.0 as cy_primary_ppvs,
        0.0 as cy_net_units,
        0.0 as ly_search_ppvs,
        0.0 as ly_primary_ppvs,
        0.0 as ly_net_units ,
        0.0 as cy_ja_search_ppvs,
        0.0 as cy_ja_primary_ppvs,
        0.0 as cy_ja_net_units ,
        0.0  as ly_ja_search_ppvs,
        0.0  as ly_ja_primary_ppvs,
         0.0  as ly_ja_net_units

  
  from
    (
   Select 
   date_dim_key as order_date_key
   from 
  bigfoot_external_neo.scp_oms__date_dim_fact date_dim
  where date_dim_key BETWEEN 20250823 AND 20251022

    ) as festive

 cross join

(
select
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
        SUM(sales.gmv / 62) AS ja_gmv,
        SUM(sales.units / 62) AS ja_units
    FROM 
        bigfoot_external_neo.cp_bi_prod_sales__forward_unit_history_fact sales

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
        AND (sales.order_date_key BETWEEN 20240701 AND 20240831)
        AND sales.analytic_business_unit IN ('BGM','Home','Furniture')
        AND sales.is_shopsy_order = FALSE


    GROUP BY
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
            ELSE '15k+'
        END)
END ,

case when t5.owner = 'KAM' then 'KAM' else 'N-KAM' end ,

 case when cat.analytic_business_unit = 'BGM' and lower(bgm_b.branded_flag)='branded' then  'Branded'
             when cat.analytic_business_unit = 'Home' and  (lower(home_b.type)='branded' or lower(home_b.type)='d2c') then 'Branded' 
             when cat.analytic_business_unit = 'Furniture' and lower(fur_b.branded_flag)='branded' then 'Branded' else 'Unbranded' end ,
    case 
     when sales.is_alpha_seller = TRUE and (lower(sales.source_facility_id)  like '%\\alite\\%') or (lower(sales.source_facility_id) like '%\\al\\%') then 'Alite'
        when sales.service_profile = 'FBF' then 'FBF' 
        when sales.service_profile in ('NON_FBF','FBF_LITE') then 'NFBF'
        else 'null' 
    end 
) as base )

            
    union all 

(
    
select 

'current_year_july_august_traffic' as domain_name, 
        festive.order_date_key as order_date_key,
        marketplace as marketplace,
       analytic_business_unit as analytic_business_unit,
       analytic_super_category as analytic_super_category,
        analytic_vertical as analytic_vertical,
        is_alpha_seller as is_alpha_seller,
        brand as brand,
        city_tier as city_tier, 
        zone as zone,  
        price_point as price_point,
        kam_nkam_flag as kam_nkam_flag,
        branded_flag as branded_flag,
        base.service_profile as service_profile,
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
        0.0 as ly_net_units ,

        cy_ja_search_ppvs,
        cy_ja_primary_ppvs,
        cy_ja_net_units ,

        0.0  as ly_ja_search_ppvs,
        0.0  as ly_ja_primary_ppvs,
        0.0  as ly_ja_net_units


from 



   (
   Select 
   date_dim_key as order_date_key
   from 
  bigfoot_external_neo.scp_oms__date_dim_fact date_dim
  where date_dim_key BETWEEN 20250823 AND 20251022

    ) as festive

 cross join

(
select 
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
             when cat.analytic_business_unit = 'Furniture' and lower(fur_b.branded_flag)='branded' then 'Branded' else 'Unbranded' end  as branded_flag,

       case 
             when base.service_profile = 'FBF' then 'FBF' 
             when base.service_profile in ('NON_FBF','FBF_LITE') then 'NFBF'
        else 'null' 
        end as service_profile,
        0.0 as cy_search_ppvs,
        0.0 as cy_primary_ppvs,
        0.0 as cy_net_units,

        0.0 as ly_search_ppvs,
        0.0 as ly_primary_ppvs,
        0.0 as ly_net_units ,


        sum(search_ppvs)/62 as cy_ja_search_ppvs,
        sum(primary_ppvs)/62 as cy_ja_primary_ppvs,
        sum(net_units)/62 as cy_ja_net_units 


from bigfoot_external_neo.cp_santa__listing_performance_at_day_level_with_sales_90d_fact base 


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
AND date_key between 20250701 and 20250831 

GROUP BY

         base.marketplace_id ,
        cat.analytic_business_unit,
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

        case when cat.analytic_business_unit = 'BGM' and lower(bgm_b.branded_flag)='branded' then  "Branded"
             when cat.analytic_business_unit = 'Home' and  (lower(home_b.type)='branded' or lower(home_b.type)='d2c') then 'Branded' 
             when cat.analytic_business_unit = 'Furniture' and lower(fur_b.branded_flag)='branded' then 'Branded' else 'Unbranded' end,

        case 
             when base.service_profile = 'FBF' then 'FBF' 
             when base.service_profile in ('NON_FBF','FBF_LITE') then 'NFBF'
             else 'null' 
        end

) as base

)

    union all 

(
select 

'last_year_july_august_traffic' as domain_name, 
        festive.order_date_key as order_date_key,
        marketplace as marketplace,
       analytic_business_unit as analytic_business_unit,
       analytic_super_category as analytic_super_category,
        analytic_vertical as analytic_vertical,
        is_alpha_seller as is_alpha_seller,
        brand as brand,
        city_tier as city_tier, 
        zone as zone,  
        price_point as price_point,
        kam_nkam_flag as kam_nkam_flag,
        branded_flag as branded_flag,
        base.service_profile as service_profile,
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
        0.0 as ly_net_units ,

        0.0  as cy_ja_search_ppvs,
        0.0  as cy_ja_primary_ppvs,
        0.0  as cy_ja_net_units ,

        ly_ja_search_ppvs,
        ly_ja_primary_ppvs,
        ly_ja_net_units

from 



   (
   Select 
   date_dim_key as order_date_key
   from 
  bigfoot_external_neo.scp_oms__date_dim_fact date_dim
  where date_dim_key BETWEEN 20250823 AND 20251022

    ) as festive

 cross join

(
select 
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
             when cat.analytic_business_unit = 'Furniture' and lower(fur_b.branded_flag)='branded' then 'Branded' else 'Unbranded' end  as branded_flag,

        case 
             when base.service_profile = 'FBF' then 'FBF' 
             when base.service_profile in ('NON_FBF','FBF_LITE') then 'NFBF'
        else 'null' 
        end as service_profile,

        sum(search_ppvs)/62 as ly_ja_search_ppvs,
        sum(primary_ppvs)/62 as ly_ja_primary_ppvs,
        sum(net_units)/62 as ly_ja_net_units 


from bigfoot_external_neo.cp_santa__listing_performance_at_day_level_with_sales_90d_fact base 

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
AND date_key between 20240701 and 20240831 

GROUP BY

        base.marketplace_id ,
        cat.analytic_business_unit ,
        cat.analytic_super_category ,
        cat.analytic_vertical ,
        case when is_first_party_seller = TRUE then "Alpha" else "Mp" end ,

      case when cat.analytic_business_unit = 'BGM' and lower(bgm_b.branded_flag)='branded' then  bgm_b.brand
             when cat.analytic_business_unit = 'Home' and  (lower(home_b.type)='branded' or lower(home_b.type)='d2c') then home_b.brand 
             when cat.analytic_business_unit = 'Furniture' and lower(fur_b.branded_flag)='branded' then fur_b.brand else 'Unbranded' end,

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
             when cat.analytic_business_unit = 'Furniture' and lower(fur_b.branded_flag)='branded' then 'Branded' else 'Unbranded' end ,

        case 
             when base.service_profile = 'FBF' then 'FBF' 
             when base.service_profile in ('NON_FBF','FBF_LITE') then 'NFBF'
             else 'null' 
        end

) as base )

    
            ) as sales_fact 


