create table `dados-dev.visoes_auxiliares_cimed_tech.teste_preco_geral_t` as (select * from `dados-dev.visoes_auxiliares_cimed_tech.teste_preco_geral`)

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
				G.bukrs, g.werks, g.vkorg, y94.func_par, lf.kunnr, lf.lifnr
			from ( 
				SELECT 
					DISTINCT
						A.BUKRS, A.WERKS, A.COD_GAMA, cast(T3.LIFN2 as string) AS LIFNR, I.ID, i.vkorg 
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
					and a.werks <> '1100' 
				) AS G
			JOIN 
                `dados-dev.raw.YDSD218` as y218
                on y218.werks = g.werks
            join                
			( 
				SELECT 
					DISTINCT K.VKORG, K.KUNNR, T3.LIFN2 AS LIFNR
				FROM
					dados-dev.raw.KNVP K
				JOIN 
					dados-dev.raw.WYT3 T3
					ON T3.LIFNR = K.LIFNR
					AND T3.EKORG = '1000'
					AND T3.PARVW = 'Y1'
					AND T3.DEFPA = 'X'	
				join 
					dados-dev.raw.KNKK as knkk
					on knkk.kunnr  = K.kunnr 
					and knkk.mandt = K.mandt	
				join dados-dev.raw.KNA1 as kna1
					on kna1.kunnr = knkk.kunnr
				WHERE 
					K.PARVW = 'Y1' AND
					T3.LIFNR IN 
					(
					SELECT DISTINCT LIFNR 
					FROM dados-dev.raw_cimed_tech.YDSD225
					WHERE LIFNR like 'H%' AND ATIVO = 'S'
					) 
					-- AEO 03/03/20 - ZMCG 900610
					-- ENVIA SOMENTE CLIENTES QUE TEM CLASSE DE RISCO PREENCHIDA	
					AND coalesce(knkk.ctlpc, '') <> ''
					-- /AEO 15.04.2020 - ZMEL 301973/ 	
					and (kna1.aufsd <> '01')
					and K.VKORG <> '1100' 
			) AS LF
				ON LF.LIFNR = G.LIFNR	
				AND LF.VKORG = y218.VKORG
			join 
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
			--where 
--				g.lifnr = :IP_LIFNR and lf.kunnr = :IP_CLIENTE	
				--g.lifnr = '0000600037' and lf.kunnr = '0001009136'						 
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
