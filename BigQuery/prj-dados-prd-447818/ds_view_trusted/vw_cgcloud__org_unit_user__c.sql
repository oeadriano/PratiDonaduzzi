CREATE VIEW `prj-dados-prd-447818.ds_view_trusted.vw_cgcloud__org_unit_user__c`
AS select 
  cgcloud__Org_Unit__c,
  cgcloud__Management_Type__c, 
  cgcloud__Main__c, 
  cgcloud__User__c, 
  cgcloud__Valid_From__c, 
  cgcloud__Valid_Thru__c,
  cgcloud__Org_Unit__c ||'-'|| cgcloud__User__c as ExternalId__c
from   
  postgres_raw.org_unit_user
where  
  recordstamp >= date_sub(current_timestamp, interval 2 hour );