WITH w_TVZBT as (
    select ZTERM, vtext
    from `dados-dev.raw.TVZBT`
),
w_ped_aux as (
    SELECT 
        E_SALESDOCUMENT as PEDIDO_SAP, REPLACE(STRING(cabecalho.datapedido), '-', '') AS DATA, cabecalho.condpg as COND_PAG, 
        cabecalho.cnpjcliente as cnpj, 'Integrado' as status, cabecalho.cnpjvendedor, cabecalho.pedido as pedido_portal, 
        round(sum(itens.precounitario*itens.quantidade),2) as valor,
        T.vtext || ' dias' forma_pagamento, cabecalho.representante, cabecalho.sapIdClient as cliente
    FROM 
        dados-dev.raw_cimed_tech.ct_pedidos_auxiliar, UNNEST(itens) as itens
    join
        w_TVZBT AS T
        on T.ZTERM = cabecalho.condpg
    group by 
        E_SALESDOCUMENT,
        cabecalho.datapedido, cabecalho.condpg, cabecalho.cnpjcliente, cabecalho.cnpjvendedor, cabecalho.pedido, T.zterm, T.vtext, 
        cabecalho.representante, cabecalho.sapIdClient
),
w_dash as 
(
SELECT 
    D.DOC_VENDA AS PEDIDO_SAP, DT_OV as DATA, 
    D.COND_PAG, D.CLIENTE,    
    case
        when D.COCKPIT = 'Faturamento' then 'Faturado'
        when D.COCKPIT in ('Bloqueio Comercial', 'Bloqueio de Estoque', 'Bloqueio Financeiro') then 'Bloqueado' 
        when D.COCKPIT in ('Ordem Sem Remessa') then 'Liberado'
        when D.COCKPIT in ('Ordem Com Remessa') then 'Separação'
        when D.COCKPIT in ('Cancelado', 'Itens Cancelados', 'Recusa Financeiro') then 'Cancelado'        
        else D.COCKPIT
    end AS STATUS, round(SUM(VLR_LIQUIDO),2) AS VALOR, '' AS CNPJ, 
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
    end AS STATUS_FINAL        
FROM 
    `dados-dev.visoes_auxiliares_cimed_tech.CV_DASH_MV_VISAO` D
join
    w_TVZBT T
    on T.ZTERM = D.COND_PAG
WHERE 
    D.PEDIDO_PORTAL like 'CT-%'-- ISSO TEM Q MUDAR
GROUP BY
    D.DOC_VENDA, D.DT_OV, D.COND_PAG, D.CLIENTE, D.RAZAO_SOCIAL, D.COCKPIT, D.RAZAO_SOCIAL,
    T.vtext, D.VENDEDOR, D.PEDIDO_PORTAL
)
-- select principal
select 
    aux.PEDIDO_SAP, aux.DATA, aux.COND_PAG, 
    case 
        when coalesce(c.pedido_sap, '') = '' then aux.cliente
        else D.CLIENTE
    end as CLIENTE,
    case 
        when coalesce(c.pedido_sap, '') = '' AND coalesce(d.pedido_sap, '') = '' then aux.STATUS
        when coalesce(c.pedido_sap, '') = '' AND coalesce(d.pedido_sap, '') <> '' then d.status
        when coalesce(c.pedido_sap, '') <> '' then 'Cancelado'
        else ''
    end as STATUS, 
    aux.VALOR, aux.CNPJ, 
    case when coalesce(c.pedido_sap, '') = '' then 'FALTA KNA1'
        else D.RAZAO_SOCIAL
    end as RAZAO_SOCIAL, aux.forma_pagamento, 
    case when coalesce(c.pedido_sap, '') = '' then aux.representante
    else D.VENDEDOR
    end as VENDEDOR, aux.PEDIDO_PORTAL,
    -- se esta cancelado tem q fazer o DE->PARA 
    CASE 
        WHEN coalesce(c.pedido_sap, '') = '' and COALESCE(d.status_final, '') = '' THEN aux.status
        WHEN coalesce(c.pedido_sap, '') = '' and COALESCE(d.status_final, '') <>'' THEN d.status_final       
        WHEN coalesce(c.pedido_sap, '') <> '' and c.motivo = 'Limite Excedido'               then 'Lim Exced'
        WHEN coalesce(c.pedido_sap, '') <> '' and c.motivo = 'Duplicata Vencida'             then 'Dup Venc.'
        WHEN coalesce(c.pedido_sap, '') <> '' and c.motivo = 'Restrição Serasa'              then 'Serasa'
        WHEN coalesce(c.pedido_sap, '') <> '' and c.motivo = 'Zpre cliente < do sistema'     then 'Zpre Cli'
        WHEN coalesce(c.pedido_sap, '') <> '' and c.motivo = 'Lote validade curta'           then 'Lote VC'
        WHEN coalesce(c.pedido_sap, '') <> '' and c.motivo = 'Material sem Estoque'          then 'S/Estoque'
        WHEN coalesce(c.pedido_sap, '') <> '' and c.motivo = 'Atendimento Parcial'           then 'A Parcial'
        WHEN coalesce(c.pedido_sap, '') <> '' and c.motivo = 'Atualizar Cadastro'            then 'Cad desat'
        WHEN coalesce(c.pedido_sap, '') <> '' and c.motivo = 'Não aprovado pelo responsavel' then 'Não Aprov'
        WHEN coalesce(c.pedido_sap, '') <> '' and c.motivo = 'Valor Preço Mínimo'            then 'Preço min'
        WHEN coalesce(c.pedido_sap, '') <> '' and c.motivo = 'Cancel Administração'          then 'Canc Adm'
        WHEN coalesce(c.pedido_sap, '') <> '' and c.motivo = 'Valor Mínimo Ordem'            then 'Pd Minimo'
        WHEN coalesce(c.pedido_sap, '') <> '' and c.motivo = 'Cancelamento EDI'              then 'Cand EDI'
        WHEN coalesce(c.pedido_sap, '') <> '' and c.motivo = 'Cancel Cliente'                then 'Canc Cli'
        WHEN coalesce(c.pedido_sap, '') <> '' and c.motivo = 'Cadast Desatualizado'          then 'Cad desat'
        --ELSE d.status_final
        ELSE ''
    end as STATUS_FINAL
from 
    w_ped_aux as aux
LEFT JOIN
    (
    select 
        PEDIDO_SAP, DATA, COND_PAG, CLIENTE, STATUS, VALOR, CNPJ, RAZAO_SOCIAL, forma_pagamento, VENDEDOR, PEDIDO_PORTAL, STATUS_FINAL      
    from 
        w_dash 
    ) as d
    ON d.pedido_sap = aux.pedido_sap
LEFT JOIN 
    `dados-dev.visoes_cimed_tech.CV_VIEW_PEDIDOS_CLIENTE_CANCELADO` C
    ON C.pedido_sap = aux.pedido_sap



