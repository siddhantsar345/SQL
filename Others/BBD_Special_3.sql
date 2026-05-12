create table adhoc_ttl_90days.dgvheqg7tkarghdq_17th_Sept_2025 as
SELECT
    t1.account_id
FROM
    bigfoot_external_neo.cp_bi_prod_sales__forward_unit_live_hbase_snapshot_fact AS t1
WHERE
    LOWER(t1.unit_status) IN ('in_progress', 'undelivered', 'completed', 'delivered', 'approved', 'shipped', 'ready_to_ship', 'returned', 'return_requested', 'activated')
    AND t1.marketplace_id = 'FLIPKART'
    AND LOWER(t1.fsn) = 'dgvheqg7tkarghdq'
    AND t1.account_id NOT IN (
        SELECT
            t2.account_id
        FROM
            bigfoot_external_neo.cp_bi_prod_sales__forward_unit_live_hbase_snapshot_fact AS t2
        WHERE
            lower(t2.fsn) = 'dgvheqg7yzen8guh' and lower(t2.fsn) = 'dgvheqg7znvvxuqe'
    )
GROUP BY
    t1.account_id;