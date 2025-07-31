-- CV_VIEW_PEDIDOS_CLIENTE
-- AEO 24.11.2021
WITH W_KNA1 AS (
    SELECT KUNNR, NAME1, STCD1 FROM `dados-dev.raw.KNA1` 
), 
w_vbkd AS (
    SELECT DISTINCT vbeln, zterm FROM `dados-dev.raw_cimed_tech.VBKD`
), 
w_vbak as (
    select vbeln, BSTNK
    from `dados-dev.raw.VBAK`
    where AUART in ('ZNOR', 'ZV12')
    and VTWEG in ('07', '10')
)
SELECT 
    D.DOC_VENDA AS PEDIDO_SAP,  D.DT_OV AS DATA, D.COND_PAG, 
    D.CLIENTE, 
    case
        when D.COCKPIT = 'Faturamento' then 'Faturado'
        when D.COCKPIT in ('Bloqueio Comercial', 'Bloqueio de Estoque', 'Bloqueio Financeiro') then 'Bloqueado' 
        when D.COCKPIT in ('Ordem Sem Remessa') then 'Liberado'
        when D.COCKPIT in ('Ordem Com Remessa') then 'Separação'
        when D.COCKPIT in ('Cancelado', 'Itens Cancelados', 'Recusa Financeiro') then 'Cancelado'        
        else D.COCKPIT
    end AS STATUS, round(SUM(VLR_LIQUIDO),2) AS VALOR, K.STCD1 AS CNPJ, 
    K.NAME1 AS RAZAO_SOCIAL, T.vtext || ' dias' forma_pagamento, 
    D.VENDEDOR, vbak.BSTNK as PEDIDO_PORTAL
FROM 
    `dados-dev.visoes_auxiliares_cimed_tech.CV_DASH_MV_VISAO` D
join
    w_vbak as vbak
    on vbak.vbeln = DOC_VENDA    
join
    w_vbkd as v
    on v.vbeln = vbak.vbeln
JOIN
    W_KNA1 AS K
    ON K.KUNNR = D.CLIENTE
join
    `dados-dev.raw.TVZBT` T
    --on T.ZTERM = D.COND_PAG
    on T.ZTERM = v.zterm
--WHERE
    --D.VENDEDOR = '0000600890'
    --AND D.DT_OV BETWEEN '20210901' AND '20210930'
GROUP BY
    D.DOC_VENDA, D.DT_OV, D.COND_PAG, D.CLIENTE, D.COCKPIT, K.KUNNR, K.STCD1, K.NAME1, 
    T.vtext , D.VENDEDOR, vbak.BSTNK
/*
SELECT
	 "PEDIDO_SAP", "DATA", "PEDIDO_PORTAL", "FORMA_PAGAMENTO", "RAZAO_SOCIAL",
	 "CNPJ", "STATUS", "VALOR" 
FROM 
    "_SYS_BIC"."CimedTech/CV_VIEW_PEDIDOS_LIFNR"
    
     (
        PLACEHOLDER."$$IP_LIFNR$$" => {{ message.queryAndPath.lifnr }},
        PLACEHOLDER."$$IP_DATA_DE$$" => {{ message.queryAndPath.data_de }},
        PLACEHOLDER."$$IP_DATA_ATE$$" => {{ message.queryAndPath.data_ate }}
     );

*/


/*
WITH w_vbak as (
    select vbeln, bstnk
    from `dados-dev.raw.VBAK`    
),
w_vbkd as (
    select vbeln, zterm
    from dados-dev.raw_cimed_tech.VBKD d	
),
w_kna1 as (
    select name1, stcd1, kunnr
    from `dados-dev.raw.KNA1`
),
w_lif as (
    select distinct kunnr, lifnr
    from `dados-dev.raw_cimed_tech.LIFNR_CLIENTE_T`
)
SELECT
    Y.DOC_VENDA as pedido_sap, 
    Y.DT_OV as datapedido,   
    k.bstnk as pedido_portal, 
    T.vtext || ' dias' forma_pagamento, 
    k1.NAME1 as razao_social,
    k1.STCD1 as cnpj, 
    SUM(Y.VLR_PEDIDO) AS vlr_pedido,
    Y.COCKPIT as status,
	Y.cliente, lif.lifnr
FROM
  `dados-dev.visoes_YDBI_0006.YDBI006_ITEM_T` Y
INNER JOIN dados-dev.raw.VBAK V
    ON Y.MANDANTE = V.MANDT
    AND Y.DOC_VENDA = V.VBELN
    AND V.AUGRU <> 'ZBF'
    INNER JOIN (
        SELECT 
            MANDT, VBELN, VENDEDOR,EQUIPE_VENDAS, CONCAT(VENDEDOR,EQUIPE_VENDAS) AS CHAVE_VC, LEFT(VENDEDOR,1) AS STR_VENDEDOR
        FROM 
            dados-dev.raw.YDSD217) AS YD
    ON Y.MANDANTE = YD.MANDT
    AND Y.DOC_VENDA = YD.VBELN
    AND YD.STR_VENDEDOR <> 'H'
join 
    w_vbkd as d
    on d.vbeln = Y.DOC_VENDA
join 
    w_vbak as k 
    on d.vbeln = k.vbeln
join
	dados-dev.raw.TVZBT T
	on T.ZTERM = d.ZTERM
join 
    w_kna1 as k1
    on k1.kunnr = y.cliente
join 
    w_lif as lif 
    on lif.kunnr = y.cliente
GROUP BY 
    Y.DOC_VENDA, Y.DT_OV, k.bstnk, T.vtext, k1.NAME1, k1.STCD1, Y.COCKPIT, Y.cliente, lif.lifnr

    */