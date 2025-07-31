-- teste para substituir `dados-dev.visoes_cimed_tech.CV_A996_LOJAS_GERAL`
-- select count(*) from dados-dev.raw.KONP --133283
-- select count(*) from dados-dev.raw.A937 -- 16327
-- select count(*) from dados-dev.raw_cimed_tech.A508 -- 768366
-- select count(*) from dados-dev.raw_cimed_tech.A954 -- 70959
-- select count(*) from dados-dev.raw_cimed_tech.J_1BTXIC1 



with w_a508 as (
    SELECT 
		b.vkorg, b.matnr, b.knumh
	FROM 
        dados-dev.raw_cimed_tech.A508 b
	WHERE 
        (current_date between PARSE_DATE("%Y%m%d",b.datab) AND PARSE_DATE("%Y%m%d",b.datbi))
		and b.kschl = 'ZSTA'
),
w_konp as (
    select 
        knumh, kbetr, kpein
    from 
        dados-dev.raw.KONP
    where 
        loevm_ko <> 'X' 
		and KSCHL in ('ZFAT', 'ZSTA', 'ZPFA', 'ZPMC')
),
w_a937 as (
    SELECT 
		b.matnr, b.knumh
    FROM 
        dados-dev.raw.A937 AS b
	WHERE 
        (current_date between PARSE_DATE("%Y%m%d",b.datab) AND PARSE_DATE("%Y%m%d",b.datbi))
		AND b.kschl = 'ZFAT' 
), 
w_y218 as (
    select distinct vkorg 
    from dados-dev.raw.YDSD218
),
w_a954 as (
    SELECT 
		b.matnr, b.PLTYP, b.knumh
	from 
        dados-dev.raw_cimed_tech.A954 AS b
	WHERE 
        (current_date between PARSE_DATE("%Y%m%d",b.datab) AND PARSE_DATE("%Y%m%d",b.datbi))
		and b.kschl in ('ZPFA')
)
-- ZFAT 
SELECT 
    zfat.vkorg, zfat.matnr, zfat.kbetr AS V_ZFAT, zsta.kbetr AS V_ZSTA
FROM 
    (
    SELECT 
        b.matnr, 
        a.kbetr,
        y.vkorg         
    FROM 
        w_konp AS a 
    JOIN w_a937 AS b
        ON a.knumh = b.knumh
    CROSS JOIN 
        w_y218 as y
    ) zfat
    LEFT JOIN 
        -- ZSTA
        (
        SELECT 
            b.vkorg, b.matnr, a.kbetr
        FROM w_a508 AS b 
        JOIN w_konp AS a
            ON a.knumh = b.knumh   	
        ) zsta
        on zsta.matnr = zfat.matnr
        and zsta.vkorg = zsta.vkorg
    ------------------- ZPFA        
    JOIN
    (	
        SELECT 
            b.matnr, a.kbetr as valor, b.PLTYP as LISTA, y218.vkorg
        FROM 
            w_konp AS a 
        JOIN w_a954 AS b
            ON a.knumh = b.knumh
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
            w_y218 Y218
            ON Y218.UF = J.SHIPFROM
        WHERE
            (PARSE_DATE("%Y%m%d",cast((99999999 - cast(J.validfrom as INTEGER)) as string)) <= current_date)		
            AND J.LAND1 = 'BR'
            AND J.SHIPFROM = J.SHIPTO 
    ) as zpfa
    on zpfa.matnr = zfat.matnr
    and zpfa.vkorg = zsta.vkorg


--where zsta.vkorg = '3000'







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
    `dados-dev.raw.YDSD044` as y44 
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