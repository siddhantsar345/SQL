SELECT 
    FORMAT_DATETIME('%Y%m', list.listing_created_on) as year_mo,
    prod_dim.analytic_business_unit,
    
    CASE
        WHEN list.flipkart_selling_price <= 300 THEN "0-300"
        WHEN list.flipkart_selling_price <= 500 THEN "300-500"
        WHEN list.flipkart_selling_price > 500 THEN "500+"
        ELSE "NA" 
    END AS fsp_bucket,

    COUNT(DISTINCT CASE WHEN hist.final_atp > 0 THEN list.listing_id END) AS ai_listings,
    COUNT(DISTINCT CASE WHEN list.listing_created_on = list.first_seen THEN list.product_id END) AS new_selection_products

FROM
(
    SELECT 
        listing_id,
        product_id,
        listing_created_on,
        flipkart_selling_price,
        MIN(listing_created_on) OVER(PARTITION BY product_id) AS first_seen
    FROM bigfoot_external_neo.sp_product__listing_hive_dim
    WHERE marketplace_id = 'FLIPKART'
      AND CAST(listing_created_on AS DATE) BETWEEN '2025-12-01' AND '2026-01-31'
) AS list

LEFT JOIN bigfoot_external_neo.sp_product__product_attribute_hive_dim prod_dim
    ON list.product_id = prod_dim.product_id

LEFT JOIN bigfoot_external_neo.sp_analytics__listing_history_90d_fact hist
    ON list.listing_id = hist.listing_id 
    AND CAST(FORMAT_DATE('%Y%m%d', CAST(list.listing_created_on AS DATE)) AS INT64) = hist.process_date_key
WHERE lower(prod_dim.analytic_business_unit) IN ('home', 'furniture')  
  AND lower(prod_dim.analytic_vertical) NOT IN ('plantsapling', 'plantseed')  
  AND (prod_dim.analytic_vertical NOT IN ('MobileProtectionDesignerCaseCover','Book','BikeBodyCover','MobileProtectionPlainCaseCover','WatchCombo','CarBodyCover','MobileSkin','MobileProtectionMobileScreenGuard',
        'CameraLensProtector','SmartWatchStraps','SmartWatchScreenGuard','MobileProtectionDesignerCaseCover(OLD)','MobileProtectionPlainCaseCover(OLD)','MobileProtectionMobilePouches(OLD)'
        ) 
        OR prod_dim.vertical_name IN ('book','regionalbooks')
      ) 
        
GROUP BY 1, 2, 3