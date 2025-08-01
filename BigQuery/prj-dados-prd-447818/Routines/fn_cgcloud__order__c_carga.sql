CREATE OR REPLACE TABLE FUNCTION `prj-dados-prd-447818.ds_view_trusted.fn_cgcloud__order__c_carga`(d_ini DATE, d_fim DATE) RETURNS TABLE<gcloud__Order_Template__c STRING, cgcloud__Document_Type__c STRING, warehouse_externalid__c STRING, account__ExternalId__c STRING, cgcloud__Order_Date__c DATE, ExternalId__c STRING, codigo_repre STRING, usuario_esfera STRING, Accountable__UserExternalID__c STRING, respoonsible__ExternalId__c STRING, EsferaOrderNumber__c STRING, Owner_UserExternalID__c STRING, cgcloud__Currency__c STRING, Status__c STRING, AditionalStatusInformation__c STRING, cgcloud__Phase__c STRING, ActualMix__c NUMERIC, SapPaymentTerm__c STRING, ActualContributionMargin__c NUMERIC, ActualMargin__c NUMERIC, ActualStTax__c NUMERIC, TotalInvoicedAmount__c NUMERIC, IcmsAmount__c NUMERIC, StAmount__c NUMERIC, FciAmount__c NUMERIC, FinancialDiscount__c NUMERIC, origem STRING, valor_produto NUMERIC, SAPOrderNumber__c STRING, cgcloud__Gross_Total_Value__c NUMERIC, cgcloud__Payment_Method__c STRING> AS (
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
               'YVOL', --Venda Operador
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
         --TIMESTAMP_TRUNC(vbrk.recordstamp, DAY) >= cast(d_ini as timestamp)
         --AND TIMESTAMP_TRUNC(vbrk.recordstamp, DAY) <= cast(date_add(d_fim, interval 7 day) as timestamp) 
         --and 
         vbrk.fkdat between d_ini and d_fim
         --vbrk.fkdat between '2025-07-01' and '2025-07-05'
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
         'YVOL', --Venda Operador
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
            coalesce(vbak.ihrez,'') as ihrez,
            vbak.mandt,
            vbkd.zlsch,
            case 
               when vbak.auart in (
                  'YBOR', --Venda Normal, 
                  'YVOL', --Venda Operador
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
            `sap_raw.vbak` as vbak

         JOIN `sap_raw.vbkd` AS vbkd -- colocar no with? qual where?
            ON vbkd.vbeln = vbak.vbeln            
         where
            --TIMESTAMP_TRUNC(vbak.recordstamp, DAY) >= cast(d_ini as timestamp) 
            --AND TIMESTAMP_TRUNC(vbak.recordstamp, DAY) <= cast(date_add(d_fim, interval 7 day) as timestamp) 
            --vbak.erdat between '2025-07-01' and '2025-07-05'
             vbak.erdat between d_ini and d_fim
            AND vbak.auart in (
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
               'YVOL', --Venda Operador
               'YBON', --Bonificacao               
               'YEXP', --Fatura Exportação
               'YMGD', --Vend.MG Preço Margem
               'YRCS', --Rem.p/ cta. s.fatura
               'YSER', --Serviço s/ Retenção
               'YDEP' --Fatura Ordem BR
            )            
            and coalesce(vbak.ihrez, '') not like 'SF-%'     
         -- order BY vbeln
         ),
   w_ztbsf003 as (
      -- cluster mandt vbeln
      SELECT distinct ztbsf003.vbeln,
         ztbsf003.waerk,
         ztbsf003.netwr as netwr_cab,
         ztbsf003.mwsbp as mwsbp_cab,
         ztbsf003.st as st_cab,
         ztbsf003.fci as fci_cab,         
         ztbsf003.descfin as descfin_cab,
      FROM `sap_raw.ztbsf003` AS ztbsf003
      --join w_lista_documentos lst  on lst.vbeln = ztbsf003.vbeln
      left join w_vbak as vbak on vbak.vbeln = ztbsf003.vbeln
      left join w_vbrk as vbrk on vbrk.vbeln = ztbsf003.vbeln
      --WHERE 
         --TIMESTAMP_TRUNC(ztbsf003.recordstamp, DAY) >= cast(d_ini as timestamp)             
         --AND TIMESTAMP_TRUNC(ztbsf003.recordstamp, DAY) <= cast(date_add(d_fim, interval 7 day) as timestamp) 
      -- order BY vbeln
      
   ),
   w_ztbsf004 as (
      SELECT ztbsf004.vbeln, ANY_VALUE(ztbsf004.aubel) AS ordem_sap      
      FROM `sap_raw.ztbsf004` ztbsf004
      --join w_lista_documentos lst on ztbsf004.vbeln = lst.vbeln
      left join w_vbak as vbak on vbak.vbeln = ztbsf004.vbeln
      left join w_vbrk as vbrk on vbrk.vbeln = ztbsf004.vbeln
      --WHERE 
         --TIMESTAMP_TRUNC(ztbsf004.recordstamp, DAY) >= cast(d_ini as timestamp)             
         --AND TIMESTAMP_TRUNC(ztbsf004.recordstamp, DAY) <= cast(date_add(d_fim, interval 7 day) as timestamp)          
      group by ztbsf004.vbeln
      -- order BY vbeln
   ),   
   w_ztbsd040 AS (
      SELECT 
         distinct ztbsd040.vbeln, 
         ztbsd040.margemccp as margem_contribuicao_cab,
         ztbsd040.margemctb as margem_contabil_cab
      FROM `sap_raw.ztbsd040` AS ztbsd040
      --join w_lista_documentos lst  on ztbsd040.vbeln = lst.vbeln
      left join w_vbak as vbak on vbak.vbeln = ztbsd040.vbeln
      left join w_vbrk as vbrk on vbrk.vbeln = ztbsd040.vbeln      
      --WHERE 
         --TIMESTAMP_TRUNC(ztbsd040.recordstamp, DAY) >= cast(d_ini as timestamp)                   
         --AND TIMESTAMP_TRUNC(ztbsd040.recordstamp, DAY) <= cast(date_add(d_fim, interval 7 day) as timestamp)                   
      -- order BY vbeln
      ), 
      w_user as (
         select userexternalid__c
         from  `postgres_raw.user`
         where isactive =  true
      ),
   w_ztbsd015 as (
      select distinct 
         ztbsd015.znumext, ztbsd015.zordem, ztbsd015.pedido_esfera, 
         -- se o user esfera nao existe ou esta inativo, 
         -- grava como o owner do Walter
         case 
            when coalesce(user.userexternalid__c, '') = '' then '027443'
            else ztbsd015.usuario_esfera
         end usuario_esfera
      from 
         (
         select ztbsd015.znumext, ztbsd015.zordem, ztbsd015.zpedorig as pedido_esfera, 
            lpad(ltrim(ztbsd015.zcodoper, '0'), 6, '0') AS usuario_esfera
            from `sap_raw.ztbsd015` as ztbsd015
            --join w_lista_documentos lst on ztbsd015.zordem = lst.vbeln
            left join w_vbak as vbak on vbak.vbeln = ztbsd015.zordem
            left join w_vbrk as vbrk on vbrk.vbeln = ztbsd015.zordem               
            --WHERE 
               --TIMESTAMP_TRUNC(ztbsd015.recordstamp, DAY) >= cast(d_ini as timestamp)                   
               --AND TIMESTAMP_TRUNC(ztbsd015.recordstamp, DAY) <= cast(date_add(d_fim, interval 7 day) as timestamp)
         ) as ztbsd015
      left join w_user as user on user.userexternalid__c = ztbsd015.usuario_esfera

   ),
   w_vbap as (
      SELECT distinct vbap.vbeln, ANY_VALUE(vbap.werks) AS werks
      FROM `sap_raw.vbap` as vbap
         left join w_vbak as vbak on vbak.vbeln = vbap.vbeln
         left join w_vbrk as vbrk on vbrk.vbeln = vbap.vbeln                                    
   --WHERE 
      --TIMESTAMP_TRUNC(vbap.recordstamp, DAY) >= cast(d_ini as timestamp)                                           
      --AND TIMESTAMP_TRUNC(vbap.recordstamp, DAY) <= cast(date_add(d_fim, interval 7 day) as timestamp)                                                       
   GROUP BY vbap.vbeln
                     -- order BY vbap.vbeln
   ),
   w_vbpa as (
      select
         vbpa.vbeln, 
         -- se o user esfera nao existe ou esta inativo, 
         -- grava como o owner do Walter
         case 
            when coalesce(user.userexternalid__c, '') = '' then '027443'
            else vbpa.codigo_repre
         end codigo_repre         
      from 
         (
         SELECT vbpa.vbeln, lpad(ltrim(vbpa.lifnr, '0'), 6, '0') AS codigo_repre,
                     FROM `sap_raw.vbpa` as vbpa
                     --join w_lista_documentos lst on vbpa.vbeln = lst.vbeln
         left join w_vbak as vbak on vbak.vbeln = vbpa.vbeln
         left join w_vbrk as vbrk on vbrk.vbeln = vbpa.vbeln                                    

                     WHERE 
                        --TIMESTAMP_TRUNC(vbpa.recordstamp, DAY) >= cast(d_ini as timestamp)
                        --AND TIMESTAMP_TRUNC(vbpa.recordstamp, DAY) <= cast(date_add(d_fim, interval 7 day) as timestamp)                                                                               
                         vbpa.parvw = 'ZR'    
                     GROUP BY vbpa.vbeln, vbpa.lifnr
         ) vbpa
         left join w_user as user on user.userexternalid__c = vbpa.codigo_repre
   ),
   w_vbrp as (
    SELECT vbrp.vbeln, ANY_VALUE(vbrp.werks) AS werks
                     FROM `sap_raw.vbrp` as vbrp
                     --join w_lista_documentos lst on vbrp.vbeln = lst.vbeln
         left join w_vbak as vbak on vbak.vbeln = vbrp.vbeln
         left join w_vbrk as vbrk on vbrk.vbeln = vbrp.vbeln                                            
                     --WHERE 
                        --TIMESTAMP_TRUNC(vbrp.recordstamp, DAY) >= cast(d_ini as timestamp)                                       
                        --AND TIMESTAMP_TRUNC(vbrp.recordstamp, DAY) <= cast(date_add(d_fim, interval 7 day) as timestamp)                                                                               
                     GROUP BY vbrp.vbeln
   ),
   w_warehouse as (
      select SAPPlant__c, ExternalId__c, EmpresaOperador__c, SAPSalesOrg__c
      from `ds_view_trusted.vw_cgcloud__warehouse__c`   
  ),
w_customer_invoice as (   
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
         coalesce(vbak.ihrez, '') as referencia_externa,
         -- codigo do user no SF tem 6 posicoes
         vbpa.codigo_repre,
         ztbsd040.margem_contribuicao_cab,
         ztbsd040.margem_contabil_cab,
         vbrk.origem,
         ztbsd015.pedido_esfera,
         ztbsd015.usuario_esfera,
         vbak.zlsch as cgcloud__Payment_Method__c, 
         vbrk.tipo, 
         wh.ExternalId__c as warehouse_externalid__c
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
         and coalesce(vbak.ihrez, '') not like 'SF-%'     

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
         ztbsd015.pedido_esfera,
         ztbsd015.usuario_esfera,
         vbak.zlsch as cgcloud__Payment_Method__c,
         vbak.tipo, 
         wh.ExternalId__c as warehouse_externalid__c
    FROM w_vbak AS vbak  
	
         JOIN w_vbap as vbap  ON vbap.vbeln = vbak.vbeln 

         JOIN w_warehouse wh on wh.SAPPlant__c = vbap.werks and wh.ExternalId__c = vbak.operador_logistico         

         JOIN `sap_raw.kna1`  AS kna1     ON kna1.kunnr = vbak.kunnr

         JOIN w_ztbsf003      AS ztbsf003 ON ztbsf003.vbeln = vbak.vbeln

         JOIN w_ztbsf004 AS ztbsf004 ON ztbsf004.vbeln = vbak.vbeln
		
         LEFT JOIN w_ztbsd015 AS ztbsd015 ON ztbsd015.zordem = ztbsf004.ordem_sap
         
         LEFT JOIN w_vbpa     AS vbpa     ON vbpa.vbeln = vbak.vbeln

         LEFT JOIN w_ztbsd040 AS ztbsd040 ON ztbsd040.vbeln = vbak.vbeln 
      
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
         -- para o caso de duas faturas, aqui vai a menor data
         -- nos itens vai o numero da fatura e data de cada item faturado.
         min(erdat) as cgcloud__Order_Date__c,
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
   
--   WHERE ordem_sap = '0007825656'

   group by 
      ExternalId__c, auart, warehouse_externalid__c, kunnr, referencia_externa, ordem_sap, codigo_repre, 
      usuario_esfera, waerk, pedido_esfera, origem, cgcloud__Payment_Method__c, vtweg, tipo
   order by SAPOrderNumber__c
);