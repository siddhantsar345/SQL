----- Pricing


SELECT


-- "Price Drop" as domain_flag,
--    calc.order_date_key as order_date_key,

--    substr(cast(calc.order_date_key as string),1,6) as year_mo,


            week_num_in_year,
            week_begin_date,

   calc.analytic_business_unit as analytic_business_unit,
   calc.analytic_super_category as analytic_super_category,

--    calc.analytic_vertical as analytic_vertical,
--    calc.brand,
--    case when t5.owner ='KAM' or seller.seller_id IS NOT NULL OR seller1.seller_id IS NOT NULL OR seller2.seller_id IS NOT NULL then calc.seller_id else 'Others' end as seller_id,
--    case when lower(b.branded_flag)='branded' then b.brand else 'Others' end as brand,

   calc.is_alpha_seller as is_alpha_seller,
--    "" as az_seller_type,
--    CAST(0 as boolean) as torso_tail_flag,
--    CASE WHEN seller.seller_id IS NOT NULL OR seller1.seller_id IS NOT NULL OR seller2.seller_id IS NOT NULL then 'Manufacturer' else 'Non Manufacturer' end as manufacturer_flag,
--    case when pv.vertical is not null then 'Priority Vertical' else 'Not Priority Vertical' end as priority_vertical_flag,
--    case when t5.owner = 'KAM' then 'KAM' else 'N-KAM' end as kam_nkam_flag,
-- --    calc.service_profile as service_profile,
--    calc.price_bucket as price_bucket,
--    b.branded_flag as branded_flag,
--    b.brand_tier as brand_tier,
--    b.brand_type as brand_type,
--    b.is_priority_brand as is_priority_brand,
   


-- CASE WHEN LOWER(b.branded_flag) = 'branded' and LOWER(b.brand_type) = 'd2c' then 'D2C' else 'Non D2C' end as d2c_flag,
-- case when lower(seller.is_priority) ="yes" OR lower(seller1.is_priority) ="yes" OR lower(seller2.is_priority) = "yes" then 'Yes' else 'No' end as manufacturer_priority_flag,
-- calc.age_range as age_range ,



SUM(input_weighted_bau_asp) as input_weighted_aug_bau_asp,
SUM(input_weighted_cur_asp) as input_weighted_cur_asp,
SUM(input_weighted_exp_asp) as input_weighted_exp_asp,
SUM(output_weighted_bau_asp) as output_weighted_aug_bau_asp,
SUM(output_weighted_cur_asp) as output_weighted_cur_asp,
SUM(output_weighted_exp_asp) as output_weighted_exp_asp ,


SUM(bau_units) as bau_units,
SUM(cur_units) as cur_units,


-- CASE WHEN old_tax_rate is null then 'No GST Change'
--     WHEN old_tax_rate > new_tax_rate then 'GST Reduced'
--     WHEN old_tax_rate < new_tax_rate then 'GST Increased' else 'Others' end as gst_change_flag,


SUM(bau_gmv) as bau_gmv,
SUM(cur_gmv)as cur_gmv

-- COUNT(DISTINCT listing_id) as lids,
  
-- COUNT(DISTINCT CASE WHEN cur_asp <= expected_asp then listing_id end) as priced_lids,
-- SUM(CASE WHEN cur_asp <= expected_asp then bau_gmv end)/14 as priced_bau_gmv,
-- SUM(CASE WHEN cur_asp <= expected_asp then cur_gmv end) as priced_cur_gmv



FROM
   (
   SELECT
            week_num_in_year,
            week_begin_date,
        analytic_business_unit,
           sub.analytic_super_category,
           sub.analytic_vertical,
           sub.seller_id,
           sub.brand,
         
           sub.is_alpha_seller,
           sub.service_profile,
           sub.price_bucket,
           sub.product_id,
           sub.listing_id,
           sub.age_range,


          
           sub.bau_units,
           sub.bau_gmv,
           sub.bau_asp,
           sub.bau_fsp,
           sub.bau_gta,
           sub.bau_sp,
           sub.cur_units,
           sub.cur_gmv,
           sub.cur_asp,
           sub.old_tax_rate_mp,
           sub.new_tax_rate_mp,
           sub.old_tax_rate_dmd,
           sub.new_tax_rate_dmd,
           sub.old_tax_rate,
           sub.new_tax_rate,


       COALESCE(bau_asp - (bau_sp-(bau_sp/(1+old_tax_rate))*(1+new_tax_rate)),bau_asp) as expected_asp,


       bau_asp*bau_units as input_weighted_bau_asp,
       cur_asp*bau_units as input_weighted_cur_asp,
       COALESCE(bau_asp - (bau_sp-(bau_sp/(1+old_tax_rate))*(1+new_tax_rate)),bau_asp)*bau_units as input_weighted_exp_asp,


       bau_asp*cur_units as output_weighted_bau_asp,
       cur_asp*cur_units as output_weighted_cur_asp,
       COALESCE(bau_asp - (bau_sp-(bau_sp/(1+old_tax_rate))*(1+new_tax_rate)),bau_asp)*cur_units as output_weighted_exp_asp


   FROM
       (
       SELECT
    --    fes.order_date_key as order_date_key,
            fes.week_num_in_year,
            fes.week_begin_date,
           bau.analytic_business_unit as analytic_business_unit,
           bau.analytic_super_category as analytic_super_category,
           bau.analytic_vertical as analytic_vertical,
           bau.seller_id as seller_id,
           bau.brand as brand,
          
           bau.is_alpha_seller as is_alpha_seller,
           bau.service_profile as service_profile,
           bau.price_bucket as price_bucket,
           bau.product_id as product_id,
           bau.listing_id as listing_id,
           bau.age_range as age_range,


          
           bau.units as bau_units,
           bau.gmv as bau_gmv,
           bau.asp as bau_asp,
           bau.fsp as bau_fsp,
           bau.gta as bau_gta,
           bau.fsp - bau.gta as bau_sp,


           fes.units as cur_units,
           fes.gmv as cur_gmv,
           fes.asp as cur_asp,


           CAST(mp_gst.old_tax_rate as numeric)/100 as old_tax_rate_mp,
           CAST(mp_gst.new_tax_rate as numeric)/100 as new_tax_rate_mp,


           CAST(dmd_gst.c7 as numeric) as old_tax_rate_dmd,
            CAST(dmd_gst.c8 as numeric) as new_tax_rate_dmd,


           CASE WHEN bau.is_alpha_seller = 'Diamond' then CAST(dmd_gst.c7 as numeric) else  CAST(mp_gst.old_tax_rate as numeric)/100 end as old_tax_rate,
           CASE WHEN bau.is_alpha_seller = 'Diamond' then CAST(dmd_gst.c8 as numeric) else CAST(mp_gst.new_tax_rate as numeric)/100 end as new_tax_rate


       FROM
           (
               (
           SELECT


               cat.analytic_business_unit as analytic_business_unit,
               cat.analytic_super_category as analytic_super_category,
               cat.analytic_vertical as analytic_vertical,
              sales.seller_id as seller_id,


            --   sales.brand as brand,
               case when (lower(b.type)='branded' or lower(b.type)='d2c') then b.brand else 'Others' end as brand,
             
              case when sales.is_alpha_seller = TRUE then 'Diamond' else 'Rest of MP' end as is_alpha_seller,
              case
              when is_alpha_seller = TRUE and ((lower(sales.source_facility_id)  like '%\\_alite\\_%') or (lower(sales.source_facility_id) like '%\\_al\\_%')) then 'Alite'
              when sales.service_profile = 'FBF' then 'FBF'
              when sales.service_profile in ('NON_FBF','FBF_LITE') then 'NFBF'
              else 'null' end  as service_profile,
              CASE
               WHEN sales.gmv / sales.units <= 300 THEN "0-300"
               WHEN sales.gmv / sales.units > 300 AND sales.gmv / sales.units <= 500 then "301-500"
               WHEN sales.gmv / sales.units > 500 AND sales.gmv / sales.units <= 1000 then "501-1000"
               WHEN sales.gmv / sales.units > 1000 THEN "1000+"
               End as price_bucket,
               sales.product_id as product_id,
              sales.listing_id as listing_id,
              pd.age_range as age_range,




              SUM(units) as units,
              SUM(gmv) as gmv,
              SUM(gmv)/SUM(units) as asp,
              SUM(original_listing_price)/sum(units) as fsp,
              SUM(coalesce((cast(regexp_extract(construct_fee_adjustments, '"amount":([0-9.]+)[^}]*?"referenceId":"iks:001"', 1) as numeric)),0))/sum(units) as gta


           FROM bigfoot_external_neo.cp_bi_prod_sales__forward_unit_history_fact sales

           LEFT JOIN fdp_uploads.ds_fkint_analytics_cdo_brand_d2c_home_mapping_1_0 b
    on lower(sales.analytic_super_category) = lower(b.analytic_super_category) and lower(sales.brand) = lower(b.brand)



           LEFT JOIN bigfoot_external_neo.sp_product__product_categorization_hive_dim cat
               ON  sales.product_id = cat.product_id


           left join fdp_uploads.ds_fkint_analytics_cdo_fsn_level_age_group_1_0 as pd
                  on
                  pd.product_id=sales.product_id
                 
          




           WHERE lower(sales.status) in ('in_progress','undelivered','completed','delivered','approved','shipped','ready_to_ship','returned', 'return_requested','activated')
              AND sales.type !='service'
              AND sales.replacement_for_unit IS NULL
              AND sales.exchange_for_unit IS NULL
              AND sales.is_freebie =FALSE
              AND sales.marketplace_id IN ('FLIPKART')
              AND sales.is_shopsy_order =FALSE
            --   AND lower(sales.analytic_business_unit) IN ('home','furniture')
            AND lower(sales.analytic_business_unit) IN ('home')
              and sales.order_date_key between 20250818 and 20250831
            --   and sales.order_date_key between 20250701 and 20250831


           GROUP BY
              cat.analytic_business_unit ,
               cat.analytic_super_category ,
               cat.analytic_vertical ,
              sales.seller_id,


            --   sales.brand ,
               case when (lower(b.type)='branded' or lower(b.type)='d2c') then b.brand else 'Others' end,
           
              case when sales.is_alpha_seller = TRUE then 'Diamond' else 'Rest of MP' end ,
              case
              when is_alpha_seller = TRUE and ((lower(sales.source_facility_id)  like '%\\_alite\\_%') or (lower(sales.source_facility_id) like '%\\_al\\_%')) then 'Alite'
              when sales.service_profile = 'FBF' then 'FBF'
              when sales.service_profile in ('NON_FBF','FBF_LITE') then 'NFBF'
              else 'null' end  ,
              CASE
               WHEN sales.gmv / sales.units <= 300 THEN "0-300"
               WHEN sales.gmv / sales.units > 300 AND sales.gmv / sales.units <= 500 then "301-500"
               WHEN sales.gmv / sales.units > 500 AND sales.gmv / sales.units <= 1000 then "501-1000"
               WHEN sales.gmv / sales.units > 1000 THEN "1000+"
               End ,
               sales.product_id,
              sales.listing_id,
              pd.age_range






           ) bau


       INNER JOIN
           (
           SELECT
               sales.listing_id,
            --    order_date_key as order_date_key,
                date_dim.week_num_in_year,
                date_dim.week_begin_date,
               SUM(units) as units,
               SUM(gmv) as gmv,
               SUM(gmv)/sum(units) as asp
              
           FROM bigfoot_external_neo.cp_bi_prod_sales__forward_unit_history_fact sales
           
           LEFT JOIN bigfoot_external_neo.scp_oms__date_dim_fact as date_dim
            ON sales.order_date_key = date_dim.date_dim_key


           WHERE lower(sales.status) in ('in_progress','undelivered','completed','delivered','approved','shipped','ready_to_ship','returned', 'return_requested','activated')
               AND sales.type !='service'
               AND sales.replacement_for_unit IS NULL
               AND sales.exchange_for_unit IS NULL
               AND sales.is_freebie =FALSE
               AND sales.marketplace_id IN ('FLIPKART')
               AND sales.is_shopsy_order =FALSE
            --    AND lower(sales.analytic_business_unit) IN ('home','furniture')
            AND lower(sales.analytic_business_unit) IN ('home')
            and sales.order_date_key BETWEEN 20260101 and 20260310
                


           GROUP BY
       sales.listing_id,
            --    order_date_key as order_date_key,
                date_dim.week_num_in_year,
                date_dim.week_begin_date
           ) fes
           ON bau.listing_id = fes.listing_id


  
       LEFT JOIN
           (
           SELECT DISTINCT
               slm.listing_id,
               MIN(old_tax_rate) as old_tax_rate,
               MIN(new_tax_rate) as new_tax_rate


           FROM bigfoot_external_neo.sp_analytics__gst_reform_fact ref1


           LEFT JOIN bigfoot_external_neo.sp_product__slm_listing_attribute_history_fact slm
               on ref1.listing_id=slm.listing_id


           WHERE lower(attribute) = ('ssp')
               and updateat >= PARSE_DATETIME('%Y-%m-%d %I:%M:%S %p', '2025-09-17 02:00:00 PM')
               and updateat <= PARSE_DATETIME('%Y-%m-%d %I:%M:%S %p', '2025-09-22 02:00:00 PM')
               and source in ('SETTLEMENTS_SYSTEM_UPDATE','SLM_OPS_UPDATE')


           GROUP BY
               slm.listing_id
           ) mp_gst
           ON bau.listing_id = mp_gst.listing_id


       LEFT JOIN fdp_uploads.ds_fkint_cp_santa_pricing_uplaod_dataset_fact_1_0 dmd_gst
           ON bau.product_id = dmd_gst.c4
           AND dmd_gst.c1 = 'FLIPKART'
           AND data_set = '82bddf6e-5d45-4338-a3f3-86795e600d92'


       ) )sub


   ) calc






LEFT JOIN




  (
  SELECT
      seller_id,
      MIN(managed_by) AS owner
  FROM fdp_uploads.ds_fkint_analytics_cdo_seller_kam_ukam_mapping_1_0
  GROUP BY seller_id
  ) AS t5
on calc.seller_id = t5.seller_id




LEFT JOIN
(
  SELECT seller_id,
         analytic_super_category, analytic_vertical, brand, is_priority
  FROM fdp_uploads.ds_fkint_analytics_cdo_bgm_manufacturer_seller_list_analytics_1_0
  WHERE LOWER(analytic_super_category) = 'sportfitness'
) AS seller
  ON CAST(seller.seller_id AS STRING) = CAST(calc.seller_id AS STRING)
  AND seller.analytic_super_category = calc.analytic_super_category
  AND seller.analytic_vertical = calc.analytic_vertical
  AND seller.brand = calc.brand




LEFT JOIN
(
  SELECT seller_id,
         analytic_super_category, analytic_vertical, brand, is_priority
  FROM fdp_uploads.ds_fkint_analytics_cdo_bgm_manufacturer_seller_list_analytics_1_0
  WHERE LOWER(analytic_super_category) = 'toysandss'
) AS seller1
  ON seller1.seller_id = calc.seller_id
  AND seller1.analytic_super_category = calc.analytic_super_category








LEFT JOIN
  (SELECT seller_id,
         analytic_super_category, analytic_vertical, brand, is_priority
  FROM fdp_uploads.ds_fkint_analytics_cdo_bgm_manufacturer_seller_list_analytics_1_0
  WHERE LOWER(analytic_super_category) = 'babycare') as seller2
  on seller2.seller_id=calc.seller_id
  and seller2.analytic_super_category = calc.analytic_super_category
  and seller2.brand = calc.brand




--priority vertical flag
LEFT JOIN fdp_uploads.ds_fkint_analytics_cdo_bgm_priority_vertical_list_1_0 as pv
on calc.analytic_vertical=pv.vertical




--branded_d2c_priority_PnM
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
  ON LOWER(calc.analytic_super_category) = LOWER(b.analytic_super_category)
  AND LOWER(calc.brand) = LOWER(b.brand)










GROUP BY
--    calc.order_date_key ,
            week_num_in_year,
            week_begin_date,
   calc.analytic_business_unit ,
   calc.analytic_super_category ,
--    calc.analytic_vertical ,
--    calc.brand,
--    case when t5.owner ='KAM' or seller.seller_id IS NOT NULL OR seller1.seller_id IS NOT NULL OR seller2.seller_id IS NOT NULL then calc.seller_id else 'Others' end ,
--    case when lower(b.branded_flag)='branded' then b.brand else 'Others' end ,
 
   calc.is_alpha_seller 


--    CASE WHEN seller.seller_id IS NOT NULL OR seller1.seller_id IS NOT NULL OR seller2.seller_id IS NOT NULL then 'Manufacturer' else 'Non Manufacturer' end ,
--    case when pv.vertical is not null then 'Priority Vertical' else 'Not Priority Vertical' end ,
--    case when t5.owner = 'KAM' then 'KAM' else 'N-KAM' end ,
--    calc.service_profile ,
--    calc.price_bucket 
--    b.branded_flag ,
--    b.brand_tier,
--    b.brand_type ,
--    b.is_priority_brand ,


-- CASE WHEN LOWER(b.branded_flag) = 'branded' and LOWER(b.brand_type) = 'd2c' then 'D2C' else 'Non D2C' end ,
-- case when lower(seller.is_priority) ="yes" OR lower(seller1.is_priority) ="yes" OR lower(seller2.is_priority) = "yes" then 'Yes' else 'No' end ,
-- calc.age_range,

-- CASE WHEN old_tax_rate is null then 'No GST Change'
--     WHEN old_tax_rate > new_tax_rate then 'GST Reduced'
--     WHEN old_tax_rate < new_tax_rate then 'GST Increased' else 'Others' end






----------- PI CI
select
    a.yearmo,
    a.week_num_in_year,
    a.week_begin_date,

    a.analytic_business_unit as bu,
    a.analytic_super_category as sc,
    -- a.analytic_vertical,
    -- a.brand,


    avg(fk_price) as fk_price,
    avg(comp_price) as comp_price,

    sum(search_ppvs) as search_ppvs,

    sum(fk_price_post_coupon * search_ppvs) as fk_cp,
    sum(comp_price_post_coupon * search_ppvs) as comp_cp,

    (sum(case when fsn_coupon_landscape= "FK_Comp" then search_ppvs else 0 end ) - sum(case when fsn_coupon_landscape= "AI_Comp" then search_ppvs else 0 end )) as ci_cd


from
( 
    select
        a.yearmo,

                date_dim.week_num_in_year,
                date_dim.week_begin_date,
        
        a.analytic_business_unit,
        a.analytic_super_category,
        a.analytic_vertical,
        -- a.brand,
        case when (lower(b.type)='branded' or lower(b.type)='d2c') then b.brand else 'Others' end as brand,
        a.fk_seller_type,
        a.az_seller_type,
        a.search_ppvs,
        a.fsn_landscape,
        a.fk_price,
        a.comp_price,
        a.fk_price_post_coupon,
        a.fsn,
        (comp_price-coalesce(comp_coupon_discount,0)) as comp_price_post_coupon,
        CASE
            WHEN fk_price_post_coupon < 1000 AND (comp_price - coalesce(comp_coupon_discount,0)) / NULLIF(fk_price_post_coupon,0) > 1.02 THEN "FK_Comp"
            WHEN fk_price_post_coupon < 1000 AND (comp_price - coalesce(comp_coupon_discount,0)) / NULLIF(fk_price_post_coupon,0) < 0.98 THEN "AI_Comp"
            WHEN fk_price_post_coupon >= 1000 AND (comp_price - coalesce(comp_coupon_discount,0)) / NULLIF(fk_price_post_coupon,0) > 1.01 THEN "FK_Comp"
            WHEN fk_price_post_coupon >= 1000 AND (comp_price - coalesce(comp_coupon_discount,0)) / NULLIF(fk_price_post_coupon,0) < 0.99 THEN "AI_Comp"
            ELSE "Parity"
        END as fsn_coupon_landscape

    from bigfoot_external_neo.analytics_cdo__unweighted_comp_base_hist_fact as a
           
           LEFT JOIN bigfoot_external_neo.scp_oms__date_dim_fact as date_dim
            ON a.date_key = date_dim.date_dim_key



        LEFT JOIN fdp_uploads.ds_fkint_analytics_cdo_brand_d2c_home_mapping_1_0 b
    on lower(a.analytic_super_category) = lower(b.analytic_super_category) and lower(a.brand) = lower(b.brand)


    WHERE lower(competitor) = 'ai'
        AND ci_business_unit = 'Home'
        AND CAST(date_key AS BIGINT) BETWEEN 20260101 AND 20260310



) as a

group by
    a.yearmo,
    a.week_num_in_year,
    a.week_begin_date,

    a.analytic_business_unit,
    a.analytic_super_category


-------------




SELECT
   substr(cast(comp.date_key as string),1,6) as year_mo,
   comp.analytic_business_unit as analytic_business_unit,
       date_dim.week_num_in_year,
    date_dim.week_begin_date,

mpp,


       sum(comp.m_dw) as m_dw,
   sum(comp.cdw) as cdw,
   sum(comp.cdw_fee) as cdw_fee,
   sum(comp.dw) as dw,
      sum(comp.fk_comp_display) as fk_comp_display,
   sum(comp.ms_comp_display) as ms_comp_display,
      sum(comp.fk_comp_display_fee) as fk_comp_display_fee,
   sum(comp.ms_comp_display_fee) as ms_comp_display_fee,
   comp.analytic_super_category as analytic_super_category
      
FROM bigfoot_external_neo.cp_santa__meesho_pi_2__sc_level_fact AS comp

LEFT JOIN bigfoot_external_neo.scp_oms__date_dim_fact as date_dim
    ON comp.date_key = date_dim.date_dim_key

WHERE lower(comp.analytic_business_unit) in ('home')
    AND CAST(date_key AS BIGINT) BETWEEN 20260101 and 20260310

GROUP BY 
1,2,3,4,5,14



-------- Selection
-------- New Selection Selection


select 
    lhd.analytic_business_unit,        
    lhd.analytic_super_category,   
    lhd.analytic_vertical,
            wd.week_begin_date,
        wd.yearmo,
        wd.week_num_in_year,

    CASE 
        WHEN lhd.flipkart_selling_price < 200 THEN '0-200'
        WHEN lhd.flipkart_selling_price >= 200 AND lhd.flipkart_selling_price < 300 THEN '200-300'
        WHEN lhd.flipkart_selling_price >= 300 AND lhd.flipkart_selling_price < 500 THEN '300-500'
        WHEN lhd.flipkart_selling_price >= 500 THEN '500+'
        ELSE 'na'
    END AS pp,

    count(distinct lhd.listing_id) as new_selection_listings,
    -- count(distinct case when created_data_fact.product_created_date = CAST(lhd.listing_created_on AS DATE)  then list_dim.product_id end) as new_fsn_count

    -- ,count(distinct case when created_data_fact.item_created_date=lhd.listing_created_date then prod_dim.itemid end) as new_item_count
    
    COUNT(DISTINCT CASE 
        WHEN PARSE_DATE('%Y%m%d', CAST(created_data_fact.product_created_date AS STRING)) = CAST(lhd.listing_created_on AS DATE) 
        THEN lhd.product_id 
    END) AS new_fsn_count,

    COUNT(DISTINCT CASE 
        WHEN PARSE_DATE('%Y%m%d', CAST(created_data_fact.item_created_date AS STRING)) = CAST(lhd.listing_created_on AS DATE) 
        THEN prod_dim.itemid -- Using prod_dim as requested
    END) AS new_item_count



from bigfoot_external_neo.sp_product__listing_hive_dim as lhd

left join bigfoot_external_neo.sp_product__product_attribute_hive_dim prod_dim
    on lhd.product_id = prod_dim.product_id

left join bigfoot_external_neo.analytics_cdo__item_created_date_fact created_data_fact
    on lhd.listing_id = created_data_fact.listing_id

left JOIN bigfoot_external_neo.scp_oms__date_dim_fact as wd
    ON CAST(FORMAT_DATETIME('%Y%m%d', CAST(lhd.listing_created_on AS TIMESTAMP)) AS INT64) = wd.date_dim_key

where lhd.marketplace_id = 'FLIPKART' 
    AND lower(lhd.analytic_business_unit) in ('home')
    and CAST(listing_created_on AS DATE) BETWEEN '2026-01-01' and '2026-03-10' 

 group by 1,2,3,4,5,6,7



----- Selection with 1 ppv

select
    sales.week_begin_date,
    sales.yearmo,
    sales.week_num_in_year,
    sales.analytic_business_unit,
    sales.analytic_super_category,
    sales.tag,
    sales.analytic_vertical,
    count(distinct case when primary_ppvs >= 1 then listing_id end) as ppv_1_lid_count,
    count(distinct case when primary_ppvs >= 1000 then listing_id end) as ppv_1000_lid_count,
    sum(units) as total_units,

    count(distinct case when primary_ppvs >= 1 then product_id end) as ppv_1_pid_count,
    count(distinct case when primary_ppvs >= 1000 then product_id end) as ppv_1000_pid_count,

    count(distinct case when primary_ppvs >= 1  and lower(service_profile) in ("fbf","fbf_and_fbf_lite","fbf_and_non_fbf","fbf_lite") then listing_id end) as ppv_1_fbf_lid_count,
    count(distinct case when primary_ppvs >= 1000  and lower(service_profile) in ("fbf","fbf_and_fbf_lite","fbf_and_non_fbf","fbf_lite") then listing_id end) as ppv_1000_fbf_lid_count,

    count(distinct case when primary_ppvs >= 1  and lower(service_profile) in ("fbf","fbf_and_fbf_lite","fbf_and_non_fbf","fbf_lite") then product_id end) as ppv_1_fbf_pid_count,
    count(distinct case when primary_ppvs >= 1000  and lower(service_profile) in ("fbf","fbf_and_fbf_lite","fbf_and_non_fbf","fbf_lite") then product_id end) as ppv_1000_fbf_pid_count,

    count(distinct case when primary_ppvs >= 50 then listing_id end) as ppv_50_lid_count,
    count(distinct case when primary_ppvs >= 50 then product_id end) as ppv_50_pid_count,
    count(distinct case when primary_ppvs >= 50  and lower(service_profile) in ("fbf","fbf_and_fbf_lite","fbf_and_non_fbf","fbf_lite") then listing_id end) as ppv_50_fbf_lid_count,
    count(distinct case when primary_ppvs >= 50  and lower(service_profile) in ("fbf","fbf_and_fbf_lite","fbf_and_non_fbf","fbf_lite") then product_id end) as ppv_50_fbf_pid_count,

    count(distinct case when primary_ppvs >= 10 then listing_id end) as ppv_10_lid_count,
    count(distinct case when primary_ppvs >= 10  and lower(service_profile) in ("fbf","fbf_and_fbf_lite","fbf_and_non_fbf","fbf_lite") then listing_id end) as ppv_10_fbf_lid_count

from 
(
    SELECT
        wd.week_begin_date,
        wd.yearmo,
        wd.week_num_in_year,
        sales.listing_id,
        sales.product_id,
        sales.analytic_business_unit,
        sales.analytic_super_category,
        sales.analytic_vertical,
        sales.service_profile,
        a.tag,
        sum(COALESCE(sales.primary_ppvs, 0)) AS primary_ppvs,
        sum(COALESCE(sales.gross_units, 0)) AS units

    FROM bigfoot_external_neo.cp_santa__listing_performance_at_day_level_with_sales_90d_fact sales

    -- -- Hipo
    -- left join bigfoot_external_neo.planning_selection_design__hipo_metrics_new_pipeline_historical_fact as a 
    --     on a.product_id = sales.product_id

    LEFT JOIN (
        SELECT product_id, tag 
        FROM (
            SELECT product_id, tag, ROW_NUMBER() OVER(PARTITION BY product_id ORDER BY tag_end_date DESC) as rn 
            FROM bigfoot_external_neo.planning_selection_design__hipo_metrics_new_pipeline_historical_fact
            WHERE tag_end_date <= 20260310
        ) as a
        WHERE rn = 1
    ) hipo ON s.product_id = hipo.product_id

    left JOIN bigfoot_external_neo.scp_oms__date_dim_fact wd
    ON sales.date_key = wd.date_dim_key

    LEFT JOIN bigfoot_external_neo.sp_product__product_attribute_hive_dim prod_dim
        ON sales.product_id = prod_dim.product_id

    WHERE sales.marketplace_id='FLIPKART' 
        and sales.date_key between 20260101 and 20260310
        and lower(sales.analytic_business_unit) in ('home')
        and lower(prod_dim.analytic_vertical) not in ('plantsapling', 'plantseed')
        and (prod_dim.analytic_vertical not in ('MobileProtectionDesignerCaseCover','Book','BikeBodyCover','MobileProtectionPlainCaseCover','WatchCombo','CarBodyCover','MobileSkin','MobileProtectionMobileScreenGuard','CameraLensProtector','SmartWatchStraps','SmartWatchScreenGuard','MobileProtectionDesignerCaseCover(OLD)','MobileProtectionPlainCaseCover(OLD)','MobileProtectionMobilePouches(OLD)') or prod_dim.vertical_name in ('book','regionalbooks')) 


    GROUP BY 1,2,3,4,5,6,7,8,9,10
) as sales
group by 1,2,3,4,5,6,7



---transacting selection

SELECT
        wd.week_begin_date,
        wd.yearmo,
        wd.week_num_in_year,
        prod_dim.analytic_business_unit,
        prod_dim.analytic_super_category,
        prod_dim.analytic_vertical,
        count(distinct sales.listing_id) as trans_lid_count,
        count(distinct sales.product_id) as trans_pid_count,
        sum(sales.gmv) as gmv,
        sum(sales.units) as sales_units

    FROM bigfoot_external_neo.cp_bi_prod_sales__forward_unit_history_fact as sales

    left JOIN bigfoot_external_neo.scp_oms__date_dim_fact wd
    ON sales.order_date_key = wd.date_dim_key

    left join (
    select
        listing_id
        ,is_first_party_seller as is_alpha_seller
        ,flipkart_selling_price
    from bigfoot_external_neo.sp_product__listing_hive_dim
    where marketplace_id = 'FLIPKART'
) list_dim_fact
on list_dim_fact.listing_id = sales.listing_id

    LEFT JOIN bigfoot_external_neo.sp_product__product_attribute_hive_dim as prod_dim
        on sales.product_id = prod_dim.product_id

    WHERE
        lower(sales.status) in ('in_progress','undelivered','completed','delivered','approved','shipped','ready_to_ship','returned', 'return_requested','activated')
        AND sales.type !='service'
        AND sales.category_id NOT IN (21726, 21651)
        AND sales.replacement_for_unit IS NULL
        AND sales.exchange_for_unit IS NULL
        AND sales.is_freebie = FALSE
        AND sales.marketplace_id = 'FLIPKART'
        AND sales.is_shopsy_order = False
        AND sales.order_date_key BETWEEN 20260101 AND 20260310
        AND lower(prod_dim.analytic_business_unit) IN ('home', 'furniture')
        and lower(prod_dim.analytic_vertical) not in ('plantsapling', 'plantseed')
        and (prod_dim.analytic_vertical not in ('MobileProtectionDesignerCaseCover','Book','BikeBodyCover','MobileProtectionPlainCaseCover','WatchCombo','CarBodyCover','MobileSkin','MobileProtectionMobileScreenGuard','CameraLensProtector','SmartWatchStraps','SmartWatchScreenGuard','MobileProtectionDesignerCaseCover(OLD)','MobileProtectionPlainCaseCover(OLD)','MobileProtectionMobilePouches(OLD)') or prod_dim.vertical_name in ('book','regionalbooks')) 

    group by 1,2,3,4,5,6






-------- Speed
select 
sales.analytic_business_unit,
sales.analytic_super_category,
sales.analytic_vertical,
sales.cms_vertical,
        wd.week_begin_date,
        wd.yearmo,
        wd.week_num_in_year,
 case 
    when sales.service_profile = 'FBF' then 'FBF' 
    when sales.service_profile in ('NON_FBF','FBF_LITE') then 'NFBF'
    else 'null' end  as service_profile,
    
    
SUM(CASE WHEN sales.sla_in_days <= 0 THEN 1 ELSE 0 END) AS d0_units,
SUM(CASE WHEN sales.sla_in_days <= 1 THEN 1 ELSE 0 END) AS d1_units,
SUM(CASE WHEN sales.sla_in_days <= 2 THEN 1 ELSE 0 END) AS d2_units,
SUM(CASE WHEN sales.sla_in_days <= 4 THEN 1 ELSE 0 END) AS d4_units,
SUM(CASE WHEN sales.sla_in_days <= 6 THEN 1 ELSE 0 END) AS d6_units,
sum(units) as units,
sum(gmv) as gmv



FROM  bigfoot_external_neo.cp_bi_prod_sales__forward_unit_history_fact sales

    left JOIN bigfoot_external_neo.scp_oms__date_dim_fact wd
    ON sales.order_date_key = wd.date_dim_key



-- LEFT JOIN  fdp_uploads.ds_fkint_cp_santa_hyperlocal_vertical_bu_mapping_2_0 AS hl 
--     ON sales.analytic_vertical = hl.analytic_vertical 
--     AND LOWER(hl.bu_final) = 'home'  
--     and sales.marketplace_id='HYPERLOCAL'

WHERE LOWER(sales.status) IN ('in_progress', 'undelivered', 'completed', 'delivered', 'approved', 'shipped', 'ready_to_ship', 'returned', 'return_requested', 'activated')
        AND sales.type  = 'physical'
        AND sales.replacement_for_unit IS NULL
        AND sales.exchange_for_unit IS NULL
        AND sales.is_freebie = FALSE
        -- AND (sales.marketplace_id IN ('FLIPKART') OR (sales.marketplace_id = 'HYPERLOCAL' AND  hl.analytic_vertical IS NOT NULL))
        AND sales.marketplace_id IN ('FLIPKART')
        AND sales.analytic_business_unit IN ('Home')
        AND sales.order_date_key BETWEEN 20260101 and  20260310
        AND sales.is_shopsy_order = FALSE
        
    group by 
         case 
    when sales.service_profile = 'FBF' then 'FBF' 
    when sales.service_profile in ('NON_FBF','FBF_LITE') then 'NFBF'
    else 'null' end,
            wd.week_begin_date,
        wd.yearmo,
        wd.week_num_in_year,
sales.analytic_business_unit,
sales.analytic_super_category,
sales.analytic_vertical,
sales.cms_vertical;



-------------

WITH weekly_snapshot AS (
    SELECT 
        wd.week_begin_date,
        wd.yearmo,
        wd.week_num_in_year,
        MAX(list_dim.process_date_key) as report_date

    FROM bigfoot_external_neo.sp_analytics__listing_history_90d_fact list_dim

    INNER JOIN bigfoot_external_neo.scp_oms__date_dim_fact wd
        ON list_dim.process_date_key = wd.date_dim_key
        
    WHERE list_dim.process_date_key BETWEEN 20260101 AND 20260310
    AND list_dim.marketplace_id = 'FLIPKART'
    GROUP BY 1,2,3

)
SELECT 
    snap.week_begin_date,
    snap.yearmo,
    snap.week_num_in_year,
    
    prod_dim.analytic_business_unit,
    prod_dim.analytic_super_category,
    prod_dim.analytic_vertical,
    a.tag,

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

INNER JOIN weekly_snapshot snap
    ON list_dim.process_date_key = snap.report_date

LEFT JOIN bigfoot_external_neo.sp_product__product_attribute_hive_dim prod_dim
    on list_dim.product_id = prod_dim.product_id

    -- Hipo
-- left join bigfoot_external_neo.planning_selection_design__hipo_metrics_new_pipeline_historical_fact as a 
--     on a.product_id = list_dim.product_id


LEFT JOIN (
    SELECT product_id, tag 
    FROM (
        SELECT product_id, tag, 
               ROW_NUMBER() OVER(PARTITION BY product_id ORDER BY tag_end_date DESC) as rn 
        FROM bigfoot_external_neo.planning_selection_design__hipo_metrics_new_pipeline_historical_fact
    ) WHERE rn = 1
) a ON a.product_id = list_dim.product_id



WHERE
    list_dim.marketplace_id = 'FLIPKART'
    and lower(prod_dim.analytic_business_unit) in  ( 'home')
    and lower(analytic_vertical) not in ('plantsapling', 'plantseed')
    and (prod_dim.analytic_vertical not in ('MobileProtectionDesignerCaseCover','Book','BikeBodyCover','MobileProtectionPlainCaseCover','WatchCombo','CarBodyCover','MobileSkin','MobileProtectionMobileScreenGuard','CameraLensProtector','SmartWatchStraps','SmartWatchScreenGuard','MobileProtectionDesignerCaseCover(OLD)','MobileProtectionPlainCaseCover(OLD)','MobileProtectionMobilePouches(OLD)') or prod_dim.vertical_name in ('book','regionalbooks')) 

GROUP BY 1,2,3,4,5,6,7


------------



select 
    lhd.analytic_business_unit,        
    lhd.analytic_super_category,   
    lhd.analytic_vertical,
            wd.week_begin_date,
        wd.yearmo,
        wd.week_num_in_year,


    count(distinct lhd.listing_id) as new_selection_listings,
    -- count(distinct case when created_data_fact.product_created_date = CAST(lhd.listing_created_on AS DATE)  then list_dim.product_id end) as new_fsn_count

    -- ,count(distinct case when created_data_fact.item_created_date=lhd.listing_created_date then prod_dim.itemid end) as new_item_count
    
    COUNT(DISTINCT CASE 
        WHEN PARSE_DATE('%Y%m%d', CAST(created_data_fact.product_created_date AS STRING)) = CAST(lhd.listing_created_on AS DATE) 
        THEN lhd.product_id 
    END) AS new_fsn_count,

    COUNT(DISTINCT CASE 
        WHEN PARSE_DATE('%Y%m%d', CAST(created_data_fact.item_created_date AS STRING)) = CAST(lhd.listing_created_on AS DATE) 
        THEN prod_dim.itemid -- Using prod_dim as requested
    END) AS new_item_count



from bigfoot_external_neo.sp_product__listing_hive_dim as lhd

left join bigfoot_external_neo.sp_product__product_attribute_hive_dim prod_dim
    on lhd.product_id = prod_dim.product_id

left join bigfoot_external_neo.analytics_cdo__item_created_date_fact created_data_fact
    on lhd.listing_id = created_data_fact.listing_id

left JOIN bigfoot_external_neo.scp_oms__date_dim_fact as wd
    ON CAST(FORMAT_DATETIME('%Y%m%d', CAST(lhd.listing_created_on AS TIMESTAMP)) AS INT64) = wd.date_dim_key

where lhd.marketplace_id = 'FLIPKART' 
    AND lower(lhd.analytic_business_unit) in ('home')
    and CAST(listing_created_on AS DATE) BETWEEN '2026-01-01' and '2026-03-10' 

 group by 1,2,3,4,5,6;


---------


WITH base AS (
    SELECT 
        sales.analytic_business_unit,
        sales.product_id,
        wd.week_start_date,
        wd.year,
        wd.week_of_year,
        SUM(sales.gmv) AS gmv,
        SUM(sales.units) AS units,
        max(sales.listing_price) AS listing_price



    FROM bigfoot_external_neo.cp_bi_prod_sales__forward_unit_history_fact AS sales 
        LEFT JOIN bigfoot_external_neo.scp_oms__date_dim_fact wd
        ON sales.order_date_key = wd.date_dim_key


    WHERE LOWER(sales.status) IN ('in_progress', 'undelivered', 'completed', 'delivered', 'approved', 'shipped', 'ready_to_ship', 'returned', 'return_requested', 'activated')
        AND sales.type  = 'physical'
        AND sales.replacement_for_unit IS NULL
        AND sales.exchange_for_unit IS NULL
        AND sales.is_freebie = FALSE
        AND sales.marketplace_id IN ('FLIPKART')
        AND (
            sales.order_date_key BETWEEN 20250818 AND 20250831
            OR sales.order_date_key >= 20260101
        )
        AND sales.is_shopsy_order = FALSE
        AND LOWER(sales.analytic_business_unit) IN ('home')

    GROUP BY 1, 2, 3,4,5,6
),

baseline AS (
    SELECT 
        product_id,
        analytic_business_unit,
        SUM(gmv) / NULLIF(SUM(units), 0) AS bbd_asp,
        SUM(gmv) AS bbd_gmv,
        AVG(listing_price) AS bbd_price

    FROM base 
    WHERE order_date_key BETWEEN 20250818 AND 20250831
    GROUP BY 1, 2
),

spl_pricing AS (
    SELECT 
        product_id,
        analytic_business_unit,
        SUM(gmv) / NULLIF(SUM(units), 0) AS spl_asp,
        AVG(listing_price) AS spl_price
    FROM base 
    WHERE order_date_key BETWEEN 20250908 AND 20250921
    GROUP BY 1, 2
)

SELECT 
    b.product_id AS fsn,
    s.spl_price,
    b.bbd_price,
    ROUND((b.bbd_price - s.spl_price) / NULLIF(s.spl_price,0) * 100,2) AS pct_diff
FROM bbd_pricing b
INNER JOIN spl_pricing s 
    ON b.product_id = s.product_id 

WHERE ABS(s.spl_price - b.bbd_price) / NULLIF(s.spl_price,0) <= 0.015





