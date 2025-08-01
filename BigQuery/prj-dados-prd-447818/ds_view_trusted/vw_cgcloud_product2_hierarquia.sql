CREATE VIEW `prj-dados-prd-447818.ds_view_trusted.vw_cgcloud_product2_hierarquia`
AS with w_recordtype as 
  (
    select id, ambiente, name, SobjectType
    from `ds_trusted.sf_recordtype_template`
    where name = 'Product Group' and SobjectType <> 'Product'
  ),
  w_cgcloud_template as 
  (
    select id, ambiente, name
    from `ds_trusted.sf_recordtype_template`
    where SobjectType = 'cgcloud__Product_Template__c' 
  )
select 
  distinct
  matnr, grupo_novo as Name, 
  rc.id as RecordTypeId, 
  tp.id as cgcloud__Product_Template__c,
  grupo_novo as cgcloud__Description_1_Language_1__c,
  grupo_novo as ExternalId,
  grupo_novo as ProductCode,
  grupo_novo as cgcloud__Consumer_Goods_External_Product_Id__c,
  '' as cgcloud__category__c,
  'Category' as cgcloud__Product_Level__c, 	  
  'grupo' as tipo,   
  rc.ambiente,
  3 as ordem
FROM 
  `ds_view_trusted.vw_cgcloud_product2_hierarquia_base` 
cross join 
  w_recordtype as rc
cross join
  w_cgcloud_template as tp

where
  rc.name = 'Product Group'
  and tp.name = 'Grupo'
  and rc.ambiente = tp.ambiente

union all
select 
  distinct
  matnr, classe_terapeutica as Name, 
  rc.id as RecordTypeId, 
  tp.id as cgcloud__Product_Template__c,
  classe_terapeutica as cgcloud__Description_1_Language_1__c,
  classe_terapeutica as ExternalId,
  classe_terapeutica as ProductCode,
  classe_terapeutica as cgcloud__Consumer_Goods_External_Product_Id__c,
  grupo_novo as cgcloud__category__c, 
  'SubCategory' as cgcloud__Product_Level__c, 	    
  'classe' as tipo, 
  rc.ambiente,
  2 as ordem
FROM  
  `ds_view_trusted.vw_cgcloud_product2_hierarquia_base` 
cross join 
  w_recordtype as rc
cross join
  w_cgcloud_template as tp

where
  rc.name = 'Product Group'
  and tp.name = 'Classe Terapêutica'
  and rc.ambiente = tp.ambiente

union all

select 
  distinct
  matnr, principio_ativo as Name, 
  rc.id as RecordTypeId, 
  tp.id as cgcloud__Product_Template__c,

  principio_ativo as cgcloud__Description_1_Language_1__c,
  principio_ativo as ExternalId,
  principio_ativo as ProductCode,
  principio_ativo as cgcloud__Consumer_Goods_External_Product_Id__c,
  classe_terapeutica as cgcloud__category__c, 
  'Brand' as cgcloud__Product_Level__c, 	  
  'principio' as tipo,
  rc.ambiente,
  1 as ordem
FROM 
  `ds_view_trusted.vw_cgcloud_product2_hierarquia_base` 
cross join 
  w_recordtype as rc
cross join
  w_cgcloud_template as tp

where
  rc.name = 'Product Group'
  and tp.name = 'Princípio Ativo'
  and rc.ambiente = tp.ambiente
  and coalesce(matnr, '') <> ''
order by matnr, ambiente, ordem  ;