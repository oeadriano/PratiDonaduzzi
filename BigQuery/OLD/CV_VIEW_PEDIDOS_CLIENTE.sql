-- CV_VIEW_PEDIDOS_CLIENTE
--select count(*) from CV_DASH_MV_VISAO_T
--select count(*) from dados-dev.raw_cimed_tech.VBKD d -- 23.285.078
--select count(*) from dados-dev.raw.VBAK k -- 4.958.254
--select count(*) from dados-dev.raw.TVZBT T    -- 983
--select count(*) from dados-dev.raw_cimed_tech.LIFNR_CLIENTE_T LIF    199.363
--select count(*) from dados-dev.raw.KNA1 k1    -- 119718

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
    SUM(Y.VLR_PEDIDO) AS VLR_PEDIDO,
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


/*
select
	distinct
		k.vbeln as pedido_sap,
		k.erdat as datapedido,
		k.BSTNK as pedido_portal, 
		T.vtext || ' dias' forma_pagamento, 
		k1.NAME1 as razao_social,
		k1.STCD1 as cnpj, 
		k.NETWR as valor,
		'Faturado' as status,
		-- status do pedido deve vir de outra
		-- tabela materializada
		k.kunnr as cliente, lif.lifnr
from
	dados-dev.raw.VBAK k
join 
	dados-dev.raw_cimed_tech.VBKD d
	on d.vbeln = k.vbeln
join
	dados-dev.raw.TVZBT T
	on T.ZTERM = d.ZTERM
-- join com status de pedido	
join
	dados-dev.raw_cimed_tech.LIFNR_CLIENTE_T LIF
	ON LIF.KUNNR = k.KUNNR
join
	dados-dev.raw.KNA1 k1
	on k1.kunnr = k.kunnr
	
select 
	DOC_VENDA as pedido_sap, k.erdat as datapedido, 
	k.vbeln as pedido_portal, 'vbak' as forma_pagamento,
	'vbak' as razao_social, 	
from 
	YDBI006_ITEM_T 	
join 
	dados-dev.raw.VBAK k
	
*/