-- 16/12/21 correcao aliquota de 12% para generico em MG e SP
with w_konp as (
	select 
		mandt, knumh, kbetr, kpein
	from 
		`dados-dev.raw.KONP`
	where 
		loevm_ko <> 'X' -- marcado para exclusão 
		and mandt = '500'
),
w_y218 as (
	select * 
	from `dados-dev.raw.YDSD218`
	where  vkorg <> '1100'
)
,
  W_CUSTO_ZFAT as (SELECT
	                 cast(MANDT as integer) as MANDT,
	                 TABELA,
	                 ESCALA,
	                 UF,
	                 '1005' as VKORG,
	                 CANAL,
	                 CLIENTE,
	                 REDE,
	                 DATA,
 	                 VALIDADE,
                     PRODUTO,
	                 VALOR,
	                 QTDMIN,
	                 CODIGO,
	                 '' as CLASSE, 
	                 "ID_DISTRIBUIDORA" 
                   FROM `dados-dev.visoes_auxiliares_cimed_tech.CV_A937_MATERIAL`
                   where tabela = 'ZFAT'
  ),
  W_508_VKORG_MATERIAL as (  SELECT 
								a.mandt, 
								b.kschl as tabela,  
								''      as escala, 
								''      as uf, 
								b.vkorg, 
								''      as canal,
								''      as cliente, 
								''      as rede, 
								b.datab as data, 
								b.datbi as validade,	
								cast(cast(b.matnr as integer) as string) as produto,  
								a.kbetr as valor, 
								a.kpein as qtdmin,
                                b.kschl as codigo, 
								i.id    AS id_distribuidora
							FROM w_konp AS a 
 							JOIN `dados-dev.raw_cimed_tech.A508` AS b
	     					  ON a.knumh = b.knumh   
							JOIN w_y218 AS i
							  ON i.vkorg = b.vkorg	
							WHERE 
								(current_date between PARSE_DATE("%Y%m%d",b.datab) AND PARSE_DATE("%Y%m%d",b.datbi))
							  and a.mandt = '500'  
							  And b.kschl in ('ZSTA', 'ZPTL', 'ZPMI')
							ORDER BY
							   b.kschl, 
							   b.vkorg, 
							   data, 
							   validade, 
							   produto

  ),
  W_A508_ZQCO_VKORG_MATERIAL as (SELECT
                                   b.vkorg, 
	                               cast(cast(b.matnr as integer) as string) as produto,
	                               cast(c.kbetr/10 as int64) as faixa, 
                                   cast(c.kstbm as integer) as qtdmin
                                 FROM w_konp AS a
                                 JOIN `dados-dev.raw_cimed_tech.A508` AS b
	                               ON a.knumh = b.knumh
                                 JOIN `dados-dev.raw_cimed_tech.KONM` AS c
	                               ON a.knumh = c.knumh
                                 JOIN w_y218 AS i
	                               ON i.vkorg = b.vkorg
                                 WHERE 
								 	(current_date between PARSE_DATE("%Y%m%d",b.datab) AND PARSE_DATE("%Y%m%d",b.datbi))	                               
	                               And b.kschl in ('ZQCO')
                                 ORDER BY
	                               vkorg, 
                                   produto, 
                                   faixa 
  ),
W_A954_955_ZPFA_ZPMC as (
  select 
		q.tabela, substring(q.produto, 13, 6) as produto,
		case
			when j.SHIPFROM in ('MG', 'SP') and generico = 'S' then valor_12
			else valor
		end as valor,
		q.lista, j.SHIPFROM, Y218.VKORG
		--, generico, valor_12
	from 
		(        
		select 
			tabela, matnr as produto, sum(valor) as valor, sum(valor_12) as valor_12,
			LISTA, generico
		from
			(
			with w_mara as (
				select matnr, 
					case when matkl in ('PA07','PA08', 'PA09', 'PA10', 'PA16', 'PA17', 'PA20', 'PA21', 'PA22') then 'S'
					else 'N'
				end as generico    
				from 
					`dados-dev.raw.MARA`
				where 
					MTPOS_MARA in ('YLOT', 'YMKT')
			)
			-- ZPFA GERAL
			SELECT
				b.kschl AS tabela, b.matnr, a.kbetr AS valor, 0 as valor_12,
				CASE
					WHEN b.PLTYP = '97' THEN '17.5'
				ELSE
					b.PLTYP
				END AS LISTA, 
				m.generico
			FROM
				w_konp AS a
			JOIN
				`dados-dev.raw_cimed_tech.A954` AS b
				ON a.knumh = b.knumh
			join
				w_mara as m
				on m.matnr = b.matnr
			WHERE     
				(current_date BETWEEN PARSE_DATE("%Y%m%d",b.datab) AND PARSE_DATE("%Y%m%d", b.datbi))
				AND b.kschl IN ('ZPFA')
			-- ZPMC GERAL 
			union all
			SELECT
				b.kschl AS tabela, b.matnr, a.kbetr AS valor, 0 as valor_12,
				CASE
					WHEN b.PLTYP = '97' THEN '17.5'
				ELSE
					b.PLTYP
				END AS LISTA, 
				m.generico
			FROM
				w_konp AS a
			JOIN
				`dados-dev.raw_cimed_tech.A955` AS b
				ON a.knumh = b.knumh
			join
				w_mara as m
				on m.matnr = b.matnr
			WHERE
				(current_date BETWEEN PARSE_DATE("%Y%m%d",b.datab) AND PARSE_DATE("%Y%m%d", b.datbi))
				AND b.kschl IN ('ZPMC')

			UNION ALL
			-- ZPFA 12% PARA GENERICO MG E SP
			SELECT
				b.kschl AS tabela, b.matnr, 0 AS valor, a.kbetr as valor_12,
				'18' AS LISTA, m.generico
			FROM
				w_konp AS a
			JOIN
				`dados-dev.raw_cimed_tech.A954` AS b
				ON a.knumh = b.knumh
			join
				w_mara as m
				on m.matnr = b.matnr
			WHERE     
				(current_date BETWEEN PARSE_DATE("%Y%m%d",b.datab) AND PARSE_DATE("%Y%m%d", b.datbi))
				AND b.kschl IN ('ZPFA')
				AND b.PLTYP = '12' 
				and m.generico = 'S'    

			-- ZPMC DE 12% para GENERICO MG E SP
			union all
			SELECT
				b.kschl AS tabela, b.matnr, 0 AS valor, a.kbetr as valor_12,
				'18' AS LISTA, m.generico
			FROM
				w_konp AS a
			JOIN
				`dados-dev.raw_cimed_tech.A955` AS b
				ON a.knumh = b.knumh
			join
				w_mara as m
				on m.matnr = b.matnr
			WHERE
				(current_date BETWEEN PARSE_DATE("%Y%m%d",b.datab) AND PARSE_DATE("%Y%m%d", b.datbi))
				AND b.kschl IN ('ZPMC')
				AND b.PLTYP = '12' 
				and m.generico = 'S'
			)    
		group by
			tabela, matnr, LISTA, generico
		) as q
	join	
		`dados-dev.raw_cimed_tech.J_1BTXIC1` J
		ON J.RATE  = cast(q.LISTA as numeric)
		JOIN
			(SELECT 
				SHIPFROM, Min(VALIDFROM) AS VALIDFROM
			FROM 
				`dados-dev.raw_cimed_tech.J_1BTXIC1`
			WHERE 
				SHIPFROM=SHIPTO
				-- AEO 07.12.21 AND specf_rate = 0
			GROUP BY SHIPFROM	
		) U	
		ON U.SHIPFROM = J.SHIPFROM
		AND U.VALIDFROM = J.VALIDFROM	
	join 
		w_y218 as Y218
		ON Y218.UF = J.SHIPFROM
	WHERE 
		PARSE_DATE("%Y%m%d",cast((cast(99999999 as int64) - cast(J.validfrom as int64)) as string)) <= current_date
		AND J.LAND1 = 'BR'
		AND J.SHIPFROM = J.SHIPTO
		--AND J.SHIPFROM in ('MG', 'SP')
		AND Y218.vkorg <> '1100'
 )


SELECT
		P.produto, 
        P.perc_comis, 
        ZPFA.VALOR as v_zpfa, 
        ZPMC.VALOR as v_zpmc, 
        P.v_zfat, 
		P.v_zsta, 
        v_zptl, 
        v_zpmi,
		sum(P.valor_p)  as valor_p, 
        sum(P.valor_m)  as valor_m, 
        sum(P.valor_g)  as valor_g, 
		sum(P.valor_g1) as valor_g1, 
        sum(P.valor_g2) as valor_g2, 
		sum(P.QDE_P)    as qde_p, 
        sum(P.qde_m)    as qde_m, 
        sum(P.qde_g)    as qde_g, 
		sum(P.qde_g1)   as qde_g1, 
        sum(P.qde_g2)   as qde_g2,
		P.FUNC_PAR as func_par,
		P.VKORG as vkorg
	from 
		(
		SELECT
			PMG.produto, 
			PMG.perc_comis,
			ZFAT.VALOR AS V_ZFAT,
			ZSTA.VALOR AS V_ZSTA,
			ZPTL.VALOR AS V_ZPTL,
			ZPMI.VALOR AS V_ZPMI,			
			case
				when PMG.faixa = 5 then round(((ZFAT.VALOR / (1 - PMG.valor/100)) + ZSTA.VALOR),2)
				else 0
			end as VALOR_P,
			case
				when PMG.faixa = 4 then round(((ZFAT.VALOR / (1 - PMG.valor/100)) + ZSTA.VALOR),2)
				else 0
			end as VALOR_M,	
			case
				when PMG.faixa = 3 then round(((ZFAT.VALOR / (1 - PMG.valor/100)) + ZSTA.VALOR),2)
				else 0
			end as VALOR_G,	
			case
				when PMG.faixa = 2 then round(((ZFAT.VALOR / (1 - PMG.valor/100)) + ZSTA.VALOR),2)
				else 0
			end as VALOR_G1,	
			case
				when PMG.faixa = 1 then round(((ZFAT.VALOR / (1 - PMG.valor/100)) + ZSTA.VALOR),2)
				else 0
			end as VALOR_G2,			
			case
				when PMG.faixa = 5 then COALESCE(ZQ.QTDMIN, 1)
				else 0
			end as QDE_P,		
			case
				when PMG.faixa = 4 then COALESCE(ZQ.QTDMIN, 1)
				else 0
			end as QDE_M, 
			case
				when PMG.faixa = 3 then COALESCE(ZQ.QTDMIN, 1)
				else 0
			end as QDE_G, 
			case
				when PMG.faixa = 2 then COALESCE(ZQ.QTDMIN, 1)
				else 0
			end as QDE_G1, 
			case
				when PMG.faixa = 1 then COALESCE(ZQ.QTDMIN, 1)
				else 0
			end as QDE_G2, 
			PMG.VKORG, PMG.FUNC_PAR
		FROM
			(	
			SELECT
				ROW_NUMBER() OVER
				(PARTITION BY b.matnr
					order by b.matnr, k.kstbm) as faixa, 				
				cast(cast(b.matnr as integer) as string) as produto,     
			    k.kstbm as valor, 
			    -- retirado para nao atrapalhar a api
				-- em caso de cadastr de comissao antigo
				-- round((k.kbetr/10),2) as perc_comis, 
			    0 as perc_comis, 
			    b.vkorg, 
                b.WTY_V_PARVW as FUNC_PAR
			FROM w_konp as a 
			INNER JOIN dados-dev.raw_cimed_tech.A996 AS b
				ON a.knumh = b.knumh
				AND a.mandt = b.mandt
			INNER JOIN `dados-dev.raw_cimed_tech.KONM` as k
				on k.mandt = b.mandt
				AND k.knumh = b.knumh
			WHERE 
				(current_date between PARSE_DATE("%Y%m%d",b.datab) AND PARSE_DATE("%Y%m%d",b.datbi))
				--AND b.vkorg = '3000' AND b.WTY_V_PARVW = 'Y1'
			ORDER BY
				b.matnr, faixa desc
			) PMG		
		JOIN W_CUSTO_ZFAT ZFAT
			ON ZFAT.produto = PMG.produto
		LEFT JOIN 
			W_508_VKORG_MATERIAL ZSTA
			ON ZSTA.VKORG = PMG.VKORG
			AND ZSTA.PRODUTO = PMG.PRODUTO	
			AND ZSTA.TABELA IN( 'ZSTA')
		LEFT JOIN 
			W_508_VKORG_MATERIAL ZPMI
			ON ZPMI.VKORG = PMG.VKORG
			AND ZPMI.PRODUTO = PMG.PRODUTO	
			AND ZPMI.TABELA IN( 'ZPMI')			
		LEFT JOIN 
			W_508_VKORG_MATERIAL ZPTL
			ON ZPTL.VKORG = PMG.VKORG
			AND ZPTL.PRODUTO = PMG.PRODUTO	
			AND ZPTL.TABELA = 'ZPTL'
		LEFT JOIN W_A508_ZQCO_VKORG_MATERIAL ZQ
			ON ZQ.VKORG = PMG.VKORG
			AND ZQ.PRODUTO = PMG.PRODUTO
			AND ZQ.FAIXA = PMG.FAIXA
		) as P
	join w_y218 as y218
	  on y218.vkorg = P.VKORG
		--on y218.vkorg = '3000'
	JOIN W_A954_955_ZPFA_ZPMC ZPFA
	  ON ZPFA.PRODUTO = P.PRODUTO
 	 AND ZPFA.SHIPFROM = y218.UF
	 AND ZPFA.TABELA = 'ZPFA'
	LEFT JOIN W_A954_955_ZPFA_ZPMC ZPMC
	  ON ZPMC.PRODUTO = P.PRODUTO
  	 AND ZPMC.SHIPFROM = y218.UF
	 AND ZPMC.TABELA = 'ZPMC'
	group by
	  P.produto, 
      P.perc_comis, 
      ZPFA.VALOR, 
      ZPMC.VALOR, 
	  P.V_ZFAT, 
      P.V_ZSTA,
      P.V_ZPTL,
      P.V_ZPMI,
      P.FUNC_PAR,
	  P.VKORG
	order by produto

/* 16/12/21 - 
with   
  W_CUSTO_ZFAT as (SELECT
	                 cast(MANDT as integer) as MANDT,
	                 TABELA,
	                 ESCALA,
	                 UF,
	                 '1005' as VKORG,
	                 CANAL,
	                 CLIENTE,
	                 REDE,
	                 DATA,
 	                 VALIDADE,
                     PRODUTO,
	                 VALOR,
	                 QTDMIN,
	                 CODIGO,
	                 '' as CLASSE, 
	                 "ID_DISTRIBUIDORA" 
                   FROM `dados-dev.visoes_auxiliares_cimed_tech.CV_A937_MATERIAL`
                   where tabela = 'ZFAT'
  ),
  W_508_VKORG_MATERIAL as (  SELECT 
								a.mandt, 
								b.kschl as tabela,  
								''      as escala, 
								''      as uf, 
								b.vkorg, 
								''      as canal,
								''      as cliente, 
								''      as rede, 
								b.datab as data, 
								b.datbi as validade,	
								cast(cast(b.matnr as integer) as string) as produto,  
								a.kbetr as valor, 
								a.kpein as qtdmin,
                                b.kschl as codigo, 
								i.id    AS id_distribuidora
							FROM `dados-dev.raw.KONP` AS a 
 							left JOIN `dados-dev.raw_cimed_tech.A508` AS b
	     					  ON a.knumh = b.knumh   
							left JOIN `dados-dev.raw.YDSD218` AS i
							  ON i.vkorg = b.vkorg	
							WHERE a.loevm_ko <> 'X' -- marcado para exclusão
							  AND (current_date between PARSE_DATE("%Y%m%d",b.datab) AND PARSE_DATE("%Y%m%d",b.datbi))
							  and a.mandt = '500'  
							  And b.kschl in ('ZSTA', 'ZPTL', 'ZPMI')
							ORDER BY
							   b.kschl, 
							   b.vkorg, 
							   data, 
							   validade, 
							   produto

  ),
  W_A508_ZQCO_VKORG_MATERIAL as (SELECT
                                   b.vkorg, 
	                               cast(cast(b.matnr as integer) as string) as produto,
	                               cast(c.kbetr/10 as int64) as faixa, 
                                   cast(c.kstbm as integer) as qtdmin
                                 FROM `dados-dev.raw.KONP` AS a
                                 JOIN `dados-dev.raw_cimed_tech.A508` AS b
	                               ON a.knumh = b.knumh
                                 JOIN `dados-dev.raw_cimed_tech.KONM` AS c
	                               ON a.knumh = c.knumh
                                 JOIN `dados-dev.raw.YDSD218` AS i
	                               ON i.vkorg = b.vkorg
                                 WHERE a.loevm_ko <> 'X' -- marcado para exclusão
	                               AND (current_date between PARSE_DATE("%Y%m%d",b.datab) AND PARSE_DATE("%Y%m%d",b.datbi))
	                               and a.mandt = '500'
	                               And b.kschl in ('ZQCO')
                                 ORDER BY
	                               vkorg, 
                                   produto, 
                                   faixa 
  ),
  W_A954_955_ZPFA_ZPMC as (select
							 q.tabela, 
							 q.produto, 
							 q.valor, 
							 q.lista, 
							 j.SHIPFROM, 
							 Y218.VKORG
						   from (SELECT 
		                           b.kschl as tabela, 
								   cast(cast(b.matnr as integer) as string) as produto, 
								   a.kbetr as valor, 
								   case 
									 when b.PLTYP = '97' then '17.5'
									 else b.PLTYP
								   end as LISTA
								 FROM `dados-dev.raw.KONP` AS a 
								 left JOIN `dados-dev.raw_cimed_tech.A954` AS b
								   ON a.knumh = b.knumh
								 WHERE a.loevm_ko <> 'X' -- marcado para exclusão
								   AND (current_date between PARSE_DATE("%Y%m%d",b.datab) AND PARSE_DATE("%Y%m%d",b.datbi))
								   and a.mandt = '500'  
								   and b.kschl in ('ZPFA')
								 union all
								 SELECT 
									b.kschl as tabela, 
									cast(cast(b.matnr as integer) as string) as produto,
									a.kbetr as valor,
									b.PLTYP as LISTA
								 FROM `dados-dev.raw.KONP` AS a 
								 left JOIN `dados-dev.raw_cimed_tech.A955` AS b
								   ON a.knumh = b.knumh   
								 WHERE a.loevm_ko <> 'X' -- marcado para exclusão
								   AND (current_date between PARSE_DATE("%Y%m%d",b.datab) AND PARSE_DATE("%Y%m%d",b.datbi))
								   and a.mandt = '500'  
								   and b.kschl in ('ZPMC')	
								) q
						   join	`dados-dev.raw_cimed_tech.J_1BTXIC1` J
						     ON J.RATE  = cast(q.LISTA as numeric)
						   JOIN	(SELECT 
						           SHIPFROM, 
								   Min(VALIDFROM) AS VALIDFROM
								 FROM `dados-dev.raw_cimed_tech.J_1BTXIC1`
								 WHERE SHIPFROM=SHIPTO
								  -- AEO 07.12.21 AND specf_rate = 0
								 GROUP BY SHIPFROM	
								) U	
						     ON U.SHIPFROM = J.SHIPFROM
						    AND U.VALIDFROM = J.VALIDFROM	
						   join `dados-dev.raw.YDSD218` Y218
							 ON Y218.UF = J.SHIPFROM
						   WHERE PARSE_DATE("%Y%m%d",cast((cast(99999999 as int64) - cast(J.validfrom as int64)) as string)) <= current_date
							 AND J.LAND1 = 'BR'
							 AND J.SHIPFROM = J.SHIPTO
 )


SELECT
		P.produto, 
        P.perc_comis, 
        ZPFA.VALOR as v_zpfa, 
        ZPMC.VALOR as v_zpmc, 
        P.v_zfat, 
		P.v_zsta, 
        v_zptl, 
        v_zpmi,
		sum(P.valor_p)  as valor_p, 
        sum(P.valor_m)  as valor_m, 
        sum(P.valor_g)  as valor_g, 
		sum(P.valor_g1) as valor_g1, 
        sum(P.valor_g2) as valor_g2, 
		sum(P.QDE_P)    as qde_p, 
        sum(P.qde_m)    as qde_m, 
        sum(P.qde_g)    as qde_g, 
		sum(P.qde_g1)   as qde_g1, 
        sum(P.qde_g2)   as qde_g2,
		P.FUNC_PAR as func_par,
		P.VKORG as vkorg
	from 
		(
		SELECT
			PMG.produto, 
			PMG.perc_comis,
			ZFAT.VALOR AS V_ZFAT,
			ZSTA.VALOR AS V_ZSTA,
			ZPTL.VALOR AS V_ZPTL,
			ZPMI.VALOR AS V_ZPMI,			
			case
				when PMG.faixa = 5 then round(((ZFAT.VALOR / (1 - PMG.valor/100)) + ZSTA.VALOR),2)
				else 0
			end as VALOR_P,
			case
				when PMG.faixa = 4 then round(((ZFAT.VALOR / (1 - PMG.valor/100)) + ZSTA.VALOR),2)
				else 0
			end as VALOR_M,	
			case
				when PMG.faixa = 3 then round(((ZFAT.VALOR / (1 - PMG.valor/100)) + ZSTA.VALOR),2)
				else 0
			end as VALOR_G,	
			case
				when PMG.faixa = 2 then round(((ZFAT.VALOR / (1 - PMG.valor/100)) + ZSTA.VALOR),2)
				else 0
			end as VALOR_G1,	
			case
				when PMG.faixa = 1 then round(((ZFAT.VALOR / (1 - PMG.valor/100)) + ZSTA.VALOR),2)
				else 0
			end as VALOR_G2,			
			case
				when PMG.faixa = 5 then COALESCE(ZQ.QTDMIN, 1)
				else 0
			end as QDE_P,		
			case
				when PMG.faixa = 4 then COALESCE(ZQ.QTDMIN, 1)
				else 0
			end as QDE_M, 
			case
				when PMG.faixa = 3 then COALESCE(ZQ.QTDMIN, 1)
				else 0
			end as QDE_G, 
			case
				when PMG.faixa = 2 then COALESCE(ZQ.QTDMIN, 1)
				else 0
			end as QDE_G1, 
			case
				when PMG.faixa = 1 then COALESCE(ZQ.QTDMIN, 1)
				else 0
			end as QDE_G2, 
			PMG.VKORG, PMG.FUNC_PAR
		FROM
			(	
			SELECT
				ROW_NUMBER() OVER
				(PARTITION BY b.matnr
					order by b.matnr, k.kstbm) as faixa, 				
				cast(cast(b.matnr as integer) as string) as produto,     
			    k.kstbm as valor, 
			    -- retirado para nao atrapalhar a api
				-- em caso de cadastr de comissao antigo
				-- round((k.kbetr/10),2) as perc_comis, 
			    0 as perc_comis, 
			    b.vkorg, 
                b.WTY_V_PARVW as FUNC_PAR
			FROM `dados-dev.raw.KONP` as a 
			INNER JOIN dados-dev.raw_cimed_tech.A996 AS b
				ON a.knumh = b.knumh
				AND a.mandt = b.mandt
			INNER JOIN `dados-dev.raw_cimed_tech.KONM` as k
				on k.mandt = b.mandt
				AND k.knumh = b.knumh
			WHERE a.loevm_ko <> 'X' -- marcado para exclusão
		      AND (current_date between PARSE_DATE("%Y%m%d",b.datab) AND PARSE_DATE("%Y%m%d",b.datbi))
				--AND b.vkorg = '3000' AND b.WTY_V_PARVW = 'Y1'
			ORDER BY
				b.matnr, faixa desc
			) PMG		
		JOIN W_CUSTO_ZFAT ZFAT
			ON ZFAT.produto = PMG.produto
		LEFT JOIN 
			W_508_VKORG_MATERIAL ZSTA
			ON ZSTA.VKORG = PMG.VKORG
			AND ZSTA.PRODUTO = PMG.PRODUTO	
			AND ZSTA.TABELA IN( 'ZSTA')
		LEFT JOIN 
			W_508_VKORG_MATERIAL ZPMI
			ON ZPMI.VKORG = PMG.VKORG
			AND ZPMI.PRODUTO = PMG.PRODUTO	
			AND ZPMI.TABELA IN( 'ZPMI')			
		LEFT JOIN 
			W_508_VKORG_MATERIAL ZPTL
			ON ZPTL.VKORG = PMG.VKORG
			AND ZPTL.PRODUTO = PMG.PRODUTO	
			AND ZPTL.TABELA = 'ZPTL'
		LEFT JOIN W_A508_ZQCO_VKORG_MATERIAL ZQ
			ON ZQ.VKORG = PMG.VKORG
			AND ZQ.PRODUTO = PMG.PRODUTO
			AND ZQ.FAIXA = PMG.FAIXA
		) as P
	join `dados-dev.raw.YDSD218` y218
	  on y218.vkorg = P.VKORG
		--on y218.vkorg = '3000'
	JOIN W_A954_955_ZPFA_ZPMC ZPFA
	  ON ZPFA.PRODUTO = P.PRODUTO
 	 AND ZPFA.SHIPFROM = y218.UF
	 AND ZPFA.TABELA = 'ZPFA'
	LEFT JOIN W_A954_955_ZPFA_ZPMC ZPMC
	  ON ZPMC.PRODUTO = P.PRODUTO
  	 AND ZPMC.SHIPFROM = y218.UF
	 AND ZPMC.TABELA = 'ZPMC'
	group by
	  P.produto, 
      P.perc_comis, 
      ZPFA.VALOR, 
      ZPMC.VALOR, 
	  P.V_ZFAT, 
      P.V_ZSTA,
      P.V_ZPTL,
      P.V_ZPMI,
      P.FUNC_PAR,
	  P.VKORG
	order by produto		
	*/