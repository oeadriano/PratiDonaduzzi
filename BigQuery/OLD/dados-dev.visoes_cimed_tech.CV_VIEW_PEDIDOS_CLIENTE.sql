WITH w_vbkd AS (
    SELECT DISTINCT vbeln, zterm FROM `dados-dev.raw_cimed_tech.VBKD`
),
w_TVZBT as (
    select ZTERM, vtext
    from `dados-dev.raw.TVZBT`
),
w_dash as 
(
SELECT 
    D.DOC_VENDA AS PEDIDO_SAP, D.DT_OV AS DATA, v.zterm as COND_PAG, D.CLIENTE, 
    case
        when D.COCKPIT = 'Faturamento' then 'Faturado'
        when D.COCKPIT in ('Bloqueio Comercial', 'Bloqueio de Estoque', 'Bloqueio Financeiro') then 'Bloqueado' 
        when D.COCKPIT in ('Ordem Sem Remessa') then 'Liberado'
        when D.COCKPIT in ('Ordem Com Remessa') then 'Separação'
        when D.COCKPIT in ('Cancelado', 'Itens Cancelados', 'Recusa Financeiro') then 'Cancelado'        
        else D.COCKPIT
    end AS STATUS, round(SUM(VLR_LIQUIDO),2) AS VALOR, D.CNPJCLIENTE as CNPJ, 
    D.RAZAO_SOCIAL, T.vtext || ' dias' forma_pagamento, 
    D.VENDEDOR, D.PEDIDO_PORTAL, 
    case                                     
        when D.COCKPIT = 'Faturamento' then 'Faturado'
        when D.COCKPIT = 'Bloqueio Comercial'  then 'Bloq Coml'
        when D.COCKPIT = 'Bloqueio de Estoque' then 'Bloq Estq'
        when D.COCKPIT = 'Bloqueio Financeiro' then 'Bloq Fin'

        when D.COCKPIT in ('Ordem Sem Remessa') then 'S/Remessa'
        when D.COCKPIT in ('Ordem Com Remessa') then 'C/Remessa'
        when D.COCKPIT in ('Cancelado', 'Itens Cancelados', 'Recusa Financeiro') then 'Cancelado'
        else D.COCKPIT
    end AS STATUS_FINAL, D.DATAHORA_TIMESTAMP as timestamp_pedido    
FROM 
    `dados-dev.visoes_auxiliares_cimed_tech.CV_DASH_MV_VISAO` D
join
    w_vbkd as v
    on v.vbeln = D.DOC_VENDA
join
    w_TVZBT T
    on T.ZTERM = v.zterm
GROUP BY
    D.DOC_VENDA, D.DT_OV, v.zterm, D.CLIENTE, D.COCKPIT, D.RAZAO_SOCIAL, T.vtext, D.VENDEDOR, D.PEDIDO_PORTAL, D.DATAHORA_TIMESTAMP, D.CNPJCLIENTE
)
select 
    D.PEDIDO_SAP, D.DATA, D.COND_PAG, D.CLIENTE, D.STATUS, D.VALOR, D.CNPJ, D.RAZAO_SOCIAL, D.forma_pagamento, 
    D.VENDEDOR, D.PEDIDO_PORTAL, D.STATUS_FINAL, D.timestamp_pedido      
from 
    w_dash as D