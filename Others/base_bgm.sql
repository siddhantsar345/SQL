SELECT
  DISTINCT sales.account_id
  
FROM bigfoot_external_neo.cp_bi_prod_sales__forward_unit_history_fact sales

LEFT JOIN  
fdp_uploads.ds_fkint_cp_santa_hyperlocal_vertical_bu_mapping_2_0 AS hl 
    ON sales.analytic_vertical = hl.analytic_vertical 
    
Left Join
(SELECT
DISTINCT sales.account_id
  
FROM bigfoot_external_neo.cp_bi_prod_sales__forward_unit_history_fact sales

LEFT JOIN  
fdp_uploads.ds_fkint_cp_santa_hyperlocal_vertical_bu_mapping_2_0 AS hl 
    ON sales.analytic_vertical = hl.analytic_vertical 
    
  WHERE LOWER(sales.status) IN ('in_progress', 'undelivered', 'completed', 'delivered', 'approved', 'shipped', 'ready_to_ship', 'returned', 'return_requested', 'activated')
        AND sales.type  = 'physical'
        AND sales.replacement_for_unit IS NULL
        AND sales.exchange_for_unit IS NULL
        AND sales.is_freebie = FALSE
        AND (sales.marketplace_id IN ('FLIPKART') OR (sales.marketplace_id = 'HYPERLOCAL' AND  hl.analytic_vertical IS NOT NULL))
  AND sales.order_date_key between 20240914 and 20250915 
  AND sales.is_shopsy_order = FALSE
  AND lower(sales.analytic_super_category) IN ('babycare')) as a 
  on a.account_id = sales.account_id
    
  WHERE LOWER(sales.status) IN ('in_progress', 'undelivered', 'completed', 'delivered', 'approved', 'shipped', 'ready_to_ship', 'returned', 'return_requested', 'activated')
        AND sales.type  = 'physical'
        AND sales.replacement_for_unit IS NULL
        AND sales.exchange_for_unit IS NULL
        AND sales.is_freebie = FALSE
        AND (sales.marketplace_id IN ('FLIPKART') OR (sales.marketplace_id = 'HYPERLOCAL' AND  hl.analytic_vertical IS NOT NULL))
  AND sales.order_date_key between 20250315 and 20250915
  AND sales.is_shopsy_order = FALSE
  AND lower(sales.analytic_vertical) IN ('cribtoyplaygym', 'poster', 'pillow', 'infantdungaree', 'infantdress', 'womennightdressnighty', 'birthdaycombo', 'mattressprotector', 'handjuicer', 'walnuts', 'womenethnicdress', 'clothdryerstand', 'kidcomboset', 'womenethnicgown', 'womendress', 'musicaltoy', 'infantcomboset', 'adultdiapers', 'mosquitonet', 'deskorganizers', 'infantethnicset', 'bedsheet', 'pillowcover', 'tablecover', 'balloondecoration', 'slipcover', 'dates', 'collapsiblewardrobe', 'almonds', 'walldecoration', 'artificialflower')
  AND a.account_id IS NULL