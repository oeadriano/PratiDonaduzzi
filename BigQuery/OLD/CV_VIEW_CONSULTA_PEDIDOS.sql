-- CV_VIEW_CONSULTA_PEDIDOS
WITH 
  w_rep_clientes as (
    select 
      distinct codigo, cli_est as estado, cli_cid as cidade
    from `dados-dev.raw_cimed_tech.REP_CLIENTES_IP_T`
  ),
w_lif_lojas_supervisor as 
(
    select 
        distinct l.lifnr, l.cod_gama as loja, r.vnd_cod_sap as cod_superior
    from 
        `dados-dev.raw_cimed_tech.LOJAS_LIFNR_T` as l
    join 
        `dados-dev.visoes_cimed_tech.CV_SF_CADASTRO_REPRESENTANTES` r
        on r.vnd_cod_sap = l.lifnr
),
w_TVZBT as (
    select ZTERM, vtext
    --from `dados-dev.raw.TVZBT`
    from dados-dev.sap.VH_MD_TVZBT    
    where ZTERM between '1000' and '1999'    
),
w_dash as (
    SELECT 
        D.DOC_VENDA as PEDIDO_SAP, 
        DT_OV as DATA, 
        D.COND_PAG, D.CLIENTE,    
        case
            when D.COCKPIT = 'Faturamento' then 'Faturado'
            when D.COCKPIT in ('Bloqueio Comercial', 'Bloqueio de Estoque', 'Bloqueio Financeiro') then 'Bloqueado' 
            when D.COCKPIT in ('Ordem Sem Remessa') then 'Liberado'
            when D.COCKPIT in ('Ordem Com Remessa') then 'Separação'
            when D.COCKPIT in ('Cancelado', 'Itens Cancelados', 'Recusa Financeira') then 'Cancelado'        
            else D.COCKPIT
        end AS STATUS, round(SUM(VLR_LIQUIDO),2) AS VALOR, D.CNPJCLIENTE AS CNPJ, 
        D.RAZAO_SOCIAL, T.vtext || ' dias' forma_pagamento, 
        D.VENDEDOR, D.PEDIDO_PORTAL, 
        case        
            when D.COCKPIT = 'Faturamento' then 'Faturado'
            when D.COCKPIT = 'Bloqueio Comercial'  then 'Bloq Coml'
            when D.COCKPIT = 'Bloqueio de Estoque' then 'Bloq Estq'
            when D.COCKPIT = 'Bloqueio Financeiro' then 'Bloq Fin'

            when D.COCKPIT in ('Ordem Sem Remessa') then 'S/Remessa'
            when D.COCKPIT in ('Ordem Com Remessa') then 'C/Remessa'
            when D.COCKPIT in ('Cancelado', 'Itens Cancelados', 'Recusa Financeira') then 'Cancelado'
            else D.COCKPIT
        end AS STATUS_FINAL, 
        d.DATAHORA_TIMESTAMP, ERNAM, CENTRO, cli.estado, cli.cidade, loj.loja, loj.cod_superior
    FROM 
        `dados-dev.raw_cimed_tech.CV_DASH_MV_VISAO_T` D
    JOIN 
        w_rep_clientes as cli
        on cli.codigo = D.cliente        
    left join
        w_TVZBT T        
        on T.ZTERM = D.COND_PAG
    join 
        w_lif_lojas_supervisor as loj
        on loj.lifnr = D.VENDEDOR
    WHERE
        DT_OV_D >= date_sub(current_date, interval 3 month)
    GROUP BY
        D.DOC_VENDA, D.DT_OV, D.COND_PAG, D.CLIENTE, D.RAZAO_SOCIAL, D.COCKPIT, D.RAZAO_SOCIAL,
        T.vtext, D.VENDEDOR, D.PEDIDO_PORTAL, d.DATAHORA_TIMESTAMP, D.CNPJCLIENTE, ERNAM, centro,
        cli.estado, cli.cidade, loj.loja, loj.cod_superior
)
-- select principal, primeiro somente pedido CT-DIGIBEE
select 
    *
FROM 
    w_dash as D
