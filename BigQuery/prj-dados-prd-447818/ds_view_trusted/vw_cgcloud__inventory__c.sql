CREATE VIEW `prj-dados-prd-447818.ds_view_trusted.vw_cgcloud__inventory__c`
AS select 
  distinct e.werks||"-"||ltrim(e.kunnr, '0')||"-"||ltrim(e.matnr, '0') as ExternalId__c, 
  'Active' cgcloud__Phase__c,
  '0001' as cgcloud__Sales_Org__c,
  p.cgcloud__Short_Description_Language_1__c as cgcloud__Description_Language_1__c,
  case 
    when e.labst >= 0 then e.labst
    else 0
  end as cgcloud__Initial_Inventory__c, 
  'Estoque Padrão' as cgcloud__Inventory_Template__c,
  p.cgcloud__Product_Short_Code__c as cgcloud__Product__c,
  '' cgcloud__Tour__c,
  '2025-01-01' as cgcloud__Valid_From__c,
  -- '2099-12-31' as cgcloud__Valid_Thru__c,
  current_date  as cgcloud__Valid_Thru__c,
  ltrim(e.kunnr, '0') as cgcloud__warehouse__c  
from 
  sap_raw.ztbsf001 e  
join
  `ds_view_trusted.vw_product2` p
  on ltrim(e.matnr, '0') = p.ProductCode
where
  e.recordstamp >= date_sub(current_timestamp, INTERVAL 30 minute)
  and e.matnr not like '00000000000%' -- gambiarra para tratar com a Alemão
order by 
  ExternalId__c;