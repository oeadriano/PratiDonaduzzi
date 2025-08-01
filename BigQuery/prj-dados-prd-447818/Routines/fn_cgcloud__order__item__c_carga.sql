
CREATE OR REPLACE TABLE FUNCTION `prj-dados-prd-447818.ds_view_trusted.fn_cgcloud__order__item__c_carga`(d_ini DATE, d_fim DATE) RETURNS TABLE<cgcloud__order_ExternalId__c STRING, cgcloud__Product_externalid STRING, ExternalID__c STRING, ItemSAP__c STRING, item_category STRING, cgcloud__Quantity__c NUMERIC, ActualUnitValue__c NUMERIC, cgcloud__Base_Price_Receipt__c NUMERIC, cgcloud__Special_Price__c NUMERIC, SubstituicaoTributariaSAP__c NUMERIC, DiscountSAP__c NUMERIC, InternalComission__c NUMERIC, TotalInvoicedAmount__c NUMERIC, ActualMargin__c NUMERIC, MarginTax__c NUMERIC, MarginTaxSAP__c NUMERIC, MarginTaxCTB__c NUMERIC, MarginTaxCTBSAP__c NUMERIC, InvoiceNumber__c STRING, BillingDate__c DATE, DataAcordada__c DATE, ICMSSAP__c NUMERIC, cgcloud__Price_Receipt__c NUMERIC> AS (
WITH w_vbrk as (
  SELECT vbrk.vbeln, vbrk.erdat, 
  case 
    when vbrk.fkart in (
      -- vendas
      'YBOR', --Venda Normal
      'YEXP', --Fatura Exportação
      'YMGD', --Vend.MG Preço Margem
      'YRCS', --Rem.p/ cta. s.fatura
      'YSER', --Serviço s/ Retenção
      'YDEP' --Fatura Ordem BR    
    ) then 'FAT' else 'DEV'
    end as tipo
  FROM `sap_raw.vbrk` as vbrk
  WHERE 
      vbrk.fkdat between d_ini and d_fim
      --vbrk.fkdat between '2025-07-01' and '2025-07-05'
      AND vbrk.fkart IN
      (
      -- devoluções
      'YBOD', --Dev. Bonific. NF Cli
      'YBOE', --Dev. Bonific. NF Pro
      'YBRB', --D.Norm/Lic.Ind.NF.Cl
      'YBRO', --D.Norm/Lic.Ind.NF.Pr
      'YEXO', --Devolução Exportação
      'YNFE', --D.Norm/Lic.Ind.NFECL
      'YREC', --Dev.Repos.NF.Cliente
      'YTR1', --T.Norm/Lic.Ind.NF.Pr
      'YREM', --Dev.Repos.NF.Própria
      -- vendas
      'YBOR', --Venda Normal
      'YEXP', --Fatura Exportação
      'YMGD', --Vend.MG Preço Margem
      'YRCS', --Rem.p/ cta. s.fatura
      'YSER', --Serviço s/ Retenção
      'YDEP' --Fatura Ordem BR
      )
      AND vbrk.vkorg <> '0080'
      AND coalesce(vbrk.sfakn,'') = ''      
      AND coalesce(vbrk.fksto,'') <> 'X'
),      
w_vbak as (
  SELECT vbak.vbeln, vbak.erdat, 
  case 
    when vbak.auart in (
      -- vendas
      'YBOR', --Venda Normal
      'YEXP', --Fatura Exportação
      'YMGD', --Vend.MG Preço Margem
      'YRCS', --Rem.p/ cta. s.fatura
      'YSER', --Serviço s/ Retenção
      'YDEP' --Fatura Ordem BR    
    ) then 'FAT' else 'DEV'
    end as tipo
  FROM `sap_raw.vbak` AS vbak 
  WHERE 
  --vbak.erdat between '2025-07-01' and '2025-07-05'
    vbak.erdat between d_ini and d_fim
    and vbak.auart IN 
    (
       -- devoluções 
      'YBOD', --Dev. Bonific. NF Cli
      'YBOE', --Dev. Bonific. NF Pro
      'YBRB', --D.Norm/Lic.Ind.NF.Cl
      'YBRO', --D.Norm/Lic.Ind.NF.Pr
      'YEXO', --Devolução Exportação
      'YNFE', --D.Norm/Lic.Ind.NFECL
      'YREC', --Dev.Repos.NF.Cliente
      'YTR1', --T.Norm/Lic.Ind.NF.Pr
      'YREM', --Dev.Repos.NF.Própria
      -- vendas
      'YBOR', --Venda Normal
      'YEXP', --Fatura Exportação
      'YMGD', --Vend.MG Preço Margem
      'YRCS', --Rem.p/ cta. s.fatura
      'YSER', --Serviço s/ Retenção
      'YDEP'  --Fatura Ordem BR
    )
    and vbak.ihrez not like 'SF-%'  
     
)/*, w_lista_documentos as (
    select distinct vbeln
    from (
      select vbeln from w_vbrk
      union all
      select vbeln from w_vbak
    )
)*/
, w_ztbsf004 as (
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

  left join w_vbak as vbak on vbak.vbeln = ztbsf004.vbeln
  left join w_vbrk as vbrk on vbrk.vbeln = ztbsf004.vbeln
 

   ), w_ztbsd058 as (
    select ztbsd058.vbeln, 
          ztbsd058.posnr, 
          ztbsd058.margemccp as margem_contribuicao_item,
          ztbsd058.margemctb as margem_contabil_item,
          ztbsd058.icms as icms
        from `sap_raw.ztbsd058` as ztbsd058

      left join w_vbak as vbak on vbak.vbeln = ztbsd058.vbeln
      left join w_vbrk as vbrk on vbrk.vbeln = ztbsd058.vbeln
   )
   ,w_customer_invoice_items as (
    SELECT DISTINCT vbrk.vbeln,
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
          vbrp.matnr, 
          vbrk.tipo
      FROM `sap_raw.vbrp` AS vbrp
      
      JOIN w_vbrk as vbrk ON vbrp.vbeln = vbrk.vbeln

      JOIN w_ztbsf004 AS ztbsf004 ON ztbsf004.vbeln = vbrp.vbeln AND ztbsf004.posnr = vbrp.posnr
         
      -- join com VBAK é para desconsiderar resgistros quem venham do SF.
      LEFT JOIN w_vbak  AS vbak     ON vbak.vbeln = ztbsf004.aubel      

      LEFT JOIN w_ztbsd058 AS ztbsd058 ON ztbsd058.vbeln = vbrp.vbeln AND ztbsd058.posnr = vbrp.posnr
  
  UNION ALL

  SELECT DISTINCT vbap.vbeln,
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
          vbap.matnr, 
          vbak.tipo
    
    FROM `sap_raw.vbap` AS vbap 

        JOIN w_vbak AS vbak on vbak.vbeln =  vbap.vbeln  

        JOIN w_ztbsf004      AS ztbsf004 ON ztbsf004.vbeln = vbap.vbeln AND ztbsf004.posnr = vbap.posnr

        LEFT JOIN w_ztbsd058 AS ztbsd058 ON ztbsd058.vbeln = vbap.vbeln AND ztbsd058.posnr = vbap.posnr

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
  case when tipo = 'DEV' then coalesce(netpr_item, 0) * (-1) else coalesce(netpr_item, 0) end as ActualUnitValue__c,       
  case when tipo = 'DEV' then coalesce(netpr_item, 0) * (-1) else coalesce(netpr_item, 0) end as cgcloud__Base_Price_Receipt__c,
  case when tipo = 'DEV' then coalesce(netpr_item, 0) * (-1) else coalesce(netpr_item, 0) end as cgcloud__Special_Price__c,
  
  case when tipo = 'DEV' then coalesce(st_item, 0) * (-1) else coalesce(st_item, 0) end as SubstituicaoTributariaSAP__c, 
  descfin_item as DiscountSAP__c, 
  percom_item as InternalComission__c, 
  
  case 
    when tipo = 'DEV' then  (coalesce(netwr_item, 0) + coalesce(mwsbp_item, 0)) * (-1) 
    else coalesce(netwr_item, 0) + coalesce(mwsbp_item, 0) 
  end as TotalInvoicedAmount__c,       

  0 as ActualMargin__c, 

  margem_contribuicao_item as MarginTax__c,  -- margem de contribuição
  margem_contribuicao_item as MarginTaxSAP__c, 
  margem_contabil_item as MarginTaxCTB__c, 
  margem_contabil_item as MarginTaxCTBSAP__c,

  vbeln as InvoiceNumber__c,
  erdat as BillingDate__c, 
  erdat as DataAcordada__c, -- nao tem no sap? por enquanto é a data do faturamento   
  icms as ICMSSAP__c, 

  case 
    when tipo = 'DEV' then  (coalesce(netwr_item, 0) + coalesce(mwsbp_item, 0)) * (-1) 
    else coalesce(netwr_item, 0) + coalesce(mwsbp_item, 0)
  end as cgcloud__Price_Receipt__c
  
  FROM 
    w_customer_invoice_items
);