-- CV_SF_CONSULTA_PEDIDOS
WITH w_TVZBT as (
    select 
        ZTERM, vtext, 
        cast(length(vtext)-length(replace(vtext, '/', ''))+1 as string) as parcelas
    --from `dados-dev.raw.TVZBT`
    from dados-dev.sap.VH_MD_TVZBT    
    where ZTERM between '1000' and '1999'
    order by zterm
),
w_ped_aux as (
    SELECT 
        E_SALESDOCUMENT as PEDIDO_SAP, STRING(cabecalho.datapedido) AS DATA, cabecalho.condpg as COND_PAG, 
        cabecalho.cnpjcliente as cnpj, 'Integrado' as status, cabecalho.cnpjvendedor, cabecalho.pedido as pedido_portal, 
        round(sum(itens.precounitario*itens.quantidade),2) as valor,
        T.vtext || ' dias' forma_pagamento, cabecalho.representante, cabecalho.sapIdClient as cliente,
        cast(REPLACE(cabecalho.pedido, 'CT-', '') as INT64) as timestamp_pedido, cabecalho.razao_social, 
        cabecalho.orgvendas, cabecalho.canal, integrador as ERNAM,t.parcelas as qde_parcelas, 'Integrado' as status_final,         
        t.parcelas|| '_' || t.zterm || '_' || t.vtext as id_unico        
    FROM 
        dados-dev.raw_cimed_tech.ct_pedidos_auxiliar, UNNEST(itens) as itens
    left join
        w_TVZBT AS T
        on T.ZTERM = cabecalho.condpg
    group by 
        E_SALESDOCUMENT,
        cabecalho.datapedido, cabecalho.condpg, cabecalho.cnpjcliente, cabecalho.cnpjvendedor, cabecalho.pedido, T.zterm, T.vtext, 
        cabecalho.representante, cabecalho.sapIdClient, cabecalho.razao_social, cabecalho.orgvendas, cabecalho.canal, 
		integrador, t.parcelas
),
w_dash as (
	SELECT 
		D.DOC_VENDA as PEDIDO_SAP, 
        substring(DT_OV, 1, 4)||'-'||substring(DT_OV, 5, 2)||'-'||substring(DT_OV, 7, 2) as DATA, 
		coalesce(D.COND_PAG, '') as COND_PAG, D.CLIENTE,    
		case
            when coalesce(c.pedido_sap, '') <> '' then 'Cancelado' -- pedido cancelado no SAP
            else             
                case
                when D.COCKPIT = 'Faturamento' then 'Faturado'
                when D.COCKPIT in ('Bloqueio Comercial', 'Bloqueio de Estoque', 'Bloqueio Financeiro') then 'Bloqueado' 
                when D.COCKPIT in ('Ordem Sem Remessa') then 'Liberado'
                when D.COCKPIT in ('Ordem Com Remessa') then 'Separação'
                when D.COCKPIT in ('Cancelado', 'Itens Cancelados', 'Recusa Financeiro') then 'Cancelado'        
                else D.COCKPIT
            end
		end AS STATUS, round(SUM(VLR_LIQUIDO),2) AS VALOR, D.CNPJCLIENTE AS CNPJ, 
		D.RAZAO_SOCIAL, coalesce(T.vtext || ' dias', '') as forma_pagamento, 
		D.VENDEDOR, D.PEDIDO_PORTAL, 
		case
            when coalesce(c.pedido_sap, '') <> '' then 'Cancelado' -- pedido cancelado no SAP
            else D.COCKPIT
		end AS STATUS_FINAL, 
        coalesce(c.motivo, '') as  motivo_cancelamento, 
        d.DATAHORA_TIMESTAMP, D.ERNAM, D.ORG_VENDA, D.CANAL_DISTR, t.parcelas as qde_parcelas, 
        max(D.ETL_VENDA) as ETL_VENDA, 
        max(D.ETL_REMESSA) AS ETL_REMESSA, 
        MAX(D.ETL_FATURAMENTO) AS ETL_FATURAMENTO,
        t.parcelas|| '_' || t.zterm || '_' || t.vtext as id_unico
	FROM 
		`dados-dev.raw_cimed_tech.CV_DASH_MV_VISAO_T` D
	left join
		w_TVZBT T        
		on T.ZTERM = D.COND_PAG
    LEFT JOIN 
        `dados-dev.raw_cimed_tech.CV_VIEW_PEDIDOS_CLIENTE_CANCELADO_T` C    
        on C.pedido_sap = D.DOC_VENDA
    WHERE 
        D.DOC_TIPO in ('ZNOR', 'ZGOV', 'YTRI', 'ZV12') 
	GROUP BY
		D.DOC_VENDA, D.DT_OV, D.COND_PAG, D.CLIENTE, D.RAZAO_SOCIAL, D.COCKPIT, D.RAZAO_SOCIAL,
		T.vtext, D.VENDEDOR, D.PEDIDO_PORTAL, d.DATAHORA_TIMESTAMP, D.CNPJCLIENTE, C.pedido_sap, c.motivo, 
        D.ERNAM, D.ORG_VENDA, D.CANAL_DISTR, t.parcelas, t.zterm, t.vtext
)
-- select principal, primeiro somente pedido CT-DIGIBEE
select 
    aux.DATA AS Data_OV__c, aux.PEDIDO_PORTAL as Pedido_Portal__c,     
    aux.VALOR as Valor_do_pedido_original__c,
    case 
        when coalesce(d.pedido_sap, '') = '' then aux.STATUS
        when coalesce(d.pedido_sap, '') <> '' then D.status
        else ''
    end as Status, 
    case 
        when coalesce(d.pedido_sap, '') = '' then aux.status_final
        when coalesce(d.pedido_sap, '') <> '' then D.status_final
        else ''
    end as status_final, 
    coalesce(motivo_cancelamento, '') as  motivo_cancelamento, 
    aux.PEDIDO_SAP as Codigo_Pedido_SAP__c, '' as Mensagem_Integracao__c,
    aux.COND_PAG as Codigo_Condicao_Pagamento__c,     
    case 
        when coalesce(D.pedido_sap, '') = '' then aux.cliente
        else D.CLIENTE 
    end as Codigo_SAP__c,
    case 
        when coalesce(D.pedido_sap, '') = '' then aux.orgvendas
        else D.ORG_VENDA 
    end as Organizacao_Vendas__c, 
    case 
        when coalesce(D.pedido_sap, '') = '' then aux.canal
        else D.CANAL_DISTR
    end as Canal__c, 
    case 
        when coalesce(d.pedido_sap, '') = '' then aux.representante
        else D.VENDEDOR 
    end as Codigo_Vendedor_SAP__c, 
    aux.forma_pagamento as desdobramento, 
    replace(aux.forma_pagamento, ' dias', '') as parcelas, 
    case 
        when coalesce(d.pedido_sap, '') = '' then aux.ERNAM
        else D.ERNAM
    end as Ernam__c,
								
    case 
        when coalesce(D.id_unico, '') = '' then aux.id_unico
        else D.id_unico
    end as Id_unico__c, 						
    -- TIMESTAMP_MILLIS(case when coalesce(d.pedido_sap, '') = '' then aux.timestamp_pedido else D.DATAHORA_TIMESTAMP end) as Data_Hora_Pedido,     
    replace(substring(cast(TIMESTAMP_MILLIS(case when coalesce(d.pedido_sap, '') = '' then aux.timestamp_pedido else D.DATAHORA_TIMESTAMP end) as STRING), 1, 10)||'T'||
            substring(cast(TIMESTAMP_MILLIS(case when coalesce(d.pedido_sap, '') = '' then aux.timestamp_pedido else D.DATAHORA_TIMESTAMP end) as STRING), 12, 10)||'Z','+0', '')
    as Data_Hora_Pedido,
    case when coalesce(D.ETL_VENDA, '') = '' then '' else substring(D.ETL_VENDA, 1, 10)||'T'||substring(D.ETL_VENDA, 12, 10)||'Z' end as ETL_VENDA, 
    case when coalesce(D.ETL_REMESSA, '') = '' then '' else substring(D.ETL_REMESSA, 1, 10)||'T'||substring(D.ETL_REMESSA, 12, 10)||'Z' end as ETL_REMESSA,     
    case when coalesce(D.ETL_FATURAMENTO, '') = '' then '' else substring(D.ETL_FATURAMENTO, 1, 10)||'T'||substring(D.ETL_FATURAMENTO, 12, 10)||'Z' end as ETL_FATURAMENTO,     
    cast(SUBSTRING(cast(TIMESTAMP_MILLIS(case when coalesce(d.pedido_sap, '') = '' then aux.timestamp_pedido else D.DATAHORA_TIMESTAMP end) as STRING), 1, 19) as timestamp)AS LAST_UPDATE,
    'w_ped_aux' as tipo    	
from 
    w_ped_aux as aux
LEFT JOIN
    w_dash AS D
    ON D.PEDIDO_SAP = aux.pedido_sap 
where 
    D.ERNAM in('RFC_DIGIBEE') OR 
    aux.ERNAM in ('CimedTech')

union all 
-- aqui tudo que não é RFC_DIGIBEE
select 
    D.DATA as Data_OV__c, D.PEDIDO_PORTAL as Pedido_Portal__c, D.VALOR as Valor_do_pedido_original__c,
    D.status, D.status_final, '' as motivo_cancelamento, D.PEDIDO_SAP as Codigo_Pedido_SAP__c, '' as Mensagem_Integracao__c, 
    D.COND_PAG as Codigo_Condicao_Pagamento__c, 
    D.CLIENTE as Codigo_SAP__c, D.ORG_VENDA as Organizacao_Vendas__c, D.CANAL_DISTR as Canal__c, 
    D.VENDEDOR as Codigo_Vendedor_SAP__c, D.forma_pagamento as desdobramento,
    replace(D.forma_pagamento, ' dias', '') as parcelas, 
    D.ERNAM as Ernam__c, 
    coalesce(D.id_unico, '1_1000_7') as Id_Unico__c,
    cast(TIMESTAMP_MILLIS(D.DATAHORA_TIMESTAMP) AS STRING) as Data_Hora_Pedido,     
    case when coalesce(D.ETL_VENDA, '') = '' then '' else substring(D.ETL_VENDA, 1, 10)||'T'||substring(D.ETL_VENDA, 12, 10)||'Z' end as ETL_VENDA, 
    case when coalesce(D.ETL_REMESSA, '') = '' then '' else substring(D.ETL_REMESSA, 1, 10)||'T'||substring(D.ETL_REMESSA, 12, 10)||'Z' end as ETL_REMESSA,     
    case when coalesce(D.ETL_FATURAMENTO, '') = '' then '' else substring(D.ETL_FATURAMENTO, 1, 10)||'T'||substring(D.ETL_FATURAMENTO, 12, 10)||'Z' end as ETL_FATURAMENTO,
        cast(SUBSTRING(CAST(case 
            when (ETL_FATURAMENTO <> '') and (ETL_REMESSA = '') AND (ETL_VENDA <> '') then ETL_FATURAMENTO    
            when COALESCE(ETL_VENDA||ETL_REMESSA||ETL_FATURAMENTO, '') = '' THEN CAST(D.DATAHORA_TIMESTAMP AS STRING)
            when (ETL_VENDA > ETL_REMESSA) and (ETL_VENDA > ETL_FATURAMENTO) then ETL_VENDA
            when (ETL_REMESSA > ETL_VENDA ) and (ETL_REMESSA > ETL_FATURAMENTO) then ETL_REMESSA
            when (ETL_FATURAMENTO > ETL_VENDA ) and (ETL_FATURAMENTO > ETL_REMESSA) then ETL_REMESSA
            else ETL_VENDA
        end AS STRING),1,19) AS TIMESTAMP) AS LAST_UPDATE, 
    'w_dash' as tipo
from 
    w_dash AS D
where 
    D.ERNAM <> 'RFC_DIGIBEE'