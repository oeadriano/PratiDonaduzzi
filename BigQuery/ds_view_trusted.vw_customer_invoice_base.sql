WITH
  w_data_corte as (
     select date_sub(current_date, interval 1 day ) as dt_ini
  ),
  w_lista_documentos AS 
  (
    select 
    distinct vbeln, mandt
    from 
      (      
      -- particionamento fkdat
      -- cluster mandt vbeln
      SELECT vbrk.vbeln, vbrk.mandt
        FROM `sap_raw.vbrk` AS vbrk
      WHERE 
        fkdat >= (select dt_ini from w_data_corte)
        and vbrk.recordstamp >= date_sub(current_timestamp, interval 30 minute)

        UNION ALL

      -- particionamento erdat
      -- cluster mandt vbeln
      SELECT vbak.vbeln, vbak.mandt
        FROM `sap_raw.vbak` AS vbak
      WHERE 
        erdat >= (select dt_ini from w_data_corte)
        and vbak.recordstamp >= date_sub(current_timestamp, interval 30 minute)

        UNION ALL      

      -- particionamento nao tem
      -- cluster mandt vbeln
      SELECT ztbsf003.vbeln, ztbsf003.mandt
        FROM `sap_raw.ztbsf003` AS ztbsf003
      WHERE ztbsf003.recordstamp >= date_sub(current_timestamp, interval 30 minute)

        UNION ALL            

      -- particionamento nao tem
      -- cluster mandt vbeln
      SELECT ztbsf004.vbeln, ztbsf004.mandt
        FROM `sap_raw.ztbsf004` AS ztbsf004
      WHERE ztbsf004.recordstamp >= date_sub(current_timestamp, interval 30 minute)
      GROUP BY vbeln, mandt
      )      
  )
  SELECT  'S' as origem,
          vbrk.vbeln,
          vbrk.fkart as auart,
          vbrk.vkorg, 
          vbrk.vtweg, 
          vbrk.kunag as kunnr,
          vbrk.erdat,
          vbrk.erzet, 
          vbrk.xblnr,
          '' as operador_logistico,
          vbrk.fkdat, 
          vbrk.zterm,
          '' as ihrez,
          vbrk.mandt

    FROM  w_lista_documentos AS doc 

          JOIN `sap_raw.vbrk` AS vbrk 
            ON vbrk.mandt = doc.mandt 
            and vbrk.vbeln = doc.vbeln
  --AEO 190625 - somente documentos da picklist DocumentType__c
  -- WHERE  vbrk.fkart IN  ('YBOR', 'YMGD', 'YDEP', 'YSER', 'YRCS' ,'YBON','YCAC', 
  --                        'YREB', 'YTR1', 'ZEXP', 'YBRB', 'YBRO', 'YNFE', 'YREM',
  --                        'YREC', 'YRED', 'YBOE', 'YBOD', 'YEXO')  
  WHERE  vbrk.fkart IN  ('YVOL', 'YBOR', 'YBON')
      AND vbrk.vkorg <> '0080'
      AND coalesce(vbrk.sfakn,'') = ''      
      AND coalesce(vbrk.fksto,'') <> 'X' 
      AND vbrk.fkdat >= (select dt_ini from w_data_corte)

  UNION ALL

  SELECT  'O' as origem,
          vbak.vbeln,
          vbak.auart, 
          vbak.vkorg, 
          vbak.vtweg, 
          vbak.kunnr,
          vbak.erdat,
          vbak.erzet, 
          
          CASE 
               WHEN vbak.bstnk IS NULL OR vbak.bstnk = '' THEN NULL
               WHEN STRPOS(vbak.bstnk, '/') > 0 THEN SUBSTR(vbak.bstnk, STRPOS(vbak.bstnk, '/') + 1)
               ELSE vbak.bstnk
          END as xblnr,

          CASE 
               WHEN vbak.bstnk IS NULL OR vbak.bstnk = '' THEN NULL
               WHEN STRPOS(vbak.bstnk, '/') > 0 THEN SUBSTR(vbak.bstnk, 1, STRPOS(vbak.bstnk, '/') - 1)
               ELSE vbak.bstnk
          END as operador_logistico,          

         vbak.bstdk as fkdat,  
         vbkd.zterm,
         vbak.ihrez,
         vbak.mandt

    FROM w_lista_documentos AS doc 

         JOIN `sap_raw.vbak` AS vbak 
          ON vbak.mandt = doc.mandt 
          and vbak.vbeln = doc.vbeln

         JOIN `sap_raw.vbkd` AS vbkd 
          ON vbkd.mandt = vbak.mandt 
          and vbkd.vbeln = vbak.vbeln
  --AEO 190625 - somente documentos da picklist cgcloud__Document_Type__c
  -- WHERE vbak.auart IN ('YVOL','YDOL')
   WHERE vbak.auart IN ('YVOL', 'YBOR', 'YBON')   
   AND vbak.erdat >= (select dt_ini from w_data_corte)
   AND vbkd.fkdat >= (select dt_ini from w_data_corte)