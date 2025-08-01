CREATE VIEW `prj-dados-prd-447818.ds_view_trusted.vw_product2`
AS with
  w_atualizados as (
    select 
      distinct ltrim(matnr, '0') as matnr
    from 
      (
      select matnr from sap_raw.mara where recordstamp >= date_sub(current_timestamp, interval 2 hour )
      union all
      select matnr from sap_raw.makt where recordstamp >= date_sub(current_timestamp, interval 2 hour )
      union all
      select matnr from sap_raw.marm where recordstamp >= date_sub(current_timestamp, interval 2 hour )
      union all
      select matnr from sap_raw.marc where recordstamp >= date_sub(current_timestamp, interval 2 hour )
      )  
  ),
w_hierarquia as (
  -- produto
  -- principio ativo - cgcloud__Criterion_3_Product__r.Name
    -- classe - cgcloud__Criterion_2_Product__r.Name
      -- grupo - cgcloud__Criterion_1_Product__r.Name
  with w_crit_1 as (
    SELECT 
      ltrim(matnr, '0') as matnr, name as cgcloud__Criterion_1_Product__c
    FROM `ds_view_trusted.vw_cgcloud_product2_hierarquia` 
    where 
      tipo = 'grupo'
  ),
  w_crit_2 as (
    SELECT 
      ltrim(matnr, '0') as matnr, name as cgcloud__Criterion_2_Product__c
    FROM `ds_view_trusted.vw_cgcloud_product2_hierarquia` 
    where 
      tipo = 'classe'
  ),
  w_crit_3 as (
    SELECT 
      ltrim(matnr, '0') as matnr, name as cgcloud__Criterion_3_Product__c
    FROM `ds_view_trusted.vw_cgcloud_product2_hierarquia` 
    where 
      tipo = 'principio'
  )
  SELECT 
    c1.matnr,
    coalesce(c1.cgcloud__Criterion_1_Product__c, '')  as cgcloud__Criterion_1_Product__c, 
    coalesce(c2.cgcloud__Criterion_2_Product__c, '')  as cgcloud__Criterion_2_Product__c,
    coalesce(c3.cgcloud__Criterion_3_Product__c, '')  as cgcloud__Criterion_3_Product__c  
  FROM 
    w_crit_1 c1
  join 
    w_crit_2 c2
    on c1.matnr = c2.matnr
  join 
    w_crit_3 c3
    on c1.matnr = c3.matnr
  ), 
  w_recordtype as 
  (
    select id, ambiente
    from `ds_trusted.sf_recordtype_template`
    where name = 'Product' and SobjectType = 'Product2'
  ),
  w_cgcloud_template as 
  (
    select id, ambiente
    from `ds_trusted.sf_recordtype_template`
    where objeto = 'cgcloud__Product_Template__c' and name in ('Product', 'Produto')
  ),
  w_id as (
      select rc.id as rc_id, tp.id as tp_id, rc.ambiente
      from w_recordtype as rc
      join w_cgcloud_template as tp on rc.ambiente = tp.ambiente
  )
SELECT
  distinct 
  ltrim(mara.matnr, '0') as ProductCode,
  ltrim(mara.matnr, '0') as cgcloud__Consumer_Goods_Product_Code__c,   
  ltrim(mara.matnr, '0') as cgcloud__Product_Short_Code__c,
  ltrim(mara.matnr, '0') as cgcloud__Consumer_Goods_External_Product_Id__c,
  makt.maktx as cgcloud__Short_Description_Language_1__c,
  true as IsActive,   
  '4' as cgcloud__State__c,
  mara.ean11 as cgcloud__GTIN__c, 
  makt.maktx as Name, 
  mara.mhdhb as cgcloud__Pack_Size__c,
  makt.maktx as cgcloud__Description_1_Language_1__c,  
  'Product' as cgcloud__Product_Level__c,
  
  FORMAT_DATE("%Y-%m-%d",current_date ) as cgcloud__Delivery_Valid_From__c,
  '2099-12-31' as cgcloud__Delivery_Valid_Thru__c,     
 
  FORMAT_DATE("%Y-%m-%d",current_date ) as cgcloud__Field_Valid_From__c,
  '2099-12-31' as cgcloud__Field_Valid_Thru__c,
  
  FORMAT_DATE("%Y-%m-%d",current_date ) as cgcloud__KAM_Valid_From__c,
  '2099-12-31' as cgcloud__KAM_Valid_Thru__c,
  
  FORMAT_DATE("%Y-%m-%d",current_date ) as cgcloud__New_Item_Valid_From__c,
  '2099-12-31' as cgcloud__New_Item_Valid_Thru__c, 
  id.rc_id as RecordTypeId, 
  id.tp_id as cgcloud__Product_Template__c, 
  '0001' as cgcloud__Sales_Org__c, 
  id.ambiente, 
  coalesce(h.cgcloud__Criterion_1_Product__c, '')  as cgcloud__Criterion_1_Product__c, 
  coalesce(h.cgcloud__Criterion_2_Product__c, '')  as cgcloud__Criterion_2_Product__c,
  coalesce(h.cgcloud__Criterion_3_Product__c, '')  as cgcloud__Criterion_3_Product__c, 
  5 as ordem, 
  mara.meins as UnitofMeasure, 
  mara.recordstamp
FROM 
  sap_raw.mara AS mara

JOIN sap_raw.makt AS makt
  ON makt.mandt = mara.mandt
  AND makt.matnr = mara.matnr
  AND makt.spras = 'P'

join sap_raw.marm MAM
  on mara.matnr = MAM.matnr 
  AND mara.mtart in ('FERT', 'ZLIC')
 --AND MAM.meinh = 'CX'    
 --AND MAM.umren = 1
	
join sap_raw.marc mc
  on mc.matnr = mara.matnr 
--  and mc.werks = '3000'

join 
  w_hierarquia h
  on h.matnr = ltrim(mara.matnr, '0')

cross join 
  w_id as id
	
WHERE LEFT(mara.matnr,6) = '000000'
-- aeo 110625 por enquanto desconsidera registros atualizados.
-- AND ltrim(mara.matnr, '0') in (select matnr from w_atualizados)  
--and ltrim(mara.matnr, '0') = '17477'

union all

SELECT 
  distinct name as ProductCode, 
  name as cgcloud__Consumer_Goods_Product_Code__c, 
  name as cgcloud__Product_Short_Code__c,
  name as cgcloud__Consumer_Goods_External_Product_Id__c, 
  name as cgcloud__Short_Description_Language_1__c, 
  True as IsActive, 
  '4' as cgcloud__State__c, 
  '' as cgcloud__GTIN__c, 
  name, 
  0 as cgcloud__Pack_Size__c, 
  name as cgcloud__Description_1_Language_1__c, 
  cgcloud__Product_Level__c, 
  '' as cgcloud__Delivery_Valid_From__c,
  '' as cgcloud__Delivery_Valid_Thru__c,
  '' as cgcloud__Field_Valid_From__c,
  '' as cgcloud__Field_Valid_Thru__c,
  '' as cgcloud__KAM_Valid_From__c,
  '' as cgcloud__KAM_Valid_Thru__c,
  '' as cgcloud__New_Item_Valid_From__c,
  '' as cgcloud__New_Item_Valid_Thru__c,
  RecordTypeId,
  cgcloud__Product_Template__c, 
  '0001' as cgcloud__Sales_Org__c,
  ambiente, 
  '' as cgcloud__Criterion_1_Product__c, 
  '' as cgcloud__Criterion_2_Product__c,
  '' as cgcloud__Criterion_3_Product__c,
  ordem,
  '' as UnitOfMeasure, 
  current_timestamp as recordstamp
FROM 
  `ds_view_trusted.vw_cgcloud_product2_hierarquia` 

ORDER BY ambiente, ordem, ProductCode


;