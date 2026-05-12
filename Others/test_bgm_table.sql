create table adhoc_ttl_90days.autoaccessorys_on_test_16th_Sept_2025 as
SELECT account_id FROM adhoc_ttl_90days.autoaccessorys_on_16th_Sept_2025_base
WHERE rand() <= 0.9