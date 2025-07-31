-- CV_VIEW_PEDIDOS_CLIENTE_CT_TESTE

WITH w_TVZBT as (
    select ZTERM, vtext
    from `dados-dev.raw.TVZBT`
),
w_ped_aux as (
    SELECT 
        E_SALESDOCUMENT as PEDIDO_SAP, REPLACE(STRING(cabecalho.datapedido), '-', '') AS DATA, cabecalho.condpg as COND_PAG, 
        cabecalho.cnpjcliente as cnpj, 'Integrado' as status, cabecalho.cnpjvendedor, cabecalho.pedido as pedido_portal, 
        round(sum(itens.precounitario*itens.quantidade),2) as valor,
        T.vtext || ' dias' forma_pagamento, cabecalho.representante, cabecalho.sapIdClient as cliente,
        cast(REPLACE(cabecalho.pedido, 'CT-', '') as INT64) as timestamp_pedido, cabecalho.razao_social
    FROM 
        dados-dev.raw_cimed_tech.ct_pedidos_auxiliar, UNNEST(itens) as itens
    join
        w_TVZBT AS T
        on T.ZTERM = cabecalho.condpg
    group by 
        E_SALESDOCUMENT,
        cabecalho.datapedido, cabecalho.condpg, cabecalho.cnpjcliente, cabecalho.cnpjvendedor, cabecalho.pedido, T.zterm, T.vtext, 
        cabecalho.representante, cabecalho.sapIdClient, cabecalho.razao_social
),
w_dash as (
	SELECT 
		D.DOC_VENDA as PEDIDO_SAP, 
        DT_OV as DATA, 
		D.COND_PAG, D.CLIENTE,    
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
		D.RAZAO_SOCIAL, T.vtext || ' dias' forma_pagamento, 
		D.VENDEDOR, D.PEDIDO_PORTAL, 
		case
            when coalesce(c.pedido_sap, '') <> '' then c.motivo -- pedido cancelado no SAP
            else
                case		
                when D.COCKPIT = 'Faturamento' then 'Faturado'
                when D.COCKPIT = 'Bloqueio Comercial'  then 'Bloq Coml'
                when D.COCKPIT = 'Bloqueio de Estoque' then 'Bloq Estq'
                when D.COCKPIT = 'Bloqueio Financeiro' then 'Bloq Fin'

                when D.COCKPIT in ('Ordem Sem Remessa') then 'S/Remessa'
                when D.COCKPIT in ('Ordem Com Remessa') then 'C/Remessa'
                when D.COCKPIT in ('Cancelado', 'Itens Cancelados', 'Recusa Financeiro') then 'Cancelado'
                else D.COCKPIT
            end
		end AS STATUS_FINAL, 
        d.DATAHORA_TIMESTAMP, ERNAM
	FROM 
		`dados-dev.raw_cimed_tech.CV_DASH_MV_VISAO_T` D
	join
		w_TVZBT T        
		on T.ZTERM = D.COND_PAG
    LEFT JOIN 
        `dados-dev.raw_cimed_tech.CV_VIEW_PEDIDOS_CLIENTE_CANCELADO_T` C    
        on C.pedido_sap = D.DOC_VENDA
	GROUP BY
		D.DOC_VENDA, D.DT_OV, D.COND_PAG, D.CLIENTE, D.RAZAO_SOCIAL, D.COCKPIT, D.RAZAO_SOCIAL,
		T.vtext, D.VENDEDOR, D.PEDIDO_PORTAL, d.DATAHORA_TIMESTAMP, D.CNPJCLIENTE, ERNAM, C.pedido_sap, c.motivo
)
-- select principal, primeiro somente pedido CT-DIGIBEE
select 
    aux.PEDIDO_SAP, aux.DATA, aux.COND_PAG, 
    case 
        when coalesce(D.pedido_sap, '') = '' then aux.cliente
        else D.CLIENTE
    end as CLIENTE,
    case 
        when coalesce(d.pedido_sap, '') = '' then aux.STATUS
        when coalesce(d.pedido_sap, '') <> '' then D.status
        else ''
    end as STATUS, 
    aux.VALOR, aux.CNPJ, 
    case when coalesce(d.pedido_sap, '') = '' then aux.razao_social
        else D.RAZAO_SOCIAL
    end as RAZAO_SOCIAL, aux.forma_pagamento, 
    case when coalesce(d.pedido_sap, '') = '' then aux.representante
    else D.VENDEDOR
    end as VENDEDOR, aux.PEDIDO_PORTAL,
    -- se esta cancelado tem q fazer o DE->PARA 
    CASE 
        WHEN COALESCE(d.status_final, '') = '' THEN aux.status
        WHEN COALESCE(d.status_final, '') <>'' THEN D.status_final       
        ELSE ''
    end as STATUS_FINAL,
    case when coalesce(d.pedido_sap, '') = '' then timestamp_pedido
        else D.DATAHORA_TIMESTAMP
    end as timestamp_pedido
from 
    w_ped_aux as aux
LEFT JOIN
    w_dash AS D
    ON D.PEDIDO_SAP = aux.pedido_sap
where 
    ERNAM = 'RFC_DIGIBEE'
union all 
-- aqui tudo que não é RFC_DIGIBEE
select 
    D.PEDIDO_SAP, D.DATA, D.COND_PAG, 
    D.CLIENTE,D.status, D.VALOR, D.CNPJ, 
    D.RAZAO_SOCIAL, D.forma_pagamento, D.VENDEDOR, D.PEDIDO_PORTAL,
    D.STATUS_FINAL, D.DATAHORA_TIMESTAMP as timestamp_pedido
from 
    w_dash AS D
where 
    ERNAM <> 'RFC_DIGIBEE'