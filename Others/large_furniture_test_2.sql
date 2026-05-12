create table adhoc_ttl_90days.largefurniture_test_19th_September_2025 as
SELECT account_id FROM adhoc_ttl_90days.largefurniture_base_19th_September_2025
WHERE rand() <= 0.9