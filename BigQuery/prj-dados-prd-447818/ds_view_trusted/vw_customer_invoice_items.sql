CREATE VIEW `prj-dados-prd-447818.ds_view_trusted.vw_customer_invoice_items`
AS WITH
  w_lista_doc AS 
  (
     SELECT * FROM `ds_view_trusted.vw_customer_invoice`
  )

  SELECT w_doc.vbeln,
         w_doc.auart, 
         w_doc.vkorg, 
         w_doc.werks,
         w_doc.vtweg, 
         w_doc.kunnr,
         w_doc.name1,
         w_doc.regio, 
         w_doc.erdat,
         w_doc.erzet, 
         w_doc.xblnr,
         w_doc.operador_logistico,
         w_doc.fkdat, 
         w_doc.zterm,
         w_doc.waerk,
         w_doc.netwr_cab,
         w_doc.mwsbp_cab,
         w_doc.st_cab,
         w_doc.fci_cab,
         w_doc.descfin_cab,
         vbrp.matnr,
         vbrp.arktx,
         vbrp.pstyv,
         vbrp.fkimg,
         vbrp.vrkme,
         ztbsf004.netpr as netpr_item,
         ztbsf004.netwr as netwr_item,
         ztbsf004.mwsbp as mwsbp_item,
         ztbsf004.st as st_item,
         ztbsf004.fci as fci_item,
         ztbsf004.descfin as descfin_item,
         ztbsf004.percom as percom_item,
         ztbsf004.aubel as ordem_sap,
         ztbsf004.aupos as item_ordem_sap,
         w_doc.pedido_esfera,
         w_doc.usuario_esfera,
         w_doc.referencia_externa,
         w_doc.codigo_repre,
         w_doc.margem_contribuicao_cab,
         w_doc.margem_contabil_cab,

         ztbsd058.margemccp as margem_contribuicao_item,
         ztbsd058.margemctb as margem_contabil_item,
         ztbsd058.icms as icms -- AEO 100725

    FROM w_lista_doc AS w_doc

         JOIN `sap_raw.vbrp`          AS vbrp     ON vbrp.vbeln = w_doc.vbeln
                                                 AND vbrp.fkimg <> 0                                              
         JOIN `sap_raw.ztbsf004`      AS ztbsf004 ON ztbsf004.vbeln = vbrp.vbeln
                                                 AND ztbsf004.posnr = vbrp.posnr                                               
         LEFT JOIN `sap_raw.ztbsd058` AS ztbsd058 ON ztbsd058.vbeln = vbrp.vbeln
                                                 AND ztbsd058.posnr = vbrp.posnr
   WHERE w_doc.origem = 'S' 
     AND vbrp.erdat >= date_sub(current_date, interval 30 day)

  UNION ALL

  SELECT w_doc_op.vbeln,
         w_doc_op.auart, 
         w_doc_op.vkorg, 
         w_doc_op.werks,
         w_doc_op.vtweg, 
         w_doc_op.kunnr,
         w_doc_op.name1,
         w_doc_op.regio, 
         w_doc_op.erdat,
         w_doc_op.erzet, 
         w_doc_op.xblnr,
         w_doc_op.operador_logistico,
         w_doc_op.fkdat,  
         w_doc_op.zterm,
         w_doc_op.waerk,
         w_doc_op.netwr_cab,
         w_doc_op.mwsbp_cab,
         w_doc_op.st_cab,
         w_doc_op.fci_cab,
         w_doc_op.descfin_cab,
         vbap.matnr,
         vbap.arktx,
         vbap.pstyv,
         vbap.kwmeng as fkimg,
         vbap.zieme  as vrkme,
         ztbsf004.netpr as netpr_item,
         ztbsf004.netwr as netwr_item,
         ztbsf004.mwsbp as mwsbp_item,
         ztbsf004.st as st_item,
         ztbsf004.fci as fci_item,
         ztbsf004.descfin as descfin_item,
         ztbsf004.percom as percom_item,
         ztbsf004.aubel as ordem_sap,
         ztbsf004.aupos as item_ordem_sap,
         w_doc_op.pedido_esfera,
         w_doc_op.usuario_esfera,
         w_doc_op.referencia_externa,
         w_doc_op.codigo_repre,
         w_doc_op.margem_contribuicao_cab,
         w_doc_op.margem_contabil_cab,
         ztbsd058.margemccp as margem_contribuicao_item,
         ztbsd058.margemctb as margem_contabil_item, 
         ztbsd058.icms as icms -- AEO 100725

    FROM w_lista_doc AS w_doc_op
         
         JOIN `sap_raw.vbap`          AS vbap     ON vbap.vbeln = w_doc_op.vbeln
         JOIN `sap_raw.ztbsf004`      AS ztbsf004 ON ztbsf004.vbeln = vbap.vbeln
                                                 AND ztbsf004.posnr = vbap.posnr
         LEFT JOIN `sap_raw.ztbsd058` AS ztbsd058 ON ztbsd058.vbeln = vbap.vbeln         
                                                 AND ztbsd058.posnr = vbap.posnr                                            
   WHERE w_doc_op.origem = 'O' 
   AND vbap.erdat >= date_sub(current_date, interval 30 day)

ORDER BY vbeln;