CREATE VIEW `prj-dados-prd-447818.ds_view_trusted.vw_cgcloud__Account_Trade_Org_Hierarchy__c`
AS select 
  cgcloud__Child_Account__c, 
  cgcloud__Parent_Account__c, 
  cgcloud__Valid_From__c, 
  cgcloud__Valid_Thru__c, ExternalId__c, 
from 
  postgres_raw.account_trade_org_hierarchy
where
  recordstamp >= date_sub(current_timestamp, interval 2 hour );