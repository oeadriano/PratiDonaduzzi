
WITH
   w_vbrk as (
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
          vbrk.mandt,
          vbrk.zlsch, 
          case 
            when vbrk.fkart in (
               'YBOR', --Venda Normal
               'YBON', --Bonificacao         
               'YEXP', --Fatura Exportação
               'YMGD', --Vend.MG Preço Margem
               'YRCS', --Rem.p/ cta. s.fatura
               'YSER', --Serviço s/ Retenção
               'YDEP' --Fatura Ordem BR
            ) then 'FAT' 
            else 'DEV'
         end as tipo         
      from           
         `sap_raw.vbrk` AS vbrk 
      WHERE 
         --TIMESTAMP_TRUNC(vbrk.recordstamp, DAY) >= date_sub(current_timestamp, interval 1 DAY) and
         vbrk.fkdat >= date_sub(current_date, interval 3 DAY)
         AND vbrk.recordstamp >= date_sub(current_timestamp, interval 30 minute) 
         AND vbrk.fkart in (
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
         -- faturas
         'YBOR', --Venda Normal
         'YBON', --Bonificacao         
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
            vbak.mandt,
            vbkd.zlsch,
            case 
               when vbak.auart in (
                  'YVOL' --Venda Operador
               ) then 'FAT' 
            else 'DEV'
         end as tipo 
         from 
            `sap_raw.vbak` as vbak

         JOIN `sap_raw.vbkd` AS vbkd -- colocar no with? qual where?
            ON vbkd.vbeln = vbak.vbeln            
         where
            --TIMESTAMP_TRUNC(vbak.recordstamp, DAY) >= date_sub(current_timestamp, interval 1 DAY)
            vbak.erdat >= date_sub(current_date, interval 3 DAY)
            and vbak.recordstamp >= date_sub(current_timestamp, interval 30 minute)
            --AEO 190625 - somente documentos da picklist cgcloud__Document_Type__c
            -- WHERE vbak.auart IN ('YVOL','YDOL')
         AND vbak.auart in (
            -- devoluções
            'YDOL', --Dev. Op.Log
            -- faturas
            'YVOL'  --Venda Operador
            )            
         and COALESCE(vbak.ihrez, '') not like 'SF-%'     
         ),
   w_ztbsf003 as (
      -- cluster mandt vbeln
      SELECT ztbsf003.vbeln,
         ztbsf003.waerk,
         ztbsf003.netwr as netwr_cab,
         ztbsf003.mwsbp as mwsbp_cab,
         ztbsf003.st as st_cab,
         ztbsf003.fci as fci_cab,         
         ztbsf003.descfin as descfin_cab,
      FROM `sap_raw.ztbsf003` AS ztbsf003
      WHERE 
         TIMESTAMP_TRUNC(ztbsf003.recordstamp, DAY) >= date_sub(current_timestamp, interval 1 DAY)
         and ztbsf003.recordstamp >= date_sub(current_timestamp, interval 30 minute)
   ),
   w_ztbsf004 as (
      SELECT vbeln, ANY_VALUE(aubel) AS ordem_sap      
      FROM `sap_raw.ztbsf004`       
      WHERE  
         TIMESTAMP_TRUNC(recordstamp, DAY) >= date_sub(current_timestamp, interval 1 DAY)
         and recordstamp >= date_sub(current_timestamp, interval 30 minute)
      group by vbeln, aubel
   ),
   -- talvez nao precise dessa lista...
   w_lista_documentos as (
      SELECT distinct vbeln  
         from    
         (
            SELECT vbeln FROM w_vbrk union all 
            SELECT vbeln FROM w_vbak union all 
            SELECT vbeln FROM w_ztbsf003 union all 
            SELECT vbeln FROM w_ztbsf004 
         )
   ),
   w_ztbsd040 AS (
      SELECT 
         ztbsd040.vbeln, 
         ztbsd040.margemccp as margem_contribuicao_cab,
         ztbsd040.margemctb as margem_contabil_cab
      FROM `sap_raw.ztbsd040` AS ztbsd040
      join w_lista_documentos lst 
      on ztbsd040.vbeln = lst.vbeln
      ), 
   w_ztbsd015 as (
      select 
         ztbsd015.znumext, ztbsd015.zordem, ztbsd015.zpedorig as pedido_esfera,         
         -- se o user esfera nao existe ou esta inativo, 
         -- grava como o owner do Walter
         case 
            when coalesce(user.userexternalid__c, '') = '' then '027443'
            else lpad(ltrim(ztbsd015.zcodoper, '0'), 6, '0') 
         end as usuario_esfera 

      from `sap_raw.ztbsd015` as ztbsd015
      
      join w_lista_documentos lst on ztbsd015.zordem = lst.vbeln

      left join `postgres_raw.user` user on user.userexternalid__c = lpad(ltrim(ztbsd015.zcodoper, '0'), 6, '0')

      where user.isactive = true

   ),
   w_vbap as (
      SELECT vbap.vbeln, ANY_VALUE(vbap.werks) AS werks
                     FROM `sap_raw.vbap` as vbap
                     join w_lista_documentos lst 
                     on vbap.vbeln = lst.vbeln
                     GROUP BY vbap.vbeln
                     order BY vbap.vbeln
   ),
   w_vbpa as (
      SELECT 
         vbeln, 
         -- se o user esfera nao existe ou esta inativo, 
         -- grava como o owner do Walter
         case 
            when coalesce(user.userexternalid__c, '') = '' then '027443'
            else codigo_repre 
         end as codigo_repre 
      from 
         (
         SELECT 
            vbpa.vbeln, lpad(ltrim(vbpa.lifnr, '0'), 6, '0') AS codigo_repre,
         FROM 
            `sap_raw.vbpa` as vbpa      
         join w_lista_documentos lst on vbpa.vbeln = lst.vbeln      
         where vbpa.parvw = 'ZR'          
         GROUP BY vbpa.vbeln, vbpa.lifnr
         ) as vbpa
      
      left join `postgres_raw.user` user on user.userexternalid__c = codigo_repre

   ),
   w_vbrp as (
    SELECT vbrp.vbeln, ANY_VALUE(vbrp.werks) AS werks
                 FROM `sap_raw.vbrp` as vbrp
                 join w_lista_documentos lst 
                     on vbrp.vbeln = lst.vbeln
                     GROUP BY vbrp.vbeln
   ),
w_customer_invoice as (
  with w_warehouse as (
      select SAPPlant__c, ExternalId__c, EmpresaOperador__c, SAPSalesOrg__c
      from `ds_view_trusted.vw_cgcloud__warehouse__c`   
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
         ztbsf003.netwr_cab,
         ztbsf003.mwsbp_cab,
         ztbsf003.st_cab,
         ztbsf003.fci_cab,         
         ztbsf003.descfin_cab,
         ztbsf004.ordem_sap,
         vbak.ihrez as referencia_externa,
         -- codigo do user no SF tem 6 posicoes
         vbpa.codigo_repre,
         ztbsd040.margem_contribuicao_cab,
         ztbsd040.margem_contabil_cab,
         vbrk.origem,
         ztbsd015.usuario_esfera,
         ztbsd015.pedido_esfera,
         vbak.zlsch as cgcloud__Payment_Method__c, 
         vbrk.tipo, 
         wh.ExternalId__c as warehouse_externalid__c,         
    FROM w_vbrk AS vbrk

         JOIN w_vbrp as vbrp           ON vbrk.vbeln = vbrp.vbeln  

         JOIN w_warehouse wh on wh.SAPPlant__c = vbrp.werks and wh.SAPSalesOrg__c = vbrk.vkorg                      
         
		   JOIN `sap_raw.kna1` AS kna1   ON kna1.kunnr = vbrk.kunnr
         
         JOIN w_ztbsf003 AS ztbsf003   ON ztbsf003.vbeln = vbrk.vbeln

         JOIN w_ztbsf004 AS ztbsf004   ON ztbsf004.vbeln = vbrk.vbeln

         LEFT JOIN w_ztbsd015 AS ztbsd015 ON ztbsd015.zordem = ztbsf004.ordem_sap

         LEFT JOIN w_vbak AS vbak   ON vbak.vbeln = ztbsf004.ordem_sap
         
         LEFT JOIN w_vbpa     AS vbpa     ON vbpa.vbeln = vbrk.vbeln

         LEFT JOIN w_ztbsd040 AS ztbsd040 ON ztbsd040.vbeln = vbrk.vbeln          
      
      WHERE
         wh.EmpresaOperador__c = 'Empresa'
         and COALESCE(vbak.ihrez, '') not like 'SF-%'     

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
         vbak.zterm,
         ztbsf003.waerk,
         ztbsf003.netwr_cab,
         ztbsf003.mwsbp_cab,
         ztbsf003.st_cab,
         ztbsf003.fci_cab,
         ztbsf003.descfin_cab,
         ztbsf004.ordem_sap,
         COALESCE(ztbsd015.znumext, vbak.ihrez) as referencia_externa,
         vbpa.codigo_repre,
         ztbsd040.margem_contribuicao_cab,
         ztbsd040.margem_contabil_cab,
         vbak.origem,
         ztbsd015.usuario_esfera,
         ztbsd015.pedido_esfera,         
         vbak.zlsch as cgcloud__Payment_Method__c,
         vbak.tipo, 
         wh.ExternalId__c as warehouse_externalid__c,          
    FROM w_vbak AS vbak  
         
         JOIN w_vbap as vbap  ON vbap.vbeln = vbak.vbeln 
         
         LEFT JOIN w_warehouse wh on wh.SAPPlant__c = vbap.werks and wh.ExternalId__c = vbak.operador_logistico         

         JOIN `sap_raw.kna1`  AS kna1     ON kna1.kunnr = vbak.kunnr

         JOIN w_ztbsf003      AS ztbsf003 ON ztbsf003.vbeln = vbak.vbeln

         JOIN w_ztbsf004 AS ztbsf004 ON ztbsf004.vbeln = vbak.vbeln
		
         LEFT JOIN w_ztbsd015 AS ztbsd015 ON ztbsd015.zordem = ztbsf004.ordem_sap
         
         LEFT JOIN w_vbpa     AS vbpa     ON vbpa.vbeln = vbak.vbeln

         LEFT JOIN w_ztbsd040 AS ztbsd040 ON ztbsd040.vbeln = vbak.vbeln 

      WHERE
         wh.EmpresaOperador__c <> 'Empresa'


   )  
  -- pedidos YVOL - operador logistico
  SELECT DISTINCT 
         case
            -- TV e REP
            when vtweg = '10' and auart = 'YBOR'then 'Pedido Padrão'
            when vtweg = '10' and auart = 'YVOL'then 'Pedido Operador Logístico'
            when vtweg = '10' and auart = 'YBON'then 'Pedido Bonificado'
            -- Hospitalar
            when vtweg = '11' and auart = 'YBOR'then 'Pedido Hospitalar Padrão'
            -- then 'Pedido Hospitalar Padrão'
            when vtweg = '12' and auart = 'YBOR'then 'Pedido Orgão Publico Padrão'
            -- Orgão 
            -- then 'Pedido Orgão Publico Padrão'
            else 'Pedido Padrão'
         end as gcloud__Order_Template__c, 
         auart as cgcloud__Document_Type__c, 
         warehouse_externalid__c,
         ltrim(kunnr, '0') as account__ExternalId__c, 
         erdat as cgcloud__Order_Date__c,
         case
            when referencia_externa like 'SF-%' then referencia_externa
            else 'SAP-'||ltrim(ordem_sap, '0')
         end as ExternalId__c, 
         codigo_repre, usuario_esfera, 
         coalesce(codigo_repre, usuario_esfera) as Accountable__UserExternalID__c,  -- codigo_repre, VERIFICAR***
         coalesce(codigo_repre, usuario_esfera) as respoonsible__ExternalId__c,          
         pedido_esfera as EsferaOrderNumber__c, 
         coalesce(usuario_esfera, '') as Owner_UserExternalID__c, 
         waerk as cgcloud__Currency__c,
         
         -- campos nao criados no SF
         'Faturado' as Status__c, 
         '' as AditionalStatusInformation__c, 
         -- AEO 11/07/25 - Ruan pediu para colocar status "Ready", pois o "Closed" esta permitindo edição do pedido. Abriu chamado na SF
         --'Closed' as cgcloud__Phase__c, 
         'Ready' as cgcloud__Phase__c, 
         -- mix vi ser calculado no SF
         0 as ActualMix__c, -- calcular com base nos itens faturados
         max(zterm) as SapPaymentTerm__c,
         sum(coalesce(margem_contabil_cab, 0)) as ActualContributionMargin__c, -- Margem contabil recalculada - SAP
         sum(coalesce(margem_contribuicao_cab, 0)) as ActualMargin__c, -- 
         sum(coalesce(st_cab, 0)) as ActualStTax__c, -- Imposto ST recalculado - SAP
         sum(coalesce(netwr_cab, 0)) + sum(coalesce(mwsbp_cab, 0)) + sum(coalesce(st_cab, 0)) as TotalInvoicedAmount__c, -- Valor Total Faturado - SAP
         sum(coalesce(mwsbp_cab, 0)) as IcmsAmount__c, -- Valor ICMS - SAP
         sum(coalesce(st_cab, 0)) as StAmount__c, -- Valor ST - SAP(Duplicidade de campo com ActualStTax__c ?)
         sum(coalesce(fci_cab, 0)) as FciAmount__c, -- Valor FCI - SAP
         sum(coalesce(descfin_cab, 0)) as FinancialDiscount__c, -- Valor desconto financeiro - SAP
         origem, -- sap / OL? 
         case 
            when tipo = 'DEV' then sum(coalesce(netwr_cab, 0)) * (-1)
            else sum(coalesce(netwr_cab, 0))         
         end as valor_produto, --netwr_cab         
         ordem_sap as SAPOrderNumber__c,          
         -- IcmsAmount__c entra no item abaixo?
         case 
            when tipo = 'DEV' then ( sum(coalesce(netwr_cab, 0)) + sum(coalesce(mwsbp_cab, 0)) + sum(coalesce(st_cab, 0)) ) * (-1)
            else sum(coalesce(netwr_cab, 0)) + sum(coalesce(mwsbp_cab, 0)) + sum(coalesce(st_cab, 0))
         end as cgcloud__Gross_Total_Value__c,  -- valort total do pedido com impostos        
         coalesce(cgcloud__Payment_Method__c, 'A') as cgcloud__Payment_Method__c -- metodo de pagamento         
    FROM 
         w_customer_invoice
   group by 
      ExternalId__c, auart, warehouse_externalid__c, kunnr, erdat, referencia_externa, ordem_sap, codigo_repre, 
      usuario_esfera, usuario_esfera, waerk, pedido_esfera, origem, cgcloud__Payment_Method__c, vtweg, tipo

order by SAPOrderNumber__c
