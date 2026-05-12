create table adhoc_ttl_90days.dgvheqg7znvvxuqe_17th_Sept_2025 as
select sales.account_id
FROM
    bigfoot_external_neo.cp_bi_prod_sales__forward_unit_live_hbase_snapshot_fact sales
WHERE
    lower(sales.unit_status) IN ('in_progress','undelivered','completed','delivered','approved','shipped','ready_to_ship','returned', 'return_requested','activated')
    AND sales.freebie_flag = FALSE
    AND UPPER(sales.is_shopsy_order) = 'FALSE'
    AND (sales.marketplace_id IN ('FLIPKART'))
    AND lower(sales.fsn)='dgvheqg7znvvxuqe'
GROUP BY sales.account_id