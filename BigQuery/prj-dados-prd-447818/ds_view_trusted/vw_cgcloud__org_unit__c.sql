CREATE VIEW `prj-dados-prd-447818.ds_view_trusted.vw_cgcloud__org_unit__c`
AS SELECT 
                externalid__c, 
                cgcloud__Description_Language_1__c,
                cgcloud__Org_Type__c,
                cgcloud__Org_Level__c, 
                cgcloud__Sales_Org__c,
                cgcloud__Main__c
from 
  prj-dados-prd-447818.postgres_raw.org_unit
where
  recordstamp >= date_sub(current_timestamp, INTERVAL 120 MINUTE);