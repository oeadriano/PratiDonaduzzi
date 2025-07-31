--CV_A996_VKORG_FUNC_MATERIAL_IP_COM_LOJAS_OFF
SELECT
	P.produto, P.perc_comis, ZPFA.VALOR as zpfa, ZPMC.VALOR as zpmc, P.v_zfat, P.v_zsta,
	sum(P.valor_p) as valor_p, sum(P.valor_m) as valor_m,  sum(P.valor_g) as valor_g, 
	sum(P.valor_g1) as valor_g1, sum(P.valor_G2) as valor_g2,
	
	sum(P.QDE_P) as qde_p, sum(P.qde_m) as qde_m, sum(P.qde_g) as qde_g,
	sum(P.QDE_G1) as qde_g1, sum(P.qde_g2) as qde_g2,
	
	sum(P.COMIS_P) as comis_p, sum(P.COMIS_m) as comis_m, sum(P.COMIS_g) as comis_g,	
	sum(P.COMIS_G1) as comis_g1, sum(P.COMIS_G2) as comis_g2,
	
	COALESCE(VC.VALOR, 0) AS valor_vc, 
	CASE
		WHEN COALESCE(VC.VALOR, 0) = 0 THEN 0
		ELSE 1 
	END AS qde_vc, 
	COALESCE(VC.SALDO, 0) AS disponivel_vc, 
	P.cod_gama,
	P.descricao, 
	P.vtweg, 
	P.bukrs, 
	P.werks, 
	P.func_par,
	P.vkorg, 
	coalesce(ult.vlr_unit, 0) as ult_compra_valor, 
	CAST(coalesce(ult.ult_qde,0) AS INTEGER) as ult_compra_qde, 
	coalesce(ult.erdat, '') as ult_compra_data,
    M.codigobarras, 
    M.DESCRICAO as descricao_material, 
    M.principioativo,
    M.generico, 
    M.lista, 
    M.codigo_ms,
	M.linha, 
	M.status, 
	M.c_controlado, 
	CASE
		WHEN M.GRP_MERCADORIA IN ('PA01', 'PA02', 'PA03') THEN 'MIP'
		WHEN M.GRP_MERCADORIA IN ('PA04', 'PA05', 'PA06') THEN 'RX'
		WHEN M.GRP_MERCADORIA IN ('PA07', 'PA08', 'PA09', 'PA23', 'PA24', 'PA25') THEN 'Controlados'
		WHEN M.GRP_MERCADORIA IN ('PA10', 'PA16', 'PA17') THEN 'Genéricos'
		WHEN M.GRP_MERCADORIA IN ('PA11') THEN 'Cosméticos'
		WHEN M.GRP_MERCADORIA IN ('PA12') THEN 'Correlatos'
		WHEN M.GRP_MERCADORIA IN ('PA13') THEN 'Suprimentos'	
		WHEN M.GRP_MERCADORIA IN ('PA14', 'PA18', 'PA19', 'PA20', 'PA21', 'PA22') THEN 'Hospitalar'
		WHEN M.GRP_MERCADORIA IN ('PA15') THEN 'Terceiros'
		ELSE M.GRP_MERCADORIA
	END AS grp_mercadoria,	
	M.fabricante, 
	M.caixa_padrao, 
	M.ipi,
	M.farm_popular, 
	M.prod_marca, 
	M.prod_classei, 
	M.prod_fator, 
	M.ncm, 
	M.grpmercexterno, 
    '' as lgort, --E.lgort, 
	'' as meses, --E.meses, 
	0 as transtio, --E.transito, 
	0 as disponivel, --E.disponivel, 
	g.menu_categoria, 
	g.filtro_contexto, 
	'https://storage.googleapis.com/gc-conteudo/'||substring(M.hierarquia, 1, 3)|| '/'||substring(M.hierarquia, 4, 3)|| '/'||substring(M.hierarquia, 5, 3)||'/'||substring(M.hierarquia, 10, 3)||'/'||P.produto||'/'||P.produto||'-I.png' as imagem,
	'https://storage.googleapis.com/gc-conteudo/'||substring(M.hierarquia, 1, 3)|| '/'||substring(M.hierarquia, 4, 3)|| '/'||substring(M.hierarquia, 5, 3)||'/'||substring(M.hierarquia, 10, 3)||'/'||P.produto||'/'||P.produto||'-B.pdf' as bula,	
	'https://storage.googleapis.com/gc-conteudo/'||substring(M.hierarquia, 1, 3)|| '/'||substring(M.hierarquia, 4, 3)|| '/'||substring(M.hierarquia, 5, 3)||'/'||substring(M.hierarquia, 10, 3)||'/'||P.produto||'/'||P.produto||'-F.pdf' as ficha,
	g.num_filtro, 
	g.num_categoria, 
	250 AS pedido_minimo, 
    'P' as tipo_p, 
    'M' as tipo_m, 
    'G' as tipo_g, 
    CASE 
    	WHEN COALESCE(VC.VALOR, 0) = 0 THEN NULL
    	ELSE 'VC' 
    END AS tipo_vc, 
	'A' as grupo_a, 
	'B' as grupo_b, 
	-- integração define o tipo de documento usado na integração da OV
	-- mockado para separar ZNOR, ZV12 e YTRI
    -- cabe uma versão da api com o tipo de documento
	'ZNOR' as int_znor, 
	'ZV12' as int_zv12, 
    P.KUNNR, P.LIFNR
FROM 
	(
	SELECT
		PMG.produto, 
		PMG.perc_comis,
		ZFAT.VALOR AS V_ZFAT, ZSTA.VALOR AS V_ZSTA, 		
		case when PMG.faixa = 2 then round(((ZFAT.VALOR / (1 - PMG.valor/100)) + ZSTA.VALOR),2) else 0 end as VALOR_P,
		case when PMG.faixa = 1 then round(((ZFAT.VALOR / (1 - PMG.valor/100)) + ZSTA.VALOR),2) else 0 end as VALOR_M,	
		case when PMG.faixa = 0 then round(((ZFAT.VALOR / (1 - PMG.valor/100)) + ZSTA.VALOR),2) else 0 end as VALOR_G,	
		case when PMG.faixa = -1 then round(((ZFAT.VALOR / (1 - PMG.valor/100)) + ZSTA.VALOR),2) else 0 end as VALOR_G1,
		case when PMG.faixa = -2 then round(((ZFAT.VALOR / (1 - PMG.valor/100)) + ZSTA.VALOR),2) else 0 end as VALOR_G2,	
		
		case when PMG.faixa = 2 then COALESCE(ZQ.QTDMIN, 1) else 0 end as QDE_P,		
		case when PMG.faixa = 1 then COALESCE(ZQ.QTDMIN, 1) else 0 end as QDE_M, 
		case when PMG.faixa = 0 then COALESCE(ZQ.QTDMIN, 1) else 0 end as QDE_G, 
		case when PMG.faixa = -1 then COALESCE(ZQ.QTDMIN, 1) else 0 end as QDE_G1, 
		case when PMG.faixa = -2 then COALESCE(ZQ.QTDMIN, 1) else 0 end as QDE_G2, 		
  
		case when PMG.faixa = 2 then PMG.perc_comis else 0 end as COMIS_P,
		case when PMG.faixa = 1 then PMG.perc_comis else 0 end as COMIS_M,	
		case when PMG.faixa = 0 then PMG.perc_comis else 0 end as COMIS_G,	
		case when PMG.faixa = -1 then PMG.perc_comis else 0 end as COMIS_G1,	
		case when PMG.faixa = -2 then PMG.perc_comis else 0 end as COMIS_G2,			
  
		PMG.COD_GAMA, PMG.DESCRICAO, PMG.VTWEG, PMG.BUKRS, 															 
		PMG.WERKS, PMG.VKORG, PMG.FUNC_PAR, 
		KNA1.REGIO, PMG.kunnr, PMG.lifnr
	FROM
		(	
		SELECT
			ROW_NUMBER() OVER
			(PARTITION BY b.matnr
				order by b.matnr, k.kstbm)-3 as faixa, 				
			cast(cast(b.matnr as integer) as string) as produto,     
		    k.kstbm as valor , round((k.kbetr/10),2) as perc_comis,
		    LJ.*
		FROM 
			dados-dev.raw.KONP AS a 
		INNER JOIN 
			dados-dev.raw_cimed_tech.A996 AS b
			ON a.knumh = b.knumh
			AND a.mandt = b.mandt
		INNER JOIN 
			dados-dev.raw_cimed_tech.KONM as k
			on k.mandt = b.mandt
			AND k.knumh = b.knumh
		JOIN
		(
			select 
				g.cod_gama, l.descricao, l.vtweg, 
				G.bukrs, g.werks, y218.vkorg, y94.func_par, lf.kunnr, lf.lifnr
			from( 
				-- "_SYS_BIC"."VISAO/CV_YDSD_GAMA_AUTORIZACOES" G
				SELECT 
					DISTINCT
						A.BUKRS, A.WERKS, A.COD_GAMA, cast(T3.LIFN2 as string) AS LIFNR, I.ID
				FROM 
					dados-dev.raw_cimed_tech.YDSD225 AS a
				JOIN 
					dados-dev.raw_cimed_tech.YDSD056 AS b
					ON a.cod_gama = b.cod_gama
				left JOIN 
					dados-dev.raw.YDSD218 AS i
					ON i.werks = a.werks
				left JOIN
					dados-dev.raw.WYT3 T3
					ON T3.lifnr = A.lifnr					
					AND T3.ekorg = '1000'
					AND T3.parvw = 'Y1'
					AND T3.defpa = 'X'	
				WHERE 
					a.ativo = 'S' 
					AND b.ativo = 'S'
					ANd coalesce(T3.LIFN2, '') <> ''
					and a.werks <> '1100' ) AS G
			JOIN
				dados-dev.raw.YDSD218 y218
				on y218.werks = G.werks		
			JOIN 
				dados-dev.raw_cimed_tech.LIFNR_CLIENTE_T AS LF
				ON LF.LIFNR = G.LIFNR	
				AND LF.VKORG = y218.VKORG
			JOIN 
				dados-dev.raw.KNVV K
				ON K.kunnr = lf.kunnr 
				and k.vwerk = G.werks
			JOIN
				dados-dev.raw_cimed_tech.YDSD056 L
                
				ON L.COD_GAMA = G.COD_GAMA
				AND L.VTWEG = K.VTWEG		
			JOIN
				dados-dev.raw.YDSD094 Y94
				ON LF.LIFNR = Y94.repr	
            WHERE 
                L.ativo = 'S'
		) LJ
		ON LJ.vkorg = b.vkorg
			AND LJ.FUNC_PAR =  b.WTY_V_PARVW 		
		WHERE 
			a.loevm_ko <> 'X' -- marcado para exclusão
			-- AND (current_date between b.datab AND b.datbi) -- mudei
			AND (current_date between PARSE_DATE("%Y%m%d",b.datab) AND PARSE_DATE("%Y%m%d",b.datbi))
			--and k.kstbm > 2 -- gambiarra para mostrar somente 3 faixas
		ORDER BY
			b.matnr, k.kstbm
		) PMG		
	JOIN (
	--"_SYS_BIC"."VISAO/CV_CUSTO_ZFAT" ZFAT
	SELECT 
	cast(a.mandt as integer) as MANDT, 
	b.kschl as tabela, 
	'' as escala, 
	'' as uf, 
	'1005' as vkorg, 
	'' as canal, 
	'' as cliente, 
	'' as rede, 
	b.datab as data, 
	b.datbi as validade, 
	cast(cast(b.matnr as integer) as string) as produto, 
	a.kbetr as valor, 
	a.kpein as qtdmin, 
	b.kschl as codigo, 
    '' as CLASSE, 
	99 as id_distribuidora
FROM dados-dev.raw.KONP AS a 
left JOIN dados-dev.raw.A937 AS b
	ON a.knumh = b.knumh
WHERE 
	a.loevm_ko <> 'X' -- marcado para exclusão
	AND (current_date between PARSE_DATE("%Y%m%d",b.datab) AND PARSE_DATE("%Y%m%d",b.datbi))
	and a.mandt = '500'
	AND b.kschl = 'ZFAT' ) as ZFAT
		ON ZFAT.PRODUTO = PMG.PRODUTO
	
	LEFT JOIN ( 
	--"_SYS_BIC"."VISAO/CV_A508_VKORG_MATERIAL" ZSTA
	SELECT 
	a.mandt, b.kschl as tabela,  '' as escala, '' as uf, b.vkorg, '' as canal,
	'' as cliente, '' as rede, b.datab as data, b.datbi as validade,	
	cast(cast(b.matnr as integer) as string) as produto,  a.kbetr as valor, a.kpein as qtdmin,
    b.kschl as codigo, i.id AS id_distribuidora
FROM dados-dev.raw.KONP AS a 
left JOIN dados-dev.raw_cimed_tech.A508 AS b
	ON a.knumh = b.knumh   
left JOIN 
	dados-dev.raw.YDSD218 AS i
	ON i.vkorg = b.vkorg	
WHERE 
	a.loevm_ko <> 'X' -- marcado para exclusão
	AND (current_date between PARSE_DATE("%Y%m%d",b.datab) AND PARSE_DATE("%Y%m%d",b.datbi))
	and a.mandt = '500'  
	And b.kschl in ('ZSTA', 'ZPTL')
ORDER BY
	b.kschl, b.vkorg, data, validade, produto ) AS ZSTA
		ON ZSTA.VKORG = PMG.VKORG
		AND ZSTA.PRODUTO = PMG.PRODUTO		
	LEFT JOIN ( 
	--"_SYS_BIC"."VISAO/CV_A508_A709_ZQCO" ZQ
	select 
		VKORG, PRODUTO, FAIXA, QTDMIN 
	FROM 
	   (select VKORG, PRODUTO, FAIXA, QTDMIN 
		from ( SELECT i.vkorg, 
                      cast(cast(b.matnr as integer) as string) as produto,
                      cast(c.kbetr/10 as integer) as faixa, cast(c.kstbm as integer) as qtdmin
                 FROM dados-dev.raw.KONP AS a
                 JOIN dados-dev.raw_cimed_tech.A709 AS b
                   ON a.knumh = b.knumh
                 JOIN dados-dev.raw_cimed_tech.KONM AS c
                   ON a.knumh = c.knumh
                 CROSS JOIN	dados-dev.raw.YDSD218 AS i
                 WHERE a.loevm_ko <> 'X' -- marcado para exclusão
                   AND (current_date between PARSE_DATE("%Y%m%d",b.datab) AND PARSE_DATE("%Y%m%d",b.datbi))
                   and a.mandt = '500'
                   And b.kschl in ('ZQCO')
                 ORDER BY vkorg, produto, faixa
             )
		where
			VKORG||PRODUTO not in 
			(SELECT DISTINCT b.vkorg || cast(cast(b.matnr as integer) as string) as produto
                 FROM dados-dev.raw.KONP AS a
                 JOIN dados-dev.raw_cimed_tech.A508 AS b
                   ON a.knumh = b.knumh
                 JOIN dados-dev.raw.YDSD218 AS i
                   ON i.vkorg = b.vkorg
                 WHERE a.loevm_ko <> 'X' -- marcado para exclusão
                   AND (current_date between PARSE_DATE("%Y%m%d",b.datab) AND PARSE_DATE("%Y%m%d",b.datbi))
                   and a.mandt = '500'
                   And b.kschl in ('ZQCO') )
		union all
		-- todos os produtos da chave vkorg
		select 
			VKORG, PRODUTO, FAIXA, QTDMIN 
		from ( SELECT b.vkorg, 
                      cast(cast(b.matnr as integer) as string) as produto,
                      cast(c.kbetr/10 as integer) as faixa, cast(c.kstbm as integer) as qtdmin
                 FROM dados-dev.raw.KONP AS a
                 JOIN dados-dev.raw_cimed_tech.A508 AS b
                   ON a.knumh = b.knumh
                 JOIN dados-dev.raw_cimed_tech.KONM AS c
                   ON a.knumh = c.knumh
                 JOIN dados-dev.raw.YDSD218 AS i
                   ON i.vkorg = b.vkorg
                 WHERE a.loevm_ko <> 'X' -- marcado para exclusão
                   AND (current_date between PARSE_DATE("%Y%m%d",b.datab) AND PARSE_DATE("%Y%m%d",b.datbi))
                   and a.mandt = '500'
                   And b.kschl in ('ZQCO')
                 ORDER BY vkorg, produto, faixa 
		      )

		) 
--where produto = '100069'
	ORDER BY VKORG, PRODUTO, FAIXA ) as ZQ
		ON ZQ.VKORG = PMG.VKORG
		AND ZQ.PRODUTO = PMG.PRODUTO
		AND (ZQ.FAIXA)-1 = PMG.FAIXA	
	JOIN
		dados-dev.raw.KNA1 KNA1
		on KNA1.kunnr = PMG.kunnr
	where 
		ZSTA.tabela  = 'ZSTA'	
--		and PMG.FAIXA in (0, 1, 2)		
--		and PMG.PRODUTO	in ('100069', '100078')
	) P
JOIN 
	dados-dev.raw_cimed_tech.CV_CADASTRO_MATERIAL_T M
	ON SUBSTRING(M.CODIGO, 13, 6) = P.PRODUTO
--LEFT JOIN 
--	dados-dev.visoes_auxiliares_cimed_tech.CV_YDSD_ATUALIZAR_ESTOQUE E
--  ON E.MATNR = P.PRODUTO
--		AND E.WERKS = P.WERKS	
LEFT JOIN
	(
		select 
			distinct k.kunnr, substring(p.matnr, 13, 6) as matnr,
			max(p.erdat) as erdat, 
			round( (sum(p.netwr) + sum(p.MWSBP)) / sum(p.KWMENG), 2) as vlr_unit, 
			sum(p.KWMENG) as ult_qde
		from 
			dados-dev.raw.VBAK k
		join 
			dados-dev.raw.VBAP p
			on p.vbeln = k.vbeln
			and p.KWMENG <> 0
		-- where
--			k.kunnr = :IP_CLIENTE
			-- k.kunnr = '0001009136'
		group by
			k.kunnr, p.matnr
		order by
			erdat
	) ult
	ON ult.matnr = P.produto			
join
	(
	select 
		p.matnr, p.num_filtro, p.num_categoria,
		case
			when p.num_categoria = 1 then 'HIGIENE E BELEZA'
			when p.num_categoria = 2 then 'DERMOCOSMETICOS'		
			when p.num_categoria = 3 then 'NUTRIÇÃO'			
			when p.num_categoria = 4 then 'VITAMINAS'
			when p.num_categoria = 5 then 'EQUIVALENTES'		
			when p.num_categoria = 6 then 'GENERICOS'
			when p.num_categoria = 7 then 'GENERICOS OTC'
			when p.num_categoria = 8 then 'OTC'
		END AS MENU_CATEGORIA, 
		case
			when p.num_filtro = 1 then 'PROMOCOES'
			when p.num_filtro = 2 then 'NOVIDADES'		
			when p.num_filtro = 3 then 'LANÇAMENTO'
			ELSE ''
		END AS FILTRO_CONTEXTO
	from 
		(
		select 
			substring(matnr, 13, 6) as matnr, 
			-- (3-1+1) * rand()+1 as num_filtro,
			-- (8-1+1) * rand()+1 as num_categoria
			trunc((3-1+1) * rand()+1) as num_filtro,
			trunc((8-1+1) * rand()+1) as num_categoria
		from
		 	dados-dev.raw.MARA 
		) p	
	) g
	on g.matnr = p.produto
JOIN ( 
	--"_SYS_BIC"."CimedTech/CV_A954_955_ZPFA_ZPMC" ZPFA
	select
	q.tabela, q.produto, q.valor, q.lista, j.SHIPFROM, Y218.VKORG
from 
	(	
	SELECT 
		b.kschl as tabela, cast(cast(b.matnr as integer) as string) as produto, 
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
	AND J.SHIPFROM = J.SHIPTO ) AS ZPFA
  ON ZPFA.PRODUTO = P.PRODUTO
 AND ZPFA.SHIPFROM = P.REGIO

LEFT JOIN ( 
	-- "_SYS_BIC"."CimedTech/CV_A954_955_ZPFA_ZPMC"
	select
	q.tabela, q.produto, q.valor, q.lista, j.SHIPFROM, Y218.VKORG
from 
	(	
	SELECT 
		b.kschl as tabela, cast(cast(b.matnr as integer) as string) as produto,
		a.kbetr as valor, b.PLTYP as LISTA
	FROM 
		dados-dev.raw.KONP AS a 
	left JOIN dados-dev.raw_cimed_tech.A955 AS b
		ON a.knumh = b.knumh   
	WHERE 
		a.loevm_ko <> 'X' -- marcado para exclusão
		AND (current_date between PARSE_DATE("%Y%m%d",b.datab) AND PARSE_DATE("%Y%m%d",b.datbi))
		and a.mandt = '500'  
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
	AND J.SHIPFROM = J.SHIPTO ) AS ZPMC
  ON ZPMC.PRODUTO = P.PRODUTO
 AND ZPMC.SHIPFROM = P.REGIO

LEFT JOIN 
	(
	SELECT
		PRODUTO, VALOR, SALDO, VKORG
	FROM 
		dados-dev.visoes_auxiliares_cimed_tech.CV_VIEW_VALIDADE_CURTA
	) VC
	ON VC.VKORG = P.VKORG 
	AND VC.PRODUTO = P.PRODUTO
group by 
	--num_categoria, num_filtro, 
	P.produto, P.perc_comis, ZPFA, ZPMC, P.V_ZFAT, P.V_ZSTA, P.COD_GAMA, 
	P.DESCRICAO, P.VTWEG, P.BUKRS, P.WERKS, P.FUNC_PAR, P.REGIO,
	P.VKORG, ult.vlr_unit, ult.ult_qde, ult.erdat,
	M.CODIGOBARRAS, M.CODIGO, M.DESCRICAO, M.PRINCIPIOATIVO, M.GENERICO, M.LISTA, M.CODIGO_MS,
	M.LINHA, M.STATUS, M.C_CONTROLADO, M.GRP_MERCADORIA,  M.FABRICANTE, M.CAIXA_PADRAO, M.IPI,
	M.FARM_POPULAR, M.PROD_MARCA, M.PROD_CLASSEI, M.PROD_FATOR, M.NCM, M.GRPMERCEXTERNO, 
	--E.LGORT, E.MESES, E.TRANSITO, E.DISPONIVEL, 
	g.menu_categoria, g.filtro_contexto,
	M.hierarquia, g.num_filtro, g.num_categoria, 
	VC.VALOR, VC.SALDO, P.KUNNR, P.LIFNR
Order by
	vlr_unit desc
    limit 10
 
												 
