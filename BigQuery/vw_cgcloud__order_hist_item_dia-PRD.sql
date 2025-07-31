WITH w_vbrk as (
  SELECT vbrk.vbeln, vbrk.erdat
  FROM `sap_raw.vbrk` as vbrk
  WHERE 
      TIMESTAMP_TRUNC(vbrk.recordstamp, DAY) >= date_sub(current_timestamp, interval 1 DAY)
      AND 
      vbrk.recordstamp >= date_sub(current_timestamp, interval 30 minute) 
      --AEO 190625 - somente documentos da picklist DocumentType__c
      -- WHERE  vbrk.fkart IN  ('YBOR', 'YMGD', 'YDEP', 'YSER', 'YRCS' ,'YBON','YCAC', 
      --                        'YREB', 'YTR1', 'ZEXP', 'YBRB', 'YBRO', 'YNFE', 'YREM',
      --                        'YREC', 'YRED', 'YBOE', 'YBOD', 'YEXO')  
      and vbrk.fkart IN  ('YVOL', 'YBOR', 'YBON')
      AND vbrk.vkorg <> '0080'
      AND coalesce(vbrk.sfakn,'') = ''      
      AND coalesce(vbrk.fksto,'') <> 'X'
),      
w_vbak as (
  SELECT vbak.vbeln, vbak.erdat
  FROM `sap_raw.vbak` AS vbak 
  WHERE 
    TIMESTAMP_TRUNC(vbak.recordstamp, DAY) >= date_sub(current_timestamp, interval 1 DAY)
    and vbak.recordstamp >= date_sub(current_timestamp, interval 30 minute)
    --AEO 190625 - somente documentos da picklist cgcloud__Document_Type__c
    -- WHERE vbak.auart IN ('YVOL','YDOL')
    and vbak.auart IN ('YVOL', 'YBOR', 'YBON')   
    and vbak.ihrez not like 'SF-%'  
     
), w_lista_documentos as (
    select distinct vbeln
    from (
      select vbeln from w_vbrk
      union all
      select vbeln from w_vbak
    )
), w_ztbsf004 as (
  SELECT ztbsf004.aubel, ztbsf004.vbeln, ztbsf004.posnr, 
      ztbsf004.netpr as netpr_item, --
      ztbsf004.netwr as netwr_item,               
      ztbsf004.mwsbp as mwsbp_item, --
      ztbsf004.st as st_item, -- 
      ztbsf004.fci as fci_item,--
      ztbsf004.descfin as descfin_item,--
      ztbsf004.percom as percom_item,--
      ztbsf004.aubel as ordem_sap, --
      ztbsf004.aupos as item_ordem_sap
  FROM `sap_raw.ztbsf004` as ztbsf004
  
  JOIN w_lista_documentos as lst ON lst.vbeln = ztbsf004.vbeln

  WHERE  
         TIMESTAMP_TRUNC(recordstamp, DAY) >= date_sub(current_timestamp, interval 1 DAY)  

   ), w_ztbsd058 as (
    select ztbsd058.vbeln, 
          ztbsd058.posnr, 
          ztbsd058.margemccp as margem_contribuicao_item,
          ztbsd058.margemctb as margem_contabil_item,
          ztbsd058.icms as icms
        from `sap_raw.ztbsd058` as ztbsd058

        JOIN w_lista_documentos as lst ON lst.vbeln = ztbsd058.vbeln

    WHERE  
          TIMESTAMP_TRUNC(recordstamp, DAY) >= date_sub(current_timestamp, interval 1 DAY)  

   )
   ,w_customer_invoice_items as (
    SELECT vbrk.vbeln,
          vbrk.erdat, 
          vbrp.pstyv, --
          vbrp.fkimg, --
          ztbsf004.netpr_item, --
          ztbsf004.netwr_item,         
          ztbsf004.mwsbp_item, --
          ztbsf004.st_item, -- 
          ztbsf004.fci_item,--
          ztbsf004.descfin_item,--
          ztbsf004.percom_item,--
          ztbsf004.ordem_sap, --
          ztbsf004.item_ordem_sap, --
          ztbsd058.margem_contribuicao_item,
          ztbsd058.margem_contabil_item,
          ztbsd058.icms, 
          'S' as origem, 
          vbrp.matnr
      FROM `sap_raw.vbrp` AS vbrp
      
      JOIN w_vbrk as vbrk ON vbrp.vbeln = vbrk.vbeln

      JOIN w_ztbsf004 AS ztbsf004 ON ztbsf004.vbeln = vbrp.vbeln AND ztbsf004.posnr = vbrp.posnr
         
      -- join com VBAK é para desconsiderar resgistros quem venham do SF.
      LEFT JOIN w_vbak  AS vbak     ON vbak.vbeln = ztbsf004.aubel      

      LEFT JOIN w_ztbsd058 AS ztbsd058 ON ztbsd058.vbeln = vbrp.vbeln AND ztbsd058.posnr = vbrp.posnr
  
      WHERE 
        TIMESTAMP_TRUNC(vbrp.recordstamp, DAY) >= date_sub(current_timestamp, interval 1 DAY)

  UNION ALL

  SELECT vbap.vbeln,
          vbak.erdat,
          vbap.pstyv, --
          vbap.kwmeng as fkimg, --
          ztbsf004.netpr_item, --
          ztbsf004.netwr_item,         
          ztbsf004.mwsbp_item, --
          ztbsf004.st_item, -- 
          ztbsf004.fci_item,--
          ztbsf004.descfin_item,--
          ztbsf004.percom_item,--
          ztbsf004.ordem_sap, --
          ztbsf004.item_ordem_sap, --
          ztbsd058.margem_contribuicao_item,
          ztbsd058.margem_contabil_item,
          ztbsd058.icms,
          'O' as origem, 
          vbap.matnr
    
    FROM `sap_raw.vbap` AS vbap 

        JOIN w_vbak AS vbak on vbak.vbeln =  vbap.vbeln  

        JOIN w_ztbsf004      AS ztbsf004 ON ztbsf004.vbeln = vbap.vbeln AND ztbsf004.posnr = vbap.posnr

        LEFT JOIN w_ztbsd058 AS ztbsd058 ON ztbsd058.vbeln = vbap.vbeln AND ztbsd058.posnr = vbap.posnr
      
      WHERE 
        TIMESTAMP_TRUNC(vbap.recordstamp, DAY) >= date_sub(current_timestamp, interval 1 DAY)        

  ORDER  BY vbeln
)

SELECT
  'SAP-'||ltrim(ordem_sap, '0') as cgcloud__order_ExternalId__c,
  ltrim(matnr,'0') as cgcloud__Product_externalid,
  -- external pedido + item + doc de fatura
  ltrim(ordem_sap, '0') ||'-'||item_ordem_sap ||'-'|| vbeln as ExternalID__c,       
  item_ordem_sap as ItemSAP__c, 
  pstyv as item_category, 
  fkimg as cgcloud__Quantity__c,       

  --  valores unitarios do item
  coalesce(netpr_item, 0) as ActualUnitValue__c,       
  coalesce(netpr_item, 0) as cgcloud__Base_Price_Receipt__c,
  coalesce(netpr_item, 0) as cgcloud__Special_Price__c,
  
  st_item as SubstituicaoTributariaSAP__c, 
  descfin_item as DiscountSAP__c, 
  percom_item as InternalComission__c,   
  coalesce(netwr_item, 0) + coalesce(mwsbp_item, 0) as TotalInvoicedAmount__c, -- impostos??


  0 as ActualMargin__c, 

  margem_contribuicao_item as MarginTax__c,  -- margem de contribuição
  margem_contribuicao_item as MarginTaxSAP__c, 
  margem_contabil_item as MarginTaxCTB__c, 
  margem_contabil_item as MarginTaxCTBSAP__c,

  vbeln as InvoiceNumber__c,
  erdat as BillingDate__c, 
  erdat as DataAcordada__c, -- nao tem no sap? por enquanto é a data do faturamento   
  icms as ICMSSAP__c, 
  
  coalesce(netwr_item, 0) + coalesce(mwsbp_item, 0) as cgcloud__Price_Receipt__c, -- impostos??      
FROM 
  w_customer_invoice_items