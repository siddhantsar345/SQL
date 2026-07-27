#!/usr/bin/env python
# coding: utf-8

# In[ ]:


from datetime import date
from datetime import datetime, timedelta
today=date.today()
day=today-timedelta(days=1)


# # For BU level (Query 1 - overall)

# In[ ]:


import requests
import json
from io import StringIO
import time
import pandas as pd
import jaydebeapi
import os
import subprocess
import pandas as pd
import numpy as np
import datetime
import calendar
import pygsheets
import re
from datetime import date
import jaydebeapi
import os
import subprocess
import numpy as np
import datetime
import calendar
import pygsheets
import re

# output = subprocess.check_output(['bash', '-c', 'echo $CLASSPATH:/usr/local/fdp-infra-hive/lib/*'])
# os.environ['CLASSPATH'] = '/usr/local/fdp-infra-hive/lib/*'

# url = ("jdbc:hive2://fkp-fdp-galaxy-sun-zkjn-0001.c.fkp-fdp-galaxy.internal:2181,fkp-fdp-galaxy-sun-zkjn-0002.c.fkp-fdp-galaxy.internal:2181,fkp-fdp-galaxy-sun-zkjn-0003.c.fkp-fdp-galaxy.internal:2181/default;transportMode=http;httpPath=cliservice;serviceDiscoveryMode=zooKeeper;zooKeeperNamespace=fkp-fdp-galaxy-hive3-hs2-agni;hive.client.read.socket.timeout=300?hive.metastore.client.socket.timeout=180;hive.server.tcp.keepalive=true;hive.server.read.socket.timeout=300")
 
# print('Established JDBC connection---------------------')

# conn = jaydebeapi.connect("org.apache.hive.jdbc.HiveDriver", url,{'user': "mohammed.usama", 'password': "Khalid@170757"})

# print('Connected to hive server-------------------------')

# cursor = conn.cursor()
# cursor.execute("ADD JAR /usr/share/fk-bigfoot-hivejsonserde/json-serde-1.3-SNAPSHOT-jar-with-dependencies.jar")
# cursor.execute("ADD JAR /usr/share/fk-bigfoot-dimlookup/dimlookup-hive-udf-1.0-SNAPSHOT-jar-with-dependencies.jar")
# cursor.execute("ADD JAR gs://fkpdp-mhosy-2nig-1a5d-systemlibs/libraries/hive/jars/hive-udfs-1.0-SNAPSHOT.jar")
# cursor.execute("CREATE TEMPORARY FUNCTION lookup as 'com.flipkart.bigfoot.dimlookup.udf.HiveLookupUDF'")
# cursor.execute("CREATE TEMPORARY FUNCTION arrToString as 'com.flipkart.fdp.CustomCaster'")
# cursor.execute("CREATE TEMPORARY FUNCTION lookupkey as 'com.flipkart.bigfoot.dimlookup.udf.HiveKeyGeneratorUDF'")
# cursor.execute("CREATE TEMPORARY FUNCTION lookup_date as 'com.flipkart.bigfoot.dimlookup.udf.DateLookupUDF'")
# cursor.execute("CREATE TEMPORARY FUNCTION lookup_time as 'com.flipkart.bigfoot.dimlookup.udf.TimeLookupUDF'")
# cursor.execute("CREATE TEMPORARY FUNCTION aggregate_filter as 'com.flipkart.bigfoot.dimlookup.udf.AggregateConditionUDF'")
# cursor.execute("CREATE TEMPORARY FUNCTION aggregate as 'com.flipkart.bigfoot.dimlookup.udf.AggregateUDF'")
# cursor.execute("CREATE TEMPORARY FUNCTION ISOToSqlTs as 'com.flipkart.bigfoot.dimlookup.udf.DateISOToSqlUDF'")
# cursor.execute("CREATE TEMPORARY FUNCTION business_date_diff as 'com.flipkart.bigfoot.dimlookup.udf.BusinessDayDiffUDF'")

# cursor.execute("set mapreduce.input.fileinputformat.input.dir.recursive=true")

# print('connect')

X_Client_Id= 'analytics-cdo' ### Change as per your org-namespace
X_Client_Secret= '6cbdc3cd-a3f7-43e1-a2f9-1935f6317c44' ### Change as per your org-namespace
user_name='shubham.v.vc' ### Change as per your username

# Alpha Query you want to pull
query = """
select
substr(sales_fact.order_date_key,1,6) as months,
sales_fact.analytic_business_unit,
--TC
count(distinct(sales_fact.account_id)) as customers,  
--RC/NC
count(distinct(case when sales_fact.new_customer_flag = 1 then sales_fact.account_id end)) as nc,
count(distinct(case when sales_fact.new_customer_flag = 0 then sales_fact.account_id end)) as rc,
--Plus/Non-Plus
count(distinct(case when lower(sales_fact.user_lockin_state) ='active' then sales_fact.account_id end)) as Plus,
count(distinct(case when lower(sales_fact.user_lockin_state) !='active' then sales_fact.account_id end)) as Non_Plus,
--gender_tag
count(distinct(case when lower(new_demograph.gender) = 'male' then sales_fact.account_id end)) as MALE,
count(distinct(case when lower(new_demograph.gender) = 'female' then sales_fact.account_id end)) as FEMALE,
--marital_status
count(distinct(case when lower(new_demograph.is_married)= 'yes' THEN sales_fact.account_id end)) as MARRIED,
count(distinct(case when lower(new_demograph.is_married)= 'no' THEN sales_fact.account_id end)) as UNMARRIED,
--parental_status
count(distinct(case when lower(new_demograph.is_parent)= 'yes' THEN sales_fact.account_id end)) as PARENT,
count(distinct(case when lower(new_demograph.is_parent)= 'no' THEN sales_fact.account_id end)) as NOT_PARENT,
--student_status
count(distinct(case when lower(new_demograph.is_student)= 'yes' THEN sales_fact.account_id end)) as STUDENT,
count(distinct(case when lower(new_demograph.is_student)= 'no' THEN sales_fact.account_id end)) as NOT_STUDENT,
--age_flag
count(distinct(case WHEN new_demograph.min_age >= 0 and new_demograph.max_age < 15 THEN sales_fact.account_id end)) as age_0_15,
count(distinct(case WHEN new_demograph.min_age >= 15 and new_demograph.max_age < 25 THEN sales_fact.account_id end)) as age_15_25,
count(distinct(case WHEN new_demograph.min_age >= 25 and new_demograph.max_age < 35 THEN sales_fact.account_id end)) as age_25_35,
count(distinct(case WHEN new_demograph.min_age >= 35 and new_demograph.max_age < 45 THEN sales_fact.account_id end)) as age_35_45,
count(distinct(case WHEN new_demograph.min_age >= 45 and new_demograph.max_age <= 100 THEN sales_fact.account_id end)) as age_45_100,

--Customer_section
0 as Premium,
-- count(distinct(case when aff_seg.aff_segment = 'premium' then sales_fact.account_id end)) as Premium,
0 as Emerging_Premium,
-- count(distinct(case when aff_seg.aff_segment = 'emerging_premium' then sales_fact.account_id end)) as Emerging_Premium,
0 as Mass,
-- count(distinct(case when aff_seg.aff_segment = 'mass' then sales_fact.account_id end)) as Mass,
0 as Entry,
--count(distinct(case when aff_seg.aff_segment not in ('premium','emerging_premium','mass') then sales_fact.account_id end)) as Entry,

-- category_type
count(distinct(case when aff_cohort.affluence_score <= 0.25 then sales_fact.account_id end)) as Low_Aff,
count(distinct(case when aff_cohort.affluence_score between 0.25 and 0.75 then sales_fact.account_id end)) as Mid_Aff,
count(distinct(case when aff_cohort.affluence_score >= 0.75 then sales_fact.account_id end)) as High_Aff,
--cust_category
count(distinct(case WHEN cust_fact_nn.account_id is not null THEN sales_fact.account_id end)) as NN_cust,
count(distinct(case WHEN cust_fact_on.account_id is not null THEN sales_fact.account_id end)) as ON_cust,
count(distinct(sales_fact.account_id)) - count(distinct(case WHEN cust_fact_nn.account_id is not null THEN sales_fact.account_id end)) - count(distinct(case WHEN cust_fact_on.account_id is not null THEN sales_fact.account_id end)) as OO_cust,
--tpc_flag
count(distinct(case WHEN base.trans_count >=1 and base.trans_count<=3 THEN sales_fact.account_id end)) as low_tpc,
count(distinct(case WHEN base.trans_count >=4 and base.trans_count<=7 THEN sales_fact.account_id end)) as mid_tpc,
count(distinct(case WHEN base.trans_count >=8 and base.trans_count<=12 THEN sales_fact.account_id end)) as high_tpc,
count(distinct(case WHEN base.trans_count>12 THEN sales_fact.account_id end)) as very_high_tpc,

--MLE_CUSTOMER
sum(MLE_fact.mle_cust) as mle_cust
from
bigfoot_external_neo.cp_bi_prod_sales__forward_unit_history_fact as sales_fact

/*left join
bigfoot_external_neo.analytics_cdo__FK_Aff_Segment_fact as aff_seg
on sales_fact.account_id = aff_seg.account_id
*/

left join
bigfoot_external_neo.cp_uie__Affluence_Cohort_Score_fact as aff_cohort
on sales_fact.account_id = aff_cohort.account_id
left join
bigfoot_external_neo.cp_uie__account_demographics_insight_beta_fact new_demograph
on sales_fact.account_id = new_demograph.account_id
left join
( 
	select 
		b.analytic_business_unit,
		b.account_id
	from
		bigfoot_external_neo.analytics_cdo__customer_insight_hive_fact b 
	inner join  
		bigfoot_external_neo.cp_bi_prod_sales__forward_unit_history_fact a
	on 
		a.order_item_id =b.order_item_id
	where 
		lower(a.status) in ('in_progress','undelivered','completed','delivered','approved','shipped','ready_to_ship','returned', 'return_requested','activated')
		and a.type !='service'
		and lower(a.marketplace_id)= 'flipkart'
		and a.category_id !=21726
		and a.category_id !=21651
		and a.is_freebie =false
		and (a.replacement_for_unit is null or a.replacement_for_unit='not_replacement')
		and (a.exchange_for_unit is null or a.exchange_for_unit='not_exchange')
		and is_shopsy_order = FALSE
		and a.order_date_key  between lookup_date(date_sub(date_sub(current_date,1),dayofmonth(date_sub(current_date,1))-1)) and lookup_date(date_sub(current_date,2))
		and lower(a.analytic_business_unit) in ('bgm','electronics','furniture','home','large','lifestyle','mobile')
		and b.new_cust_flag = 1
		group by
		b.analytic_business_unit,
		b.account_id
) as cust_fact_nn
on sales_fact.account_id=cust_fact_nn.account_id 
and sales_fact.analytic_business_unit = cust_fact_nn.analytic_business_unit
left join
( 
	select 
		b.analytic_business_unit,
		b.account_id
	from
		bigfoot_external_neo.analytics_cdo__customer_insight_hive_fact b 
	inner join  
		bigfoot_external_neo.cp_bi_prod_sales__forward_unit_history_fact a
	on 
		a.order_item_id =b.order_item_id
	where 
		lower(a.status) in ('in_progress','undelivered','completed','delivered','approved','shipped','ready_to_ship','returned', 'return_requested','activated')
		and a.type !='service'
		and lower(a.marketplace_id)= 'flipkart'
		and a.category_id !=21726
		and a.category_id !=21651
		and a.is_freebie =false
		and (a.replacement_for_unit is null or a.replacement_for_unit='not_replacement')
		and (a.exchange_for_unit is null or a.exchange_for_unit='not_exchange')
		and is_shopsy_order = FALSE
		and a.order_date_key between lookup_date(date_sub(date_sub(current_date,1),dayofmonth(date_sub(current_date,1))-1)) and lookup_date(date_sub(current_date,2))
		and lower(a.analytic_business_unit) in ('bgm','electronics','furniture','home','large','lifestyle','mobile')
		and b.new_cust_flag = 0
		and b.new_to_bu = 1
		group by
		b.analytic_business_unit,
		b.account_id
) as cust_fact_on
on sales_fact.account_id=cust_fact_on.account_id 
and sales_fact.analytic_business_unit = cust_fact_on.analytic_business_unit
left join
(	
	select
	sa.account_id,
	sa.analytic_business_unit,
	count(distinct sa.order_external_id) as trans_count
	from
	bigfoot_external_neo.analytics_cdo__customer_insight_hive_fact sa
	where
	sa.approve_date_key between lookup_date(date_sub(date_sub(current_date,1),dayofmonth(date_sub(current_date,1))-1)) and lookup_date(date_sub(current_date,2))
	group by
	sa.account_id,
	sa.analytic_business_unit
) base
on sales_fact.account_id = base.account_id
left join
( 
	select
	a.months,
	a.account_id,
	count(distinct(a.account_id)) as mle_cust
	from
	(
		select
		substr(c.approve_date_key,1,6) as months,
		c.account_id
		from
		bigfoot_external_neo.analytics_cdo__customer_insight_hive_fact c
		where
	 	lower(c.analytic_business_unit) in ('mobile','large','electronics')
	 	and c.new_to_bu=1
	 	and c.approve_date_key between lookup_date(date_sub(date_sub(current_date,1),dayofmonth(date_sub(current_date,1))-1)) and lookup_date(date_sub(current_date,2))
		group by
	 	substr(c.approve_date_key,1,6),
	 	c.account_id
	) a
	left join
	(
		select
		substr(ca.approve_date_key,1,6) as months,
		ca.account_id
		from
		bigfoot_external_neo.analytics_cdo__customer_insight_hive_fact ca
		where
		lower(ca.analytic_business_unit) in ('mobile','large','electronics')
		and ca.new_to_bu=0
		and ca.approve_date_key between lookup_date(date_sub(date_sub(current_date,1),dayofmonth(date_sub(current_date,1))-1)) and lookup_date(date_sub(current_date,2))
		group by
		substr(ca.approve_date_key,1,6),
		ca.account_id
	) b
	on a.months = b.months and a.account_id = b.account_id
	where
	b.account_id is null
	group by
	a.months,
	a.account_id
) as MLE_fact
on MLE_fact.account_id = sales_fact.account_id
where
sales_fact.order_date_key between lookup_date(date_sub(date_sub(current_date,1),dayofmonth(date_sub(current_date,1))-1)) and lookup_date(date_sub(current_date,2))
and lower(sales_fact.analytic_business_unit) in ('bgm','electronics','furniture','home','large','lifestyle','mobile')
and lower(sales_fact.status) in ('in_progress','undelivered','completed','delivered','approved','shipped','ready_to_ship','returned', 'return_requested','activated')
and sales_fact.type !='service'
and sales_fact.category_id !=21726
and sales_fact.category_id !=21651
and sales_fact.replacement_for_unit is null
and sales_fact.exchange_for_unit is null
and sales_fact.is_freebie = false
and sales_fact.marketplace_id = 'FLIPKART'
and sales_fact.is_shopsy_order = false
group by
substr(sales_fact.order_date_key,1,6),
sales_fact.analytic_business_unit

"""

url = 'http://validator.fdp-qaas-validator-prod.fkcloud.in/query/queries'


headers ={'Accept': '*', 'Content-Type': 'application/x-www-form-urlencoded',
          'Host': 'validator.fdp-qaas-validator-prod.fkcloud.in',
          'X-Client-Id': X_Client_Id, 
          'X-Client-Secret': X_Client_Secret,
          'x-authenticated-user':user_name 
          }
data ={'query':query,'sourceName':'HIVE'}

r = requests.post(url, headers=headers, data = data)
print(r.content)

print('r is: ',r)
print('If you get <Response [200]> above, that implies the url request was successful ')
query_handle_byte_dtype = r.content
# using decode() + loads() to convert to dictionary
query_handle_dict_dtype = json.loads(query_handle_byte_dtype.decode('utf-8'))
query_handle = query_handle_dict_dtype['queryHandle']['handle']
print("http://fdp.fkinternal.com/query/result/"+query_handle)

url = '  http://validator.fdp-qaas-validator-prod.fkcloud.in/query/queries/'+query_handle+'/status'


headers ={'Accept': '*', 'Content-Type': 'application/x-www-form-urlencoded',
          'Host': 'validator.fdp-qaas-validator-prod.fkcloud.in',
          'X-Client-Id': X_Client_Id, 
          'X-Client-Secret': X_Client_Secret,
          'x-authenticated-user':user_name 
          }
data ={'query':query,'sourceName':'HIVE'}

status_req = requests.get(url, headers=headers)

json.loads(status_req.content.decode('utf-8'))['status']
  
a = 0

while (a != 1):
    b=''
    status_req = requests.get(url, headers=headers)
    b = json.loads(status_req.content.decode('utf-8'))['status']    
    if b == 'SUCCESSFUL':
        a = 1
    else: 
        a = 0
    print(a)
    print('code still running')
    time.sleep(30)
    
print(status_req)

url_data_pull = 'http://validator.fdp-qaas-validator-prod.fkcloud.in/query/queries/'+ query_handle +'/downloadresults'


headers_data_pull ={'Accept': '*', 'Content-Type': 'application/x-www-form-urlencoded',
                    'Host': 'validator.fdp-qaas-validator-prod.fkcloud.in',
                    'X-Client-Id': X_Client_Id, 
          'X-Client-Secret': X_Client_Secret,
          'x-authenticated-user':user_name 
                   }

r_data_pull = requests.get(url_data_pull, headers=headers_data_pull)

query_output = r_data_pull.content

s=query_output.decode('utf-8')


data = StringIO(s) 

cust_data=pd.read_csv(data)

# gc=pygsheets.authorize(service_file='ShivankAutomation-fd5dab44a774.json')
# sh=gc.open('Life_Style_Data')

# data=sh[2]





# In[ ]:


cust_data


# In[ ]:


gc=pygsheets.authorize(service_file='ShivankAutomation-fd5dab44a774.json')
sh=gc.open('Customer Insights Dashboard')
worksheet=sh.worksheets().copy()
sheet_name = [s.title for s in worksheet]
data=sh[sheet_name.index('BU_LEVEL')]
data.clear(start='A2', end='AI100000', fields="*")
data.set_dataframe(cust_data,(2,1),copy_head=False,copy_index=False)


# # For BU level (Query 2 - Geo_tags) 

# In[ ]:


import requests
import json
from io import StringIO
import time
import pandas as pd
import jaydebeapi
import os
import subprocess
import pandas as pd
import numpy as np
import datetime
import calendar
import pygsheets
import re
from datetime import date
import jaydebeapi
import os
import subprocess
import numpy as np
import datetime
import calendar
import pygsheets
import re

# output = subprocess.check_output(['bash', '-c', 'echo $CLASSPATH:/usr/local/fdp-infra-hive/lib/*'])
# os.environ['CLASSPATH'] = '/usr/local/fdp-infra-hive/lib/*'

# url = ("jdbc:hive2://fkp-fdp-galaxy-sun-zkjn-0001.c.fkp-fdp-galaxy.internal:2181,fkp-fdp-galaxy-sun-zkjn-0002.c.fkp-fdp-galaxy.internal:2181,fkp-fdp-galaxy-sun-zkjn-0003.c.fkp-fdp-galaxy.internal:2181/default;transportMode=http;httpPath=cliservice;serviceDiscoveryMode=zooKeeper;zooKeeperNamespace=fkp-fdp-galaxy-hive3-hs2-agni;hive.client.read.socket.timeout=300?hive.metastore.client.socket.timeout=180;hive.server.tcp.keepalive=true;hive.server.read.socket.timeout=300")
 
# print('Established JDBC connection---------------------')

# conn = jaydebeapi.connect("org.apache.hive.jdbc.HiveDriver", url,{'user': "mohammed.usama", 'password': "Khalid@170757"})

# print('Connected to hive server-------------------------')

# cursor = conn.cursor()
# cursor.execute("ADD JAR /usr/share/fk-bigfoot-hivejsonserde/json-serde-1.3-SNAPSHOT-jar-with-dependencies.jar")
# cursor.execute("ADD JAR /usr/share/fk-bigfoot-dimlookup/dimlookup-hive-udf-1.0-SNAPSHOT-jar-with-dependencies.jar")
# cursor.execute("ADD JAR gs://fkpdp-mhosy-2nig-1a5d-systemlibs/libraries/hive/jars/hive-udfs-1.0-SNAPSHOT.jar")
# cursor.execute("CREATE TEMPORARY FUNCTION lookup as 'com.flipkart.bigfoot.dimlookup.udf.HiveLookupUDF'")
# cursor.execute("CREATE TEMPORARY FUNCTION arrToString as 'com.flipkart.fdp.CustomCaster'")
# cursor.execute("CREATE TEMPORARY FUNCTION lookupkey as 'com.flipkart.bigfoot.dimlookup.udf.HiveKeyGeneratorUDF'")
# cursor.execute("CREATE TEMPORARY FUNCTION lookup_date as 'com.flipkart.bigfoot.dimlookup.udf.DateLookupUDF'")
# cursor.execute("CREATE TEMPORARY FUNCTION lookup_time as 'com.flipkart.bigfoot.dimlookup.udf.TimeLookupUDF'")
# cursor.execute("CREATE TEMPORARY FUNCTION aggregate_filter as 'com.flipkart.bigfoot.dimlookup.udf.AggregateConditionUDF'")
# cursor.execute("CREATE TEMPORARY FUNCTION aggregate as 'com.flipkart.bigfoot.dimlookup.udf.AggregateUDF'")
# cursor.execute("CREATE TEMPORARY FUNCTION ISOToSqlTs as 'com.flipkart.bigfoot.dimlookup.udf.DateISOToSqlUDF'")
# cursor.execute("CREATE TEMPORARY FUNCTION business_date_diff as 'com.flipkart.bigfoot.dimlookup.udf.BusinessDayDiffUDF'")

# cursor.execute("set mapreduce.input.fileinputformat.input.dir.recursive=true")

# print('connect')

X_Client_Id= 'analytics-cdo' ### Change as per your org-namespace
X_Client_Secret= '6cbdc3cd-a3f7-43e1-a2f9-1935f6317c44' ### Change as per your org-namespace
user_name='shubham.v.vc' ### Change as per your username

# Alpha Query you want to pull
query = """
select
substr(sales_fact.order_date_key,1,6) as year_month,
sales_fact.analytic_business_unit,
case
when loc.city_tier = 'Metro' then "Metro"
when loc.city_tier = 'Tier 1A' or loc.city_tier='Tier 1B' then "Tier 1"
when loc.city_tier = 'Tier 2' then "Tier 2"
else "Tier 3 & Others"
end as tiers_flag,
case
when lower(loc.zone) = 'north' then "North"
when lower(loc.zone) = 'south' then "South"
when lower(loc.zone) = 'east' then "East"
else "West"
end as zone_flag,
afff.cohort as v3_affluence_signal,
CASE
WHEN (cust_fact.new_cust_flag=TRUE ) THEN 'NN'
WHEN (cust_fact.new_cust_flag=FALSE and cust_fact.new_to_bu=TRUE) THEN 'ON'
ELSE 'OO'
END as cust_category,
count(distinct(sales_fact.account_id)) as total_customers,
sum(sales_fact.units) as total_units,
sum(sales_fact.gmv) as total_gmv
from
bigfoot_external_neo.cp_bi_prod_sales__forward_unit_history_fact as sales_fact
left join
bigfoot_external_neo.scp_ekl__logistics_geo_hive_dim loc
on sales_fact.pincode = loc.pincode
left join 
bigfoot_external_neo.cp_uie__Affluence_V3_2_final_output_fact afff
on sales_fact.account_id = afff.account_id
left join
( 
    select 
    distinct order_id,
    new_cust_flag,
    new_to_bu 
    from
    bigfoot_external_neo.analytics_cdo__customer_insight_hive_fact
) as cust_fact
on sales_fact.order_id=cust_fact.order_id
where
sales_fact.order_date_key between lookup_date(date_sub(date_sub(current_date,1),dayofmonth(date_sub(current_date,1))-1)) and lookup_date(date_sub(current_date,2))
and lower(sales_fact.status) in ('in_progress','undelivered','completed','delivered','approved','shipped','ready_to_ship','returned', 'return_requested','activated')
and sales_fact.type != 'service'
and sales_fact.category_id != 21726
and sales_fact.category_id != 21651
and sales_fact.replacement_for_unit is null
and sales_fact.exchange_for_unit is null
and sales_fact.is_freebie = false
and sales_fact.is_shopsy_order = false
and lower(sales_fact.marketplace_id) in ('flipkart')
group by
substr(sales_fact.order_date_key,1,6),
sales_fact.analytic_business_unit,
case
when loc.city_tier = 'Metro' then "Metro"
when loc.city_tier = 'Tier 1A' or loc.city_tier='Tier 1B' then "Tier 1"
when loc.city_tier = 'Tier 2' then "Tier 2"
else "Tier 3 & Others"
end,
case
when lower(loc.zone) = 'north' then "North"
when lower(loc.zone) = 'south' then "South"
when lower(loc.zone) = 'east' then "East"
else "West"
end,
afff.cohort,
CASE
WHEN (cust_fact.new_cust_flag=TRUE ) THEN 'NN'
WHEN (cust_fact.new_cust_flag=FALSE and cust_fact.new_to_bu=TRUE) THEN 'ON'
ELSE 'OO'
END

"""

url = 'http://validator.fdp-qaas-validator-prod.fkcloud.in/query/queries'


headers ={'Accept': '*', 'Content-Type': 'application/x-www-form-urlencoded',
          'Host': 'validator.fdp-qaas-validator-prod.fkcloud.in',
          'X-Client-Id': X_Client_Id, 
          'X-Client-Secret': X_Client_Secret,
          'x-authenticated-user':user_name 
          }
data ={'query':query,'sourceName':'HIVE'}

r = requests.post(url, headers=headers, data = data)
print(r.content)

print('r is: ',r)
print('If you get <Response [200]> above, that implies the url request was successful ')
query_handle_byte_dtype = r.content
# using decode() + loads() to convert to dictionary
query_handle_dict_dtype = json.loads(query_handle_byte_dtype.decode('utf-8'))
query_handle = query_handle_dict_dtype['queryHandle']['handle']
print("http://fdp.fkinternal.com/query/result/"+query_handle)

url = '  http://validator.fdp-qaas-validator-prod.fkcloud.in/query/queries/'+query_handle+'/status'


headers ={'Accept': '*', 'Content-Type': 'application/x-www-form-urlencoded',
          'Host': 'validator.fdp-qaas-validator-prod.fkcloud.in',
          'X-Client-Id': X_Client_Id, 
          'X-Client-Secret': X_Client_Secret,
          'x-authenticated-user':user_name 
          }
data ={'query':query,'sourceName':'HIVE'}

status_req = requests.get(url, headers=headers)

json.loads(status_req.content.decode('utf-8'))['status']
  
a = 0

while (a != 1):
    b=''
    status_req = requests.get(url, headers=headers)
    b = json.loads(status_req.content.decode('utf-8'))['status']    
    if b == 'SUCCESSFUL':
        a = 1
    else: 
        a = 0
    print(a)
    print('code still running')
    time.sleep(30)
    
print(status_req)

url_data_pull = 'http://validator.fdp-qaas-validator-prod.fkcloud.in/query/queries/'+ query_handle +'/downloadresults'


headers_data_pull ={'Accept': '*', 'Content-Type': 'application/x-www-form-urlencoded',
                    'Host': 'validator.fdp-qaas-validator-prod.fkcloud.in',
                    'X-Client-Id': X_Client_Id, 
          'X-Client-Secret': X_Client_Secret,
          'x-authenticated-user':user_name 
                   }

r_data_pull = requests.get(url_data_pull, headers=headers_data_pull)

query_output = r_data_pull.content

s=query_output.decode('utf-8')


data = StringIO(s) 

cust_data=pd.read_csv(data)

# gc=pygsheets.authorize(service_file='ShivankAutomation-fd5dab44a774.json')
# sh=gc.open('Life_Style_Data')

# data=sh[2]





# In[ ]:


cust_data


# In[ ]:


gc=pygsheets.authorize(service_file='ShivankAutomation-fd5dab44a774.json')
sh=gc.open('Customer Insights Dashboard')
worksheet=sh.worksheets().copy()
sheet_name = [s.title for s in worksheet]
data=sh[sheet_name.index('BU_LEVEL')]
data.clear(start='AL2', end='AT100000', fields="*")
data.set_dataframe(cust_data,(2,38),copy_head=False,copy_index=False)


# # For BU level (Query 3 - m1,m2 cuts)

# In[ ]:


from datetime import date
from datetime import datetime, timedelta
today=date.today()#-timedelta(days=15)
day1=today-timedelta(days=today.day)
end_day_main1='{:02d}'.format(day1.year)+'{:02d}'.format(day1.month)+'{:02d}'.format(day1.day)
start_day_main1='{:02d}'.format(day1.year)+'{:02d}'.format(day1.month)+'01'

day2=today-timedelta(days=today.day+day1.day)
end_day_main2='{:02d}'.format(day2.year)+'{:02d}'.format(day2.month)+'{:02d}'.format(day2.day)
start_day_main2='{:02d}'.format(day2.year)+'{:02d}'.format(day2.month)+'01'

day3=today-timedelta(days=today.day+day1.day+day2.day)
end_day_main3='{:02d}'.format(day3.year)+'{:02d}'.format(day3.month)+'{:02d}'.format(day3.day)
start_day_main3='{:02d}'.format(day3.year)+'{:02d}'.format(day3.month)+'01'

day4=today-timedelta(days=today.day+day1.day+day2.day+day3.day)
end_day_main4='{:02d}'.format(day4.year)+'{:02d}'.format(day4.month)+'{:02d}'.format(day4.day)
#start_day_main4='{:02d}'.format(day4.year)+'{:02d}'.format(day4.month)+'01'

day5=today-timedelta(days=today.day+day1.day+day2.day+day3.day+day4.day)
day6=today-timedelta(days=today.day+day1.day+day2.day+day3.day+day4.day+day5.day)
start_day_main6='{:02d}'.format(day6.year)+'{:02d}'.format(day6.month)+'01'

day7=today-timedelta(days=today.day+day1.day+day2.day+day3.day+day4.day+day5.day+day6.day)
end_day_main7='{:02d}'.format(day7.year)+'{:02d}'.format(day7.month)+'{:02d}'.format(day7.day)

day8=today-timedelta(days=today.day+day1.day+day2.day+day3.day+day4.day+day5.day+day6.day+day7.day)
day9=today-timedelta(days=today.day+day1.day+day2.day+day3.day+day4.day+day5.day+day6.day+day7.day+day8.day)
day10=today-timedelta(days=today.day+day1.day+day2.day+day3.day+day4.day+day5.day+day6.day+day7.day+day8.day+day9.day)
day11=today-timedelta(days=today.day+day1.day+day2.day+day3.day+day4.day+day5.day+day6.day+day7.day+day8.day+day9.day+day10.day)
day12=today-timedelta(days=today.day+day1.day+day2.day+day3.day+day4.day+day5.day+day6.day+day7.day+day8.day+day9.day+day10.day+day11.day)
start_day_main12='{:02d}'.format(day12.year)+'{:02d}'.format(day12.month)+'01'


# In[ ]:


# Repeat

import requests
import json
from io import StringIO
import time
import pandas as pd
import jaydebeapi
import os
import subprocess
import pandas as pd
import numpy as np
import datetime
import calendar
import pygsheets
import re
from datetime import date
import jaydebeapi
import os
import subprocess
import numpy as np
import datetime
import calendar
import pygsheets
import re

# output = subprocess.check_output(['bash', '-c', 'echo $CLASSPATH:/usr/local/fdp-infra-hive/lib/*'])
# os.environ['CLASSPATH'] = '/usr/local/fdp-infra-hive/lib/*'

# url = ("jdbc:hive2://fkp-fdp-galaxy-sun-zkjn-0001.c.fkp-fdp-galaxy.internal:2181,fkp-fdp-galaxy-sun-zkjn-0002.c.fkp-fdp-galaxy.internal:2181,fkp-fdp-galaxy-sun-zkjn-0003.c.fkp-fdp-galaxy.internal:2181/default;transportMode=http;httpPath=cliservice;serviceDiscoveryMode=zooKeeper;zooKeeperNamespace=fkp-fdp-galaxy-hive3-hs2-agni;hive.client.read.socket.timeout=300?hive.metastore.client.socket.timeout=180;hive.server.tcp.keepalive=true;hive.server.read.socket.timeout=300")
 
# print('Established JDBC connection---------------------')

# conn = jaydebeapi.connect("org.apache.hive.jdbc.HiveDriver", url,{'user': "mohammed.usama", 'password': "Khalid@170757"})

# print('Connected to hive server-------------------------')

# cursor = conn.cursor()
# cursor.execute("ADD JAR /usr/share/fk-bigfoot-hivejsonserde/json-serde-1.3-SNAPSHOT-jar-with-dependencies.jar")
# cursor.execute("ADD JAR /usr/share/fk-bigfoot-dimlookup/dimlookup-hive-udf-1.0-SNAPSHOT-jar-with-dependencies.jar")
# cursor.execute("ADD JAR gs://fkpdp-mhosy-2nig-1a5d-systemlibs/libraries/hive/jars/hive-udfs-1.0-SNAPSHOT.jar")
# cursor.execute("CREATE TEMPORARY FUNCTION lookup as 'com.flipkart.bigfoot.dimlookup.udf.HiveLookupUDF'")
# cursor.execute("CREATE TEMPORARY FUNCTION arrToString as 'com.flipkart.fdp.CustomCaster'")
# cursor.execute("CREATE TEMPORARY FUNCTION lookupkey as 'com.flipkart.bigfoot.dimlookup.udf.HiveKeyGeneratorUDF'")
# cursor.execute("CREATE TEMPORARY FUNCTION lookup_date as 'com.flipkart.bigfoot.dimlookup.udf.DateLookupUDF'")
# cursor.execute("CREATE TEMPORARY FUNCTION lookup_time as 'com.flipkart.bigfoot.dimlookup.udf.TimeLookupUDF'")
# cursor.execute("CREATE TEMPORARY FUNCTION aggregate_filter as 'com.flipkart.bigfoot.dimlookup.udf.AggregateConditionUDF'")
# cursor.execute("CREATE TEMPORARY FUNCTION aggregate as 'com.flipkart.bigfoot.dimlookup.udf.AggregateUDF'")
# cursor.execute("CREATE TEMPORARY FUNCTION ISOToSqlTs as 'com.flipkart.bigfoot.dimlookup.udf.DateISOToSqlUDF'")
# cursor.execute("CREATE TEMPORARY FUNCTION business_date_diff as 'com.flipkart.bigfoot.dimlookup.udf.BusinessDayDiffUDF'")

# cursor.execute("set mapreduce.input.fileinputformat.input.dir.recursive=true")

# print('connect')

X_Client_Id= 'analytics-cdo' ### Change as per your org-namespace
X_Client_Secret= '6cbdc3cd-a3f7-43e1-a2f9-1935f6317c44' ### Change as per your org-namespace
user_name='shubham.v.vc' ### Change as per your username

# Alpha Query you want to pull
query = """
select
    substr(a.order_date_key,1,6) as year_month,
    a.analytic_business_unit,
    sum(a.gmv) as gmv,
    sum(a.units) as units,
    count(distinct(a.account_id)) as customers,
case 
    when b.last  between """+ start_day_main1 + """ and """ + end_day_main1 + """
    then "M1"
    when b.last  between """+ start_day_main2 + """ and """ + end_day_main2 + """
    then "M2"
    when b.last  between """+ start_day_main3 + """ and """ + end_day_main3 + """
    then "M3"
    when b.last  between """+ start_day_main6 + """ and """ + end_day_main4 + """
    then "M4-6"
    when b.last  between """+ start_day_main12 + """ and """ + end_day_main7 + """
    then "M7-12 (Lapser)"
    when b.last  < """+ start_day_main12 + """
    then "Re activated"
    else "New"
end as repeat
from
(
    select
        order_date_key, analytic_business_unit, analytic_super_category,
        account_id,
        FLOOR((DayOfMonth(from_unixtime(unix_timestamp(cast(order_date_key as STRING), 'yyyyMMdd')))-1)/7)+1 as weekofmon,
        sum(gmv) as gmv,
        sum(units) as units,
        count(distinct(account_id)) 
    from
        bigfoot_external_neo.cp_bi_prod_sales__forward_unit_history_fact
    where
        lower(status) in ('in_progress','undelivered','completed','delivered','approved','shipped','ready_to_ship','returned', 'return_requested','activated')
        and type !='service'
        and category_id !=21726
        and category_id !=21651
        and order_date_key between lookup_date(date_sub(date_sub(current_date,1),dayofmonth(date_sub(current_date,1))-1)) and lookup_date(date_sub(current_date,2))
        and lower(marketplace_id) = 'flipkart'
        and (replacement_for_unit is null or replacement_for_unit='not_replacement')
        and (exchange_for_unit is null or exchange_for_unit='not_exchange')
        and is_freebie =false
        and is_shopsy_order = false
    group by
        order_date_key,analytic_business_unit,analytic_super_category,
        FLOOR((DayOfMonth(from_unixtime(unix_timestamp(cast(order_date_key as STRING), 'yyyyMMdd')))-1)/7)+1,
        account_id
) a
left join 
(
    select
        account_id,
        analytic_business_unit,
        max(approve_date_key) as last
    from
        bigfoot_external_neo.analytics_cdo__customer_insight_hive_fact
    where 
        approve_date_key < lookup_date(date_sub(date_sub(current_date,1),dayofmonth(date_sub(current_date,1))-1))
    group by 
        account_id,
        analytic_business_unit
 ) b
on a.account_id = b.account_id and a.analytic_business_unit = b.analytic_business_unit
group by
    substr(a.order_date_key,1,6),
    a.analytic_business_unit,
case 
    when b.last  between """+ start_day_main1 + """ and """ + end_day_main1 + """
    then "M1"
    when b.last  between """+ start_day_main2 + """ and """ + end_day_main2 + """
    then "M2"
    when b.last  between """+ start_day_main3 + """ and """ + end_day_main3 + """
    then "M3"
    when b.last  between """+ start_day_main6 + """ and """ + end_day_main4 + """
    then "M4-6"
    when b.last  between """+ start_day_main12 + """ and """ + end_day_main7 + """
    then "M7-12 (Lapser)"
    when b.last  < """+ start_day_main12 + """
    then "Re activated"
    else "New"
end
"""

url = 'http://validator.fdp-qaas-validator-prod.fkcloud.in/query/queries'


headers ={'Accept': '*', 'Content-Type': 'application/x-www-form-urlencoded',
          'Host': 'validator.fdp-qaas-validator-prod.fkcloud.in',
          'X-Client-Id': X_Client_Id, 
          'X-Client-Secret': X_Client_Secret,
          'x-authenticated-user':user_name 
          }
data ={'query':query,'sourceName':'HIVE'}

r = requests.post(url, headers=headers, data = data)
print(r.content)

print('r is: ',r)
print('If you get <Response [200]> above, that implies the url request was successful ')
query_handle_byte_dtype = r.content
# using decode() + loads() to convert to dictionary
query_handle_dict_dtype = json.loads(query_handle_byte_dtype.decode('utf-8'))
query_handle = query_handle_dict_dtype['queryHandle']['handle']
print("http://fdp.fkinternal.com/query/result/"+query_handle)

url = '  http://validator.fdp-qaas-validator-prod.fkcloud.in/query/queries/'+query_handle+'/status'


headers ={'Accept': '*', 'Content-Type': 'application/x-www-form-urlencoded',
          'Host': 'validator.fdp-qaas-validator-prod.fkcloud.in',
          'X-Client-Id': X_Client_Id, 
          'X-Client-Secret': X_Client_Secret,
          'x-authenticated-user':user_name 
          }
data ={'query':query,'sourceName':'HIVE'}

status_req = requests.get(url, headers=headers)

json.loads(status_req.content.decode('utf-8'))['status']
  
a = 0

while (a != 1):
    b=''
    status_req = requests.get(url, headers=headers)
    b = json.loads(status_req.content.decode('utf-8'))['status']    
    if b == 'SUCCESSFUL':
        a = 1
    else: 
        a = 0
    print(a)
    print('code still running')
    time.sleep(30)
    
print(status_req)

url_data_pull = 'http://validator.fdp-qaas-validator-prod.fkcloud.in/query/queries/'+ query_handle +'/downloadresults'


headers_data_pull ={'Accept': '*', 'Content-Type': 'application/x-www-form-urlencoded',
                    'Host': 'validator.fdp-qaas-validator-prod.fkcloud.in',
                    'X-Client-Id': X_Client_Id, 
          'X-Client-Secret': X_Client_Secret,
          'x-authenticated-user':user_name 
                   }

r_data_pull = requests.get(url_data_pull, headers=headers_data_pull)

query_output = r_data_pull.content

s=query_output.decode('utf-8')


data = StringIO(s) 

repeat=pd.read_csv(data)

# gc=pygsheets.authorize(service_file='ShivankAutomation-fd5dab44a774.json')
# sh=gc.open('Life_Style_Data')

# data=sh[2]



# In[ ]:


repeat


# In[ ]:


gc=pygsheets.authorize(service_file='ShivankAutomation-fd5dab44a774.json')
sh=gc.open('Customer Insights Dashboard')
worksheet=sh.worksheets().copy()
sheet_name = [s.title for s in worksheet]
data=sh[sheet_name.index('raw_data_m1_cuts')]
data.clear(start='J2', end='O200000', fields="*")
data.set_dataframe(repeat,(2,10),copy_head=False,copy_index=False)



# # For BU level (TPC)

from datetime import date
from datetime import datetime, timedelta
today=date.today()#-timedelta(days=15)
day1=today-timedelta(days=today.day)

dm2=today-timedelta(days=2)

som='{:02d}'.format(dm2.year)+'{:02d}'.format(dm2.month)+'01'
eom='{:02d}'.format(dm2.year)+'{:02d}'.format(dm2.month)+'{:02d}'.format(dm2.day)

#### m1 
m1_end='{:02d}'.format(day1.year)+'{:02d}'.format(day1.month)+'{:02d}'.format(day1.day)
m1_start='{:02d}'.format(day1.year)+'{:02d}'.format(day1.month)+'01'
m1_end_ly='{:02d}'.format(day1.year-1)+'{:02d}'.format(day1.month)+'{:02d}'.format(day1.day)
m1_start_ly='{:02d}'.format(day1.year-1)+'{:02d}'.format(day1.month)+'01'


#### m2
day2=today-timedelta(days=today.day+day1.day)
m2_end='{:02d}'.format(day2.year)+'{:02d}'.format(day2.month)+'{:02d}'.format(day2.day)
m2_start='{:02d}'.format(day2.year)+'{:02d}'.format(day2.month)+'01'
m2_end_ly='{:02d}'.format(day2.year-1)+'{:02d}'.format(day2.month)+'{:02d}'.format(day2.day)
m2_start_ly='{:02d}'.format(day2.year-1)+'{:02d}'.format(day2.month)+'01'


#### m3
day3=today-timedelta(days=today.day+day1.day+day2.day)
m3_end='{:02d}'.format(day3.year)+'{:02d}'.format(day3.month)+'{:02d}'.format(day3.day)
m3_start='{:02d}'.format(day3.year)+'{:02d}'.format(day3.month)+'01'
m3_end_ly='{:02d}'.format(day3.year-1)+'{:02d}'.format(day3.month)+'{:02d}'.format(day3.day)
m3_start_ly='{:02d}'.format(day3.year-1)+'{:02d}'.format(day3.month)+'01'


#### m4-6
day4=today-timedelta(days=today.day+day1.day+day2.day+day3.day)
m4_6_end='{:02d}'.format(day4.year)+'{:02d}'.format(day4.month)+'{:02d}'.format(day4.day)

day5=today-timedelta(days=today.day+day1.day+day2.day+day3.day+day4.day)
day6=today-timedelta(days=today.day+day1.day+day2.day+day3.day+day4.day+day5.day)
m4_6_start='{:02d}'.format(day6.year)+'{:02d}'.format(day6.month)+'01'
m4_6_end_ly='{:02d}'.format(day4.year-1)+'{:02d}'.format(day4.month)+'{:02d}'.format(day4.day)
m4_6_start_ly='{:02d}'.format(day6.year-1)+'{:02d}'.format(day6.month)+'01'


#### m7-12
day7=today-timedelta(days=today.day+day1.day+day2.day+day3.day+day4.day+day5.day+day6.day)
m7_12_end='{:02d}'.format(day7.year)+'{:02d}'.format(day7.month)+'{:02d}'.format(day7.day)

day8=today-timedelta(days=today.day+day1.day+day2.day+day3.day+day4.day+day5.day+day6.day+day7.day)
day9=today-timedelta(days=today.day+day1.day+day2.day+day3.day+day4.day+day5.day+day6.day+day7.day+day8.day)
day10=today-timedelta(days=today.day+day1.day+day2.day+day3.day+day4.day+day5.day+day6.day+day7.day+day8.day+day9.day)
day11=today-timedelta(days=today.day+day1.day+day2.day+day3.day+day4.day+day5.day+day6.day+day7.day+day8.day+day9.day+day10.day)
day12=today-timedelta(days=today.day+day1.day+day2.day+day3.day+day4.day+day5.day+day6.day+day7.day+day8.day+day9.day+day10.day+day11.day)
m7_12_start='{:02d}'.format(day12.year)+'{:02d}'.format(day12.month)+'01'


m7_12_end_ly='{:02d}'.format(day7.year-1)+'{:02d}'.format(day7.month)+'{:02d}'.format(day7.day)
m7_12_start_ly='{:02d}'.format(day12.year-1)+'{:02d}'.format(day12.month)+'01'




import requests
import json
from io import StringIO
import time
import pandas as pd
import jaydebeapi
import os
import subprocess
import pandas as pd
import numpy as np
import datetime
import calendar
import pygsheets
import re
from datetime import date
import jaydebeapi
import os
import subprocess
import numpy as np
import datetime
import calendar
import pygsheets
import re

# output = subprocess.check_output(['bash', '-c', 'echo $CLASSPATH:/usr/local/fdp-infra-hive/lib/*'])
# os.environ['CLASSPATH'] = '/usr/local/fdp-infra-hive/lib/*'

# url = ("jdbc:hive2://fkp-fdp-galaxy-sun-zkjn-0001.c.fkp-fdp-galaxy.internal:2181,fkp-fdp-galaxy-sun-zkjn-0002.c.fkp-fdp-galaxy.internal:2181,fkp-fdp-galaxy-sun-zkjn-0003.c.fkp-fdp-galaxy.internal:2181/default;transportMode=http;httpPath=cliservice;serviceDiscoveryMode=zooKeeper;zooKeeperNamespace=fkp-fdp-galaxy-hive3-hs2-agni;hive.client.read.socket.timeout=300?hive.metastore.client.socket.timeout=180;hive.server.tcp.keepalive=true;hive.server.read.socket.timeout=300")
 
# print('Established JDBC connection---------------------')

# conn = jaydebeapi.connect("org.apache.hive.jdbc.HiveDriver", url,{'user': "mohammed.usama", 'password': "Khalid@170757"})

# print('Connected to hive server-------------------------')

# cursor = conn.cursor()
# cursor.execute("ADD JAR /usr/share/fk-bigfoot-hivejsonserde/json-serde-1.3-SNAPSHOT-jar-with-dependencies.jar")
# cursor.execute("ADD JAR /usr/share/fk-bigfoot-dimlookup/dimlookup-hive-udf-1.0-SNAPSHOT-jar-with-dependencies.jar")
# cursor.execute("ADD JAR gs://fkpdp-mhosy-2nig-1a5d-systemlibs/libraries/hive/jars/hive-udfs-1.0-SNAPSHOT.jar")
# cursor.execute("CREATE TEMPORARY FUNCTION lookup as 'com.flipkart.bigfoot.dimlookup.udf.HiveLookupUDF'")
# cursor.execute("CREATE TEMPORARY FUNCTION arrToString as 'com.flipkart.fdp.CustomCaster'")
# cursor.execute("CREATE TEMPORARY FUNCTION lookupkey as 'com.flipkart.bigfoot.dimlookup.udf.HiveKeyGeneratorUDF'")
# cursor.execute("CREATE TEMPORARY FUNCTION lookup_date as 'com.flipkart.bigfoot.dimlookup.udf.DateLookupUDF'")
# cursor.execute("CREATE TEMPORARY FUNCTION lookup_time as 'com.flipkart.bigfoot.dimlookup.udf.TimeLookupUDF'")
# cursor.execute("CREATE TEMPORARY FUNCTION aggregate_filter as 'com.flipkart.bigfoot.dimlookup.udf.AggregateConditionUDF'")
# cursor.execute("CREATE TEMPORARY FUNCTION aggregate as 'com.flipkart.bigfoot.dimlookup.udf.AggregateUDF'")
# cursor.execute("CREATE TEMPORARY FUNCTION ISOToSqlTs as 'com.flipkart.bigfoot.dimlookup.udf.DateISOToSqlUDF'")
# cursor.execute("CREATE TEMPORARY FUNCTION business_date_diff as 'com.flipkart.bigfoot.dimlookup.udf.BusinessDayDiffUDF'")

# cursor.execute("set mapreduce.input.fileinputformat.input.dir.recursive=true")

# print('connect')

X_Client_Id= 'analytics-cdo' ### Change as per your org-namespace
X_Client_Secret= '6cbdc3cd-a3f7-43e1-a2f9-1935f6317c44' ### Change as per your org-namespace
user_name='shubham.v.vc' ### Change as per your username

# Alpha Query you want to pull
query = """
----TPC for current month for Customer dashboard

select
	sales_fact.month as year_month,
	sales_fact.analytic_business_unit,
	count(distinct(sales_fact.account_id)) as customers,
	count(distinct(case WHEN tpc_base.orders >12 THEN sales_fact.account_id end)) as very_high_tpc,
	count(distinct(case WHEN tpc_base.orders >=8 and tpc_base.orders<=12 THEN sales_fact.account_id end)) as high_tpc,
	count(distinct(case WHEN tpc_base.orders >=4 and tpc_base.orders<=7 THEN sales_fact.account_id end)) as mid_tpc,
	count(distinct(case WHEN tpc_base.orders >=1 and tpc_base.orders<=3 THEN sales_fact.account_id end)) as low_tpc
from
	(select
	account_id,sales_fact.analytic_business_unit,
	substr(sales_fact.order_date_key,1,6) as month,
	count(distinct order_external_id) as orders

		FROM bigfoot_external_neo.cp_bi_prod_sales__forward_unit_history_fact as sales_fact
	where
		sales_fact.order_date_key between """+ som + """ and """+ eom + """
		-- and lower(sales_fact.analytic_business_unit) in ('lifestyle')   --- change as per requirement
		and lower(sales_fact.status) in ('in_progress','undelivered','completed','delivered','approved','shipped','ready_to_ship','returned', 'return_requested','activated')
		and sales_fact.type !='service'
		and sales_fact.category_id !=21726
		and sales_fact.category_id !=21651
		and sales_fact.replacement_for_unit is null
		and sales_fact.exchange_for_unit is null
		and sales_fact.is_freebie = false
		and sales_fact.marketplace_id = 'FLIPKART'
		and sales_fact.is_shopsy_order = false
	group by
	account_id,sales_fact.analytic_business_unit,
	substr(sales_fact.order_date_key,1,6)
	) AS sales_fact

left join
----- TPC data code
	(
	select
		substr("""+ som + """,1,6) as month,
		analytic_business_unit,
		account_id,
		count(distinct order_external_id) as orders
	from bigfoot_external_neo.analytics_cdo__customer_insight_hive_fact
	where 
		approve_date_key between """+ m7_12_start + """ and """+ m1_end + """
		-- and lower(analytic_business_unit) = 'lifestyle'
	group by
		substr("""+ som + """,1,6),
		analytic_business_unit,
		account_id
	) tpc_base
on 
	sales_fact.month = tpc_base.month 
	AND sales_fact.analytic_business_unit = tpc_base.analytic_business_unit
	and  sales_fact.account_id = tpc_base.account_id
group by
	sales_fact.month,
	sales_fact.analytic_business_unit

"""

url = 'http://validator.fdp-qaas-validator-prod.fkcloud.in/query/queries'


headers ={'Accept': '*', 'Content-Type': 'application/x-www-form-urlencoded',
          'Host': 'validator.fdp-qaas-validator-prod.fkcloud.in',
          'X-Client-Id': X_Client_Id, 
          'X-Client-Secret': X_Client_Secret,
          'x-authenticated-user':user_name 
          }
data ={'query':query,'sourceName':'HIVE'}

r = requests.post(url, headers=headers, data = data)
print(r.content)

print('r is: ',r)
print('If you get <Response [200]> above, that implies the url request was successful ')
query_handle_byte_dtype = r.content
# using decode() + loads() to convert to dictionary
query_handle_dict_dtype = json.loads(query_handle_byte_dtype.decode('utf-8'))
query_handle = query_handle_dict_dtype['queryHandle']['handle']
print("http://fdp.fkinternal.com/query/result/"+query_handle)

url = '  http://validator.fdp-qaas-validator-prod.fkcloud.in/query/queries/'+query_handle+'/status'


headers ={'Accept': '*', 'Content-Type': 'application/x-www-form-urlencoded',
          'Host': 'validator.fdp-qaas-validator-prod.fkcloud.in',
          'X-Client-Id': X_Client_Id, 
          'X-Client-Secret': X_Client_Secret,
          'x-authenticated-user':user_name 
          }
data ={'query':query,'sourceName':'HIVE'}

status_req = requests.get(url, headers=headers)

json.loads(status_req.content.decode('utf-8'))['status']
  
a = 0

while (a != 1):
    b=''
    status_req = requests.get(url, headers=headers)
    b = json.loads(status_req.content.decode('utf-8'))['status']    
    if b == 'SUCCESSFUL':
        a = 1
    else: 
        a = 0
    print(a)
    print('code still running')
    time.sleep(30)
    
print(status_req)

url_data_pull = 'http://validator.fdp-qaas-validator-prod.fkcloud.in/query/queries/'+ query_handle +'/downloadresults'


headers_data_pull ={'Accept': '*', 'Content-Type': 'application/x-www-form-urlencoded',
                    'Host': 'validator.fdp-qaas-validator-prod.fkcloud.in',
                    'X-Client-Id': X_Client_Id, 
          'X-Client-Secret': X_Client_Secret,
          'x-authenticated-user':user_name 
                   }

r_data_pull = requests.get(url_data_pull, headers=headers_data_pull)

query_output = r_data_pull.content

s=query_output.decode('utf-8')


data = StringIO(s) 

tpc=pd.read_csv(data)

# gc=pygsheets.authorize(service_file='ShivankAutomation-fd5dab44a774.json')
# sh=gc.open('Life_Style_Data')

# data=sh[2]


tpc=tpc.iloc[:-1,:]


gc=pygsheets.authorize(service_file='ShivankAutomation-fd5dab44a774.json')
sh=gc.open('Customer Insights Dashboard')
worksheet=sh.worksheets().copy()
sheet_name = [s.title for s in worksheet]
data=sh[sheet_name.index('raw_tpc')]
data.clear(start='A2', end='G1000', fields="*")
data.set_dataframe(tpc,(2,1),copy_head=False,copy_index=False)




# # For BUxSC level (Query 4 - overall cuts)

# In[ ]:


import requests
import json
from io import StringIO
import time
import pandas as pd
import jaydebeapi
import os
import subprocess
import pandas as pd
import numpy as np
import datetime
import calendar
import pygsheets
import re
from datetime import date
import jaydebeapi
import os
import subprocess
import numpy as np
import datetime
import calendar
import pygsheets
import re

# output = subprocess.check_output(['bash', '-c', 'echo $CLASSPATH:/usr/local/fdp-infra-hive/lib/*'])
# os.environ['CLASSPATH'] = '/usr/local/fdp-infra-hive/lib/*'

# url = ("jdbc:hive2://fkp-fdp-galaxy-sun-zkjn-0001.c.fkp-fdp-galaxy.internal:2181,fkp-fdp-galaxy-sun-zkjn-0002.c.fkp-fdp-galaxy.internal:2181,fkp-fdp-galaxy-sun-zkjn-0003.c.fkp-fdp-galaxy.internal:2181/default;transportMode=http;httpPath=cliservice;serviceDiscoveryMode=zooKeeper;zooKeeperNamespace=fkp-fdp-galaxy-hive3-hs2-agni;hive.client.read.socket.timeout=300?hive.metastore.client.socket.timeout=180;hive.server.tcp.keepalive=true;hive.server.read.socket.timeout=300")
 
# print('Established JDBC connection---------------------')

# conn = jaydebeapi.connect("org.apache.hive.jdbc.HiveDriver", url,{'user': "mohammed.usama", 'password': "Khalid@170757"})

# print('Connected to hive server-------------------------')

# cursor = conn.cursor()
# cursor.execute("ADD JAR /usr/share/fk-bigfoot-hivejsonserde/json-serde-1.3-SNAPSHOT-jar-with-dependencies.jar")
# cursor.execute("ADD JAR /usr/share/fk-bigfoot-dimlookup/dimlookup-hive-udf-1.0-SNAPSHOT-jar-with-dependencies.jar")
# cursor.execute("ADD JAR gs://fkpdp-mhosy-2nig-1a5d-systemlibs/libraries/hive/jars/hive-udfs-1.0-SNAPSHOT.jar")
# cursor.execute("CREATE TEMPORARY FUNCTION lookup as 'com.flipkart.bigfoot.dimlookup.udf.HiveLookupUDF'")
# cursor.execute("CREATE TEMPORARY FUNCTION arrToString as 'com.flipkart.fdp.CustomCaster'")
# cursor.execute("CREATE TEMPORARY FUNCTION lookupkey as 'com.flipkart.bigfoot.dimlookup.udf.HiveKeyGeneratorUDF'")
# cursor.execute("CREATE TEMPORARY FUNCTION lookup_date as 'com.flipkart.bigfoot.dimlookup.udf.DateLookupUDF'")
# cursor.execute("CREATE TEMPORARY FUNCTION lookup_time as 'com.flipkart.bigfoot.dimlookup.udf.TimeLookupUDF'")
# cursor.execute("CREATE TEMPORARY FUNCTION aggregate_filter as 'com.flipkart.bigfoot.dimlookup.udf.AggregateConditionUDF'")
# cursor.execute("CREATE TEMPORARY FUNCTION aggregate as 'com.flipkart.bigfoot.dimlookup.udf.AggregateUDF'")
# cursor.execute("CREATE TEMPORARY FUNCTION ISOToSqlTs as 'com.flipkart.bigfoot.dimlookup.udf.DateISOToSqlUDF'")
# cursor.execute("CREATE TEMPORARY FUNCTION business_date_diff as 'com.flipkart.bigfoot.dimlookup.udf.BusinessDayDiffUDF'")

# cursor.execute("set mapreduce.input.fileinputformat.input.dir.recursive=true")

# print('connect')

X_Client_Id= 'analytics-cdo' ### Change as per your org-namespace
X_Client_Secret= '6cbdc3cd-a3f7-43e1-a2f9-1935f6317c44' ### Change as per your org-namespace
user_name='shubham.v.vc' ### Change as per your username

# Alpha Query you want to pull
query = """
select
substr(sales_fact.order_date_key,1,6) as months,
sales_fact.analytic_business_unit,
sales_fact.analytic_super_category,
--TC
count(distinct(sales_fact.account_id)) as customers,  
--RC/NC
count(distinct(case when sales_fact.new_customer_flag = 1 then sales_fact.account_id end)) as nc,
count(distinct(case when sales_fact.new_customer_flag = 0 then sales_fact.account_id end)) as rc,
--Plus/Non-Plus
count(distinct(case when lower(sales_fact.user_lockin_state) ='active' then sales_fact.account_id end)) as Plus,
count(distinct(case when lower(sales_fact.user_lockin_state) !='active' then sales_fact.account_id end)) as Non_Plus,
--gender_tag
count(distinct(case	when lower(new_demograph.gender) = 'male' then sales_fact.account_id end)) as MALE,
count(distinct(case	when lower(new_demograph.gender) = 'female' then sales_fact.account_id end)) as FEMALE,
--marital_status
count(distinct(case	when lower(new_demograph.is_married)= 'yes' THEN sales_fact.account_id end)) as MARRIED,
count(distinct(case	when lower(new_demograph.is_married)= 'no' THEN sales_fact.account_id end)) as UNMARRIED,
--parental_status
count(distinct(case	when lower(new_demograph.is_parent)= 'yes' THEN sales_fact.account_id end)) as PARENT,
count(distinct(case	when lower(new_demograph.is_parent)= 'no' THEN sales_fact.account_id end)) as NOT_PARENT,
--student_status
count(distinct(case	when lower(new_demograph.is_student)= 'yes' THEN sales_fact.account_id end)) as STUDENT,
count(distinct(case	when lower(new_demograph.is_student)= 'no' THEN sales_fact.account_id end)) as NOT_STUDENT,
--age_flag
count(distinct(case	WHEN new_demograph.min_age >= 0 and new_demograph.max_age < 15 THEN sales_fact.account_id end)) as age_0_15,
count(distinct(case	WHEN new_demograph.min_age >= 15 and new_demograph.max_age < 25 THEN sales_fact.account_id end)) as age_15_25,
count(distinct(case	WHEN new_demograph.min_age >= 25 and new_demograph.max_age < 35 THEN sales_fact.account_id end)) as age_25_35,
count(distinct(case	WHEN new_demograph.min_age >= 35 and new_demograph.max_age < 45 THEN sales_fact.account_id end)) as age_35_45,
count(distinct(case	WHEN new_demograph.min_age >= 45 and new_demograph.max_age <= 100 THEN sales_fact.account_id end)) as age_45_100,

--Customer_section
0 as Premium,
-- count(distinct(case	when aff_seg.aff_segment = 'premium' then sales_fact.account_id end)) as Premium,
0 as Emerging_Premium,
-- count(distinct(case	when aff_seg.aff_segment = 'emerging_premium' then sales_fact.account_id end)) as Emerging_Premium,
0 as Mass,
--count(distinct(case	when aff_seg.aff_segment = 'mass' then sales_fact.account_id end)) as Mass,
0 as Entry,
--count(distinct(case	when aff_seg.aff_segment not in ('premium','emerging_premium','mass') then sales_fact.account_id end)) as Entry,


--category_type
count(distinct(case	when aff_cohort.affluence_score <= 0.25 then sales_fact.account_id end)) as Low_Aff,
count(distinct(case	when aff_cohort.affluence_score between 0.25 and 0.75 then sales_fact.account_id end)) as Mid_Aff,
count(distinct(case	when aff_cohort.affluence_score >= 0.75 then sales_fact.account_id end)) as High_Aff,
--cust_category
count(distinct(case	WHEN cust_fact_nn.account_id is not null THEN sales_fact.account_id end)) as NN_cust,
count(distinct(case	WHEN cust_fact_on.account_id is not null THEN sales_fact.account_id end)) as ON_cust,
count(distinct(sales_fact.account_id)) - count(distinct(case WHEN cust_fact_nn.account_id is not null THEN sales_fact.account_id end)) - count(distinct(case WHEN cust_fact_on.account_id is not null THEN sales_fact.account_id end)) as OO_cust,
--tpc_flag
count(distinct(case	WHEN base.trans_count >=1 and base.trans_count<=3 THEN sales_fact.account_id end)) as low_tpc,
count(distinct(case	WHEN base.trans_count >=4 and base.trans_count<=7 THEN sales_fact.account_id end)) as mid_tpc,
count(distinct(case	WHEN base.trans_count >=8 and base.trans_count<=12 THEN sales_fact.account_id end)) as high_tpc,
count(distinct(case	WHEN base.trans_count>12 THEN sales_fact.account_id end)) as very_high_tpc,
--MLE_CUSTOMER
sum(MLE_fact.mle_cust) as mle_cust,
count(distinct(case	WHEN cust_fact_oon.account_id is not null THEN sales_fact.account_id end)) as OON_cust
from
bigfoot_external_neo.cp_bi_prod_sales__forward_unit_history_fact as sales_fact

/*
left join
bigfoot_external_neo.analytics_cdo__FK_Aff_Segment_fact as aff_seg
on sales_fact.account_id = aff_seg.account_id
*/

left join
bigfoot_external_neo.cp_uie__Affluence_Cohort_Score_fact as aff_cohort
on sales_fact.account_id = aff_cohort.account_id
left join
bigfoot_external_neo.cp_uie__account_demographics_insight_beta_fact new_demograph
on sales_fact.account_id = new_demograph.account_id
left join
( 
	select 
		b.analytic_business_unit,
		b.account_id
	from
		bigfoot_external_neo.analytics_cdo__customer_insight_hive_fact b 
	inner join  
		bigfoot_external_neo.cp_bi_prod_sales__forward_unit_history_fact a
	on 
		a.order_item_id =b.order_item_id
	where 
		lower(a.status) in ('in_progress','undelivered','completed','delivered','approved','shipped','ready_to_ship','returned', 'return_requested','activated')
		and a.type !='service'
		and lower(a.marketplace_id)= 'flipkart'
		and a.category_id !=21726
		and a.category_id !=21651
		and a.is_freebie =false
		and (a.replacement_for_unit is null or a.replacement_for_unit='not_replacement')
		and (a.exchange_for_unit is null or a.exchange_for_unit='not_exchange')
		and is_shopsy_order = FALSE
		and a.order_date_key  between lookup_date(date_sub(date_sub(current_date,1),dayofmonth(date_sub(current_date,1))-1)) and lookup_date(date_sub(current_date,2))
		and lower(a.analytic_business_unit) in ('bgm','electronics','furniture','home','large','lifestyle','mobile')
		and b.new_cust_flag = 1
		group by
		b.analytic_business_unit,
		b.account_id
) as cust_fact_nn
on sales_fact.account_id=cust_fact_nn.account_id 
and sales_fact.analytic_business_unit = cust_fact_nn.analytic_business_unit
left join
( 
	select 
		b.analytic_business_unit,
		b.account_id
	from
		bigfoot_external_neo.analytics_cdo__customer_insight_hive_fact b 
	inner join  
		bigfoot_external_neo.cp_bi_prod_sales__forward_unit_history_fact a
	on 
		a.order_item_id =b.order_item_id
	where 
		lower(a.status) in ('in_progress','undelivered','completed','delivered','approved','shipped','ready_to_ship','returned', 'return_requested','activated')
		and a.type !='service'
		and lower(a.marketplace_id)= 'flipkart'
		and a.category_id !=21726
		and a.category_id !=21651
		and a.is_freebie =false
		and (a.replacement_for_unit is null or a.replacement_for_unit='not_replacement')
		and (a.exchange_for_unit is null or a.exchange_for_unit='not_exchange')
		and is_shopsy_order = FALSE
		and a.order_date_key between lookup_date(date_sub(date_sub(current_date,1),dayofmonth(date_sub(current_date,1))-1)) and lookup_date(date_sub(current_date,2))
		and lower(a.analytic_business_unit) in ('bgm','electronics','furniture','home','large','lifestyle','mobile')
		and b.new_cust_flag = 0
		and b.new_to_bu = 1
		group by
		b.analytic_business_unit,
		b.account_id
) as cust_fact_on
on sales_fact.account_id=cust_fact_on.account_id 
and sales_fact.analytic_business_unit = cust_fact_on.analytic_business_unit
left join
( 
	select 
		b.analytic_business_unit,
		b.account_id
	from
		bigfoot_external_neo.analytics_cdo__customer_insight_hive_fact b 
	inner join  
		bigfoot_external_neo.cp_bi_prod_sales__forward_unit_history_fact a
	on 
		a.order_item_id =b.order_item_id
	where 
		lower(a.status) in ('in_progress','undelivered','completed','delivered','approved','shipped','ready_to_ship','returned', 'return_requested','activated')
		and a.type !='service'
		and lower(a.marketplace_id)= 'flipkart'
		and a.category_id !=21726
		and a.category_id !=21651
		and a.is_freebie =false
		and (a.replacement_for_unit is null or a.replacement_for_unit='not_replacement')
		and (a.exchange_for_unit is null or a.exchange_for_unit='not_exchange')
		and is_shopsy_order = FALSE
		and a.order_date_key  between lookup_date(date_sub(date_sub(current_date,1),dayofmonth(date_sub(current_date,1))-1)) and lookup_date(date_sub(current_date,2))
		and lower(a.analytic_business_unit) in ('bgm','electronics','furniture','home','large','lifestyle','mobile')
		and b.new_cust_flag = 0
		and b.new_to_bu = 0
		and b.new_to_sc = 1
		group by
		b.analytic_business_unit,
		b.account_id
) as cust_fact_oon
on sales_fact.account_id=cust_fact_oon.account_id 
and sales_fact.analytic_business_unit = cust_fact_oon.analytic_business_unit
left join
(	
	select
	sa.account_id,
	sa.analytic_business_unit,
	count(distinct sa.order_external_id) as trans_count
	from
	bigfoot_external_neo.analytics_cdo__customer_insight_hive_fact sa
	where
	sa.approve_date_key between lookup_date(date_sub(date_sub(current_date,1),dayofmonth(date_sub(current_date,1))-1)) and lookup_date(date_sub(current_date,2))
	group by
	sa.account_id,
	sa.analytic_business_unit
) base
on sales_fact.account_id = base.account_id
left join
( 
	select
	a.months,
	a.account_id,
	count(distinct(a.account_id)) as mle_cust
	from
	(
		select
		substr(c.approve_date_key,1,6) as months,
		c.account_id
		from
		bigfoot_external_neo.analytics_cdo__customer_insight_hive_fact c
		where
	 	lower(c.analytic_business_unit) in ('mobile','large','electronics')
	 	and c.new_to_bu=1
	 	and c.approve_date_key between lookup_date(date_sub(date_sub(current_date,1),dayofmonth(date_sub(current_date,1))-1)) and lookup_date(date_sub(current_date,2))
		group by
	 	substr(c.approve_date_key,1,6),
	 	c.account_id
	) a
	left join
	(
		select
		substr(ca.approve_date_key,1,6) as months,
		ca.account_id
		from
		bigfoot_external_neo.analytics_cdo__customer_insight_hive_fact ca
		where
		lower(ca.analytic_business_unit) in ('mobile','large','electronics')
		and ca.new_to_bu=0
		and ca.approve_date_key between lookup_date(date_sub(date_sub(current_date,1),dayofmonth(date_sub(current_date,1))-1)) and lookup_date(date_sub(current_date,2))
		group by
		substr(ca.approve_date_key,1,6),
		ca.account_id
	) b
	on a.months = b.months and a.account_id = b.account_id
	where
	b.account_id is null
	group by
	a.months,
	a.account_id
) as MLE_fact
on MLE_fact.account_id = sales_fact.account_id
where
sales_fact.order_date_key between lookup_date(date_sub(date_sub(current_date,1),dayofmonth(date_sub(current_date,1))-1)) and lookup_date(date_sub(current_date,2))
and lower(sales_fact.analytic_business_unit) in ('bgm','electronics','furniture','home','large','lifestyle','mobile')
and lower(sales_fact.status) in ('in_progress','undelivered','completed','delivered','approved','shipped','ready_to_ship','returned', 'return_requested','activated')
and sales_fact.type !='service'
and sales_fact.category_id !=21726
and sales_fact.category_id !=21651
and sales_fact.replacement_for_unit is null
and sales_fact.exchange_for_unit is null
and sales_fact.is_freebie = false
and sales_fact.marketplace_id = 'FLIPKART'
and sales_fact.is_shopsy_order = false
group by
substr(sales_fact.order_date_key,1,6),
sales_fact.analytic_business_unit,
sales_fact.analytic_super_category

"""

url = 'http://validator.fdp-qaas-validator-prod.fkcloud.in/query/queries'


headers ={'Accept': '*', 'Content-Type': 'application/x-www-form-urlencoded',
          'Host': 'validator.fdp-qaas-validator-prod.fkcloud.in',
          'X-Client-Id': X_Client_Id, 
          'X-Client-Secret': X_Client_Secret,
          'x-authenticated-user':user_name 
          }
data ={'query':query,'sourceName':'HIVE'}

r = requests.post(url, headers=headers, data = data)
print(r.content)

print('r is: ',r)
print('If you get <Response [200]> above, that implies the url request was successful ')
query_handle_byte_dtype = r.content
# using decode() + loads() to convert to dictionary
query_handle_dict_dtype = json.loads(query_handle_byte_dtype.decode('utf-8'))
query_handle = query_handle_dict_dtype['queryHandle']['handle']
print("http://fdp.fkinternal.com/query/result/"+query_handle)

url = '  http://validator.fdp-qaas-validator-prod.fkcloud.in/query/queries/'+query_handle+'/status'


headers ={'Accept': '*', 'Content-Type': 'application/x-www-form-urlencoded',
          'Host': 'validator.fdp-qaas-validator-prod.fkcloud.in',
          'X-Client-Id': X_Client_Id, 
          'X-Client-Secret': X_Client_Secret,
          'x-authenticated-user':user_name 
          }
data ={'query':query,'sourceName':'HIVE'}

status_req = requests.get(url, headers=headers)

json.loads(status_req.content.decode('utf-8'))['status']
  
a = 0

while (a != 1):
    b=''
    status_req = requests.get(url, headers=headers)
    b = json.loads(status_req.content.decode('utf-8'))['status']    
    if b == 'SUCCESSFUL':
        a = 1
    else: 
        a = 0
    print(a)
    print('code still running')
    time.sleep(30)
    
print(status_req)

url_data_pull = 'http://validator.fdp-qaas-validator-prod.fkcloud.in/query/queries/'+ query_handle +'/downloadresults'


headers_data_pull ={'Accept': '*', 'Content-Type': 'application/x-www-form-urlencoded',
                    'Host': 'validator.fdp-qaas-validator-prod.fkcloud.in',
                    'X-Client-Id': X_Client_Id, 
          'X-Client-Secret': X_Client_Secret,
          'x-authenticated-user':user_name 
                   }

r_data_pull = requests.get(url_data_pull, headers=headers_data_pull)

query_output = r_data_pull.content

s=query_output.decode('utf-8')


data = StringIO(s) 

cust_data=pd.read_csv(data)

# gc=pygsheets.authorize(service_file='ShivankAutomation-fd5dab44a774.json')
# sh=gc.open('Life_Style_Data')

# data=sh[2]









# In[ ]:


cust_data


# In[ ]:


gc=pygsheets.authorize(service_file='ShivankAutomation-fd5dab44a774.json')
sh=gc.open('Customer Insights Dashboard')
worksheet=sh.worksheets().copy()
sheet_name = [s.title for s in worksheet]
data=sh[sheet_name.index('BUxSC_LEVEL')]
data.clear(start='A2', end='AK200000', fields="*")
data.set_dataframe(cust_data,(2,1),copy_head=False,copy_index=False)


# # For BUxSC level (Query 5 - Geo_level cuts)

# In[ ]:


import requests
import json
from io import StringIO
import time
import pandas as pd
import jaydebeapi
import os
import subprocess
import pandas as pd
import numpy as np
import datetime
import calendar
import pygsheets
import re
from datetime import date
import jaydebeapi
import os
import subprocess
import numpy as np
import datetime
import calendar
import pygsheets
import re

# output = subprocess.check_output(['bash', '-c', 'echo $CLASSPATH:/usr/local/fdp-infra-hive/lib/*'])
# os.environ['CLASSPATH'] = '/usr/local/fdp-infra-hive/lib/*'

# url = ("jdbc:hive2://fkp-fdp-galaxy-sun-zkjn-0001.c.fkp-fdp-galaxy.internal:2181,fkp-fdp-galaxy-sun-zkjn-0002.c.fkp-fdp-galaxy.internal:2181,fkp-fdp-galaxy-sun-zkjn-0003.c.fkp-fdp-galaxy.internal:2181/default;transportMode=http;httpPath=cliservice;serviceDiscoveryMode=zooKeeper;zooKeeperNamespace=fkp-fdp-galaxy-hive3-hs2-agni;hive.client.read.socket.timeout=300?hive.metastore.client.socket.timeout=180;hive.server.tcp.keepalive=true;hive.server.read.socket.timeout=300")
 
# print('Established JDBC connection---------------------')

# conn = jaydebeapi.connect("org.apache.hive.jdbc.HiveDriver", url,{'user': "mohammed.usama", 'password': "Khalid@170757"})

# print('Connected to hive server-------------------------')

# cursor = conn.cursor()
# cursor.execute("ADD JAR /usr/share/fk-bigfoot-hivejsonserde/json-serde-1.3-SNAPSHOT-jar-with-dependencies.jar")
# cursor.execute("ADD JAR /usr/share/fk-bigfoot-dimlookup/dimlookup-hive-udf-1.0-SNAPSHOT-jar-with-dependencies.jar")
# cursor.execute("ADD JAR gs://fkpdp-mhosy-2nig-1a5d-systemlibs/libraries/hive/jars/hive-udfs-1.0-SNAPSHOT.jar")
# cursor.execute("CREATE TEMPORARY FUNCTION lookup as 'com.flipkart.bigfoot.dimlookup.udf.HiveLookupUDF'")
# cursor.execute("CREATE TEMPORARY FUNCTION arrToString as 'com.flipkart.fdp.CustomCaster'")
# cursor.execute("CREATE TEMPORARY FUNCTION lookupkey as 'com.flipkart.bigfoot.dimlookup.udf.HiveKeyGeneratorUDF'")
# cursor.execute("CREATE TEMPORARY FUNCTION lookup_date as 'com.flipkart.bigfoot.dimlookup.udf.DateLookupUDF'")
# cursor.execute("CREATE TEMPORARY FUNCTION lookup_time as 'com.flipkart.bigfoot.dimlookup.udf.TimeLookupUDF'")
# cursor.execute("CREATE TEMPORARY FUNCTION aggregate_filter as 'com.flipkart.bigfoot.dimlookup.udf.AggregateConditionUDF'")
# cursor.execute("CREATE TEMPORARY FUNCTION aggregate as 'com.flipkart.bigfoot.dimlookup.udf.AggregateUDF'")
# cursor.execute("CREATE TEMPORARY FUNCTION ISOToSqlTs as 'com.flipkart.bigfoot.dimlookup.udf.DateISOToSqlUDF'")
# cursor.execute("CREATE TEMPORARY FUNCTION business_date_diff as 'com.flipkart.bigfoot.dimlookup.udf.BusinessDayDiffUDF'")

# cursor.execute("set mapreduce.input.fileinputformat.input.dir.recursive=true")

# print('connect')

X_Client_Id= 'analytics-cdo' ### Change as per your org-namespace
X_Client_Secret= '6cbdc3cd-a3f7-43e1-a2f9-1935f6317c44' ### Change as per your org-namespace
user_name='shubham.v.vc' ### Change as per your username

# Alpha Query you want to pull
query = """
select
substr(sales_fact.order_date_key,1,6) as year_month,
sales_fact.analytic_business_unit,
sales_fact.analytic_super_category,
case
when loc.city_tier = 'Metro' then "Metro"
when loc.city_tier = 'Tier 1A' or loc.city_tier='Tier 1B' then "Tier 1"
when loc.city_tier = 'Tier 2' then "Tier 2"
else "Tier 3 & Others"
end as tiers_flag,
case
when lower(loc.zone) = 'north' then "North"
when lower(loc.zone) = 'south' then "South"
when lower(loc.zone) = 'east' then "East"
else "West"
end as zone_flag,
afff.cohort as v3_affluence_signal,
CASE
WHEN (cust_fact.new_cust_flag=TRUE ) THEN 'NN'
WHEN (cust_fact.new_cust_flag=FALSE and cust_fact.new_to_bu=TRUE) THEN 'ON'
ELSE 'OO'
END as cust_category,
count(distinct(sales_fact.account_id)) as total_customers,
sum(sales_fact.units) as total_units,
sum(sales_fact.gmv) as total_gmv
from
bigfoot_external_neo.cp_bi_prod_sales__forward_unit_history_fact as sales_fact
left join
bigfoot_external_neo.scp_ekl__logistics_geo_hive_dim loc
on sales_fact.pincode = loc.pincode
left join 
bigfoot_external_neo.cp_uie__Affluence_V3_2_final_output_fact afff
on sales_fact.account_id = afff.account_id
left join
( 
    select 
    distinct order_id,
    new_cust_flag,
    new_to_bu 
    from
    bigfoot_external_neo.analytics_cdo__customer_insight_hive_fact
) as cust_fact
on sales_fact.order_id=cust_fact.order_id
where
sales_fact.order_date_key between lookup_date(date_sub(date_sub(current_date,1),dayofmonth(date_sub(current_date,1))-1)) and lookup_date(date_sub(current_date,2))
and lower(sales_fact.status) in ('in_progress','undelivered','completed','delivered','approved','shipped','ready_to_ship','returned', 'return_requested','activated')
and sales_fact.type != 'service'
and sales_fact.category_id != 21726
and sales_fact.category_id != 21651
and sales_fact.replacement_for_unit is null
and sales_fact.exchange_for_unit is null
and sales_fact.is_freebie = false
and sales_fact.is_shopsy_order = false
and lower(sales_fact.marketplace_id) in ('flipkart')
group by
substr(sales_fact.order_date_key,1,6),
sales_fact.analytic_business_unit,
sales_fact.analytic_super_category,
case
when loc.city_tier = 'Metro' then "Metro"
when loc.city_tier = 'Tier 1A' or loc.city_tier='Tier 1B' then "Tier 1"
when loc.city_tier = 'Tier 2' then "Tier 2"
else "Tier 3 & Others"
end,
case
when lower(loc.zone) = 'north' then "North"
when lower(loc.zone) = 'south' then "South"
when lower(loc.zone) = 'east' then "East"
else "West"
end,
afff.cohort,
CASE
WHEN (cust_fact.new_cust_flag=TRUE ) THEN 'NN'
WHEN (cust_fact.new_cust_flag=FALSE and cust_fact.new_to_bu=TRUE) THEN 'ON'
ELSE 'OO'
END
"""

url = 'http://validator.fdp-qaas-validator-prod.fkcloud.in/query/queries'


headers ={'Accept': '*', 'Content-Type': 'application/x-www-form-urlencoded',
          'Host': 'validator.fdp-qaas-validator-prod.fkcloud.in',
          'X-Client-Id': X_Client_Id, 
          'X-Client-Secret': X_Client_Secret,
          'x-authenticated-user':user_name 
          }
data ={'query':query,'sourceName':'HIVE'}

r = requests.post(url, headers=headers, data = data)
print(r.content)

print('r is: ',r)
print('If you get <Response [200]> above, that implies the url request was successful ')
query_handle_byte_dtype = r.content
# using decode() + loads() to convert to dictionary
query_handle_dict_dtype = json.loads(query_handle_byte_dtype.decode('utf-8'))
query_handle = query_handle_dict_dtype['queryHandle']['handle']
print("http://fdp.fkinternal.com/query/result/"+query_handle)

url = '  http://validator.fdp-qaas-validator-prod.fkcloud.in/query/queries/'+query_handle+'/status'


headers ={'Accept': '*', 'Content-Type': 'application/x-www-form-urlencoded',
          'Host': 'validator.fdp-qaas-validator-prod.fkcloud.in',
          'X-Client-Id': X_Client_Id, 
          'X-Client-Secret': X_Client_Secret,
          'x-authenticated-user':user_name 
          }
data ={'query':query,'sourceName':'HIVE'}

status_req = requests.get(url, headers=headers)

json.loads(status_req.content.decode('utf-8'))['status']
  
a = 0

while (a != 1):
    b=''
    status_req = requests.get(url, headers=headers)
    b = json.loads(status_req.content.decode('utf-8'))['status']    
    if b == 'SUCCESSFUL':
        a = 1
    else: 
        a = 0
    print(a)
    print('code still running')
    time.sleep(30)
    
print(status_req)

url_data_pull = 'http://validator.fdp-qaas-validator-prod.fkcloud.in/query/queries/'+ query_handle +'/downloadresults'


headers_data_pull ={'Accept': '*', 'Content-Type': 'application/x-www-form-urlencoded',
                    'Host': 'validator.fdp-qaas-validator-prod.fkcloud.in',
                    'X-Client-Id': X_Client_Id, 
          'X-Client-Secret': X_Client_Secret,
          'x-authenticated-user':user_name 
                   }

r_data_pull = requests.get(url_data_pull, headers=headers_data_pull)

query_output = r_data_pull.content

s=query_output.decode('utf-8')


data = StringIO(s) 

cust_data=pd.read_csv(data)

# gc=pygsheets.authorize(service_file='ShivankAutomation-fd5dab44a774.json')
# sh=gc.open('Life_Style_Data')

# data=sh[2]





# In[ ]:


cust_data


# In[ ]:


gc=pygsheets.authorize(service_file='ShivankAutomation-fd5dab44a774.json')
sh=gc.open('Customer Insights Dashboard')
worksheet=sh.worksheets().copy()
sheet_name = [s.title for s in worksheet]
data=sh[sheet_name.index('BUxSC_Level_Geo')]
data.clear(start='A2', end='J200000', fields="*")
data.set_dataframe(cust_data,(2,1),copy_head=False,copy_index=False)


# # For BUxSC level (Query 6 - m1_m2_level cuts)

# In[ ]:





# In[ ]:


from datetime import date
from datetime import datetime, timedelta
today=date.today()#-timedelta(days=15)
day1=today-timedelta(days=today.day)
end_day_main1='{:02d}'.format(day1.year)+'{:02d}'.format(day1.month)+'{:02d}'.format(day1.day)
start_day_main1='{:02d}'.format(day1.year)+'{:02d}'.format(day1.month)+'01'

day2=today-timedelta(days=today.day+day1.day)
end_day_main2='{:02d}'.format(day2.year)+'{:02d}'.format(day2.month)+'{:02d}'.format(day2.day)
start_day_main2='{:02d}'.format(day2.year)+'{:02d}'.format(day2.month)+'01'

day3=today-timedelta(days=today.day+day1.day+day2.day)
end_day_main3='{:02d}'.format(day3.year)+'{:02d}'.format(day3.month)+'{:02d}'.format(day3.day)
start_day_main3='{:02d}'.format(day3.year)+'{:02d}'.format(day3.month)+'01'

day4=today-timedelta(days=today.day+day1.day+day2.day+day3.day)
end_day_main4='{:02d}'.format(day4.year)+'{:02d}'.format(day4.month)+'{:02d}'.format(day4.day)
#start_day_main4='{:02d}'.format(day4.year)+'{:02d}'.format(day4.month)+'01'

day5=today-timedelta(days=today.day+day1.day+day2.day+day3.day+day4.day)
day6=today-timedelta(days=today.day+day1.day+day2.day+day3.day+day4.day+day5.day)
start_day_main6='{:02d}'.format(day6.year)+'{:02d}'.format(day6.month)+'01'

day7=today-timedelta(days=today.day+day1.day+day2.day+day3.day+day4.day+day5.day+day6.day)
end_day_main7='{:02d}'.format(day7.year)+'{:02d}'.format(day7.month)+'{:02d}'.format(day7.day)

day8=today-timedelta(days=today.day+day1.day+day2.day+day3.day+day4.day+day5.day+day6.day+day7.day)
day9=today-timedelta(days=today.day+day1.day+day2.day+day3.day+day4.day+day5.day+day6.day+day7.day+day8.day)
day10=today-timedelta(days=today.day+day1.day+day2.day+day3.day+day4.day+day5.day+day6.day+day7.day+day8.day+day9.day)
day11=today-timedelta(days=today.day+day1.day+day2.day+day3.day+day4.day+day5.day+day6.day+day7.day+day8.day+day9.day+day10.day)
day12=today-timedelta(days=today.day+day1.day+day2.day+day3.day+day4.day+day5.day+day6.day+day7.day+day8.day+day9.day+day10.day+day11.day)
start_day_main12='{:02d}'.format(day12.year)+'{:02d}'.format(day12.month)+'01'


# In[ ]:


# Repeat

import requests
import json
from io import StringIO
import time
import pandas as pd
import jaydebeapi
import os
import subprocess
import pandas as pd
import numpy as np
import datetime
import calendar
import pygsheets
import re
from datetime import date
import jaydebeapi
import os
import subprocess
import numpy as np
import datetime
import calendar
import pygsheets
import re

# output = subprocess.check_output(['bash', '-c', 'echo $CLASSPATH:/usr/local/fdp-infra-hive/lib/*'])
# os.environ['CLASSPATH'] = '/usr/local/fdp-infra-hive/lib/*'

# url = ("jdbc:hive2://fkp-fdp-galaxy-sun-zkjn-0001.c.fkp-fdp-galaxy.internal:2181,fkp-fdp-galaxy-sun-zkjn-0002.c.fkp-fdp-galaxy.internal:2181,fkp-fdp-galaxy-sun-zkjn-0003.c.fkp-fdp-galaxy.internal:2181/default;transportMode=http;httpPath=cliservice;serviceDiscoveryMode=zooKeeper;zooKeeperNamespace=fkp-fdp-galaxy-hive3-hs2-agni;hive.client.read.socket.timeout=300?hive.metastore.client.socket.timeout=180;hive.server.tcp.keepalive=true;hive.server.read.socket.timeout=300")
 
# print('Established JDBC connection---------------------')

# conn = jaydebeapi.connect("org.apache.hive.jdbc.HiveDriver", url,{'user': "mohammed.usama", 'password': "Khalid@170757"})

# print('Connected to hive server-------------------------')

# cursor = conn.cursor()
# cursor.execute("ADD JAR /usr/share/fk-bigfoot-hivejsonserde/json-serde-1.3-SNAPSHOT-jar-with-dependencies.jar")
# cursor.execute("ADD JAR /usr/share/fk-bigfoot-dimlookup/dimlookup-hive-udf-1.0-SNAPSHOT-jar-with-dependencies.jar")
# cursor.execute("ADD JAR gs://fkpdp-mhosy-2nig-1a5d-systemlibs/libraries/hive/jars/hive-udfs-1.0-SNAPSHOT.jar")
# cursor.execute("CREATE TEMPORARY FUNCTION lookup as 'com.flipkart.bigfoot.dimlookup.udf.HiveLookupUDF'")
# cursor.execute("CREATE TEMPORARY FUNCTION arrToString as 'com.flipkart.fdp.CustomCaster'")
# cursor.execute("CREATE TEMPORARY FUNCTION lookupkey as 'com.flipkart.bigfoot.dimlookup.udf.HiveKeyGeneratorUDF'")
# cursor.execute("CREATE TEMPORARY FUNCTION lookup_date as 'com.flipkart.bigfoot.dimlookup.udf.DateLookupUDF'")
# cursor.execute("CREATE TEMPORARY FUNCTION lookup_time as 'com.flipkart.bigfoot.dimlookup.udf.TimeLookupUDF'")
# cursor.execute("CREATE TEMPORARY FUNCTION aggregate_filter as 'com.flipkart.bigfoot.dimlookup.udf.AggregateConditionUDF'")
# cursor.execute("CREATE TEMPORARY FUNCTION aggregate as 'com.flipkart.bigfoot.dimlookup.udf.AggregateUDF'")
# cursor.execute("CREATE TEMPORARY FUNCTION ISOToSqlTs as 'com.flipkart.bigfoot.dimlookup.udf.DateISOToSqlUDF'")
# cursor.execute("CREATE TEMPORARY FUNCTION business_date_diff as 'com.flipkart.bigfoot.dimlookup.udf.BusinessDayDiffUDF'")

# cursor.execute("set mapreduce.input.fileinputformat.input.dir.recursive=true")

# print('connect')

X_Client_Id= 'analytics-cdo' ### Change as per your org-namespace
X_Client_Secret= '6cbdc3cd-a3f7-43e1-a2f9-1935f6317c44' ### Change as per your org-namespace
user_name='shubham.v.vc' ### Change as per your username

# Alpha Query you want to pull
query = """
select
    substr(a.order_date_key,1,6) as year_month,
    a.analytic_business_unit,
    a.analytic_super_category,
    sum(a.gmv) as gmv,
    sum(a.units) as units,
    count(distinct(a.account_id)) as customers,
case 
    when b.last  between """+ start_day_main1 + """ and """ + end_day_main1 + """
    then "M1"
    when b.last  between """+ start_day_main2 + """ and """ + end_day_main2 + """
    then "M2"
    when b.last  between """+ start_day_main3 + """ and """ + end_day_main3 + """
    then "M3"
    when b.last  between """+ start_day_main6 + """ and """ + end_day_main4 + """
    then "M4-6"
    when b.last  between """+ start_day_main12 + """ and """ + end_day_main7 + """
    then "M7-12 (Lapser)"
    when b.last  < """+ start_day_main12 + """
    then "Re activated"
    else "New"
end as repeat
from
(
    select
        order_date_key,analytic_business_unit,analytic_super_category,
        account_id,
        FLOOR((DayOfMonth(from_unixtime(unix_timestamp(cast(order_date_key as STRING), 'yyyyMMdd')))-1)/7)+1 as weekofmon,
        sum(gmv) as gmv,
        sum(units) as units,
        count(distinct(account_id)) 
    from
        bigfoot_external_neo.cp_bi_prod_sales__forward_unit_history_fact
    where
        lower(status) in ('in_progress','undelivered','completed','delivered','approved','shipped','ready_to_ship','returned', 'return_requested','activated')
        and type !='service'
        and category_id !=21726
        and category_id !=21651
        and order_date_key between lookup_date(date_sub(date_sub(current_date,1),dayofmonth(date_sub(current_date,1))-1)) and lookup_date(date_sub(current_date,2))
        and lower(marketplace_id) = 'flipkart'
        and (replacement_for_unit is null or replacement_for_unit='not_replacement')
        and (exchange_for_unit is null or exchange_for_unit='not_exchange')
        and is_freebie =false
        and is_shopsy_order = false
    group by
        order_date_key,analytic_business_unit,analytic_super_category,
        FLOOR((DayOfMonth(from_unixtime(unix_timestamp(cast(order_date_key as STRING), 'yyyyMMdd')))-1)/7)+1,
        account_id
) a
left join 
(
    select
        account_id,
        analytic_business_unit,
        max(approve_date_key) as last
    from
        bigfoot_external_neo.analytics_cdo__customer_insight_hive_fact
    where 
        approve_date_key < lookup_date(date_sub(date_sub(current_date,1),dayofmonth(date_sub(current_date,1))-1))
    group by 
        account_id,
        analytic_business_unit
 ) b
on a.account_id = b.account_id and a.analytic_business_unit = b.analytic_business_unit
group by
    substr(a.order_date_key,1,6),
    a.analytic_business_unit,a.analytic_super_category,
case 
    when b.last  between """+ start_day_main1 + """ and """ + end_day_main1 + """
    then "M1"
    when b.last  between """+ start_day_main2 + """ and """ + end_day_main2 + """
    then "M2"
    when b.last  between """+ start_day_main3 + """ and """ + end_day_main3 + """
    then "M3"
    when b.last  between """+ start_day_main6 + """ and """ + end_day_main4 + """
    then "M4-6"
    when b.last  between """+ start_day_main12 + """ and """ + end_day_main7 + """
    then "M7-12 (Lapser)"
    when b.last  < """+ start_day_main12 + """
    then "Re activated"
    else "New"
end
"""

url = 'http://validator.fdp-qaas-validator-prod.fkcloud.in/query/queries'


headers ={'Accept': '*', 'Content-Type': 'application/x-www-form-urlencoded',
          'Host': 'validator.fdp-qaas-validator-prod.fkcloud.in',
          'X-Client-Id': X_Client_Id, 
          'X-Client-Secret': X_Client_Secret,
          'x-authenticated-user':user_name 
          }
data ={'query':query,'sourceName':'HIVE'}

r = requests.post(url, headers=headers, data = data)
print(r.content)

print('r is: ',r)
print('If you get <Response [200]> above, that implies the url request was successful ')
query_handle_byte_dtype = r.content
# using decode() + loads() to convert to dictionary
query_handle_dict_dtype = json.loads(query_handle_byte_dtype.decode('utf-8'))
query_handle = query_handle_dict_dtype['queryHandle']['handle']
print("http://fdp.fkinternal.com/query/result/"+query_handle)

url = '  http://validator.fdp-qaas-validator-prod.fkcloud.in/query/queries/'+query_handle+'/status'


headers ={'Accept': '*', 'Content-Type': 'application/x-www-form-urlencoded',
          'Host': 'validator.fdp-qaas-validator-prod.fkcloud.in',
          'X-Client-Id': X_Client_Id, 
          'X-Client-Secret': X_Client_Secret,
          'x-authenticated-user':user_name 
          }
data ={'query':query,'sourceName':'HIVE'}

status_req = requests.get(url, headers=headers)

json.loads(status_req.content.decode('utf-8'))['status']
  
a = 0

while (a != 1):
    b=''
    status_req = requests.get(url, headers=headers)
    b = json.loads(status_req.content.decode('utf-8'))['status']    
    if b == 'SUCCESSFUL':
        a = 1
    else: 
        a = 0
    print(a)
    print('code still running')
    time.sleep(30)
    
print(status_req)

url_data_pull = 'http://validator.fdp-qaas-validator-prod.fkcloud.in/query/queries/'+ query_handle +'/downloadresults'


headers_data_pull ={'Accept': '*', 'Content-Type': 'application/x-www-form-urlencoded',
                    'Host': 'validator.fdp-qaas-validator-prod.fkcloud.in',
                    'X-Client-Id': X_Client_Id, 
          'X-Client-Secret': X_Client_Secret,
          'x-authenticated-user':user_name 
                   }

r_data_pull = requests.get(url_data_pull, headers=headers_data_pull)

query_output = r_data_pull.content

s=query_output.decode('utf-8')


data = StringIO(s) 

repeat=pd.read_csv(data)

# gc=pygsheets.authorize(service_file='ShivankAutomation-fd5dab44a774.json')
# sh=gc.open('Life_Style_Data')

# data=sh[2]


# In[ ]:


repeat


# In[ ]:


gc=pygsheets.authorize(service_file='ShivankAutomation-fd5dab44a774.json')
sh=gc.open('Customer Insights Dashboard')
worksheet=sh.worksheets().copy()
sheet_name = [s.title for s in worksheet]
data=sh[sheet_name.index('raw_data_m1_cuts')]
data.clear(start='A2', end='G200000', fields="*")
data.set_dataframe(repeat,(2,1),copy_head=False,copy_index=False)


# In[ ]:





# # Week On Week (Queries)

# # For BU level (Query 7 - WoW overall)

# In[ ]:


import requests
import json
from io import StringIO
import time
import pandas as pd
import jaydebeapi
import os
import subprocess
import pandas as pd
import numpy as np
import datetime
import calendar
import pygsheets
import re
from datetime import date
import jaydebeapi
import os
import subprocess
import numpy as np
import datetime
import calendar
import pygsheets
import re

# output = subprocess.check_output(['bash', '-c', 'echo $CLASSPATH:/usr/local/fdp-infra-hive/lib/*'])
# os.environ['CLASSPATH'] = '/usr/local/fdp-infra-hive/lib/*'

# url = ("jdbc:hive2://fkp-fdp-galaxy-sun-zkjn-0001.c.fkp-fdp-galaxy.internal:2181,fkp-fdp-galaxy-sun-zkjn-0002.c.fkp-fdp-galaxy.internal:2181,fkp-fdp-galaxy-sun-zkjn-0003.c.fkp-fdp-galaxy.internal:2181/default;transportMode=http;httpPath=cliservice;serviceDiscoveryMode=zooKeeper;zooKeeperNamespace=fkp-fdp-galaxy-hive3-hs2-agni;hive.client.read.socket.timeout=300?hive.metastore.client.socket.timeout=180;hive.server.tcp.keepalive=true;hive.server.read.socket.timeout=300")
 
# print('Established JDBC connection---------------------')

# conn = jaydebeapi.connect("org.apache.hive.jdbc.HiveDriver", url,{'user': "mohammed.usama", 'password': "Khalid@170757"})

# print('Connected to hive server-------------------------')

# cursor = conn.cursor()
# cursor.execute("ADD JAR /usr/share/fk-bigfoot-hivejsonserde/json-serde-1.3-SNAPSHOT-jar-with-dependencies.jar")
# cursor.execute("ADD JAR /usr/share/fk-bigfoot-dimlookup/dimlookup-hive-udf-1.0-SNAPSHOT-jar-with-dependencies.jar")
# cursor.execute("ADD JAR gs://fkpdp-mhosy-2nig-1a5d-systemlibs/libraries/hive/jars/hive-udfs-1.0-SNAPSHOT.jar")
# cursor.execute("CREATE TEMPORARY FUNCTION lookup as 'com.flipkart.bigfoot.dimlookup.udf.HiveLookupUDF'")
# cursor.execute("CREATE TEMPORARY FUNCTION arrToString as 'com.flipkart.fdp.CustomCaster'")
# cursor.execute("CREATE TEMPORARY FUNCTION lookupkey as 'com.flipkart.bigfoot.dimlookup.udf.HiveKeyGeneratorUDF'")
# cursor.execute("CREATE TEMPORARY FUNCTION lookup_date as 'com.flipkart.bigfoot.dimlookup.udf.DateLookupUDF'")
# cursor.execute("CREATE TEMPORARY FUNCTION lookup_time as 'com.flipkart.bigfoot.dimlookup.udf.TimeLookupUDF'")
# cursor.execute("CREATE TEMPORARY FUNCTION aggregate_filter as 'com.flipkart.bigfoot.dimlookup.udf.AggregateConditionUDF'")
# cursor.execute("CREATE TEMPORARY FUNCTION aggregate as 'com.flipkart.bigfoot.dimlookup.udf.AggregateUDF'")
# cursor.execute("CREATE TEMPORARY FUNCTION ISOToSqlTs as 'com.flipkart.bigfoot.dimlookup.udf.DateISOToSqlUDF'")
# cursor.execute("CREATE TEMPORARY FUNCTION business_date_diff as 'com.flipkart.bigfoot.dimlookup.udf.BusinessDayDiffUDF'")

# cursor.execute("set mapreduce.input.fileinputformat.input.dir.recursive=true")

# print('connect')

X_Client_Id= 'analytics-cdo' ### Change as per your org-namespace
X_Client_Secret= '6cbdc3cd-a3f7-43e1-a2f9-1935f6317c44' ### Change as per your org-namespace
user_name='shubham.v.vc' ### Change as per your username

# Alpha Query you want to pull
query = """
select
dt.week_num_in_year as week_num,
sales_fact.analytic_business_unit,
--TC
count(distinct(sales_fact.account_id)) as customers,  
--RC/NC
count(distinct(case when sales_fact.new_customer_flag = 1 then sales_fact.account_id end)) as nc,
count(distinct(case when sales_fact.new_customer_flag = 0 then sales_fact.account_id end)) as rc,
--Plus/Non-Plus
count(distinct(case when lower(sales_fact.user_lockin_state) ='active' then sales_fact.account_id end)) as Plus,
count(distinct(case when lower(sales_fact.user_lockin_state) !='active' then sales_fact.account_id end)) as Non_Plus,
--gender_tag
count(distinct(case when lower(new_demograph.gender) = 'male' then sales_fact.account_id end)) as MALE,
count(distinct(case when lower(new_demograph.gender) = 'female' then sales_fact.account_id end)) as FEMALE,
--marital_status
count(distinct(case when lower(new_demograph.is_married)= 'yes' THEN sales_fact.account_id end)) as MARRIED,
count(distinct(case when lower(new_demograph.is_married)= 'no' THEN sales_fact.account_id end)) as UNMARRIED,
--parental_status
count(distinct(case when lower(new_demograph.is_parent)= 'yes' THEN sales_fact.account_id end)) as PARENT,
count(distinct(case when lower(new_demograph.is_parent)= 'no' THEN sales_fact.account_id end)) as NOT_PARENT,
--student_status
count(distinct(case when lower(new_demograph.is_student)= 'yes' THEN sales_fact.account_id end)) as STUDENT,
count(distinct(case when lower(new_demograph.is_student)= 'no' THEN sales_fact.account_id end)) as NOT_STUDENT,
--age_flag
count(distinct(case WHEN new_demograph.min_age >= 0 and new_demograph.max_age < 15 THEN sales_fact.account_id end)) as age_0_15,
count(distinct(case WHEN new_demograph.min_age >= 15 and new_demograph.max_age < 25 THEN sales_fact.account_id end)) as age_15_25,
count(distinct(case WHEN new_demograph.min_age >= 25 and new_demograph.max_age < 35 THEN sales_fact.account_id end)) as age_25_35,
count(distinct(case WHEN new_demograph.min_age >= 35 and new_demograph.max_age < 45 THEN sales_fact.account_id end)) as age_35_45,
count(distinct(case WHEN new_demograph.min_age >= 45 and new_demograph.max_age <= 100 THEN sales_fact.account_id end)) as age_45_100,

--Customer_section
0 as Premium,
-- count(distinct(case	when aff_seg.aff_segment = 'premium' then sales_fact.account_id end)) as Premium,
0 as Emerging_Premium,
-- count(distinct(case	when aff_seg.aff_segment = 'emerging_premium' then sales_fact.account_id end)) as Emerging_Premium,
0 as Mass,
--count(distinct(case	when aff_seg.aff_segment = 'mass' then sales_fact.account_id end)) as Mass,
0 as Entry,
--count(distinct(case	when aff_seg.aff_segment not in ('premium','emerging_premium','mass') then sales_fact.account_id end)) as Entry,



--category_type
count(distinct(case when aff_cohort.affluence_score <= 0.25 then sales_fact.account_id end)) as Low_Aff,
count(distinct(case when aff_cohort.affluence_score between 0.25 and 0.75 then sales_fact.account_id end)) as Mid_Aff,
count(distinct(case when aff_cohort.affluence_score >= 0.75 then sales_fact.account_id end)) as High_Aff,
--cust_category
count(distinct(case WHEN cust_fact_nn.account_id is not null THEN sales_fact.account_id end)) as NN_cust,
count(distinct(case WHEN cust_fact_on.account_id is not null THEN sales_fact.account_id end)) as ON_cust,
count(distinct(sales_fact.account_id)) - count(distinct(case WHEN cust_fact_nn.account_id is not null THEN sales_fact.account_id end)) - count(distinct(case WHEN cust_fact_on.account_id is not null THEN sales_fact.account_id end)) as OO_cust,
--tpc_flag
count(distinct(case WHEN base.trans_count >=1 and base.trans_count<=3 THEN sales_fact.account_id end)) as low_tpc,
count(distinct(case WHEN base.trans_count >=4 and base.trans_count<=7 THEN sales_fact.account_id end)) as mid_tpc,
count(distinct(case WHEN base.trans_count >=8 and base.trans_count<=12 THEN sales_fact.account_id end)) as high_tpc,
count(distinct(case WHEN base.trans_count>12 THEN sales_fact.account_id end)) as very_high_tpc,
--MLE_CUSTOMER
sum(MLE_fact.mle_cust) as mle_cust
from
bigfoot_external_neo.cp_bi_prod_sales__forward_unit_history_fact as sales_fact
left join 
	(select 
		distinct date_dim_key,week_num_in_year
	from
		bigfoot_external_neo.scp_oms__date_dim_fact ) dt 
on 
	sales_fact.order_date_key = dt.date_dim_key
/*
left join
bigfoot_external_neo.analytics_cdo__FK_Aff_Segment_fact as aff_seg
on sales_fact.account_id = aff_seg.account_id
*/
left join
bigfoot_external_neo.cp_uie__Affluence_Cohort_Score_fact as aff_cohort
on sales_fact.account_id = aff_cohort.account_id
left join
bigfoot_external_neo.cp_uie__account_demographics_insight_beta_fact new_demograph
on sales_fact.account_id = new_demograph.account_id
left join
( 
	select 
		b.analytic_business_unit,
		b.account_id
	from
		bigfoot_external_neo.analytics_cdo__customer_insight_hive_fact b 
	inner join  
		bigfoot_external_neo.cp_bi_prod_sales__forward_unit_history_fact a
	on 
		a.order_item_id =b.order_item_id
	where 
		lower(a.status) in ('in_progress','undelivered','completed','delivered','approved','shipped','ready_to_ship','returned', 'return_requested','activated')
		and a.type !='service'
		and lower(a.marketplace_id)= 'flipkart'
		and a.category_id !=21726
		and a.category_id !=21651
		and a.is_freebie =false
		and (a.replacement_for_unit is null or a.replacement_for_unit='not_replacement')
		and (a.exchange_for_unit is null or a.exchange_for_unit='not_exchange')
		and is_shopsy_order = FALSE
		and a.order_date_key  between lookup_date(date_sub(current_date,49)) and lookup_date(date_sub(current_date,2))  -- change as per week req.
		and lower(a.analytic_business_unit) in ('bgm','electronics','furniture','home','large','lifestyle','mobile')
		and b.new_cust_flag = 1
		group by
		b.analytic_business_unit,
		b.account_id
) as cust_fact_nn
on sales_fact.account_id=cust_fact_nn.account_id 
and sales_fact.analytic_business_unit = cust_fact_nn.analytic_business_unit
left join
( 
	select 
		b.analytic_business_unit,
		b.account_id
	from
		bigfoot_external_neo.analytics_cdo__customer_insight_hive_fact b 
	inner join  
		bigfoot_external_neo.cp_bi_prod_sales__forward_unit_history_fact a
	on 
		a.order_item_id =b.order_item_id
	where 
		lower(a.status) in ('in_progress','undelivered','completed','delivered','approved','shipped','ready_to_ship','returned', 'return_requested','activated')
		and a.type !='service'
		and lower(a.marketplace_id)= 'flipkart'
		and a.category_id !=21726
		and a.category_id !=21651
		and a.is_freebie =false
		and (a.replacement_for_unit is null or a.replacement_for_unit='not_replacement')
		and (a.exchange_for_unit is null or a.exchange_for_unit='not_exchange')
		and is_shopsy_order = FALSE
		and a.order_date_key  between lookup_date(date_sub(current_date,49)) and lookup_date(date_sub(current_date,2))  -- change as per week req.
		and lower(a.analytic_business_unit) in ('bgm','electronics','furniture','home','large','lifestyle','mobile')
		and b.new_cust_flag = 0
		and b.new_to_bu = 1
		group by
		b.analytic_business_unit,
		b.account_id
) as cust_fact_on
on sales_fact.account_id=cust_fact_on.account_id 
and sales_fact.analytic_business_unit = cust_fact_on.analytic_business_unit
left join
(	
	select
	sa.account_id,
	sa.analytic_business_unit,
	count(distinct sa.order_external_id) as trans_count
	from
	bigfoot_external_neo.analytics_cdo__customer_insight_hive_fact sa
	where
	sa.approve_date_key between lookup_date(date_sub(current_date,49)) and lookup_date(date_sub(current_date,2))  -- change as per week req.
	group by
	sa.account_id,
	sa.analytic_business_unit
) base
on sales_fact.account_id = base.account_id
left join
( 
	select
	a.months,
	a.account_id,
	count(distinct(a.account_id)) as mle_cust
	from
	(
		select
		substr(c.approve_date_key,1,6) as months,
		c.account_id
		from
		bigfoot_external_neo.analytics_cdo__customer_insight_hive_fact c
		where
	 	lower(c.analytic_business_unit) in ('mobile','large','electronics')
	 	and c.new_to_bu=1
	 	and c.approve_date_key between lookup_date(date_sub(current_date,49)) and lookup_date(date_sub(current_date,2))  -- change as per week req.
		group by
	 	substr(c.approve_date_key,1,6),
	 	c.account_id
	) a
	left join
	(
		select
		substr(ca.approve_date_key,1,6) as months,
		ca.account_id
		from
		bigfoot_external_neo.analytics_cdo__customer_insight_hive_fact ca
		where
		lower(ca.analytic_business_unit) in ('mobile','large','electronics')
		and ca.new_to_bu=0
		and ca.approve_date_key between lookup_date(date_sub(current_date,49)) and lookup_date(date_sub(current_date,2))  -- change as per week req.
		group by
		substr(ca.approve_date_key,1,6),
		ca.account_id
	) b
	on a.months = b.months and a.account_id = b.account_id
	where
	b.account_id is null
	group by
	a.months,
	a.account_id
) as MLE_fact
on MLE_fact.account_id = sales_fact.account_id
where
sales_fact.order_date_key between lookup_date(date_sub(current_date,49)) and lookup_date(date_sub(current_date,2))  -- change as per week req.
and lower(sales_fact.analytic_business_unit) in ('bgm','electronics','furniture','home','large','lifestyle','mobile')
and lower(sales_fact.status) in ('in_progress','undelivered','completed','delivered','approved','shipped','ready_to_ship','returned', 'return_requested','activated')
and sales_fact.type !='service'
and sales_fact.category_id !=21726
and sales_fact.category_id !=21651
and sales_fact.replacement_for_unit is null
and sales_fact.exchange_for_unit is null
and sales_fact.is_freebie = false
and sales_fact.marketplace_id = 'FLIPKART'
and sales_fact.is_shopsy_order = false
group by
dt.week_num_in_year,
sales_fact.analytic_business_unit

"""

url = 'http://validator.fdp-qaas-validator-prod.fkcloud.in/query/queries'


headers ={'Accept': '*', 'Content-Type': 'application/x-www-form-urlencoded',
          'Host': 'validator.fdp-qaas-validator-prod.fkcloud.in',
          'X-Client-Id': X_Client_Id, 
          'X-Client-Secret': X_Client_Secret,
          'x-authenticated-user':user_name 
          }
data ={'query':query,'sourceName':'HIVE'}

r = requests.post(url, headers=headers, data = data)
print(r.content)

print('r is: ',r)
print('If you get <Response [200]> above, that implies the url request was successful ')
query_handle_byte_dtype = r.content
# using decode() + loads() to convert to dictionary
query_handle_dict_dtype = json.loads(query_handle_byte_dtype.decode('utf-8'))
query_handle = query_handle_dict_dtype['queryHandle']['handle']
print("http://fdp.fkinternal.com/query/result/"+query_handle)

url = '  http://validator.fdp-qaas-validator-prod.fkcloud.in/query/queries/'+query_handle+'/status'


headers ={'Accept': '*', 'Content-Type': 'application/x-www-form-urlencoded',
          'Host': 'validator.fdp-qaas-validator-prod.fkcloud.in',
          'X-Client-Id': X_Client_Id, 
          'X-Client-Secret': X_Client_Secret,
          'x-authenticated-user':user_name 
          }
data ={'query':query,'sourceName':'HIVE'}

status_req = requests.get(url, headers=headers)

json.loads(status_req.content.decode('utf-8'))['status']
  
a = 0

while (a != 1):
    b=''
    status_req = requests.get(url, headers=headers)
    b = json.loads(status_req.content.decode('utf-8'))['status']    
    if b == 'SUCCESSFUL':
        a = 1
    else: 
        a = 0
    print(a)
    print('code still running')
    time.sleep(30)
    
print(status_req)

url_data_pull = 'http://validator.fdp-qaas-validator-prod.fkcloud.in/query/queries/'+ query_handle +'/downloadresults'


headers_data_pull ={'Accept': '*', 'Content-Type': 'application/x-www-form-urlencoded',
                    'Host': 'validator.fdp-qaas-validator-prod.fkcloud.in',
                    'X-Client-Id': X_Client_Id, 
          'X-Client-Secret': X_Client_Secret,
          'x-authenticated-user':user_name 
                   }

r_data_pull = requests.get(url_data_pull, headers=headers_data_pull)

query_output = r_data_pull.content

s=query_output.decode('utf-8')


data = StringIO(s) 

cust_data=pd.read_csv(data)

# gc=pygsheets.authorize(service_file='ShivankAutomation-fd5dab44a774.json')
# sh=gc.open('Life_Style_Data')

# data=sh[2]


# In[ ]:


cust_data


# In[ ]:


gc=pygsheets.authorize(service_file='ShivankAutomation-fd5dab44a774.json')
sh=gc.open('WOW_Customer_Dashboard')
worksheet=sh.worksheets().copy()
sheet_name = [s.title for s in worksheet]
data=sh[sheet_name.index('BU_Level')]
data.clear(start='A2', end='AI100000', fields="*")
data.set_dataframe(cust_data,(2,1),copy_head=False,copy_index=False)


# # For BU level (Query 8 - WoW Geo_Level)

# In[ ]:


import requests
import json
from io import StringIO
import time
import pandas as pd
import jaydebeapi
import os
import subprocess
import pandas as pd
import numpy as np
import datetime
import calendar
import pygsheets
import re
from datetime import date
import jaydebeapi
import os
import subprocess
import numpy as np
import datetime
import calendar
import pygsheets
import re

# output = subprocess.check_output(['bash', '-c', 'echo $CLASSPATH:/usr/local/fdp-infra-hive/lib/*'])
# os.environ['CLASSPATH'] = '/usr/local/fdp-infra-hive/lib/*'

# url = ("jdbc:hive2://fkp-fdp-galaxy-sun-zkjn-0001.c.fkp-fdp-galaxy.internal:2181,fkp-fdp-galaxy-sun-zkjn-0002.c.fkp-fdp-galaxy.internal:2181,fkp-fdp-galaxy-sun-zkjn-0003.c.fkp-fdp-galaxy.internal:2181/default;transportMode=http;httpPath=cliservice;serviceDiscoveryMode=zooKeeper;zooKeeperNamespace=fkp-fdp-galaxy-hive3-hs2-agni;hive.client.read.socket.timeout=300?hive.metastore.client.socket.timeout=180;hive.server.tcp.keepalive=true;hive.server.read.socket.timeout=300")
 
# print('Established JDBC connection---------------------')

# conn = jaydebeapi.connect("org.apache.hive.jdbc.HiveDriver", url,{'user': "mohammed.usama", 'password': "Khalid@170757"})

# print('Connected to hive server-------------------------')

# cursor = conn.cursor()
# cursor.execute("ADD JAR /usr/share/fk-bigfoot-hivejsonserde/json-serde-1.3-SNAPSHOT-jar-with-dependencies.jar")
# cursor.execute("ADD JAR /usr/share/fk-bigfoot-dimlookup/dimlookup-hive-udf-1.0-SNAPSHOT-jar-with-dependencies.jar")
# cursor.execute("ADD JAR gs://fkpdp-mhosy-2nig-1a5d-systemlibs/libraries/hive/jars/hive-udfs-1.0-SNAPSHOT.jar")
# cursor.execute("CREATE TEMPORARY FUNCTION lookup as 'com.flipkart.bigfoot.dimlookup.udf.HiveLookupUDF'")
# cursor.execute("CREATE TEMPORARY FUNCTION arrToString as 'com.flipkart.fdp.CustomCaster'")
# cursor.execute("CREATE TEMPORARY FUNCTION lookupkey as 'com.flipkart.bigfoot.dimlookup.udf.HiveKeyGeneratorUDF'")
# cursor.execute("CREATE TEMPORARY FUNCTION lookup_date as 'com.flipkart.bigfoot.dimlookup.udf.DateLookupUDF'")
# cursor.execute("CREATE TEMPORARY FUNCTION lookup_time as 'com.flipkart.bigfoot.dimlookup.udf.TimeLookupUDF'")
# cursor.execute("CREATE TEMPORARY FUNCTION aggregate_filter as 'com.flipkart.bigfoot.dimlookup.udf.AggregateConditionUDF'")
# cursor.execute("CREATE TEMPORARY FUNCTION aggregate as 'com.flipkart.bigfoot.dimlookup.udf.AggregateUDF'")
# cursor.execute("CREATE TEMPORARY FUNCTION ISOToSqlTs as 'com.flipkart.bigfoot.dimlookup.udf.DateISOToSqlUDF'")
# cursor.execute("CREATE TEMPORARY FUNCTION business_date_diff as 'com.flipkart.bigfoot.dimlookup.udf.BusinessDayDiffUDF'")

# cursor.execute("set mapreduce.input.fileinputformat.input.dir.recursive=true")

# print('connect')

X_Client_Id= 'analytics-cdo' ### Change as per your org-namespace
X_Client_Secret= '6cbdc3cd-a3f7-43e1-a2f9-1935f6317c44' ### Change as per your org-namespace
user_name='shubham.v.vc' ### Change as per your username

# Alpha Query you want to pull
query = """
select
dt.week_num_in_year as week_num,
sales_fact.analytic_business_unit,
case
when loc.city_tier = 'Metro' then "Metro"
when loc.city_tier = 'Tier 1A' or loc.city_tier='Tier 1B' then "Tier 1"
when loc.city_tier = 'Tier 2' then "Tier 2"
else "Tier 3 & Others"
end as tiers_flag,
case
when lower(loc.zone) = 'north' then "North"
when lower(loc.zone) = 'south' then "South"
when lower(loc.zone) = 'east' then "East"
else "West"
end as zone_flag,
afff.cohort as v3_affluence_signal,
CASE
WHEN (cust_fact.new_cust_flag=TRUE ) THEN 'NN'
WHEN (cust_fact.new_cust_flag=FALSE and cust_fact.new_to_bu=TRUE) THEN 'ON'
ELSE 'OO'
END as cust_category,
count(distinct(sales_fact.account_id)) as total_customers,
sum(sales_fact.units) as total_units,
sum(sales_fact.gmv) as total_gmv
from
bigfoot_external_neo.cp_bi_prod_sales__forward_unit_history_fact as sales_fact
left join 
	(select 
		distinct date_dim_key,week_num_in_year
	from
		bigfoot_external_neo.scp_oms__date_dim_fact ) dt 
on 
	sales_fact.order_date_key = dt.date_dim_key
left join
bigfoot_external_neo.scp_ekl__logistics_geo_hive_dim loc
on sales_fact.pincode = loc.pincode
left join 
bigfoot_external_neo.cp_uie__Affluence_V3_2_final_output_fact afff
on sales_fact.account_id = afff.account_id
left join
( 
    select 
    distinct order_id,
    new_cust_flag,
    new_to_bu 
    from
    bigfoot_external_neo.analytics_cdo__customer_insight_hive_fact
) as cust_fact
on sales_fact.order_id=cust_fact.order_id
where
sales_fact.order_date_key between lookup_date(date_sub(current_date,49)) and lookup_date(date_sub(current_date,2))  -- change as per week req.
and lower(sales_fact.status) in ('in_progress','undelivered','completed','delivered','approved','shipped','ready_to_ship','returned', 'return_requested','activated')
and sales_fact.type != 'service'
and sales_fact.category_id != 21726
and sales_fact.category_id != 21651
and sales_fact.replacement_for_unit is null
and sales_fact.exchange_for_unit is null
and sales_fact.is_freebie = false
and sales_fact.is_shopsy_order = false
and lower(sales_fact.marketplace_id) in ('flipkart')
group by
dt.week_num_in_year,
sales_fact.analytic_business_unit,
case
when loc.city_tier = 'Metro' then "Metro"
when loc.city_tier = 'Tier 1A' or loc.city_tier='Tier 1B' then "Tier 1"
when loc.city_tier = 'Tier 2' then "Tier 2"
else "Tier 3 & Others"
end,
case
when lower(loc.zone) = 'north' then "North"
when lower(loc.zone) = 'south' then "South"
when lower(loc.zone) = 'east' then "East"
else "West"
end,
afff.cohort,
CASE
WHEN (cust_fact.new_cust_flag=TRUE ) THEN 'NN'
WHEN (cust_fact.new_cust_flag=FALSE and cust_fact.new_to_bu=TRUE) THEN 'ON'
ELSE 'OO'
END

"""

url = 'http://validator.fdp-qaas-validator-prod.fkcloud.in/query/queries'


headers ={'Accept': '*', 'Content-Type': 'application/x-www-form-urlencoded',
          'Host': 'validator.fdp-qaas-validator-prod.fkcloud.in',
          'X-Client-Id': X_Client_Id, 
          'X-Client-Secret': X_Client_Secret,
          'x-authenticated-user':user_name 
          }
data ={'query':query,'sourceName':'HIVE'}

r = requests.post(url, headers=headers, data = data)
print(r.content)

print('r is: ',r)
print('If you get <Response [200]> above, that implies the url request was successful ')
query_handle_byte_dtype = r.content
# using decode() + loads() to convert to dictionary
query_handle_dict_dtype = json.loads(query_handle_byte_dtype.decode('utf-8'))
query_handle = query_handle_dict_dtype['queryHandle']['handle']
print("http://fdp.fkinternal.com/query/result/"+query_handle)

url = '  http://validator.fdp-qaas-validator-prod.fkcloud.in/query/queries/'+query_handle+'/status'


headers ={'Accept': '*', 'Content-Type': 'application/x-www-form-urlencoded',
          'Host': 'validator.fdp-qaas-validator-prod.fkcloud.in',
          'X-Client-Id': X_Client_Id, 
          'X-Client-Secret': X_Client_Secret,
          'x-authenticated-user':user_name 
          }
data ={'query':query,'sourceName':'HIVE'}

status_req = requests.get(url, headers=headers)

json.loads(status_req.content.decode('utf-8'))['status']
  
a = 0

while (a != 1):
    b=''
    status_req = requests.get(url, headers=headers)
    b = json.loads(status_req.content.decode('utf-8'))['status']    
    if b == 'SUCCESSFUL':
        a = 1
    else: 
        a = 0
    print(a)
    print('code still running')
    time.sleep(30)
    
print(status_req)

url_data_pull = 'http://validator.fdp-qaas-validator-prod.fkcloud.in/query/queries/'+ query_handle +'/downloadresults'


headers_data_pull ={'Accept': '*', 'Content-Type': 'application/x-www-form-urlencoded',
                    'Host': 'validator.fdp-qaas-validator-prod.fkcloud.in',
                    'X-Client-Id': X_Client_Id, 
          'X-Client-Secret': X_Client_Secret,
          'x-authenticated-user':user_name 
                   }

r_data_pull = requests.get(url_data_pull, headers=headers_data_pull)

query_output = r_data_pull.content

s=query_output.decode('utf-8')


data = StringIO(s) 

cust_data=pd.read_csv(data)

# gc=pygsheets.authorize(service_file='ShivankAutomation-fd5dab44a774.json')
# sh=gc.open('Life_Style_Data')

# data=sh[2]





# In[ ]:


cust_data


# In[ ]:


gc=pygsheets.authorize(service_file='ShivankAutomation-fd5dab44a774.json')
sh=gc.open('WOW_Customer_Dashboard')
worksheet=sh.worksheets().copy()
sheet_name = [s.title for s in worksheet]
data=sh[sheet_name.index('BU_Level_Geo')]
data.clear(start='A2', end='I100000', fields="*")
data.set_dataframe(cust_data,(2,1),copy_head=False,copy_index=False)


# # For BUxSC level (Query 9 - WoW Overall_Level)

# In[ ]:


import requests
import json
from io import StringIO
import time
import pandas as pd
import jaydebeapi
import os
import subprocess
import pandas as pd
import numpy as np
import datetime
import calendar
import pygsheets
import re
from datetime import date
import jaydebeapi
import os
import subprocess
import numpy as np
import datetime
import calendar
import pygsheets
import re

# output = subprocess.check_output(['bash', '-c', 'echo $CLASSPATH:/usr/local/fdp-infra-hive/lib/*'])
# os.environ['CLASSPATH'] = '/usr/local/fdp-infra-hive/lib/*'

# url = ("jdbc:hive2://fkp-fdp-galaxy-sun-zkjn-0001.c.fkp-fdp-galaxy.internal:2181,fkp-fdp-galaxy-sun-zkjn-0002.c.fkp-fdp-galaxy.internal:2181,fkp-fdp-galaxy-sun-zkjn-0003.c.fkp-fdp-galaxy.internal:2181/default;transportMode=http;httpPath=cliservice;serviceDiscoveryMode=zooKeeper;zooKeeperNamespace=fkp-fdp-galaxy-hive3-hs2-agni;hive.client.read.socket.timeout=300?hive.metastore.client.socket.timeout=180;hive.server.tcp.keepalive=true;hive.server.read.socket.timeout=300")
 
# print('Established JDBC connection---------------------')

# conn = jaydebeapi.connect("org.apache.hive.jdbc.HiveDriver", url,{'user': "mohammed.usama", 'password': "Khalid@170757"})

# print('Connected to hive server-------------------------')

# cursor = conn.cursor()
# cursor.execute("ADD JAR /usr/share/fk-bigfoot-hivejsonserde/json-serde-1.3-SNAPSHOT-jar-with-dependencies.jar")
# cursor.execute("ADD JAR /usr/share/fk-bigfoot-dimlookup/dimlookup-hive-udf-1.0-SNAPSHOT-jar-with-dependencies.jar")
# cursor.execute("ADD JAR gs://fkpdp-mhosy-2nig-1a5d-systemlibs/libraries/hive/jars/hive-udfs-1.0-SNAPSHOT.jar")
# cursor.execute("CREATE TEMPORARY FUNCTION lookup as 'com.flipkart.bigfoot.dimlookup.udf.HiveLookupUDF'")
# cursor.execute("CREATE TEMPORARY FUNCTION arrToString as 'com.flipkart.fdp.CustomCaster'")
# cursor.execute("CREATE TEMPORARY FUNCTION lookupkey as 'com.flipkart.bigfoot.dimlookup.udf.HiveKeyGeneratorUDF'")
# cursor.execute("CREATE TEMPORARY FUNCTION lookup_date as 'com.flipkart.bigfoot.dimlookup.udf.DateLookupUDF'")
# cursor.execute("CREATE TEMPORARY FUNCTION lookup_time as 'com.flipkart.bigfoot.dimlookup.udf.TimeLookupUDF'")
# cursor.execute("CREATE TEMPORARY FUNCTION aggregate_filter as 'com.flipkart.bigfoot.dimlookup.udf.AggregateConditionUDF'")
# cursor.execute("CREATE TEMPORARY FUNCTION aggregate as 'com.flipkart.bigfoot.dimlookup.udf.AggregateUDF'")
# cursor.execute("CREATE TEMPORARY FUNCTION ISOToSqlTs as 'com.flipkart.bigfoot.dimlookup.udf.DateISOToSqlUDF'")
# cursor.execute("CREATE TEMPORARY FUNCTION business_date_diff as 'com.flipkart.bigfoot.dimlookup.udf.BusinessDayDiffUDF'")

# cursor.execute("set mapreduce.input.fileinputformat.input.dir.recursive=true")

# print('connect')

X_Client_Id= 'analytics-cdo' ### Change as per your org-namespace
X_Client_Secret= '6cbdc3cd-a3f7-43e1-a2f9-1935f6317c44' ### Change as per your org-namespace
user_name='shubham.v.vc' ### Change as per your username

# Alpha Query you want to pull
query = """
select
dt.week_num_in_year as week_num,
sales_fact.analytic_business_unit,
sales_fact.analytic_super_category,
--TC
count(distinct(sales_fact.account_id)) as customers,  
--RC/NC
count(distinct(case when sales_fact.new_customer_flag = 1 then sales_fact.account_id end)) as nc,
count(distinct(case when sales_fact.new_customer_flag = 0 then sales_fact.account_id end)) as rc,
--Plus/Non-Plus
count(distinct(case when lower(sales_fact.user_lockin_state) ='active' then sales_fact.account_id end)) as Plus,
count(distinct(case when lower(sales_fact.user_lockin_state) !='active' then sales_fact.account_id end)) as Non_Plus,
--gender_tag
count(distinct(case when lower(new_demograph.gender) = 'male' then sales_fact.account_id end)) as MALE,
count(distinct(case when lower(new_demograph.gender) = 'female' then sales_fact.account_id end)) as FEMALE,
--marital_status
count(distinct(case when lower(new_demograph.is_married)= 'yes' THEN sales_fact.account_id end)) as MARRIED,
count(distinct(case when lower(new_demograph.is_married)= 'no' THEN sales_fact.account_id end)) as UNMARRIED,
--parental_status
count(distinct(case when lower(new_demograph.is_parent)= 'yes' THEN sales_fact.account_id end)) as PARENT,
count(distinct(case when lower(new_demograph.is_parent)= 'no' THEN sales_fact.account_id end)) as NOT_PARENT,
--student_status
count(distinct(case when lower(new_demograph.is_student)= 'yes' THEN sales_fact.account_id end)) as STUDENT,
count(distinct(case when lower(new_demograph.is_student)= 'no' THEN sales_fact.account_id end)) as NOT_STUDENT,
--age_flag
count(distinct(case WHEN new_demograph.min_age >= 0 and new_demograph.max_age < 15 THEN sales_fact.account_id end)) as age_0_15,
count(distinct(case WHEN new_demograph.min_age >= 15 and new_demograph.max_age < 25 THEN sales_fact.account_id end)) as age_15_25,
count(distinct(case WHEN new_demograph.min_age >= 25 and new_demograph.max_age < 35 THEN sales_fact.account_id end)) as age_25_35,
count(distinct(case WHEN new_demograph.min_age >= 35 and new_demograph.max_age < 45 THEN sales_fact.account_id end)) as age_35_45,
count(distinct(case WHEN new_demograph.min_age >= 45 and new_demograph.max_age <= 100 THEN sales_fact.account_id end)) as age_45_100,

--Customer_section
0 as Premium,
-- count(distinct(case	when aff_seg.aff_segment = 'premium' then sales_fact.account_id end)) as Premium,
0 as Emerging_Premium,
-- count(distinct(case	when aff_seg.aff_segment = 'emerging_premium' then sales_fact.account_id end)) as Emerging_Premium,
0 as Mass,
--count(distinct(case	when aff_seg.aff_segment = 'mass' then sales_fact.account_id end)) as Mass,
0 as Entry,
--count(distinct(case	when aff_seg.aff_segment not in ('premium','emerging_premium','mass') then sales_fact.account_id end)) as Entry,


--category_type
count(distinct(case when aff_cohort.affluence_score <= 0.25 then sales_fact.account_id end)) as Low_Aff,
count(distinct(case when aff_cohort.affluence_score between 0.25 and 0.75 then sales_fact.account_id end)) as Mid_Aff,
count(distinct(case when aff_cohort.affluence_score >= 0.75 then sales_fact.account_id end)) as High_Aff,
--cust_category
count(distinct(case WHEN cust_fact_nn.account_id is not null THEN sales_fact.account_id end)) as NN_cust,
count(distinct(case WHEN cust_fact_on.account_id is not null THEN sales_fact.account_id end)) as ON_cust,
count(distinct(sales_fact.account_id)) - count(distinct(case WHEN cust_fact_nn.account_id is not null THEN sales_fact.account_id end)) - count(distinct(case WHEN cust_fact_on.account_id is not null THEN sales_fact.account_id end)) as OO_cust,
--tpc_flag
count(distinct(case WHEN base.trans_count >=1 and base.trans_count<=3 THEN sales_fact.account_id end)) as low_tpc,
count(distinct(case WHEN base.trans_count >=4 and base.trans_count<=7 THEN sales_fact.account_id end)) as mid_tpc,
count(distinct(case WHEN base.trans_count >=8 and base.trans_count<=12 THEN sales_fact.account_id end)) as high_tpc,
count(distinct(case WHEN base.trans_count>12 THEN sales_fact.account_id end)) as very_high_tpc,
--MLE_CUSTOMER
sum(MLE_fact.mle_cust) as mle_cust,
count(distinct(case WHEN cust_fact_oon.account_id is not null THEN sales_fact.account_id end)) as OON_cust
from
bigfoot_external_neo.cp_bi_prod_sales__forward_unit_history_fact as sales_fact
left join 
	(select 
		distinct date_dim_key,week_num_in_year
	from
		bigfoot_external_neo.scp_oms__date_dim_fact ) dt 
on 
	sales_fact.order_date_key = dt.date_dim_key

/*
left join
bigfoot_external_neo.analytics_cdo__FK_Aff_Segment_fact as aff_seg
on sales_fact.account_id = aff_seg.account_id
*/

left join
bigfoot_external_neo.cp_uie__Affluence_Cohort_Score_fact as aff_cohort
on sales_fact.account_id = aff_cohort.account_id
left join
bigfoot_external_neo.cp_uie__account_demographics_insight_beta_fact new_demograph
on sales_fact.account_id = new_demograph.account_id
left join
( 
	select 
		b.analytic_business_unit,
		b.account_id
	from
		bigfoot_external_neo.analytics_cdo__customer_insight_hive_fact b 
	inner join  
		bigfoot_external_neo.cp_bi_prod_sales__forward_unit_history_fact a
	on 
		a.order_item_id =b.order_item_id
	where 
		lower(a.status) in ('in_progress','undelivered','completed','delivered','approved','shipped','ready_to_ship','returned', 'return_requested','activated')
		and a.type !='service'
		and lower(a.marketplace_id)= 'flipkart'
		and a.category_id !=21726
		and a.category_id !=21651
		and a.is_freebie =false
		and (a.replacement_for_unit is null or a.replacement_for_unit='not_replacement')
		and (a.exchange_for_unit is null or a.exchange_for_unit='not_exchange')
		and is_shopsy_order = FALSE
		and a.order_date_key  between lookup_date(date_sub(current_date,49)) and lookup_date(date_sub(current_date,2))  -- change as per week req.
		and lower(a.analytic_business_unit) in ('bgm','electronics','furniture','home','large','lifestyle','mobile')
		and b.new_cust_flag = 1
	group by
		b.analytic_business_unit,
		b.account_id
) as cust_fact_nn
on sales_fact.account_id=cust_fact_nn.account_id 
and sales_fact.analytic_business_unit = cust_fact_nn.analytic_business_unit
left join
( 
	select 
		b.analytic_business_unit,
		b.account_id
	from
		bigfoot_external_neo.analytics_cdo__customer_insight_hive_fact b 
	inner join  
		bigfoot_external_neo.cp_bi_prod_sales__forward_unit_history_fact a
	on 
		a.order_item_id =b.order_item_id
	where 
		lower(a.status) in ('in_progress','undelivered','completed','delivered','approved','shipped','ready_to_ship','returned', 'return_requested','activated')
		and a.type !='service'
		and lower(a.marketplace_id)= 'flipkart'
		and a.category_id !=21726
		and a.category_id !=21651
		and a.is_freebie =false
		and (a.replacement_for_unit is null or a.replacement_for_unit='not_replacement')
		and (a.exchange_for_unit is null or a.exchange_for_unit='not_exchange')
		and is_shopsy_order = FALSE
		and a.order_date_key  between lookup_date(date_sub(current_date,49)) and lookup_date(date_sub(current_date,2))  -- change as per week req.
		and lower(a.analytic_business_unit) in ('bgm','electronics','furniture','home','large','lifestyle','mobile')
		and b.new_cust_flag = 0
		and b.new_to_bu = 1
	group by
		b.analytic_business_unit,
		b.account_id
) as cust_fact_on
on sales_fact.account_id=cust_fact_on.account_id 
and sales_fact.analytic_business_unit = cust_fact_on.analytic_business_unit
left join
( 
	select 
		b.analytic_business_unit,
		b.account_id
	from
		bigfoot_external_neo.analytics_cdo__customer_insight_hive_fact b 
	inner join  
		bigfoot_external_neo.cp_bi_prod_sales__forward_unit_history_fact a
	on 
		a.order_item_id =b.order_item_id
	where 
		lower(a.status) in ('in_progress','undelivered','completed','delivered','approved','shipped','ready_to_ship','returned', 'return_requested','activated')
		and a.type !='service'
		and lower(a.marketplace_id)= 'flipkart'
		and a.category_id !=21726
		and a.category_id !=21651
		and a.is_freebie =false
		and (a.replacement_for_unit is null or a.replacement_for_unit='not_replacement')
		and (a.exchange_for_unit is null or a.exchange_for_unit='not_exchange')
		and is_shopsy_order = FALSE
		and a.order_date_key  between lookup_date(date_sub(current_date,49)) and lookup_date(date_sub(current_date,2))  -- change as per week req.
		and lower(a.analytic_business_unit) in ('bgm','electronics','furniture','home','large','lifestyle','mobile')
		and b.new_cust_flag = 0
		and b.new_to_bu = 0
		and b.new_to_sc = 1
	group by
		b.analytic_business_unit,
		b.account_id
) as cust_fact_oon
on sales_fact.account_id=cust_fact_oon.account_id 
and sales_fact.analytic_business_unit = cust_fact_oon.analytic_business_unit
left join
(	
	select
	sa.account_id,
	sa.analytic_business_unit,
	count(distinct sa.order_external_id) as trans_count
	from
	bigfoot_external_neo.analytics_cdo__customer_insight_hive_fact sa
	where
	sa.approve_date_key between lookup_date(date_sub(current_date,49)) and lookup_date(date_sub(current_date,2))  -- change as per week req.
	group by
	sa.account_id,
	sa.analytic_business_unit
) base
on sales_fact.account_id = base.account_id
left join
( 
	select
	a.months,
	a.account_id,
	count(distinct(a.account_id)) as mle_cust
	from
	(
		select
		substr(c.approve_date_key,1,6) as months,
		c.account_id
		from
		bigfoot_external_neo.analytics_cdo__customer_insight_hive_fact c
		where
	 	lower(c.analytic_business_unit) in ('mobile','large','electronics')
	 	and c.new_to_bu=1
	 	and c.approve_date_key between lookup_date(date_sub(current_date,49)) and lookup_date(date_sub(current_date,2))  -- change as per week req.
		group by
	 	substr(c.approve_date_key,1,6),
	 	c.account_id
	) a
	left join
	(
		select
		substr(ca.approve_date_key,1,6) as months,
		ca.account_id
		from
		bigfoot_external_neo.analytics_cdo__customer_insight_hive_fact ca
		where
		lower(ca.analytic_business_unit) in ('mobile','large','electronics')
		and ca.new_to_bu=0
		and ca.approve_date_key between lookup_date(date_sub(current_date,49)) and lookup_date(date_sub(current_date,2))  -- change as per week req.
		group by
		substr(ca.approve_date_key,1,6),
		ca.account_id
	) b
	on a.months = b.months and a.account_id = b.account_id
	where
	b.account_id is null
	group by
	a.months,
	a.account_id
) as MLE_fact
on MLE_fact.account_id = sales_fact.account_id
where
sales_fact.order_date_key between lookup_date(date_sub(current_date,49)) and lookup_date(date_sub(current_date,2))  -- change as per week req.
and lower(sales_fact.analytic_business_unit) in ('bgm','electronics','furniture','home','large','lifestyle','mobile')
and lower(sales_fact.status) in ('in_progress','undelivered','completed','delivered','approved','shipped','ready_to_ship','returned', 'return_requested','activated')
and sales_fact.type !='service'
and sales_fact.category_id !=21726
and sales_fact.category_id !=21651
and sales_fact.replacement_for_unit is null
and sales_fact.exchange_for_unit is null
and sales_fact.is_freebie = false
and sales_fact.marketplace_id = 'FLIPKART'
and sales_fact.is_shopsy_order = false
group by
dt.week_num_in_year,
sales_fact.analytic_business_unit,
sales_fact.analytic_super_category

"""

url = 'http://validator.fdp-qaas-validator-prod.fkcloud.in/query/queries'


headers ={'Accept': '*', 'Content-Type': 'application/x-www-form-urlencoded',
          'Host': 'validator.fdp-qaas-validator-prod.fkcloud.in',
          'X-Client-Id': X_Client_Id, 
          'X-Client-Secret': X_Client_Secret,
          'x-authenticated-user':user_name 
          }
data ={'query':query,'sourceName':'HIVE'}

r = requests.post(url, headers=headers, data = data)
print(r.content)

print('r is: ',r)
print('If you get <Response [200]> above, that implies the url request was successful ')
query_handle_byte_dtype = r.content
# using decode() + loads() to convert to dictionary
query_handle_dict_dtype = json.loads(query_handle_byte_dtype.decode('utf-8'))
query_handle = query_handle_dict_dtype['queryHandle']['handle']
print("http://fdp.fkinternal.com/query/result/"+query_handle)

url = '  http://validator.fdp-qaas-validator-prod.fkcloud.in/query/queries/'+query_handle+'/status'


headers ={'Accept': '*', 'Content-Type': 'application/x-www-form-urlencoded',
          'Host': 'validator.fdp-qaas-validator-prod.fkcloud.in',
          'X-Client-Id': X_Client_Id, 
          'X-Client-Secret': X_Client_Secret,
          'x-authenticated-user':user_name 
          }
data ={'query':query,'sourceName':'HIVE'}

status_req = requests.get(url, headers=headers)

json.loads(status_req.content.decode('utf-8'))['status']
  
a = 0

while (a != 1):
    b=''
    status_req = requests.get(url, headers=headers)
    b = json.loads(status_req.content.decode('utf-8'))['status']    
    if b == 'SUCCESSFUL':
        a = 1
    else: 
        a = 0
    print(a)
    print('code still running')
    time.sleep(30)
    
print(status_req)

url_data_pull = 'http://validator.fdp-qaas-validator-prod.fkcloud.in/query/queries/'+ query_handle +'/downloadresults'


headers_data_pull ={'Accept': '*', 'Content-Type': 'application/x-www-form-urlencoded',
                    'Host': 'validator.fdp-qaas-validator-prod.fkcloud.in',
                    'X-Client-Id': X_Client_Id, 
          'X-Client-Secret': X_Client_Secret,
          'x-authenticated-user':user_name 
                   }

r_data_pull = requests.get(url_data_pull, headers=headers_data_pull)

query_output = r_data_pull.content

s=query_output.decode('utf-8')


data = StringIO(s) 

cust_data=pd.read_csv(data)

# gc=pygsheets.authorize(service_file='ShivankAutomation-fd5dab44a774.json')
# sh=gc.open('Life_Style_Data')

# data=sh[2]





# In[ ]:


cust_data


# In[ ]:


gc=pygsheets.authorize(service_file='ShivankAutomation-fd5dab44a774.json')
sh=gc.open('WOW_Customer_Dashboard')
worksheet=sh.worksheets().copy()
sheet_name = [s.title for s in worksheet]
data=sh[sheet_name.index('BUxSC_Level')]
data.clear(start='A2', end='AK200000', fields="*")
data.set_dataframe(cust_data,(2,1),copy_head=False,copy_index=False)


# # For BUxSC level (Query 10 - WoW Geo_Level)

# In[ ]:


import requests
import json
from io import StringIO
import time
import pandas as pd
import jaydebeapi
import os
import subprocess
import pandas as pd
import numpy as np
import datetime
import calendar
import pygsheets
import re
from datetime import date
import jaydebeapi
import os
import subprocess
import numpy as np
import datetime
import calendar
import pygsheets
import re

# output = subprocess.check_output(['bash', '-c', 'echo $CLASSPATH:/usr/local/fdp-infra-hive/lib/*'])
# os.environ['CLASSPATH'] = '/usr/local/fdp-infra-hive/lib/*'

# url = ("jdbc:hive2://fkp-fdp-galaxy-sun-zkjn-0001.c.fkp-fdp-galaxy.internal:2181,fkp-fdp-galaxy-sun-zkjn-0002.c.fkp-fdp-galaxy.internal:2181,fkp-fdp-galaxy-sun-zkjn-0003.c.fkp-fdp-galaxy.internal:2181/default;transportMode=http;httpPath=cliservice;serviceDiscoveryMode=zooKeeper;zooKeeperNamespace=fkp-fdp-galaxy-hive3-hs2-agni;hive.client.read.socket.timeout=300?hive.metastore.client.socket.timeout=180;hive.server.tcp.keepalive=true;hive.server.read.socket.timeout=300")
 
# print('Established JDBC connection---------------------')

# conn = jaydebeapi.connect("org.apache.hive.jdbc.HiveDriver", url,{'user': "mohammed.usama", 'password': "Khalid@170757"})

# print('Connected to hive server-------------------------')

# cursor = conn.cursor()
# cursor.execute("ADD JAR /usr/share/fk-bigfoot-hivejsonserde/json-serde-1.3-SNAPSHOT-jar-with-dependencies.jar")
# cursor.execute("ADD JAR /usr/share/fk-bigfoot-dimlookup/dimlookup-hive-udf-1.0-SNAPSHOT-jar-with-dependencies.jar")
# cursor.execute("ADD JAR gs://fkpdp-mhosy-2nig-1a5d-systemlibs/libraries/hive/jars/hive-udfs-1.0-SNAPSHOT.jar")
# cursor.execute("CREATE TEMPORARY FUNCTION lookup as 'com.flipkart.bigfoot.dimlookup.udf.HiveLookupUDF'")
# cursor.execute("CREATE TEMPORARY FUNCTION arrToString as 'com.flipkart.fdp.CustomCaster'")
# cursor.execute("CREATE TEMPORARY FUNCTION lookupkey as 'com.flipkart.bigfoot.dimlookup.udf.HiveKeyGeneratorUDF'")
# cursor.execute("CREATE TEMPORARY FUNCTION lookup_date as 'com.flipkart.bigfoot.dimlookup.udf.DateLookupUDF'")
# cursor.execute("CREATE TEMPORARY FUNCTION lookup_time as 'com.flipkart.bigfoot.dimlookup.udf.TimeLookupUDF'")
# cursor.execute("CREATE TEMPORARY FUNCTION aggregate_filter as 'com.flipkart.bigfoot.dimlookup.udf.AggregateConditionUDF'")
# cursor.execute("CREATE TEMPORARY FUNCTION aggregate as 'com.flipkart.bigfoot.dimlookup.udf.AggregateUDF'")
# cursor.execute("CREATE TEMPORARY FUNCTION ISOToSqlTs as 'com.flipkart.bigfoot.dimlookup.udf.DateISOToSqlUDF'")
# cursor.execute("CREATE TEMPORARY FUNCTION business_date_diff as 'com.flipkart.bigfoot.dimlookup.udf.BusinessDayDiffUDF'")

# cursor.execute("set mapreduce.input.fileinputformat.input.dir.recursive=true")

# print('connect')

X_Client_Id= 'analytics-cdo' ### Change as per your org-namespace
X_Client_Secret= '6cbdc3cd-a3f7-43e1-a2f9-1935f6317c44' ### Change as per your org-namespace
user_name='shubham.v.vc' ### Change as per your username

# Alpha Query you want to pull
query = """
select
dt.week_num_in_year as week_num,
sales_fact.analytic_business_unit,
sales_fact.analytic_super_category,
case
when loc.city_tier = 'Metro' then "Metro"
when loc.city_tier = 'Tier 1A' or loc.city_tier='Tier 1B' then "Tier 1"
when loc.city_tier = 'Tier 2' then "Tier 2"
else "Tier 3 & Others"
end as tiers_flag,
case
when lower(loc.zone) = 'north' then "North"
when lower(loc.zone) = 'south' then "South"
when lower(loc.zone) = 'east' then "East"
else "West"
end as zone_flag,
afff.cohort as v3_affluence_signal,
CASE
WHEN (cust_fact.new_cust_flag=TRUE ) THEN 'NN'
WHEN (cust_fact.new_cust_flag=FALSE and cust_fact.new_to_bu=TRUE) THEN 'ON'
ELSE 'OO'
END as cust_category,
count(distinct(sales_fact.account_id)) as total_customers,
sum(sales_fact.units) as total_units,
sum(sales_fact.gmv) as total_gmv
from
bigfoot_external_neo.cp_bi_prod_sales__forward_unit_history_fact as sales_fact
left join 
	(select 
		distinct date_dim_key,week_num_in_year
	from
		bigfoot_external_neo.scp_oms__date_dim_fact ) dt 
on 
	sales_fact.order_date_key = dt.date_dim_key
left join
bigfoot_external_neo.scp_ekl__logistics_geo_hive_dim loc
on sales_fact.pincode = loc.pincode
left join 
bigfoot_external_neo.cp_uie__Affluence_V3_2_final_output_fact afff
on sales_fact.account_id = afff.account_id
left join
( 
    select 
    distinct order_id,
    new_cust_flag,
    new_to_bu 
    from
    bigfoot_external_neo.analytics_cdo__customer_insight_hive_fact
) as cust_fact
on sales_fact.order_id=cust_fact.order_id
where
sales_fact.order_date_key between lookup_date(date_sub(current_date,49)) and lookup_date(date_sub(current_date,2))  -- change as per week req.
and lower(sales_fact.status) in ('in_progress','undelivered','completed','delivered','approved','shipped','ready_to_ship','returned', 'return_requested','activated')
and sales_fact.type != 'service'
and sales_fact.category_id != 21726
and sales_fact.category_id != 21651
and sales_fact.replacement_for_unit is null
and sales_fact.exchange_for_unit is null
and sales_fact.is_freebie = false
and sales_fact.is_shopsy_order = false
and lower(sales_fact.marketplace_id) in ('flipkart')
group by
dt.week_num_in_year,
sales_fact.analytic_business_unit,
sales_fact.analytic_super_category,
case
when loc.city_tier = 'Metro' then "Metro"
when loc.city_tier = 'Tier 1A' or loc.city_tier='Tier 1B' then "Tier 1"
when loc.city_tier = 'Tier 2' then "Tier 2"
else "Tier 3 & Others"
end,
case
when lower(loc.zone) = 'north' then "North"
when lower(loc.zone) = 'south' then "South"
when lower(loc.zone) = 'east' then "East"
else "West"
end,
afff.cohort,
CASE
WHEN (cust_fact.new_cust_flag=TRUE ) THEN 'NN'
WHEN (cust_fact.new_cust_flag=FALSE and cust_fact.new_to_bu=TRUE) THEN 'ON'
ELSE 'OO'
END

"""

url = 'http://validator.fdp-qaas-validator-prod.fkcloud.in/query/queries'


headers ={'Accept': '*', 'Content-Type': 'application/x-www-form-urlencoded',
          'Host': 'validator.fdp-qaas-validator-prod.fkcloud.in',
          'X-Client-Id': X_Client_Id, 
          'X-Client-Secret': X_Client_Secret,
          'x-authenticated-user':user_name 
          }
data ={'query':query,'sourceName':'HIVE'}

r = requests.post(url, headers=headers, data = data)
print(r.content)

print('r is: ',r)
print('If you get <Response [200]> above, that implies the url request was successful ')
query_handle_byte_dtype = r.content
# using decode() + loads() to convert to dictionary
query_handle_dict_dtype = json.loads(query_handle_byte_dtype.decode('utf-8'))
query_handle = query_handle_dict_dtype['queryHandle']['handle']
print("http://fdp.fkinternal.com/query/result/"+query_handle)

url = '  http://validator.fdp-qaas-validator-prod.fkcloud.in/query/queries/'+query_handle+'/status'


headers ={'Accept': '*', 'Content-Type': 'application/x-www-form-urlencoded',
          'Host': 'validator.fdp-qaas-validator-prod.fkcloud.in',
          'X-Client-Id': X_Client_Id, 
          'X-Client-Secret': X_Client_Secret,
          'x-authenticated-user':user_name 
          }
data ={'query':query,'sourceName':'HIVE'}

status_req = requests.get(url, headers=headers)

json.loads(status_req.content.decode('utf-8'))['status']
  
a = 0

while (a != 1):
    b=''
    status_req = requests.get(url, headers=headers)
    b = json.loads(status_req.content.decode('utf-8'))['status']    
    if b == 'SUCCESSFUL':
        a = 1
    else: 
        a = 0
    print(a)
    print('code still running')
    time.sleep(30)
    
print(status_req)

url_data_pull = 'http://validator.fdp-qaas-validator-prod.fkcloud.in/query/queries/'+ query_handle +'/downloadresults'


headers_data_pull ={'Accept': '*', 'Content-Type': 'application/x-www-form-urlencoded',
                    'Host': 'validator.fdp-qaas-validator-prod.fkcloud.in',
                    'X-Client-Id': X_Client_Id, 
          'X-Client-Secret': X_Client_Secret,
          'x-authenticated-user':user_name 
                   }

r_data_pull = requests.get(url_data_pull, headers=headers_data_pull)

query_output = r_data_pull.content

s=query_output.decode('utf-8')


data = StringIO(s) 

cust_data=pd.read_csv(data)

# gc=pygsheets.authorize(service_file='ShivankAutomation-fd5dab44a774.json')
# sh=gc.open('Life_Style_Data')

# data=sh[2]





# In[ ]:


cust_data


# In[ ]:


gc=pygsheets.authorize(service_file='ShivankAutomation-fd5dab44a774.json')
sh=gc.open('WOW_Customer_Dashboard')
worksheet=sh.worksheets().copy()
sheet_name = [s.title for s in worksheet]
data=sh[sheet_name.index('BUxSC_Level_Geo')]
data.clear(start='A2', end='J200000', fields="*")
data.set_dataframe(cust_data,(2,1),copy_head=False,copy_index=False)


# In[ ]:





# In[ ]:





# In[ ]:





# In[ ]:





# In[ ]:





# In[ ]:





# In[ ]:





# In[ ]:




