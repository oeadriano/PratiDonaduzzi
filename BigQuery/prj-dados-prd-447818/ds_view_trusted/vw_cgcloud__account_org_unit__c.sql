CREATE VIEW `prj-dados-prd-447818.ds_view_trusted.vw_cgcloud__account_org_unit__c`
AS select 
  cgcloud__Org_Unit__c, 
  cgcloud__Account__c, 
  cgcloud__Active__c,
  cgcloud__Valid_From__c,
  cgcloud__Valid_Thru__c,
  externalid__c
from  
  prj-dados-prd-447818.postgres_raw.account_org_unit
where
  recordstamp >= date_sub(current_timestamp, interval 120 minute);