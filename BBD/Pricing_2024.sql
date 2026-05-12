SELECT
  *
FROM
  (
    SELECT
      order_date_key,
      analytic_business_unit,
      analytic_super_category,
      is_alpha_seller,
      SUM(input_bau_weighted_asp) AS input_bau_weighted_asp,
      SUM(input_fes_weighted_asp) AS input_fes_weighted_asp,
      SUM(output_bau_weighted_asp) AS output_bau_weighted_asp,
      SUM(output_fes_weighted_asp) AS output_fes_weighted_asp
    FROM
      (
        SELECT
          bau.analytic_super_category AS analytic_super_category,
          bau.analytic_business_unit,
          bau.product_id AS product_id,
          bau.listing_id AS listing_id,
          bau.is_alpha_seller AS is_alpha_seller,
          fes.order_date_key AS order_date_key,
          (bau.gmv / bau.units) * bau.units AS input_bau_weighted_asp,
          (fes.gmv / fes.units) * bau.units AS input_fes_weighted_asp,
          (bau.gmv / bau.units) * fes.units AS output_bau_weighted_asp,
          (fes.gmv / fes.units) * fes.units AS output_fes_weighted_asp
        FROM
          (
            SELECT
              sales.analytic_super_category,
              analytic_business_unit,
              sales.product_id,
              sales.listing_id,
              CASE
                WHEN sales.is_alpha_seller = TRUE THEN 'Diamond'
                ELSE 'Rest of MP'
              END AS is_alpha_seller,
              SUM(units) / 62 AS units,
              SUM(gmv) / 62 AS gmv,
              SUM(listing_price) AS lp
            FROM
              bigfoot_external_neo.cp_bi_prod_sales__forward_unit_history_fact sales
            WHERE
              LOWER(sales.status) IN (
                'in_progress',
                'undelivered',
                'completed',
                'delivered',
                'approved',
                'shipped',
                'ready_to_ship',
                'returned',
                'return_requested',
                'activated'
              )
              AND sales.type != 'service'
              AND sales.replacement_for_unit IS NULL
              AND sales.exchange_for_unit IS NULL
              AND sales.is_freebie = FALSE
              AND sales.marketplace_id IN ('FLIPKART')
              AND sales.is_shopsy_order = FALSE
              AND sales.analytic_business_unit IN ('BGM', 'Home', 'Furniture')
              AND order_date_key BETWEEN 20240701 AND 20240831
            GROUP BY
              sales.analytic_super_category,
              analytic_business_unit,
              sales.product_id,
              sales.listing_id,
              CASE
                WHEN sales.is_alpha_seller = TRUE THEN 'Diamond'
                ELSE 'Rest of MP'
              END
          ) bau
          INNER JOIN (
            SELECT
              sales.listing_id,
              sales.order_date_key,
              SUM(CASE WHEN LOWER(sales.status) IN (
                'in_progress',
                'undelivered',
                'completed',
                'delivered',
                'approved',
                'shipped',
                'ready_to_ship',
                'returned',
                'return_requested',
                'activated'
              ) THEN sales.units ELSE 0 END) AS units,
              SUM(CASE WHEN LOWER(sales.status) IN (
                'in_progress',
                'undelivered',
                'completed',
                'delivered',
                'approved',
                'shipped',
                'ready_to_ship',
                'returned',
                'return_requested',
                'activated'
              ) THEN sales.gmv ELSE 0 END) AS gmv,
              SUM(sales.listing_price) AS lp
            FROM
              bigfoot_external_neo.cp_bi_prod_sales__forward_unit_history_fact sales
            WHERE
              LOWER(sales.status) IN (
                'in_progress',
                'undelivered',
                'completed',
                'delivered',
                'approved',
                'shipped',
                'ready_to_ship',
                'returned',
                'return_requested',
                'activated'
              )
              AND sales.type != 'service'
              AND sales.is_shopsy_order = FALSE
              AND sales.marketplace_id IN ('FLIPKART')
              AND sales.analytic_business_unit IN ('BGM', 'Home', 'Furniture')
              AND order_date_key BETWEEN 20240901 AND 20241031
            GROUP BY
              sales.listing_id,
              sales.order_date_key
          ) fes ON bau.listing_id = fes.listing_id
      ) sub
    GROUP BY
      order_date_key,
      analytic_business_unit,
      analytic_super_category,
      is_alpha_seller
  ) AS final_output;