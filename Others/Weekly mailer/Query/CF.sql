select

cf.actual_reservation_date_key as order_date_key,
prod_cat.analytic_business_unit as analytic_business_unit,
prod_cat.analytic_super_category as analytic_super_category,
prod_cat.analytic_vertical as analytic_vertical,
case when cf.is_first_party_seller = TRUE then 'Diamond' else 'Rest of MP' end as is_alpha_seller,
CASE WHEN bmp.brand IS NOT NULL THEN prod_cat.brand ELSE 'Unbranded' END AS brand, 
case when bmp.brand is not null then 'Branded' else 'Unbranded' end as brand_flag, 
'FBF' as service_profile,

SUM(cf.source_cluster_sale) as source_cluster_sale, 
SUM(case when cf.fr_dr_cluster_type = 'FR_cluster' then  cf.source_cluster_sale else 0 end) as fr_cluster_source_cluster_sale,
SUM(case when cf.fr_dr_cluster_type = 'DR_cluster' then  cf.source_cluster_sale else 0 end) as dr_cluster_source_cluster_sale,
 
SUM(cf.destination_cluster_sale) as destination_cluster_sale,
SUM(case when cf.fr_dr_cluster_type = 'FR_cluster' then  cf.destination_cluster_sale else 0 end) as fr_cluster_destination_cluster_sale,
SUM(case when cf.fr_dr_cluster_type = 'DR_cluster' then  cf.destination_cluster_sale else 0 end) as dr_cluster_destination_cluster_sale

from bigfoot_external_neo.retail_ip__cluster_fulfillment_historical_hive_fact cf

LEFT JOIN bigfoot_external_neo.sp_product__product_categorization_hive_dim prod_cat 
    on cf.fsn = prod_cat.product_id 

LEFT JOIN
       (
       select
           brand,
           analytic_super_category
       from fdp_uploads.ds_fkint_analytics_cdo_final_central_consolidated_sc_brand_list_fact_1_0
       group by      
           brand,
           analytic_super_category
       ) bmp
       on lower(prod_cat.brand) = lower(bmp.brand)
       and lower(prod_cat.analytic_super_category) = lower(bmp.analytic_super_category)


WHERE (cf.actual_reservation_date_key between 20260101 and CAST(FORMAT_DATE('%Y%m%d', DATE_SUB(CURRENT_DATE(), INTERVAL 1 DAY)) AS INT64))
    AND lower(prod_cat.analytic_business_unit) in ('bgm','home','lifestyle','furniture')
    AND cf.cluster_city is not null 
    AND TRIM(cf.cluster_city) NOT IN ('','PUNE_CLUSTER')
    AND cf.fc not IN ('ban_dol_al_hyb_nl_01nl', 'ban_mad_al_urb_nl_01nl', 'micro_surat_01', 'mum_mah_al_hyb_nl_01nl', 'mum_tha_al_ban_nl_01nl', 'mum_tha_al_urb_nl_01nl', 'mys_bel_wh_nl_01nl', 'new_new_al_urb_nl_01nl', 'ran_gag_al_urb_nl_01nl')

Group by 

cf.actual_reservation_date_key ,
 prod_cat.analytic_business_unit ,
prod_cat.analytic_super_category ,
prod_cat.analytic_vertical ,
case when cf.is_first_party_seller = TRUE then 'Diamond' else 'Rest of MP' end ,
CASE WHEN bmp.brand IS NOT NULL THEN prod_cat.brand ELSE 'Unbranded' END,
case when bmp.brand is not null then 'Branded' else 'Unbranded' end