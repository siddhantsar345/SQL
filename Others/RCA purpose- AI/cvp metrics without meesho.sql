    WITH bmp_brands AS (
        SELECT
            brand,
            analytic_super_category
        FROM fdp_uploads.ds_fkint_analytics_cdo_final_central_consolidated_sc_brand_list_fact_1_0
        GROUP BY       
            brand,
            analytic_super_category
    ),

    pareto_verticals AS(
        SELECT analytic_super_category,analytic_vertical
    FROM (
        SELECT
            analytic_super_category,
            analytic_vertical,
            SUM(vertical_gmv) OVER (PARTITION BY analytic_super_category ORDER BY vertical_gmv DESC ROWS UNBOUNDED PRECEDING) AS vert_gmv_cumilative,
            SUM(vertical_gmv) OVER (PARTITION BY analytic_super_category) AS total_sc_gmv,
            SUM(vertical_gmv) OVER (PARTITION BY analytic_super_category ORDER BY vertical_gmv DESC) / SUM(vertical_gmv) OVER (PARTITION BY analytic_super_category) AS percentage_value
        FROM (
            SELECT
                sales.analytic_super_category,
                sales.analytic_vertical,
                SUM(gmv) AS vertical_gmv
            FROM bigfoot_external_neo.cp_bi_prod_sales__forward_unit_history_fact sales
            WHERE LOWER(sales.status) IN ('in_progress','undelivered','completed','delivered','approved','shipped','ready_to_ship','returned','return_requested','activated')
                AND sales.type != 'service'
                AND sales.replacement_for_unit IS NULL
                AND sales.exchange_for_unit IS NULL
                AND sales.is_freebie = FALSE
                AND sales.marketplace_id IN ('FLIPKART')
                AND sales.is_shopsy_order = FALSE
                AND LOWER(sales.analytic_business_unit) IN ('bgm','home','lifestyle','furniture')
                AND order_date_key BETWEEN 20250701 AND 20260331
            GROUP BY sales.analytic_super_category, sales.analytic_vertical
        ) base
    ) base2
    WHERE percentage_value <= 0.8
    )

    SELECT
    speed.order_date_key as order_date_key,
    speed.analytic_business_unit as analytic_business_unit,
    speed.analytic_super_category as analytic_super_category, 
    speed.analytic_vertical as analytic_vertical, 
    speed.brand as brand, 
    speed.branded_flag as branded_flag,
    speed.is_alpha_seller as is_alpha_seller, 

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


    price_drop.input_bau_weighted_asp as input_bau_weighted_asp,
    price_drop.input_fes_weighted_asp as input_fes_weighted_asp,
    price_drop.output_bau_weighted_asp as output_bau_weighted_asp,
    price_drop.output_fes_weighted_asp as output_fes_weighted_asp

    FROM


    (
    SELECT
        sales.order_date_key,
        sales.analytic_business_unit,
        sales.analytic_super_category,
        sales.analytic_vertical,
        CASE WHEN bmp.brand IS NOT NULL THEN sales.brand ELSE 'Unbranded' END AS brand, 
        CASE WHEN bmp.brand IS NOT NULL THEN 'Branded' ELSE 'Unbranded' END AS branded_flag,
        CASE WHEN sales.is_alpha_seller = TRUE THEN 'Diamond' ELSE 'Rest of MP' END AS is_alpha_seller, 
        
        SUM(sales.units) as total_units,
        SUM(CASE WHEN sales.sla_in_days <= 0 THEN sales.units ELSE 0 END) AS d0_units,
        SUM(CASE WHEN sales.sla_in_days <= 1 THEN sales.units ELSE 0 END) AS d1_units,
        SUM(CASE WHEN sales.sla_in_days <= 2 THEN sales.units ELSE 0 END) AS d2_units,
        SUM(CASE WHEN sales.sla_in_days <= 4 THEN sales.units ELSE 0 END) AS d4_units,
        SUM(CASE WHEN sales.sla_in_days <= 6 THEN sales.units ELSE 0 END) AS d6_units
    FROM bigfoot_external_neo.cp_bi_prod_sales__forward_unit_history_fact sales
    LEFT JOIN bmp_brands bmp 
        ON LOWER(sales.brand) = LOWER(bmp.brand) 
        AND LOWER(sales.analytic_super_category) = LOWER(bmp.analytic_super_category)
    WHERE LOWER(sales.status) IN ('in_progress', 'undelivered', 'completed', 'delivered', 'approved', 'shipped', 'ready_to_ship', 'returned', 'return_requested', 'activated')
        AND sales.type  !='service'
        AND sales.replacement_for_unit IS NULL
        AND sales.exchange_for_unit IS NULL
        AND sales.is_freebie = FALSE
        AND sales.marketplace_id IN ('FLIPKART')
        AND lower(sales.analytic_business_unit) IN ('bgm','home','lifestyle','furniture')
        AND sales.order_date_key between 20240801 and 20241231
        AND sales.is_shopsy_order = FALSE    
    GROUP BY
        sales.order_date_key,
        sales.analytic_business_unit,
        sales.analytic_super_category,
        sales.analytic_vertical,
        CASE WHEN bmp.brand IS NOT NULL THEN sales.brand ELSE 'Unbranded' END, 
        CASE WHEN bmp.brand IS NOT NULL THEN 'Branded' ELSE 'Unbranded' END,
        CASE WHEN sales.is_alpha_seller = TRUE THEN 'Diamond' ELSE 'Rest of MP' END 
    ) as speed


    INNER JOIN pareto_verticals pv
    ON LOWER(speed.analytic_super_category) = LOWER(pv.analytic_super_category)
    AND LOWER(speed.analytic_vertical) = LOWER(pv.analytic_vertical)


    LEFT JOIN


    (
    SELECT
        list_dim.process_date_key as order_date_key,
        prod_dim.analytic_business_unit as analytic_business_unit,
        prod_dim.analytic_super_category as analytic_super_category,
        prod_dim.analytic_vertical as analytic_vertical,
        CASE WHEN bmp.brand IS NOT NULL THEN prod_dim.brand ELSE 'Unbranded' END AS brand, 
        CASE WHEN bmp.brand IS NOT NULL THEN 'Branded' ELSE 'Unbranded' END AS branded_flag,
        sales.is_alpha_seller as is_alpha_seller,

        count(distinct list_dim.listing_id) as a_listings,
        count(distinct list_dim.product_id) as a_products,
        count(distinct case when list_dim.final_atp > 0 then list_dim.listing_id end) as ai_listings,
        count(distinct case when list_dim.final_atp > 0 then list_dim.product_id end) as ai_products

    FROM bigfoot_external_neo.sp_analytics__listing_history_90d_fact as list_dim

    LEFT JOIN bigfoot_external_neo.sp_product__product_categorization_hive_dim prod_dim
        on list_dim.product_id = prod_dim.product_id

    LEFT JOIN bmp_brands bmp 
        ON LOWER(prod_dim.brand) = LOWER(bmp.brand) 
        AND LOWER(prod_dim.analytic_super_category) = LOWER(bmp.analytic_super_category)

    LEFT JOIN (
        SELECT 
        listing_id,
        CASE WHEN is_alpha_seller = TRUE THEN 'Diamond' ELSE 'Rest of MP' END AS is_alpha_seller
        FROM bigfoot_external_neo.cp_bi_prod_sales__forward_unit_history_fact
        WHERE order_date_key between 20240801 and 20241231
        GROUP BY 
        listing_id, 
        CASE WHEN is_alpha_seller = TRUE THEN 'Diamond' ELSE 'Rest of MP' END
    ) as sales
        ON list_dim.listing_id = sales.listing_id

    WHERE list_dim.marketplace_id = 'FLIPKART'
        and lower(prod_dim.analytic_business_unit) in ('bgm','home','lifestyle','furniture')
        and list_dim.process_date_key between 20240801 and 20241231
    GROUP BY
        list_dim.process_date_key,
        prod_dim.analytic_business_unit,
        prod_dim.analytic_super_category,
        prod_dim.analytic_vertical,
        CASE WHEN bmp.brand IS NOT NULL THEN prod_dim.brand ELSE 'Unbranded' END, 
        CASE WHEN bmp.brand IS NOT NULL THEN 'Branded' ELSE 'Unbranded' END,
        sales.is_alpha_seller
    ) as instock


    ON
    instock.order_date_key = speed.order_date_key and
    instock.analytic_business_unit = speed.analytic_business_unit and
    instock.analytic_super_category = speed.analytic_super_category and
    instock.analytic_vertical = speed.analytic_vertical and
    instock.brand = speed.brand and 
    instock.branded_flag = speed.branded_flag and
    instock.is_alpha_seller = speed.is_alpha_seller



    LEFT JOIN
    (
    
    SELECT  
        a.order_date_key,
        a.analytic_business_unit,  
        a.analytic_super_category,
        a.analytic_vertical,
        a.brand, 
        a.branded_flag,
        a.is_alpha_seller, 
        
        SUM(CASE WHEN lower(a.competitor) IN ('ai') AND a.ci_business_unit NOT IN ("BGM(Books)", "Electronics") THEN a.search_ppvs ELSE 0 END) AS ai_search_ppvs,
        SUM(CASE WHEN a.fsn_coupon_landscape = "FK_Comp" AND lower(a.competitor) IN ('ai') AND a.ci_business_unit NOT IN ("BGM(Books)", "Electronics") THEN a.search_ppvs ELSE 0 END) AS ai_fk_cd,
        SUM(CASE WHEN a.fsn_coupon_landscape = "AI_Comp" AND lower(a.competitor) IN ('ai') AND a.ci_business_unit NOT IN ("BGM(Books)", "Electronics") THEN a.search_ppvs ELSE 0 END) AS ai_az_cd,
        SUM(CASE WHEN lower(a.competitor) IN ('ai') AND a.ci_business_unit NOT IN ("BGM(Books)", "Electronics") THEN a.fk_price_post_coupon * a.search_ppvs ELSE 0 END) AS ai_wfcp,
        SUM(CASE WHEN lower(a.competitor) IN ('ai') AND a.ci_business_unit NOT IN ("BGM(Books)", "Electronics") THEN a.comp_price_post_coupon * a.search_ppvs ELSE 0 END) AS ai_wccp,

        SUM(CASE WHEN lower(a.competitor) IN ("myntra") AND a.ci_business_unit IN ("lifestyle-Non_Apparel","lifestyle-Apparel") THEN a.search_ppvs ELSE 0 END) AS myntra_search_ppvs,
        SUM(CASE WHEN a.fsn_coupon_landscape = "FK_Comp" AND lower(a.competitor) IN ("myntra") AND a.ci_business_unit IN ("lifestyle-Non_Apparel","lifestyle-Apparel") THEN a.search_ppvs ELSE 0 END) AS myntra_fk_cd,
        SUM(CASE WHEN a.fsn_coupon_landscape = "AI_Comp" AND lower(a.competitor) IN ("myntra") AND a.ci_business_unit IN ("lifestyle-Non_Apparel","lifestyle-Apparel") THEN a.search_ppvs ELSE 0 END) AS myntra_az_cd,
        SUM(CASE WHEN lower(a.competitor) IN ("myntra") AND a.ci_business_unit IN ("lifestyle-Non_Apparel","lifestyle-Apparel") THEN a.fk_price_post_coupon * a.search_ppvs ELSE 0 END) AS myntra_wfcp,
        SUM(CASE WHEN lower(a.competitor) IN ("myntra") AND a.ci_business_unit IN ("lifestyle-Non_Apparel","lifestyle-Apparel") THEN a.comp_price_post_coupon * a.search_ppvs ELSE 0 END) AS myntra_wccp

    FROM  
        (
        SELECT  
            CAST(date_key AS int64) AS order_date_key,
            a.competitor,  
            a.yearmo,  
            b.week_num_in_year,  
            a.analytic_business_unit,  
            a.ci_business_unit,  
            a.analytic_super_category,  
            CASE WHEN lower(prod.analytic_business_unit) = 'lifestyle' THEN prod.cms_vertical ELSE prod.analytic_vertical END AS analytic_vertical,
            CASE WHEN bmp.brand IS NOT NULL THEN a.brand ELSE 'Unbranded' END AS brand, 
            CASE WHEN bmp.brand IS NOT NULL THEN 'Branded' ELSE 'Unbranded' END AS branded_flag,
            a.fk_seller_type AS is_alpha_seller, 
            a.mcat_tag,
            a.az_seller_type,  
            search_ppvs,  
            fsn_landscape,  
            fk_price, 
            comp_price,  
            fk_price_post_coupon,  
            (comp_price - COALESCE(comp_coupon_discount, 0)) AS comp_price_post_coupon,
            CASE
            WHEN fk_price_post_coupon < 1000 AND (comp_price - COALESCE(comp_coupon_discount, 0)) / NULLIF(fk_price_post_coupon, 0) > 1.02 THEN "FK_Comp"
            WHEN fk_price_post_coupon < 1000 AND (comp_price - COALESCE(comp_coupon_discount, 0)) / NULLIF(fk_price_post_coupon, 0) < 0.98 THEN "AI_Comp"
            WHEN fk_price_post_coupon >= 1000 AND (comp_price - COALESCE(comp_coupon_discount, 0)) / NULLIF(fk_price_post_coupon, 0) > 1.01 THEN "FK_Comp"
            WHEN fk_price_post_coupon >= 1000 AND (comp_price - COALESCE(comp_coupon_discount, 0)) / NULLIF(fk_price_post_coupon, 0) < 0.99 THEN "AI_Comp"
            ELSE "Parity"
            END AS fsn_coupon_landscape
        FROM bigfoot_external_neo.analytics_cdo__unweighted_comp_base_hist_fact AS a  
        LEFT JOIN bigfoot_external_neo.sp_product__product_categorization_hive_dim prod
            ON prod.product_id = a.fsn
        LEFT JOIN bigfoot_external_neo.scp_oms__date_dim_fact AS b  
            ON CAST(b.date_dim_key AS string) = a.date_key 
        LEFT JOIN bmp_brands bmp 
            ON LOWER(a.brand) = LOWER(bmp.brand) 
            AND LOWER(a.analytic_super_category) = LOWER(bmp.analytic_super_category)
        WHERE (CAST(date_key AS int64) between 20240801 and 20241231)
            AND (
            (lower(competitor) IN ("ai") AND ci_business_unit NOT IN ("BGM(Books)", "Electronics"))
            OR
            (lower(competitor) IN ("myntra") AND ci_business_unit IN ("lifestyle-Non_Apparel","lifestyle-Apparel"))
            )
        ) AS a
    GROUP BY
        a.order_date_key,
        a.analytic_business_unit,
        a.analytic_super_category,
        a.analytic_vertical,
        a.brand, 
        a.branded_flag,
        a.is_alpha_seller 
    ) as ai_myntra
    ON
    ai_myntra.order_date_key = speed.order_date_key and
    ai_myntra.analytic_business_unit = speed.analytic_business_unit and
    ai_myntra.analytic_super_category = speed.analytic_super_category and
    ai_myntra.analytic_vertical = speed.analytic_vertical and
    ai_myntra.brand = speed.brand and 
    ai_myntra.branded_flag = speed.branded_flag and
    ai_myntra.is_alpha_seller = speed.is_alpha_seller 


    LEFT JOIN


    (
    SELECT
        order_date_key,
        analytic_business_unit,
        analytic_super_category,
        analytic_vertical,
        brand, 
        branded_flag,
        is_alpha_seller, 

        SUM(input_bau_weighted_asp) as input_bau_weighted_asp,
        SUM(input_fes_weighted_asp) as input_fes_weighted_asp,
        SUM(output_bau_weighted_asp) as output_bau_weighted_asp,
        SUM(output_fes_weighted_asp) as output_fes_weighted_asp
    FROM
    (
        SELECT
        fes.order_date_key as order_date_key,
        bau.analytic_business_unit,
        bau.analytic_super_category,
        bau.analytic_vertical,
        bau.brand, 
        bau.branded_flag,
        bau.is_alpha_seller, 
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
            analytic_vertical,
            CASE WHEN bmp.brand IS NOT NULL THEN sales.brand ELSE 'Unbranded' END AS brand, 
            CASE WHEN bmp.brand IS NOT NULL THEN 'Branded' ELSE 'Unbranded' END AS branded_flag,
            CASE WHEN sales.is_alpha_seller = TRUE THEN 'Diamond' ELSE 'Rest of MP' END as is_alpha_seller,
            sales.product_id,
            sales.listing_id,
            SUM(units) as units,
            SUM(gmv) as gmv,
            SUM(listing_price) as lp
        FROM bigfoot_external_neo.cp_bi_prod_sales__forward_unit_history_fact sales
        LEFT JOIN bmp_brands bmp 
            ON LOWER(sales.brand) = LOWER(bmp.brand) 
            AND LOWER(sales.analytic_super_category) = LOWER(bmp.analytic_super_category)
        WHERE lower(sales.status) in ('in_progress','undelivered','completed','delivered','approved','shipped','ready_to_ship','returned', 'return_requested','activated')
            AND sales.type !='service'
            AND sales.replacement_for_unit IS NULL
            AND sales.exchange_for_unit IS NULL
            AND sales.is_freebie =FALSE
            AND sales.marketplace_id IN ('FLIPKART')
            AND sales.is_shopsy_order =FALSE
            AND lower(sales.analytic_business_unit) IN ('bgm','home','lifestyle','furniture')
            AND ((order_date_key between 20230701 and 20230831))
        GROUP BY
            sales.analytic_super_category,
            analytic_business_unit,
            analytic_vertical,
            CASE WHEN bmp.brand IS NOT NULL THEN sales.brand ELSE 'Unbranded' END, 
            CASE WHEN bmp.brand IS NOT NULL THEN 'Branded' ELSE 'Unbranded' END,
            CASE WHEN sales.is_alpha_seller = TRUE THEN 'Diamond' ELSE 'Rest of MP' END,
            sales.product_id,
            sales.listing_id
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
            AND lower(sales.analytic_business_unit) IN ('bgm','home','lifestyle','furniture')
            AND order_date_key between 20240801 and 20241231
        GROUP BY
            sales.listing_id,
            order_date_key
        ) fes
        ON bau.listing_id = fes.listing_id
    ) sub
    GROUP BY
        order_date_key,
        analytic_business_unit,
        analytic_super_category,
        analytic_vertical,
        brand, 
        branded_flag,
        is_alpha_seller 
    ) as price_drop
    ON
    price_drop.order_date_key = speed.order_date_key and
    price_drop.analytic_business_unit = speed.analytic_business_unit and
    price_drop.analytic_super_category = speed.analytic_super_category and
    price_drop.analytic_vertical = speed.analytic_vertical and
    price_drop.brand = speed.brand and 
    price_drop.branded_flag = speed.branded_flag and
    price_drop.is_alpha_seller = speed.is_alpha_seller