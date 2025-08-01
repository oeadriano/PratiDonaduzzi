CREATE VIEW `prj-dados-prd-447818.ds_view_trusted.vw_cgcloud__account_relationship__c`
AS select 
  distinct a.customer_code as Account_ExternalID, 
  'Warehouse' as cgcloud__Relationship_Type__c, 
  'false' as cgcloud__Is_Primary_Relationship__c, 
  a.warehouse_code as Related_ExternalId, 
  a.valid_from as cgcloud__Start_Date__c, 
  a.valid_thru as cgcloud__End_Date__c, 
  a.externalid as ExternalId__c
from 
  `postgres_raw.warehouse_account` a
where
  recordstamp >= date_sub(current_timestamp, interval 2 hour)
union all
-- warehouse sem considerar o recordstamp  para carga geral somente
select 
  distinct cgcloud__externalid__c as Account_ExternalID, 
  'DeliveryRecipient' as cgcloud__Relationship_Type__c, 
  'true' as cgcloud__Is_Primary_Relationship__c, 
  cgcloud__externalid__c as Related_ExternalId, 
  cast('2025-01-01' as date) as cgcloud__Start_Date__c, 
  cast('2099-12-31' as date) as cgcloud__End_Date__c, 
  cgcloud__externalid__c ||'-'||cgcloud__externalid__c as ExternalId__c
from 
  `postgres_raw.account` 
where
  recordstamp >= date_sub(current_timestamp, interval 2 hour);