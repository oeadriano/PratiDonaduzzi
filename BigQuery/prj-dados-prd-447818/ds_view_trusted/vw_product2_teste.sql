CREATE VIEW `prj-dados-prd-447818.ds_view_trusted.vw_product2_teste`
AS with
    w_atualizados as (
        SELECT distinct ltrim(matnr, '0') as matnr
            from
            (
                SELECT matnr FROM sap_raw.mara WHERE recordstamp >= date_sub(current_timestamp, interval 2 hour )
                union all
                SELECT matnr FROM sap_raw.makt WHERE recordstamp >= date_sub(current_timestamp, interval 2 hour )
                union all
                SELECT matnr FROM sap_raw.marm WHERE recordstamp >= date_sub(current_timestamp, interval 2 hour )
                union all
                SELECT matnr FROM sap_raw.marc WHERE recordstamp >= date_sub(current_timestamp, interval 2 hour )
            )  
    ),

    w_materiais_base as (
        SELECT *
          FROM `ds_view_trusted.vw_cgcloud_product2_hierarquia_base` as base
               -- por enquanto desconsidera registros atualizados.
         --WHERE ltrim(matnr, '0') in (select matnr from w_atualizados)  
    ),

    w_recordtype as (
        SELECT id, ambiente
          FROM `ds_trusted.sf_recordtype_template`
         WHERE name = 'Product' 
           AND SobjectType = 'Product2'
    ),

    w_cgcloud_template as (
        SELECT id, ambiente
          FROM `ds_trusted.sf_recordtype_template`
         WHERE objeto = 'cgcloud__Product_Template__c' 
           AND name in ('Product', 'Produto')
    ),

    w_id as (
        SELECT rc.id as rc_id, tp.id as tp_id, rc.ambiente
          FROM w_recordtype as rc          
               JOIN w_cgcloud_template AS tp ON rc.ambiente = tp.ambiente
    )

    SELECT distinct 
           ltrim(w_mat.matnr, '0') as ProductCode,
           ltrim(w_mat.matnr, '0') as cgcloud__Consumer_Goods_Product_Code__c,   
           ltrim(w_mat.matnr, '0') as cgcloud__Product_Short_Code__c,
           ltrim(w_mat.matnr, '0') as cgcloud__Consumer_Goods_External_Product_Id__c,
           w_mat.maktx as cgcloud__Short_Description_Language_1__c,
           true as IsActive,   
           '4' as cgcloud__State__c,
           w_mat.ean11 as cgcloud__GTIN__c, 
           w_mat.maktx as Name, 
           w_mat.mhdhb as cgcloud__Pack_Size__c,
           w_mat.maktx as cgcloud__Description_1_Language_1__c,  
           'Product'   as cgcloud__Product_Level__c,
  
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
           coalesce(w_mat.grupo_novo, '')  as cgcloud__Criterion_1_Product__c, 
           coalesce(w_mat.classe_terapeutica, '')  as cgcloud__Criterion_2_Product__c,
           coalesce(w_mat.principio_ativo, '')  as cgcloud__Criterion_3_Product__c, 
           5 as ordem, 
           w_mat.meins as UnitofMeasure
      
      FROM w_materiais_base AS w_mat
           CROSS JOIN w_id   AS id
	 WHERE LEFT(w_mat.matnr,6) = '000000'


;