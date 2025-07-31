-- teste para substituir `dados-dev.visoes_cimed_tech.CV_A996_LOJAS_GERAL`
with w_konp as (
	select 
		mandt, knumh, kbetr, kpein
    from 
        dados-dev.raw.KONP
	where 
		kschl IN('ZCO2','ZQCO', 'ZPTL')
		and loevm_ko <> 'X'
), 
w_a996 as (
    select 
        mandt, knumh, vkorg, wty_v_parvw, matnr
    from 
        dados-dev.raw_cimed_tech.A996
    where 
        kschl = 'ZQCO'
        AND (current_date between PARSE_DATE("%Y%m%d",datab) AND PARSE_DATE("%Y%m%d",datbi))
),
w_44_218 as (
    select 
        y218.vkorg, y218.werks, y44.lgort, y44.meses
	from 
        dados-dev.raw.YDSD218 y218
	join 
        dados-dev.raw_cimed_tech.YDSD044 y44
        on y44.werks = y218.werks
),
w_validade_curta as (
	select 
		z.vkorg,
		z.matnr as produto,
		z.kbetr as valor
		,sum(e.qtutil_livre) AS saldo
	from (
		with w_a850 as
		(
			select  
				vkorg, matnr, knumh
			from 
				dados-dev.raw_cimed_tech.A850
			where 
				current_date BETWEEN PARSE_DATE("%Y%m%d",datab) AND PARSE_DATE("%Y%m%d",datbi)		
				and kschl = 'ZPTL'
		)
		SELECT
			b.vkorg, b.matnr, a.kbetr, a.kpein
		FROM
			w_konp as a
		JOIN
			w_a850 as b
			ON a.knumh = b.knumh	
	) as z
	join
		w_44_218 y218
		on y218.vkorg = z.vkorg	
	------- estoque ------    
	join
		(
		with w_mch1 as 
			(
				SELECT
					MATNR, CHARG, VFDAT, qndat, hsdat, 1 as counter, diasavencer
				from 
					(
					SELECT 
						MATNR, CHARG, VFDAT, qndat, hsdat, 1 as counter,
						CASE
							WHEN VFDAT = '00000000' THEN NULL
						ELSE
							DATE_DIFF(PARSE_DATE("%Y%m%d",VFDAT), CURRENT_DATE , day) 
						END AS diasavencer
					FROM 
						dados-dev.raw.MCH1
					)
				where 
					DIASAVENCER BETWEEN 0 AND 179
			),
			w_mchb as (
				SELECT
					MATNR, WERKS, CHARG, LGORT, LAEDA, LFGJA, LFMON, CLABS, CINSM, CSPEM
				FROM
					dados-dev.raw.MCHB        
		)	
	SELECT 
	  Q1.material, QB.centro, QB.deposito, QB.lote, Q1.dtprod_d, 
	  Q1.dtvenc, Q1.dtcontrl_d, QB.mes_periodo_atual, QB.exerc_periodo_atual,
	  QB.dtutimodif, Q1.diasavencer, SUM(QB.QTUTIL_LIVRE) AS QTUTIL_LIVRE, 
	  SUM(QB.QTCONTROL_QUAL) AS qtcontrol_qual, SUM(QB.QTBLOQ) AS qtbloq
	FROM 
		(
		SELECT
			MATNR AS material, CHARG AS lote, VFDAT AS dtvenc, qndat as dtcontrl_d, hsdat as dtprod_d, diasavencer
		FROM
			w_mch1
		) AS Q1
	JOIN 
		(
		SELECT
			MATNR AS MATERIAL, WERKS AS CENTRO, CHARG AS LOTE, LGORT AS DEPOSITO, LAEDA AS DTUTIMODIF, LFGJA AS EXERC_PERIODO_ATUAL,
			LFMON AS MES_PERIODO_ATUAL, CLABS AS QTUTIL_LIVRE, CINSM AS QTCONTROL_QUAL, CSPEM AS QTBLOQ
		FROM
			w_mchb
		where 
			LGORT in (select lgort from w_44_218)
		) AS QB
		ON Q1.MATERIAL = QB.MATERIAL
		AND Q1.LOTE = QB.LOTE 
	WHERE
		QTUTIL_LIVRE > 0.0
	GROUP BY
		Q1.MATERIAL, QB.CENTRO, QB.DEPOSITO, QB.LOTE, Q1.DTPROD_D, Q1.DTVENC, Q1.DTCONTRL_D,
		QB.MES_PERIODO_ATUAL, QB.EXERC_PERIODO_ATUAL, QB.DTUTIMODIF,Q1.DIASAVENCER
	) as E
	on E.MATERIAL = Z.matnr
		and E.CENTRO = y218.WERKS
		and E.DEPOSITO = y218.LGORT	
	group by
		z.VKORG, z.matnr, z.kbetr        
	order by 
		z.VKORG, z.matnr
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
		distinct D.CLIENTE as kunnr, 
		D.MATNR, max(D.DT_OV) as erdat, 
		round( (sum(D.VLR_LIQUIDO) + sum(D.VLR_MONTIMPOSTO)) / sum(D.QTDECALCULADA), 2) as vlr_unit, 
		round(sum(D.QTDECALCULADA), 2) as ult_qde		
	FROM dados-dev.visoes_YDBI_0006.YDBI006_ITEM_T D
	GROUP BY
		D.CLIENTE, D.MATNR
),
w_contexto AS (
    SELECT * FROM EXTERNAL_QUERY("projects/dados-dev/locations/us/connections/cimed-postgres-us", "SELECT c.id, pd.produto__c, c.name, C.tipo_de_destaque__c FROM SF.CAMPAIGN C join	SF.PRODUTOS_DESTAQUE__C PD 	on PD.campanha__c = C.id where c.type = 'Destaque' ")
),
w_precos as (
    select *
    from `dados-dev.visoes_cimed_tech.A996_LOJAS_PRECOS_T`	
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
    round(SUM(V_ZPFA),2) AS ZPFA,
	round(SUM(V_ZPMC),2) AS ZPMC,
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
	'https://storage.googleapis.com/gc-conteudo/'||substring(MAT.hierarquia, 1, 3)|| '/'||substring(MAT.hierarquia, 4, 3)|| '/'||substring(MAT.hierarquia, 5, 3)||'/'||substring(MAT.hierarquia, 10, 3)||'/'||substring(P.produto,13,6)||'/'||substring(P.produto,13,6)||'-I.png?ignoreCache=0' as IMAGEM,
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
            )
        select 
            lif.*, g.matnr
        from 
            dados-dev.raw_cimed_tech.LOJAS_LIFNR_T as lif
        join
            w_gama_produto as g
            ON g.cod_gama = lif.cod_gama
    ),
    w_zco2 as 
        (
        select 
            vkorg, func_par, produto, faixa, valor, perc_comis
        from 
            dados-dev.visoes_cimed_tech.A996_LOJAS_ZCO2_T
        ),
        w_zqco as (
            with w_konm as (
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
    )
    select  
        loja.cod_gama, loja.descricao, loja.vtweg, loja.bukrs, loja.werks, 
        loja.vkorg, loja.func_par, loja.kunnr, loja.lifnr,        
        zco2.produto, zco2.faixa, 0 as perc_comis, 

        zprc.V_ZFAT, zprc.V_ZSTA, zprc.V_ZPFA, zprc.V_ZPMC,    

        case when zco2.faixa = 2 then round(((zprc.V_ZFAT / (1 - zco2.valor/100)) + zprc.V_ZSTA),2) else 0 end as VALOR_P,
        case when zco2.faixa = 1 then round(((zprc.V_ZFAT / (1 - zco2.valor/100)) + zprc.V_ZSTA),2) else 0 end as VALOR_M,	
        case when zco2.faixa = 0 then round(((zprc.V_ZFAT / (1 - zco2.valor/100)) + zprc.V_ZSTA),2) else 0 end as VALOR_G,	
        case when zco2.faixa = -1 then round(((zprc.V_ZFAT / (1 - zco2.valor/100)) + zprc.V_ZSTA),2) else 0 end as VALOR_G1,
        case when zco2.faixa = -2 then round(((zprc.V_ZFAT / (1 - zco2.valor/100)) + zprc.V_ZSTA),2) else 0 end as VALOR_G2,	

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
        0 as disponivel, 0 as transito, y44.meses, y44.lgort
    from 
        w_loja as loja
    join 
        w_zco2 as zco2 
        on zco2.vkorg = loja.vkorg 
        and zco2.func_par = loja.func_par
        and zco2.produto = loja.matnr
    join    
        w_precos as zprc
        on zprc.matnr = zco2.produto
        and zprc.vkorg = zco2.vkorg
    left join  
        w_zqco as zqco
        on zqco.vkorg = zco2.vkorg
        and zqco.produto  = zco2.produto
        and zqco.faixa-1 = zco2.faixa
    join 
        w_44_218 as y44 
        on y44.werks = loja.werks
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