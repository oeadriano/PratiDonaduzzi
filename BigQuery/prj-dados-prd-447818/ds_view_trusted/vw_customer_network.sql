CREATE VIEW `prj-dados-prd-447818.ds_view_trusted.vw_customer_network`
AS select 
  cgcloud__ExternalId__c, 
  name, 
  TradeName__c,
  case     
    when cgcloud__ExternalId__c in ('R11', 'R485') then 'Associativismo'
    else 'Rede'
  end as RecordType, 
  case     
    when cgcloud__ExternalId__c in ('R11', 'R485') then 'Associativismo'
    else 'Rede'
  end as cgcloud__Account_Template__c
 from 
  prj-dados-prd-447818.postgres_raw.customer_network;