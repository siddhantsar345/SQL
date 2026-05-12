select 
domain_flag,    
CAST(order_date_key as INT64) as order_date_key,
marketplace,    
analytic_business_unit,
analytic_super_category,    
analytic_vertical,  
seller_id,  
brand,  
city_tier,  
zone,
is_alpha_seller,
serviceability_status,    
az_seller_type, 
torso_tail_flag,    
manufacturer_flag,  
priority_vertical_flag,
kam_nkam_flag,  
service_profile,    
price_bucket,   
branded_flag,   
brand_tier,
brand_type,
is_priority_brand,  
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
manufacturer_priority_flag,
age_range,
transacting_selection_count,
new_selection,
csds_sds_units,
csds_units,
source_cluster_sale,
cast(fr_cluster_source_cluster_sale as numeric) as fr_cluster_source_cluster_sale,
cast(dr_cluster_source_cluster_sale as numeric) as dr_cluster_source_cluster_sale,
cast(destination_cluster_sale as numeric) as destination_cluster_sale,
cast(fr_cluster_destination_cluster_sale as numeric) as fr_cluster_destination_cluster_sale,
cast(dr_cluster_destination_cluster_sale as numeric) as dr_cluster_destination_cluster_sale,
cust_category_type, 
cust_category_name, 
orders, 
customers,
 cy_mtd_orders,
 cy_mtd_customers,
ly_mtd_orders,
 ly_mtd_customers,
fk_cd,
az_cd,
wfcp,
wccp,
op_sp_num, 
op_sp_den, 
ip_sp_num, 
ip_sp_den,
selection_score_v3, 
az_product_count,
fk_product_count,
product_type,
fk_historic_max_product_count,
input_weighted_aug_bau_asp,
input_weighted_cur_asp,
input_weighted_exp_asp,
output_weighted_aug_bau_asp,
output_weighted_cur_asp,
output_weighted_exp_asp,
bau_units,
cur_units,
gst_change_flag,
bau_gmv,
cur_gmv,
lids,
priced_lids,
priced_bau_gmv,
priced_cur_gmv,
 m_dw, 
cdw, 
dw


from

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
salesdata3.serviceability_status as serviceability_status,
"" as az_seller_type,
CAST(0 as boolean) as torso_tail_flag,
salesdata3.manufacturer_flag as manufacturer_flag,
salesdata3.priority_vertical_flag as priority_vertical_flag,
salesdata3.kam_nkam_flag as kam_nkam_flag,
salesdata3.service_profile as service_profile,
salesdata3.price_bucket as price_bucket,
salesdata3.branded_flag as branded_flag,
salesdata3.brand_tier as brand_tier,
salesdata3.brand_type as brand_type,
salesdata3.is_priority_brand as is_priority_brand, 
sum(salesdata3.gmv) as gmv, 
sum(salesdata3.units) as units, 
sum(salesdata3.fsp) as fsp,
sum(salesdata3.mrp) as mrp,
sum(salesdata3.fbf_units) as fbf_units, 
sum(salesdata3.sla) as sla,
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
sum(case when salesdata3.analytic_business_unit in ('BGM') and lower(salesdata3.bmp_brand) = "unbranded" and salesdata3.rating_3_8 = 1 then salesdata3.rated_units
            when salesdata3.analytic_business_unit in ('BGM') and lower(salesdata3.bmp_brand) = "branded" and salesdata3.rating_4 = 1 then salesdata3.rated_units end) as pq_rated_good_pq_units,
sum(case when salesdata3.rating_4 = 1 then salesdata3.rated_units end) as pq_rating_4_units,
sum(case when salesdata3.rating_3_8 = 1 then salesdata3.rated_units end) as pq_rating_3_8_units,
sum(case when salesdata3.rating_3_85 = 1 then salesdata3.rated_units end) as pq_rating_3_85_units,
sum(case when salesdata3.rating_3_9 = 1 then salesdata3.rated_units end) as pq_rating_3_9_units,
sum(case when salesdata3.analytic_super_category in ('AutoAccessorys') and salesdata3.rating_3_2 = 1 then salesdata3.rated_units
            when salesdata3.analytic_super_category in ('MakeupFragrances','SportFitness','Industrial&Scientific') and salesdata3.rating_3_4 = 1 then salesdata3.rated_units
            when salesdata3.analytic_super_category in ('BabyCare','FoodAndNutrition','Grooming','HealthCare','HouseHoldSupplies','ToysAndSS') and salesdata3.rating_3_6 = 1 then salesdata3.rated_units end) as pq_rated_hygiene_pq_units,                   
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
0.0 as output_fes_weighted_asp,
0.0 as output_bau_weighted_asp,
0.0 as input_bau_weighted_asp,
0.0 as input_fes_weighted_asp,
0.0 as input_fes_weighted_fsp,
0.0 as input_bau_weighted_fsp,
0.0 as output_fes_weighted_fsp,
0.0 as outut_bau_weighted_fsp,
salesdata3.d2c_flag as d2c_flag,
salesdata3.manufacturer_priority_flag as manufacturer_priority_flag,
salesdata3.age_range as age_range,
0 as transacting_selection_count,
0 as new_selection,
0 as csds_sds_units,
0 as csds_units,
0 as source_cluster_sale,
0 as fr_cluster_source_cluster_sale,
0 as dr_cluster_source_cluster_sale,
0 as destination_cluster_sale,
0 as fr_cluster_destination_cluster_sale,
0 as dr_cluster_destination_cluster_sale,
'' as cust_category_type, 
'' as cust_category_name, 
0 as orders, 
0 as customers,
0 as cy_mtd_orders,
0 as cy_mtd_customers,
0 as ly_mtd_orders,
0 as ly_mtd_customers,
0 as fk_cd,
0 as az_cd,
0 as wfcp,
0 as wccp,
0 as op_sp_num, 
0 as op_sp_den, 
0 as ip_sp_num, 
0 as ip_sp_den,

0.0 as selection_score_v3, 
0.0 as az_product_count,
0.0 as fk_product_count,
"" as product_type,
0.0 as fk_historic_max_product_count,

0.0 as input_weighted_aug_bau_asp,
0.0 as input_weighted_cur_asp,
0.0 as input_weighted_exp_asp,
0.0 as output_weighted_aug_bau_asp,
0.0 as output_weighted_cur_asp,
0.0 as output_weighted_exp_asp,
0.0 as bau_units,
0.0 as cur_units,
'' as gst_change_flag,
0.0 as bau_gmv,
0.0 as cur_gmv,
0.0 as lids,
0.0 as priced_lids,
0.0 as priced_bau_gmv,
0.0 as priced_cur_gmv,
0.0 as m_dw, 
0.0 as cdw, 
0.0 as dw

from 

(
select 

salesdata2.order_date_key as order_date_key,
salesdata2.marketplace as marketplace,
salesdata2.analytic_business_unit as analytic_business_unit, 
salesdata2.analytic_super_category as analytic_super_category, 
salesdata2.analytic_vertical as analytic_vertical, 
salesdata2.seller_id as seller_id,
salesdata2.brand as brand, 
salesdata2.city_tier as city_tier, 
salesdata2.zone as zone, 
salesdata2.is_alpha_seller as is_alpha_seller,
salesdata2.serviceability_status, 
0 as torso_tail_flag,
salesdata2.manufacturer_flag as manufacturer_flag,
salesdata2.priority_vertical_flag as priority_vertical_flag,
salesdata2.kam_nkam_flag as kam_nkam_flag,
salesdata2.service_profile as service_profile,
salesdata2.price_bucket as price_bucket,
salesdata2.branded_flag as branded_flag,
salesdata2.brand_tier as brand_tier,
salesdata2.brand_type as brand_type,
salesdata2.is_priority_brand as is_priority_brand, 
salesdata2.bmp_brand,
salesdata2.brand_name,
salesdata2.d2c_flag,
salesdata2.manufacturer_priority_flag,
salesdata2.age_range,
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
sum(salesdata2.sla) as sla,
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
salesdata1.analytic_vertical as analytic_vertical, 
salesdata1.seller_id as seller_id,
salesdata1.brand as brand, 
salesdata1.city_tier as city_tier, 
salesdata1.zone as zone, 
salesdata1.is_alpha_seller as is_alpha_seller,
salesdata1.serviceability_status, 
0 as torso_tail_flag,
salesdata1.manufacturer_flag as manufacturer_flag,
salesdata1.priority_vertical_flag as priority_vertical_flag,
salesdata1.kam_nkam_flag as kam_nkam_flag,
salesdata1.service_profile as service_profile,
salesdata1.price_bucket as price_bucket,
salesdata1.branded_flag as branded_flag,
salesdata1.brand_tier as brand_tier,
salesdata1.brand_type as brand_type,
salesdata1.is_priority_brand as is_priority_brand, 
salesdata1.bmp_brand,
salesdata1.brand_name,
salesdata1.d2c_flag,
salesdata1.manufacturer_priority_flag,
salesdata1.age_range,

sum(salesdata1.gmv) as gmv, 
sum(salesdata1.units) as units, 
sum(salesdata1.fsp) as fsp,
sum(salesdata1.mrp) as mrp,
sum(salesdata1.fbf_units) as fbf_units, 
sum(salesdata1.sla) as sla,
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
cat.analytic_business_unit as analytic_business_unit, 
cat.analytic_super_category as analytic_super_category, 
cat.analytic_vertical as analytic_vertical,
case when t5.owner ='KAM' or seller.seller_id IS NOT NULL OR seller1.seller_id IS NOT NULL OR seller2.seller_id IS NOT NULL then sales.seller_id else 'Others' end as seller_id,
case when lower(b.branded_flag)='branded' then b.brand else 'Others' end as brand,
geo.city_tier as city_tier, 
geo.zone as zone,  

case when sales.is_alpha_seller = TRUE then 'Diamond' else 'Rest of MP' end as is_alpha_seller, 

CASE 
    WHEN hyper.pincode IS NOT NULL THEN 'Serviceable'
    ELSE 'Non-Serviceable'
END AS serviceability_status,

0 as torso_tail_flag,
case when seller.seller_id IS NOT NULL OR seller1.seller_id IS NOT NULL OR seller2.seller_id IS NOT NULL then 'Manufacturers' else 'Non Manufacturers' end as manufacturer_flag,
case when pv.vertical is not null then 'Priority Vertical' else 'Not Priority Vertical' end as priority_vertical_flag,
case when t5.owner = 'KAM' then 'KAM' else 'N-KAM' end as kam_nkam_flag,
 case 
 when is_alpha_seller = TRUE and ((lower(sales.source_facility_id)  like '%\\_alite\\_%') or (lower(sales.source_facility_id) like '%\\_al\\_%')) then 'Alite'
    when sales.service_profile = 'FBF' then 'FBF' 
    when sales.service_profile in ('NON_FBF','FBF_LITE') then 'NFBF'
    else 'null' end as service_profile,
CASE 
        WHEN sales.gmv / sales.units <= 300 THEN "0-300"
         WHEN sales.gmv / sales.units > 300 AND sales.gmv / sales.units <= 500 then "301-500"
       WHEN sales.gmv / sales.units > 500 AND sales.gmv / sales.units <= 1000 then "501-1000"
   WHEN sales.gmv / sales.units > 1000 THEN "1000+"
 End as price_bucket,
b.branded_flag as branded_flag,
b.brand_tier as brand_tier,
b.brand_type as brand_type,
b.is_priority_brand as is_priority_brand, 
case when bmp.brand is not null then "Branded" else "Unbranded" end bmp_brand,
case when bmp.brand is not null then sales.brand else "Unbranded" end brand_name,
CASE WHEN LOWER(b.branded_flag) = 'branded' and LOWER(b.brand_type) = 'd2c' then 'D2C' else 'Non D2C' end as d2c_flag,

case when lower(seller.is_priority) ="yes" OR lower(seller1.is_priority) ="yes" OR lower(seller2.is_priority) = "yes" then 'Yes' else 'No' end as manufacturer_priority_flag,
pd.age_range as age_range,


sum(sales.gmv) as gmv,
sum(sales.units) as units, 
sum(sales.listing_price) as fsp, 
sum(sales.mrp) as mrp,
sum(case when sales.service_profile = 'FBF' and lower(sales.source_facility_id) not like '%\\_alite\\_%' and lower(sales.source_facility_id) not like '%\\_al\\_%' then sales.units end)  AS fbf_units,
sum(sales.sla_in_days) AS sla,
AVG(DATE_DIFF(sales.delivered_date_time, sales.order_date_time,day)) AS o2d,
SUM(CASE WHEN sales.sla_in_days <= 0 THEN 1 ELSE 0 END) AS d0_units,
SUM(CASE WHEN sales.sla_in_days <= 1 THEN 1 ELSE 0 END) AS d1_units,
SUM(CASE WHEN sales.sla_in_days <= 2 THEN 1 ELSE 0 END) AS d2_units,
SUM(CASE WHEN sales.sla_in_days <= 4 THEN 1 ELSE 0 END) AS d4_units,
SUM(CASE WHEN sales.sla_in_days <= 6 THEN 1 ELSE 0 END) AS d6_units,
SUM(CASE WHEN sales.unit_is_rtod = true THEN sales.units END) AS rto_Units,
SUM(CASE WHEN sales.unit_is_rtod = true THEN sales.gmv END) AS rto_GMV,
SUM(ret.return_item_quantity) AS rvp_Units,
SUM(ret.return_amount) AS rvp_GMV,
sum(rudata.ru_den) as ru_den, 
sum(rudata.ru_num) as ru_num,
coalesce(gid.group_id,sales.product_id) as group_id

FROM  bigfoot_external_neo.cp_bi_prod_sales__forward_unit_history_fact sales

LEFT JOIN fdp_uploads.ds_fkint_analytics_cdo_pincodes_bgm_minutes_2_0 AS hyper
    ON CAST(sales.pincode AS STRING) = CAST(hyper.pincode AS STRING)


LEFT JOIN bigfoot_external_neo.sp_product__product_categorization_hive_dim cat
       ON  sales.product_id = cat.product_id


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

left join  fdp_uploads.ds_fkint_analytics_cdo_fsn_level_age_group_1_0 as pd
on
pd.product_id = cat.product_id

LEFT JOIN  fdp_uploads.ds_fkint_cp_santa_hyperlocal_vertical_bu_mapping_2_0 AS hl 
    ON cat.analytic_vertical = hl.analytic_vertical 
    AND LOWER(hl.bu_final) = 'bgm'  
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
        MIN(managed_by) AS owner
    FROM fdp_uploads.ds_fkint_analytics_cdo_seller_kam_ukam_mapping_1_0
    GROUP BY seller_id
    ) AS t5 
on sales.seller_id = t5.seller_id

left join 

fdp_uploads.ds_fkint_analytics_cdo_bgm_priority_vertical_list_1_0 as pv
on 
cat.analytic_vertical=pv.vertical 

LEFT JOIN (
    SELECT seller_id,
           analytic_super_category, analytic_vertical, brand, is_priority
    FROM fdp_uploads.ds_fkint_analytics_cdo_bgm_manufacturer_seller_list_analytics_1_0
    WHERE LOWER(analytic_super_category) = 'sportfitness'
) AS seller
    ON CAST(seller.seller_id AS STRING) = CAST(sales.seller_id AS STRING)
    AND seller.analytic_super_category = cat.analytic_super_category
    AND seller.analytic_vertical = cat.analytic_vertical
    AND seller.brand = cat.brand

LEFT JOIN (
    SELECT seller_id,
           analytic_super_category, analytic_vertical, brand, is_priority
    FROM fdp_uploads.ds_fkint_analytics_cdo_bgm_manufacturer_seller_list_analytics_1_0
    WHERE LOWER(analytic_super_category) = 'toysandss'
) AS seller1
    ON seller1.seller_id = sales.seller_id
    AND seller1.analytic_super_category = cat.analytic_super_category
  
    left join 
  
    (SELECT seller_id,
           analytic_super_category, analytic_vertical, brand, is_priority
    FROM fdp_uploads.ds_fkint_analytics_cdo_bgm_manufacturer_seller_list_analytics_1_0
    WHERE LOWER(analytic_super_category) = 'babycare') as seller2 
    on seller2.seller_id=sales.seller_id 
    and seller2.analytic_super_category = cat.analytic_super_category
    and seller2.brand = cat.brand
 

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
    ON LOWER(cat.analytic_super_category) = LOWER(b.analytic_super_category)
    AND LOWER(cat.brand) = LOWER(b.brand)


LEFT JOIN 
    (
    SELECT 
        forward_unit_id,
        SUM(return_item_quantity) as return_item_quantity,
        SUM(return_amount) as return_amount
    FROM bigfoot_external_neo.scp_rrr__return_l2_id_level_hive_ss_fact
    WHERE UPPER(return_type) = 'CUSTOMER_RETURN' 
            AND (order_item_approve_date_key BETWEEN 20250101 and CAST(FORMAT_DATE('%Y%m%d', DATE_SUB(CURRENT_DATE(), INTERVAL 1 DAY)) AS INT64))
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
        
      (ff.fulfill_item_unit_order_date_key BETWEEN 20250101 and CAST(FORMAT_DATE('%Y%m%d', DATE_SUB(CURRENT_DATE(), INTERVAL 1 DAY)) AS INT64))
        AND cat.analytic_business_unit IN ('BGM')
     
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

        AND cat.analytic_business_unit IN ('BGM')
        AND (sales.order_date_key BETWEEN 20250101 and CAST(FORMAT_DATE('%Y%m%d', DATE_SUB(CURRENT_DATE(), INTERVAL 1 DAY)) AS INT64))
        AND sales.is_shopsy_order = FALSE

group by
sales.product_id,
sales.order_date_key , 
sales.marketplace_id , 
cat.analytic_business_unit , 
cat.analytic_super_category , 
cat.analytic_vertical,
case when t5.owner ='KAM' or seller.seller_id IS NOT NULL OR seller1.seller_id IS NOT NULL OR seller2.seller_id IS NOT NULL then sales.seller_id else 'Others' end,
case when lower(b.branded_flag)='branded' then b.brand else 'Others' end,
geo.city_tier , 
geo.zone , 
case when sales.is_alpha_seller = TRUE then 'Diamond' else 'Rest of MP' end,
case when hyper.pincode IS NOT NULL then 'Serviceable' else 'Non-Serviceable'end,
CAST(0 as boolean),
case when seller.seller_id IS NOT NULL OR seller1.seller_id IS NOT NULL OR seller2.seller_id IS NOT NULL then 'Manufacturers' else 'Non Manufacturers' end,
case when pv.vertical is not null then 'Priority Vertical' else 'Not Priority Vertical' end,
case when t5.owner = 'KAM' then 'KAM' else 'N-KAM' end,
case 
 when is_alpha_seller = TRUE and ((lower(sales.source_facility_id)  like '%\\_alite\\_%') or (lower(sales.source_facility_id) like '%\\_al\\_%')) then 'Alite'
    when sales.service_profile = 'FBF' then 'FBF' 
    when sales.service_profile in ('NON_FBF','FBF_LITE') then 'NFBF'
    else 'null' end,
CASE 
        WHEN sales.gmv / sales.units <= 300 THEN "0-300"
         WHEN sales.gmv / sales.units > 300 AND sales.gmv / sales.units <= 500 then "301-500"
       WHEN sales.gmv / sales.units > 500 AND sales.gmv / sales.units <= 1000 then "501-1000"
   WHEN sales.gmv / sales.units > 1000 THEN "1000+"
 End ,

b.branded_flag ,
b.brand_tier ,
b.brand_type,
b.is_priority_brand,
case when bmp.brand is not null then "Branded" else "Unbranded" end,
case when bmp.brand is not null then sales.brand else "Unbranded" end, 
CASE WHEN LOWER(b.branded_flag) = 'branded' and LOWER(b.brand_type) = 'd2c' then 'D2C' else 'Non D2C' end ,

case when lower(seller.is_priority) ="yes" OR lower(seller1.is_priority) ="yes" OR lower(seller2.is_priority) = "yes" then 'Yes' else 'No' end,
pd.age_range,
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
                    on CAST(FORMAT_DATETIME('%Y%m%d',rat.data.createStamp) as int64) = date_dim.date_dim_key


                where lower(data.domainType) in ('product')
                and lower(data.domain) = 'flipkart'
                and lower(data.status) = 'active'
                and data.certifiedBuyer = true
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
salesdata1.analytic_vertical ,
salesdata1.seller_id ,
salesdata1.brand ,
salesdata1.city_tier ,
salesdata1.zone ,
salesdata1.is_alpha_seller,
salesdata1.serviceability_status,
CAST(0 as boolean),
salesdata1.manufacturer_flag,
salesdata1.priority_vertical_flag,
salesdata1.kam_nkam_flag,
salesdata1.service_profile,
salesdata1.price_bucket,
salesdata1.branded_flag,
salesdata1.brand_tier ,
salesdata1.brand_type ,
salesdata1.is_priority_brand,
salesdata1.bmp_brand,
salesdata1.brand_name,
salesdata1.d2c_flag,
salesdata1.manufacturer_priority_flag,
salesdata1.age_range) as salesdata2


group by 

salesdata2.order_date_key ,
salesdata2.marketplace ,
salesdata2.analytic_business_unit ,
salesdata2.analytic_super_category ,
salesdata2.analytic_vertical ,
salesdata2.seller_id ,
salesdata2.brand ,
salesdata2.city_tier ,
salesdata2.zone ,
salesdata2.is_alpha_seller ,
salesdata2.serviceability_status,
CAST(0 as boolean),
salesdata2.manufacturer_flag,
salesdata2.priority_vertical_flag,
salesdata2.kam_nkam_flag,
salesdata2.service_profile ,
salesdata2.price_bucket,
salesdata2.branded_flag ,
salesdata2.brand_tier ,
salesdata2.brand_type ,
salesdata2.is_priority_brand,
salesdata2.bmp_brand,
salesdata2.brand_name,
salesdata2.d2c_flag,
salesdata2.manufacturer_priority_flag,
salesdata2.age_range,
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
salesdata3.serviceability_status,
CAST(0 as boolean),
salesdata3.manufacturer_flag,
salesdata3.priority_vertical_flag,
salesdata3.kam_nkam_flag,
salesdata3.service_profile ,
salesdata3.price_bucket,
salesdata3.branded_flag ,
salesdata3.brand_tier ,
salesdata3.brand_type,
salesdata3.is_priority_brand ,
salesdata3.brand_name,
salesdata3.d2c_flag,
salesdata3.manufacturer_priority_flag,
salesdata3.age_range




union all



SELECT

   "pricing" as domain_flag,
    CAST(pi_data.order_date_key as INT64)    as  order_date_key,
     ""   as marketplace,
    pi_data.analytic_business_unit as analytic_business_unit, 
    pi_data.analytic_super_category as analytic_super_category, 
    pi_data.analytic_vertical as analytic_vertical,
    pi_data.fk_seller_id as seller_id, 

    pi_data.brand as brand, 
      ""  as city_tier,
      ""  as zone,
    pi_data.fk_seller_type as is_alpha_seller,
    "" as serviceability_status,
    pi_data.az_seller_type as az_seller_type,
    CAST(0 as boolean) as torso_tail_flag, 
    pi_data.manufacturer_flag as manufacturer_flag,
    pi_data.priority_vertical_flag as priority_vertical_flag,
    pi_data.kam_nkam_flag as kam_nkam_flag,
    "" as service_profile,
    pi_data.price_bucket as price_bucket,
    pi_data.branded_flag as branded_flag,
    pi_data.brand_tier as brand_tier,
    pi_data.brand_type as brand_type, 
    pi_data.is_priority_brand as is_priority_brand,
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
    SUM(pi_data.fk_price * pi_data.search_ppvs) AS fk_price_npi,
    SUM(pi_data.comp_price * pi_data.search_ppvs) AS comp_price_npi,
    SUM(CASE WHEN fsn_landscape = 'FK_Comp' then search_ppvs end) as fk_comp,
    SUM(CASE WHEN fsn_landscape = 'AI_Comp' then search_ppvs end) as az_comp,
    SUM(search_ppvs) as search_ppvs,
    0.0 as ly_gmv,
    0 as ly_units,
    0.0 as  sds_pure_az,
0.0 as sds_oos_attribution_pure_az,
0.0 as msku_count,
0.0 as output_fes_weighted_asp,
0.0 as output_bau_weighted_asp,
0.0 as input_bau_weighted_asp,
0.0 as input_fes_weighted_asp,
0.0 as input_fes_weighted_fsp,
0.0 as input_bau_weighted_fsp,
0.0 as output_fes_weighted_fsp,
0.0 as outut_bau_weighted_fsp,
 pi_data.d2c_flag,
pi_data.manufacturer_priority_flag,
pi_data.age_range as age_range,
0 as transacting_selection_count,
0 as new_selection,
0 as csds_sds_units,
0 as csds_units,
0 as source_cluster_sale,
0 as fr_cluster_source_cluster_sale,
0 as dr_cluster_source_cluster_sale,
0 as destination_cluster_sale,
0 as fr_cluster_destination_cluster_sale,
0 as dr_cluster_destination_cluster_sale,
'' as cust_category_type, 
'' as cust_category_name, 
0 as orders, 
0 as customers,
0 as cy_mtd_orders,
0 as cy_mtd_customers,
0 as ly_mtd_orders,
0 as ly_mtd_customers,
sum(case when pi_data.fsn_coupon_landscape= "FK_Comp" then pi_data.search_ppvs else 0 end ) as fk_cd,
sum(case when pi_data.fsn_coupon_landscape= "AI_Comp" then pi_data.search_ppvs else 0 end ) as az_cd,
sum(pi_data.fk_price_post_coupon * pi_data.search_ppvs) as wfcp,
sum(pi_data.comp_price_post_coupon * pi_data.search_ppvs) as wccp,
0 as op_sp_num, 
0 as op_sp_den, 
0 as ip_sp_num, 
0 as ip_sp_den,
0.0 as selection_score_v3, 
0.0 as az_product_count,
0.0 as fk_product_count,
"" as product_type,
0.0 as fk_historic_max_product_count,

0.0 as input_weighted_aug_bau_asp,
0.0 as input_weighted_cur_asp,
0.0 as input_weighted_exp_asp,
0.0 as output_weighted_aug_bau_asp,
0.0 as output_weighted_cur_asp,
0.0 as output_weighted_exp_asp,
0.0 as bau_units,
0.0 as cur_units,
'' as gst_change_flag,
0.0 as bau_gmv,
0.0 as cur_gmv,
0.0 as lids,
0.0 as priced_lids,
0.0 as priced_bau_gmv,
0.0 as priced_cur_gmv,
0.0 as m_dw, 
0.0 as cdw, 
0.0 as dw



FROM
    ( SELECT
       comp.date_key as order_date_key,
        comp.analytic_business_unit as analytic_business_unit,
        comp.ci_business_unit as ci_business_unit,
        comp.analytic_super_category as analytic_super_category,
        comp.analytic_vertical as analytic_vertical,

        case when t5.owner ='KAM' or seller.seller_id IS NOT NULL OR seller1.seller_id IS NOT NULL OR seller2.seller_id IS NOT NULL then comp.fk_seller_id else 'Others' end as  fk_seller_id,


        case when lower(b.branded_flag)='branded' then comp.brand else 'Others' end as brand,
        case when lower(comp.fk_seller_type) = 'fk-alpha' then 'Diamond'
              when lower(comp.fk_seller_type) = 'fk-non_alpha' then 'Rest of MP' else 'Others' end as fk_seller_type, 
        case when lower(comp.az_seller_type)='az-alpha' then 'Diamond'
        when lower(comp.az_seller_type)='az-non_alpha' then 'Rest of MP' else 'Others' end as az_seller_type,

        CAST(0 as boolean) as torso_tail_flag,

        case when seller.seller_id IS NOT NULL OR seller1.seller_id IS NOT NULL OR seller2.seller_id IS NOT NULL then 'Manufacturers' else 'Non Manufacturers' end as manufacturer_flag,

        case when pv.vertical is not null then 'Priority Vertical' else 'Not Priority Vertical' end as priority_vertical_flag,
        
        case when t5.owner = 'KAM' then 'KAM' else 'N-KAM' end as kam_nkam_flag,
        CASE WHEN LOWER(b.branded_flag) = 'branded' and LOWER(b.brand_type) = 'd2c' then 'D2C' else 'Non D2C' end as d2c_flag,

case when lower(seller.is_priority) ="yes" OR lower(seller1.is_priority) ="yes" OR lower(seller2.is_priority) = "yes" then 'Yes' else 'No' end as manufacturer_priority_flag,
pd.age_range as age_range,


case when fk_price between 0 and 300 then '0-300'
when fk_price between 301 and 500 then '301-500'
when fk_price between 501 and 1000 then '501-1000'
when fk_price>1000 then '1000+' else "" end as price_bucket,
        b.branded_flag as branded_flag,
        b.brand_tier as brand_tier,
        b2.brand_type as brand_type,
        b.is_priority_brand as is_priority_brand, 
        fsn_landscape,
        search_ppvs AS search_ppvs,
        fk_price  AS fk_price,
        comp_price AS comp_price,
    
        fk_price_post_coupon as fk_price_post_coupon ,
      
        comp_price-coalesce(comp_coupon_discount,0) as comp_price_post_coupon,
        CASE
            WHEN fk_price_post_coupon < 1000 AND (comp_price-coalesce(comp_coupon_discount,0))/NULLIF(fk_price_post_coupon,0) > 1.02 THEN "FK_Comp"
            WHEN fk_price_post_coupon < 1000 AND (comp_price-coalesce(comp_coupon_discount,0))/NULLIF(fk_price_post_coupon,0) < 0.98 THEN "AI_Comp"
            WHEN fk_price_post_coupon >= 1000 AND (comp_price-coalesce(comp_coupon_discount,0))/NULLIF(fk_price_post_coupon,0) > 1.01 THEN "FK_Comp"
            WHEN fk_price_post_coupon >= 1000 AND (comp_price-coalesce(comp_coupon_discount,0))/NULLIF(fk_price_post_coupon,0) < 0.99 THEN "AI_Comp"
            ELSE "Parity"
        END as fsn_coupon_landscape

    FROM bigfoot_external_neo.analytics_cdo__unweighted_comp_base_hist_fact AS comp
    left join 
    fdp_uploads.ds_fkint_analytics_cdo_fsn_level_age_group_1_0 as pd 
    on
    pd.product_id=comp.fsn 

LEFT JOIN 
    (
    SELECT
        seller_id,
        MIN(managed_by) AS owner
    FROM fdp_uploads.ds_fkint_analytics_cdo_seller_kam_ukam_mapping_1_0
    GROUP BY seller_id
    ) AS t5 
on comp.fk_seller_id = t5.seller_id

   left join 
fdp_uploads.ds_fkint_analytics_cdo_bgm_priority_vertical_list_1_0 as pv
on 
comp.analytic_vertical=pv.vertical 

    LEFT JOIN (
    SELECT seller_id,
           analytic_super_category, analytic_vertical, brand, is_priority
    FROM fdp_uploads.ds_fkint_analytics_cdo_bgm_manufacturer_seller_list_analytics_1_0
    WHERE LOWER(analytic_super_category) = 'sportfitness'
) AS seller
    ON CAST(seller.seller_id AS STRING) = CAST(comp.fk_seller_id AS STRING)
    AND seller.analytic_super_category = comp.analytic_super_category
    AND seller.analytic_vertical = comp.analytic_vertical
    AND seller.brand = comp.brand

LEFT JOIN (
    SELECT seller_id,
           analytic_super_category, analytic_vertical, brand, is_priority
    FROM fdp_uploads.ds_fkint_analytics_cdo_bgm_manufacturer_seller_list_analytics_1_0
    WHERE LOWER(analytic_super_category) = 'toysandss'
) AS seller1
    ON seller1.seller_id = comp.fk_seller_id
    AND seller1.analytic_super_category = comp.analytic_super_category

left join 
    (SELECT seller_id,
           analytic_super_category, analytic_vertical, brand, is_priority
    FROM fdp_uploads.ds_fkint_analytics_cdo_bgm_manufacturer_seller_list_analytics_1_0
    WHERE LOWER(analytic_super_category) = 'babycare') as seller2 
    on seller2.seller_id=comp.fk_seller_id 
    and seller2.analytic_super_category = comp.analytic_super_category
    and seller2.brand = comp.brand


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
    ON LOWER(comp.analytic_super_category) = LOWER(b.analytic_super_category)
    AND LOWER(comp.brand) = LOWER(b.brand)

LEFT JOIN 
    (
    SELECT 
        LOWER(brand) AS brand,
        MIN(brand_type) AS brand_type
    FROM  
        fdp_uploads.ds_fkint_analytics_cdo_bgm_sc_brand_mapping_analytics_1_0
    GROUP BY 
        LOWER(brand)
    ) b2
    ON LOWER(comp.brand) = LOWER(b2.brand)   

    WHERE
        (CAST(date_key as INT64) between 20250101 and CAST(FORMAT_DATE('%Y%m%d', DATE_SUB(CURRENT_DATE(), INTERVAL 1 DAY)) AS INT64))
        AND competitor IN ('AI')
                And ci_business_unit in ("BGM(Non-Books)")
                And analytic_business_unit in ("BGM")
                and ci_business_unit not in ("BGM(Books)" )

    

    ) as pi_data

GROUP BY
 CAST(pi_data.order_date_key as INT64)  ,
    pi_data.analytic_business_unit ,
    pi_data.analytic_super_category ,
    pi_data.analytic_vertical ,
    pi_data.fk_seller_id ,
    pi_data.brand ,
    pi_data.fk_seller_type, 
    pi_data.az_seller_type,
   CAST(0 as boolean), 
    pi_data.manufacturer_flag,
    pi_data.priority_vertical_flag,
    pi_data.kam_nkam_flag ,
    pi_data.price_bucket,
    pi_data.branded_flag,
    pi_data.brand_tier,
    pi_data.brand_type, 
    pi_data.is_priority_brand,
    pi_data.d2c_flag,
    pi_data.manufacturer_priority_flag,
    pi_data.age_range
    
    union all 

   select 
"last year" as domain_flag,
(sales.order_date_key) + 10000 as order_date_key, 
sales.marketplace_id as marketplace, 
cat.analytic_business_unit as analytic_business_unit, 
cat.analytic_super_category as analytic_super_category, 
cat.analytic_vertical as analytic_vertical,
case when t5.owner ='KAM' or seller.seller_id IS NOT NULL OR seller1.seller_id IS NOT NULL OR seller2.seller_id IS NOT NULL then sales.seller_id else 'Others' end as seller_id,
case when lower(b.branded_flag)='branded' then b.brand else 'Others' end as brand,
geo.city_tier as city_tier, 
geo.zone as zone, 

case when sales.is_alpha_seller = TRUE then 'Diamond' else 'Rest of MP' end as is_alpha_seller,
"" as serviceability_status,
"" as az_seller_type,
CAST(0 as boolean) as torso_tail_flag,
case when seller.seller_id IS NOT NULL OR seller1.seller_id IS NOT NULL OR seller2.seller_id IS NOT NULL then 'Manufacturers' else 'Non Manufacturers' end as manufacturer_flag,
case when pv.vertical is not null then 'Priority Vertical' else 'Not Priority Vertical' end as priority_vertical_flag,
case when t5.owner = 'KAM' then 'KAM' else 'N-KAM' end as kam_nkam_flag,
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
b.branded_flag as branded_flag,
b.brand_tier as brand_tier,
b.brand_type as brand_type,
b.is_priority_brand as is_priority_brand, 
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
0.0 as output_fes_weighted_asp,
0.0 as output_bau_weighted_asp,
0.0 as input_bau_weighted_asp,
0.0 as input_fes_weighted_asp,
0.0 as input_fes_weighted_fsp,
0.0 as input_bau_weighted_fsp,
0.0 as output_fes_weighted_fsp,
0.0 as outut_bau_weighted_fsp,
CASE WHEN LOWER(b.branded_flag) = 'branded' and LOWER(b.brand_type) = 'd2c' then 'D2C' else 'Non D2C' end as d2c_flag,

case when lower(seller.is_priority) ="yes" OR lower(seller1.is_priority) ="yes" OR lower(seller2.is_priority) = "yes" then 'Yes' else 'No' end as manufacturer_priority_flag,

pd.age_range as age_range,
0 as transacting_selection_count,
0 as new_selection,
0 as csds_sds_units,
0 as csds_units,
0 as source_cluster_sale,
0 as fr_cluster_source_cluster_sale,
0 as dr_cluster_source_cluster_sale,
0 as destination_cluster_sale,
0 as fr_cluster_destination_cluster_sale,
0 as dr_cluster_destination_cluster_sale,
'' as cust_category_type, 
'' as cust_category_name, 
0 as orders, 
0 as customers,
0 as cy_mtd_orders,
0 as cy_mtd_customers,
0 as ly_mtd_orders,
0 as ly_mtd_customers,
0 as fk_cd,
0 as az_cd,
0 as wfcp,
0 as wccp,
0 as op_sp_num, 
0 as op_sp_den, 
0 as ip_sp_num, 
0 as ip_sp_den,
0.0 as selection_score_v3, 
0.0 as az_product_count,
0.0 as fk_product_count,
"" as product_type,
0.0 as fk_historic_max_product_count,
0.0 as input_weighted_aug_bau_asp,
0.0 as input_weighted_cur_asp,
0.0 as input_weighted_exp_asp,
0.0 as output_weighted_aug_bau_asp,
0.0 as output_weighted_cur_asp,
0.0 as output_weighted_exp_asp,
0.0 as bau_units,
0.0 as cur_units,
'' as gst_change_flag,
0.0 as bau_gmv,
0.0 as cur_gmv,
0.0 as lids,
0.0 as priced_lids,
0.0 as priced_bau_gmv,
0.0 as priced_cur_gmv,
0.0 as m_dw, 
0.0 as cdw, 
0.0 as dw



FROM  bigfoot_external_neo.cp_bi_prod_sales__forward_unit_history_fact sales

LEFT JOIN bigfoot_external_neo.sp_product__product_categorization_hive_dim cat
      ON  sales.product_id = cat.product_id

left join 
fdp_uploads.ds_fkint_analytics_cdo_fsn_level_age_group_1_0 as pd 
on
pd.product_id=cat.product_id

LEFT JOIN  fdp_uploads.ds_fkint_cp_santa_hyperlocal_vertical_bu_mapping_2_0 AS hl 
    ON cat.analytic_vertical = hl.analytic_vertical 
    AND LOWER(hl.bu_final) = 'bgm'  
    and sales.marketplace_id='HYPERLOCAL'

LEFT JOIN

    (
    SELECT
        seller_id,
        MIN(managed_by) AS owner
    FROM fdp_uploads.ds_fkint_analytics_cdo_seller_kam_ukam_mapping_1_0
    GROUP BY seller_id
    ) AS t5 
on sales.seller_id = t5.seller_id

left join 

fdp_uploads.ds_fkint_analytics_cdo_bgm_priority_vertical_list_1_0 as pv
on 
cat.analytic_vertical=pv.vertical 

LEFT JOIN (
    SELECT seller_id,
           analytic_super_category, analytic_vertical, brand, is_priority
    FROM fdp_uploads.ds_fkint_analytics_cdo_bgm_manufacturer_seller_list_analytics_1_0
    WHERE LOWER(analytic_super_category) = 'sportfitness'
) AS seller
    ON CAST(seller.seller_id AS STRING) = CAST(sales.seller_id AS STRING)
    AND seller.analytic_super_category = cat.analytic_super_category
    AND seller.analytic_vertical = cat.analytic_vertical
    AND seller.brand = cat.brand

LEFT JOIN (
    SELECT seller_id,
           analytic_super_category, analytic_vertical, brand, is_priority
    FROM fdp_uploads.ds_fkint_analytics_cdo_bgm_manufacturer_seller_list_analytics_1_0
    WHERE LOWER(analytic_super_category) = 'toysandss'
) AS seller1
    ON seller1.seller_id = sales.seller_id
    AND seller1.analytic_super_category = cat.analytic_super_category
  
    left join 
  
    (SELECT seller_id,
           analytic_super_category, analytic_vertical, brand, is_priority
    FROM fdp_uploads.ds_fkint_analytics_cdo_bgm_manufacturer_seller_list_analytics_1_0
    WHERE LOWER(analytic_super_category) = 'babycare') as seller2 
    on seller2.seller_id=sales.seller_id 
    and seller2.analytic_super_category = cat.analytic_super_category
    and seller2.brand = cat.brand
 

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
    ON LOWER(cat.analytic_super_category) = LOWER(b.analytic_super_category)
    AND LOWER(cat.brand) = LOWER(b.brand)


LEFT JOIN 
    (
    SELECT 
        forward_unit_id,
        SUM(return_item_quantity) as return_item_quantity,
        SUM(return_amount) as return_amount
    FROM bigfoot_external_neo.scp_rrr__return_l2_id_level_hive_ss_fact
    WHERE UPPER(return_type) = 'CUSTOMER_RETURN' 
            AND (order_item_approve_date_key BETWEEN 20240101 and CAST(FORMAT_DATE('%Y%m%d', DATE_SUB(DATE_SUB(CURRENT_DATE(), INTERVAL 1 YEAR), INTERVAL 1 DAY)) AS INT64))
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
    
        AND cat.analytic_business_unit IN ('BGM')
        AND (sales.order_date_key BETWEEN 20240101 and CAST(FORMAT_DATE('%Y%m%d', DATE_SUB(DATE_SUB(CURRENT_DATE(), INTERVAL 1 YEAR), INTERVAL 1 DAY)) AS INT64))
        AND sales.is_shopsy_order = FALSE

group by
(sales.order_date_key) + 10000, 
sales.marketplace_id , 
cat.analytic_business_unit , 
cat.analytic_super_category , 
cat.analytic_vertical ,
case when t5.owner ='KAM' or seller.seller_id IS NOT NULL OR seller1.seller_id IS NOT NULL OR seller2.seller_id IS NOT NULL then sales.seller_id else 'Others' end ,
case when lower(b.branded_flag)='branded' then b.brand else 'Others' end ,
geo.city_tier , 
geo.zone , 
case when sales.is_alpha_seller = TRUE then 'Diamond' else 'Rest of MP' end,
CAST(0 as boolean),
case when seller.seller_id IS NOT NULL OR seller1.seller_id IS NOT NULL OR seller2.seller_id IS NOT NULL then 'Manufacturers' else 'Non Manufacturers' end,
case when pv.vertical is not null then 'Priority Vertical' else 'Not Priority Vertical' end,
case when t5.owner = 'KAM' then 'KAM' else 'N-KAM' end,
case 
 when is_alpha_seller = TRUE and ((lower(sales.source_facility_id)  like '%\\_alite\\_%') or (lower(sales.source_facility_id) like '%\\_al\\_%')) then 'Alite'
    when sales.service_profile = 'FBF' then 'FBF' 
    when sales.service_profile in ('NON_FBF','FBF_LITE') then 'NFBF'
    else 'null' end ,
CASE 
        WHEN sales.gmv / sales.units <= 300 THEN "0-300"
         WHEN sales.gmv / sales.units > 300 AND sales.gmv / sales.units <= 500 then "301-500"
       WHEN sales.gmv / sales.units > 500 AND sales.gmv / sales.units <= 1000 then "501-1000"
   WHEN sales.gmv / sales.units > 1000 THEN "1000+"
 End ,

b.branded_flag ,
b.brand_tier ,
b.brand_type,
b.is_priority_brand,
CASE WHEN LOWER(b.branded_flag) = 'branded' and LOWER(b.brand_type) = 'd2c' then 'D2C' else 'Non D2C' end ,

case when lower(seller.is_priority) ="yes" OR lower(seller1.is_priority) ="yes" OR lower(seller2.is_priority) = "yes" then 'Yes' else 'No' end,
pd.age_range



  
  
  union all
  

    SELECT
'sds' as domain_flag,
    sds.computation_date  as order_date_key,
    '' as marketplace,
sds.bu as analytic_business_unit,
   sds.super_category as analytic_super_category,
case when pv.vertical is not null then pt.analytic_vertical else 'Others' end as analytic_vertical,
"" as seller_id,

CASE WHEN LOWER(b.branded_flag) = 'branded'then sds.final_brand else 'Others' end as brand,
"" as city_tier,
"" as zone, 
"" as is_alpha_seller,
"" as serviceability_status,
"" as az_seller_type,
CAST(0 as boolean) as torso_tail_flag,
"" as manufacturer_flag,
case when pv.vertical is not null then 'Priority Vertical' else 'Not Priority Vertical' end as priority_vertical_flag,
"" as kam_nkam_flag,
"" as service_profile,
"" as price_bucket,
b.branded_flag as branded_flag,
b.brand_tier as brand_tier,
b.brand_type as brand_type,
b.is_priority_brand as is_priority_brand,
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
0.0 as output_fes_weighted_asp,
0.0 as output_bau_weighted_asp,
0.0 as input_bau_weighted_asp,
0.0 as input_fes_weighted_asp,
0.0 as input_fes_weighted_fsp,
0.0 as input_bau_weighted_fsp,
0.0 as output_fes_weighted_fsp,
0.0 as outut_bau_weighted_fsp,
"" as d2c_flag,
"" as manufacturer_priority_flag,
"" as age_range,
0 as transacting_selection_count,
0 as new_selection,
0 as csds_sds_units,
0 as csds_units,
0 as source_cluster_sale,
0 as fr_cluster_source_cluster_sale,
0 as dr_cluster_source_cluster_sale,
0 as destination_cluster_sale,
0 as fr_cluster_destination_cluster_sale,
0 as dr_cluster_destination_cluster_sale,
'' as cust_category_type, 
'' as cust_category_name, 
0 as orders, 
0 as customers,
0 as cy_mtd_orders,
0 as cy_mtd_customers,
0 as ly_mtd_orders,
0 as ly_mtd_customers,
0 as fk_cd,
0 as az_cd,
0 as wfcp,
0 as wccp,
0 as op_sp_num, 
0 as op_sp_den, 
0 as ip_sp_num, 
0 as ip_sp_den,
sum(selection_score_v3) as selection_score_v3, 
sum(az_product_count) as az_product_count,
sum(fk_product_count) as fk_product_count,
sds.product_type as product_type,
sum(fk_historic_max_product_count) as fk_historic_max_product_count,
0.0 as input_weighted_aug_bau_asp,
0.0 as input_weighted_cur_asp,
0.0 as input_weighted_exp_asp,
0.0 as output_weighted_aug_bau_asp,
0.0 as output_weighted_cur_asp,
0.0 as output_weighted_exp_asp,
0.0 as bau_units,
0.0 as cur_units,
'' as gst_change_flag,
0.0 as bau_gmv,
0.0 as cur_gmv,
0.0 as lids,
0.0 as priced_lids,
0.0 as priced_bau_gmv,
0.0 as priced_cur_gmv,

0.0 as m_dw, 
0.0 as cdw, 
0.0 as dw





   
FROM fdp_uploads.ds_fkint_analytics_cdo_branded_sds_non_ls_marketscores_weekly_fact_1_1 sds

left JOIN fdp_uploads.ds_fkint_analytics_cdo_product_type_and_vertical_mapping_1_0 pt  
    on sds.product_type = pt.product_type

LEFT JOIN fdp_uploads.ds_fkint_analytics_cdo_bgm_priority_vertical_list_1_0 as pv
on pt.analytic_vertical=pv.vertical


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
    ON LOWER(sds.super_category) = LOWER(b.analytic_super_category)
    AND LOWER(sds.final_brand) = LOWER(b.brand)


WHERE is_branded = TRUE
and exclude_final = 0
and Sc_exclude = 0
and hygiene_msku = 1
and bu = 'BGM'
and (sds.computation_date between 20250101 and CAST(FORMAT_DATE('%Y%m%d', DATE_SUB(CURRENT_DATE(), INTERVAL 1 DAY)) AS INT64))

GROUP BY 
    sds.computation_date ,

sds.bu ,
   sds.super_category ,
case when pv.vertical is not null then pt.analytic_vertical else 'Others' end ,
CASE WHEN LOWER(b.branded_flag) = 'branded'then sds.final_brand else 'Others' end ,

case when pv.vertical is not null then 'Priority Vertical' else 'Not Priority Vertical' end ,

b.branded_flag ,
b.brand_tier ,
b.brand_type ,
b.is_priority_brand,
sds.product_type 
  
union all


SELECT 

"Price Drop" as domain_flag,
    calc.order_date_key as order_date_key,
    '' as marketplace, 
    calc.analytic_business_unit as analytic_business_unit,
    calc.analytic_super_category as analytic_super_category,
    calc.analytic_vertical as analytic_vertical,
    case when t5.owner ='KAM' or seller.seller_id IS NOT NULL OR seller1.seller_id IS NOT NULL OR seller2.seller_id IS NOT NULL then calc.seller_id else 'Others' end as seller_id,
    case when lower(b.branded_flag)='branded' then b.brand else 'Others' end as brand,
    '' as city_tier,
    '' as zone,
    calc.is_alpha_seller as is_alpha_seller,
    "" as serviceability_status,
    "" as az_seller_type,
    CAST(0 as boolean) as torso_tail_flag,
    CASE WHEN seller.seller_id IS NOT NULL OR seller1.seller_id IS NOT NULL OR seller2.seller_id IS NOT NULL then 'Manufacturer' else 'Non Manufacturer' end as manufacturer_flag,
    case when pv.vertical is not null then 'Priority Vertical' else 'Not Priority Vertical' end as priority_vertical_flag,
    case when t5.owner = 'KAM' then 'KAM' else 'N-KAM' end as kam_nkam_flag,
    calc.service_profile as service_profile,
    calc.price_bucket as price_bucket,
    b.branded_flag as branded_flag,
    b.brand_tier as brand_tier,
    b.brand_type as brand_type,
    b.is_priority_brand as is_priority_brand,
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

0.0 as output_fes_weighted_asp,
0.0 as output_bau_weighted_asp,
0.0 as input_bau_weighted_asp,
0.0 as input_fes_weighted_asp,

0.0 as input_fes_weighted_fsp,
0.0 as input_bau_weighted_fsp,
0.0 as output_fes_weighted_fsp,
0.0 as outut_bau_weighted_fsp,

CASE WHEN LOWER(b.branded_flag) = 'branded' and LOWER(b.brand_type) = 'd2c' then 'D2C' else 'Non D2C' end as d2c_flag,
case when lower(seller.is_priority) ="yes" OR lower(seller1.is_priority) ="yes" OR lower(seller2.is_priority) = "yes" then 'Yes' else 'No' end as manufacturer_priority_flag,
calc.age_range as age_range ,
0 as transacting_selection_count,
0 as new_selection,
0 as csds_sds_units,
0 as csds_units,
0 as source_cluster_sale,
0 as fr_cluster_source_cluster_sale,
0 as dr_cluster_source_cluster_sale,
0 as destination_cluster_sale,
0 as fr_cluster_destination_cluster_sale,
0 as dr_cluster_destination_cluster_sale,
'' as cust_category_type,
'' as cust_category_name,
0 as orders,
0 as customers,
0 as cy_mtd_orders,
0 as cy_mtd_customers,
0 as ly_mtd_orders,
0 as ly_mtd_customers,
0 as fk_cd,
0 as az_cd,
0 as wfcp,
0 as wccp,
0 as op_sp_num,
0 as op_sp_den,
0 as ip_sp_num,
0 as ip_sp_den,


0.0 as selection_score_v3,
0.0 as az_product_count,
0.0 as fk_product_count,
"" as product_type,
0.0 as fk_historic_max_product_count, 

SUM(input_weighted_bau_asp) as input_weighted_aug_bau_asp,
SUM(input_weighted_cur_asp) as input_weighted_cur_asp,
SUM(input_weighted_exp_asp) as input_weighted_exp_asp,
SUM(output_weighted_bau_asp) as output_weighted_aug_bau_asp,
SUM(output_weighted_cur_asp) as output_weighted_cur_asp,
SUM(output_weighted_exp_asp) as output_weighted_exp_asp ,

SUM(bau_units)/14 as bau_units,
SUM(cur_units) as cur_units,

CASE WHEN old_tax_rate is null then 'No GST Change' 
     WHEN old_tax_rate > new_tax_rate then 'GST Reduced' 
     WHEN old_tax_rate < new_tax_rate then 'GST Increased' else 'Others' end as gst_change_flag,

SUM(bau_gmv)/14 as bau_gmv,
SUM(cur_gmv)as cur_gmv,

COUNT(DISTINCT listing_id) as lids,
    
COUNT(DISTINCT CASE WHEN cur_asp <= expected_asp then listing_id end) as priced_lids,
SUM(CASE WHEN cur_asp <= expected_asp then bau_gmv end)/14 as priced_bau_gmv,
SUM(CASE WHEN cur_asp <= expected_asp then cur_gmv end) as priced_cur_gmv,

0.0 as m_dw, 
0.0 as cdw, 
0.0 as dw



FROM
    (
    SELECT 
         order_date_key,
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
        COALESCE(bau_asp - (bau_sp-(bau_sp/(1+old_tax_rate))*(1+new_tax_rate)),bau_asp)*cur_units as output_weighted_exp_asp,

    FROM
        (
        SELECT 
            fes.order_date_key as order_date_key,
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
            CASE WHEN bau.is_alpha_seller = 'Diamond' then CAST(dmd_gst.c8 as numeric) else CAST(mp_gst.new_tax_rate as numeric)/100 end as new_tax_rate,

        FROM
            (
                (
            SELECT

                cat.analytic_business_unit as analytic_business_unit,
                cat.analytic_super_category as analytic_super_category,
                cat.analytic_vertical as analytic_vertical,
               sales.seller_id as seller_id,

               sales.brand as brand,
               
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
               AND lower(sales.analytic_business_unit) IN ('bgm')
               AND (order_date_key between 20250818 and 20250831)

            GROUP BY
               cat.analytic_business_unit ,
                cat.analytic_super_category ,
                cat.analytic_vertical ,
               sales.seller_id,

               sales.brand ,
             
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
                order_date_key as order_date_key,
                SUM(units) as units,
                SUM(gmv) as gmv,
                SUM(gmv)/sum(units) as asp
                
            FROM bigfoot_external_neo.cp_bi_prod_sales__forward_unit_history_fact sales

            WHERE lower(sales.status) in ('in_progress','undelivered','completed','delivered','approved','shipped','ready_to_ship','returned', 'return_requested','activated')
                AND sales.type !='service'
                AND sales.replacement_for_unit IS NULL
                AND sales.exchange_for_unit IS NULL
                AND sales.is_freebie =FALSE
                AND sales.marketplace_id IN ('FLIPKART')
                AND sales.is_shopsy_order =FALSE
                AND lower(sales.analytic_business_unit) IN ('bgm')
                AND (order_date_key between 20251025 and CAST(FORMAT_DATE('%Y%m%d', DATE_SUB(CURRENT_DATE(), INTERVAL 1 DAY)) AS INT64))

            GROUP BY
                sales.listing_id,
                order_date_key
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
    calc.order_date_key ,
    calc.analytic_business_unit ,
    calc.analytic_super_category ,
    calc.analytic_vertical ,
    case when t5.owner ='KAM' or seller.seller_id IS NOT NULL OR seller1.seller_id IS NOT NULL OR seller2.seller_id IS NOT NULL then calc.seller_id else 'Others' end ,
    case when lower(b.branded_flag)='branded' then b.brand else 'Others' end ,
   
    calc.is_alpha_seller ,

    CASE WHEN seller.seller_id IS NOT NULL OR seller1.seller_id IS NOT NULL OR seller2.seller_id IS NOT NULL then 'Manufacturer' else 'Non Manufacturer' end ,
    case when pv.vertical is not null then 'Priority Vertical' else 'Not Priority Vertical' end ,
    case when t5.owner = 'KAM' then 'KAM' else 'N-KAM' end ,
    calc.service_profile ,
    calc.price_bucket ,
    b.branded_flag ,
    b.brand_tier,
    b.brand_type ,
    b.is_priority_brand ,

CASE WHEN LOWER(b.branded_flag) = 'branded' and LOWER(b.brand_type) = 'd2c' then 'D2C' else 'Non D2C' end ,
case when lower(seller.is_priority) ="yes" OR lower(seller1.is_priority) ="yes" OR lower(seller2.is_priority) = "yes" then 'Yes' else 'No' end ,
calc.age_range,
CASE WHEN old_tax_rate is null then 'No GST Change' 
     WHEN old_tax_rate > new_tax_rate then 'GST Reduced' 
     WHEN old_tax_rate < new_tax_rate then 'GST Increased' else 'Others' end 



union all 

select 

"transacting_selection" as domain_flag,
(sales.order_date_key) as order_date_key, 
sales.marketplace_id as marketplace, 
cat.analytic_business_unit as analytic_business_unit, 
cat.analytic_super_category as analytic_super_category, 
cat.analytic_vertical as analytic_vertical,
case when t5.owner ='KAM' or seller.seller_id IS NOT NULL OR seller1.seller_id IS NOT NULL OR seller2.seller_id IS NOT NULL then sales.seller_id else 'Others' end as seller_id,
case when lower(b.branded_flag)='branded' then b.brand else 'Others' end as brand,
'' as city_tier, 
'' as zone, 

case when sales.is_alpha_seller = TRUE then 'Diamond' else 'Rest of MP' end as is_alpha_seller,
"" as serviceability_status,
"" as az_seller_type,
CAST(0 as boolean) as torso_tail_flag,
case when seller.seller_id IS NOT NULL OR seller1.seller_id IS NOT NULL OR seller2.seller_id IS NOT NULL then 'Manufacturers' else 'Non Manufacturers' end as manufacturer_flag,
case when pv.vertical is not null then 'Priority Vertical' else 'Not Priority Vertical' end as priority_vertical_flag,
case when t5.owner = 'KAM' then 'KAM' else 'N-KAM' end as kam_nkam_flag,
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
b.branded_flag as branded_flag,
b.brand_tier as brand_tier,
b.brand_type as brand_type,
b.is_priority_brand as is_priority_brand, 
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

cast(0.0 as numeric)  as ly_gmv,
0 as ly_units,
0.0 as  sds_pure_az,
0.0 as sds_oos_attribution_pure_az,
0.0 as msku_count,
0.0 as output_fes_weighted_asp,
0.0 as output_bau_weighted_asp,
0.0 as input_bau_weighted_asp,
0.0 as input_fes_weighted_asp,
0.0 as input_fes_weighted_fsp,
0.0 as input_bau_weighted_fsp,
0.0 as output_fes_weighted_fsp,
0.0 as outut_bau_weighted_fsp,
CASE WHEN LOWER(b.branded_flag) = 'branded' and LOWER(b.brand_type) = 'd2c' then 'D2C' else 'Non D2C' end as d2c_flag,

case when lower(seller.is_priority) ="yes" OR lower(seller1.is_priority) ="yes" OR lower(seller2.is_priority) = "yes" then 'Yes' else 'No' end as manufacturer_priority_flag,

pd.age_range as age_range,
count(distinct(sales.listing_id)) as transacting_selection_count,
0 as new_selection,
0 as csds_sds_units,
0 as csds_units,
0 as source_cluster_sale,
0 as fr_cluster_source_cluster_sale,
0 as dr_cluster_source_cluster_sale,
0 as destination_cluster_sale,
0 as fr_cluster_destination_cluster_sale,
0 as dr_cluster_destination_cluster_sale,
'' as cust_category_type, 
'' as cust_category_name, 
0 as orders, 
0 as customers,
0 as cy_mtd_orders,
0 as cy_mtd_customers,
0 as ly_mtd_orders,
0 as ly_mtd_customers,
0 as fk_cd,
0 as az_cd,
0 as wfcp,
0 as wccp,
0 as op_sp_num, 
0 as op_sp_den, 
0 as ip_sp_num, 
0 as ip_sp_den,

0.0 as selection_score_v3, 
0.0 as az_product_count,
0.0 as fk_product_count,
"" as product_type,
0.0 as fk_historic_max_product_count,
0.0 as input_weighted_aug_bau_asp,
0.0 as input_weighted_cur_asp,
0.0 as input_weighted_exp_asp,
0.0 as output_weighted_aug_bau_asp,
0.0 as output_weighted_cur_asp,
0.0 as output_weighted_exp_asp,
0.0 as bau_units,
0.0 as cur_units,
'' as gst_change_flag,
0.0 as bau_gmv,
0.0 as cur_gmv,
0.0 as lids,
0.0 as priced_lids,
0.0 as priced_bau_gmv,
0.0 as priced_cur_gmv,
0.0 as m_dw, 
0.0 as cdw, 
0.0 as dw



FROM  bigfoot_external_neo.cp_bi_prod_sales__forward_unit_history_fact sales

LEFT JOIN bigfoot_external_neo.sp_product__product_categorization_hive_dim cat
      ON  sales.product_id = cat.product_id

left join 
fdp_uploads.ds_fkint_analytics_cdo_fsn_level_age_group_1_0 as pd 
on
pd.product_id=cat.product_id

LEFT JOIN  fdp_uploads.ds_fkint_cp_santa_hyperlocal_vertical_bu_mapping_2_0 AS hl 
    ON cat.analytic_vertical = hl.analytic_vertical 
    AND LOWER(hl.bu_final) = 'bgm'  
    and sales.marketplace_id='HYPERLOCAL'

LEFT JOIN

    (
    SELECT
        seller_id,
        MIN(managed_by) AS owner
    FROM fdp_uploads.ds_fkint_analytics_cdo_seller_kam_ukam_mapping_1_0
    GROUP BY seller_id
    ) AS t5 
on sales.seller_id = t5.seller_id

left join 

fdp_uploads.ds_fkint_analytics_cdo_bgm_priority_vertical_list_1_0 as pv
on 
sales.analytic_vertical=pv.vertical 

LEFT JOIN (
    SELECT seller_id,
           analytic_super_category, analytic_vertical, brand, is_priority
    FROM fdp_uploads.ds_fkint_analytics_cdo_bgm_manufacturer_seller_list_analytics_1_0
    WHERE LOWER(analytic_super_category) = 'sportfitness'
) AS seller
    ON CAST(seller.seller_id AS STRING) = CAST(sales.seller_id AS STRING)
    AND seller.analytic_super_category = cat.analytic_super_category
    AND seller.analytic_vertical = cat.analytic_vertical
    AND seller.brand = cat.brand

LEFT JOIN (
    SELECT seller_id,
           analytic_super_category, analytic_vertical, brand, is_priority
    FROM fdp_uploads.ds_fkint_analytics_cdo_bgm_manufacturer_seller_list_analytics_1_0
    WHERE LOWER(analytic_super_category) = 'toysandss'
) AS seller1
    ON seller1.seller_id = sales.seller_id
    AND seller1.analytic_super_category = cat.analytic_super_category
  
    left join 
  
    (SELECT seller_id,
           analytic_super_category, analytic_vertical, brand, is_priority
    FROM fdp_uploads.ds_fkint_analytics_cdo_bgm_manufacturer_seller_list_analytics_1_0
    WHERE LOWER(analytic_super_category) = 'babycare') as seller2 
    on seller2.seller_id=sales.seller_id 
    and seller2.analytic_super_category = cat.analytic_super_category
    and seller2.brand = cat.brand
 

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
    ON LOWER(cat.analytic_super_category) = LOWER(b.analytic_super_category)
    AND LOWER(cat.brand) = LOWER(b.brand)


LEFT JOIN 
    (
    SELECT 
        forward_unit_id,
        SUM(return_item_quantity) as return_item_quantity,
        SUM(return_amount) as return_amount
    FROM bigfoot_external_neo.scp_rrr__return_l2_id_level_hive_ss_fact
    WHERE UPPER(return_type) = 'CUSTOMER_RETURN' 
            AND (order_item_approve_date_key BETWEEN 20250101 and CAST(FORMAT_DATE('%Y%m%d', DATE_SUB(CURRENT_DATE(), INTERVAL 1 DAY)) AS INT64))
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
    
        AND cat.analytic_business_unit IN ('BGM')
        AND (sales.order_date_key BETWEEN 20250101 and CAST(FORMAT_DATE('%Y%m%d', DATE_SUB(CURRENT_DATE(), INTERVAL 1 DAY)) AS INT64))
        AND sales.is_shopsy_order = FALSE

group by
(sales.order_date_key), 
sales.marketplace_id , 
cat.analytic_business_unit , 
cat.analytic_super_category , 
cat.analytic_vertical ,
case when t5.owner ='KAM' or seller.seller_id IS NOT NULL OR seller1.seller_id IS NOT NULL OR seller2.seller_id IS NOT NULL then sales.seller_id else 'Others' end ,
case when lower(b.branded_flag)='branded' then b.brand else 'Others' end ,
case when sales.is_alpha_seller = TRUE then 'Diamond' else 'Rest of MP' end,
CAST(0 as boolean),
case when seller.seller_id IS NOT NULL OR seller1.seller_id IS NOT NULL OR seller2.seller_id IS NOT NULL then 'Manufacturers' else 'Non Manufacturers' end,
case when pv.vertical is not null then 'Priority Vertical' else 'Not Priority Vertical' end,
case when t5.owner = 'KAM' then 'KAM' else 'N-KAM' end,
case 
 when is_alpha_seller = TRUE and ((lower(sales.source_facility_id)  like '%\\_alite\\_%') or (lower(sales.source_facility_id) like '%\\_al\\_%')) then 'Alite'
    when sales.service_profile = 'FBF' then 'FBF' 
    when sales.service_profile in ('NON_FBF','FBF_LITE') then 'NFBF'
    else 'null' end ,
CASE 
        WHEN sales.gmv / sales.units <= 300 THEN "0-300"
         WHEN sales.gmv / sales.units > 300 AND sales.gmv / sales.units <= 500 then "301-500"
       WHEN sales.gmv / sales.units > 500 AND sales.gmv / sales.units <= 1000 then "501-1000"
   WHEN sales.gmv / sales.units > 1000 THEN "1000+"
 End ,

b.branded_flag ,
b.brand_tier ,
b.brand_type,
b.is_priority_brand,
CASE WHEN LOWER(b.branded_flag) = 'branded' and LOWER(b.brand_type) = 'd2c' then 'D2C' else 'Non D2C' end ,

case when lower(seller.is_priority) ="yes" OR lower(seller1.is_priority) ="yes" OR lower(seller2.is_priority) = "yes" then 'Yes' else 'No' end,
pd.age_range

union all 

select 

"new_selection" as domain_flag,
CAST(FORMAT_datetime('%Y%m%d',lhd.listing_created_on) as INT64) as order_date_key, 
lhd.marketplace_id as marketplace, 
lhd.analytic_business_unit as analytic_business_unit, 
lhd.analytic_super_category as analytic_super_category, 
lhd.analytic_vertical as analytic_vertical,
case when t5.owner ='KAM' or seller.seller_id IS NOT NULL OR seller1.seller_id IS NOT NULL OR seller2.seller_id IS NOT NULL then lhd.seller_id else 'Others' end as seller_id,
case when lower(b.branded_flag)='branded' then b.brand else 'Others' end as brand,
'' as city_tier, 
'' as zone, 
case when lhd.is_first_party_seller = TRUE then 'Diamond' else 'Rest of MP' end as is_alpha_seller,
"" as serviceability_status,
"" as az_seller_type,
CAST(0 as boolean) as torso_tail_flag,
case when seller.seller_id IS NOT NULL OR seller1.seller_id IS NOT NULL OR seller2.seller_id IS NOT NULL then 'Manufacturers' else 'Non Manufacturers' end as manufacturer_flag,
case when pv.vertical is not null then 'Priority Vertical' else 'Not Priority Vertical' end as priority_vertical_flag,
case when t5.owner = 'KAM' then 'KAM' else 'N-KAM' end as kam_nkam_flag,
case 
    when lhd.service_profile = 'FBF' then 'FBF' 
    when lhd.service_profile in ('NON_FBF','FBF_LITE','FBF_AND_FBF_LITE','FBF_AND_NON_FBF') then 'NFBF'
    else 'null' end  as service_profile,


CASE 
        WHEN lhd.flipkart_selling_price <= 300 THEN "0-300"
         WHEN lhd.flipkart_selling_price  > 300 AND lhd.flipkart_selling_price  <= 500 then "301-500"
       WHEN lhd.flipkart_selling_price  > 500 AND lhd.flipkart_selling_price  <= 1000 then "501-1000"
   WHEN lhd.flipkart_selling_price  > 1000 THEN "1000+"
 End as price_bucket,
b.branded_flag as branded_flag,
b.brand_tier as brand_tier,
b.brand_type as brand_type,
b.is_priority_brand as is_priority_brand, 
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

cast(0.0 as numeric)  as ly_gmv,
0 as ly_units,
0.0 as  sds_pure_az,
0.0 as sds_oos_attribution_pure_az,
0.0 as msku_count,
0.0 as output_fes_weighted_asp,
0.0 as output_bau_weighted_asp,
0.0 as input_bau_weighted_asp,
0.0 as input_fes_weighted_asp,
0.0 as input_fes_weighted_fsp,
0.0 as input_bau_weighted_fsp,
0.0 as output_fes_weighted_fsp,
0.0 as outut_bau_weighted_fsp,
CASE WHEN LOWER(b.branded_flag) = 'branded' and LOWER(b.brand_type) = 'd2c' then 'D2C' else 'Non D2C' end as d2c_flag,

case when lower(seller.is_priority) ="yes" OR lower(seller1.is_priority) ="yes" OR lower(seller2.is_priority) = "yes" then 'Yes' else 'No' end as manufacturer_priority_flag,

pd.age_range as age_range,
0 as transacting_selection_count,
count(distinct(lhd.listing_id)) as new_selection,
0 as csds_sds_units,
0 as csds_units,
0 as source_cluster_sale,
0 as fr_cluster_source_cluster_sale,
0 as dr_cluster_source_cluster_sale,
0 as destination_cluster_sale,
0 as fr_cluster_destination_cluster_sale,
0 as dr_cluster_destination_cluster_sale,
'' as cust_category_type, 
'' as cust_category_name, 
0 as orders, 
0 as customers,
0 as cy_mtd_orders,
0 as cy_mtd_customers,
0 as ly_mtd_orders,
0 as ly_mtd_customers,
0 as fk_cd,
0 as az_cd,
0 as wfcp,
0 as wccp,
0 as op_sp_num, 
0 as op_sp_den, 
0 as ip_sp_num, 
0 as ip_sp_den,

0.0 as selection_score_v3, 
0.0 as az_product_count,
0.0 as fk_product_count,
"" as product_type,
0.0 as fk_historic_max_product_count,
0.0 as input_weighted_aug_bau_asp,
0.0 as input_weighted_cur_asp,
0.0 as input_weighted_exp_asp,
0.0 as output_weighted_aug_bau_asp,
0.0 as output_weighted_cur_asp,
0.0 as output_weighted_exp_asp,
0.0 as bau_units,
0.0 as cur_units,
'' as gst_change_flag,
0.0 as bau_gmv,
0.0 as cur_gmv,
0.0 as lids,
0.0 as priced_lids,
0.0 as priced_bau_gmv,
0.0 as priced_cur_gmv,

0.0 as m_dw, 
0.0 as cdw, 
0.0 as dw



FROM  bigfoot_external_neo.sp_product__listing_hive_dim as lhd
left join 
fdp_uploads.ds_fkint_analytics_cdo_fsn_level_age_group_1_0 as pd 
on
pd.product_id=lhd.product_id

LEFT JOIN  fdp_uploads.ds_fkint_cp_santa_hyperlocal_vertical_bu_mapping_2_0 AS hl 
    ON lhd.analytic_vertical = hl.analytic_vertical 
    AND LOWER(hl.bu_final) = 'bgm'  
    and lhd.marketplace_id='HYPERLOCAL'

LEFT JOIN

    (
    SELECT
        seller_id,
        MIN(managed_by) AS owner
    FROM fdp_uploads.ds_fkint_analytics_cdo_seller_kam_ukam_mapping_1_0
    GROUP BY seller_id
    ) AS t5 
on lhd.seller_id = t5.seller_id

left join 

fdp_uploads.ds_fkint_analytics_cdo_bgm_priority_vertical_list_1_0 as pv
on 
lhd.analytic_vertical=pv.vertical 

LEFT JOIN (
    SELECT seller_id,
           analytic_super_category, analytic_vertical, brand, is_priority
    FROM fdp_uploads.ds_fkint_analytics_cdo_bgm_manufacturer_seller_list_analytics_1_0
    WHERE LOWER(analytic_super_category) = 'sportfitness'
) AS seller
    ON CAST(seller.seller_id AS STRING) = CAST(lhd.seller_id AS STRING)
    AND seller.analytic_super_category = lhd.analytic_super_category
    AND seller.analytic_vertical = lhd.analytic_vertical
    AND seller.brand = lhd.brand

LEFT JOIN (
    SELECT seller_id,
           analytic_super_category, analytic_vertical, brand, is_priority
    FROM fdp_uploads.ds_fkint_analytics_cdo_bgm_manufacturer_seller_list_analytics_1_0
    WHERE LOWER(analytic_super_category) = 'toysandss'
) AS seller1
    ON seller1.seller_id = lhd.seller_id
    AND seller1.analytic_super_category = lhd.analytic_super_category
  
    left join 
  
    (SELECT seller_id,
           analytic_super_category, analytic_vertical, brand, is_priority
    FROM fdp_uploads.ds_fkint_analytics_cdo_bgm_manufacturer_seller_list_analytics_1_0
    WHERE LOWER(analytic_super_category) = 'babycare') as seller2 
    on seller2.seller_id=lhd.seller_id 
    and seller2.analytic_super_category = lhd.analytic_super_category
    and seller2.brand = lhd.brand
 

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
    ON LOWER(lhd.analytic_super_category) = LOWER(b.analytic_super_category)
    AND LOWER(lhd.brand) = LOWER(b.brand)


WHERE 

      (lhd.marketplace_id IN ('FLIPKART') OR (lhd.marketplace_id = 'HYPERLOCAL' AND  hl.analytic_vertical IS NOT NULL))
    
        AND lhd.analytic_business_unit IN ('BGM')
        AND CAST(FORMAT_datetime('%Y%m%d',lhd.listing_created_on) as INT64) BETWEEN 20250101 and CAST(FORMAT_DATE('%Y%m%d', DATE_SUB(CURRENT_DATE(), INTERVAL 1 DAY)) AS INT64)
    

group by
CAST(FORMAT_datetime('%Y%m%d',lhd.listing_created_on) as INT64),
lhd.marketplace_id ,
lhd.analytic_business_unit ,
lhd.analytic_super_category ,
lhd.analytic_vertical ,
case when t5.owner ='KAM' or seller.seller_id IS NOT NULL OR seller1.seller_id IS NOT NULL OR seller2.seller_id IS NOT NULL then lhd.seller_id else 'Others' end ,
case when lower(b.branded_flag)='branded' then b.brand else 'Others' end ,
case when lhd.is_first_party_seller = TRUE then 'Diamond' else 'Rest of MP' end,
CAST(0 as boolean),
case when seller.seller_id IS NOT NULL OR seller1.seller_id IS NOT NULL OR seller2.seller_id IS NOT NULL then 'Manufacturers' else 'Non Manufacturers' end ,
case when pv.vertical is not null then 'Priority Vertical' else 'Not Priority Vertical' end ,
case when t5.owner = 'KAM' then 'KAM' else 'N-KAM' end ,
case 
    when lhd.service_profile = 'FBF' then 'FBF' 
    when lhd.service_profile in ('NON_FBF','FBF_LITE','FBF_AND_FBF_LITE','FBF_AND_NON_FBF') then 'NFBF'
    else 'null' end  ,
CASE 
        WHEN lhd.flipkart_selling_price <= 300 THEN "0-300"
         WHEN lhd.flipkart_selling_price  > 300 AND lhd.flipkart_selling_price  <= 500 then "301-500"
       WHEN lhd.flipkart_selling_price  > 500 AND lhd.flipkart_selling_price  <= 1000 then "501-1000"
   WHEN lhd.flipkart_selling_price  > 1000 THEN "1000+"
 End ,
b.branded_flag ,
b.brand_tier ,
b.brand_type ,
b.is_priority_brand ,
CASE WHEN LOWER(b.branded_flag) = 'branded' and LOWER(b.brand_type) = 'd2c' then 'D2C' else 'Non D2C' end ,

case when lower(seller.is_priority) ="yes" OR lower(seller1.is_priority) ="yes" OR lower(seller2.is_priority) = "yes" then 'Yes' else 'No' end,
pd.age_range


union all 


select

'csds' as domain_flag,
csds.date_key as order_date_key,
'' as marketplace,
csds.analytic_business_unit as analytic_business_unit,
csds.analytic_super_category as analytic_super_category,
'' as analytic_vertical,
'' as seller_id,
'' as brand,
'' as city_tier,
'' as zone,
'' as is_alpha_seller,
'' as serviceability_status,
'' as az_seller_type,
cast(0 as BOOLEAN) as torso_tail_flag,
'' as manufacturer_flag,
'' as priority_vertical_flag,
'' as kam_nkam_flag,
'' as service_profile,
case when fsp_bucket in ("0-100",'100-200','200-300') then '0-300' 
         when fsp_bucket in ("300-400",'400-500','400-500') then '301-500'
         when fsp_bucket in ('500-650','650-800','800-1000') then '501-1000'
         when fsp_bucket in ('1000-1200','1200-1400','1400-1700','1700-2000','2000+') then '1000+' end as   price_bucket,
'' as branded_flag,
'' as brand_tier,
'' as brand_type,
'' as is_priority_brand,
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
cast(0.0 as numeric)  as ly_gmv,
0 as ly_units,
0.0 as  sds_pure_az,
0.0 as sds_oos_attribution_pure_az,
0.0 as msku_count,
0.0 as output_fes_weighted_asp,
0.0 as output_bau_weighted_asp,
0.0 as input_bau_weighted_asp,
0.0 as input_fes_weighted_asp,
0.0 as input_fes_weighted_fsp,
0.0 as input_bau_weighted_fsp,
0.0 as output_fes_weighted_fsp,
0.0 as outut_bau_weighted_fsp,
"" as d2c_flag,
"" as manufacturer_priority_flag,
"" as age_range,
0 as transacting_selection_count,
0 as new_selection,
sum(csds.sds_units) as csds_sds_units,
sum(csds.units) as csds_units,
0 as source_cluster_sale,
0 as fr_cluster_source_cluster_sale,
0 as dr_cluster_source_cluster_sale,
0 as destination_cluster_sale,
0 as fr_cluster_destination_cluster_sale,
0 as dr_cluster_destination_cluster_sale,
'' as cust_category_type, 
'' as cust_category_name, 
0 as orders, 
0 as customers,
0 as cy_mtd_orders,
0 as cy_mtd_customers,
0 as ly_mtd_orders,
0 as ly_mtd_customers,
0 as fk_cd,
0 as az_cd,
0 as wfcp,
0 as wccp,
0 as op_sp_num, 
0 as op_sp_den, 
0 as ip_sp_num, 
0 as ip_sp_den,

0.0 as selection_score_v3, 
0.0 as az_product_count,
0.0 as fk_product_count,
"" as product_type,
0.0 as fk_historic_max_product_count,
0.0 as input_weighted_aug_bau_asp,
0.0 as input_weighted_cur_asp,
0.0 as input_weighted_exp_asp,
0.0 as output_weighted_aug_bau_asp,
0.0 as output_weighted_cur_asp,
0.0 as output_weighted_exp_asp,
0.0 as bau_units,
0.0 as cur_units,
'' as gst_change_flag,
0.0 as bau_gmv,
0.0 as cur_gmv,
0.0 as lids,
0.0 as priced_lids,
0.0 as priced_bau_gmv,
0.0 as priced_cur_gmv,

0.0 as m_dw, 
0.0 as cdw, 
0.0 as dw



from
bigfoot_external_neo.analytics_cdo__csds_new_msku_98p_history_fact csds
where lower(csds.analytic_business_unit) = 'bgm'
and (date_key between 20250101 and CAST(FORMAT_DATE('%Y%m%d', DATE_SUB(CURRENT_DATE(), INTERVAL 1 DAY)) AS INT64))
group by 
csds.date_key,
csds.analytic_business_unit,
csds.analytic_super_category ,
case when fsp_bucket in ("0-100",'100-200','200-300') then '0-300' 
         when fsp_bucket in ("300-400",'400-500','400-500') then '301-500'
         when fsp_bucket in ('500-650','650-800','800-1000') then '501-1000'
         when fsp_bucket in ('1000-1200','1200-1400','1400-1700','1700-2000','2000+') then '1000+' end

union all 

select

'cluster_fulfillment' as domain_flag,
cf.actual_reservation_date_key as order_date_key,
'Flipkart' as marketplace,
 prod_cat.analytic_business_unit as analytic_business_unit,
prod_cat.analytic_super_category as analytic_super_category,
prod_cat.analytic_vertical as analytic_vertical,
'' as seller_id,
case when lower(bgm.branded_flag)='branded' then prod_cat.brand else 'Others' end as brand,
'' as city_tier,
'' as zone,
case when cf.is_first_party_seller = TRUE then 'Diamond' else 'Rest of MP' end as is_alpha_seller,
'' as serviceability_status,
'' as az_seller_type,
cast(0 as BOOLEAN) as torso_tail_flag,
'' as manufacturer_flag,
'' as priority_vertical_flag,
'' as kam_nkam_flag,
'FBF' as service_profile,
'' as price_bucket,
bgm.branded_flag as branded_flag,
bgm.brand_tier as brand_tier,
bgm.brand_type as brand_type,
bgm.is_priority_brand as is_priority_brand, 
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
cast(0.0 as numeric)  as ly_gmv,
0 as ly_units,
0.0 as  sds_pure_az,
0.0 as sds_oos_attribution_pure_az,
0.0 as msku_count,
0.0 as output_fes_weighted_asp,
0.0 as output_bau_weighted_asp,
0.0 as input_bau_weighted_asp,
0.0 as input_fes_weighted_asp,
0.0 as input_fes_weighted_fsp,
0.0 as input_bau_weighted_fsp,
0.0 as output_fes_weighted_fsp,
0.0 as outut_bau_weighted_fsp,
"" as d2c_flag,
"" as manufacturer_priority_flag,
"" as age_range,
0 as transacting_selection_count,
0 as new_selection,
0 as csds_sds_units,
0 as csds_units,
SUM(cf.source_cluster_sale) as source_cluster_sale, 
SUM(case when cf.fr_dr_cluster_type = 'FR_cluster' then  cf.source_cluster_sale else 0 end) as fr_cluster_source_cluster_sale,
SUM(case when cf.fr_dr_cluster_type = 'DR_cluster' then  cf.source_cluster_sale else 0 end) as dr_cluster_source_cluster_sale,
 
SUM(cf.destination_cluster_sale) as destination_cluster_sale,
SUM(case when cf.fr_dr_cluster_type = 'FR_cluster' then  cf.destination_cluster_sale else 0 end) as fr_cluster_destination_cluster_sale,
SUM(case when cf.fr_dr_cluster_type = 'DR_cluster' then  cf.destination_cluster_sale else 0 end) as dr_cluster_destination_cluster_sale,
'' as cust_category_type, 
'' as cust_category_name, 
0 as orders, 
0 as customers,
0 as cy_mtd_orders,
0 as cy_mtd_customers,
0 as ly_mtd_orders,
0 as ly_mtd_customers,
0 as fk_cd,
0 as az_cd,
0 as wfcp,
0 as wccp,
0 as op_sp_num, 
0 as op_sp_den, 
0 as ip_sp_num, 
0 as ip_sp_den,

0.0 as selection_score_v3, 
0.0 as az_product_count,
0.0 as fk_product_count,
"" as product_type,
0.0 as fk_historic_max_product_count,

0.0 as input_weighted_aug_bau_asp,
0.0 as input_weighted_cur_asp,
0.0 as input_weighted_exp_asp,
0.0 as output_weighted_aug_bau_asp,
0.0 as output_weighted_cur_asp,
0.0 as output_weighted_exp_asp,
0.0 as bau_units,
0.0 as cur_units,
'' as gst_change_flag,
0.0 as bau_gmv,
0.0 as cur_gmv,
0.0 as lids,
0.0 as priced_lids,
0.0 as priced_bau_gmv,
0.0 as priced_cur_gmv,

0.0 as m_dw, 
0.0 as cdw, 
0.0 as dw
 




from bigfoot_external_neo.retail_ip__cluster_fulfillment_historical_hive_fact cf

LEFT JOIN bigfoot_external_neo.sp_product__product_categorization_hive_dim prod_cat 
    on cf.fsn = prod_cat.product_id 

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
)  as bgm
ON LOWER(prod_cat.analytic_super_category) = LOWER(bgm.analytic_super_category)
AND LOWER(prod_cat.brand) = LOWER(bgm.brand)

WHERE (cf.actual_reservation_date_key between 20250101 and CAST(FORMAT_DATE('%Y%m%d', DATE_SUB(CURRENT_DATE(), INTERVAL 1 DAY)) AS INT64))
    AND prod_cat.analytic_business_unit = 'BGM'
    AND cf.cluster_city is not null 
    AND TRIM(cf.cluster_city) NOT IN ('','PUNE_CLUSTER')
    AND cf.fc not IN ('ban_dol_al_hyb_nl_01nl', 'ban_mad_al_urb_nl_01nl', 'micro_surat_01', 'mum_mah_al_hyb_nl_01nl', 'mum_tha_al_ban_nl_01nl', 'mum_tha_al_urb_nl_01nl', 'mys_bel_wh_nl_01nl', 'new_new_al_urb_nl_01nl', 'ran_gag_al_urb_nl_01nl')

Group by 

cf.actual_reservation_date_key ,
 prod_cat.analytic_business_unit ,
prod_cat.analytic_super_category ,
prod_cat.analytic_vertical ,
case when lower(bgm.branded_flag)='branded' then prod_cat.brand else 'Others' end ,
case when cf.is_first_party_seller = TRUE then 'Diamond' else 'Rest of MP' end ,
bgm.branded_flag ,
bgm.brand_tier,
bgm.brand_type ,
bgm.is_priority_brand

union all 


select 
'customer_metric' as domain_flag,
order_date_key as order_date_key,
'' as marketplace,
'' as analytic_business_unit,
'' as analytic_super_category,
'' as analytic_vertical,
'' as seller_id,
'' as brand,
'' as city_tier,
'' as zone,
'' as is_alpha_seller,
'' as serviceability_status,
'' as az_seller_type,
  CAST(0 as boolean)  as torso_tail_flag,
'' as manufacturer_flag,
'' as priority_vertical_flag,
'' as kam_nkam_flag,
'' as service_profile,
'' as price_bucket,
'' as branded_flag,
'' as brand_tier,
'' as brand_type,
'' as is_priority_brand,
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
cast(0.0 as numeric)  as ly_gmv,
0 as ly_units,
0.0 as  sds_pure_az,
0.0 as sds_oos_attribution_pure_az,
0.0 as msku_count,
0.0 as output_fes_weighted_asp,
0.0 as output_bau_weighted_asp,
0.0 as input_bau_weighted_asp,
0.0 as input_fes_weighted_asp,
0.0 as input_fes_weighted_fsp,
0.0 as input_bau_weighted_fsp,
0.0 as output_fes_weighted_fsp,
0.0 as outut_bau_weighted_fsp,
'' as d2c_flag,
'' as manufacturer_priority_flag,
'' as age_range,
0 as transacting_selection_count,
0 as new_selection,
0 as csds_sds_units,
0 as csds_units,
0 as source_cluster_sale,
0 as fr_cluster_source_cluster_sale,
0 as dr_cluster_source_cluster_sale,
0 as destination_cluster_sale,
0 as fr_cluster_destination_cluster_sale,
0 as dr_cluster_destination_cluster_sale,
category_type as cust_category_type,
category_name as cust_category_name,
orders as orders,
customers as customers,
0 as cy_mtd_orders,
0 as cy_mtd_customers,
0 as ly_mtd_orders,
0 as ly_mtd_customers,
0 as fk_cd,
0 as az_cd,
0 as wfcp,
0 as wccp,
0 as op_sp_num, 
0 as op_sp_den, 
0 as ip_sp_num, 
0 as ip_sp_den,

0.0 as selection_score_v3, 
0.0 as az_product_count,
0.0 as fk_product_count,
"" as product_type,
0.0 as fk_historic_max_product_count,
0.0 as input_weighted_aug_bau_asp,
0.0 as input_weighted_cur_asp,
0.0 as input_weighted_exp_asp,
0.0 as output_weighted_aug_bau_asp,
0.0 as output_weighted_cur_asp,
0.0 as output_weighted_exp_asp,
0.0 as bau_units,
0.0 as cur_units,
'' as gst_change_flag,
0.0 as bau_gmv,
0.0 as cur_gmv,
0.0 as lids,
0.0 as priced_lids,
0.0 as priced_bau_gmv,
0.0 as priced_cur_gmv,

0.0 as m_dw, 
0.0 as cdw, 
0.0 as dw


from 
(

WITH Base AS (
  SELECT 
        sales.account_id,
        sales.units as units,
        sales.gmv as gmv,
        sales.order_external_id,
        cat.analytic_business_unit,
        cat.analytic_vertical,
        cat.analytic_super_category,
        sales.order_item_id,
        sales.order_date_key
    FROM bigfoot_external_neo.cp_bi_prod_sales__forward_unit_history_fact sales

    LEFT JOIN bigfoot_external_neo.sp_product__product_categorization_hive_dim cat
      ON  sales.product_id = cat.product_id

    LEFT JOIN  fdp_uploads.ds_fkint_cp_santa_hyperlocal_vertical_bu_mapping_2_0 AS hl 
    ON cat.analytic_vertical = hl.analytic_vertical 
    AND LOWER(hl.bu_final) = 'bgm'  
    and sales.marketplace_id='HYPERLOCAL'

   WHERE LOWER(sales.status) IN ('in_progress', 'undelivered', 'completed', 'delivered', 'approved', 'shipped', 'ready_to_ship', 'returned', 'return_requested', 'activated')
        AND sales.type  = 'physical'
        AND sales.replacement_for_unit IS NULL
        AND sales.exchange_for_unit IS NULL
        AND sales.is_freebie = FALSE
        AND (sales.marketplace_id IN ('FLIPKART') OR (sales.marketplace_id = 'HYPERLOCAL' AND  hl.analytic_vertical IS NOT NULL))
        AND cat.analytic_business_unit IN ('BGM')
        AND (sales.order_date_key BETWEEN 20250101 and CAST(FORMAT_DATE('%Y%m%d', DATE_SUB(CURRENT_DATE(), INTERVAL 1 DAY)) AS INT64))
        AND sales.is_shopsy_order = FALSE
),

Aggregated AS (
    SELECT 
        order_date_key,
        'business_unit' AS category_type,
        analytic_business_unit AS category_name,
        COUNT(DISTINCT order_external_id) AS orders,
        COUNT(DISTINCT account_id) AS customers

    FROM Base

    GROUP BY order_date_key, 
    analytic_business_unit

    UNION ALL

    SELECT 
    order_date_key,
    'super_category' AS category_type,
    analytic_super_category AS category_name,
    COUNT(DISTINCT order_external_id) AS orders,
    COUNT(DISTINCT account_id) AS customers
    
FROM Base

GROUP BY 
    order_date_key, 
    analytic_super_category


    Union all

    select 
     order_date_key,
    'price_bucket' AS category_type,
    CASE 
        WHEN Base.gmv / Base.units <= 300 THEN "0-300"
         WHEN Base.gmv / Base.units > 300 AND Base.gmv / Base.units <= 500 then "301-500"
       WHEN Base.gmv / Base.units > 500 AND Base.gmv / Base.units <= 1000 then "501-1000"
   WHEN Base.gmv / Base.units > 1000 THEN "1000+"
 End as category_name,
    COUNT(DISTINCT order_external_id) AS orders,
    COUNT(DISTINCT account_id) AS customers
    
FROM Base

GROUP BY 
    order_date_key, 
    CASE 
        WHEN Base.gmv / Base.units <= 300 THEN "0-300"
         WHEN Base.gmv / Base.units > 300 AND Base.gmv / Base.units <= 500 then "301-500"
       WHEN Base.gmv / Base.units > 500 AND Base.gmv / Base.units <= 1000 then "501-1000"
   WHEN Base.gmv / Base.units > 1000 THEN "1000+"
 End
   
)

SELECT order_date_key,
category_type,
category_name,
orders,
customers

 FROM Aggregated ) as cust 

 union all



select 
'customer_metric_mtd' as domain_flag,
order_date_key as order_date_key,
'' as marketplace,
 analytic_business_unit as analytic_business_unit,
 analytic_super_category as analytic_super_category,
'' as analytic_vertical,
'' as seller_id,
'' as brand,
'' as city_tier,
'' as zone,
'' as is_alpha_seller,
'' as serviceability_status,
'' as az_seller_type,
  CAST(0 as boolean)  as torso_tail_flag,
'' as manufacturer_flag,
'' as priority_vertical_flag,
'' as kam_nkam_flag,
'' as service_profile,
price_bucket as price_bucket,
'' as branded_flag,
'' as brand_tier,
'' as brand_type,
'' as is_priority_brand,
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
cast(0.0 as numeric)  as ly_gmv,
0 as ly_units,
0.0 as  sds_pure_az,
0.0 as sds_oos_attribution_pure_az,
0.0 as msku_count,
0.0 as output_fes_weighted_asp,
0.0 as output_bau_weighted_asp,
0.0 as input_bau_weighted_asp,
0.0 as input_fes_weighted_asp,
0.0 as input_fes_weighted_fsp,
0.0 as input_bau_weighted_fsp,
0.0 as output_fes_weighted_fsp,
0.0 as outut_bau_weighted_fsp,
'' as d2c_flag,
'' as manufacturer_priority_flag,
'' as age_range,
0 as transacting_selection_count,
0 as new_selection,
0 as csds_sds_units,
0 as csds_units,
0 as source_cluster_sale,
0 as fr_cluster_source_cluster_sale,
0 as dr_cluster_source_cluster_sale,
0 as destination_cluster_sale,
0 as fr_cluster_destination_cluster_sale,
0 as dr_cluster_destination_cluster_sale,
category_type as cust_category_type,
'' as cust_category_name,
0 as orders,
0 as customers,
orders as cy_mtd_orders,
customers as cy_mtd_customers,
0 as ly_mtd_orders,
0 as ly_mtd_customers,
0 as fk_cd,
0 as az_cd,
0 as wfcp,
0 as wccp,
0 as op_sp_num, 
0 as op_sp_den, 
0 as ip_sp_num, 
0 as ip_sp_den,

0.0 as selection_score_v3, 
0.0 as az_product_count,
0.0 as fk_product_count,
"" as product_type,
0.0 as fk_historic_max_product_count,

0.0 as input_weighted_aug_bau_asp,
0.0 as input_weighted_cur_asp,
0.0 as input_weighted_exp_asp,
0.0 as output_weighted_aug_bau_asp,
0.0 as output_weighted_cur_asp,
0.0 as output_weighted_exp_asp,
0.0 as bau_units,
0.0 as cur_units,
'' as gst_change_flag,
0.0 as bau_gmv,
0.0 as cur_gmv,
0.0 as lids,
0.0 as priced_lids,
0.0 as priced_bau_gmv,
0.0 as priced_cur_gmv,

0.0 as m_dw, 
0.0 as cdw, 
0.0 as dw


from 
(

WITH Base AS (
  SELECT 
        sales.account_id,
        sales.units as units,
        sales.gmv as gmv,
        sales.order_external_id,
        cat.analytic_business_unit,
        cat.analytic_vertical,
        cat.analytic_super_category,
        sales.order_item_id,
        sales.order_date_key
    FROM bigfoot_external_neo.cp_bi_prod_sales__forward_unit_history_fact sales

    LEFT JOIN bigfoot_external_neo.sp_product__product_categorization_hive_dim cat
      ON  sales.product_id = cat.product_id





    LEFT JOIN  fdp_uploads.ds_fkint_cp_santa_hyperlocal_vertical_bu_mapping_2_0 AS hl 
    ON cat.analytic_vertical = hl.analytic_vertical 
    AND LOWER(hl.bu_final) = 'bgm'  
    and sales.marketplace_id='HYPERLOCAL'

   WHERE LOWER(sales.status) IN ('in_progress', 'undelivered', 'completed', 'delivered', 'approved', 'shipped', 'ready_to_ship', 'returned', 'return_requested', 'activated')
        AND sales.type  = 'physical'
        AND sales.replacement_for_unit IS NULL
        AND sales.exchange_for_unit IS NULL
        AND sales.is_freebie = FALSE
        AND (sales.marketplace_id IN ('FLIPKART') OR (sales.marketplace_id = 'HYPERLOCAL' AND  hl.analytic_vertical IS NOT NULL))
        AND cat.analytic_business_unit IN ('BGM')
        AND (sales.order_date_key BETWEEN 20250101 and CAST(FORMAT_DATE('%Y%m%d', DATE_SUB(CURRENT_DATE(), INTERVAL 1 DAY)) AS INT64))
        AND sales.is_shopsy_order = FALSE
),

Aggregated AS (
   
        SELECT 
        
CAST(CONCAT(SUBSTRING(CAST(base.order_date_key AS STRING), 0, 6), '01') AS INT64) AS order_date_key,
  'business_unit' AS category_type,
        analytic_business_unit AS analytic_business_unit,
        '' as analytic_super_category,
        '' as price_bucket,
        COUNT(DISTINCT order_external_id) AS orders,
        COUNT(DISTINCT account_id) AS customers
    FROM Base

    GROUP BY CAST(CONCAT(SUBSTRING(CAST(base.order_date_key AS STRING), 0, 6), '01') AS INT64) ,
    analytic_business_unit


    UNION ALL


    SELECT 
CAST(CONCAT(SUBSTRING(CAST(base.order_date_key AS STRING), 0, 6), '01') AS INT64) AS order_date_key,
  'super_category' AS category_type,
   '' AS analytic_business_unit,
        analytic_super_category  as analytic_super_category,
        '' as price_bucket,
        COUNT(DISTINCT order_external_id) AS orders,
        COUNT(DISTINCT account_id) AS customers
    FROM Base

    GROUP BY CAST(CONCAT(SUBSTRING(CAST(base.order_date_key AS STRING), 0, 6), '01') AS INT64) ,
  
    analytic_super_category



   union all

  

     SELECT 
CAST(CONCAT(SUBSTRING(CAST(base.order_date_key AS STRING), 0, 6), '01') AS INT64) AS order_date_key,
  'price_bucket' AS category_type,
  '' AS analytic_business_unit,
  '' as analytic_super_category,
         CASE 
        WHEN Base.gmv / Base.units <= 300 THEN "0-300"
         WHEN Base.gmv / Base.units > 300 AND Base.gmv / Base.units <= 500 then "301-500"
       WHEN Base.gmv / Base.units > 500 AND Base.gmv / Base.units <= 1000 then "501-1000"
   WHEN Base.gmv / Base.units > 1000 THEN "1000+"
 End AS price_bucket,
        COUNT(DISTINCT order_external_id) AS orders,
        COUNT(DISTINCT account_id) AS customers
    FROM Base

    GROUP BY CAST(CONCAT(SUBSTRING(CAST(base.order_date_key AS STRING), 0, 6), '01') AS INT64) ,
  
     CASE 
        WHEN Base.gmv / Base.units <= 300 THEN "0-300"
         WHEN Base.gmv / Base.units > 300 AND Base.gmv / Base.units <= 500 then "301-500"
       WHEN Base.gmv / Base.units > 500 AND Base.gmv / Base.units <= 1000 then "501-1000"
   WHEN Base.gmv / Base.units > 1000 THEN "1000+"
 End

  
   
)

SELECT order_date_key,
category_type,
analytic_business_unit,
analytic_super_category,
price_bucket,
orders,
customers
 FROM Aggregated ) as cust 


 union all 

select 
'ly_customer_metric_mtd' as domain_flag,
order_date_key as order_date_key,
'' as marketplace,
 analytic_business_unit as analytic_business_unit,
 analytic_super_category as analytic_super_category,
'' as analytic_vertical,
'' as seller_id,
'' as brand,
'' as city_tier,
'' as zone,
'' as is_alpha_seller,
'' as serviceability_status,
'' as az_seller_type,
  CAST(0 as boolean)  as torso_tail_flag,
'' as manufacturer_flag,
'' as priority_vertical_flag,
'' as kam_nkam_flag,
'' as service_profile,
price_bucket as price_bucket,
'' as branded_flag,
'' as brand_tier,
'' as brand_type,
'' as is_priority_brand,
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
cast(0.0 as numeric)  as ly_gmv,
0 as ly_units,
0.0 as  sds_pure_az,
0.0 as sds_oos_attribution_pure_az,
0.0 as msku_count,
0.0 as output_fes_weighted_asp,
0.0 as output_bau_weighted_asp,
0.0 as input_bau_weighted_asp,
0.0 as input_fes_weighted_asp,
0.0 as input_fes_weighted_fsp,
0.0 as input_bau_weighted_fsp,
0.0 as output_fes_weighted_fsp,
0.0 as outut_bau_weighted_fsp,
'' as d2c_flag,
'' as manufacturer_priority_flag,
'' as age_range,
0 as transacting_selection_count,
0 as new_selection,
0 as csds_sds_units,
0 as csds_units,
0 as source_cluster_sale,
0 as fr_cluster_source_cluster_sale,
0 as dr_cluster_source_cluster_sale,
0 as destination_cluster_sale,
0 as fr_cluster_destination_cluster_sale,
0 as dr_cluster_destination_cluster_sale,
category_type as cust_category_type,
'' as cust_category_name,
0 as orders,
0 as customers,
0 as cy_mtd_orders,
0 as cy_mtd_customers,
orders as ly_mtd_orders,
customers as ly_mtd_customers,
0 as fk_cd,
0 as az_cd,
0 as wfcp,
0 as wccp,
0 as op_sp_num, 
0 as op_sp_den, 
0 as ip_sp_num, 
0 as ip_sp_den,

0.0 as selection_score_v3, 
0.0 as az_product_count,
0.0 as fk_product_count,
"" as product_type,
0.0 as fk_historic_max_product_count,

0.0 as input_weighted_aug_bau_asp,
0.0 as input_weighted_cur_asp,
0.0 as input_weighted_exp_asp,
0.0 as output_weighted_aug_bau_asp,
0.0 as output_weighted_cur_asp,
0.0 as output_weighted_exp_asp,
0.0 as bau_units,
0.0 as cur_units,
'' as gst_change_flag,
0.0 as bau_gmv,
0.0 as cur_gmv,
0.0 as lids,
0.0 as priced_lids,
0.0 as priced_bau_gmv,
0.0 as priced_cur_gmv,

0.0 as m_dw, 
0.0 as cdw, 
0.0 as dw


from 
(

WITH Base AS (
  SELECT 
        sales.account_id,
        sales.units as units,
        sales.gmv as gmv,
        sales.order_external_id,
        cat.analytic_business_unit,
        cat.analytic_vertical,
        cat.analytic_super_category,
        sales.order_item_id,
        sales.order_date_key
    FROM bigfoot_external_neo.cp_bi_prod_sales__forward_unit_history_fact sales

    LEFT JOIN bigfoot_external_neo.sp_product__product_categorization_hive_dim cat
      ON  sales.product_id = cat.product_id


    LEFT JOIN  fdp_uploads.ds_fkint_cp_santa_hyperlocal_vertical_bu_mapping_2_0 AS hl 
    ON cat.analytic_vertical = hl.analytic_vertical 
    AND LOWER(hl.bu_final) = 'bgm'  
    and sales.marketplace_id='HYPERLOCAL'

   WHERE LOWER(sales.status) IN ('in_progress', 'undelivered', 'completed', 'delivered', 'approved', 'shipped', 'ready_to_ship', 'returned', 'return_requested', 'activated')
        AND sales.type  = 'physical'
        AND sales.replacement_for_unit IS NULL
        AND sales.exchange_for_unit IS NULL
        AND sales.is_freebie = FALSE
        AND (sales.marketplace_id IN ('FLIPKART') OR (sales.marketplace_id = 'HYPERLOCAL' AND  hl.analytic_vertical IS NOT NULL))
        AND cat.analytic_business_unit IN ('BGM')
        AND (sales.order_date_key BETWEEN 20240101 and CAST(FORMAT_DATE('%Y%m%d', DATE_SUB(DATE_SUB(CURRENT_DATE(), INTERVAL 1 YEAR), INTERVAL 1 DAY)) AS INT64))
        AND sales.is_shopsy_order = FALSE
),

Aggregated AS (
   
        SELECT 
        
CAST(CONCAT(SUBSTRING(CAST(base.order_date_key AS STRING), 0, 6), '01') AS INT64) AS order_date_key,
  'business_unit' AS category_type,
        analytic_business_unit AS analytic_business_unit,
        '' as analytic_super_category,
        '' as price_bucket,
        COUNT(DISTINCT order_external_id) AS orders,
        COUNT(DISTINCT account_id) AS customers
    FROM Base

    GROUP BY CAST(CONCAT(SUBSTRING(CAST(base.order_date_key AS STRING), 0, 6), '01') AS INT64) ,
    analytic_business_unit


    UNION ALL


    SELECT 
CAST(CONCAT(SUBSTRING(CAST(base.order_date_key AS STRING), 0, 6), '01') AS INT64) AS order_date_key,
  'super_category' AS category_type,
   '' AS analytic_business_unit,
        analytic_super_category  as analytic_super_category,
        '' as price_bucket,
        COUNT(DISTINCT order_external_id) AS orders,
        COUNT(DISTINCT account_id) AS customers
    FROM Base

    GROUP BY CAST(CONCAT(SUBSTRING(CAST(base.order_date_key AS STRING), 0, 6), '01') AS INT64) ,
  
    analytic_super_category



    Union all

  

     SELECT 
CAST(CONCAT(SUBSTRING(CAST(base.order_date_key AS STRING), 0, 6), '01') AS INT64) AS order_date_key,
  'price_bucket' AS category_type,
  '' AS analytic_business_unit,
  '' as analytic_super_category,
         CASE 
        WHEN Base.gmv / Base.units <= 300 THEN "0-300"
         WHEN Base.gmv / Base.units > 300 AND Base.gmv / Base.units <= 500 then "301-500"
       WHEN Base.gmv / Base.units > 500 AND Base.gmv / Base.units <= 1000 then "501-1000"
   WHEN Base.gmv / Base.units > 1000 THEN "1000+"
 End AS price_bucket,
        COUNT(DISTINCT order_external_id) AS orders,
        COUNT(DISTINCT account_id) AS customers
    FROM Base

    GROUP BY CAST(CONCAT(SUBSTRING(CAST(base.order_date_key AS STRING), 0, 6), '01') AS INT64) ,
  
     CASE 
        WHEN Base.gmv / Base.units <= 300 THEN "0-300"
         WHEN Base.gmv / Base.units > 300 AND Base.gmv / Base.units <= 500 then "301-500"
       WHEN Base.gmv / Base.units > 500 AND Base.gmv / Base.units <= 1000 then "501-1000"
   WHEN Base.gmv / Base.units > 1000 THEN "1000+"
 End

  
   
)

SELECT order_date_key + 10000 as order_date_key ,
category_type,
analytic_business_unit,
analytic_super_category,
price_bucket,
orders,
customers
 FROM Aggregated ) as cust 



 union all 

 SELECT 
        'settlement_price' as domain_flag,
        main.order_date_key as order_date_key,
        '' as marketplace,
        main.bu as analytic_business_unit,
        main.sc as analytic_super_category,
        main.analytic_vertical as analytic_vertical,
        main.seller_id as seller_id, 
        main.brand as brand, 
        '' as city_tier, 
        '' as zone, 
        main.is_alpha_seller as is_alpha_seller,
        '' as serviceability_status,
        '' as az_seller_type , 
        cast(0 as boolean) as torso_tail_flag, 
        main.manufacturer_flag as manufacturer_flag, 
        main.priority_vertical_flag as priority_vertical_flag, 
        main.kam_nkam_flag as kam_nkam_flag,
        main.service_profile as service_profile, 
        main.price_bucket as price_bucket, 
        main.branded_flag as branded_flag, 
        main.brand_tier as brand_tier,
        main.brand_type as brand_type,
        main.is_priority_brand as is_priority_brand, 
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
cast(0.0 as numeric)  as ly_gmv,
0 as ly_units,
0.0 as  sds_pure_az,
0.0 as sds_oos_attribution_pure_az,
0.0 as msku_count,
0.0 as output_fes_weighted_asp,
0.0 as output_bau_weighted_asp,
0.0 as input_bau_weighted_asp,
0.0 as input_fes_weighted_asp,
0.0 as input_fes_weighted_fsp,
0.0 as input_bau_weighted_fsp,
0.0 as output_fes_weighted_fsp,
0.0 as outut_bau_weighted_fsp,
main.d2c_flag as d2c_flag,
main.manufacturer_priority_flag as manufacturer_priority_flag,
'' as age_range,
0 as transacting_selection_count,
0 as new_selection,
0 as csds_sds_units,
0 as csds_units,
0 as source_cluster_sale,
0 as fr_cluster_source_cluster_sale,
0 as dr_cluster_source_cluster_sale,
0 as destination_cluster_sale,
0 as fr_cluster_destination_cluster_sale,
0 as dr_cluster_destination_cluster_sale,
'' as cust_category_type,
'' as cust_category_name,
0 as orders,
0 as customers,
0 as cy_mtd_orders,
0 as cy_mtd_customers,
0 as ly_mtd_orders,
0 as ly_mtd_customers,
0 as fk_cd,
0 as az_cd,
0 as wfcp,
0 as wccp,
SUM((main.settlement_price - baseline.settlement_price) * main.units) AS op_sp_num,
SUM(baseline.settlement_price * main.units) AS op_sp_den,
SUM((main.settlement_price - baseline.settlement_price) * baseline.units) AS ip_sp_num,
SUM(baseline.settlement_price * baseline.units) AS ip_sp_den,

0.0 as selection_score_v3, 
0.0 as az_product_count,
0.0 as fk_product_count,
'' as product_type,
0.0 as fk_historic_max_product_count,

0.0 as input_weighted_aug_bau_asp,
0.0 as input_weighted_cur_asp,
0.0 as input_weighted_exp_asp,
0.0 as output_weighted_aug_bau_asp,
0.0 as output_weighted_cur_asp,
0.0 as output_weighted_exp_asp,
0.0 as bau_units,
0.0 as cur_units,
'' as gst_change_flag,
0.0 as bau_gmv,
0.0 as cur_gmv,
0.0 as lids,
0.0 as priced_lids,
0.0 as priced_bau_gmv,
0.0 as priced_cur_gmv,

0.0 as m_dw, 
0.0 as cdw, 
0.0 as dw
    
    
    
    FROM 
    	(
        SELECT
     		sp.order_date_key as order_date_key,

            sp.listing_id,
            cat.analytic_business_unit AS bu,
            cat.analytic_super_category as sc,
            cat.analytic_vertical as analytic_vertical,
            case when t5.owner ='KAM' or seller.seller_id IS NOT NULL OR seller1.seller_id IS NOT NULL OR seller2.seller_id IS NOT NULL then sp.seller_id else 'Others' end as seller_id,
            case when lower(b.branded_flag)='branded' then cat.brand else 'Others' end as brand,
            '' as city_tier, 
            '' as zone,  
            case when lhd.is_first_party_seller = TRUE then 'Diamond' else 'Rest of MP' end as is_alpha_seller, 
            0 as torso_tail_flag,
            case when seller.seller_id IS NOT NULL OR seller1.seller_id IS NOT NULL OR seller2.seller_id IS NOT NULL then 'Manufacturers' else 'Non Manufacturers' end as manufacturer_flag,
            case when pv.vertical is not null then 'Priority Vertical' else 'Not Priority Vertical' end as priority_vertical_flag,
            case when t5.owner = 'KAM' then 'KAM' else 'N-KAM' end as kam_nkam_flag,

            case 
                when lhd.service_profile = 'FBF' then 'FBF' 
                when lhd.service_profile in ('NON_FBF','FBF_LITE','FBF_AND_FBF_LITE','FBF_AND_NON_FBF') then 'NFBF'
                else 'null' end  as service_profile,

            CASE 
                  WHEN sp.gmv / sp.units <= 300 THEN "0-300"
               WHEN sp.gmv / sp.units > 300 AND sp.gmv / sp.units <= 500 then "301-500"
              WHEN sp.gmv / sp.units > 500 AND sp.gmv / sp.units <= 1000 then "501-1000"
             WHEN sp.gmv / sp.units > 1000 THEN "1000+"
            End as price_bucket,
            b.branded_flag as branded_flag,
            b.brand_tier as brand_tier,
            b.brand_type as brand_type,
            b.is_priority_brand as is_priority_brand, 
            CASE WHEN LOWER(b.branded_flag) = 'branded' and LOWER(b.brand_type) = 'd2c' then 'D2C' else 'Non D2C' end as d2c_flag,

            case when lower(seller.is_priority) ="yes" OR lower(seller1.is_priority) ="yes" OR lower(seller2.is_priority) = "yes" then 'Yes' else 'No' end as manufacturer_priority_flag,
            t5.owner as owner,
            SUM(sp.units) AS units,
            SUM(sp.gmv)  AS gmv,
            SUM(sp.gmv) / SUM(sp.units)  AS asp,
            SUM(sp.settlement_price  * sp.units ) / SUM(sp.units)  AS settlement_price,
            SUM(sp.listing_price * sp.units) / SUM(sp.units)  AS listing_price
        
        FROM bigfoot_external_neo.cp_santa__mp_seller_pre_settlement_fact sp 

         LEFT JOIN bigfoot_external_neo.sp_product__product_categorization_hive_dim cat
        ON  sp.product_id = cat.product_id

        left join 

            fdp_uploads.ds_fkint_analytics_cdo_bgm_priority_vertical_list_1_0 as pv
            on cat.analytic_vertical=pv.vertical 

        left join bigfoot_external_neo.sp_product__listing_hive_dim as lhd
        on lhd.listing_id = sp.listing_id



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
    ON LOWER(cat.analytic_super_category) = LOWER(b.analytic_super_category)
    AND LOWER(cat.brand) = LOWER(b.brand)



        LEFT JOIN (
    SELECT seller_id,
           analytic_super_category, analytic_vertical, brand, is_priority
    FROM fdp_uploads.ds_fkint_analytics_cdo_bgm_manufacturer_seller_list_analytics_1_0
    WHERE LOWER(analytic_super_category) = 'sportfitness'
) AS seller
    ON CAST(seller.seller_id AS STRING) = CAST(sp.seller_id AS STRING)
    AND seller.analytic_super_category = cat.analytic_super_category
    AND seller.analytic_vertical = cat.analytic_vertical
    AND seller.brand = cat.brand

LEFT JOIN (
    SELECT seller_id,
           analytic_super_category, analytic_vertical, brand, is_priority
    FROM fdp_uploads.ds_fkint_analytics_cdo_bgm_manufacturer_seller_list_analytics_1_0
    WHERE LOWER(analytic_super_category) = 'toysandss'
) AS seller1
    ON seller1.seller_id = sp.seller_id
    AND seller1.analytic_super_category = cat.analytic_super_category
  
    left join 
  
    (SELECT seller_id,
           analytic_super_category, analytic_vertical, brand, is_priority
    FROM fdp_uploads.ds_fkint_analytics_cdo_bgm_manufacturer_seller_list_analytics_1_0
    WHERE LOWER(analytic_super_category) = 'babycare') as seller2 
    on seller2.seller_id=sp.seller_id 
    and seller2.analytic_super_category = cat.analytic_super_category
    and seller2.brand = cat.brand

      

        LEFT JOIN bigfoot_external_neo.scp_oms__date_dim_fact date_dim
            ON sp.order_date_key = date_dim.date_dim_key

        LEFT JOIN
		    (
		    SELECT
		        seller_id,
		        MIN(managed_by) AS owner
		    FROM fdp_uploads.ds_fkint_analytics_cdo_seller_kam_ukam_mapping_1_0
		    GROUP BY seller_id
		    ) AS t5 
			on sp.seller_id = t5.seller_id



        WHERE sp.order_date_key >= 20250101
            AND sp.units  > 0
            AND sp.listing_price > 0
            AND LOWER(sp.analytic_business_unit) IN ('bgm')

        GROUP BY
       		sp.order_date_key ,

            sp.listing_id,
            cat.analytic_business_unit ,
            cat.analytic_super_category ,
            cat.analytic_vertical ,
            case when t5.owner ='KAM' or seller.seller_id IS NOT NULL OR seller1.seller_id IS NOT NULL OR seller2.seller_id IS NOT NULL then sp.seller_id else 'Others' end ,
            case when lower(b.branded_flag)='branded' then cat.brand else 'Others' end ,
            
            case when lhd.is_first_party_seller = TRUE then 'Diamond' else 'Rest of MP' end ,
        
            case when seller.seller_id IS NOT NULL OR seller1.seller_id IS NOT NULL OR seller2.seller_id IS NOT NULL then 'Manufacturers' else 'Non Manufacturers' end,
            case when pv.vertical is not null then 'Priority Vertical' else 'Not Priority Vertical' end ,
            case when t5.owner = 'KAM' then 'KAM' else 'N-KAM' end ,

            case 
                when lhd.service_profile = 'FBF' then 'FBF' 
                when lhd.service_profile in ('NON_FBF','FBF_LITE','FBF_AND_FBF_LITE','FBF_AND_NON_FBF') then 'NFBF'
                else 'null' end ,

            CASE 
                  WHEN sp.gmv / sp.units <= 300 THEN "0-300"
               WHEN sp.gmv / sp.units > 300 AND sp.gmv / sp.units <= 500 then "301-500"
              WHEN sp.gmv / sp.units > 500 AND sp.gmv / sp.units <= 1000 then "501-1000"
             WHEN sp.gmv / sp.units > 1000 THEN "1000+"
            End ,

            b.branded_flag ,
            b.brand_tier ,
            b.brand_type ,
            b.is_priority_brand ,
            CASE WHEN LOWER(b.branded_flag) = 'branded' and LOWER(b.brand_type) = 'd2c' then 'D2C' else 'Non D2C' end ,

            case when lower(seller.is_priority) ="yes" OR lower(seller1.is_priority) ="yes" OR lower(seller2.is_priority) = "yes" then 'Yes' else 'No' end,
            t5.owner

    	) main

    INNER JOIN 
   		(
        SELECT
            listing_id,
            SUM(units) AS units,
            SUM(settlement_price * units) / SUM(units) AS settlement_price

        FROM bigfoot_external_neo.cp_santa__mp_seller_pre_settlement_fact

        WHERE order_date_key BETWEEN 20250315 AND 20250415
            AND units  > 0
            AND listing_price > 0
            AND LOWER(analytic_business_unit) IN ('bgm')
        GROUP BY listing_id
    	) baseline 
    	ON baseline.listing_id = main.listing_id

    GROUP BY 
       
         main.order_date_key ,
    
        main.bu ,
        main.sc ,
        main.analytic_vertical ,
        main.seller_id ,
        main.brand ,
        main.is_alpha_seller ,
        
        main.manufacturer_flag ,
        main.priority_vertical_flag ,
        main.kam_nkam_flag ,
        main.service_profile ,
        main.price_bucket,
        main.branded_flag ,
        main.brand_tier ,
        main.brand_type,
        main.is_priority_brand ,
        main.d2c_flag ,
main.manufacturer_priority_flag


union all 

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
'' as serviceability_status,
'' as az_seller_type,
cast(0 as boolean) as torso_tail_flag,
'' as manufacturer_flag, 
'' as priority_vertical_flag, 
'' as kam_nkam_flag, 
'' as service_profile,
mpi_data.price_bucket  as price_bucket,
'' as branded_flag,
'' as brand_tier,
'' as brand_type, 
'' as is_priority_brand,

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
cast(0.0 as numeric)  as ly_gmv,
0 as ly_units,
0.0 as  sds_pure_az,
0.0 as sds_oos_attribution_pure_az,
0.0 as msku_count,
0.0 as output_fes_weighted_asp,
0.0 as output_bau_weighted_asp,
0.0 as input_bau_weighted_asp,
0.0 as input_fes_weighted_asp,
0.0 as input_fes_weighted_fsp,
0.0 as input_bau_weighted_fsp,
0.0 as output_fes_weighted_fsp,
0.0 as outut_bau_weighted_fsp,
'' as d2c_flag,
'' as manufacturer_priority_flag,
'' as age_range,
0 as transacting_selection_count,
0 as new_selection,
0 as csds_sds_units,
0 as csds_units,
0 as source_cluster_sale,
0 as fr_cluster_source_cluster_sale,
0 as dr_cluster_source_cluster_sale,
0 as destination_cluster_sale,
0 as fr_cluster_destination_cluster_sale,
0 as dr_cluster_destination_cluster_sale,
'' as cust_category_type,
'' as cust_category_name,
0 as orders,
0 as customers,
0 as cy_mtd_orders,
0 as cy_mtd_customers,
0 as ly_mtd_orders,
0 as ly_mtd_customers,
0 as fk_cd,
0 as az_cd,
0 as wfcp,
0 as wccp,
0.0 AS op_sp_num,
0.0 AS op_sp_den,
0.0 AS ip_sp_num,
0.0 AS ip_sp_den,

0.0 as selection_score_v3, 
0.0 as az_product_count,
0.0 as fk_product_count,
'' as product_type,
0.0 as fk_historic_max_product_count,

0.0 as input_weighted_aug_bau_asp,
0.0 as input_weighted_cur_asp,
0.0 as input_weighted_exp_asp,
0.0 as output_weighted_aug_bau_asp,
0.0 as output_weighted_cur_asp,
0.0 as output_weighted_exp_asp,
0.0 as bau_units,
0.0 as cur_units,
'' as gst_change_flag,
0.0 as bau_gmv,
0.0 as cur_gmv,
0.0 as lids,
0.0 as priced_lids,
0.0 as priced_bau_gmv,
0.0 as priced_cur_gmv,

SUM(mpi_data.m_dw) as m_dw,
SUM(mpi_data.cdw) as cdw,
SUM(mpi_data.dw) as dw,



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
		AND lower(comp.analytic_business_unit) in ('bgm')

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


   ) as lsp_fact

