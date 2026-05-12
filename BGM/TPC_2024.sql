SELECT 
        EXTRACT(YEAR from DATE(month_begin_date)) as year1,
        EXTRACT(MONTH from DATE(month_begin_date)) as month1,
        month_begin_date,
        COUNT(DISTINCT account_id) as total_customers,
        count(distinct case when fk_orders = 0 or fk_orders is null then account_id end) as tpc_0_customers,
        count(distinct case when fk_orders <=3 and fk_orders >0 then account_id end) as tpc_1_3_customers,
        count(distinct case when fk_orders <=7 and fk_orders >3 then account_id end) as tpc_4_7_customers,
        count(distinct case when fk_orders <=12 and fk_orders >7 then account_id end) as tpc_8_12_customers,
        count(distinct case when fk_orders <=29 and fk_orders >12 then account_id end) as tpc_13_29_customers,
        count(distinct case when fk_orders >=30 then account_id end) as tpc_30_plus_customers,
        count(distinct case when bgm_orders = 0 or bgm_orders is null then account_id end) as bgm_tpc_0_customers,
        count(distinct case when bgm_orders =1 then account_id end) as bgm_tpc_1_customers,
        count(distinct case when bgm_orders <=3 and bgm_orders >1 then account_id end) as bgm_tpc_2_3_customers,
        count(distinct case when bgm_orders <=5 and bgm_orders >3 then account_id end) as bgm_tpc_4_5_customers,
        count(distinct case when bgm_orders >=6 then account_id end) as bgm_tpc_6_plus_customers

FROM
        (
        SELECT 
           base.month_begin_date,
           base.account_id,
           COUNT(DISTINCT fk.order_external_id) as fk_orders,
           COUNT(DISTINCT CASE WHEN fk.analytic_business_unit = 'BGM' then order_external_id end) as bgm_orders

        FROM
                (
                SELECT
                        dates.month_begin_date,
                        bgm.account_id

                FROM 
                   (
                   SELECT 
                                   month_begin_date
                   FROM bigfoot_external_neo.scp_oms__date_dim_fact
                   WHERE date_dim_key  >= 20240101 and date_dim_key <= 20240727
                   GROUP BY 
                                   month_begin_date
                   ) dates

                LEFT JOIN
                        (
                        SELECT 
                                account_id,
                                dates.month_begin_date

                        FROM bigfoot_external_neo.cp_bi_prod_sales__forward_unit_history_fact sales

                        LEFT JOIN bigfoot_external_neo.scp_oms__date_dim_fact dates
                                ON sales.order_date_key = dates.date_dim_key
                        
                        WHERE lower(status) in ('in_progress','undelivered','completed','delivered','approved','shipped','ready_to_ship','returned', 'return_requested','activated')
                        AND type IN ('physical')
                        AND replacement_for_unit IS NULL
                        AND exchange_for_unit IS NULL
                        AND is_freebie =FALSE
                        AND marketplace_id IN ('FLIPKART')
                        AND lower(analytic_business_unit) in ('bgm')
                        AND is_shopsy_order =FALSE
                        AND order_date_key BETWEEN 20240401 AND 20240427

                        GROUP BY
                                account_id,
                                dates.month_begin_date
                        ) bgm
                        on bgm.month_begin_date = dates.month_begin_date

                GROUP BY 
                        dates.month_begin_date,
                        bgm.account_id
                ) base

        LEFT JOIN
            (
                SELECT 
                        account_id,
                        order_date_time,
                        order_external_id,
                        analytic_business_unit

                FROM bigfoot_external_neo.cp_bi_prod_sales__forward_unit_history_fact 
                
                WHERE lower(status) in ('in_progress','undelivered','completed','delivered','approved','shipped','ready_to_ship','returned', 'return_requested','activated')
                AND type IN ('physical')
                AND replacement_for_unit IS NULL
                AND exchange_for_unit IS NULL
                AND is_freebie =FALSE
                AND marketplace_id IN ('FLIPKART')
                AND is_shopsy_order =FALSE
                AND order_date_key >= 20230101

                GROUP BY
                        account_id,
                        order_date_time,
                        order_external_id,
                        analytic_business_unit
                ) fk
            on base.account_id = fk.account_id
                  and date(fk.order_date_time) between DATE_SUB(date(base.month_begin_date), INTERVAL 366 DAY) and DATE_SUB(date(base.month_begin_date), INTERVAL 1 DAY)

        GROUP BY
                base.month_begin_date,
                   base.account_id
        ) base2

GROUP BY
        EXTRACT(YEAR from DATE(month_begin_date)),
        EXTRACT(MONTH from DATE(month_begin_date)),
        month_begin_date