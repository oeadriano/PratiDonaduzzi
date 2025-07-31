{
"query": {{ CONCAT("SELECT LIFNR, CODIGO,CLI_RZS,CLI_CGC,CLI_END,CLI_NUM,CLI_BAI,CLI_CEP,CLI_EST,CLI_CID,CLI_TEL,CLI_EMAIL,CLI_LIMITE, ALVARANUMERO,ALVARADATA,ALVARANUMEROSANIT,ALVARADATASANIT,RESPTECNICONOME,RESPTECNICOCRF,DATACRF,ALVARANUMEROSIVISA,ALVARADATASIVISA,CONTROLADO,NUMERO_AE,CAIXA_FECHADA,BLOQUEIO,GRUPO_CONTAS,CROSSDOCKING,CONTA_MATRIZ,BU,ASSOCIATIVISMO1,ASSOCIATIVISMO2,NOME_ASS1,NOME_ASS2,COD_REDE,NOME_REDE,BLOQ_FINANCEIRO,POSITIVADO,BLOQ_DOCUMENTO,CREDITO_TOTAL,CREDITO_CONSUMIDO,MIX_PLANEJADO,MIX_REALIZADO,OPORTUNIDADE,OPORTUNIDADE_REALIZADO,DUP_ATRASO,TAG_CREDITO,TAG_DOCUMENTACAO,TAG_POSITIVADO,TAG_DUPLICATAS 
FROM raw_cimed_tech.REP_CLIENTES_IP_T WHERE LIFNR = '" , message.queryAndPath.lifnr , "' " ) }},
"useLegacySql": false
}

{
"query": {{ CONCAT("SELECT * FROM visoes_cimed_tech.CV_A996_LOJAS_GERAL WHERE lifnr = '" , message.queryAndPath.lifnr , "' and kunnr = '", message.queryAndPath.cliente, "' " ) }},
"useLegacySql": false
}

,
material as (
        select 
        codigo, codigobarras, DESCRICAO as descricao_material, principioativo, generico, lista, 
        codigo_ms, linha, status, c_controlado, produto_hierarquia, 
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
	    prod_fator, ncm, grpmercexterno
    from     
        dados-dev.raw_cimed_tech.CV_CADASTRO_MATERIAL_T
)




----------------------------------------------------------------------------------------------------------------
---------------------------------------- VERSAO FINAL ----------------------------------------------------------
----------------------------------------------------------------------------------------------------------------
with material as (    
        select 
        codigo, codigobarras, DESCRICAO as descricao_material, principioativo, generico, lista, 
        codigo_ms, linha, status, c_controlado, produto_hierarquia, 
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
	    prod_fator, ncm, grpmercexterno
    from     
        dados-dev.raw_cimed_tech.CV_CADASTRO_MATERIAL_T
)    
select 
    mat.codigo, mat.codigobarras, mat.descricao_material, mat.principioativo, mat.generico, mat.lista, 
    mat.codigo_ms, mat.linha, mat.status, mat.c_controlado, mat.produto_hierarquia,
	mat.grp_mercadoria, mat.fabricante, mat.caixa_padrao, mat.ipi, mat.farm_popular, mat.prod_marca, mat.prod_classei, 
	mat.prod_fator, mat.ncm, mat.grpmercexterno,	
    P.cod_gama, P.descricao, P.vtweg, P.bukrs, P.werks,P.vkorg, P.func_par, P.kunnr, P.lifnr, P.produto, 0 as perc_comis,
    sum(V_ZFAT) as V_ZFAT,
	sum(V_ZSTA) as V_ZSTA,
    sum(ZPFA) as ZPFA,
	sum(ZPMC) as ZPMC,
    sum(VALOR_P) as VALOR_P,
    sum(VALOR_M) as VALOR_M,
    sum(VALOR_G) as VALOR_G,
    sum(VALOR_G1) as VALOR_G1,
    sum(VALOR_G2) as VALOR_G2,

    sum(QDE_P) as QDE_P,
    sum(QDE_M) as QDE_M,
    sum(QDE_G) as QDE_G,
    sum(QDE_G1) as QDE_G1,
    sum(QDE_G2) as QDE_G2,

    sum(COMIS_P) as COMIS_P,
    sum(COMIS_M) as COMIS_M,
    sum(COMIS_G) as COMIS_G,
    sum(COMIS_G1) as COMIS_G1,
    sum(COMIS_G2) as COMIS_G2
	
from 
    material as mat
join 
(
with w_loja as (
   select 
        distinct g.cod_gama, l.descricao, l.vtweg, 
        G.bukrs, g.werks, g.vkorg, y94.func_par, lf.kunnr, lf.lifnr, g.produto
    from ( 
        -- "_SYS_BIC"."VISAO/CV_YDSD_GAMA_AUTORIZACOES" G
        SELECT 
            DISTINCT A.BUKRS, A.WERKS, A.COD_GAMA, cast(T3.LIFN2 as string) AS LIFNR, I.ID, i.vkorg, c.matnr as produto
        FROM 
            dados-dev.raw_cimed_tech.YDSD225 AS a
        JOIN 
            dados-dev.raw_cimed_tech.YDSD056 AS b
            ON a.cod_gama = b.cod_gama
        JOIN
            dados-dev.raw_cimed_tech.YDSD057 AS c 
            ON c.cod_gama = b.cod_gama
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
            and a.werks <> '1100' 
        ) AS G
    join                
        ( 
        SELECT 
            DISTINCT VKORG, KUNNR, LIFNR
        FROM
            `dados-dev.raw_cimed_tech.LIFNR_CLIENTE_T`
        ) AS LF
            ON LF.LIFNR = G.LIFNR	
            AND LF.VKORG = G.VKORG
    JOIN
        dados-dev.raw_cimed_tech.YDSD056 L
        ON L.COD_GAMA = G.COD_GAMA
    JOIN
        dados-dev.raw.YDSD094 Y94
        ON LF.LIFNR = Y94.repr	
    --where 
    --				g.lifnr = :IP_LIFNR and lf.kunnr = :IP_CLIENTE	
        --g.lifnr = '0000600037' and lf.kunnr = '0001009136'	
),
w_zco2 as ( 
    SELECT
        ROW_NUMBER() OVER (PARTITION BY b.vkorg, b.wty_v_parvw, b.matnr order by b.vkorg, b.wty_v_parvw, b.matnr, k.kbetr )-3 AS faixa,
        b.matnr as produto,
        k.kstbm AS valor, ROUND((k.kbetr/10),2) AS perc_comis, 
        b.vkorg, b.wty_v_parvw as func_par
    FROM
        dados-dev.raw.KONP AS a
    INNER JOIN
        dados-dev.raw_cimed_tech.A996 AS b
    ON
        a.knumh = b.knumh
        AND a.mandt = b.mandt
    INNER JOIN
        dados-dev.raw_cimed_tech.KONM AS k
    ON
        k.mandt = b.mandt
        AND k.knumh = b.knumh
    where  
        b.kschl = 'ZCO2'
        AND (current_date between PARSE_DATE("%Y%m%d",b.datab) AND PARSE_DATE("%Y%m%d",b.datbi))
    ORDER BY
        b.vkorg, b.WTy_v_parvw, b.matnr, k.kbetr
),
w_zfat as (
    SELECT 
		b.kschl as tabela, 
		b.matnr as produto, 
		a.kbetr as valor, 
		a.kpein as qtdmin, 
	FROM 
        dados-dev.raw.KONP AS a 
	JOIN dados-dev.raw.A937 AS b
		ON a.knumh = b.knumh
	WHERE 
		a.loevm_ko <> 'X' -- marcado para exclusão
		AND (current_date between PARSE_DATE("%Y%m%d",b.datab) AND PARSE_DATE("%Y%m%d",b.datbi))
		and a.mandt = '500'
		AND b.kschl = 'ZFAT' 
),
w_zsta as (
    SELECT 
		b.kschl as tabela, b.vkorg, b.matnr as produto,  a.kbetr as valor, a.kpein as qtdmin,
		b.kschl as codigo
	FROM dados-dev.raw.KONP AS a 
	left JOIN dados-dev.raw_cimed_tech.A508 AS b
		ON a.knumh = b.knumh   	
	WHERE 
		a.loevm_ko <> 'X' -- marcado para exclusão
		AND (current_date between PARSE_DATE("%Y%m%d",b.datab) AND PARSE_DATE("%Y%m%d",b.datbi))
		and a.mandt = '500'  
		And b.kschl = 'ZSTA'
),
w_zqco as (
-- "_SYS_BIC"."VISAO/CV_A508_A709_ZQCO" ZQ	
	select 
		VKORG, PRODUTO, FAIXA, QTDMIN 
	FROM 
	   (select VKORG, PRODUTO, FAIXA, QTDMIN 
		from ( SELECT i.vkorg, 
                      b.matnr as produto,
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
			(SELECT DISTINCT b.vkorg || b.matnr as produto,
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
                      b.matnr as produto,
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
    case when zco2.faixa = -2 then zco2.perc_comis else 0 end as COMIS_G2    
from 
    w_loja as loja
join 
    w_zco2 as zco2 
    on zco2.vkorg = loja.vkorg 
    and zco2.func_par = loja.func_par
    and zco2.produto = loja.produto
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
join  
    w_zpfa as zpfa 
    on zpfa.produto = zco2.produto
    and zpfa.vkorg = zco2.vkorg
join  
    w_zpmc as zpmc
    on zpmc.produto = zco2.produto
    and zpmc.vkorg = zco2.vkorg
) P
on mat.codigo = P.produto
group by	
 mat.codigo, mat.codigobarras, mat.descricao_material, mat.principioativo, mat.generico, mat.lista, 
    mat.codigo_ms, mat.linha, mat.status, mat.c_controlado, mat.produto_hierarquia,
	mat.grp_mercadoria, mat.fabricante, mat.caixa_padrao, mat.ipi, mat.farm_popular, mat.prod_marca, mat.prod_classei, 
	mat.prod_fator, mat.ncm, mat.grpmercexterno,	
    P.cod_gama, P.descricao, P.vtweg, P.bukrs, P.werks,P.vkorg, P.func_par, P.kunnr, P.lifnr, P.produto
order by P.produto
