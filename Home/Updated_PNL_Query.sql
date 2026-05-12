SELECT
    *,
    --RTO_RVP_formula
    overall_rto_gmv_percentage * gmv as final_rto_gmv,
    overall_rto_units_percentage * units as final_rto_units,
    overall_rvp_gmv_percentage * gmv as final_rvp_gmv,
    overall_rvp_units_percentage * units as final_rvp_units,

    --CN_formula
    case
        when cnxfsn_formula = "Gross Units" then cnxfsn_value * units
        when cnxfsn_formula = "Net Units" then (cnxfsn_value * (units * (1 - overall_rto_units_percentage - overall_rvp_units_percentage)))
        when cnxfsn_formula = "% of net MRP" then (cnxfsn_value * (mrp / units) * (units * (1 - overall_rto_units_percentage - overall_rvp_units_percentage)))
    end as final_CN,

    ---Cogs and Im formula
    case
        when overall_cogs_im_percentage is null or overall_cogs_im_percentage = 0 then ((units - (overall_rto_units_percentage * units) - (overall_rvp_units_percentage * units)) * cogsxfsn__cost_per_unit)
        when cogsxfsn__cost_per_unit is null or cogsxfsn__cost_per_unit = 0 then ((((mrp / units) * (units * (1 - overall_rto_units_percentage - overall_rvp_units_percentage))) * (1 - overall_cogs_im_percentage)) / (1 + overall_tax_percentage))
        when overall_cogs_im_percentage > 0 and cogsxfsn__cost_per_unit > 0 then GREATEST(((units - (overall_rto_units_percentage * units) - (overall_rvp_units_percentage * units)) * cogsxfsn__cost_per_unit), ((((mrp / units) * (units * (1 - overall_rto_units_percentage - overall_rvp_units_percentage))) * (1 - overall_cogs_im_percentage)) / (1 + overall_tax_percentage)))
        else 0
    end as final_cogs_im,

    --Net_units
    (units - (units * overall_rto_units_percentage) - (units * overall_rvp_units_percentage)) as net_units,

    --Net_gmv
    (gmv - (gmv * overall_rto_gmv_percentage) - (gmv * overall_rvp_gmv_percentage)) as nmv,

    --SCM formula
    (overall_final_cpu * units) as final_scm,

    ----Bl_SC_formula
    sub2.freight * (gmv - (gmv * overall_rto_gmv_percentage) - (gmv * overall_rvp_gmv_percentage)) as final_freight,
    sub2.sc_losses_excl_expiry * (gmv - (gmv * overall_rto_gmv_percentage) - (gmv * overall_rvp_gmv_percentage)) as final_sc_losses_excl_expiry,
    sub2.bank_burn * (gmv - (gmv * overall_rto_gmv_percentage) - (gmv * overall_rvp_gmv_percentage)) as final_bank_burn,
    sub2.others_royalty_etc * (gmv - (gmv * overall_rto_gmv_percentage) - (gmv * overall_rvp_gmv_percentage)) as final_others_royalty_etc,
    sub2.expiry * (gmv - (gmv * overall_rto_gmv_percentage) - (gmv * overall_rvp_gmv_percentage)) as final_expiry,
    sub2.other_inventory_provisions * (gmv - (gmv * overall_rto_gmv_percentage) - (gmv * overall_rvp_gmv_percentage)) as final_other_inventory_provisions,
    --sub2.cs * (gmv - (gmv*overall_rto_gmv_percentage)-(gmv*overall_rvp_gmv_percentage)) as final_cs,
    5.05 * (units - (units * overall_rto_units_percentage) - (units * overall_rvp_units_percentage)) as final_cs,
    sub2.pg_charges * (gmv - (gmv * overall_rto_gmv_percentage) - (gmv * overall_rvp_gmv_percentage)) as final_pg_charges,
    sub2.catalog * (gmv - (gmv * overall_rto_gmv_percentage) - (gmv * overall_rvp_gmv_percentage)) as final_catalog,
    sub2.perf_marketing * (gmv - (gmv * overall_rto_gmv_percentage) - (gmv * overall_rvp_gmv_percentage)) as final_perf_marketing,
    sub2.cat_marketing * (gmv - (gmv * overall_rto_gmv_percentage) - (gmv * overall_rvp_gmv_percentage)) as final_cat_marketing,
    sub2.alite * (gmv - (gmv * overall_rto_gmv_percentage) - (gmv * overall_rvp_gmv_percentage)) as final_alite,
    sub2.other_pm_to_cm * (gmv - (gmv * overall_rto_gmv_percentage) - (gmv * overall_rvp_gmv_percentage)) as final_other_pm_to_cm,

    --ads_formula
    CASE
        -- First condition for categories other than 'autoaccessorys' and 'toysandss'
        WHEN LOWER(analytic_super_category) NOT IN ('autoaccessorys', 'toysandss') and adsxfsn__fsn is not null
        THEN
            (CASE
                WHEN adsxfsn__absolute_or_percentage = 'GMV %' THEN adsxfsn__value * gmv
                WHEN adsxfsn__absolute_or_percentage = 'Net MRP %' THEN adsxfsn__value * ((mrp / units) * (units * (1 - overall_rto_units_percentage - overall_rvp_units_percentage)))
                WHEN adsxfsn__absolute_or_percentage = 'Net Units' THEN adsxfsn__value * (units - (units * overall_rto_units_percentage) - (units * overall_rvp_units_percentage))
                WHEN adsxfsn__absolute_or_percentage = 'Gross MRP %' THEN adsxfsn__value * mrp
                WHEN adsxfsn__absolute_or_percentage = 'NMV %' THEN adsxfsn__value * (gmv - (gmv * overall_rto_gmv_percentage) - (gmv * overall_rvp_gmv_percentage))
                WHEN adsxfsn__fsn IS NOT NULL AND adsxfsn__absolute_or_percentage IS NULL AND adsxfsn__value > 1 THEN adsxfsn__value * (units - (units * overall_rto_units_percentage) - (units * overall_rvp_units_percentage))
                WHEN adsxfsn__fsn IS NOT NULL AND adsxfsn__absolute_or_percentage IS NULL AND adsxfsn__value < 1 THEN adsxfsn__value * (gmv - (gmv * overall_rto_gmv_percentage) - (gmv * overall_rvp_gmv_percentage))
                ELSE NULL
            END)
        WHEN LOWER(analytic_super_category) NOT IN ('autoaccessorys', 'toysandss') and adsxfsn1__fsn is null
        THEN
            (CASE
                WHEN adsxfsn1__absolute_or_percentage = 'GMV %' THEN adsxfsn1__value * gmv
                WHEN adsxfsn1__absolute_or_percentage = 'Net MRP %' THEN adsxfsn1__value * ((mrp / units) * (units * (1 - overall_rto_units_percentage - overall_rvp_units_percentage)))
                WHEN adsxfsn1__absolute_or_percentage = 'Net Units' THEN adsxfsn1__value * (units - (units * overall_rto_units_percentage) - (units * overall_rvp_units_percentage))
                WHEN adsxfsn1__absolute_or_percentage = 'Gross MRP %' THEN adsxfsn1__value * mrp
                WHEN adsxfsn1__absolute_or_percentage = 'NMV %' THEN adsxfsn1__value * (gmv - (gmv * overall_rto_gmv_percentage) - (gmv * overall_rvp_gmv_percentage))
                WHEN adsxfsn1__fsn IS NOT NULL AND adsxfsn1__absolute_or_percentage IS NULL AND adsxfsn1__value > 1 THEN adsxfsn1__value * (units - (units * overall_rto_units_percentage) - (units * overall_rvp_units_percentage))
                WHEN adsxfsn1__fsn IS NOT NULL AND adsxfsn1__absolute_or_percentage IS NULL AND adsxfsn1__value < 1 THEN adsxfsn1__value * (gmv - (gmv * overall_rto_gmv_percentage) - (gmv * overall_rvp_gmv_percentage))
                ELSE NULL
            END)

        -- Second condition for the 'toysandss' category
        WHEN LOWER(analytic_super_category) IN ('toysandss')
        THEN
            CASE
                WHEN sum((gmv - (gmv * overall_rto_gmv_percentage) - (gmv * overall_rvp_gmv_percentage))) over (partition by analytic_super_category, brand) = 0 THEN 0
                ELSE ((gmv - (gmv * overall_rto_gmv_percentage) - (gmv * overall_rvp_gmv_percentage))) / (sum((gmv - (gmv * overall_rto_gmv_percentage) - (gmv * overall_rvp_gmv_percentage))) over (partition by analytic_super_category, brand)) * adsxtoyssxbrand__total_ads_amount * adsxtoyssxdayxper__day_wise_ads_percentage
            END

        -- Third condition for the 'autoaccessorys' category
        WHEN LOWER(analytic_super_category) IN ('autoaccessorys') THEN 0.1019 * (gmv - (gmv * overall_rto_gmv_percentage) - (gmv * overall_rvp_gmV_percentage))
        ELSE NULL -- Handles any other categories not covered
    END AS ads


FROM
    (
        SELECT
            sales1.*,
            --CN x FSN
            cnxfsn.formula as cnxfsn_formula,
            --IMXFSN
            imxfsn.type as imxfsn_type,
            --CN x FSN
            cnxfsn.value as cnxfsn_value,
            --COGSXFSN
            cogsxfsn.cost_per_unit as cogsxfsn__cost_per_unit,
            --IMXFSN
            imxfsn.im_in_percentage as imxfsn__im_in_percentage,
            --IMXSC
            imxsc.im_in_percentage as imxsc__im_in_percentage,
            --RTO_RVP_FSN
            rto_rvp_fsn.rto_percentage_gmv as rto_rvp_fsn__rto_percentage_gmv,
            rto_rvp_fsn.rto_percentage_units as rto_rvp_fsn__rto_percentage_units,
            rto_rvp_fsn.rvp_percentage_value as rto_rvp_fsn__rvp_percentage_value,
            rto_rvp_fsn.rvp_percentage_units as rto_rvp_fsn__rvp_percentage_units,
            --RTO_RVP_SCXVerticalBrand
            rto_rvp_scxverticalbrand.rto_percentage_gmv as rto_rvp_scxverticalbrand__rto_percentage_gmv,
            rto_rvp_scxverticalbrand.rto_percentage_units as rto_rvp_scxverticalbrand__rto_percentage_units,
            rto_rvp_scxverticalbrand.rvp_percentage_value as rto_rvp_scxverticalbrand__rvp_percentage_value,
            rto_rvp_scxverticalbrand.rvp_percentage_units as rto_rvp_scxverticalbrand__rvp_percentage_units,
            --RTO_RVP_SCXVertical
            rto_rvp_scxvertical.rto_percentage_value as rto_rvp_scxvertical__rto_percentage_value,
            rto_rvp_scxvertical.rto_percentage_units as rto_rvp_scxvertical__rto_percentage_units,
            rto_rvp_scxvertical.rvp_percentage_value as rto_rvp_scxvertical__rvp_percentage_value,
            rto_rvp_scxvertical.rvp_percentage_units as rto_rvp_scxvertical__rvp_percentage_units,
            --RTO_RVP_SC
            rto_rvp_sc.rto_percentage_value as rto_rvp_sc__rto_percentage_value,
            rto_rvp_sc.rto_percentage_units as rto_rvp_sc__rto_percentage_units,
            rto_rvp_sc.rvp_percentage_value as rto_rvp_sc__rvp_percentage_value,
            rto_rvp_sc.rvp_percentage_units as rto_rvp_sc__rvp_percentage_units,
            --Tax_SC X Vertical
            tax_scxvertical.gst_percentage as tax_scxvertical__gst_percentage,
            --Tax_FSN
            tax_fsn.gst_percentage as tax_fsn__gst_percentage,
            --Rto_rvp_logic
            COALESCE(rto_rvp_fsn.rto_percentage_gmv, rto_rvp_scxverticalbrand.rto_percentage_gmv, rto_rvp_scxvertical.rto_percentage_value, rto_rvp_sc.rto_percentage_value) as overall_rto_gmv_percentage,
            COALESCE(rto_rvp_fsn.rto_percentage_units, rto_rvp_scxverticalbrand.rto_percentage_units, rto_rvp_scxvertical.rto_percentage_units, rto_rvp_sc.rto_percentage_units) as overall_rto_units_percentage,
            COALESCE(rto_rvp_fsn.rvp_percentage_value, rto_rvp_scxverticalbrand.rvp_percentage_value, rto_rvp_scxvertical.rvp_percentage_value, rto_rvp_sc.rvp_percentage_value) as overall_rvp_gmv_percentage,
            COALESCE(rto_rvp_fsn.rvp_percentage_units, rto_rvp_scxverticalbrand.rvp_percentage_units, rto_rvp_scxvertical.rvp_percentage_units, rto_rvp_sc.rvp_percentage_units) as overall_rvp_units_percentage,
            --Tax_logic
            COALESCE(tax_scxvertical.gst_percentage, tax_fsn.gst_percentage, 0.18) as overall_tax_percentage,
            --Cogs and Im logic
            coalesce(imxfsn.im_in_percentage, imxsc.im_in_percentage) as overall_cogs_im_percentage,
            --Bl_SC
            blxsc.freight as freight,
            blxsc.sc_losses_excl_expiry as sc_losses_excl_expiry,
            blxsc.bank_burn as bank_burn,
            blxsc.others_royalty_etc as others_royalty_etc,
            blxsc.expiry as expiry,
            blxsc.other_inventory_provisions as other_inventory_provisions,
            blxsc.cs as cs,
            blxsc.pg_charges as pg_charges,
            blxsc.catalog as catalog,
            blxsc.perf_marketing as perf_marketing,
            blxsc.cat_marketing as cat_marketing,
            blxsc.alite as alite,
            blxsc.other_pm_to_cm as other_pm_to_cm,
            --SCmxscxvertical
            scmxscxvertical.final_cpu as scmxscxvertical__final_cpu,
            --SCmxscxfsn
            scmxscxfsn.final_cpu as scmxscxfsn__final_cpu,
            --SCmxsc
            scmxsc.final_cpu as scmxsc__final_cpu,
            --SCM logic
            coalesce(scmxscxvertical.final_cpu, scmxscxfsn.final_cpu, scmxsc.final_cpu) as overall_final_cpu,
            --Ads
            adsxfsn.absolute_or_percentage as adsxfsn__absolute_or_percentage,
            adsxfsn.value as adsxfsn__value,
            adsxfsn.fsn as adsxfsn__fsn,
            --ads_toyssandss
            adsxtoyssxbrand.total_ads_amount as adsxtoyssxbrand__total_ads_amount,
            adsxtoyssxdayxper.day_wise_ads_percentage as adsxtoyssxdayxper__day_wise_ads_percentage,
            adsxfsn1.absolute_or_percentage as adsxfsn1__absolute_or_percentage,
            adsxfsn1.value as adsxfsn1__value,
            adsxfsn1.fsn as adsxfsn1__fsn
        FROM
            (
                SELECT
                    sales.marketplace_id as marketplace_id,
                    prod_dim.analytic_business_unit as analytic_business_unit,
                    CAST(FORMAT_DATETIME('%Y%m%d', approved_date_time) as int64) as order_date_key,
                    prod_dim.analytic_super_category as analytic_super_category,
                    prod_dim.analytic_category as analytic_category,
                    prod_dim.analytic_sub_category as analytic_sub_category,
                    sales.product_id as product_id,
                    prod_dim.analytic_vertical as analytic_vertical,
                    prod_dim.brand as brand,
                    (CASE when sales.is_alpha_seller = TRUE then 'Alpha' else 'NON_Alpha' end) as Alpha_Flag,
                    sales.service_profile as FBF_Flag,
                    sum(listing_price) as listing_price,
                    sum(sales.gmv) AS gmv,
                    sum(sales.units) AS units,
                    sum(COALESCE(CAST(regexp_extract(construct_fee_adjustments, '"amount":([0-9.]+)[^}]*?"referenceId":"iks:001"', 1) AS numeric), 0)) as GTA_Fee,
                    sum(COALESCE(CAST(regexp_extract(construct_fee_adjustments, '"amount":([0-9.]+)[^}]*?"referenceId":"pf:001"', 1) AS numeric), 0)) as PF_Fee,
                    sum(COALESCE(CAST(regexp_extract(construct_fee_adjustments, '"amount":([0-9.]+)[^}]*?"referenceId":"cod:001"', 1) AS numeric), 0)) as COD_Fee,
                    sum(mrp) as mrp,
                    sum(listing_price_coins) as listing_price_coins,
                    sum(listing_price_coins_base_currency) as listing_price_coins_base_currency,
                    sum(construct_fee_value) as construct_fee_value
                FROM
                    bigfoot_external_neo.cp_bi_prod_sales__forward_unit_history_fact sales
                LEFT JOIN
                    bigfoot_external_neo.sp_product__product_categorization_hive_dim prod_dim
                    ON sales.product_id_key = prod_dim.product_categorization_hive_dim_key
                WHERE
                    lower(sales.status) in ('in_progress', 'undelivered', 'completed', 'delivered', 'approved', 'shipped', 'ready_to_ship', 'returned', 'return_requested', 'activated')
                    AND sales.type !='service'
                    AND sales.replacement_for_unit IS NULL
                    AND sales.exchange_for_unit IS NULL
                    AND sales.is_freebie = FALSE
                    AND sales.marketplace_id IN ('FLIPKART')
                    AND prod_dim.analytic_business_unit IN ('BGM')
                    AND CAST(FORMAT_DATETIME('%Y%m%d', approved_date_time) as int64) between 20250801 and 20250831
                    AND order_date_key >= 20250101
                    AND sales.is_alpha_seller = TRUE
                    AND sales.is_shopsy_order = FALSE
                GROUP BY
                    prod_dim.analytic_business_unit,
                    CAST(FORMAT_DATETIME('%Y%m%d', approved_date_time) as int64),
                    sales.product_id,
                    prod_dim.analytic_super_category,
                    prod_dim.analytic_category,
                    prod_dim.analytic_sub_category,
                    prod_dim.analytic_vertical,
                    prod_dim.brand,
                    sales.marketplace_id,
                    sales.is_shopsy_order,
                    (CASE when sales.is_alpha_seller = TRUE then 'Alpha' else 'NON_Alpha' end),
                    sales.service_profile
            ) as sales1
        --CN x FSN
        LEFT JOIN fdp_uploads.ds_fkint_analytics_cdo_pnl_inputs_fsn_x_day_level_cn_1_0 as cnxfsn
            ON lower(cnxfsn.analytic_super_category) = lower(sales1.analytic_super_category)
            AND cnxfsn.fsn = sales1.product_id
            --lower(cnxfsn.brand)=lower(sales1.brand) and
            AND cnxfsn.date = sales1.order_date_key
        --COGSXFSN
        LEFT JOIN fdp_uploads.ds_fkint_analytics_cdo_pnl_inputs_fsn_x_month_level_cogs_2_0 as cogsxfsn
            ON lower(cogsxfsn.analytic_super_category) = lower(sales1.analytic_super_category)
            AND cogsxfsn.fsn = sales1.product_id
            AND cast(cogsxfsn.yearmo as string) = substring(cast(sales1.order_date_key as string), 0, 6)
        --IMXFSN
        LEFT JOIN fdp_uploads.ds_fkint_analytics_cdo_pnl_inputs_fsn_x_brand_month_level_im_2_0 as imxfsn
            ON cast(imxfsn.yearmo as string) = substring(cast(sales1.order_date_key as string), 0, 6)
            AND lower(imxfsn.analytic_super_category) = lower(sales1.analytic_super_category)
            AND imxfsn.fsn = sales1.product_id
            --lower(imxfsn.brand) = lower(sales1.brand)
        --IMXSC
        LEFT JOIN fdp_uploads.ds_fkint_analytics_cdo_pnl_inputs_sc_x_month_level_im_1_0 as imxsc
            ON cast(imxsc.yearmo as string) = substring(cast(sales1.order_date_key as string), 0, 6)
            AND lower(imxsc.analytic_super_category) = lower(sales1.analytic_super_category)
        --RTO_RVP_FSN
        LEFT JOIN fdp_uploads.ds_fkint_analytics_cdo_pnl_inputs_fsn_x_month_level_rto_rvp_2_0 as rto_rvp_fsn
            ON rto_rvp_fsn.fsn = sales1.product_id
            AND lower(rto_rvp_fsn.analytic_super_category) = lower(sales1.analytic_super_category)
            AND cast(rto_rvp_fsn.yearmo as string) = substring(cast(sales1.order_date_key as string), 0, 6)
            AND (rto_rvp_fsn.rto_percentage_units > 0 OR rto_rvp_fsn.rvp_percentage_units > 0)
            AND (rto_rvp_fsn.rto_percentage_gmv > 0 or rto_rvp_fsn.rvp_percentage_value > 0)
        --RTO_RVP_SCXVerticalBrand
        LEFT JOIN fdp_uploads.ds_fkint_analytics_cdo_pnl_inputs_sc_x_verticalbrand_x_month_level_rto_rvp_1_0 as rto_rvp_scxverticalbrand
            ON cast(rto_rvp_scxverticalbrand.yearmo as string) = substring(cast(sales1.order_date_key as string), 0, 6)
            AND lower(rto_rvp_scxverticalbrand.analytic_super_category) = lower(sales1.analytic_super_category)
            AND lower(rto_rvp_scxverticalbrand.analytic_verticalxbrand) = lower(CONCAT(sales1.analytic_vertical, sales1.brand))
            AND (rto_rvp_scxverticalbrand.rto_percentage_units > 0 or rto_rvp_scxverticalbrand.rvp_percentage_units > 0)
            AND (rto_rvp_scxverticalbrand.rto_percentage_gmv > 0 or rto_rvp_scxverticalbrand.rvp_percentage_value > 0)
        --RTO_RVP_SCXVertical
        LEFT JOIN fdp_uploads.ds_fkint_analytics_cdo_pnl_inputs_sc_x_vertical_x_month_level_rto_rvp_1_0 as rto_rvp_scxvertical
            ON cast(rto_rvp_scxvertical.yearmo as string) = substring(cast(sales1.order_date_key as string), 0, 6)
            AND lower(rto_rvp_scxvertical.analytic_super_category) = lower(sales1.analytic_super_category)
            AND lower(rto_rvp_scxvertical.analytic_vertical) = lower(sales1.analytic_vertical)
            AND (rto_rvp_scxvertical.rto_percentage_units > 0 or rto_rvp_scxvertical.rvp_percentage_units > 0)
            AND (rto_rvp_scxvertical.rto_percentage_value > 0 or rto_rvp_scxvertical.rvp_percentage_value > 0)
        --RTO_RVP_SC
        LEFT JOIN fdp_uploads.ds_fkint_analytics_cdo_pnl_inputs_sc_x_month_level_rto_rvp_1_0 as rto_rvp_sc
            ON cast(rto_rvp_sc.yearmo as string) = substring(cast(sales1.order_date_key as string), 0, 6)
            AND lower(rto_rvp_sc.analytic_super_category) = lower(sales1.analytic_super_category)
            AND (rto_rvp_sc.rto_percentage_units > 0 or rto_rvp_sc.rvp_percentage_units > 0)
            AND (rto_rvp_sc.rto_percentage_value > 0 or rto_rvp_sc.rvp_percentage_value > 0)
        --Tax_SC X Vertical
        LEFT JOIN fdp_uploads.ds_fkint_analytics_cdo_pnl_inputs_sc_x_month_level_tax_1_0 as tax_scxvertical
            ON cast(tax_scxvertical.yearmo as string) = substring(cast(sales1.order_date_key as string), 0, 6)
            AND lower(tax_scxvertical.analytic_super_category) = lower(sales1.analytic_super_category)
            AND lower(tax_scxvertical.analytic_vertical) = lower(sales1.analytic_vertical)
        --Tax_FSN
        LEFT JOIN fdp_uploads.ds_fkint_analytics_cdo_pnl_inputs_fsn_x_month_level_tax_1_0 as tax_fsn
            ON cast(tax_fsn.yearmo as string) = substring(cast(sales1.order_date_key as string), 0, 6)
            AND tax_fsn.fsn = sales1.product_id
        --Bl_SC
        LEFT JOIN fdp_uploads.ds_fkint_analytics_cdo_pnl_inputs_sc_x_month_level_bl_1_0 as blxsc
            ON cast(blxsc.yearmo as string) = substring(cast(sales1.order_date_key as string), 0, 6)
            AND lower(blxsc.analytic_super_category) = lower(sales1.analytic_super_category)
        --SCmxscxvertical
        LEFT JOIN fdp_uploads.ds_fkint_analytics_cdo_pnl_inputs_sc_x_vertical_level_month_scm_2_0 as scmxscxvertical
            ON cast(scmxscxvertical.yearmo as string) = substring(cast(sales1.order_date_key as string), 0, 6)
            AND lower(scmxscxvertical.analytic_super_category) = lower(sales1.analytic_super_category)
            AND lower(scmxscxvertical.analytic_vertical) = lower(sales1.analytic_vertical)
        --SCmxscxfsn
        LEFT JOIN fdp_uploads.ds_fkint_analytics_cdo_pnl_inputs_sc_x_fsn_level_month_scm_1_0 as scmxscxfsn
            ON cast(scmxscxfsn.yearmo as string) = substring(cast(sales1.order_date_key as string), 0, 6)
            AND lower(scmxscxfsn.analytic_super_category) = lower(sales1.analytic_super_category)
            AND scmxscxfsn.fsn = sales1.product_id
        --SCmxsc
        LEFT JOIN fdp_uploads.ds_fkint_analytics_cdo_pnl_inputs_sc_level_month_scm_1_0 as scmxsc
            ON cast(scmxsc.yearmo as string) = substring(cast(sales1.order_date_key as string), 0, 6)
            AND lower(scmxsc.analytic_super_category) = lower(sales1.analytic_super_category)
        --adsxfsn
        LEFT JOIN fdp_uploads.ds_fkint_analytics_cdo_pnl_inputs_sc_x_fsn_level_month_ads_1_0 as adsxfsn
            ON adsxfsn.date = sales1.order_date_key
            AND lower(adsxfsn.analytic_super_category) = lower(sales1.analytic_super_category)
            AND adsxfsn.fsn = sales1.product_id
            --lower(adsxfsn.brand) = lower(sales1.brand) and
            AND adsxfsn.fsn is not null
     
        LEFT JOIN fdp_uploads.ds_fkint_analytics_cdo_pnl_inputs_sc_x_fsn_level_month_ads_1_0 as adsxfsn1
            ON adsxfsn1.date = sales1.order_date_key
            AND lower(adsxfsn1.analytic_super_category) = lower(sales1.analytic_super_category)
            AND lower(adsxfsn1.brand) = lower(sales1.brand)
            AND adsxfsn1.fsn is null

        LEFT JOIN fdp_uploads.ds_fkint_analytics_cdo_pnl_inputs_toysandss_x__brand_level_month_ads_3_0 as adsxtoyssxbrand
        --total_ads_amount
            ON cast(adsxtoyssxbrand.yearmo as string) = substring(cast(sales1.order_date_key as string), 0, 6)
            AND lower(adsxtoyssxbrand.analytic_super_category) = lower(sales1.analytic_super_category)
            AND lower(adsxtoyssxbrand.brand) = lower(sales1.brand)
        --adsxtoyndssxbrandxdaywise_percentage
        LEFT JOIN fdp_uploads.ds_fkint_analytics_cdo_pnl_inputs_toysandss_x_day_wise_ads_percentage_level_month_ads_1_0 as adsxtoyssxdayxper
            ON adsxtoyssxdayxper.date = sales1.order_date_key
    ) as sub2