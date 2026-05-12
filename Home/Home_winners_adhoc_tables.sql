create table adhoc_ttl_90days.first_winner_1 as (
select distinct account_id
FROM fdp_uploads.ds_fkint_analytics_cdo_top_3_winners_1_0
    WHERE rank=1
)

create table adhoc_ttl_90days.second_winner_1 as (
select distinct account_id
FROM fdp_uploads.ds_fkint_analytics_cdo_top_3_winners_1_0
    WHERE rank=2
)

create table adhoc_ttl_90days.third_winner_1 as (
select distinct account_id
FROM fdp_uploads.ds_fkint_analytics_cdo_top_3_winners_1_0
    WHERE rank=3
)