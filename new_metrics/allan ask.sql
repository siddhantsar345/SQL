-- seller score query --

    with sqs_data AS (
        SELECT 
            seller_id,
            MAX(overall_score) as sqs
        FROM bigfoot_external_neo.sp_analytics__seller_score_fact
        GROUP BY seller_id
    ),

-- listing quality score query --

    lqs_data AS (
        SELECT 
            listing_id, 
            MIN(v3_cluster) as lqs 
        FROM bigfoot_external_neo.sp_darwin__listing_quality_score_final_view_fact
        GROUP BY listing_id
    ),

-- ratings query --

    pq_data AS (
        SELECT
            fsn,
            SUM(ROUND(rating, 1) * rating_count) / SUM(rating_count) AS avg_rating
        FROM (
            SELECT 
                data.domainid AS fsn, 
                data.rating AS rating, 
                COUNT(data.ratingId) as rating_count
            FROM bigfoot_snapshot.dart_fkint_cp_ca_ugc_ratingentity_1_view_total
            WHERE data.domaintype = 'product'
                AND data.certifiedbuyer = TRUE
                AND (data.aspectId IS NULL OR data.aspectId = 'overall')
            GROUP BY data.domainid, data.rating
        ) aa
        GROUP BY fsn
    ),

    apr_sales_data AS (
    SELECT
        listing_id,
        SUM(gmv) AS apr_gmv,
        SUM(units) AS apr_units
    FROM bigfoot_external_neo.cp_bi_prod_sales__forward_unit_history_fact
    WHERE order_date_key BETWEEN 20260401 AND 20260430
        AND marketplace_id = 'FLIPKART'
        AND type != 'service'
        AND is_freebie = FALSE
    GROUP BY listing_id
)

-- for getting the latest snapshot --

    SELECT
        list_hive.analytic_super_category as sc,
        list_hive.analytic_vertical as vertical,
        list_hive.brand,
        list_hive.product_id as fsn,
        list_hive.seller_id,
        list_hive.listing_id,
        list_hive.is_first_party_seller as alpha_mp,
        list_hive.service_profile, 
        list_hive.flipkart_selling_price as fsp,
        lqs.lqs,
        sqs.sqs,
        pq.avg_rating as pq,
        apr.apr_gmv AS gmv,
        apr.apr_units AS units

    FROM bigfoot_external_neo.sp_product__listing_hive_dim as list_hive

    LEFT JOIN sqs_data sqs ON list_hive.seller_id = sqs.seller_id

    LEFT JOIN lqs_data lqs ON list_hive.listing_id = lqs.listing_id

    LEFT JOIN pq_data pq   ON list_hive.product_id = pq.fsn

    LEFT JOIN apr_sales_data apr ON list_hive.listing_id = apr.listing_id

    WHERE list_hive.marketplace_id = 'FLIPKART'
        AND LOWER(list_hive.analytic_business_unit) = 'bgm'
        AND UPPER(list_hive.brand) IN ('BIOTIQUE', 'COLGATE', 'LUVLAP')
        AND UPPER(list_hive.listing_status) = 'ACTIVE'