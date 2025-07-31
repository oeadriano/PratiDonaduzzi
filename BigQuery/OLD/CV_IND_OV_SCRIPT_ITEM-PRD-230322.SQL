-- AEO 23.03.22 duplicidade de etl_remessa e ETL_VBRK retirada
-- CV_IND_OV_SCRIPT_ITEM
with  
  w_ipi as (SELECT KNUMV, 
                   KSCHL, 
                   KPOSN,  
                   KWERT 
              FROM `dados-prod.raw.KONV_part` 
              WHERE KSCHL = 'BX23' 
                AND KDATU_DT >= DATE_ADD(CURRENT_DATE, INTERVAL -2 MONTH)
                AND KDATU_DT <= CURRENT_DATE
                AND KWERT > 0 

), 
  w_bol as (SELECT MANDT,  
                   KNUMV,  
                   KPOSN, 
                   KSCHL, 
                   SUM(KWERT) AS KWERT  
              FROM `dados-prod.raw.KONV_part` 
              WHERE KSCHL = 'ZBOL' 
                AND KDATU_DT >= DATE_ADD(CURRENT_DATE, INTERVAL -2 MONTH)
                AND KDATU_DT <= CURRENT_DATE
              GROUP BY MANDT, KNUMV, KPOSN, KSCHL 

), 
  w_icmi as (SELECT KNUMV --Nº condição do documento 
                   ,KPOSN --Item 
                   ,KWERT --Valor da Condição **** 
                   ,KBETR --Montante ****** 
                   ,WAERS --Moeda ***** 
                   ,KPEIN --Por ****** 
                   ,KMEIN --Unidade do Preço ***** 
                   ,KSCHL --Tp_Cond_Pr ***** 
                   ,STUNR 
               FROM `dados-prod.raw.KONV_part` 
               WHERE KSCHL IN ('ICMI' ) 
                AND KDATU_DT >= DATE_ADD(CURRENT_DATE, INTERVAL -2 MONTH)
                AND KDATU_DT <= CURRENT_DATE
               ORDER BY KNUMV, KPOSN  
),
  w_kna1 as (
    select kunnr,
           name1,
           stcd1
      from `dados-prod.raw.KNA1`
  ),
  w_ydsd217 as (
        SELECT VBELN,
               VENDEDOR,
               EQUIPE_VENDAS as cad_supervisor,
               CONCAT(VENDEDOR,EQUIPE_VENDAS) AS CHAVE_VC,
          FROM dados-prod.raw.YDSD217 
  )

--CV_IND_OV_SCRIPT_ITEM 

SELECT  
  AUX.MANDANTE,       
  AUX.DOC_VENDA, 
  AUX.DOC_ITEM, 
  AUX.CATEG_ITEM, 
  AUX.EMPRESA,  
  AUX.CENTRO, 
  AUX.DEPOSITO, 
  AUX.MATNR, 
  AUX.COD_MATERIAL, 
  AUX.DESCR_MATERIAL, 
  AUX.CLIENTE,   
  AUX.DT_OV,   
  AUX.DT_OV_D,      
  AUX.DOC_TIPO,   
  AUX.ORG_VENDAS, 
  AUX.CANAL_DISTR, 
  AUX.EQ_VENDAS, 
  AUX.ESCR_VENDA, 
  AUX.SET_ATIV, 
  AUX.LOC_EXP, 
  AUX.COCKPIT, 
  AUX.ANOMES, 
  AUX.QTDECALCULADA, 
  VBKD.ZTERM as COND_PAG, 
  CASE WHEN ESP.DESCRICAO LIKE 'ESPECIAL%' THEN 0 ELSE AUX.VLR_MONTIMPOSTO END AS VLR_MONTIMPOSTO,   
  CASE WHEN ESP.DESCRICAO LIKE 'ESPECIAL%' THEN 0 ELSE AUX.VLR_LIQUIDO END AS VLR_LIQUIDO,  
  CASE WHEN ESP.DESCRICAO LIKE 'ESPECIAL%' THEN 0 ELSE AUX.VLR_PEDIDO END AS VLR_PEDIDO,   
  CASE WHEN ESP.DESCRICAO LIKE 'ESPECIAL%' THEN 0 ELSE AUX.VLR_BOLETO END AS VLR_BOLETO,   
  CASE WHEN ( ESP.VALOR = 'YBP2' ) OR ( ESP.VALOR = 'YBP3' ) THEN 0 ELSE AUX.CUSTO_UNIT END AS CUSTO_UNIT,   
  CASE WHEN ESP.DESCRICAO LIKE 'ESPECIAL%' THEN 0 ELSE AUX.VLR_IPI END AS VLR_IPI, 
  AUX.ETL_VBAK, 
  --AUX.ETL_VBRK, 
  '' as ETL_VBRK,
  --AUX.ETL_LIPS, 
  '' as ETL_LIPS, 
  AUX.ETL_OV,
  AUX.AUGRU,
  AUX.BSTNK,
  AUX.ERZET as DOC_VHORA,
  aux.ernam,
  kna1.name1 as nome_cliente,
  kna1.stcd1 as cnpj_cliente,
  ydsd217.vendedor,
  ydsd217.cad_supervisor,
  ydsd217.chave_vc

FROM -- Select Bloqueio de Estoque -- 
  (SELECT 
    A.MANDT           AS MANDANTE,                        
    A.VBELN           AS DOC_VENDA, 
    B.POSNR           AS DOC_ITEM, 
    B.PSTYV           AS CATEG_ITEM, 
    A.BUKRS_VF        AS EMPRESA,  
    B.WERKS           AS CENTRO, 
    B.LGORT           AS DEPOSITO, 
    B.MATNR           AS MATNR, 
    CAST(B.MATNR AS INT)   AS COD_MATERIAL, 
    B.ARKTX           AS DESCR_MATERIAL, 
    A.KUNNR           AS CLIENTE,   
    A.ERDAT           AS DT_OV,   
    PARSE_DATE("%Y%m%d",A.ERDAT) AS DT_OV_D,        
    A.AUART           AS DOC_TIPO,   
    A.VKORG           AS ORG_VENDAS, 
    A.VTWEG           AS CANAL_DISTR, 
    A.VKGRP           AS EQ_VENDAS, 
    A.VKBUR           AS ESCR_VENDA, 
    B.SPART           AS SET_ATIV, 
    B.VSTEL           AS LOC_EXP, 
    'Bloqueio de Estoque' AS COCKPIT, 
    SUBSTR(A.ERDAT, 1,6) AS ANOMES, 
    --SUBSTR(REPLACE(CAST(CURRENT_DATE AS STRING),'-',''),1,6) AS ANOMES, 
    CASE WHEN B.VRKME = 'CX' THEN CASE WHEN COALESCE(B.KWMENG,0) > 0 THEN COALESCE(KITEM.KWERT,0) / COALESCE(KITEM.KBETR,0) END ELSE COALESCE(B.KWMENG,0) END AS QTDECALCULADA, 
    CASE WHEN A.AUART = 'ZBON' THEN 0 ELSE COALESCE(Sum(B.MWSBP),0) END AS VLR_MONTIMPOSTO,     
    CASE WHEN A.AUART = 'ZBON' THEN 0 ELSE COALESCE(Sum(B.NETWR),0) END AS VLR_LIQUIDO,     
    CASE WHEN A.AUART = 'ZBON' THEN 0 ELSE COALESCE(KITEM.KWERT,0) END AS VLR_PEDIDO,      
    CASE WHEN A.AUART = 'ZBON' THEN 0 ELSE COALESCE(Sum(D.KWERT),0) END AS VLR_BOLETO,     
    PC.STPRS  AS CUSTO_UNIT,     
    SUM(COALESCE(IPI.KWERT,0)) AS VLR_IPI,     
    (PC.STPRS * CASE WHEN B.VRKME = 'CX' THEN CASE WHEN COALESCE(B.KWMENG,0) > 0 THEN COALESCE(KITEM.KWERT,0) / COALESCE(KITEM.KBETR,0) END ELSE COALESCE(B.KWMENG,0) END )AS CUSTO_TOTAL, 
    A.ETL_TIMESTAMP AS ETL_VBAK, 
    --V.ETL_TIMESTAMP AS ETL_VBRK, 
	'' as ETL_VBRK,
    --C.ETL_TIMESTAMP AS ETL_LIPS, 
    '' as ETL_LIPS, 	
    CURRENT_TIMESTAMP AS ETL_OV,
    A.AUGRU,
    A.BSTNK,
    A.ERZET,
    a.ernam
 
  /*-- Cabeçalho Docto Vendas --*/ 
  FROM `dados-prod.raw.VBAK`                  AS A 
   
  /*-- Linha de Itens Docto Venda --*/ 
  JOIN `dados-prod.raw.VBAP`                  AS B 
  ON    A.MANDT = B.MANDT 
  AND   A.VBELN = B.VBELN 
   
  /*-- Documento SD: status de cabeçalho --*/ 
  LEFT JOIN `dados-prod.raw.VBUK`             AS E 
  ON    A.MANDT   = E.MANDT 
  AND   A.VBELN   = E.VBELN  
   
  /*-- VBRP --*/ 
  LEFT JOIN `dados-prod.raw.VBRP`              AS G 
  ON    A.MANDT   = G.MANDT 
  AND   A.VBELN   = G.AUBEL  
  AND   B.POSNR   = G.AUPOS  
 

  /*
  LEFT JOIN `dados-prod.raw.VBRK`              AS V 
  ON    G.MANDT = V.MANDT 
  AND   G.VBELN = V.VBELN 
  */
   
    /*-- LIPS --
  LEFT JOIN `dados-prod.raw.LIPS`              AS C 
  ON    B.MANDT   = C.MANDT 
  AND   B.VBELN   = C.VGBEL  
  AND   B.POSNR   = C.VGPOS
  */ 

  LEFT JOIN w_bol AS D 
    ON    B.MANDT = D.MANDT 
    AND   A.KNUMV = D.KNUMV 
    AND   B.POSNR = D.KPOSN  
      
  LEFT JOIN w_icmi AS KITEM 
    ON ( A.KNUMV = KITEM.KNUMV AND B.POSNR = KITEM.KPOSN ) 
   
  LEFT JOIN 
    (SELECT A.MATNR, A.STPRS FROM `dados-prod.raw.MBEW` A 
      INNER JOIN 
    (SELECT MATNR, MAX(TIMESTAMP_MILLIS(TIMESTAMP)) AS TIMESTAMP FROM `dados-prod.raw.MBEW` 
      WHERE OWNPR = 'X' 
      AND BWKEY IN ('1001', '1100', '1200', '1401') 
      GROUP BY MATNR   
     ) AS B 
       ON  A.MATNR = B.MATNR 
       AND TIMESTAMP_MILLIS(A.TIMESTAMP) = B.TIMESTAMP 
    WHERE A.OWNPR = 'X' 
    AND A.BWKEY IN ( '1001', '1100', '1200', '1401' ) 
    AND A.STPRS > 0 
    ORDER BY A.MATNR 
    ) AS PC 
    ON B.MATNR = PC.MATNR 
   
  LEFT JOIN w_ipi AS IPI 
    ON ( A.KNUMV = IPI.KNUMV  
    AND   B.POSNR = IPI.KPOSN)        
  WHERE A.AUART IN (SELECT VALOR FROM `dados-prod.raw.YDBI001` 
                    WHERE RELATORIO = 'DASHBOARD DETALHADO'  
                    AND NOME_VIEW = 'CV_DASHBOARD_DETALHE' 
                    AND FILTRO    = 'AUART' 
                    AND DESCRICAO = 'TP. DOC - BLOQUEIO DE ESTOQUE' 
                    ORDER BY VALOR ) 
  AND   B.SHKZG <> 'X' 
  AND   G.AUBEL IS NULL  
  AND   B.ABGRU NOT IN (SELECT VALOR FROM `dados-prod.raw.YDBI001` WHERE RELATORIO = 'DASHBOARD DETALHADO' 
                        AND NOME_VIEW = 'CV_DASHBOARD_DETALHE' 
                        AND FILTRO    = 'ABGRU' 
                        AND DESCRICAO = 'MOT. RECUSA - BLOQUEIO DE ESTOQUE') 
  AND   A.LIFSK IN (SELECT VALOR FROM `dados-prod.raw.YDBI001` 
                     WHERE RELATORIO = 'DASHBOARD DETALHADO' 
                     AND NOME_VIEW = 'CV_DASHBOARD_DETALHE' 
                     AND FILTRO    = 'LIFSK' 
                     AND DESCRICAO = 'MOT. BLOQUEIO - BLOQUEIO DE ESTOQUE' ) 
  AND B.WERKS    IN ( SELECT WERKS FROM `dados-prod.raw.YDSD051`) 
  AND A.BUKRS_VF IN ( SELECT BUKRS FROM `dados-prod.raw.YDSD051`) 
  AND A.VKORG    IN ( SELECT BUKRS FROM `dados-prod.raw.YDSD051`)  
  AND E.LFSTK IN ('A','B') --Sem Remessa 
  AND A.VTWEG <= '10' 
  --AND   A.ERDAT >= 'DTINI' 
  AND A.ERDAT >= REPLACE(CAST(DATE_ADD((CURRENT_DATE), INTERVAL -2 MONTH)AS STRING),'-','') 
  --AND   A.ERDAT <= 'DTFIM' 
  AND A.ERDAT <= REPLACE(CAST(CURRENT_DATE AS STRING),'-','') 
  -- NAO LEVAR A RASPADINHA PARA O MAPA DE VENDA ( _SYS_BIC.YDBI006 ) 
  AND B.MATNR <> '000000000000702219'   
  -- O select abaixo é feito pra GARANTIR QUE NENHUM ITEM TENHA RECUSA FINANCEIRA  
  AND   A.VBELN NOT IN (SELECT VBELN FROM `dados-prod.raw.VBAP`  
                        WHERE ABGRU IN (SELECT LOW FROM `dados-prod.raw.TVARVC`WHERE NAME = 'YDSD_MP_ORDER_STATUS_REC_FINAN' AND LOW <> ''))                        
  GROUP BY A.MANDT,  
           A.VBELN, 
           B.POSNR, 
           B.PSTYV, 
           A.AUART,  
           A.ERDAT,  
           A.BUKRS_VF,  
           A.VKORG,  
           A.VTWEG,  
           A.LIFSK,   
           A.KUNNR,  
           A.VKGRP, 
           A.VKBUR, 
           B.MATNR,   
           B.ARKTX,  
           B.SPART,  
           B.WERKS,  
           B.LGORT,  
           B.VSTEL,  
           B.ABGRU, 
           B.VRKME, 
           B.VRKME, 
           B.KWMENG, 
           KITEM.KWERT, 
           KITEM.KBETR, 
           IPI.KWERT, 
           PC.STPRS, 
           A.ETL_TIMESTAMP, 
           --V.ETL_TIMESTAMP, 
           --C.ETL_TIMESTAMP,
           A.AUGRU,
           A.BSTNK,
           A.ERZET,
           a.ernam
           
  UNION ALL 

    SELECT 
      A.MANDT           AS MANDANTE,                        
      A.VBELN           AS DOC_VENDA, 
      B.POSNR           AS DOC_ITEM, 
      B.PSTYV           AS CATEG_ITEM, 
      A.BUKRS_VF        AS EMPRESA,  
      B.WERKS           AS CENTRO, 
      B.LGORT           AS DEPOSITO, 
      B.MATNR           AS MATNR, 
      cast(B.MATNR as INT)   AS COD_MATERIAL, 
      B.ARKTX           AS DESCR_MATERIAL, 
      A.KUNNR           AS CLIENTE,   
      A.ERDAT           AS DT_OV,   
      PARSE_DATE("%Y%m%d",A.ERDAT)  AS DT_OV_D,      
      A.AUART           AS DOC_TIPO,   
      A.VKORG           AS ORG_VENDAS, 
      A.VTWEG           AS CANAL_DISTR, 
      A.VKGRP           AS EQ_VENDAS, 
      A.VKBUR           AS ESCR_VENDA, 
      B.SPART           AS SET_ATIV, 
      B.VSTEL           AS LOC_EXP, 
      'Bloqueio Financeiro' AS COCKPIT, 
      SUBSTR(A.ERDAT, 1,6) AS ANOMES, 
      --SUBSTR(REPLACE(CAST(CURRENT_DATE AS STRING),'-',''),1,6) AS ANOMES, 
      CASE WHEN B.VRKME = 'CX' THEN CASE WHEN COALESCE(B.KWMENG,0) > 0 THEN COALESCE(KITEM.KWERT,0) / COALESCE(KITEM.KBETR,0) END ELSE COALESCE(B.KWMENG,0) END AS QTDECALCULADA, 
      CASE WHEN A.AUART = 'ZBON' THEN 0 ELSE COALESCE(Sum(B.MWSBP),0) END AS VLR_MONTIMPOSTO, 
      CASE WHEN A.AUART = 'ZBON' THEN 0 ELSE COALESCE(Sum(B.NETWR),0) END AS VLR_LIQUIDO,  
      CASE WHEN A.AUART = 'ZBON' THEN 0 ELSE COALESCE(KITEM.KWERT,0) END AS VLR_PEDIDO, 
      CASE WHEN A.AUART = 'ZBON' THEN 0 ELSE COALESCE(Sum(D.KWERT),0) END AS VLR_BOLETO, 
      PC.STPRS as CUSTO_UNIT, 
      SUM(COALESCE(IPI.KWERT,0)) AS IPI, 
      (CASE WHEN B.VRKME = 'CX' THEN CASE WHEN COALESCE(B.KWMENG,0) > 0 THEN COALESCE(KITEM.KWERT,0) / COALESCE(KITEM.KBETR,0) END ELSE COALESCE(B.KWMENG,0) END * PC.STPRS) AS CUSTO_TOTAL, 
      A.ETL_TIMESTAMP AS ETL_VBAK, 
      --V.ETL_TIMESTAMP as ETL_VBRK, 
	  '' as ETL_VBRK,	  
      --C.ETL_TIMESTAMP AS ETL_LIPS, 
	  '' as ETL_LIPS, 
      CURRENT_TIMESTAMP AS ETL_OV,
      A.AUGRU,
      A.BSTNK,
      A.ERZET,
      a.ernam

  /*-- Linha de Itens Docto Venda --*/ 
  FROM `dados-prod.raw.VBAK`                   AS A 
   
  /*-- Cabeçalho Docto Vendas --*/ 
  JOIN `dados-prod.raw.VBAP`              AS B 
  ON    A.MANDT = B.MANDT 
  AND   A.VBELN = B.VBELN 
   
  /*-- Documento SD: status de cabeçalho --*/ 
  LEFT JOIN `dados-prod.raw.VBUK`             AS E 
  ON    A.MANDT   = E.MANDT 
  AND   A.VBELN   = E.VBELN  
   
  /*-- VBRP --*/ 
  LEFT JOIN `dados-prod.raw.VBRP`             AS G 
  ON    A.MANDT   = G.MANDT 
  AND   A.VBELN   = G.AUBEL  

  /*LEFT JOIN `dados-prod.raw.VBRK`              AS V 
  ON    G.MANDT = V.MANDT 
  AND   G.VBELN = V.VBELN 
  */
 
   /*-- LIPS --
  LEFT JOIN `dados-prod.raw.LIPS`              AS C 
  ON    B.MANDT   = C.MANDT 
  AND   B.VBELN   = C.VGBEL  
  AND   B.POSNR   = C.VGPOS  
  */
   
  LEFT JOIN w_bol AS D 
    ON    B.MANDT = D.MANDT 
    AND   A.KNUMV = D.KNUMV 
    AND   B.POSNR = D.KPOSN  
   
  LEFT JOIN w_icmi AS KITEM 
    ON ( A.KNUMV = KITEM.KNUMV AND B.POSNR = KITEM.KPOSN ) 
   
  LEFT JOIN 
  ( 
    SELECT A.MATNR, A.STPRS 
    FROM 
    `dados-prod.raw.MBEW` A 
      INNER JOIN 
    ( 
      SELECT MATNR, MAX(TIMESTAMP_MILLIS(TIMESTAMP)) AS TIMESTAMP FROM `dados-prod.raw.MBEW` 
      WHERE OWNPR = 'X' 
        AND BWKEY IN ('1001', '1100', '1200', '1401') 
      GROUP BY MATNR   
     ) B 
       ON  A.MATNR = B.MATNR 
       AND TIMESTAMP_MILLIS(A.TIMESTAMP) = B.TIMESTAMP 
    WHERE A.OWNPR = 'X' 
      AND A.BWKEY IN ( '1001', '1100', '1200', '1401' ) 
      AND A.STPRS > 0 
    ORDER BY A.MATNR 
  ) AS PC 
    ON B.MATNR = PC.MATNR 
   
  LEFT JOIN w_ipi AS IPI 
      ON ( A.KNUMV = IPI.KNUMV  
     AND   B.POSNR = IPI.KPOSN) 
         
  WHERE A.AUART IN ( SELECT VALOR FROM `dados-prod.raw.YDBI001`  
             WHERE RELATORIO = 'DASHBOARD DETALHADO' 
               AND NOME_VIEW = 'CV_DASHBOARD_DETALHE' 
             AND FILTRO    = 'AUART' 
                 AND DESCRICAO = 'TP. DOC - BLOQUEIO FINANCEIRO'   
             ORDER BY VALOR ) 
  AND   B.SHKZG <> 'X' 
  AND   G.AUBEL IS NULL 
  --- INSERIDO EM 21/10/2020 PARA BATER VALOR DO MAPA DE VENDAS COM O DASHFATURAMENTO 
  AND   (   (  B.ABGRU = ''     AND 
             E.CMGST IN ('B') AND 
             A.LIFSK = ''     AND 
             A.VBELN NOT IN ( SELECT VBELN 
                                    FROM `dados-prod.raw.YDMM017` 
                                    WHERE COALESCE( MBLNR, '' ) <> '' ) 
          ) 
     OR  
        ( A.LIFSK IN ('01','Y1','Y2','Y4','YF','YP','YQ','YR') AND 
          B.ABGRU NOT IN (SELECT ABGRU  
                                FROM `dados-prod.raw.YDSD050`  
                                WHERE RECUSA_FIN = 'X') 
        ) 
    ) 
  --- INSERIDO EM 21/10/2020 PARA BATER VALOR DO MAPA DE VENDAS COM O DASHFATURAMENTO 
  AND   (( B.ABGRU = '' AND E.CMGST IN ('B') ) 
          OR A.LIFSK IN ( SELECT VALOR FROM `dados-prod.raw.YDBI001`  
                WHERE RELATORIO = 'DASHBOARD DETALHADO' 
                  AND NOME_VIEW = 'CV_DASHBOARD_DETALHE' 
                  AND FILTRO    = 'LIFSK' 
                  AND DESCRICAO = 'MOT. BLOQUEIO - BLOQUEIO FINANCEIRO' )) 
  AND   B.WERKS IN ( SELECT WERKS FROM `dados-prod.raw.YDSD051`) 
  AND   E.LFSTK = 'A' --Sem Remessa 
  AND   A.VTWEG <= '10' 
  --AND   A.ERDAT >= 'DTINI' 
  AND A.ERDAT >= REPLACE(CAST(DATE_ADD((CURRENT_DATE), INTERVAL -2 MONTH)AS STRING),'-','') 
  --AND   A.ERDAT <= 'DTFIM' 
  AND A.ERDAT <= REPLACE(CAST(CURRENT_DATE AS STRING),'-','') 
   
  -- NAO LEVAR A RASPADINHA PARA O MAPA DE VENDA ( _SYS_BIC.YDBI006 ) 
  AND B.MATNR <> '000000000000702219'   
   
  -- O select abaixo é feito pra GARANTIR QUE NENHUM ITEM TENHA RECUSA FINANCEIRA  
  -- DEIXAR ASSIM 
  AND   A.VBELN NOT IN ( SELECT VBELN FROM `dados-prod.raw.VBAP`  
                               WHERE ABGRU IN ( SELECT LOW FROM `dados-prod.raw.TVARVC` 
                                                  WHERE NAME = 'YDSD_MP_ORDER_STATUS_REC_FINAN' 
                                                    AND LOW <> '' 
                       ) ) 
                        
  GROUP BY A.MANDT, 
           A.VBELN, 
           B.POSNR, 
           B.PSTYV, 
           A.AUART,  
           A.ERDAT,  
           A.BUKRS_VF,  
           A.VKORG,  
           A.VTWEG,  
           A.LIFSK,   
           A.KUNNR,  
           A.VKGRP, 
           A.VKBUR, 
           B.MATNR,   
           B.ARKTX, 
           B.SPART,  
           B.WERKS,  
           B.LGORT,  
           B.VSTEL,  
           B.ABGRU, 
           B.VRKME, 
           B.KWMENG, 
           KITEM.KWERT, 
           KITEM.KBETR, 
           PC.STPRS, 
           A.ETL_TIMESTAMP, 
           --V.ETL_TIMESTAMP, 
           --C.ETL_TIMESTAMP,
           A.AUGRU,
           A.BSTNK,
           A.ERZET,
           a.ernam

  UNION ALL 
   
                -- Select Recusa Financeiro -- 
    SELECT 
            A.MANDT           AS MANDANTE,                        
            A.VBELN           AS DOC_VENDA, 
            B.POSNR           AS DOC_ITEM, 
            B.PSTYV           AS CATEG_ITEM, 
            A.BUKRS_VF        AS EMPRESA,  
            B.WERKS           AS CENTRO, 
            B.LGORT           AS DEPOSITO, 
            B.MATNR           AS MATNR, 
            cast(B.MATNR as INT)   AS COD_MATERIAL, 
            B.ARKTX           AS DESCR_MATERIAL, 
            A.KUNNR           AS CLIENTE,   
            A.ERDAT           AS DT_OV,   
            CAST(CONCAT(SUBSTR(A.ERDAT, 0 , 4), '-' ,SUBSTR(A.ERDAT, 5 , 2), '-' , SUBSTR(A.ERDAT, 7 , 2) ) AS DATE)  AS DT_OV_D,      
            A.AUART           AS DOC_TIPO,   
            A.VKORG           AS ORG_VENDAS, 
            A.VTWEG           AS CANAL_DISTR, 
            A.VKGRP           AS EQ_VENDAS, 
            A.VKBUR           AS ESCR_VENDA, 
            B.SPART           AS SET_ATIV, 
            B.VSTEL           AS LOC_EXP, 
            'Recusa Financeiro'   AS COCKPIT, 
            SUBSTR(A.ERDAT, 1,6) AS ANOMES, 
            --SUBSTR(REPLACE(CAST(CURRENT_DATE AS STRING),'-',''),1,6) AS ANOMES, 
            CASE WHEN B.VRKME = 'CX' THEN CASE WHEN COALESCE(B.KWMENG,0) > 0 THEN COALESCE(KITEM.KWERT,0) / COALESCE(KITEM.KBETR,0) END ELSE COALESCE(B.KWMENG,0) END AS QTDECALCULADA, 
            CASE WHEN A.AUART = 'ZBON' THEN 0 ELSE COALESCE(Sum(B.MWSBP),0) END AS VLR_MONTIMPOSTO, 
            CASE WHEN A.AUART = 'ZBON' THEN 0 ELSE COALESCE(Sum(B.NETWR),0) END AS VLR_LIQUIDO, 
            CASE WHEN A.AUART = 'ZBON' THEN 0 ELSE COALESCE(KITEM.KWERT,0) END AS VLR_PEDIDO, 
            CASE WHEN A.AUART = 'ZBON' THEN 0 ELSE COALESCE(Sum(D.KWERT), 0) END AS VLR_BOLETO, 
            PC.STPRS as CUSTO_UNIT, 
            SUM(COALESCE(IPI.KWERT,0)) AS IPI, 
            (CASE WHEN B.VRKME = 'CX' THEN CASE WHEN COALESCE(B.KWMENG,0) > 0 THEN COALESCE(KITEM.KWERT,0) / COALESCE(KITEM.KBETR,0) END ELSE COALESCE(B.KWMENG,0) END * PC.STPRS) AS CUSTO_TOTAL, 
            A.ETL_TIMESTAMP AS ETL_VBAK, 
			--V.ETL_TIMESTAMP AS ETL_VBRK, 
			'' as ETL_VBRK,
            --C.ETL_TIMESTAMP AS ETL_LIPS, 
			'' as ETL_LIPS, 			
            CURRENT_TIMESTAMP AS ETL_OV,
            A.AUGRU,
            A.BSTNK,
            A.ERZET,
            a.ernam

  /*-- cabec Docto Venda --*/ 
  FROM `dados-prod.raw.VBAK`                   AS A 
   
  /*-- Itens Docto Vendas --*/ 
  JOIN `dados-prod.raw.VBAP`                   AS B 
  ON    A.MANDT = B.MANDT 
  AND   A.VBELN = B.VBELN 
   
  /*-- Motivo de recusa -- */ 
  JOIN `dados-prod.raw.TVAGT`                  AS T 
  ON   B.MANDT = T.MANDT 
  AND  B.ABGRU = T.ABGRU 
  AND  T.SPRAS = 'P' 
   
  /*-- Documento SD: status de cabeçalho --*/ 
  LEFT JOIN `dados-prod.raw.VBUK`             AS E 
  ON    A.MANDT   = E.MANDT 
  AND   A.VBELN   = E.VBELN  
   
  /*-- VBRP --*/ 
  LEFT JOIN `dados-prod.raw.VBRP`             AS G 
  ON    A.MANDT   = G.MANDT 
  AND   A.VBELN   = G.AUBEL  
 
  /*LEFT JOIN `dados-prod.raw.VBRK`              AS V 
  ON    G.MANDT = V.MANDT 
  AND   G.VBELN = V.VBELN 
  */
    /*-- LIPS --
  LEFT JOIN `dados-prod.raw.LIPS`              AS C 
  ON    B.MANDT   = C.MANDT 
  AND   B.VBELN   = C.VGBEL  
  AND   B.POSNR   = C.VGPOS
  */
   
  /*-- Recusa Financeira --*/ 
  LEFT JOIN `dados-prod.raw.YDSD050`               AS H 
  ON    B.MANDT   = H.MANDT 
  AND   B.ABGRU   = H.ABGRU  
  AND   H.RECUSA_FIN = 'X' 
   
  LEFT JOIN w_bol AS D 
    ON    B.MANDT = D.MANDT 
    AND   A.KNUMV = D.KNUMV 
    AND   B.POSNR = D.KPOSN  
   
  LEFT JOIN w_icmi AS KITEM 
    ON ( A.KNUMV = KITEM.KNUMV AND B.POSNR = KITEM.KPOSN ) 
   
  LEFT JOIN 
  ( 
    SELECT A.MATNR, A.STPRS 
    FROM 
    `dados-prod.raw.MBEW` A 
      INNER JOIN 
    ( 
      SELECT MATNR,  MAX(TIMESTAMP_MILLIS(TIMESTAMP)) AS TIMESTAMP FROM  `dados-prod.raw.MBEW` 
      WHERE OWNPR = 'X' 
        AND BWKEY IN ('1001', '1100', '1200', '1401') 
      GROUP BY MATNR   
     ) B 
       ON  A.MATNR = B.MATNR 
       AND TIMESTAMP_MILLIS(A.TIMESTAMP)= B.TIMESTAMP 
    WHERE A.OWNPR = 'X' 
      AND A.BWKEY IN ( '1001', '1100', '1200', '1401' ) 
      AND A.STPRS > 0 
    ORDER BY A.MATNR 
  ) AS PC 
    ON B.MATNR = PC.MATNR 
   
  LEFT JOIN w_ipi AS IPI 
      ON ( A.KNUMV = IPI.KNUMV  
     AND   B.POSNR = IPI.KPOSN) 
         
  WHERE B.SHKZG <> 'X' 
  AND   G.AUBEL IS NULL 
  AND   B.WERKS IN ( SELECT WERKS FROM `dados-prod.raw.YDSD051`) 
  AND   E.LFSTK = 'A' --Sem Remessa 
  AND   A.LIFSK NOT IN ('ZB') /* inclusão em 09/02/2017 -- Bruno Marcos */ 
  AND   A.VTWEG <= '10' 
  --AND LEFT ("A"."ERDAT", 6) = DTAUX  
  AND LEFT (A.ERDAT, 6) = LEFT(REPLACE(CAST(CURRENT_DATE AS STRING),'-',''),6)   
   
  -- NAO LEVAR A RASPADINHA PARA O MAPA DE VENDA ( _SYS_BIC.YDBI006 ) 
  AND B.MATNR <> '000000000000702219'    
   
  -- O select abaixo é feito pra verificar pelo menos um item  
  -- tiver a Recusa Financeira, toda a Ordem deve ter o mesmo Status 
  -- DEIXAR ASSIM 
  AND   A.VBELN IN ( SELECT VBELN FROM `dados-prod.raw.VBAP`  
                         WHERE ABGRU IN ( SELECT LOW FROM `dados-prod.raw.TVARVC` 
                                          WHERE NAME = 'YDSD_MP_ORDER_STATUS_REC_FINAN' 
                                          AND LOW <> '' 
                       ) ) 
   
  GROUP BY A.MANDT, 
           A.VBELN, 
           B.POSNR, 
           B.PSTYV, 
           A.AUART,  
           A.ERDAT,  
           A.BUKRS_VF,  
           A.VKORG,  
           A.VTWEG,  
           A.LIFSK,   
           A.KUNNR,  
           A.VKGRP, 
           A.VKBUR, 
           B.MATNR,   
           B.ARKTX, 
           B.SPART,  
           B.WERKS,  
           B.LGORT,  
           B.VSTEL,  
           B.ABGRU, 
           B.VRKME, 
           B.KWMENG, 
           KITEM.KWERT, 
           KITEM.KBETR, 
          --IPI.KWERT,-- 
           PC.STPRS, 
           A.ETL_TIMESTAMP, 
           --V.ETL_TIMESTAMP, 
           --C.ETL_TIMESTAMP,
           A.AUGRU,
           A.BSTNK,
           A.ERZET,
           a.ernam

             
  UNION ALL 
   
                -- Select Bloqueio Comercial -- 
        SELECT 
                A.MANDT           AS MANDANTE,                        
                A.VBELN           AS DOC_VENDA, 
                B.POSNR           AS DOC_ITEM, 
                B.PSTYV           AS CATEG_ITEM, 
                A.BUKRS_VF        AS EMPRESA,  
                B.WERKS           AS CENTRO, 
                B.LGORT           AS DEPOSITO, 
                B.MATNR           AS MATNR, 
                cast(B.MATNR as INT)   AS COD_MATERIAL, 
                B.ARKTX           AS DESCR_MATERIAL, 
                A.KUNNR           AS CLIENTE,   
                A.ERDAT           AS DT_OV,   
                CAST(CONCAT(SUBSTR(A.ERDAT, 0 , 4), '-' ,SUBSTR(A.ERDAT, 5 , 2), '-' , SUBSTR(A.ERDAT, 7 , 2) ) AS DATE)  AS DT_OV_D,      
                A.AUART           AS DOC_TIPO,   
                A.VKORG           AS ORG_VENDAS, 
                A.VTWEG           AS CANAL_DISTR, 
                A.VKGRP           AS EQ_VENDAS, 
                A.VKBUR           AS ESCR_VENDA, 
                B.SPART           AS SET_ATIV, 
                B.VSTEL           AS LOC_EXP, 
                'Bloqueio Comercial'  AS COCKPIT, 
                SUBSTR(A.ERDAT, 1,6) AS ANOMES, 
                --SUBSTR(REPLACE(CAST(CURRENT_DATE AS STRING),'-',''),1,6) AS ANOMES, 
                CASE WHEN B.VRKME = 'CX' THEN CASE WHEN COALESCE(B.KWMENG,0) > 0 THEN COALESCE(KITEM.KWERT,0) / COALESCE(KITEM.KBETR,0) END ELSE COALESCE(B.KWMENG,0) END AS QTDECALCULADA, 
                CASE WHEN A.AUART = 'ZBON' THEN 0 ELSE COALESCE(Sum(B.MWSBP),0) eND AS VLR_MONTIMPOSTO,  
                CASE WHEN A.AUART = 'ZBON' THEN 0 ELSE COALESCE(Sum(B.NETWR),0) END AS VLR_LIQUIDO, 
                CASE WHEN A.AUART = 'ZBON' THEN 0 ELSE COALESCE(KITEM.KWERT,0) END AS VLR_PEDIDO, 
                CASE WHEN A.AUART = 'ZBON' THEN 0 ELSE COALESCE(Sum(D.KWERT), 0) END AS VLR_BOLETO,  
                PC.STPRS as CUSTO_UNIT,  
                SUM(COALESCE(IPI.KWERT,0)) AS IPI, 
                CASE WHEN B.VRKME = 'CX' THEN CASE WHEN COALESCE(B.KWMENG,0) > 0 THEN COALESCE(KITEM.KWERT,0) / COALESCE(KITEM.KBETR,0) END ELSE COALESCE(B.KWMENG,0) END * PC.STPRS AS CUSTO_TOTAL, 
                A.ETL_TIMESTAMP AS ETL_VBAK, 
                --V.ETL_TIMESTAMP AS ETL_VBRK, 
				'' as ETL_VBRK,
                --C.ETL_TIMESTAMP AS ETL_LIPS, 
				'' as ETL_LIPS, 
                CURRENT_TIMESTAMP AS ETL_OV,
                A.AUGRU,
                A.BSTNK,
                A.ERZET,
                a.ernam

  /*-- Linha de Itens Docto Venda --*/ 
  FROM `dados-prod.raw.VBAK`                 AS A 
   
  /*-- Cabeçalho Docto Vendas --*/ 
  LEFT JOIN `dados-prod.raw.VBAP`              AS B 
  ON    A.MANDT = B.MANDT 
  AND   A.VBELN = B.VBELN 
   
  /*-- Documento SD: status de cabeçalho --*/ 
  LEFT JOIN `dados-prod.raw.VBUK`              AS E 
  ON    A.MANDT   = E.MANDT 
  AND   A.VBELN   = E.VBELN  
 

  /*-- VBRP --*/ 
  LEFT JOIN `dados-prod.raw.VBRP`             AS G 
  ON    A.MANDT   = G.MANDT 
  AND   A.VBELN   = G.AUBEL  
 

  /*LEFT JOIN `dados-prod.raw.VBRK`              AS V 
  ON    G.MANDT = V.MANDT 
  AND   G.VBELN = V.VBELN 
  */
 

    /*-- LIPS --
  LEFT JOIN `dados-prod.raw.LIPS`              AS C 
  ON    B.MANDT   = C.MANDT 
  AND   B.VBELN   = C.VGBEL  
  AND   B.POSNR   = C.VGPOS  
  */
   
  LEFT JOIN w_bol AS D 
    ON    B.MANDT = D.MANDT 
    AND   A.KNUMV = D.KNUMV 
    AND   B.POSNR = D.KPOSN  
   
  LEFT JOIN w_icmi AS KITEM 
    ON ( A.KNUMV = KITEM.KNUMV AND B.POSNR = KITEM.KPOSN ) 
   
  LEFT JOIN 
  ( 
    SELECT A.MATNR, A.STPRS 
    FROM 
    `dados-prod.raw.MBEW` A 
      INNER JOIN 
    ( 
      SELECT MATNR,  MAX(TIMESTAMP_MILLIS(TIMESTAMP)) AS TIMESTAMP FROM `dados-prod.raw.MBEW` 
      WHERE OWNPR = 'X' 
        AND BWKEY IN ('1001', '1100', '1200', '1401') 
      GROUP BY MATNR   
     ) B 
       ON  A.MATNR = B.MATNR 
       AND TIMESTAMP_MILLIS(A.TIMESTAMP) = B.TIMESTAMP 
    WHERE A.OWNPR = 'X' 
      AND A.BWKEY IN ( '1001', '1100', '1200', '1401' ) 
      AND A.STPRS > 0 
    ORDER BY A.MATNR 
  ) AS PC 
    ON B.MATNR = PC.MATNR 
   
  LEFT JOIN w_ipi AS IPI 
      ON ( A.KNUMV = IPI.KNUMV  
     AND   B.POSNR = IPI.KPOSN) 
          
  WHERE E.LFSTK = 'A' /*-- Sem Remessa-- */ 
  AND   B.SHKZG <> 'X' /*-- Sem devolucao --*/ 
  AND   A.LIFSK NOT IN ( SELECT VALOR FROM `dados-prod.raw.YDBI001`  
                 WHERE RELATORIO = 'DASHBOARD DETALHADO' 
                   AND NOME_VIEW = 'CV_DASHBOARD_DETALHE' 
                   AND FILTRO    = 'LIFSK' 
                   AND DESCRICAO = 'MOT. BLOQUEIO - BLOQUEIO COMERCIAL' ) 
  AND   A.LIFSK <> '' 
  AND   E.CMGST NOT IN ('C') 
  AND   A.AUART IN ( SELECT VALOR FROM `dados-prod.raw.YDBI001`  
             WHERE RELATORIO = 'DASHBOARD DETALHADO' 
              AND NOME_VIEW  = 'CV_DASHBOARD_DETALHE' 
              AND FILTRO     = 'AUART' 
              AND DESCRICAO  = 'TP. DOC - BLOQUEIO COMERCIAL' 
                    ORDER BY VALOR ) 
  AND   B.WERKS IN ( SELECT WERKS FROM `dados-prod.raw.YDSD051`) 
  AND   B.ABGRU NOT IN ( SELECT VALOR FROM `dados-prod.raw.YDBI001`  
                 WHERE RELATORIO = 'DASHBOARD DETALHADO' 
                   AND NOME_VIEW = 'CV_DASHBOARD_DETALHE' 
                   AND FILTRO    = 'ABGRU' 
                   AND DESCRICAO = 'MOT. RECUSA - BLOQUEIO COMERCIAL' ) 
  AND   A.VTWEG <= '10' 
  AND ( A.LIFSK NOT IN ( 'ZB','Y6' )  
        AND UPPER(A.VSNMR_V) NOT LIKE '%PHARMA%'  
        AND UPPER(A.VSNMR_V) NOT LIKE '%NEOGRID%'  
      )  
  --AND   A.ERDAT >= 'DTINI' 
  AND A.ERDAT >= REPLACE(CAST(DATE_ADD((CURRENT_DATE), INTERVAL -2 MONTH)AS STRING),'-','') 
  --AND   A.ERDAT <= 'DTFIM' 
  AND A.ERDAT <= REPLACE(CAST(CURRENT_DATE AS STRING),'-','') 
   
  -- NAO LEVAR A RASPADINHA PARA O MAPA DE VENDA ( _SYS_BIC.YDBI006 ) 
  AND B.MATNR <> '000000000000702219'   
   
  -- O select abaixo é feito pra GARANTIR QUE NENHUM ITEM TENHA RECUSA FINANCEIRA  
  -- DEIXAR ASSIM 
  AND   A.VBELN NOT IN ( SELECT VBELN FROM `dados-prod.raw.VBAP`  
                               WHERE ABGRU IN ( SELECT LOW FROM `dados-prod.raw.TVARVC` 
                                                  WHERE NAME = 'YDSD_MP_ORDER_STATUS_REC_FINAN' 
                                                    AND LOW <> '' 
                       ) ) 
                        
  GROUP BY A.MANDT, 
           A.VBELN, 
           B.POSNR, 
           B.PSTYV, 
           A.AUART,  
           A.ERDAT,  
           A.BUKRS_VF,  
           A.VKORG,  
           A.VTWEG,  
           A.LIFSK,   
           A.KUNNR,  
           A.VKGRP, 
           A.VKBUR, 
           B.MATNR,   
           B.ARKTX, 
           B.SPART,  
           B.WERKS,  
           B.LGORT,  
           B.VSTEL,  
           B.ABGRU, 
           B.VRKME, 
           B.KWMENG, 
           KITEM.KWERT, 
           KITEM.KBETR, 
           --IPI.KWERT,-- 
           PC.STPRS, 
           A.ETL_TIMESTAMP, 
           --V.ETL_TIMESTAMP, 
           --C.ETL_TIMESTAMP,
           A.AUGRU,
           A.BSTNK,
           A.ERZET,
           a.ernam

  UNION ALL 
   
                -- Select Itens Cancelados -- 
  SELECT 
  A.MANDT           AS MANDANTE,                        
  A.VBELN           AS DOC_VENDA, 
  B.POSNR           AS DOC_ITEM, 
  B.PSTYV           AS CATEG_ITEM, 
  A.BUKRS_VF        AS EMPRESA,  
  B.WERKS           AS CENTRO, 
  B.LGORT           AS DEPOSITO, 
  B.MATNR           AS MATNR, 
  cast(B.MATNR as INT)   AS COD_MATERIAL, 
  B.ARKTX           AS DESCR_MATERIAL, 
  A.KUNNR           AS CLIENTE,   
  A.ERDAT           AS DT_OV,   
  CAST(CONCAT(SUBSTR(A.ERDAT, 0 , 4), '-' ,SUBSTR(A.ERDAT, 5 , 2), '-' , SUBSTR(A.ERDAT, 7 , 2) ) AS DATE)     AS DT_OV_D,      
  A.AUART           AS DOC_TIPO,   
  A.VKORG           AS ORG_VENDAS, 
  A.VTWEG           AS CANAL_DISTR, 
  A.VKGRP           AS EQ_VENDAS, 
  A.VKBUR           AS ESCR_VENDA, 
  B.SPART           AS SET_ATIV, 
  B.VSTEL           AS LOC_EXP, 
  'Itens Cancelados'    AS COCKPIT, 
  SUBSTR(A.ERDAT, 1,6) AS ANOMES, 
  --SUBSTR(REPLACE(CAST(CURRENT_DATE AS STRING),'-',''),1,6) AS ANOMES, 
   
  CASE  
    WHEN B.VRKME = 'CX' THEN 
      CASE 
      WHEN COALESCE(B.KWMENG,0) > 0 THEN 
        COALESCE(KITEM.KWERT,0) / COALESCE(KITEM.KBETR,0)  
    END 
    ELSE 
      COALESCE(B.KWMENG,0) 
  END AS QTDECALCULADA, 
   
  CASE 
    WHEN A.AUART = 'ZBON' THEN 0 
    ELSE 
      COALESCE(Sum(B.MWSBP),0) 
  END AS VLR_MONTIMPOSTO, 
   
  CASE 
    WHEN A.AUART = 'ZBON' THEN 0 
    ELSE 
      COALESCE(Sum(B.NETWR),0) 
  END AS VLR_LIQUIDO, 
   
  CASE 
    WHEN A.AUART = 'ZBON' THEN 0 
    ELSE 
      COALESCE(KITEM.KWERT,0) 
  END AS VLR_PEDIDO, 
   
  CASE 
    WHEN A.AUART = 'ZBON' THEN 0 
    ELSE 
      COALESCE(Sum(D.KWERT), 0) 
  END AS VLR_BOLETO, 
   
  PC.STPRS as CUSTO_UNIT, 
  SUM(COALESCE(IPI.KWERT,0)) AS IPI, 
    CASE  
    WHEN B.VRKME = 'CX' THEN 
      CASE 
      WHEN COALESCE(B.KWMENG,0) > 0 THEN 
        COALESCE(KITEM.KWERT,0) / COALESCE(KITEM.KBETR,0)  
    END 
    ELSE 
      COALESCE(B.KWMENG,0) 
  END * PC.STPRS AS CUSTO_TOTAL, 
  A.ETL_TIMESTAMP AS ETL_VBAK, 
  --V.ETL_TIMESTAMP AS ETL_VBRK, 
  '' as ETL_VBRK,
  --C.ETL_TIMESTAMP AS ETL_LIPS, 
  '' as ETL_LIPS,   
  CURRENT_TIMESTAMP AS ETL_OV,
  A.AUGRU,
  A.BSTNK,
  A.ERZET,
  a.ernam
   
  /*-- Linha de Itens Docto Venda --*/ 
  FROM `dados-prod.raw.VBAK`                  AS A 
   
  /*-- Cabeçalho Docto Vendas --*/ 
  JOIN `dados-prod.raw.VBAP`                   AS B 
  ON    A.MANDT = B.MANDT 
  AND   A.VBELN = B.VBELN 
   
  /*-- Documento SD: status de cabeçalho --*/ 
  LEFT JOIN `dados-prod.raw.VBUK`              AS E 
  ON    A.MANDT   = E.MANDT 
  AND   A.VBELN   = E.VBELN  
 
  /*-- Mestre de Clientes --*/ 
  JOIN  `dados-prod.raw.KNA1`                  AS K 
  ON   A.MANDT   = K.MANDT 
  AND  A.KUNNR   = K.KUNNR 
   
  /*-- Dsc Motivo Recusa --*/ 
  JOIN `dados-prod.raw.TVAGT`                 AS T 
  ON   B.MANDT   = T.MANDT 
  AND  B.ABGRU   = T.ABGRU 
  AND  T.SPRAS = 'P' 
   
    /*-- VBRP --*/ 
  LEFT JOIN `dados-prod.raw.VBRP`             AS G 
  ON    A.MANDT   = G.MANDT 
  AND   A.VBELN   = G.AUBEL  

  /*LEFT JOIN `dados-prod.raw.VBRK`              AS V 
  ON    G.MANDT = V.MANDT 
  AND   G.VBELN = V.VBELN 
  */
 
   /*-- LIPS --
  LEFT JOIN `dados-prod.raw.LIPS`              AS C 
  ON    B.MANDT   = C.MANDT 
  AND   B.VBELN   = C.VGBEL  
  AND   B.POSNR   = C.VGPOS  
  */ 

  LEFT JOIN w_bol AS D 
    ON    B.MANDT = D.MANDT 
    AND   A.KNUMV = D.KNUMV 
    AND   B.POSNR = D.KPOSN  
  

 LEFT JOIN w_icmi AS KITEM 
    ON ( A.KNUMV = KITEM.KNUMV AND B.POSNR = KITEM.KPOSN ) 
   
  LEFT JOIN 
  ( 
   SELECT A.MATNR, A.STPRS 
    FROM 
    `dados-prod.raw.MBEW` A 
      INNER JOIN 
    ( 
      SELECT MATNR, MAX(TIMESTAMP_MILLIS(TIMESTAMP)) AS TIMESTAMP FROM `dados-prod.raw.MBEW` 
      WHERE OWNPR = 'X' 
        AND BWKEY IN ('1001', '1100', '1200', '1401') 
      GROUP BY MATNR   
     ) B 
       ON  A.MATNR = B.MATNR 
      AND TIMESTAMP_MILLIS(A.TIMESTAMP) = B.TIMESTAMP 
    WHERE A.OWNPR = 'X' 
      AND A.BWKEY IN ('1001', '1100', '1200', '1401') 
      AND A.STPRS > 0 
    ORDER BY A.MATNR 
  ) AS PC 
    ON B.MATNR = PC.MATNR 
   
  LEFT JOIN w_ipi AS IPI 
      ON ( A.KNUMV = IPI.KNUMV  
     AND   B.POSNR = IPI.KPOSN) 
      
  WHERE A.LIFSK NOT IN ('ZB') 
  AND LEFT (A.ERDAT, 6) = LEFT(REPLACE(CAST(CURRENT_DATE AS STRING),'-',''),6)  
  AND   E.LFSTK = 'A' --Sem Remessa 
  AND   B.WERKS IN ( SELECT WERKS FROM `dados-prod.raw.YDSD051`) 
  AND   B.ABGRU IN ( SELECT ABGRU FROM `dados-prod.raw.YDSD050` WHERE ITENS_CANC = 'X' ) 
  
   
  -- NAO LEVAR A RASPADINHA PARA O MAPA DE VENDA ( _SYS_BIC.YDBI006 ) 
  AND B.MATNR <> '000000000000702219' 
   
  -- O select abaixo é feito pra GARANTIR QUE NENHUM ITEM TENHA RECUSA FINANCEIRA  
  -- DEIXAR ASSIM 
  AND   A.VBELN NOT IN ( SELECT VBELN FROM `dados-prod.raw.VBAP`  
                               WHERE ABGRU IN ( SELECT LOW FROM `dados-prod.raw.TVARVC` 
                                                  WHERE NAME = 'YDSD_MP_ORDER_STATUS_REC_FINAN' 
                                                    AND LOW <> '' 
                       ) ) 
                        
  GROUP BY A.MANDT, 
           A.VBELN, 
           B.POSNR, 
           B.PSTYV, 
           A.AUART,  
           A.ERDAT,  
           A.BUKRS_VF,  
           A.VKORG,  
           A.VTWEG,  
           A.LIFSK,   
           A.KUNNR,  
           A.VKGRP, 
           A.VKBUR, 
           B.MATNR,   
           B.ARKTX, 
           B.SPART,  
           B.WERKS,  
           B.LGORT,  
           B.VSTEL,  
           B.ABGRU, 
           B.VRKME, 
           B.KWMENG, 
           KITEM.KWERT, 
           KITEM.KBETR, 
           --IPI.KWERT,-- 
           PC.STPRS, 
           A.ETL_TIMESTAMP, 
           --V.ETL_TIMESTAMP, 
           --C.ETL_TIMESTAMP,
           A.AUGRU,
           A.BSTNK,
           A.ERZET,
           a.ernam
  
  UNION ALL 
   
                -- Select Ordem sem Remessa -- 
  SELECT 
  A.MANDT           AS MANDANTE,                        
  A.VBELN           AS DOC_VENDA, 
  B.POSNR           AS DOC_ITEM, 
  B.PSTYV           AS CATEG_ITEM, 
  A.BUKRS_VF        AS EMPRESA,  
  B.WERKS           AS CENTRO, 
  B.LGORT           AS DEPOSITO, 
  B.MATNR           AS MATNR, 
  CAST(B.MATNR as INT)   AS COD_MATERIAL, 
  B.ARKTX           AS DESCR_MATERIAL, 
  A.KUNNR           AS CLIENTE,   
  A.ERDAT           AS DT_OV,   
  CAST(CONCAT(SUBSTR(A.ERDAT, 0 , 4), '-' ,SUBSTR(A.ERDAT, 5 , 2), '-' , SUBSTR(A.ERDAT, 7 , 2) ) AS DATE)     AS DT_OV_D,      
  A.AUART           AS DOC_TIPO,   
  A.VKORG           AS ORG_VENDAS, 
  A.VTWEG           AS CANAL_DISTR, 
  A.VKGRP           AS EQ_VENDAS, 
  A.VKBUR           AS ESCR_VENDA, 
  B.SPART           AS SET_ATIV, 
  B.VSTEL           AS LOC_EXP, 
  'Ordem Sem Remessa'   AS COCKPIT, 
  SUBSTR(A.ERDAT, 1,6) AS ANOMES, 
  --SUBSTR(REPLACE(CAST(CURRENT_DATE AS STRING),'-',''),1,6) AS ANOMES, 
  
  CASE  
    WHEN B.VRKME = 'CX' THEN 
      CASE 
      WHEN COALESCE(B.KWMENG,0) > 0 THEN 
        COALESCE(KITEM.KWERT,0) / COALESCE(KITEM.KBETR,0)  
    END 
    ELSE 
      COALESCE(B.KWMENG,0) 
  END AS QTDECALCULADA, 
   
  CASE 
    WHEN A.AUART = 'ZBON' THEN 0 
    ELSE 
      COALESCE(Sum(B.MWSBP), 0) 
  END AS VLR_MONTIMPOSTO, 
   
  CASE 
    WHEN A.AUART = 'ZBON' THEN 0 
    ELSE 
      COALESCE(Sum(B.NETWR),0) 
  END AS VLR_LIQUIDO, 
   
  CASE 
    WHEN A.AUART = 'ZBON' THEN 0 
    ELSE 
      COALESCE(KITEM.KWERT,0) 
  END AS VLR_PEDIDO, 
   
  CASE 
    WHEN A.AUART = 'ZBON' THEN 0 
    ELSE 
      COALESCE(Sum(D.KWERT),0) 
  END AS VLR_BOLETO, 
   
  PC.STPRS as CUSTO_UNIT, 
  SUM(COALESCE(IPI.KWERT,0)) AS IPI, 
    CASE  
    WHEN B.VRKME = 'CX' THEN 
      CASE 
      WHEN COALESCE(B.KWMENG,0) > 0 THEN 
        COALESCE(KITEM.KWERT,0) / COALESCE(KITEM.KBETR,0)  
    END 

   ELSE 
      COALESCE(B.KWMENG,0) 
  END * PC.STPRS AS CUSTO_TOTAL, 
  A.ETL_TIMESTAMP AS ETL_VBAK, 
  --V.ETL_TIMESTAMP AS ETL_VBRK, 
  '' as ETL_VBRK,
  --C.ETL_TIMESTAMP AS ETL_LIPS, 
  '' as ETL_LIPS, 
  CURRENT_TIMESTAMP AS ETL_OV,
  A.AUGRU,
  A.BSTNK,
  A.ERZET,
  a.ernam

  /*-- Linha de Itens Docto Venda --*/ 
  FROM `dados-prod.raw.VBAK`                   AS A 
   
  /*-- Cabeçalho Docto Vendas --*/ 
  LEFT JOIN `dados-prod.raw.VBAP`              AS B 
  ON    A.MANDT = B.MANDT 
  AND   A.VBELN = B.VBELN 
   
  /*-- LIPS -- */
  LEFT JOIN `dados-prod.raw.LIPS`              AS C 
  ON    B.MANDT   = C.MANDT 
  AND   B.VBELN   = C.VGBEL  
  AND   B.POSNR   = C.VGPOS  
  
   
  /*-- Documento SD: status de cabeçalho --*/ 
  LEFT JOIN `dados-prod.raw.VBUK`              AS E 
  ON    A.MANDT   = E.MANDT 
  AND   A.VBELN   = E.VBELN  
   
  /*-- Documento SD: status de item --*/ 
  LEFT JOIN `dados-prod.raw.VBUP`             AS F 
  ON    A.MANDT   = F.MANDT 
  AND   A.VBELN   = F.VBELN  
  AND   B.POSNR   = F.POSNR  
 

    /*-- VBRP --*/ 
  LEFT JOIN `dados-prod.raw.VBRP`             AS G 
  ON    A.MANDT   = G.MANDT 
  AND   A.VBELN   = G.AUBEL  
 

  /*LEFT JOIN `dados-prod.raw.VBRK`              AS V 
  ON    G.MANDT = V.MANDT 
  AND   G.VBELN = V.VBELN 
  */
   
  LEFT JOIN w_bol AS D 
    ON    B.MANDT = D.MANDT 
    AND   A.KNUMV = D.KNUMV 
    AND   B.POSNR = D.KPOSN  
   
  LEFT JOIN w_icmi AS KITEM 
    ON ( A.KNUMV = KITEM.KNUMV AND B.POSNR = KITEM.KPOSN ) 
   
  LEFT JOIN 
  ( 
    SELECT A.MATNR, A.STPRS 
    FROM 
    `dados-prod.raw.MBEW` A 
      INNER JOIN 
    ( 
      SELECT MATNR, MAX(TIMESTAMP_MILLIS(TIMESTAMP)) AS TIMESTAMP FROM `dados-prod.raw.MBEW` 
      WHERE OWNPR = 'X' 
        AND BWKEY IN ('1001', '1100', '1200', '1401') 
      GROUP BY MATNR   
     ) B 
       ON  A.MATNR = B.MATNR 
       AND TIMESTAMP_MILLIS(A.TIMESTAMP) = B.TIMESTAMP 
    WHERE A.OWNPR = 'X' 
      AND A.BWKEY IN ( '1001', '1100', '1200', '1401' ) 
      AND A.STPRS > 0 
    ORDER BY A.MATNR 
  ) AS PC 
    ON B.MATNR = PC.MATNR 
   
  LEFT JOIN w_ipi AS IPI 
      ON ( A.KNUMV = IPI.KNUMV  
     AND   B.POSNR = IPI.KPOSN) 
           
  WHERE A.AUART  IN ( SELECT VALOR FROM `dados-prod.raw.YDBI001`  
             WHERE RELATORIO = 'DASHBOARD DETALHADO' 
               AND NOME_VIEW = 'CV_DASHBOARD_DETALHE' 
                 AND FILTRO    = 'AUART' 
                       AND DESCRICAO = 'TP. DOC - ORDEM SEM REMESSA' 
               ORDER BY VALOR ) 
  AND   B.WERKS IN ( SELECT WERKS FROM `dados-prod.raw.YDSD051`) 
  AND   B.ABGRU NOT IN ( SELECT VALOR FROM `dados-prod.raw.YDBI001`  
                   WHERE RELATORIO = 'DASHBOARD DETALHADO' 
                     AND NOME_VIEW = 'CV_DASHBOARD_DETALHE' 
                     AND FILTRO    = 'ABGRU' 
                     AND DESCRICAO = 'MOT. RECUSA - ORDENS SEM REMESSA' 
                   ORDER BY VALOR ) 
  AND   A.LIFSK NOT IN ( SELECT VALOR FROM `dados-prod.raw.YDBI001`  
                 WHERE RELATORIO = 'DASHBOARD DETALHADO' 
                   AND NOME_VIEW = 'CV_DASHBOARD_DETALHE' 
                     AND FILTRO    = 'LIFSK' 
                           AND DESCRICAO = 'MOT. BLOQUEIO - ORDENS SEM REMESSA' 
                   ORDER BY VALOR ) 
  AND   C.VGBEL IS NULL 
  AND   E.SPSTG NOT IN ('C') 
  AND   F.LFGSA = 'A' 
  AND   B.SHKZG <> 'X' 
  AND   A.VTWEG <= '10' 
  AND A.VBELN NOT IN ( SELECT VBELN 
                       FROM `dados-prod.raw.YDMM017` 
                       WHERE COALESCE( MBLNR, '' ) = '' 
                     ) 
  --AND   A.ERDAT >= 'DTINI' 
  AND A.ERDAT >= REPLACE(CAST(DATE_ADD((CURRENT_DATE), INTERVAL -2 MONTH)AS STRING),'-','') 
  --AND   A.ERDAT <= 'DTFIM' 
  AND A.ERDAT <= REPLACE(CAST(CURRENT_DATE AS STRING),'-','') 
   
  -- NAO LEVAR A RASPADINHA PARA O MAPA DE VENDA ( _SYS_BIC.YDBI006 ) 
  AND B.MATNR <> '000000000000702219'   
   
  GROUP BY A.MANDT, 
           A.VBELN, 
           B.POSNR, 
           B.PSTYV, 
           A.AUART,  
           A.ERDAT,  
           A.BUKRS_VF,  
           A.VKORG,  
           A.VTWEG,  
           A.LIFSK,   
           A.KUNNR,  
           A.VKGRP, 
           A.VKBUR, 
           B.MATNR,   
           B.ARKTX, 
           B.SPART,  
           B.WERKS,  
           B.LGORT,  
           B.VSTEL,  
           B.ABGRU, 
           B.VRKME, 
           B.KWMENG, 
           KITEM.KWERT, 
           KITEM.KBETR, 
           --IPI.KWERT,-- 
           PC.STPRS, 
           A.ETL_TIMESTAMP, 
           --V.ETL_TIMESTAMP, 
           --C.ETL_TIMESTAMP,
           A.AUGRU,
           A.BSTNK,
           A.ERZET,
           a.ernam
   
  UNION ALL 
   
                -- Select Ordem triangulação -- 
  SELECT 
  A.MANDT           AS MANDANTE,                        
  A.VBELN           AS DOC_VENDA, 
  B.POSNR           AS DOC_ITEM, 
  B.PSTYV           AS CATEG_ITEM, 
  A.BUKRS_VF        AS EMPRESA,  
  B.WERKS           AS CENTRO, 
  B.LGORT           AS DEPOSITO, 
  B.MATNR           AS MATNR, 
  CAST(B.MATNR AS INT)   AS COD_MATERIAL, 
  B.ARKTX           AS DESCR_MATERIAL, 
  A.KUNNR           AS CLIENTE,   
  A.ERDAT           AS DT_OV,   
  CAST(CONCAT(SUBSTR(A.ERDAT, 0 , 4), '-' ,SUBSTR(A.ERDAT, 5 , 2), '-' , SUBSTR(A.ERDAT, 7 , 2) ) AS DATE)  AS DT_OV_D,      
  A.AUART           AS DOC_TIPO,   
  A.VKORG           AS ORG_VENDAS, 
  A.VTWEG           AS CANAL_DISTR, 
  A.VKGRP           AS EQ_VENDAS, 
  A.VKBUR           AS ESCR_VENDA, 
  B.SPART           AS SET_ATIV, 
  B.VSTEL           AS LOC_EXP, 
  'Triangulação'        AS COCKPIT, 
  SUBSTR(A.ERDAT, 1,6) AS ANOMES, 
  --SUBSTR(REPLACE(CAST(CURRENT_DATE AS STRING),'-',''),1,6) AS ANOMES, 
   
  CASE  
    WHEN B.VRKME = 'CX' THEN 
      CASE 
      WHEN COALESCE(B.KWMENG,0) > 0 THEN 
        COALESCE(KITEM.KWERT,0) / COALESCE(KITEM.KBETR,0)  
    END 
    ELSE 
      COALESCE(B.KWMENG,0) 
  END AS QTDECALCULADA, 
   
  CASE 
    WHEN A.AUART = 'ZBON' THEN 0 
    ELSE 
      COALESCE(Sum(B.MWSBP),0) 
  END AS VLR_MONTIMPOSTO, 
   
  CASE 
    WHEN A.AUART = 'ZBON' THEN 0 
    ELSE 
      COALESCE(Sum(B.NETWR),0) 
  END AS VLR_LIQUIDO, 
   
  CASE 
    WHEN A.AUART = 'ZBON' THEN 0 
    ELSE 
      COALESCE(KITEM.KWERT,0) 
  END AS VLR_PEDIDO, 
   
  CASE 
    WHEN A.AUART = 'ZBON' THEN 0 
    ELSE 
      COALESCE(Sum(D.KWERT),0) 
  END AS VLR_BOLETO, 
   
  PC.STPRS as CUSTO_UNIT, 
  SUM(COALESCE(IPI.KWERT,0)) AS IPI, 
    CASE  
    WHEN B.VRKME = 'CX' THEN 
      CASE 
      WHEN COALESCE(B.KWMENG,0) > 0 THEN 
        COALESCE(KITEM.KWERT,0) / COALESCE(KITEM.KBETR,0)  
    END 
    ELSE 
      COALESCE(B.KWMENG,0) 
  END * PC.STPRS AS CUSTO_TOTAL, 
  A.ETL_TIMESTAMP AS ETL_VBAK, 
  --V.ETL_TIMESTAMP AS ETL_VBRK, 
  '' as ETL_VBRK,
  --C.ETL_TIMESTAMP AS ETL_LIPS, 
  '' as ETL_LIPS, 
  CURRENT_TIMESTAMP AS ETL_OV,
  A.AUGRU,
  A.BSTNK,
  A.ERZET,
  a.ernam

  /*-- Linha de Itens Docto Venda --*/ 
  FROM `dados-prod.raw.VBAK`                   AS A 
   
  /*-- Cabeçalho Docto Vendas --*/ 
  LEFT JOIN `dados-prod.raw.VBAP`             AS B 
  ON    A.MANDT = B.MANDT 
  AND   A.VBELN = B.VBELN 
   
  /*-- LIPS -- */
  LEFT JOIN `dados-prod.raw.LIPS`              AS C 
  ON    B.MANDT   = C.MANDT 
  AND   B.VBELN   = C.VGBEL  
  AND   B.POSNR   = C.VGPOS
  
   
  /*-- Documento SD: status de cabeçalho --*/ 
  LEFT JOIN `dados-prod.raw.VBUK`             AS E 
  ON    A.MANDT   = E.MANDT 
  AND   A.VBELN   = E.VBELN  
   
  /*-- Documento SD: status de item --*/ 
  LEFT JOIN `dados-prod.raw.VBUP`             AS F 
  ON    A.MANDT   = F.MANDT 
  AND   A.VBELN   = F.VBELN  
  AND   B.POSNR   = F.POSNR  
 

    /*-- VBRP --*/ 
  LEFT JOIN `dados-prod.raw.VBRP`             AS G 
  ON    A.MANDT   = G.MANDT 
  AND   A.VBELN   = G.AUBEL  
 

  /*LEFT JOIN `dados-prod.raw.VBRK`              AS V 
  ON    G.MANDT = V.MANDT 
  AND   G.VBELN = V.VBELN 
  */
   
  LEFT JOIN w_bol AS D 
    ON    B.MANDT = D.MANDT 
    AND   A.KNUMV = D.KNUMV 
    AND   B.POSNR = D.KPOSN  
   
  LEFT JOIN w_icmi AS KITEM 
    ON ( A.KNUMV = KITEM.KNUMV AND B.POSNR = KITEM.KPOSN ) 
   
  LEFT JOIN 
  ( 
    SELECT A.MATNR, A.STPRS 
    FROM 
    `dados-prod.raw.MBEW` A 
      INNER JOIN 
    ( 
      SELECT MATNR, MAX(TIMESTAMP_MILLIS(TIMESTAMP)) AS TIMESTAMP FROM `dados-prod.raw.MBEW` 
      WHERE OWNPR = 'X' 
        AND BWKEY IN ('1001', '1100', '1200', '1401') 
      GROUP BY MATNR   
     ) B 
       ON  A.MATNR = B.MATNR 
       AND TIMESTAMP_MILLIS(A.TIMESTAMP) = B.TIMESTAMP 
    WHERE A.OWNPR = 'X' 
      AND A.BWKEY IN ( '1001', '1100', '1200', '1401' ) 
      AND A.STPRS > 0 
    ORDER BY A.MATNR 
  ) AS PC 
    ON B.MATNR = PC.MATNR 
   
  LEFT JOIN w_ipi AS IPI 
      ON ( A.KNUMV = IPI.KNUMV  
     AND   B.POSNR = IPI.KPOSN) 
             
  WHERE A.AUART = 'YTRI' -- somente ABASTECIMENTO 
  AND   B.WERKS IN ( SELECT WERKS FROM `dados-prod.raw.YDSD051`) 
  AND   B.ABGRU NOT IN ( SELECT VALOR FROM `dados-prod.raw.YDBI001`  
                   WHERE RELATORIO = 'DASHBOARD DETALHADO' 
                     AND NOME_VIEW = 'CV_DASHBOARD_DETALHE' 
                     AND FILTRO    = 'ABGRU' 
                     AND DESCRICAO = 'MOT. RECUSA - ORDENS SEM REMESSA' 
                   ORDER BY VALOR ) 
  AND   A.LIFSK NOT IN ( SELECT VALOR FROM `dados-prod.raw.YDBI001`  
                 WHERE RELATORIO = 'DASHBOARD DETALHADO' 
                   AND NOME_VIEW = 'CV_DASHBOARD_DETALHE' 
                     AND FILTRO    = 'LIFSK' 
                           AND DESCRICAO = 'MOT. BLOQUEIO - ORDENS SEM REMESSA' 
                   ORDER BY VALOR ) 
  AND   C.VGBEL IS NULL 
  AND   E.SPSTG NOT IN ('C') 
  AND   F.LFGSA = 'A' 
  AND   B.SHKZG <> 'X' 
  AND   A.VTWEG <= '10' 
  AND A.VBELN IN ( SELECT VBELN 
                       FROM `dados-prod.raw.YDMM017` 
                       WHERE COALESCE( MBLNR, '' ) = '' 

                    ) 
  --AND   A.ERDAT >= 'DTINI' 
  AND A.ERDAT >= REPLACE(CAST(DATE_ADD((CURRENT_DATE), INTERVAL -2 MONTH)AS STRING),'-','') 
  --AND   A.ERDAT <= 'DTFIM' 
  AND A.ERDAT <= REPLACE(CAST(CURRENT_DATE AS STRING),'-','')  
   
  -- NAO LEVAR A RASPADINHA PARA O MAPA DE VENDA ( _SYS_BIC.YDBI006 ) 
  AND B.MATNR <> '000000000000702219'   
   
  GROUP BY A.MANDT, 
           A.VBELN, 
           B.POSNR, 
           B.PSTYV, 
           A.AUART,  
           A.ERDAT,  
           A.BUKRS_VF,  
           A.VKORG,  
           A.VTWEG,  
           A.LIFSK,   
           A.KUNNR,  
           A.VKGRP, 
           A.VKBUR, 
           B.MATNR,   
           B.ARKTX, 
           B.SPART,  
           B.WERKS,  
           B.LGORT,  
           B.VSTEL,  
           B.ABGRU, 
           B.VRKME, 
           B.KWMENG, 
           KITEM.KWERT, 
           KITEM.KBETR, 
           --IPI.KWERT,-- 
           PC.STPRS, 
           A.ETL_TIMESTAMP, 
           --V.ETL_TIMESTAMP, 
           --C.ETL_TIMESTAMP,
           A.AUGRU,
           A.BSTNK,
           A.ERZET,
           a.ernam

  UNION ALL 
   
                -- Select Ordem Com Remessa -- 
  SELECT 
  A.MANDT           AS MANDANTE,                        
  A.VBELN           AS DOC_VENDA, 
  B.POSNR           AS DOC_ITEM, 
  B.PSTYV           AS CATEG_ITEM, 
  A.BUKRS_VF        AS EMPRESA,  
  B.WERKS           AS CENTRO, 
  B.LGORT           AS DEPOSITO, 
  B.MATNR           AS MATNR, 
 cast(B.MATNR as INT)   AS COD_MATERIAL, 
  B.ARKTX           AS DESCR_MATERIAL, 
  A.KUNNR           AS CLIENTE,   
  A.ERDAT           AS DT_OV,   
  CAST(CONCAT(SUBSTR(A.ERDAT, 0 , 4), '-' ,SUBSTR(A.ERDAT, 5 , 2), '-' , SUBSTR(A.ERDAT, 7 , 2) ) AS DATE)  AS DT_OV_D,      
  A.AUART           AS DOC_TIPO,   
  A.VKORG           AS ORG_VENDAS, 
  A.VTWEG           AS CANAL_DISTR, 
  A.VKGRP           AS EQ_VENDAS, 
  A.VKBUR           AS ESCR_VENDA, 
  B.SPART           AS SET_ATIV, 
  B.VSTEL           AS LOC_EXP, 
  'Ordem Com Remessa'   AS COCKPIT, 
  SUBSTR(A.ERDAT, 1,6) AS ANOMES, 
  --SUBSTR(REPLACE(CAST(CURRENT_DATE AS STRING),'-',''),1,6) AS ANOMES, 
   
  CASE  
    WHEN B.VRKME = 'CX' THEN 
      CASE 
      WHEN COALESCE(B.KWMENG,0) > 0 THEN 
        COALESCE(KITEM.KWERT,0) / COALESCE(KITEM.KBETR,0)  
    END 
    ELSE 
      COALESCE(B.KWMENG,0) 
  END AS QTDECALCULADA, 
   
  CASE 
    WHEN A.AUART = 'ZBON' THEN 0 
    ELSE 
      COALESCE(Sum(B.MWSBP),0) 
  END AS VLR_MONTIMPOSTO, 
   
  CASE 
    WHEN A.AUART = 'ZBON' THEN 0 
    ELSE 
      COALESCE(Sum(B.NETWR),0) 
  END AS VLR_LIQUIDO, 
   
  CASE 
    WHEN A.AUART = 'ZBON' THEN 0 
    ELSE 
      COALESCE(KITEM.KWERT,0) 
  END AS VLR_PEDIDO, 
   
  CASE 
    WHEN A.AUART = 'ZBON' THEN 0 
    ELSE 
      COALESCE(Sum(Z.KWERT), 0) 
  END AS VLR_BOLETO, 
   
  PC.STPRS as CUSTO_UNIT, 
  SUM(COALESCE(IPI.KWERT,0)) AS IPI, 
    CASE  
    WHEN B.VRKME = 'CX' THEN 
      CASE 
      WHEN COALESCE(B.KWMENG,0) > 0 THEN 
        COALESCE(KITEM.KWERT,0) / COALESCE(KITEM.KBETR,0)  
    END 
    ELSE 
      COALESCE(B.KWMENG,0) 
  END * PC.STPRS AS CUSTO_TOTAL, 
  A.ETL_TIMESTAMP AS ETL_VBAK, 
  --D.ETL_TIMESTAMP AS ETL_VBRK, 
  '' as ETL_VBRK,
  --E.ETL_TIMESTAMP AS ETL_LIPS, 
  '' as ETL_LIPS,   
  CURRENT_TIMESTAMP AS ETL_OV,
  A.AUGRU,
  A.BSTNK,
  A.ERZET,
  a.ernam

  /*-- Linha de Itens Docto Venda --*/ 
  FROM `dados-prod.raw.VBAP`                   AS B 
   
  LEFT JOIN `dados-prod.raw.VBAK`                AS A 
  ON    A.MANDT = B.MANDT 
  AND   A.VBELN = B.VBELN 
    
  LEFT JOIN `dados-prod.raw.VBRP`              AS C 
  ON    B.MANDT = C.MANDT 
  AND   B.VBELN = C.AUBEL 
  AND   B.POSNR = C.AUPOS 
   
  LEFT JOIN `dados-prod.raw.VBRK`              AS D 
  ON    C.MANDT = D.MANDT 
  AND   C.VBELN = D.VBELN 
  AND   D.FKSTO = 'X' 
   
  JOIN `dados-prod.raw.LIPS`                  AS E 
  ON    B.MANDT = E.MANDT 
  AND   B.VBELN = E.VGBEL 
  AND   B.POSNR = E.VGPOS 
   
  LEFT JOIN `dados-prod.raw.VBUK`             AS F 
  ON    E.MANDT = F.MANDT 
  AND   E.VBELN = F.VBELN 
  AND   F.KOSTK = 'C' --(picking completo) 
  AND   F.LVSTK = 'C' --(OT/WM confirmada) 
   
  LEFT JOIN w_bol AS Z 
    ON    B.MANDT = Z.MANDT 
    AND   A.KNUMV = Z.KNUMV 
    AND   B.POSNR = Z.KPOSN  
   
  LEFT JOIN w_icmi AS KITEM 
    ON ( A.KNUMV = KITEM.KNUMV AND B.POSNR = KITEM.KPOSN ) 
   
  LEFT JOIN 
  ( 
    SELECT A.MATNR, A.STPRS 
    FROM 
    `dados-prod.raw.MBEW` A 
      INNER JOIN 
    ( 
      SELECT MATNR, MAX(TIMESTAMP_MILLIS(TIMESTAMP)) AS TIMESTAMP FROM `dados-prod.raw.MBEW` 
      WHERE OWNPR = 'X' 
        AND BWKEY IN ('1001', '1100', '1200', '1401') 
      GROUP BY MATNR   
     ) B 
       ON  A.MATNR = B.MATNR 
       AND TIMESTAMP_MILLIS(A.TIMESTAMP) = B.TIMESTAMP 
    WHERE A.OWNPR = 'X' 
      AND A.BWKEY IN ( '1001', '1100', '1200', '1401' ) 
      AND A.STPRS > 0 
    ORDER BY A.MATNR 
  ) AS PC 
    ON B.MATNR = PC.MATNR 
   
  LEFT JOIN w_ipi AS IPI 
      ON ( A.KNUMV = IPI.KNUMV  
     AND   B.POSNR = IPI.KPOSN) 
         
  WHERE B.ABGRU  NOT IN ( SELECT VALOR FROM `dados-prod.raw.YDBI001`  
                 WHERE RELATORIO = 'DASHBOARD DETALHADO' 
                   AND NOME_VIEW = 'CV_DASHBOARD_DETALHE' 
                   AND FILTRO    = 'ABGRU' 
                           AND DESCRICAO = 'MOT. RECUSA - ORDENS COM REMESSA' 
                   ORDER BY VALOR ) 
  AND   B.WERKS IN ( SELECT WERKS FROM `dados-prod.raw.YDSD051`) 
  AND   A.AUART IN ( SELECT VALOR FROM `dados-prod.raw.YDBI001`  
             WHERE RELATORIO = 'DASHBOARD DETALHADO' 
                       AND NOME_VIEW = 'CV_DASHBOARD_DETALHE' 
             AND FILTRO    = 'AUART' 
             AND DESCRICAO = 'TP. DOC - ORDEM COM REMESSA' 
             ORDER BY VALOR )  
  AND   A.LIFSK NOT IN ( SELECT VALOR FROM `dados-prod.raw.YDBI001`  
                 WHERE RELATORIO = 'DASHBOARD DETALHADO' 
                   AND NOME_VIEW = 'CV_DASHBOARD_DETALHE' 
                     AND FILTRO    = 'LIFSK' 
                           AND DESCRICAO = 'MOT. BLOQUEIO - ORDEM COM REMESSA' 
                   ORDER BY VALOR ) 
  AND   C.VBELN IS NULL 
  AND   E.VGBEL IS NOT NULL   
  AND   E.UECHA = '000000' 
  AND   A.VTWEG <= '10' 
  --AND   A.ERDAT >= 'DTINI' 
  AND A.ERDAT >= REPLACE(CAST(DATE_ADD((CURRENT_DATE), INTERVAL -2 MONTH)AS STRING),'-','') 
  --AND   A.ERDAT <= 'DTFIM' 
  AND A.ERDAT <= REPLACE(CAST(CURRENT_DATE AS STRING),'-','') 

  -- NAO LEVAR A RASPADINHA PARA O MAPA DE VENDA ( _SYS_BIC.YDBI006 ) 
  AND B.MATNR <> '000000000000702219'    
   
  GROUP BY A.MANDT, 
           A.VBELN, 
           B.POSNR, 
           B.PSTYV, 
           A.AUART,  
           A.ERDAT,  
           A.BUKRS_VF,  
           A.VKORG,  
           A.VTWEG,  
           A.LIFSK,   
           A.KUNNR,  
           A.VKGRP, 
           A.VKBUR, 
           B.MATNR,   
           B.ARKTX, 
           B.SPART, 
           B.WERKS,  
           B.LGORT,  
           B.VSTEL,  
           B.ABGRU, 
           B.VRKME, 
           B.KWMENG, 
           KITEM.KWERT, 
           KITEM.KBETR, 
           --IPI.KWERT,-- 
           PC.STPRS, 
           A.ETL_TIMESTAMP, 
           --D.ETL_TIMESTAMP, 
           --E.ETL_TIMESTAMP,
           A.AUGRU,
           A.BSTNK,
           A.ERZET,
           a.ernam

) AS AUX  
  left join( 
   select distinct cond.vbeln, cond.zterm 
     from `dados-prod.raw_cimed_tech.VBKD` as cond 
     where posnr = '000000' 
 ) as vbkd 
 on vbkd.vbeln = aux.DOC_VENDA 
  
 left join w_kna1 as KNA1
  on kna1.kunnr = aux.cliente

left join w_ydsd217 as ydsd217
  ON ydsd217.vbeln = aux.DOC_VENDA

------ zerando valores dos itens de bonificacao/brinde/amostra 
  LEFT JOIN 
  ( SELECT VALOR, DESCRICAO 
    FROM `dados-prod.raw.YDBI001`  
    WHERE RELATORIO = 'CARGA YDBI006_ITEM' 
     AND FILTRO    = 'PSTYV' 
    AND NOME_VIEW = 'CV_IND_VENDA_DASH_CARGA_ITEM' 
  ORDER BY DESCRICAO 
  ) AS ESP 
  ON AUX.CATEG_ITEM = ESP.VALOR 
------ zerando valores dos itens de bonificacao/brinde/amostra