WITH
  w_warehouse as (
      select SAPPlant__c, ExternalId__c, EmpresaOperador__c, SAPSalesOrg__c
      from `ds_view_trusted.vw_cgcloud__warehouse__c`
  ),
  w_customer_invoice as (
   select * from ds_view_trusted.vw_customer_invoice
  )  
  -- pedidos YVOL - operador logistico
  SELECT DISTINCT 
         case
            when auart = 'YBOR'then 'Pedido Padrão'
            when auart = 'YVOL'then 'Pedido Operador Logístico'
            when auart = 'YBON'then 'Pedido Bonificado'
            else ''
         end as gcloud__Order_Template__c, 
         auart as cgcloud__Document_Type__c, 
         wh.ExternalId__c as warehouse_externalid__c,
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
         sum(coalesce(netwr_cab, 0)) as valor_produto, --netwr_cab         
         ordem_sap as SAPOrderNumber__c, 
         
         -- IcmsAmount__c entra no item abaixo?
         sum(coalesce(netwr_cab, 0)) + sum(coalesce(mwsbp_cab, 0)) + sum(coalesce(st_cab, 0)) cgcloud__Gross_Total_Value__c,  -- valort total do pedido com impostos
         coalesce(cgcloud__Payment_Method__c, 'A') as cgcloud__Payment_Method__c -- metodo de pagamento
    FROM 
         w_customer_invoice
         join w_warehouse wh
            on wh.SAPPlant__c = werks and wh.ExternalId__c = operador_logistico
   WHERE 
      origem = 'O' 
   group by 
      ExternalId__c, auart, wh.ExternalId__c, kunnr, erdat, referencia_externa, ordem_sap, codigo_repre, 
      usuario_esfera, usuario_esfera, waerk, pedido_esfera, origem, cgcloud__Payment_Method__c

union all

-- pedidos YBON e YBOR - empresa
  SELECT DISTINCT 
         case
            when auart = 'YBOR'then 'Pedido Padrão'
            when auart = 'YVOL'then 'Pedido Operador Logístico'
            when auart = 'YBON'then 'Pedido Bonificado'
            else ''
         end as gcloud__Order_Template__c, 
         auart as cgcloud__Document_Type__c, 
         wh.ExternalId__c as warehouse_externalid__c,
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
         usuario_esfera as Owner_UserExternalID__c, 
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
         sum(coalesce(netwr_cab, 0) + coalesce(mwsbp_cab, 0) + coalesce(st_cab, 0)) as TotalInvoicedAmount__c, -- Valor Total Faturado - SAP
         sum(coalesce(mwsbp_cab, 0)) as IcmsAmount__c, -- Valor ICMS - SAP
         sum(coalesce(st_cab, 0)) as StAmount__c, -- Valor ST - SAP(Duplicidade de campo com ActualStTax__c ?)
         sum(coalesce(fci_cab, 0)) as FciAmount__c, -- Valor FCI - SAP
         sum(coalesce(descfin_cab, 0)) as FinancialDiscount__c, -- Valor desconto financeiro - SAP
         origem, -- sap / OL? 
         sum(coalesce(netwr_cab, 0)) as valor_produto, --netwr_cab         
         ordem_sap as SAPOrderNumber__c,          
         -- IcmsAmount__c entra no item abaixo?
         sum(coalesce(netwr_cab, 0) + coalesce(mwsbp_cab, 0) + coalesce(st_cab, 0)) cgcloud__Gross_Total_Value__c, -- valort total do pedido com impostos
         coalesce(cgcloud__Payment_Method__c, 'A') as cgcloud__Payment_Method__c -- metodo de pagamento
    FROM 
         w_customer_invoice
         join w_warehouse wh
            on wh.SAPPlant__c = werks and wh.SAPSalesOrg__c = vkorg
   WHERE 
      origem = 'S'
      and wh.EmpresaOperador__c = 'Empresa'      
   group by 
      ExternalId__c, auart, wh.ExternalId__c, kunnr, erdat, referencia_externa, ordem_sap, codigo_repre, 
      usuario_esfera, usuario_esfera, waerk, pedido_esfera, origem, cgcloud__Payment_Method__c      

