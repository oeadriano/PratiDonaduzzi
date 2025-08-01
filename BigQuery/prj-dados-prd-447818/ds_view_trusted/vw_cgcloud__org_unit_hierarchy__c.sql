CREATE VIEW `prj-dados-prd-447818.ds_view_trusted.vw_cgcloud__org_unit_hierarchy__c`
AS select 
  cgcloud__Parent_Org_Unit__c, 
  cgcloud__Child_Org_Unit__c, 
  cgcloud__Valid_From__c, 
  cgcloud__Valid_Thru__c,
  "SalesRep" as cgcloud__Child_Org_Level__c,
  "Sales" as  cgcloud__Child_Org_Type__c,
  "SalesRep" as cgcloud__Parent_Org_Level__c,
  "Sales" as cgcloud__Parent_Org_Type__c,
  cgcloud__Parent_Org_Unit__c||"-"||cgcloud__Child_Org_Unit__c as  cgcloud__externalId__c
from 
  postgres_raw.org_unit_hierarchy
where 
  recordstamp >= date_sub(current_timestamp, interval 120 minute);