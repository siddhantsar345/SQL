SELECT
comp.date_key as order_date_key,
comp.analytic_business_unit as analytic_business_unit,
comp.analytic_super_category as analytic_super_category,
CASE WHEN pareto.analytic_vertical IS NOT NULL THEN comp.analytic_vertical ELSE 'Non Pareto Vertical' END AS vertical,
mpp,
sum(comp.m_dw) as m_dw,
sum(comp.cdw) as cdw,
sum(comp.cdw_fee) as cdw_fee,
sum(comp.dw) as dw,
sum(comp.fk_comp_display) as fk_comp_display,
sum(comp.ms_comp_display) as ms_comp_display,
sum(comp.fk_comp_display_fee) as fk_comp_display_fee,
sum(comp.ms_comp_display_fee) as ms_comp_display_fee
      
FROM bigfoot_external_neo.cp_santa__meesho_pi_2__sc_level_fact AS comp

LEFT JOIN (
    SELECT analytic_super_category, analytic_vertical
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
) pareto

ON comp.analytic_super_category = pareto.analytic_super_category
    AND comp.analytic_vertical = pareto.analytic_vertical

WHERE lower(comp.analytic_business_unit) in ('bgm','home','lifestyle','furniture')
    AND CAST(date_key AS BIGINT) between 20240801 and 20241231

GROUP BY 
comp.date_key,
comp.analytic_business_unit,
comp.analytic_super_category,
vertical,
mpp