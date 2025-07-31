-- teste para substituir `dados-dev.visoes_cimed_tech.CV_A996_LOJAS_GERAL`
with 
w_konp as (
    select 
        mandt, knumh, kbetr, kpein
    from 
        dados-dev.raw.KONP
    where 
        loevm_ko <> 'X' 
), 
w_validade_curta as (
	SELECT
		PRODUTO, VALOR, SALDO, VKORG
	FROM 
		dados-dev.visoes_auxiliares_cimed_tech.CV_VIEW_VALIDADE_CURTA
),
w_material as (    
         select 
            codigo, codigobarras, DESCRICAO as descricao_material, principioativo, generico, lista, 
            codigo_ms, linha, status, c_controlado, produto_hierarquia, substring(hierarquia, 4, 3) as cod_hierarquia, hierarquia, 
        CASE
            WHEN GRP_MERCADORIA IN ('PA01', 'PA02', 'PA03') THEN 'MIP'
            WHEN GRP_MERCADORIA IN ('PA04', 'PA05', 'PA06') THEN 'RX'
            WHEN GRP_MERCADORIA IN ('PA07', 'PA08', 'PA09', 'PA23', 'PA24', 'PA25') THEN 'Controlados'
            WHEN GRP_MERCADORIA IN ('PA10', 'PA16', 'PA17') THEN 'Genéricos'
            WHEN GRP_MERCADORIA IN ('PA11') THEN 'Cosméticos'
            WHEN GRP_MERCADORIA IN ('PA12') THEN 'Correlatos'
            WHEN GRP_MERCADORIA IN ('PA13') THEN 'Suprimentos'	
            WHEN GRP_MERCADORIA IN ('PA14', 'PA18', 'PA19', 'PA20', 'PA21', 'PA22') THEN 'Hospitalar'
            WHEN GRP_MERCADORIA IN ('PA15') THEN 'Terceiros'
            ELSE GRP_MERCADORIA
	    END AS grp_mercadoria, fabricante, caixa_padrao, ipi,farm_popular, prod_marca, prod_classei, 
	    prod_fator, ncm, grpmercexterno, MENU_CATEGORIA, NUM_CATEGORIA
    from     
        dados-dev.raw_cimed_tech.CV_CADASTRO_MATERIAL_T
),
ultima_compra as (
    select 
        distinct k.kunnr, p.matnr,
        max(p.erdat) as erdat, 
        round( (sum(p.netwr) + sum(p.MWSBP)) / sum(p.KWMENG), 2) as vlr_unit, 
        sum(p.KWMENG) as ult_qde
    from 
        `dados-dev.raw.VBAK` as k 
    join 
        `dados-dev.raw.VBAP` as p
        on p.vbeln = k.vbeln    
    where 
        coalesce(p.KWMENG, 0) <> 0
    group by
        k.kunnr, p.matnr
    order by
        erdat
),
w_contexto AS (
    SELECT * FROM EXTERNAL_QUERY("projects/dados-dev/locations/us/connections/cimed-postgres-us", "SELECT c.id, pd.produto__c, c.name, C.tipo_de_destaque__c FROM SF.CAMPAIGN C join	SF.PRODUTOS_DESTAQUE__C PD 	on PD.campanha__c = C.id where c.type = 'Destaque' ")
),
w_estoque as (
	SELECT * FROM EXTERNAL_QUERY("projects/dados-dev/locations/us/connections/cimed-postgres-us", "SELECT matnr, werks, lgort, meses, disponivel, transito from ct.estoque;")
)
select 
    MAT.CODIGOBARRAS, MAT.DESCRICAO_MATERIAL, MAT.PRINCIPIOATIVO, MAT.GENERICO,
    MAT.CODIGO_MS, MAT.LINHA, MAT.STATUS, MAT.C_CONTROLADO, 
	
	-- ajusta num_categoria 
    MAT.MENU_CATEGORIA,	MAT.NUM_CATEGORIA,	
	MAT.GRP_MERCADORIA, MAT.FABRICANTE, MAT.CAIXA_PADRAO, MAT.IPI, MAT.FARM_POPULAR, MAT.PROD_MARCA, MAT.PROD_CLASSEI, 
	MAT.PROD_FATOR, MAT.NCM, MAT.GRPMERCEXTERNO,	
    P.COD_GAMA, P.DESCRICAO, P.VTWEG, P.BUKRS, P.WERKS,P.VKORG, P.FUNC_PAR, P.KUNNR, P.LIFNR, 
    substring(P.PRODUTO, 13, 6) AS PRODUTO, 0 AS PERC_COMIS,    
    round(SUM(V_ZFAT),2) AS V_ZFAT,
	round(SUM(V_ZSTA),2) AS V_ZSTA,
    round(SUM(ZPFA),2) AS ZPFA,
	round(SUM(ZPMC),2) AS ZPMC,
    round(SUM(VALOR_P),2) AS VALOR_P,
    round(SUM(VALOR_M),2) AS VALOR_M,
    round(SUM(VALOR_G),2) AS VALOR_G,
    round(SUM(VALOR_G1),2) AS VALOR_G1,
    round(SUM(VALOR_G2),2) AS VALOR_G2,

    SUM(QDE_P) AS QDE_P,
    SUM(QDE_M) AS QDE_M,
    SUM(QDE_G) AS QDE_G,
    SUM(QDE_G1) AS QDE_G1,
    SUM(QDE_G2) AS QDE_G2,

    SUM(COMIS_P) AS COMIS_P,
    SUM(COMIS_M) AS COMIS_M,
    SUM(COMIS_G) AS COMIS_G,
    SUM(COMIS_G1) AS COMIS_G1,
    SUM(COMIS_G2) AS COMIS_G2,
	'https://storage.googleapis.com/gc-conteudo/'||substring(MAT.hierarquia, 1, 3)|| '/'||substring(MAT.hierarquia, 4, 3)|| '/'||substring(MAT.hierarquia, 5, 3)||'/'||substring(MAT.hierarquia, 10, 3)||'/'||substring(P.produto,13,6)||'/'||substring(P.produto,13,6)||'-I.png' as IMAGEM,
	'https://storage.googleapis.com/gc-conteudo/'||substring(MAT.hierarquia, 1, 3)|| '/'||substring(MAT.hierarquia, 4, 3)|| '/'||substring(MAT.hierarquia, 5, 3)||'/'||substring(MAT.hierarquia, 10, 3)||'/'||substring(P.produto,13,6)||'/'||substring(P.produto,13,6)||'-B.pdf' as BULA,	
	'https://storage.googleapis.com/gc-conteudo/'||substring(MAT.hierarquia, 1, 3)|| '/'||substring(MAT.hierarquia, 4, 3)|| '/'||substring(MAT.hierarquia, 5, 3)||'/'||substring(MAT.hierarquia, 10, 3)||'/'||substring(P.produto,13,6)||'/'||substring(P.produto,13,6)||'-F.pdf' as FICHA,

	COALESCE(VC.VALOR, 0) AS VALOR_VC, 
	CASE 
		WHEN COALESCE(VC.VALOR, 0) = 0 THEN 0 
		ELSE 1  
	END AS QDE_VC, 
	COALESCE(VC.SALDO, 0) AS DISPONIVEL_VC,
	
    coalesce(ult.vlr_unit, 0) AS ULT_COMPRA_VALOR, coalesce(ult.ult_qde, 0) AS ULT_COMPRA_QDE, coalesce(ult.erdat, '') AS ULT_COMPRA_DATA,
	
    P.LGORT, p.MESES, cast(p.TRANSITO as integer) AS TRANSITO, cast(p.DISPONIVEL as integer) AS DISPONIVEL,
	
    coalesce(cont.tipo_de_destaque__c, '') as FILTRO_CONTEXTO, coalesce(cont.id, '') as NUM_FILTRO, 
    
    250 as PEDIDO_MINIMO, 
	
    'P' as TIPO_P, 'M' as TIPO_M, 'G' as TIPO_G, 
	
    -- se tem validade valor de VC, tem tag na api
    -- trazer VC de with
    CASE 
    	WHEN COALESCE(VC.VALOR, 0) = 0 THEN NULL
    	ELSE 'VC' 
    END AS TIPO_VC, 
	'A' as GRUPO_A, 'B' as GRUPO_B, 
	-- integração define o tipo de documento usado na integração da OV
	-- mockado para separar ZNOR, ZV12 e YTRI
    -- cabe uma versão da api com o tipo de documento
	'ZNOR' as INT_ZNOR, 'ZV12' as INT_ZV12
from 
    w_material as mat
join 
(
with w_loja as (
	with w_gama_produto as (
		select 
			cod_gama, matnr
		from 
			dados-dev.raw_cimed_tech.YDSD057 AS c 	
		where	
			ativo = 'S'
	),	
	w_LOJAS_LIFNR as (
		SELECT 
			DISTINCT *
		FROM
			dados-dev.raw_cimed_tech.LOJAS_LIFNR
	)
	SELECT 
		DISTINCT A.BUKRS, A.WERKS, A.COD_GAMA, a.CADEIRA, a.LIFNR, 
        a.vkorg, a.kunnr, a.descricao, a.vtweg, a.func_par, c.matnr
	FROM 
		w_LOJAS_LIFNR as a
	JOIN
		w_gama_produto as c 
		on c.cod_gama = a.cod_gama
),
w_zco2 as ( 
    WITH w_a996 as (
    select 
        mandt, knumh, vkorg, wty_v_parvw, matnr
    from 
        dados-dev.visoes_cimed_tech.W_A996
    --where 
        --kschl = 'ZCO2' 
        --AND (current_date between PARSE_DATE("%Y%m%d",datab) AND PARSE_DATE("%Y%m%d",datbi))
        --AND current_date >= PARSE_DATE("%Y%m%d",datab) AND  current_date <= PARSE_DATE("%Y%m%d",datbi)
    )
    SELECT
        ROW_NUMBER() OVER (PARTITION BY b.vkorg, b.wty_v_parvw, b.matnr order by b.vkorg, b.wty_v_parvw, b.matnr, k.kbetr )-3 AS faixa,
        b.matnr as produto,
        k.kstbm AS valor, ROUND((k.kbetr/10),2) AS perc_comis, 
        b.vkorg, b.wty_v_parvw as func_par
    FROM
        w_konp AS a
    INNER JOIN
        w_a996 AS b	  
        ON a.knumh = b.knumh
        AND a.mandt = b.mandt
    INNER JOIN
        dados-dev.raw_cimed_tech.KONM AS k	  
        ON k.mandt = b.mandt
        AND k.knumh = b.knumh     
),
w_zfat as (
    SELECT 
		b.kschl as tabela, 
		b.matnr as produto, 
		a.kbetr as valor, 
		a.kpein as qtdmin, 
	FROM 
        w_konp AS a 
	JOIN dados-dev.raw.A937 AS b
		ON a.knumh = b.knumh
	WHERE 
		(current_date between PARSE_DATE("%Y%m%d",b.datab) AND PARSE_DATE("%Y%m%d",b.datbi))
		AND b.kschl = 'ZFAT' 
),
w_zsta as (
    SELECT 
		b.kschl as tabela, b.vkorg, b.matnr as produto,  a.kbetr as valor, a.kpein as qtdmin,
		b.kschl as codigo
	FROM w_konp AS a 
	left JOIN dados-dev.raw_cimed_tech.A508 AS b
		ON a.knumh = b.knumh   	
	WHERE 
        (current_date between PARSE_DATE("%Y%m%d",b.datab) AND PARSE_DATE("%Y%m%d",b.datbi))
		and b.kschl = 'ZSTA'
),
w_zqco as (
	with w_konp as (
		select knumh 
		from dados-dev.raw.KONP
		where mandt = '500'
		and loevm_ko <> 'X' -- marcado para exclusao
	),
	w_konm as (
		select kbetr, kstbm, knumh
		from dados-dev.raw_cimed_tech.KONM
	),
	w_a709 as (
		SELECT 
			i.vkorg, b.matnr as produto, cast(c.kbetr/10 as integer) as faixa, cast(c.kstbm as integer) as qtdmin
		FROM 
			w_konp AS a
		JOIN dados-dev.raw_cimed_tech.A709 AS b
			ON a.knumh = b.knumh
		JOIN w_konm AS c
			ON a.knumh = c.knumh
		CROSS JOIN dados-dev.raw.YDSD218 AS i
		WHERE (current_date between PARSE_DATE("%Y%m%d",b.datab) AND PARSE_DATE("%Y%m%d",b.datbi))        
			And b.kschl in ('ZQCO')
	), 
	w_a508 as (
		SELECT 
			b.vkorg, b.matnr as produto, cast(c.kbetr/10 as integer) as faixa, cast(c.kstbm as integer) as qtdmin
		FROM 
			w_konp AS a
		JOIN dados-dev.raw_cimed_tech.A508 AS b
			ON a.knumh = b.knumh
		JOIN w_konm AS c
			ON a.knumh = c.knumh
		JOIN dados-dev.raw.YDSD218 AS i
			ON i.vkorg = b.vkorg
		WHERE 
			b.kschl in ('ZQCO')
			AND (current_date between PARSE_DATE("%Y%m%d",b.datab) AND PARSE_DATE("%Y%m%d",b.datbi))
	)
	select 
		VKORG, PRODUTO, FAIXA, QTDMIN 
	FROM 
		w_a508										  
	union all 													  
	(
	select *
	from w_a709
	except distinct				 
		select 
			*																		  
		FROM 
			w_a508
	)
),
w_zpfa as (
    -- precisa da UF DO cliente para joinda lista
-- "_SYS_BIC"."CimedTech/CV_A954_955_ZPFA_ZPMC" ZPFA
select
	q.tabela, q.produto, q.valor, q.lista, j.SHIPFROM, Y218.VKORG
from 	
	(	
    SELECT 
		b.kschl as tabela, b.matnr as produto, 
		a.kbetr as valor, b.PLTYP as LISTA
	FROM 
		dados-dev.raw.KONP AS a 
	left JOIN dados-dev.raw_cimed_tech.A954 AS b
		ON a.knumh = b.knumh
	WHERE 
		a.loevm_ko <> 'X' -- marcado para exclusão
		AND (current_date between PARSE_DATE("%Y%m%d",b.datab) AND PARSE_DATE("%Y%m%d",b.datbi))
		and a.mandt = '500'  
		and b.kschl in ('ZPFA')
	) q
	join	
		dados-dev.raw_cimed_tech.J_1BTXIC1 J
		ON cast(J.RATE as string)  = q.LISTA
	JOIN	
	(
		SELECT SHIPFROM, Min(VALIDFROM) AS VALIDFROM
		FROM dados-dev.raw_cimed_tech.J_1BTXIC1
		WHERE SHIPFROM=SHIPTO AND specf_rate = 0
		GROUP BY SHIPFROM	
	) U	
	ON U.SHIPFROM = J.SHIPFROM
	AND U.VALIDFROM = J.VALIDFROM	
	join
		dados-dev.raw.YDSD218 Y218
		ON Y218.UF = J.SHIPFROM
	WHERE
		(PARSE_DATE("%Y%m%d",cast((99999999 - cast(J.validfrom as INTEGER)) as string)) <= current_date)		
		AND J.LAND1 = 'BR'
		AND J.SHIPFROM = J.SHIPTO 
),
w_zpmc as (
	-- CV_A954_955_ZPFA_ZPMC
    select
		q.tabela, q.produto, q.valor, q.lista, j.SHIPFROM, Y218.VKORG
	from 
		(	
		SELECT 
			b.kschl as tabela, b.matnr as produto,
			a.kbetr as valor, b.PLTYP as LISTA
		FROM 
			w_konp AS a 
		left JOIN dados-dev.raw_cimed_tech.A955 AS b
			ON a.knumh = b.knumh   
		WHERE
            (current_date between PARSE_DATE("%Y%m%d",b.datab) AND PARSE_DATE("%Y%m%d",b.datbi))
			and b.kschl in ('ZPMC')	
		) q
	join	
		dados-dev.raw_cimed_tech.J_1BTXIC1 J
		ON cast(J.RATE as string)  = q.LISTA
	JOIN	
		(
			SELECT SHIPFROM, Min(VALIDFROM) AS VALIDFROM
			FROM dados-dev.raw_cimed_tech.J_1BTXIC1
			WHERE SHIPFROM=SHIPTO AND specf_rate = 0
			GROUP BY SHIPFROM	
		) U	
		ON U.SHIPFROM = J.SHIPFROM
		AND U.VALIDFROM = J.VALIDFROM	
	join
		dados-dev.raw.YDSD218 Y218
		ON Y218.UF = J.SHIPFROM
	WHERE
	-- (to_date(to_nvarchar(99999999 - J.validfrom)) <= current_date)
	(PARSE_DATE("%Y%m%d",cast((99999999 - cast(J.validfrom as INTEGER)) as string)) <= current_date)		
	AND J.LAND1 = 'BR'
	AND J.SHIPFROM = J.SHIPTO
),
w_ydsd044 as (
    select distinct werks, lgort, meses
    from `dados-dev.raw.YDSD044`
)
select  
    loja.cod_gama, loja.descricao, loja.vtweg, loja.bukrs, loja.werks, 
    loja.vkorg, loja.func_par, loja.kunnr, loja.lifnr,        
    zco2.produto, zco2.faixa, 0 as perc_comis, 
    zfat.valor as V_ZFAT, zsta.valor as V_ZSTA, 
    zpfa.valor as ZPFA, zpmc.valor as ZPMC,
    case when zco2.faixa = 2 then round(((zfat.valor / (1 - zco2.valor/100)) + zsta.valor),2) else 0 end as VALOR_P,
    case when zco2.faixa = 1 then round(((zfat.valor / (1 - zco2.valor/100)) + zsta.valor),2) else 0 end as VALOR_M,	
    case when zco2.faixa = 0 then round(((zfat.valor / (1 - zco2.valor/100)) + zsta.valor),2) else 0 end as VALOR_G,	
    case when zco2.faixa = -1 then round(((zfat.valor / (1 - zco2.valor/100)) + zsta.valor),2) else 0 end as VALOR_G1,
    case when zco2.faixa = -2 then round(((zfat.valor / (1 - zco2.valor/100)) + zsta.valor),2) else 0 end as VALOR_G2,	

    case when zco2.faixa = 2 then COALESCE(zqco.QTDMIN, 1) else 0 end as QDE_P,		
    case when zco2.faixa = 1 then COALESCE(zqco.QTDMIN, 1) else 0 end as QDE_M, 
    case when zco2.faixa = 0 then COALESCE(zqco.QTDMIN, 1) else 0 end as QDE_G, 
    case when zco2.faixa = -1 then COALESCE(zqco.QTDMIN, 1) else 0 end as QDE_G1, 
    case when zco2.faixa = -2 then COALESCE(zqco.QTDMIN, 1) else 0 end as QDE_G2, 		

    case when zco2.faixa = 2 then zco2.perc_comis else 0 end as COMIS_P,
    case when zco2.faixa = 1 then zco2.perc_comis else 0 end as COMIS_M,	
    case when zco2.faixa = 0 then zco2.perc_comis else 0 end as COMIS_G,	
    case when zco2.faixa = -1 then zco2.perc_comis else 0 end as COMIS_G1,	
    case when zco2.faixa = -2 then zco2.perc_comis else 0 end as COMIS_G2, 
	est.disponivel, est.transito, y44.meses, y44.lgort
from 
    w_loja as loja
join 
    w_zco2 as zco2 
    on zco2.vkorg = loja.vkorg 
    and zco2.func_par = loja.func_par
    and zco2.produto = loja.matnr
join    
    w_zfat as zfat
    on zfat.produto = zco2.produto
left join 
    w_zsta as zsta
    on zsta.vkorg = zco2.vkorg 
    and zsta.produto = zco2.produto
left join  
    w_zqco as zqco
    on zqco.vkorg = zco2.vkorg
    and zqco.produto  = zco2.produto
    and zqco.faixa-1 = zco2.faixa
left join  
    w_zpfa as zpfa 
    on zpfa.produto = zco2.produto
    and zpfa.vkorg = zco2.vkorg
left join  
    w_zpmc as zpmc
    on zpmc.produto = zco2.produto
    and zpmc.vkorg = zco2.vkorg
join 
    w_ydsd044 as y44 
    on y44.werks = loja.werks
left join 
	w_estoque as est
	on est.werks = y44.werks
    and est.lgort = y44.lgort
	and est.matnr = loja.matnr	
) P
    on mat.codigo = P.produto
left join 
    ultima_compra as ult
    on ult.kunnr = P.kunnr
    and ult.matnr = P.produto
left join w_contexto  as cont
    on cont.produto__c = P.produto
left join
	w_validade_curta as vc
	on vc.vkorg = p.vkorg
	AND vc.produto = p.produto
group by	
    mat.codigo, mat.codigobarras, mat.descricao_material, mat.principioativo, mat.generico,
    mat.codigo_ms, mat.linha, mat.status, MAT.C_CONTROLADO, MAT.PRODUTO_HIERARQUIA, MAT.cod_hierarquia, 
	MAT.GRP_MERCADORIA, mat.fabricante, mat.caixa_padrao, mat.ipi, mat.farm_popular, mat.prod_marca, mat.prod_classei, 
	mat.prod_fator, mat.ncm, mat.grpmercexterno,MAT.hierarquia,	
    P.cod_gama, P.descricao, P.vtweg, P.bukrs, P.werks,P.vkorg, P.func_par, P.kunnr, P.lifnr, P.produto,
    ult.vlr_unit, ult.ult_qde, ult.erdat, MAT.MENU_CATEGORIA, MAT.NUM_CATEGORIA,
    cont.tipo_de_destaque__c, cont.id, 
    vc.valor, vc.saldo, 
    P.LGORT, p.MESES, p.TRANSITO, p.DISPONIVEL