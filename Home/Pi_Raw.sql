SELECT 
    sales.yearmo,
    sales.analytic_business_unit,
    sum(search_ppvs) search_ppvs,
	sum(fk_price * search_ppvs) AS fk_price_npi,
    sum(comp_price * search_ppvs) AS comp_price_npi,
    sum(case when fsn_landscape = 'FK_Comp' then search_ppvs end) fk_comp,
    sum(case when fsn_landscape = 'AI_Comp' then search_ppvs end) az_comp,
    sum(case when fsn_coupon_landscape= "FK_Comp" then search_ppvs else 0 end ) as fk_cd,
    sum(case when fsn_coupon_landscape= "AI_Comp" then search_ppvs else 0 end ) as az_cd,
    sum(fk_price_post_coupon * search_ppvs) as wfcp,
    sum(comp_price_post_coupon * search_ppvs) as wccp,
    (sum(case when fsn_coupon_landscape= "FK_Comp" then search_ppvs else 0 end ) - sum(case when fsn_coupon_landscape= "AI_Comp" then search_ppvs else 0 end )) as comp_price_cd
FROM
    (
        SELECT
        a.yearmo,
        b.week_num_in_year,
        a.analytic_business_unit,
        a.analytic_super_category,
        a.analytic_vertical,
        a.mcat_tag,
        a.fk_seller_type,
        a.az_seller_type,
        is_branded,
        a.brand,
        search_ppvs,
        fsn_landscape,
        fk_price,
        comp_price,
        fk_price_post_coupon,
        fsn,
        (comp_price-coalesce(comp_coupon_discount,0)) as comp_price_post_coupon,
        CASE
            WHEN fk_price_post_coupon < 1000 AND (comp_price-coalesce(comp_coupon_discount,0))/NULLIF(fk_price_post_coupon,0) > 1.02 THEN "FK_Comp"
            WHEN fk_price_post_coupon < 1000 AND (comp_price-coalesce(comp_coupon_discount,0))/NULLIF(fk_price_post_coupon,0) < 0.98 THEN "AI_Comp"
            WHEN fk_price_post_coupon >= 1000 AND (comp_price-coalesce(comp_coupon_discount,0))/NULLIF(fk_price_post_coupon,0) < 0.99 THEN "AI_Comp"
            WHEN fk_price_post_coupon >= 1000 AND (comp_price-coalesce(comp_coupon_discount,0))/NULLIF(fk_price_post_coupon,0) > 1.01 THEN "FK_Comp"
            ELSE "Parity"
        END as fsn_coupon_landscape
        FROM bigfoot_external_neo.cp_santa__unweighted_comp_base_fact a
        LEFT JOIN 
        bigfoot_external_neo.scp_oms__date_dim_fact b
            on cast(date_dim_key as string)=a.date_key
        WHERE
            (CAST(a.date_key as INT64) between 20250101 and 20250803)
            AND competitor in ('AI')
            AND ci_business_unit in ('Home')
            AND analytic_business_unit in ('Home')
        GROUP BY
            a.yearmo,
            b.week_num_in_year,
            a.analytic_business_unit,
            a.analytic_super_category,
            a.analytic_vertical,
            a.mcat_tag,
            a.fk_seller_type,
            a.az_seller_type,
            is_branded,
            a.brand,
            search_ppvs,
            fsn_landscape,
            fk_price,
            comp_price,
            fk_price_post_coupon,
            fsn,
            comp_coupon_discount,
            fsn_coupon_landscape
    ) sales
GROUP BY 
    sales.yearmo,
    sales.analytic_business_unit;