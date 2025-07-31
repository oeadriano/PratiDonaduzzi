---------------------------------------------------------------------------------------------------------
SELECT
	ROW_NUMBER() OVER
	(PARTITION BY b.matnr
		order by b.matnr, k.kstbm)-3 as faixa, 				
	cast(cast(b.matnr as integer) as nvarchar) as produto,     
	k.kstbm as valor , round( (k.kbetr/10), 2, ROUND_HALF_UP ) as perc_comis
FROM 
	konp AS a 
INNER JOIN 
	A996 AS b
	ON a.knumh = b.knumh
	AND a.mandt = b.mandt
INNER JOIN 
	KONM as k
	on k.mandt = b.mandt
	AND k.knumh = b.knumh
WHERE
	a.loevm_ko <> 'X' -- marcado para exclusão
	AND (current_date between b.datab AND b.datbi)	
---------------------------------------------------------------------------------------------------------
SELECT 
	a.mandt, b.kschl as tabela, '' as escala, '' as uf, '' as vkorg, 
	'' as canal, '' as cliente, '' as rede, b.datab as data, 
	b.datbi as validade, cast(cast(b.matnr as integer) as nvarchar) as produto, a.kbetr as valor, 
	a.kpein as qtdmin, b.kschl as codigo, 99 as id_distribuidora
FROM 
	konp AS a 
left JOIN a937 AS b
	ON a.knumh = b.knumh
WHERE 
	a.loevm_ko <> 'X' -- marcado para exclusão
	AND (current_date between b.datab AND b.datbi)
	and a.mandt = '500'

---------------------------------------------------------------------------------------------------------
SELECT 
	a.mandt, b.kschl as tabela,  '' as escala, '' as uf, b.vkorg, '' as canal,
	'' as cliente, '' as rede, b.datab as data, b.datbi as validade,	
	cast(cast(b.matnr as integer) as nvarchar) as produto,  a.kbetr as valor, a.kpein as qtdmin,
    b.kschl as codigo, i.id AS id_distribuidora
FROM konp AS a 
left JOIN A508 AS b
	ON a.knumh = b.knumh   
left JOIN 
	YDSD218 AS i
	ON i.vkorg = b.vkorg	
WHERE 
	a.loevm_ko <> 'X' -- marcado para exclusão
	AND (current_date between b.datab AND b.datbi)
	and a.mandt = '500'
---------------------------------------------------------------------------------------------------------	
SELECT
	i.vkorg, 
	cast(cast(b.matnr as integer) as nvarchar) as produto,
	cast(c.kbetr/10 as integer) as faixa, cast(c.kstbm as integer) as qtdmin
FROM
	konp AS a
JOIN A709 AS b
	ON a.knumh = b.knumh
JOIN konm AS c
	ON a.knumh = c.knumh
CROSS JOIN
	YDSD218 AS i
WHERE
	a.loevm_ko <> 'X' -- marcado para exclusão
	AND (current_date between b.datab AND b.datbi)
	and a.mandt = '500'
ORDER BY
	vkorg, produto, faixa	
---------------------------------------------------------------------------------------------------------	
SELECT 
	b.kschl as tabela, cast(cast(b.matnr as integer) as nvarchar) as produto, 
	a.kbetr as valor, b.PLTYP as LISTA
FROM 
	konp AS a 
left JOIN A954 AS b
	ON a.knumh = b.knumh
WHERE 
	a.loevm_ko <> 'X' -- marcado para exclusão
	AND (current_date between b.datab AND b.datbi)
	and a.mandt = '500'  
---------------------------------------------------------------------------------------------------------
SELECT 
	b.kschl as tabela, cast(cast(b.matnr as integer) as nvarchar) as produto,
	a.kbetr as valor, b.PLTYP as LISTA
FROM 
	konp AS a 
left JOIN A955 AS b
	ON a.knumh = b.knumh   
WHERE 
	a.loevm_ko <> 'X' -- marcado para exclusão
	AND (current_date between b.datab AND b.datbi)
	and a.mandt = '500'
	