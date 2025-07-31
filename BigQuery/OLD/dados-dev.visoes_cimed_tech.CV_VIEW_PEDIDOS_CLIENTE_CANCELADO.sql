CREATE TABLE dados-dev.raw_cimed_tech.CV_VIEW_PEDIDOS_CLIENTE_CANCELADO_T AS 
	(
	select * from `dados-dev.visoes_cimed_tech.CV_VIEW_PEDIDOS_CLIENTE_CANCELADO`
	)



with w_vbak as (
    select MANDT, vbeln, BUKRS_VF, LIFSK, kunnr, VKORG, ERDAT
    from `dados-dev.raw.VBAK`
    where LIFSK IN ('Y5', 'Y6', 'Y8', 'YA', 'ZB', 'YP')
), 
w_vbap as (
    select mandt, vbeln, ABGRU
    from `dados-dev.raw.VBAP`
    where WERKS IN ( SELECT WERKS FROM `dados-dev.raw.YDSD051` )    
    
), 
w_vbuk as (
    select mandt, vbeln
    from `dados-dev.raw.VBUK`
    where LFSTK = 'A' --Sem Remessa
)

-- cancelamento comercial
SELECT
	DISTINCT A.VBELN AS pedido_sap, A.ERDAT as DATA, T.VTEXT as motivo
FROM 
	w_vbak AS A
JOIN w_vbap AS B
	ON A.MANDT = B.MANDT
	AND a.VBELN = B.VBELN
LEFT JOIN w_vbuk AS E
	ON    A.MANDT   = E.MANDT
	AND   A.VBELN   = E.VBELN 
JOIN `dados-dev.raw_cimed_tech.TVLST` AS T
	ON   A.MANDT   = T.MANDT
	AND  A.LIFSK   = T.LIFSP
left join
	`dados-dev.raw.YDSD218` AS I
	on I.BUKRS = A.BUKRS_VF
	and I.VKORG = A.VKORG
WHERE 
	--A.LIFSK IN ('Y5', 'Y6', 'Y8', 'YA', 'ZB', 'YP') /*INCLUSÃO BRUNO EM 09/02/2017 */  
	--AND   
    --E.LFSTK = 'A' --Sem Remessa
	--AND   B.WERKS IN ( SELECT WERKS FROM `dados-dev.raw.YDSD051` )
	--AND B.ABGRU IN ( SELECT ABGRU FROM `dados-dev.raw.YDSD050` WHERE ITENS_CANC = 'X' )
	-- O select abaixo é feito pra GARANTIR QUE NENHUM ITEM TENHA RECUSA FINANCEIRA 
	-- DEIXAR ASSIM
	A.VBELN NOT IN 
        (
            SELECT VBELN 
            FROM w_vbap 
            WHERE ABGRU IN ( SELECT LOW FROM `dados-dev.raw.TVARVC`WHERE NAME = 'YDSD_MP_ORDER_STATUS_REC_FINAN'AND LOW <> '')
        )  
union all 
-- 
-- recusado financeiro
--
SELECT
	DISTINCT A.VBELN AS pedido_sap, A.ERDAT as DATA,
	--T.BEZEI as motivo
	-- motivo resumido para o texto caber na TAG do front
	CASE 
        WHEN T.BEZEI = 'Limite Excedido'               then 'Lim Exced'
        WHEN T.BEZEI = 'Duplicata Vencida'             then 'Dup Venc.'
        WHEN T.BEZEI = 'Restrição Serasa'              then 'Serasa'
        WHEN T.BEZEI = 'Zpre cliente < do sistema'     then 'Zpre Cli'
        WHEN T.BEZEI = 'Lote validade curta'           then 'Lote VC'
        WHEN T.BEZEI = 'Material sem Estoque'          then 'S/Estoque'
        WHEN T.BEZEI = 'Atendimento Parcial'           then 'A Parcial'
        WHEN T.BEZEI = 'Atualizar Cadastro'            then 'Cad desat'
        WHEN T.BEZEI = 'Não aprovado pelo responsavel' then 'Não Aprov'
        WHEN T.BEZEI = 'Valor Preço Mínimo'            then 'Preço min'
        WHEN T.BEZEI = 'Cancel Administração'          then 'Canc Adm'
        WHEN T.BEZEI = 'Valor Mínimo Ordem'            then 'Pd Minimo'
        WHEN T.BEZEI = 'Cancelamento EDI'              then 'Cand EDI'
        WHEN T.BEZEI = 'Cancel Cliente'                then 'Canc Cli'
        WHEN T.BEZEI = 'Cadast Desatualizado'          then 'Cad desat'
		ELSE '' 
	end as motivo
FROM 
	w_vbak AS A
JOIN w_vbap AS B
	ON    A.MANDT = B.MANDT
	AND   A.VBELN = B.VBELN
LEFT JOIN w_vbuk AS E
	ON    A.MANDT   = E.MANDT
	AND   A.VBELN   = E.VBELN 
JOIN `dados-dev.raw.TVAGT`AS T
	ON   B.MANDT   = T.MANDT
	AND  B.ABGRU   = T.ABGRU
	AND  T.SPRAS = 'P'
join
	`dados-dev.raw.YDSD218`	AS I
	on I.BUKRS = A.BUKRS_VF
	and I.VKORG = A.VKORG
WHERE 
	--A.LIFSK NOT IN ('Y5', 'Y6', 'Y 8', 'YA', 'ZB', 'YP') /*INCLUSÃO BRUNO EM 09/02/2017 */  
	--AND  
    --E.LFSTK = 'A' --Sem Remessa
	--AND   B.WERKS IN ( SELECT WERKS FROM `dados-dev.raw.YDSD051` )
	-- O select abaixo é feito pra GARANTIR QUE NENHUM ITEM TENHA RECUSA FINANCEIRA 
	-- DEIXAR ASSIM
    A.VBELN IN 
        ( 
            SELECT VBELN 
            FROM w_vbap
            WHERE ABGRU IN ( SELECT LOW FROM `dados-dev.raw.TVARVC` WHERE NAME = 'YDSD_MP_ORDER_STATUS_REC_FINAN' AND LOW <> '')
        ) 

--where pedido = '0004783761'