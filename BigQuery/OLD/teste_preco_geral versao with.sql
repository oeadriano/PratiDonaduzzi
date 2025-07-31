with gama_auto as (
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
),
a996 as (
        SELECT	
			b.matnr, k.kstbm, k.kbetr, b.vkorg, b.WTY_V_PARVW
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
        where
            a.loevm_ko <> 'X' 
            AND (current_date between PARSE_DATE("%Y%m%d",b.datab) AND PARSE_DATE("%Y%m%d",b.datbi))                     
        )
SELECT
    ROW_NUMBER() OVER
    (PARTITION BY b.matnr
        order by b.matnr, b.kstbm)-3 as faixa, 				
    cast(cast(b.matnr as integer) as string) as produto,     
    b.kstbm as valor, round((b.kbetr/10),2) as perc_comis, 
    LJ.*
FROM 
    a996 as b
join 
    (
--------------        
    select 
        g.cod_gama, l.descricao, l.vtweg, 
        G.bukrs, g.werks, g.vkorg, y94.func_par, lf.kunnr, lf.lifnr
    from
        gama_auto as G
    join                			 
        `dados-dev.raw_cimed_tech.LIFNR_CLIENTE_T` as LF
        ON LF.LIFNR = G.LIFNR	
        AND LF.VKORG = G.VKORG
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
) LJ
    ON LJ.vkorg = b.vkorg
	AND LJ.FUNC_PAR =  b.WTY_V_PARVW 		
--WHERE 
    a.loevm_ko <> 'X' -- marcado para exclusão
    -- AND (current_date between b.datab AND b.datbi) -- mudei
    AND (current_date between PARSE_DATE("%Y%m%d",b.datab) AND PARSE_DATE("%Y%m%d",b.datbi))
    --and k.kstbm > 2 -- gambiarra para mostrar somente 3 faixas
ORDER BY
    b.matnr, b.kstbm
