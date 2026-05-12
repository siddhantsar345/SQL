create table adhoc_ttl_90days.smallfurniture_test_19th_Sept_2025 as
SELECT account_id FROM adhoc_ttl_90days.smallfurniture_base_19th_Sept_2025
WHERE rand() <= 0.9