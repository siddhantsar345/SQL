select 
domain_flag,    
order_date_key,
marketplace,    
analytic_business_unit,
analytic_super_category,    
analytic_vertical,  
seller_id,  
brand,  
city_tier,  
zone,
is_alpha_seller,    
az_seller_type, 
torso_tail_flag,    
kam_nkam_flag,  
service_profile,    
price_bucket,   
branded_flag,   
brand_tier,
gmv,    
units,  
fsp,    
mrp,    
fbf_units,
sla,    
o2d,
d0_units,
d1_units,   
d2_units,   
d4_units,   
d6_units,
rto_units,  
rto_gmv,    
rvp_units,
cast(rvp_gmv as numeric) as rvp_gmv,
ru_den,
ru_num, 
pq_rated_units, 
pq_num, 
pq_rated_good_pq_units, 
pq_rating_4_units,  
pq_rating_3_8_units,    
pq_rating_3_85_units,   
pq_rating_3_9_units,    
pq_rated_hygiene_pq_units,  
pq_unrated_units,   
pq_lt_5_rated_units,    
fk_price_npi,   
comp_price_npi, 
fk_comp,    
az_comp,    
search_ppvs,
ly_gmv,
ly_units,
cast(sds_pure_az as numeric) as sds_pure_az,
cast(sds_oos_attribution_pure_az as numeric) as sds_oos_attribution_pure_az,
cast(msku_count as numeric) as msku_count,
cast(output_fes_weighted_asp as numeric) as output_fes_weighted_asp,
cast(output_bau_weighted_asp as numeric) as output_bau_weighted_asp,
cast(input_bau_weighted_asp as numeric) as input_bau_weighted_asp,
cast(input_fes_weighted_asp as numeric) as input_fes_weighted_asp,
cast(input_fes_weighted_fsp as numeric) as input_fes_weighted_fsp,
cast(input_bau_weighted_fsp as numeric) as input_bau_weighted_fsp,
cast(output_fes_weighted_fsp as numeric) as output_fes_weighted_fsp,
cast(outut_bau_weighted_fsp as numeric) as outut_bau_weighted_fsp,
d2c_flag,
analytic_category,
transacting_selection_count,
new_selection,
cast(m_dw as INT64) AS m_dw,
cast(cdw as INT64) AS cdw,
cast(dw as INT64) as dw,
fk_cd,
az_cd,
wfcp,
wccp

from 
(

(
select 
'sales' as domain_flag,
salesdata3.order_date_key as order_date_key,
salesdata3.marketplace as marketplace,
salesdata3.analytic_business_unit as analytic_business_unit, 
salesdata3.analytic_super_category as analytic_super_category, 
salesdata3.analytic_vertical as analytic_vertical, 
salesdata3.seller_id as seller_id,
salesdata3.brand as brand, 
salesdata3.city_tier as city_tier, 
salesdata3.zone as zone, 
salesdata3.is_alpha_seller as is_alpha_seller, 
"" as az_seller_type,
salesdata3.torso_tail_flag as torso_tail_flag,
salesdata3.kam_nkam_flag as kam_nkam_flag,
salesdata3.service_profile as service_profile,
salesdata3.price_bucket as price_bucket,
salesdata3.branded_flag as branded_flag,
salesdata3.brand_tier as brand_tier,
sum(salesdata3.gmv) as gmv, 
sum(salesdata3.units) as units, 
sum(salesdata3.fsp) as fsp,
sum(salesdata3.mrp) as mrp,
sum(salesdata3.fbf_units) as fbf_units, 
avg(salesdata3.sla) as sla,
avg(salesdata3.o2d) as o2d,
sum(salesdata3.d0_units) as d0_units, 
sum(salesdata3.d1_units) as d1_units,
sum(salesdata3.d2_units)as d2_units,
sum(salesdata3.d4_units)as d4_units,
sum(salesdata3.d6_units) as d6_units,
sum(salesdata3.rto_units) as rto_units, 
sum(salesdata3.rto_gmv) as rto_gmv, 
sum(salesdata3.rvp_units) as rvp_units, 
sum(salesdata3.rvp_gmv) as rvp_gmv, 
sum(salesdata3.ru_den) as ru_den, 
sum(salesdata3.ru_num) as ru_num,
sum(salesdata3.rated_units) as pq_rated_units,
sum(salesdata3.num) as pq_num,   
sum(case when lower(salesdata3.analytic_business_unit) in ('furniture') and lower(salesdata3.bmp_brand) = "unbranded" and salesdata3.rating_3_8 = 1 then salesdata3.rated_units
            when lower(salesdata3.analytic_business_unit) in ('furniture') and lower(salesdata3.bmp_brand) = "branded" and salesdata3.rating_4 = 1 then salesdata3.rated_units end) as pq_rated_good_pq_units,
sum(case when salesdata3.rating_4 = 1 then salesdata3.rated_units end) as pq_rating_4_units,
sum(case when salesdata3.rating_3_8 = 1 then salesdata3.rated_units end) as pq_rating_3_8_units,
sum(case when salesdata3.rating_3_85 = 1 then salesdata3.rated_units end) as pq_rating_3_85_units,
sum(case when salesdata3.rating_3_9 = 1 then salesdata3.rated_units end) as pq_rating_3_9_units,
sum(case 
            when salesdata3.analytic_super_category in ('LargeFurniture') and salesdata3.rating_3_4 = 1 then salesdata3.rated_units
            when analytic_super_category in ('SmallFurniture') and rating_3_6 = 1 then rated_units end) as pq_rated_hygiene_pq_units,                   
sum(case when salesdata3.unrated = 1 then salesdata3.units end) as pq_unrated_units,
sum(case when salesdata3.lt_5_rated = 1 then salesdata3.rated_units end) as pq_lt_5_rated_units,
0  as fk_price_npi,
0  as comp_price_npi,
0  as fk_comp,
0  as az_comp,
0  as search_ppvs,
0.0 as ly_gmv,
0 as ly_units,
0.0 as sds_pure_az,
0.0 as sds_oos_attribution_pure_az,
0.0 as msku_count,
0.0  as output_fes_weighted_asp,
0.0 as output_bau_weighted_asp,
0.0 as input_bau_weighted_asp,
0.0 as input_fes_weighted_asp,
0.0 as input_fes_weighted_fsp,
0.0 as input_bau_weighted_fsp,
0.0 as output_fes_weighted_fsp,
0.0 as outut_bau_weighted_fsp,
salesdata3.d2c_flag as d2c_flag,
salesdata3.analytic_category as analytic_category,
0 as transacting_selection_count,
0 as new_selection,
0 as m_dw,
0 as cdw,
0 as dw,
0 as fk_cd,
0 as az_cd,
0 as wfcp,
0 as wccp

from 

(
select 

salesdata2.order_date_key as order_date_key,
salesdata2.marketplace as marketplace,
salesdata2.analytic_business_unit as analytic_business_unit, 
salesdata2.analytic_super_category as analytic_super_category, 
salesdata2.analytic_category as analytic_category,
salesdata2.analytic_vertical as analytic_vertical, 
salesdata2.seller_id as seller_id,
salesdata2.brand as brand, 
salesdata2.city_tier as city_tier, 
salesdata2.zone as zone, 
salesdata2.is_alpha_seller as is_alpha_seller, 
salesdata2.torso_tail_flag as torso_tail_flag,

salesdata2.kam_nkam_flag as kam_nkam_flag,
salesdata2.service_profile as service_profile,
salesdata2.price_bucket as price_bucket,
salesdata2.branded_flag as branded_flag,
salesdata2.brand_tier as brand_tier,
salesdata2.bmp_brand,
salesdata2.brand_name,
salesdata2.d2c_flag,
case when (salesdata2.sum_rating/salesdata2.count_rating) >= 3.2 then 1 else 0 end as rating_3_2,
case when (salesdata2.sum_rating/salesdata2.count_rating) >= 3.4 then 1 else 0 end as rating_3_4,
case when (salesdata2.sum_rating/salesdata2.count_rating) >= 3.6 then 1 else 0 end as rating_3_6,
case when (salesdata2.sum_rating/salesdata2.count_rating) >= 3.8 then 1 else 0 end as rating_3_8,
case when (salesdata2.sum_rating/salesdata2.count_rating) >= 3.85 then 1 else 0 end as rating_3_85,
case when (salesdata2.sum_rating/salesdata2.count_rating) >= 3.9 then 1 else 0 end as rating_3_9,
case when (salesdata2.sum_rating/salesdata2.count_rating) >= 3.95 then 1 else 0 end as rating_3_95,
case when (salesdata2.sum_rating/salesdata2.count_rating) >= 4 then 1 else 0 end as rating_4,
case when (salesdata2.sum_rating/salesdata2.count_rating) is null then 1 else 0 end as unrated,  
case when (salesdata2.sum_rating/salesdata2.count_rating) is not null and salesdata2.count_rating < 5 then 1 else 0 end as lt_5_rated,



sum(salesdata2.gmv) as gmv, 
sum(salesdata2.units) as units, 
sum(salesdata2.fsp) as fsp,
sum(salesdata2.mrp) as mrp,
sum(salesdata2.fbf_units) as fbf_units, 
avg(salesdata2.sla) as sla,
avg(salesdata2.o2d) as o2d,
sum(salesdata2.d0_units) as d0_units, 
sum(salesdata2.d1_units) as d1_units,
sum(salesdata2.d2_units)as d2_units,
sum(salesdata2.d4_units)as d4_units,
sum(salesdata2.d6_units) as d6_units,
sum(salesdata2.rto_units) as rto_units, 
sum(salesdata2.rto_gmv) as rto_gmv, 
sum(salesdata2.rvp_units) as rvp_units, 
sum(salesdata2.rvp_gmv) as rvp_gmv, 
sum(salesdata2.ru_den) as ru_den, 
sum(salesdata2.ru_num) as ru_num,
sum(case when salesdata2.count_rating > 0 then salesdata2.units end) as rated_units,
sum(case when salesdata2.count_rating > 0 then (salesdata2.sum_rating/salesdata2.count_rating)*salesdata2.units end) as num

from 

(
select 

salesdata1.product_id,
salesdata1.group_id,
salesdata1.order_date_key as order_date_key,
salesdata1.marketplace as marketplace,
salesdata1.analytic_business_unit as analytic_business_unit, 
salesdata1.analytic_super_category as analytic_super_category, 
salesdata1.analytic_category as analytic_category,
salesdata1.analytic_vertical as analytic_vertical, 
salesdata1.seller_id as seller_id,
salesdata1.brand as brand, 
salesdata1.city_tier as city_tier, 
salesdata1.zone as zone, 
salesdata1.is_alpha_seller as is_alpha_seller, 
salesdata1.torso_tail_flag as torso_tail_flag,
salesdata1.kam_nkam_flag as kam_nkam_flag,
salesdata1.service_profile as service_profile,
salesdata1.price_bucket as price_bucket,
salesdata1.branded_flag as branded_flag,
salesdata1.brand_tier as brand_tier,
salesdata1.bmp_brand,
salesdata1.brand_name,
salesdata1.d2c_flag,

sum(salesdata1.gmv) as gmv, 
sum(salesdata1.units) as units, 
sum(salesdata1.fsp) as fsp,
sum(salesdata1.mrp) as mrp,
sum(salesdata1.fbf_units) as fbf_units, 
avg(salesdata1.sla) as sla,
avg(salesdata1.o2d) as o2d,
sum(salesdata1.d0_units) as d0_units, 
sum(salesdata1.d1_units) as d1_units,
sum(salesdata1.d2_units)as d2_units,
sum(salesdata1.d4_units)as d4_units,
sum(salesdata1.d6_units) as d6_units,
sum(salesdata1.rto_units) as rto_units, 
sum(salesdata1.rto_gmv) as rto_gmv, 
sum(salesdata1.rvp_units) as rvp_units, 
sum(salesdata1.rvp_gmv) as rvp_gmv, 
sum(salesdata1.ru_den) as ru_den, 
sum(salesdata1.ru_num) as ru_num,
sum(pr.sum_rating) as sum_rating,
sum(pr.count_rating) as count_rating     

from

(
select 
sales.product_id as product_id,
sales.order_date_key as order_date_key, 
sales.marketplace_id as marketplace, 
sales.analytic_business_unit as analytic_business_unit, 
sales.analytic_super_category as analytic_super_category, 
sales.analytic_category as analytic_category,
sales.analytic_vertical as analytic_vertical,
case when t5.owner ='KAM'  then sales.seller_id else 'Others' end as seller_id,
case when lower(b.branded_flag)='branded' then b.brand else 'Others' end as brand,
geo.city_tier as city_tier, 
geo.zone as zone,  

case when sales.is_alpha_seller = TRUE then 'Diamond' else 'Rest of MP' end as is_alpha_seller, 
''  as torso_tail_flag,
case when t5.owner = 'KAM' then 'KAM' else 'N-KAM' end as kam_nkam_flag,
case 
    when sales.is_alpha_seller = TRUE and (lower(sales.source_facility_id)  like '%\\_alite\\_%' or lower(sales.source_facility_id) like '%\\_al\\_%') then 'Alite'
    when sales.service_profile = 'FBF' then 'FBF' 
    when sales.service_profile in ('NON_FBF','FBF_LITE') then 'NFBF'
    else 'null'
    end as service_profile,
CASE 
        WHEN sales.gmv / sales.units <= 500 THEN "0 - 500"
        WHEN sales.gmv / sales.units > 500 AND sales.gmv / sales.units <= 1000 then "501 - 1k"
         WHEN sales.gmv / sales.units > 1000 AND sales.gmv / sales.units <= 2500 then "1k - 2.5k"
       WHEN sales.gmv / sales.units > 2500 AND sales.gmv / sales.units <= 5000 then "2.5k - 5k"
       WHEN sales.gmv / sales.units > 5000 AND sales.gmv / sales.units <= 7500 then "5k - 7.5k"
       WHEN sales.gmv / sales.units > 7500 AND sales.gmv / sales.units <= 10000 then "7.5k - 10k"
       WHEN sales.gmv / sales.units > 10000 AND sales.gmv / sales.units <= 15000 then "10k - 15k"
   WHEN sales.gmv / sales.units > 15000 THEN "15k+"
 End as price_bucket,
b.branded_flag as branded_flag,
b.brand_tier as brand_tier,
case when bmp.brand is not null then "Branded" else "Unbranded" end bmp_brand,
case when bmp.brand is not null then sales.brand else "Unbranded" end brand_name, 
'' as d2c_flag,



sum(sales.gmv) as gmv,
sum(sales.units) as units, 
sum(sales.listing_price) as fsp, 
sum(sales.mrp) as mrp,
SUM(CASE WHEN sales.service_profile = 'FBF' THEN sales.units END) AS fbf_units,
AVG(sales.sla_in_days) AS sla,
AVG(date_diff(sales.delivered_date_time, sales.order_date_time, DAY)) AS o2d,
SUM(CASE WHEN sales.sla_in_days <= 0 THEN 1 ELSE 0 END) AS d0_units,
SUM(CASE WHEN sales.sla_in_days <= 1 THEN 1 ELSE 0 END) AS d1_units,
SUM(CASE WHEN sales.sla_in_days <= 2 THEN 1 ELSE 0 END) AS d2_units,
SUM(CASE WHEN sales.sla_in_days <= 4 THEN 1 ELSE 0 END) AS d4_units,
SUM(CASE WHEN sales.sla_in_days <= 6 THEN 1 ELSE 0 END) AS d6_units,
SUM(CASE WHEN sales.unit_is_rtod = TRUE THEN sales.units END) AS rto_Units,
SUM(CASE WHEN sales.unit_is_rtod = TRUE THEN sales.gmv END) AS rto_GMV,
SUM(ret.return_item_quantity) AS rvp_Units,
SUM(ret.return_amount) AS rvp_GMV,
sum(rudata.ru_den) as ru_den, 
sum(rudata.ru_num) as ru_num,
coalesce(gid.group_id,sales.product_id) as group_id

FROM  bigfoot_external_neo.cp_bi_prod_sales__forward_unit_history_fact sales


left join 
  (
  select
  data.productId as product_id,
  data.groupId as group_id
  from bigfoot_snapshot.dart_fkint_ixp_catalog_productrelationshipentity_3_view_total
  where data.relationshipType = "VARIANTS"
  and lower(data.relationshipSubType)  = "default"
  group by 
  data.groupId, 
  data.productId
  ) as gid
  on sales.product_id = gid.product_id


LEFT JOIN  fdp_uploads.ds_fkint_cp_santa_hyperlocal_vertical_bu_mapping_2_0 AS hl 
    ON sales.analytic_vertical = hl.analytic_vertical 
    AND LOWER(hl.bu_final) = 'furniture'  
    and sales.marketplace_id='HYPERLOCAL'

left join
    (
        select
        brand,
        analytic_business_unit
        from fdp_uploads.ds_fkint_analytics_cdo_fk_brand_list_1_0   
        group by        
        brand,
        analytic_business_unit
    ) bmp
    on lower(sales.brand) = lower(bmp.brand) 
    and lower(sales.analytic_business_unit) = lower(bmp.analytic_business_unit)

LEFT JOIN

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
  fdp_uploads.ds_fkint_analytics_cdo_furniture_brand_mapping_analytics_1_0 b
on lower(sales.analytic_super_category) = lower(b.analytic_super_category)
and lower(sales.brand) = lower(b.brand)
and lower(sales.analytic_vertical) = lower(b.analytic_vertical)


LEFT JOIN 
    (
    SELECT 
        forward_unit_id,
        SUM(return_item_quantity) as return_item_quantity,
        SUM(return_amount) as return_amount
    FROM bigfoot_external_neo.scp_rrr__return_l2_id_level_hive_ss_fact
    WHERE UPPER(return_type) = 'CUSTOMER_RETURN' 
            AND (order_item_approve_date_key BETWEEN 20230101 AND CAST(FORMAT_DATE('%Y%m%d', DATE_SUB(CURRENT_DATE(), INTERVAL 1 DAY)) AS INT64))
            AND UPPER(return_item_status) IN ('INIT', 'COMPLETED', 'APPROVED')
    GROUP BY
            forward_unit_id
    ) ret
    ON ret.forward_unit_id = sales.id

LEFT JOIN bigfoot_external_neo.scp_ekl__logistics_geo_hive_dim geo 
on sales.shipping_address_pincode_key =  geo.logistics_geo_hive_dim_key 

    
LEFT JOIN
  (
    SELECT
    ff.fulfill_item_unit_id,
        COUNT(DISTINCT CASE WHEN fulfill_item_unit_granular_shipment_movement_type IN ('L1', 'L2', 'Z1', 'Z2') THEN fulfill_item_unit_id END) AS ru_num,
        COUNT(DISTINCT CASE WHEN fulfill_item_unit_granular_shipment_movement_type IN ('L1', 'L2', 'Z1', 'Z2','N1','N2') THEN fulfill_item_unit_id END) AS ru_den

    FROM bigfoot_external_neo.scp_fulfillment__fulfillment_unit_hive_365_fact ff

    LEFT JOIN bigfoot_external_neo.sp_product__product_categorization_hive_dim cat
        ON  ff.fulfill_item_product_id = cat.product_id
      
    WHERE
        
      (ff.fulfill_item_unit_order_date_key BETWEEN 20230101 AND  CAST(FORMAT_DATE('%Y%m%d', DATE_SUB(CURRENT_DATE(), INTERVAL 1 DAY)) AS INT64))
        AND lower(cat.analytic_business_unit) IN ('furniture')
     
    GROUP BY
        ff.fulfill_item_unit_id
    ) rudata
    ON sales.fulfill_item_unit_id = rudata.fulfill_item_unit_id

WHERE LOWER(sales.status) IN ('in_progress', 'undelivered', 'completed', 'delivered', 'approved', 'shipped', 'ready_to_ship', 'returned', 'return_requested', 'activated')
        AND sales.type  = 'physical'
        AND sales.replacement_for_unit IS NULL
        AND sales.exchange_for_unit IS NULL
        AND sales.is_freebie = FALSE
        AND (sales.marketplace_id IN ('FLIPKART') OR (sales.marketplace_id = 'HYPERLOCAL' AND  hl.analytic_vertical IS NOT NULL))

        AND lower(sales.analytic_business_unit) IN ('furniture')
        AND (sales.order_date_key BETWEEN 20230101 AND  CAST(FORMAT_DATE('%Y%m%d', DATE_SUB(CURRENT_DATE(), INTERVAL 1 DAY)) AS INT64))
        AND sales.is_shopsy_order = FALSE

group by

sales.product_id,
sales.order_date_key ,
sales.marketplace_id ,
sales.analytic_business_unit ,
sales.analytic_super_category ,
sales.analytic_category,
sales.analytic_vertical ,
case when t5.owner ='KAM'  then sales.seller_id else 'Others' end ,
case when lower(b.branded_flag)='branded' then b.brand else 'Others' end ,
geo.city_tier,
geo.zone,

case when sales.is_alpha_seller = TRUE then 'Diamond' else 'Rest of MP' end ,
case when t5.owner = 'KAM' then 'KAM' else 'N-KAM' end ,
case 
    when sales.is_alpha_seller = TRUE and (lower(sales.source_facility_id)  like '%\\_alite\\_%' or lower(sales.source_facility_id) like '%\\_al\\_%') then 'Alite'
    when sales.service_profile = 'FBF' then 'FBF' 
    when sales.service_profile in ('NON_FBF','FBF_LITE') then 'NFBF'
    else 'null'
    end  ,
CASE 
        WHEN sales.gmv / sales.units <= 500 THEN "0 - 500"
        WHEN sales.gmv / sales.units > 500 AND sales.gmv / sales.units <= 1000 then "501 - 1k"
         WHEN sales.gmv / sales.units > 1000 AND sales.gmv / sales.units <= 2500 then "1k - 2.5k"
       WHEN sales.gmv / sales.units > 2500 AND sales.gmv / sales.units <= 5000 then "2.5k - 5k"
       WHEN sales.gmv / sales.units > 5000 AND sales.gmv / sales.units <= 7500 then "5k - 7.5k"
       WHEN sales.gmv / sales.units > 7500 AND sales.gmv / sales.units <= 10000 then "7.5k - 10k"
       WHEN sales.gmv / sales.units > 10000 AND sales.gmv / sales.units <= 15000 then "10k - 15k"
   WHEN sales.gmv / sales.units > 15000 THEN "15k+"
 End,
b.branded_flag ,
b.brand_tier ,
case when bmp.brand is not null then "Branded" else "Unbranded" end,
case when bmp.brand is not null then sales.brand else "Unbranded" end,
coalesce(gid.group_id,sales.product_id)



) as salesdata1 

left join
        (
            select
               group_id,
               -- rating_month,
               sum(sum_rating)/sum(count_rating) as rating,
               sum(sum_rating) as sum_rating,
               sum(count_rating) as count_rating

            from
            (  
                SELECT     
                   coalesce(gid.group_id,rat.data.domainId) as group_id,
                   rat.data.domainId as pid,
                   -- date_dim.year_week_num_in_year as week_yr,
                   sum(rat.data.rating) as sum_rating,
                   count(distinct rat.data.ratingId) as count_rating 

                from bigfoot_snapshot.dart_fkint_cp_ca_ugc_ratingentity_1_view_total as rat

                left join 
                    (
                    select
                    data.productId as product_id,
                    data.groupId as group_id
                    from bigfoot_snapshot.dart_fkint_ixp_catalog_productrelationshipentity_3_view_total
                    where data.relationshipType = "VARIANTS"
                    and lower(data.relationshipSubType)  = "default"
                    group by 
                    data.groupId, 
                    data.productId
                    ) as gid
                    on rat.data.domainId = gid.product_id

                left join bigfoot_external_neo.scp_oms__date_dim_fact date_dim
                
                    on CAST(FORMAT_DATETIME('%Y%m%d',rat.data.createStamp) as INT64) = date_dim.date_dim_key


                where lower(data.domainType) in ('product')
                and lower(data.domain) = 'flipkart'
                and lower(data.status) = 'active'
                and data.certifiedBuyer = TRUE
                and data.aspectid is null                  
               
                
                GROUP BY
                   
                   coalesce(gid.group_id,rat.data.domainId),
                   rat.data.domainId
                   -- date_dim.year_week_num_in_year
                           
            ) rating_tab
            group by
                group_id
                 
        ) pr
    
        on (salesdata1.group_id = pr.group_id)

        group by 

salesdata1.product_id,
salesdata1.group_id,
salesdata1.order_date_key ,
salesdata1.marketplace,
salesdata1.analytic_business_unit ,
salesdata1.analytic_super_category ,
salesdata1.analytic_category,
salesdata1.analytic_vertical ,
salesdata1.seller_id ,
salesdata1.brand ,
salesdata1.city_tier ,
salesdata1.zone ,
salesdata1.is_alpha_seller,
salesdata1.torso_tail_flag ,
salesdata1.kam_nkam_flag,
salesdata1.service_profile,
salesdata1.price_bucket,
salesdata1.branded_flag,
salesdata1.brand_tier ,

salesdata1.bmp_brand,
salesdata1.brand_name,
salesdata1.d2c_flag) as salesdata2


group by 

salesdata2.order_date_key ,
salesdata2.marketplace ,
salesdata2.analytic_business_unit ,
salesdata2.analytic_super_category ,
salesdata2.analytic_category,
salesdata2.analytic_vertical ,
salesdata2.seller_id ,
salesdata2.brand ,
salesdata2.city_tier ,
salesdata2.zone ,
salesdata2.is_alpha_seller ,
salesdata2.torso_tail_flag ,
salesdata2.kam_nkam_flag,
salesdata2.service_profile ,
salesdata2.price_bucket,
salesdata2.branded_flag ,
salesdata2.brand_tier ,
salesdata2.bmp_brand,
salesdata2.brand_name,
salesdata2.d2c_flag,
case when (salesdata2.sum_rating/salesdata2.count_rating) >= 3.2 then 1 else 0 end ,
case when (salesdata2.sum_rating/salesdata2.count_rating) >= 3.4 then 1 else 0 end ,
case when (salesdata2.sum_rating/salesdata2.count_rating) >= 3.6 then 1 else 0 end ,
case when (salesdata2.sum_rating/salesdata2.count_rating) >= 3.8 then 1 else 0 end ,
case when (salesdata2.sum_rating/salesdata2.count_rating) >= 3.85 then 1 else 0 end ,
case when (salesdata2.sum_rating/salesdata2.count_rating) >= 3.9 then 1 else 0 end ,
case when (salesdata2.sum_rating/salesdata2.count_rating) >= 3.95 then 1 else 0 end ,
case when (salesdata2.sum_rating/salesdata2.count_rating) >= 4 then 1 else 0 end ,
case when (salesdata2.sum_rating/salesdata2.count_rating) is null then 1 else 0 end ,  
case when (salesdata2.sum_rating/salesdata2.count_rating) is not null and salesdata2.count_rating < 5 then 1 else 0 end ) as salesdata3


group BY

salesdata3.order_date_key,
salesdata3.marketplace ,
salesdata3.analytic_business_unit ,
salesdata3.analytic_super_category,
salesdata3.analytic_vertical ,
salesdata3.seller_id ,
salesdata3.brand ,
salesdata3.city_tier,
salesdata3.zone ,
salesdata3.is_alpha_seller ,
salesdata3.torso_tail_flag ,
salesdata3.kam_nkam_flag,
salesdata3.service_profile ,
salesdata3.price_bucket,
salesdata3.branded_flag ,
salesdata3.brand_tier ,
salesdata3.brand_name,
salesdata3.d2c_flag,
salesdata3.analytic_category


)

union all 

(
 (
    SELECT
        "pricing" AS domain_flag,
        CAST(pi_data.order_date_key AS INT64) AS order_date_key,
        "" AS marketplace,
        pi_data.analytic_business_unit AS analytic_business_unit,
        pi_data.analytic_super_category AS analytic_super_category,
        pi_data.analytic_vertical AS analytic_vertical,
        pi_data.fk_seller_id AS seller_id,
        pi_data.brand AS brand,
        "" AS city_tier,
        "" AS zone,
        pi_data.fk_seller_type AS is_alpha_seller,
        pi_data.az_seller_type AS az_seller_type,
        pi_data.torso_tail_flag AS torso_tail_flag,
        pi_data.kam_nkam_flag AS kam_nkam_flag,
        "" AS service_profile,
        pi_data.price_bucket AS price_bucket,
        pi_data.branded_flag AS branded_flag,
        pi_data.brand_tier AS brand_tier,
        0.0 AS gmv,
        0 AS units,
        0.0 AS fsp,
        0.0 AS mrp,
        0 AS fbf_units,
        0.0 AS sla,
        0.0 AS o2d,
        0 AS d0_units,
        0 AS d1_units,
        0 AS d2_units,
        0 AS d4_units,
        0 AS d6_units,
        0 AS rto_units,
        0.0 AS rto_gmv,
        0 AS rvp_units,
        0.0 AS rvp_gmv,
        0 AS ru_den,
        0 AS ru_num,
        0 AS pq_rated_units,
        0.0 AS pq_num,
        0 AS pq_rated_good_pq_units,
        0 AS pq_rating_4_units,
        0 AS pq_rating_3_8_units,
        0 AS pq_rating_3_85_units,
        0 AS pq_rating_3_9_units,
        0 AS pq_rated_hygiene_pq_units,
        0 AS pq_unrated_units,
        0 AS pq_lt_5_rated_units,
        SUM(pi_data.fk_price_npi) AS fk_price_npi,
        SUM(pi_data.comp_price_npi) AS comp_price_npi,
        SUM(CASE WHEN fsn_landscape = 'FK_Comp' THEN search_ppvs END) AS fk_comp,
        SUM(CASE WHEN fsn_landscape = 'AI_Comp' THEN search_ppvs END) AS az_comp,
        SUM(search_ppvs) AS search_ppvs,
        0.0 AS ly_gmv,
        0 AS ly_units,
        0.0 AS sds_pure_az,
        0.0 AS sds_oos_attribution_pure_az,
        0.0 AS msku_count,
        0.0 AS output_fes_weighted_asp,
        0.0 AS output_bau_weighted_asp,
        0.0 AS input_bau_weighted_asp,
        0.0 AS input_fes_weighted_asp,
        0.0 AS input_fes_weighted_fsp,
        0.0 AS input_bau_weighted_fsp,
        0.0 AS output_fes_weighted_fsp,
        0.0 AS outut_bau_weighted_fsp,
        pi_data.d2c_flag,
        '' AS analytic_category,
        0 AS transacting_selection_count,
        0 AS new_selection,
        0 AS m_dw,
        0 AS cdw,
        0 AS dw,
        SUM(CASE WHEN pi_data.fsn_coupon_landscape= "FK_Comp" THEN pi_data.search_ppvs ELSE 0 END) AS fk_cd,
        SUM(CASE WHEN pi_data.fsn_coupon_landscape= "AI_Comp" THEN pi_data.search_ppvs ELSE 0 END) AS az_cd,
        SUM(pi_data.fk_price_post_coupon * pi_data.search_ppvs) AS wfcp,
        SUM(pi_data.comp_price_post_coupon * pi_data.search_ppvs) AS wccp
    FROM
        (
            SELECT
                comp.date_key AS order_date_key,
                comp.analytic_business_unit,
                comp.analytic_super_category,
                comp.analytic_vertical,
                CASE WHEN t5.owner ='KAM' THEN comp.fk_seller_id ELSE 'Others' END AS fk_seller_id,
                CASE WHEN LOWER(b.branded_flag)='branded' THEN comp.brand ELSE 'Others' END AS brand,
                CASE WHEN LOWER(comp.fk_seller_type) = 'fk-alpha' THEN 'Diamond'
                     WHEN LOWER(comp.fk_seller_type) = 'fk-non_alpha' THEN 'Rest of MP'
                     ELSE 'Others' END AS fk_seller_type,
                CASE WHEN LOWER(comp.az_seller_type)='az-alpha' THEN 'Diamond'
                     WHEN LOWER(comp.az_seller_type)='az-non_alpha' THEN 'Rest of MP'
                     ELSE 'Others' END AS az_seller_type,
                '' AS torso_tail_flag,
                CASE WHEN t5.owner = 'KAM' THEN 'KAM' ELSE 'N-KAM' END AS kam_nkam_flag,
                '' AS d2c_flag,
                CASE
                    WHEN fk_price BETWEEN 0 AND 500 THEN '0-500'
                    WHEN fk_price BETWEEN 501 AND 1000 THEN '501-1k'
                    WHEN fk_price BETWEEN 1001 AND 2500 THEN '1k-2.5k'
                    WHEN fk_price BETWEEN 2501 AND 5000 THEN '2.5k-5k'
                    WHEN fk_price BETWEEN 5001 AND 7500 THEN '5k-7.5k'
                    WHEN fk_price BETWEEN 7501 AND 10000 THEN '7.5k-10k'
                    WHEN fk_price BETWEEN 10001 AND 15000 THEN '10k-15k'
                    WHEN fk_price > 15000 THEN '15k+'
                    ELSE "" END AS price_bucket,
                b.branded_flag,
                b.brand_tier,
                fsn_landscape,
                SUM(search_ppvs) AS search_ppvs,
                SUM(fk_price * search_ppvs) AS fk_price_npi,
                SUM(comp_price * search_ppvs) AS comp_price_npi,
                fk_price_post_coupon,
                comp_price - COALESCE(comp_coupon_discount,0) AS comp_price_post_coupon,
                CASE
                    WHEN fk_price_post_coupon < 1000 AND (comp_price-COALESCE(comp_coupon_discount,0))/NULLIF(fk_price_post_coupon,0) > 1.02 THEN "FK_Comp"
                    WHEN fk_price_post_coupon < 1000 AND (comp_price-COALESCE(comp_coupon_discount,0))/NULLIF(fk_price_post_coupon,0) < 0.98 THEN "AI_Comp"
                    WHEN fk_price_post_coupon >= 1000 AND (comp_price-COALESCE(comp_coupon_discount,0))/NULLIF(fk_price_post_coupon,0) > 1.01 THEN "FK_Comp"
                    WHEN fk_price_post_coupon >= 1000 AND (comp_price-COALESCE(comp_coupon_discount,0))/NULLIF(fk_price_post_coupon,0) < 0.99 THEN "AI_Comp"
                    ELSE "Parity"
                END AS fsn_coupon_landscape
            FROM bigfoot_external_neo.analytics_cdo__unweighted_comp_base_hist_fact AS comp
            LEFT JOIN (
                SELECT seller_id, MIN(managed_by) AS owner
                FROM fdp_uploads.ds_fkint_analytics_cdo_seller_kam_ukam_mapping_1_0
                GROUP BY seller_id
            ) AS t5 ON comp.fk_seller_id = t5.seller_id
            LEFT JOIN fdp_uploads.ds_fkint_analytics_cdo_furniture_brand_mapping_analytics_1_0 b
                ON LOWER(comp.analytic_super_category) = LOWER(b.analytic_super_category)
               AND LOWER(comp.brand) = LOWER(b.brand)
               AND LOWER(comp.analytic_vertical) = LOWER(b.analytic_vertical)
            WHERE
                CAST(date_key AS INT64) BETWEEN 20230101 AND CAST(FORMAT_DATE('%Y%m%d', DATE_SUB(CURRENT_DATE(), INTERVAL 1 DAY)) AS INT64)
                AND competitor IN ('AI')
                AND LOWER(comp.ci_business_unit) = "furniture"
                AND LOWER(comp.analytic_business_unit) = "furniture"
            GROUP BY
                comp.date_key, comp.analytic_business_unit, comp.analytic_super_category, comp.analytic_vertical,
                CASE WHEN t5.owner ='KAM' THEN comp.fk_seller_id ELSE 'Others' END,
                CASE WHEN LOWER(b.branded_flag)='branded' THEN comp.brand ELSE 'Others' END,
                CASE WHEN LOWER(comp.fk_seller_type) = 'fk-alpha' THEN 'Diamond'
                     WHEN LOWER(comp.fk_seller_type) = 'fk-non_alpha' THEN 'Rest of MP'
                     ELSE 'Others' END,
                CASE WHEN LOWER(comp.az_seller_type)='az-alpha' THEN 'Diamond'
                     WHEN LOWER(comp.az_seller_type)='az-non_alpha' THEN 'Rest of MP'
                     ELSE 'Others' END,
                CASE WHEN t5.owner = 'KAM' THEN 'KAM' ELSE 'N-KAM' END,
                CASE
                    WHEN fk_price BETWEEN 0 AND 500 THEN '0-500'
                    WHEN fk_price BETWEEN 501 AND 1000 THEN '501-1k'
                    WHEN fk_price BETWEEN 1001 AND 2500 THEN '1k-2.5k'
                    WHEN fk_price BETWEEN 2501 AND 5000 THEN '2.5k-5k'
                    WHEN fk_price BETWEEN 5001 AND 7500 THEN '5k-7.5k'
                    WHEN fk_price BETWEEN 7501 AND 10000 THEN '7.5k-10k'
                    WHEN fk_price BETWEEN 10001 AND 15000 THEN '10k-15k'
                    WHEN fk_price > 15000 THEN '15k+'
                    ELSE "" END,
                b.branded_flag, b.brand_tier, fsn_landscape, fk_price_post_coupon, comp_price, comp_coupon_discount
        ) AS pi_data
    GROUP BY
        pi_data.order_date_key, pi_data.analytic_business_unit, pi_data.analytic_super_category,
        pi_data.analytic_vertical, pi_data.fk_seller_id, pi_data.brand,
        pi_data.fk_seller_type, pi_data.az_seller_type, pi_data.torso_tail_flag,
        pi_data.kam_nkam_flag, pi_data.price_bucket, pi_data.branded_flag,
        pi_data.brand_tier, pi_data.d2c_flag
    )

)


union all 

(

    select 
"last year" as domain_flag,
(sales.order_date_key) + 10000 as order_date_key, 
sales.marketplace_id as marketplace, 
sales.analytic_business_unit as analytic_business_unit, 
sales.analytic_super_category as analytic_super_category, 
sales.analytic_vertical as analytic_vertical,
case when t5.owner ='KAM'  then sales.seller_id else 'Others' end as seller_id,
case when lower(b.branded_flag)='branded' then b.brand else 'Others' end as brand,
geo.city_tier as city_tier, 
geo.zone as zone, 
case when sales.is_alpha_seller = TRUE then 'Diamond' else 'Rest of MP' end as is_alpha_seller, 
"" as az_seller_type,
'' as torso_tail_flag,
case when t5.owner = 'KAM' then 'KAM' else 'N-KAM' end as kam_nkam_flag,
case 
    when sales.is_alpha_seller = TRUE and (lower(sales.source_facility_id)  like '%\\_alite\\_%' or lower(sales.source_facility_id) like '%\\_al\\_%') then 'Alite'
    when sales.service_profile = 'FBF' then 'FBF' 
    when sales.service_profile in ('NON_FBF','FBF_LITE') then 'NFBF'
    else 'null'
    end as service_profile,
CASE 
        WHEN sales.gmv / sales.units <= 500 THEN "0 - 500"
        WHEN sales.gmv / sales.units > 500 AND sales.gmv / sales.units <= 1000 then "501 - 1k"
         WHEN sales.gmv / sales.units > 1000 AND sales.gmv / sales.units <= 2500 then "1k - 2.5k"
       WHEN sales.gmv / sales.units > 2500 AND sales.gmv / sales.units <= 5000 then "2.5k - 5k"
       WHEN sales.gmv / sales.units > 5000 AND sales.gmv / sales.units <= 7500 then "5k - 7.5k"
       WHEN sales.gmv / sales.units > 7500 AND sales.gmv / sales.units <= 10000 then "7.5k - 10k"
       WHEN sales.gmv / sales.units > 10000 AND sales.gmv / sales.units <= 15000 then "10k - 15k"
   WHEN sales.gmv / sales.units > 15000 THEN "15k+"
 End as price_bucket,
b.branded_flag as branded_flag,
b.brand_tier as brand_tier,
 0.0 as gmv,
    0 as units,
    0.0 as fsp,
    0.0 as mrp,
    0 as fbf_units,
    0.0 as sla,
    0.0 as o2d,
    0 as d0_units,
    0 as d1_units,
    0 as d2_units,
    0 as d4_units,
    0 as d6_units,
    0 as rto_units,
    0.0 as rto_gmv,
    0 as rvp_units,
    0.0 as rvp_gmv,
    0 as ru_den,
    0 as ru_num,
    0 as pq_rated_units,
    0.0 as pq_num,
    0 as pq_rated_good_pq_units,
    0 as pq_rating_4_units,
    0 as pq_rating_3_8_units,
    0 as pq_rating_3_85_units,
    0 as pq_rating_3_9_units,
    0 as pq_rated_hygiene_pq_units,
    0 as pq_unrated_units,
    0 as pq_lt_5_rated_units,
0  as fk_price_npi,
0  as comp_price_npi,
0  as fk_comp,
0  as az_comp,
0  as search_ppvs,

sum(sales.gmv) as ly_gmv,
sum(sales.units) as ly_units,
0.0 as  sds_pure_az,
0.0 as sds_oos_attribution_pure_az,
0.0 as msku_count,
0.0  as output_fes_weighted_asp,
0.0 as output_bau_weighted_asp,
0.0 as input_bau_weighted_asp,
0.0 as input_fes_weighted_asp,
0.0 as input_fes_weighted_fsp,
0.0 as input_bau_weighted_fsp,
0.0 as output_fes_weighted_fsp,
0.0 as outut_bau_weighted_fsp,
'' as d2c_flag,
sales.analytic_category,

0 as transacting_selection_count,
0 as new_selection,
0 as m_dw,
0 as cdw,
0 as dw,
0 as fk_cd,
0 as az_cd,
0 as wfcp,
0 as wccp


FROM  bigfoot_external_neo.cp_bi_prod_sales__forward_unit_history_fact sales


LEFT JOIN  fdp_uploads.ds_fkint_cp_santa_hyperlocal_vertical_bu_mapping_2_0 AS hl 
    ON sales.analytic_vertical = hl.analytic_vertical 
    AND LOWER(hl.bu_final) = 'furniture'  
    and sales.marketplace_id='HYPERLOCAL'

LEFT JOIN

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
  fdp_uploads.ds_fkint_analytics_cdo_furniture_brand_mapping_analytics_1_0 b
on lower(sales.analytic_super_category) = lower(b.analytic_super_category)
and lower(sales.brand) = lower(b.brand)
and lower(sales.analytic_vertical) = lower(b.analytic_vertical)


LEFT JOIN 
    (
    SELECT 
        forward_unit_id,
        SUM(return_item_quantity) as return_item_quantity,
        SUM(return_amount) as return_amount
    FROM bigfoot_external_neo.scp_rrr__return_l2_id_level_hive_ss_fact
    WHERE UPPER(return_type) = 'CUSTOMER_RETURN' 
            AND (order_item_approve_date_key BETWEEN 20230101 AND CAST(FORMAT_DATE('%Y%m%d', DATE_SUB(CURRENT_DATE(), INTERVAL 1 DAY)) AS INT64))
            AND UPPER(return_item_status) IN ('INIT', 'COMPLETED', 'APPROVED')
    GROUP BY
            forward_unit_id
    ) ret
    ON ret.forward_unit_id = sales.id

LEFT JOIN bigfoot_external_neo.scp_ekl__logistics_geo_hive_dim geo 
on sales.shipping_address_pincode_key =  geo.logistics_geo_hive_dim_key 


WHERE LOWER(sales.status) IN ('in_progress', 'undelivered', 'completed', 'delivered', 'approved', 'shipped', 'ready_to_ship', 'returned', 'return_requested', 'activated')
        AND sales.type  = 'physical'
        AND sales.replacement_for_unit IS NULL
        AND sales.exchange_for_unit IS NULL
        AND sales.is_freebie = FALSE
        AND (sales.marketplace_id IN ('FLIPKART') OR (sales.marketplace_id = 'HYPERLOCAL' AND  hl.analytic_vertical IS NOT NULL))
    
        AND lower(sales.analytic_business_unit) IN ('furniture')
        AND (sales.order_date_key BETWEEN 20230101 AND  CAST(FORMAT_DATE('%Y%m%d', DATE_SUB(CURRENT_DATE(), INTERVAL 1 DAY)) AS INT64))
        AND sales.is_shopsy_order = FALSE

group by
(sales.order_date_key) + 10000 ,
sales.marketplace_id,
sales.analytic_business_unit ,
sales.analytic_super_category ,
sales.analytic_vertical,
case when t5.owner ='KAM'  then sales.seller_id else 'Others' end ,
case when lower(b.branded_flag)='branded' then b.brand else 'Others' end ,
geo.city_tier ,
geo.zone,
case when sales.is_alpha_seller = TRUE then 'Diamond' else 'Rest of MP' end ,
case when t5.owner = 'KAM' then 'KAM' else 'N-KAM' end ,
case 
    when sales.is_alpha_seller = TRUE and (lower(sales.source_facility_id)  like '%\\_alite\\_%' or lower(sales.source_facility_id) like '%\\_al\\_%') then 'Alite'
    when sales.service_profile = 'FBF' then 'FBF' 
    when sales.service_profile in ('NON_FBF','FBF_LITE') then 'NFBF'
    else 'null'
    end ,
CASE 
        WHEN sales.gmv / sales.units <= 500 THEN "0 - 500"
        WHEN sales.gmv / sales.units > 500 AND sales.gmv / sales.units <= 1000 then "501 - 1k"
         WHEN sales.gmv / sales.units > 1000 AND sales.gmv / sales.units <= 2500 then "1k - 2.5k"
       WHEN sales.gmv / sales.units > 2500 AND sales.gmv / sales.units <= 5000 then "2.5k - 5k"
       WHEN sales.gmv / sales.units > 5000 AND sales.gmv / sales.units <= 7500 then "5k - 7.5k"
       WHEN sales.gmv / sales.units > 7500 AND sales.gmv / sales.units <= 10000 then "7.5k - 10k"
       WHEN sales.gmv / sales.units > 10000 AND sales.gmv / sales.units <= 15000 then "10k - 15k"
   WHEN sales.gmv / sales.units > 15000 THEN "15k+"
 End ,
b.branded_flag ,
b.brand_tier,
sales.analytic_category
)

union all 

(
SELECT
'sds' as domain_flag,
    sds.computation_date  as order_date_key,
    '' as marketplace,
sds.bu as analytic_business_unit,
   sds.super_category as analytic_super_category,
pt.analytic_vertical as analytic_vertical,
"" as seller_id,

CASE WHEN LOWER(b.branded_flag) = 'branded'then sds.final_brand else 'Others' end as brand,
"" as city_tier,
"" as zone, 
"" as is_alpha_seller,
"" as az_seller_type,
'' as torso_tail_flag,

"" as kam_nkam_flag,
"" as service_profile,
"" as price_bucket,
b.branded_flag as branded_flag,
b.brand_tier as brand_tier,
0.0 as gmv,
    0 as units,
    0.0 as fsp,
    0.0 as mrp,
    0 as fbf_units,
    0.0 as sla,
    0.0 as o2d,
    0 as d0_units,
    0 as d1_units,
    0 as d2_units,
    0 as d4_units,
    0 as d6_units,
    0 as rto_units,
    0.0 as rto_gmv,
    0 as rvp_units,
    0.0 as rvp_gmv,
    0 as ru_den,
    0 as ru_num,
    0 as pq_rated_units,
    0.0 as pq_num,
    0 as pq_rated_good_pq_units,
    0 as pq_rating_4_units,
    0 as pq_rating_3_8_units,
    0 as pq_rating_3_85_units,
    0 as pq_rating_3_9_units,
    0 as pq_rated_hygiene_pq_units,
    0 as pq_unrated_units,
    0 as pq_lt_5_rated_units,
0  as fk_price_npi,
0  as comp_price_npi,
0  as fk_comp,
0  as az_comp,
0  as search_ppvs,
0.0 as ly_gmv,
0 as ly_units,
    SUM(case when fk_product_count >= az_product_count then 1.0
        when fk_product_count >= 0.9 * az_product_count then 0.9
        when fk_product_count >= 0.6 * az_product_count then 0.4
        else 0.0 end) as sds_pure_az,

    SUM(case when fk_product_count + active_oos >= az_product_count then 1.0
        when fk_product_count + active_oos >= 0.9 * (az_product_count) then 0.9
        when fk_product_count + active_oos >= 0.6 * (az_product_count) then 0.4
        else 0.0 end) as sds_oos_attribution_pure_az,

    SUM(msku_count) as msku_count,
    0.0  as output_fes_weighted_asp,
0.0 as output_bau_weighted_asp,
0.0 as input_bau_weighted_asp,
0.0 as input_fes_weighted_asp,
0.0 as input_fes_weighted_fsp,
0.0 as input_bau_weighted_fsp,
0.0 as output_fes_weighted_fsp,
0.0 as outut_bau_weighted_fsp,
"" as d2c_flag,
"" as analytic_category,
0 as transacting_selection_count,
0 as new_selection,
0 as m_dw,
0 as cdw,
0 as dw,
0 as fk_cd,
0 as az_cd,
0 as wfcp,
0 as wccp


   
FROM fdp_uploads.ds_fkint_analytics_cdo_branded_sds_non_ls_marketscores_weekly_fact_1_1 sds

left JOIN fdp_uploads.ds_fkint_analytics_cdo_product_type_and_vertical_mapping_1_0 pt  
    on sds.product_type = pt.product_type



--branded_d2c_priority_PnM
LEFT JOIN
(select 
analytic_super_category,
brand,
min(a.branded_flag) as branded_flag,
min(a.brand_tier) as brand_tier
 from
  fdp_uploads.ds_fkint_analytics_cdo_furniture_brand_mapping_analytics_1_0 as a
group by 
analytic_super_category,
brand) as b

ON LOWER(sds.super_category) = LOWER(b.analytic_super_category)
    AND LOWER(sds.final_brand) = LOWER(b.brand)


WHERE is_branded = TRUE
and exclude_final = 0
and Sc_exclude = 0
and hygiene_msku = 1
and lower(bu) = 'furniture'
and sds.computation_date between 20230101 and CAST(FORMAT_DATE('%Y%m%d', DATE_SUB(CURRENT_DATE(), INTERVAL 1 DAY)) AS INT64)

GROUP BY
    sds.computation_date ,
   
sds.bu,
   sds.super_category ,
pt.analytic_vertical ,

CASE WHEN LOWER(b.branded_flag) = 'branded'then sds.final_brand else 'Others' end,

b.branded_flag ,
b.brand_tier

)

union all 

(

    SELECT 
"price drop" as domain_flag,
sales.order_date_key as order_date_key,
sales.marketplace as marketplace,
sales.analytic_business_unit as analytic_business_unit,
sales.analytic_super_category as analytic_super_category,
sales.analytic_vertical as analytic_vertical,
case when t5.owner ='KAM'  then sales.seller_id else 'Others' end as seller_id,
case when lower(b.branded_flag)='branded' then b.brand else 'Others' end as brand,
sales.city_tier as city_tier,
sales.zone as zone,
sales.is_alpha_seller as is_alpha_seller,
"" as az_seller_type,
'' as torso_tail_flag,
case when t5.owner = 'KAM' then 'KAM' else 'N-KAM' end as kam_nkam_flag,
sales.service_profile,
sales.price_bucket,
b.branded_flag as branded_flag, 
b.brand_tier as brand_tier,
 0.0 as gmv,
    0 as units,
    0.0 as fsp,
    0.0 as mrp,
    0 as fbf_units,
    0.0 as sla,
    0.0 as o2d,
    0 as d0_units,
    0 as d1_units,
    0 as d2_units,
    0 as d4_units,
    0 as d6_units,
    0 as rto_units,
    0.0 as rto_gmv,
    0 as rvp_units,
    0.0 as rvp_gmv,
    0 as ru_den,
    0 as ru_num,
    0 as pq_rated_units,
    0.0 as pq_num,
    0 as pq_rated_good_pq_units,
    0 as pq_rating_4_units,
    0 as pq_rating_3_8_units,
    0 as pq_rating_3_85_units,
    0 as pq_rating_3_9_units,
    0 as pq_rated_hygiene_pq_units,
    0 as pq_unrated_units,
    0 as pq_lt_5_rated_units,
0  as fk_price_npi,
0  as comp_price_npi,
0  as fk_comp,
0  as az_comp,
0  as search_ppvs,
0.0 as ly_gmv,
0 as ly_units,
0.0 as  sds_pure_az,
0.0 as sds_oos_attribution_pure_az,
0.0 as msku_count,
SUM(sales.output_fes_weighted_asp) as output_fes_weighted_asp,
SUM(sales.output_bau_weighted_asp) as output_bau_weighted_asp,
SUM(sales.input_bau_weighted_asp) as input_bau_weighted_asp,
SUM(sales.input_fes_weighted_asp) as input_fes_weighted_asp,
SUM(sales.input_fes_weighted_fsp) as input_fes_weighted_fsp,
SUM(sales.input_bau_weighted_fsp) as input_bau_weighted_fsp,
SUM(sales.output_fes_weighted_fsp) as output_fes_weighted_fsp,
SUM(sales.outut_bau_weighted_fsp) as outut_bau_weighted_fsp,
'' as d2c_flag,
sales.analytic_category as analytic_category,
0 as transacting_selection_count,
0 as new_selection,
0 as m_dw,
0 as cdw,
0 as dw,
0 as fk_cd,
0 as az_cd,
0 as wfcp,
0 as wccp


from

(
SELECT

a.order_date_key as order_date_key,
a.marketplace as marketplace,
a.analytic_business_unit as analytic_business_unit,
a.analytic_super_category as analytic_super_category,
a.analytic_category as analytic_category,
a.analytic_vertical as analytic_vertical,
a.seller_id as seller_id, 
a.brand as brand, 
a. city_tier,
a.zone,
a.is_alpha_seller,
a.service_profile,
a.price_bucket,
a.product_id,
a.listing_id,

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
tot_bau_gmv

FROM

(
SELECT
 fes.order_date_key as order_date_key,
    bau.marketplace as marketplace,
    bau.analytic_business_unit as analytic_business_unit,
    bau.analytic_super_category as analytic_super_category,
    bau.analytic_category as analytic_category,
    bau.analytic_vertical as analytic_vertical,
    bau.seller_id as seller_id,
    bau.brand as brand,
    bau.city_tier as city_tier,
    bau.zone as zone,
    bau.is_alpha_seller as is_alpha_seller,
    bau.service_profile as service_profile,
    bau.price_bucket as price_bucket,
   bau.product_id as product_id,
    bau.listing_id as listing_id,
   
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
    bau.gmv/bau.units as bau_asp

from

(
SELECT
    sales.marketplace_id as marketplace,
    sales.analytic_business_unit as analytic_business_unit, 
   sales.analytic_super_category as analytic_super_category,
   sales.analytic_category as analytic_category,
   sales.analytic_vertical as analytic_vertical,
    sales.seller_id as seller_id,
sales.brand as brand,
geo.city_tier as city_tier, 
geo.zone as zone, 
case when sales.is_alpha_seller = TRUE then 'Diamond' else 'Rest of MP' end as is_alpha_seller, 
case 
    when sales.is_alpha_seller = TRUE and (lower(sales.source_facility_id)  like '%\\_alite\\_%' or lower(sales.source_facility_id) like '%\\_al\\_%') then 'Alite'
    when sales.service_profile = 'FBF' then 'FBF' 
    when sales.service_profile in ('NON_FBF','FBF_LITE') then 'NFBF'
    else 'null'
    end as service_profile,
CASE 
        WHEN sales.gmv / sales.units <= 500 THEN "0 - 500"
        WHEN sales.gmv / sales.units > 500 AND sales.gmv / sales.units <= 1000 then "501 - 1k"
         WHEN sales.gmv / sales.units > 1000 AND sales.gmv / sales.units <= 2500 then "1k - 2.5k"
       WHEN sales.gmv / sales.units > 2500 AND sales.gmv / sales.units <= 5000 then "2.5k - 5k"
       WHEN sales.gmv / sales.units > 5000 AND sales.gmv / sales.units <= 7500 then "5k - 7.5k"
       WHEN sales.gmv / sales.units > 7500 AND sales.gmv / sales.units <= 10000 then "7.5k - 10k"
       WHEN sales.gmv / sales.units > 10000 AND sales.gmv / sales.units <= 15000 then "10k - 15k"
   WHEN sales.gmv / sales.units > 15000 THEN "15k+"
 End as price_bucket,
    sales.product_id as product_id,
   sales.listing_id as listing_id,
   SUM(units) as units,
   SUM(gmv) as gmv,
   SUM(listing_price) as lp

FROM bigfoot_external_neo.cp_bi_prod_sales__forward_unit_history_fact sales

LEFT JOIN  fdp_uploads.ds_fkint_cp_santa_hyperlocal_vertical_bu_mapping_2_0 AS hl 
    ON sales.analytic_vertical = hl.analytic_vertical 
    AND LOWER(hl.bu_final) = 'furniture'  
    and sales.marketplace_id='HYPERLOCAL'

LEFT JOIN bigfoot_external_neo.scp_ekl__logistics_geo_hive_dim geo 
on sales.shipping_address_pincode_key =  geo.logistics_geo_hive_dim_key 


WHERE lower(sales.status) in ('in_progress','undelivered','completed','delivered','approved','shipped','ready_to_ship','returned', 'return_requested','activated')
   AND sales.type  = 'physical'
   AND sales.replacement_for_unit IS NULL
   AND sales.exchange_for_unit IS NULL
   AND sales.is_freebie =FALSE
   AND (sales.marketplace_id IN ('FLIPKART') OR (sales.marketplace_id = 'HYPERLOCAL' AND  hl.analytic_vertical IS NOT NULL))
   AND sales.is_shopsy_order =FALSE
   AND lower(sales.analytic_business_unit) IN ('furniture')
   AND order_date_key between 20241201 and 20241231

GROUP BY
     sales.marketplace_id ,
    sales.analytic_business_unit ,
   sales.analytic_super_category ,
   sales.analytic_category,
   sales.analytic_vertical ,
    sales.seller_id ,
sales.brand,
geo.city_tier ,
geo.zone ,
case when sales.is_alpha_seller = TRUE then 'Diamond' else 'Rest of MP' end , 
 case 
    when sales.is_alpha_seller = TRUE and (lower(sales.source_facility_id)  like '%\\_alite\\_%' or lower(sales.source_facility_id) like '%\\_al\\_%') then 'Alite'
    when sales.service_profile = 'FBF' then 'FBF' 
    when sales.service_profile in ('NON_FBF','FBF_LITE') then 'NFBF'
    else 'null'
    end ,
CASE 
        WHEN sales.gmv / sales.units <= 500 THEN "0 - 500"
        WHEN sales.gmv / sales.units > 500 AND sales.gmv / sales.units <= 1000 then "501 - 1k"
         WHEN sales.gmv / sales.units > 1000 AND sales.gmv / sales.units <= 2500 then "1k - 2.5k"
       WHEN sales.gmv / sales.units > 2500 AND sales.gmv / sales.units <= 5000 then "2.5k - 5k"
       WHEN sales.gmv / sales.units > 5000 AND sales.gmv / sales.units <= 7500 then "5k - 7.5k"
       WHEN sales.gmv / sales.units > 7500 AND sales.gmv / sales.units <= 10000 then "7.5k - 10k"
       WHEN sales.gmv / sales.units > 10000 AND sales.gmv / sales.units <= 15000 then "10k - 15k"
   WHEN sales.gmv / sales.units > 15000 THEN "15k+"
 End ,
    sales.product_id ,
   sales.listing_id 
) bau

INNER JOIN

(
SELECT
   sales.listing_id,
   order_date_key  as order_date_key,
   SUM(units) as units,
   SUM(gmv) as gmv,
   SUM(listing_price) as lp
 
FROM bigfoot_external_neo.cp_bi_prod_sales__forward_unit_history_fact sales

LEFT JOIN  fdp_uploads.ds_fkint_cp_santa_hyperlocal_vertical_bu_mapping_2_0 AS hl 
    ON sales.analytic_vertical = hl.analytic_vertical 
    AND LOWER(hl.bu_final) = 'furniture'  
    and sales.marketplace_id='HYPERLOCAL'

WHERE lower(sales.status) in ('in_progress','undelivered','completed','delivered','approved','shipped','ready_to_ship','returned', 'return_requested','activated')
   AND sales.type  = 'physical'
   AND sales.replacement_for_unit IS NULL
   AND sales.exchange_for_unit IS NULL
   AND sales.is_freebie =FALSE
   AND (sales.marketplace_id IN ('FLIPKART') OR (sales.marketplace_id = 'HYPERLOCAL' AND  hl.analytic_vertical IS NOT NULL))
   AND sales.is_shopsy_order =FALSE
   AND lower(sales.analytic_business_unit) IN ('furniture')
   AND order_date_key between 20250101 and CAST(FORMAT_DATE('%Y%m%d', DATE_SUB(CURRENT_DATE(), INTERVAL 1 DAY)) AS INT64)

GROUP BY
   sales.listing_id,
   order_date_key
) fes
ON bau.listing_id = fes.listing_id
) as a


)    as sales

LEFT JOIN

(
SELECT 
 seller_id,
 MIN(managed_by) as owner
 FROM fdp_uploads.ds_fkint_analytics_cdo_seller_kam_ukam_mapping_1_0
 GROUP BY
 seller_id
) as t5
on sales.seller_id = t5.seller_id

--branded_d2c_priority_PnM
LEFT JOIN
  fdp_uploads.ds_fkint_analytics_cdo_furniture_brand_mapping_analytics_1_0 b
on lower(sales.analytic_super_category) = lower(b.analytic_super_category)
and lower(sales.brand) = lower(b.brand)
and lower(sales.analytic_vertical) = lower(b.analytic_vertical)

group by 
sales.order_date_key ,
sales.marketplace ,
sales.analytic_business_unit ,
sales.analytic_super_category ,
sales.analytic_vertical ,
case when t5.owner ='KAM'  then sales.seller_id else 'Others' end ,

case when lower(b.branded_flag)='branded' then b.brand else 'Others' end ,
sales.city_tier ,
sales.zone ,
sales.is_alpha_seller ,

case when t5.owner = 'KAM' then 'KAM' else 'N-KAM' end ,
sales.service_profile,
sales.price_bucket,
b.branded_flag , 
b.brand_tier,
sales.analytic_category
)


union all 

(




    select 
"transacting_selection" as domain_flag,
(sales.order_date_key) as order_date_key, 
sales.marketplace_id as marketplace, 
sales.analytic_business_unit as analytic_business_unit, 
sales.analytic_super_category as analytic_super_category, 
sales.analytic_vertical as analytic_vertical,
case when t5.owner ='KAM'  then sales.seller_id else 'Others' end as seller_id,
case when lower(b.branded_flag)='branded' then b.brand else 'Others' end as brand,
'' as city_tier, 
'' as zone, 
case when sales.is_alpha_seller = TRUE then 'Diamond' else 'Rest of MP' end as is_alpha_seller, 
"" as az_seller_type,
'' as torso_tail_flag,
case when t5.owner = 'KAM' then 'KAM' else 'N-KAM' end as kam_nkam_flag,
case 
    when sales.is_alpha_seller = TRUE and (lower(sales.source_facility_id)  like '%\\_alite\\_%' or lower(sales.source_facility_id) like '%\\_al\\_%') then 'Alite'
    when sales.service_profile = 'FBF' then 'FBF' 
    when sales.service_profile in ('NON_FBF','FBF_LITE') then 'NFBF'
    else 'null'
    end as service_profile,
CASE 
        WHEN sales.gmv / sales.units <= 500 THEN "0 - 500"
        WHEN sales.gmv / sales.units > 500 AND sales.gmv / sales.units <= 1000 then "501 - 1k"
         WHEN sales.gmv / sales.units > 1000 AND sales.gmv / sales.units <= 2500 then "1k - 2.5k"
       WHEN sales.gmv / sales.units > 2500 AND sales.gmv / sales.units <= 5000 then "2.5k - 5k"
       WHEN sales.gmv / sales.units > 5000 AND sales.gmv / sales.units <= 7500 then "5k - 7.5k"
       WHEN sales.gmv / sales.units > 7500 AND sales.gmv / sales.units <= 10000 then "7.5k - 10k"
       WHEN sales.gmv / sales.units > 10000 AND sales.gmv / sales.units <= 15000 then "10k - 15k"
   WHEN sales.gmv / sales.units > 15000 THEN "15k+"
 End as price_bucket,
b.branded_flag as branded_flag,
b.brand_tier as brand_tier,
 0.0 as gmv,
    0 as units,
    0.0 as fsp,
    0.0 as mrp,
    0 as fbf_units,
    0.0 as sla,
    0.0 as o2d,
    0 as d0_units,
    0 as d1_units,
    0 as d2_units,
    0 as d4_units,
    0 as d6_units,
    0 as rto_units,
    0.0 as rto_gmv,
    0 as rvp_units,
    0.0 as rvp_gmv,
    0 as ru_den,
    0 as ru_num,
    0 as pq_rated_units,
    0.0 as pq_num,
    0 as pq_rated_good_pq_units,
    0 as pq_rating_4_units,
    0 as pq_rating_3_8_units,
    0 as pq_rating_3_85_units,
    0 as pq_rating_3_9_units,
    0 as pq_rated_hygiene_pq_units,
    0 as pq_unrated_units,
    0 as pq_lt_5_rated_units,
0  as fk_price_npi,
0  as comp_price_npi,
0  as fk_comp,
0  as az_comp,
0  as search_ppvs,

0.0 as ly_gmv,
0 as ly_units,
0.0 as  sds_pure_az,
0.0 as sds_oos_attribution_pure_az,
0.0 as msku_count,
0.0  as output_fes_weighted_asp,
0.0 as output_bau_weighted_asp,
0.0 as input_bau_weighted_asp,
0.0 as input_fes_weighted_asp,
0.0 as input_fes_weighted_fsp,
0.0 as input_bau_weighted_fsp,
0.0 as output_fes_weighted_fsp,
0.0 as outut_bau_weighted_fsp,
'' as d2c_flag,
sales.analytic_category,
count(distinct(sales.listing_id)) as transacting_selection_count,

0 as new_selection,
0 as m_dw,
0 as cdw,
0 as dw,
0 as fk_cd,
0 as az_cd,
0 as wfcp,
0 as wccp


FROM  bigfoot_external_neo.cp_bi_prod_sales__forward_unit_history_fact sales


LEFT JOIN  fdp_uploads.ds_fkint_cp_santa_hyperlocal_vertical_bu_mapping_2_0 AS hl 
    ON sales.analytic_vertical = hl.analytic_vertical 
    AND LOWER(hl.bu_final) = 'furniture'  
    and sales.marketplace_id='HYPERLOCAL'

LEFT JOIN

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
  fdp_uploads.ds_fkint_analytics_cdo_furniture_brand_mapping_analytics_1_0 b
on lower(sales.analytic_super_category) = lower(b.analytic_super_category)
and lower(sales.brand) = lower(b.brand)
and lower(sales.analytic_vertical) = lower(b.analytic_vertical)



WHERE LOWER(sales.status) IN ('in_progress', 'undelivered', 'completed', 'delivered', 'approved', 'shipped', 'ready_to_ship', 'returned', 'return_requested', 'activated')
        AND sales.type  = 'physical'
        AND sales.replacement_for_unit IS NULL
        AND sales.exchange_for_unit IS NULL
        AND sales.is_freebie = FALSE
        AND (sales.marketplace_id IN ('FLIPKART') OR (sales.marketplace_id = 'HYPERLOCAL' AND  hl.analytic_vertical IS NOT NULL))
    
        AND lower(sales.analytic_business_unit) IN ('furniture')
        AND (sales.order_date_key BETWEEN 20230101 AND  CAST(FORMAT_DATE('%Y%m%d', DATE_SUB(CURRENT_DATE(), INTERVAL 1 DAY)) AS INT64))
        AND sales.is_shopsy_order = FALSE

group by

(sales.order_date_key) ,
sales.marketplace_id ,
sales.analytic_business_unit ,
sales.analytic_super_category ,
sales.analytic_vertical ,
case when t5.owner ='KAM'  then sales.seller_id else 'Others' end ,
case when lower(b.branded_flag)='branded' then b.brand else 'Others' end ,
case when sales.is_alpha_seller = TRUE then 'Diamond' else 'Rest of MP' end , 

case when t5.owner = 'KAM' then 'KAM' else 'N-KAM' end ,
case 
    when sales.is_alpha_seller = TRUE and (lower(sales.source_facility_id)  like '%\\_alite\\_%' or lower(sales.source_facility_id) like '%\\_al\\_%') then 'Alite'
    when sales.service_profile = 'FBF' then 'FBF' 
    when sales.service_profile in ('NON_FBF','FBF_LITE') then 'NFBF'
    else 'null'
    end ,
CASE 
        WHEN sales.gmv / sales.units <= 500 THEN "0 - 500"
        WHEN sales.gmv / sales.units > 500 AND sales.gmv / sales.units <= 1000 then "501 - 1k"
         WHEN sales.gmv / sales.units > 1000 AND sales.gmv / sales.units <= 2500 then "1k - 2.5k"
       WHEN sales.gmv / sales.units > 2500 AND sales.gmv / sales.units <= 5000 then "2.5k - 5k"
       WHEN sales.gmv / sales.units > 5000 AND sales.gmv / sales.units <= 7500 then "5k - 7.5k"
       WHEN sales.gmv / sales.units > 7500 AND sales.gmv / sales.units <= 10000 then "7.5k - 10k"
       WHEN sales.gmv / sales.units > 10000 AND sales.gmv / sales.units <= 15000 then "10k - 15k"
   WHEN sales.gmv / sales.units > 15000 THEN "15k+"
 End ,
b.branded_flag ,
b.brand_tier ,
sales.analytic_category

)

union all 

(

    select 
"new_selection" as domain_flag,
CAST(FORMAT_datetime('%Y%m%d',lhd.listing_created_on) as INT64) as order_date_key, 
lhd.marketplace_id as marketplace, 
lhd.analytic_business_unit as analytic_business_unit, 
lhd.analytic_super_category as analytic_super_category, 
lhd.analytic_vertical as analytic_vertical,
case when t5.owner ='KAM'  then lhd.seller_id else 'Others' end as seller_id,
case when lower(b.branded_flag)='branded' then b.brand else 'Others' end as brand,
'' as city_tier, 
'' as zone, 
case when lhd.is_first_party_seller = TRUE then 'Diamond' else 'Rest of MP' end as is_alpha_seller, 
"" as az_seller_type,
'' as torso_tail_flag,
case when t5.owner = 'KAM' then 'KAM' else 'N-KAM' end as kam_nkam_flag,
case 
    when lhd.service_profile = 'FBF' then 'FBF' 
    when lhd.service_profile in ('NON_FBF','FBF_LITE','FBF_AND_FBF_LITE','FBF_AND_NON_FBF') then 'NFBF'
    else 'null'
    end as service_profile,
CASE 
        WHEN lhd.flipkart_selling_price <= 500 THEN "0 - 500"
        WHEN lhd.flipkart_selling_price > 500 AND lhd.flipkart_selling_price <= 1000 then "501 - 1k"
         WHEN lhd.flipkart_selling_price > 1000 AND lhd.flipkart_selling_price <= 2500 then "1k - 2.5k"
       WHEN lhd.flipkart_selling_price > 2500 AND lhd.flipkart_selling_price <= 5000 then "2.5k - 5k"
       WHEN lhd.flipkart_selling_price > 5000 AND lhd.flipkart_selling_price <= 7500 then "5k - 7.5k"
       WHEN lhd.flipkart_selling_price > 7500 AND lhd.flipkart_selling_price <= 10000 then "7.5k - 10k"
       WHEN lhd.flipkart_selling_price > 10000 AND lhd.flipkart_selling_price <= 15000 then "10k - 15k"
   WHEN lhd.flipkart_selling_price > 15000 THEN "15k+"
 End as price_bucket,
b.branded_flag as branded_flag,
b.brand_tier as brand_tier,
 0.0 as gmv,
    0 as units,
    0.0 as fsp,
    0.0 as mrp,
    0 as fbf_units,
    0.0 as sla,
    0.0 as o2d,
    0 as d0_units,
    0 as d1_units,
    0 as d2_units,
    0 as d4_units,
    0 as d6_units,
    0 as rto_units,
    0.0 as rto_gmv,
    0 as rvp_units,
    0.0 as rvp_gmv,
    0 as ru_den,
    0 as ru_num,
    0 as pq_rated_units,
    0.0 as pq_num,
    0 as pq_rated_good_pq_units,
    0 as pq_rating_4_units,
    0 as pq_rating_3_8_units,
    0 as pq_rating_3_85_units,
    0 as pq_rating_3_9_units,
    0 as pq_rated_hygiene_pq_units,
    0 as pq_unrated_units,
    0 as pq_lt_5_rated_units,
0  as fk_price_npi,
0  as comp_price_npi,
0  as fk_comp,
0  as az_comp,
0  as search_ppvs,
0.0 as ly_gmv,
0 as ly_units,
0.0 as  sds_pure_az,
0.0 as sds_oos_attribution_pure_az,
0.0 as msku_count,
0.0  as output_fes_weighted_asp,
0.0 as output_bau_weighted_asp,
0.0 as input_bau_weighted_asp,
0.0 as input_fes_weighted_asp,
0.0 as input_fes_weighted_fsp,
0.0 as input_bau_weighted_fsp,
0.0 as output_fes_weighted_fsp,
0.0 as outut_bau_weighted_fsp,
'' as d2c_flag,
lhd.analytic_category,
0 as transacting_selection_count,
count(distinct(lhd.listing_id)) as new_selection,
0 as m_dw,
0 as cdw,
0 as dw,
0 as fk_cd,
0 as az_cd,
0 as wfcp,
0 as wccp


FROM  bigfoot_external_neo.sp_product__listing_hive_dim as lhd

LEFT JOIN  fdp_uploads.ds_fkint_cp_santa_hyperlocal_vertical_bu_mapping_2_0 AS hl 
    ON lhd.analytic_vertical = hl.analytic_vertical 
    AND LOWER(hl.bu_final) = 'furniture'  
    and lhd.marketplace_id='HYPERLOCAL'

LEFT JOIN

(
SELECT 
 seller_id,
 MIN(managed_by) as owner
 FROM fdp_uploads.ds_fkint_analytics_cdo_seller_kam_ukam_mapping_1_0
 GROUP BY
 seller_id
) as t5
on lhd.seller_id = t5.seller_id

 
LEFT JOIN
  fdp_uploads.ds_fkint_analytics_cdo_furniture_brand_mapping_analytics_1_0 b
on lower(lhd.analytic_super_category) = lower(b.analytic_super_category)
and lower(lhd.brand) = lower(b.brand)
and lower(lhd.analytic_vertical) = lower(b.analytic_vertical)



WHERE 
         (lhd.marketplace_id IN ('FLIPKART') OR (lhd.marketplace_id = 'HYPERLOCAL' AND  hl.analytic_vertical IS NOT NULL))
    
        AND lower(lhd.analytic_business_unit) IN ('furniture')
        AND CAST(FORMAT_datetime('%Y%m%d',lhd.listing_created_on) as INT64) BETWEEN 20230101 AND  CAST(FORMAT_DATE('%Y%m%d', DATE_SUB(CURRENT_DATE(), INTERVAL 1 DAY)) AS INT64)
      

group by
CAST(FORMAT_datetime('%Y%m%d',lhd.listing_created_on) as INT64) ,
lhd.marketplace_id ,
lhd.analytic_business_unit,
lhd.analytic_super_category ,
lhd.analytic_vertical ,
case when t5.owner ='KAM'  then lhd.seller_id else 'Others' end ,
case when lower(b.branded_flag)='branded' then b.brand else 'Others' end ,

case when lhd.is_first_party_seller = TRUE then 'Diamond' else 'Rest of MP' end ,

case when t5.owner = 'KAM' then 'KAM' else 'N-KAM' end ,
case 
    when lhd.service_profile = 'FBF' then 'FBF' 
    when lhd.service_profile in ('NON_FBF','FBF_LITE','FBF_AND_FBF_LITE','FBF_AND_NON_FBF') then 'NFBF'
    else 'null'
    end ,
CASE 
        WHEN lhd.flipkart_selling_price <= 500 THEN "0 - 500"
        WHEN lhd.flipkart_selling_price > 500 AND lhd.flipkart_selling_price <= 1000 then "501 - 1k"
         WHEN lhd.flipkart_selling_price > 1000 AND lhd.flipkart_selling_price <= 2500 then "1k - 2.5k"
       WHEN lhd.flipkart_selling_price > 2500 AND lhd.flipkart_selling_price <= 5000 then "2.5k - 5k"
       WHEN lhd.flipkart_selling_price > 5000 AND lhd.flipkart_selling_price <= 7500 then "5k - 7.5k"
       WHEN lhd.flipkart_selling_price > 7500 AND lhd.flipkart_selling_price <= 10000 then "7.5k - 10k"
       WHEN lhd.flipkart_selling_price > 10000 AND lhd.flipkart_selling_price <= 15000 then "10k - 15k"
   WHEN lhd.flipkart_selling_price > 15000 THEN "15k+"
 End ,
b.branded_flag,
b.brand_tier ,
lhd.analytic_category

)

union all

(

select

'meesho pi' as domain_flag,
 cast(mpi_data.date_key as INT64) as order_date_key,
'' marketplace,
 mpi_data.analytic_business_unit as analytic_business_unit,
  mpi_data.analytic_super_category as analytic_super_category,
 mpi_data.analytic_vertical as analytic_vertical,
'' as seller_id,
'' as brand,
'' as city_tier,
'' as zone,
'' as is_alpha_seller,
'' as az_seller_type,
'' as torso_tail_flag,
'' as kam_nkam_flag,
'' as service_profile,
mpi_data.price_bucket,
'' as branded_flag,
'' as brand_tier,
 0.0 as gmv,
    0 as units,
    0.0 as fsp,
    0.0 as mrp,
    0 as fbf_units,
    0.0 as sla,
    0.0 as o2d,
    0 as d0_units,
    0 as d1_units,
    0 as d2_units,
    0 as d4_units,
    0 as d6_units,
    0 as rto_units,
    0.0 as rto_gmv,
    0 as rvp_units,
    0.0 as rvp_gmv,
    0 as ru_den,
    0 as ru_num,
    0 as pq_rated_units,
    0.0 as pq_num,
    0 as pq_rated_good_pq_units,
    0 as pq_rating_4_units,
    0 as pq_rating_3_8_units,
    0 as pq_rating_3_85_units,
    0 as pq_rating_3_9_units,
    0 as pq_rated_hygiene_pq_units,
    0 as pq_unrated_units,
    0 as pq_lt_5_rated_units,
0  as fk_price_npi,
0  as comp_price_npi,
0  as fk_comp,
0  as az_comp,
0  as search_ppvs,
0.0 as ly_gmv,
0 as ly_units,
0.0 as  sds_pure_az,
0.0 as sds_oos_attribution_pure_az,
0.0 as msku_count,
0.0  as output_fes_weighted_asp,
0.0 as output_bau_weighted_asp,
0.0 as input_bau_weighted_asp,
0.0 as input_fes_weighted_asp,
0.0 as input_fes_weighted_fsp,
0.0 as input_bau_weighted_fsp,
0.0 as output_fes_weighted_fsp,
0.0 as outut_bau_weighted_fsp,
'' as d2c_flag,
'' as analytic_category,
0 as transacting_selection_count,
0 as new_selection,
SUM(mpi_data.m_dw) as m_dw,
	SUM(mpi_data.cdw) as cdw,
	SUM(mpi_data.dw) as dw,
    0 as fk_cd,
0 as az_cd,
0 as wfcp,
0 as wccp




from 

  (SELECT
		comp.date_key as date_key,
        comp.analytic_business_unit as analytic_business_unit,
        comp.analytic_super_category as analytic_super_category,
        comp.analytic_vertical as analytic_vertical,
         case when comp.mpp = '0 - 300' then '0-300'
			 when comp.mpp = '300 - 500' then '301-500'
			 when comp.mpp = '500+' then '500+'
		end as price_bucket,
		sum(comp.m_dw) as m_dw,
		sum(comp.cdw) as cdw,
		sum(comp.dw) as dw
		
	FROM bigfoot_external_neo.cp_santa__meesho_pi_2__sc_level_fact AS comp
	
	---- App/Non-App & Megacat Map -----
	left join 
	(
	Select distinct supercat as SC, input as megacat, trend as apparel_noapp_flag
	from fdp_uploads.ds_fkint_analytics_cdo_trendstalk_data_1_0 b
	where data_set = '6a8d7eec-d1c6-47dd-848e-5244c6ea8fcf'
	) MC 
	on comp.analytic_super_category = MC.SC
   
    WHERE
        date_key >= 20240101
		AND lower(comp.analytic_business_unit) in ("furniture")

    GROUP BY
		comp.date_key,
        comp.analytic_business_unit,
        comp.analytic_super_category,
        comp.analytic_vertical,
         case when comp.mpp = '0 - 300' then '0-300'
			 when comp.mpp = '300 - 500' then '301-500'
			 when comp.mpp = '500+' then '500+'
		end
		
		 
	) mpi_data
	
GROUP BY

    cast(mpi_data.date_key as INT64),
    mpi_data.analytic_business_unit, 
    mpi_data.analytic_super_category, 
    mpi_data.analytic_vertical,
   mpi_data.price_bucket


)

) as furniture_lsp_query