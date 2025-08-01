CREATE VIEW `prj-dados-prd-447818.ds_view_trusted.vw_customer_invoice`
AS 
WITH
  w_lista_base AS 
  (
     SELECT * FROM `ds_view_trusted.vw_customer_invoice_base`
  )

  SELECT DISTINCT 
         vbrk.vbeln,
         vbrk.auart, 
         vbrk.vkorg, 
         vbrp.werks,         
         vbrk.vtweg, 
         vbrk.kunnr,
         kna1.name1,
         kna1.regio, 
         vbrk.erdat,
         vbrk.erzet, 
         vbrk.xblnr,
         vbrk.operador_logistico,
         vbrk.fkdat, 
         vbrk.zterm,
         ztbsf003.waerk,
         ztbsf003.netwr as netwr_cab,
         ztbsf003.mwsbp as mwsbp_cab,
         ztbsf003.st as st_cab,
         ztbsf003.fci as fci_cab,         
         ztbsf003.descfin as descfin_cab,
         ztbsf004.aubel as ordem_sap,
         vbak.ihrez as referencia_externa,
         -- codigo do user no SF tem 6 posicoes
         lpad(ltrim(vbpa.lifnr, '0'), 6, '0') AS codigo_repre,
         ztbsd040.margemccp as margem_contribuicao_cab,
         ztbsd040.margemctb as margem_contabil_cab,
         vbrk.origem,
         ztbsd015.zpedorig as pedido_esfera,
         lpad(ltrim(ztbsd015.zcodoper, '0'), 6, '0') AS usuario_esfera,
         vbkd.zlsch as cgcloud__Payment_Method__c,
         vbkd.mandt
    FROM w_lista_base AS vbrk
         JOIN (
               SELECT mandt, vbeln,  ANY_VALUE(werks) AS werks
                 FROM `sap_raw.vbrp`
                 where erdat >= date_sub(current_date, interval 30 day)
                GROUP BY mandt, vbeln
               ) AS vbrp 
            ON vbrk.mandt = vbrp.mandt and vbrk.vbeln = vbrp.vbeln  
         
		   JOIN `sap_raw.kna1`          AS kna1     ON kna1.mandt = vbrk.mandt and kna1.kunnr = vbrk.kunnr
         JOIN `sap_raw.ztbsf003`      AS ztbsf003 ON ztbsf003.mandt = vbrk.mandt and ztbsf003.vbeln = vbrk.vbeln

         JOIN (
               SELECT mandt, vbeln, ANY_VALUE(aubel) AS aubel
                 FROM `sap_raw.ztbsf004`
                GROUP BY mandt, vbeln
               ) AS ztbsf004 
            ON ztbsf004.mandt = vbrk.mandt AND ztbsf004.vbeln = vbrk.vbeln

         LEFT JOIN `sap_raw.ztbsd015` AS ztbsd015 ON ztbsd015.mandt = ztbsf004.mandt AND ztbsd015.zordem = ztbsf004.aubel
         LEFT JOIN `sap_raw.vbak`     AS vbak     ON vbak.vbeln = ztbsf004.aubel
         --vbak.mandt = ztbsf004.mandt AND vbak.vbeln = ztbsf004.aubel
         LEFT JOIN `sap_raw.vbkd`     AS vbkd     ON vbkd.mandt = vbak.mandt and vbkd.vbeln = vbak.vbeln   -- AEO 110725 cgcloud__Payment_Method__c     
         LEFT JOIN `sap_raw.vbpa`     AS vbpa     ON vbpa.mandt = vbrk.mandt AND vbpa.vbeln = vbrk.vbeln
                                                 AND vbpa.parvw = 'ZR'    
         LEFT JOIN `sap_raw.ztbsd040` AS ztbsd040 ON ztbsd040.mandt = vbrk.mandt and ztbsd040.vbeln = vbrk.vbeln 

   WHERE vbrk.origem = 'S'
      and vbkd.fkdat >= date_sub(current_date, interval 30 day)
      and vbak.erdat >= date_sub(current_date, interval 30 day)
      and vbak.ihrez not like 'SF-%'
   

     UNION ALL

  SELECT DISTINCT
         vbak.vbeln,
         vbak.auart, 
         vbak.vkorg, 
         vbap.werks,
         vbak.vtweg, 
         vbak.kunnr,
         kna1.name1,
         kna1.regio, 
         vbak.erdat,
         vbak.erzet, 
         vbak.xblnr,
         vbak.operador_logistico,
         vbak.fkdat,  
         vbkd.zterm,
         ztbsf003.waerk,
         ztbsf003.netwr as netwr_cab,
         ztbsf003.mwsbp as mwsbp_cab,
         ztbsf003.st as st_cab,
         ztbsf003.fci as fci_cab,
         ztbsf003.descfin as descfin_cab,
         ztbsf004.aubel as ordem_sap,
         COALESCE(ztbsd015.znumext, vbak.ihrez) as referencia_externa,
         lpad(ltrim(vbpa.lifnr, '0'), 6, '0') AS codigo_repre,
         ztbsd040.margemccp as margem_contribuicao_cab,
         ztbsd040.margemctb as margem_contabil_cab,
         vbak.origem,
         ztbsd015.zpedorig as pedido_esfera,
         lpad(ltrim(ztbsd015.zcodoper, '0'), 6, '0') AS usuario_esfera,
         vbkd.zlsch as cgcloud__Payment_Method__c,
         vbak.mandt
    FROM w_lista_base AS vbak  
	
         JOIN (
               SELECT mandt, vbeln, ANY_VALUE(werks) AS werks
                 FROM `sap_raw.vbap`
                 where erdat >= date_sub(current_date, interval 30 day)                 
                GROUP BY mandt, vbeln
               ) AS vbap 
            ON vbap.mandt = vbak.mandt AND vbap.vbeln = vbak.vbeln 
			
         JOIN `sap_raw.kna1`          AS kna1     ON kna1.mandt = vbak.mandt AND kna1.kunnr = vbak.kunnr
         JOIN `sap_raw.vbkd`          AS vbkd     ON vbkd.mandt = vbak.mandt AND vbkd.vbeln = vbak.vbeln  -- AEO 110725 cgcloud__Payment_Method__c
         JOIN `sap_raw.ztbsf003`      AS ztbsf003 ON ztbsf003.mandt = vbak.mandt AND ztbsf003.vbeln = vbak.vbeln

         JOIN (
               SELECT mandt, vbeln, ANY_VALUE(aubel) AS aubel
                 FROM `sap_raw.ztbsf004`
                GROUP BY mandt, vbeln
               ) AS ztbsf004 
            ON ztbsf004.mandt = vbak.mandt AND ztbsf004.vbeln = vbak.vbeln
		
         LEFT JOIN `sap_raw.ztbsd015` AS ztbsd015 ON ztbsd015.mandt = ztbsf004.mandt AND ztbsd015.zordem = ztbsf004.aubel
         LEFT JOIN `sap_raw.vbpa`     AS vbpa     ON vbpa.mandt = vbak.mandt  AND vbpa.vbeln = vbak.vbeln
                                                 AND vbpa.parvw = 'ZR'                                  
         LEFT JOIN `sap_raw.ztbsd040` AS ztbsd040 ON ztbsd040.mandt = vbak.mandt AND ztbsd040.vbeln = vbak.vbeln 
         
   WHERE vbak.origem = 'O'
      and vbkd.fkdat >= date_sub(current_date, interval 30 day)
      and vbak.erdat >= date_sub(current_date, interval 30 day)         
      and vbak.ihrez not like 'SF-%';