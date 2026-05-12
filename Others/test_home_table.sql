create table adhoc_ttl_90days.household_on_test_till_16th_sep2025_test as
SELECT account_id FROM adhoc_ttl_90days.household_on_base_till_16th_sep2025_base
WHERE rand() <= 0.9