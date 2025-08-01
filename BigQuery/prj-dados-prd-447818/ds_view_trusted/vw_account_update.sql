CREATE VIEW `prj-dados-prd-447818.ds_view_trusted.vw_account_update`
AS with w_atualizados as (
  select 
    distinct codigo 
  from 
    (
      SELECT KUNNR as codigo FROM `sap_raw.knkk`  
      where recordstamp >= date_sub(current_timestamp, INTERVAL 240 minute)
      union all
      SELECT KNKLI as codigo FROM `sap_raw.s066` 
      where recordstamp >= date_sub(current_timestamp, INTERVAL 240 minute)
      union all
      SELECT KNKLI as codigo FROM `sap_raw.s067` 
      where recordstamp >= date_sub(current_timestamp, INTERVAL 240 minute)
      union all
      SELECT KNKLI as codigo FROM `sap_raw.vbak` 
      where recordstamp >= date_sub(current_timestamp, INTERVAL 240 minute)
      union all
      select cgcloud__externalid__c as codigo FROM postgres_raw.account 
      where recordstamp >= date_sub(current_timestamp, INTERVAL 240 minute)
    )    
)
select 
  c.*,   
  coalesce(b.MarketTotal__c, 0) as MarketTotal__c, 
  coalesce(b.PratiTotal__c, 0) as PratiTotal__c, 
  coalesce(b.PratiPotential__c, '') as PratiPotential__c, 
  coalesce(b.BrickOld__c, '') as BrickOld__c, 
  coalesce(b.BrickNew__c, '') as BrickNew__c, 
  coalesce(b.Class__c, '') as Class__c, 
  coalesce(b.openchannel__c, '') as openchannel__c, 
  coalesce(b.scorestatusppp__c, '') as scorestatusppp__c
from 
  prj-dados-prd-447818.ds_view_trusted.vw_customer_credit c
left join
  prj-dados-prd-447818.ds_view_trusted.vw_baseed_iqvia b
  on b.praticode__c = c.cgcloud__ExternalId__c
where 
  c.cgcloud__externalId__c in ( select codigo from w_atualizados )
ORDER BY 
  c.cgcloud__ExternalId__c  ;