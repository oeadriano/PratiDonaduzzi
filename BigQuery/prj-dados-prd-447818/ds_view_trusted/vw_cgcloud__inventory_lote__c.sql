CREATE VIEW `prj-dados-prd-447818.ds_view_trusted.vw_cgcloud__inventory_lote__c`
AS /*
  AEO 30/05/25
  - view com lotes relacionados ao warehouse
  - o vinculo com a chave externa de warehouse foi necessario
  - pois a gde maioria do registros em ztbsf002
  - nao tem relacionamento com os warehouse ativos em QAS (estranho..)
*/
with w_inventory as (
  select distinct ExternalId__c
  from ds_view_trusted.vw_cgcloud__inventory__c
)
select 
  distinct l.werks||"-"||ltrim(l.kunnr, '0')||"-"||ltrim(l.matnr, '0') as Inventory__c, -- Inventory__r.ExternalId__c
  case
    when coalesce(ltestr, '') = 'X' then 'Estratégico'
    else 'Outros'
  end as Category__c, 
  l.vfdat as LotExpirationDate__c,
  l.charg as LotNumber__c, 
  l.clabs as Quantity__c, -- a definir clabs ou cinsm
  w.ExternalId__c as Warehouse__c, 
  l.werks||"-"||ltrim(l.kunnr,'0')||"-"||ltrim(l.matnr, '0')||"-"||l.charg as ExternalId__c
FROM 
  `sap_raw.ztbsf002` l
join 
  `ds_view_trusted.vw_cgcloud__warehouse__c` w
  on w.SAPPlant__c = l.werks
where
  l.vfdat >= current_date
  and l.werks||"-"||ltrim(l.kunnr,'0')||"-"||ltrim(l.matnr, '0') in (
    select ExternalId__c from  w_inventory
  )
  -- and l.recordstamp ;