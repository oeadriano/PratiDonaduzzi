CREATE VIEW `prj-dados-prd-447818.ds_view_trusted.vw_order_status_update`
AS SELECT 
  order_sales_force as ExternalId__c, 
  order_esfera as EsferaOrderNumber__c, 
  order_sap as SAPOrderNumber__c, 
  description_status as Status__c, 
  description_sub_status as AditionalStatusInformation__c
FROM 
  `postgres_raw.status_order_esfera` 
where
  order_sales_force like 'SF-%'
  and recordstamp >= date_sub(current_timestamp, interval 20 minute )
;