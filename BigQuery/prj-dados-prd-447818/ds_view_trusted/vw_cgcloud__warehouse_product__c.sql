CREATE VIEW `prj-dados-prd-447818.ds_view_trusted.vw_cgcloud__warehouse_product__c`
AS select 
  LTRIM(cgcloud__product__c, '0') as cgcloud__Product__c, 
  cgcloud__Warehouse__c,
  '0001' as cgcloud__Sales_Org__c,
  cgcloud__Active__c,
  externalid__c as cgcloud__ExternalId__c      
  from 
    `postgres_raw.warehouse_product` 
where
  recordstamp >= date_sub(current_timestamp(), interval 30 minute)
  and LTRIM(cgcloud__product__c, '0') in (select ProductCode from `ds_view_trusted.vw_product2`)
  ;