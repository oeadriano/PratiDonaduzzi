-- CV_VIEW_LIFNR_CLIENTE
WITH y225 AS (
	  
	SELECT DISTINCT y225.LIFNR, y225.cod_gama, y218.VKORG
	FROM dados-dev.raw_cimed_tech.YDSD225 y225
	JOIN `dados-dev.raw.YDSD218` AS Y218 ON Y218.WERKS = Y225.WERKS
	WHERE 
		y225.LIFNR like 'H%' 
		AND y225.ATIVO = 'S' 
		and y225.bukrs <> '1400'
		and y225.cod_gama in ('157', '158', '159')
)
SELECT 
	DISTINCT K.vkorg, K.kunnr, T3.LIFN2 AS lifnr, 
	T3.LIFNR AS cadeira, 
	CURRENT_TIMESTAMP() AS last_update
FROM
	dados-dev.raw.KNVP K -- ciente expandido
JOIN 
	dados-dev.raw.WYT3 T3 -- cadeira
	ON T3.LIFNR = K.LIFNR
	AND T3.EKORG = '1000'
	AND T3.PARVW = 'Y1'
	AND T3.DEFPA = 'X'	
join 
	y225 
	ON y225.LIFNR = T3.LIFNR	
		and y225.vkorg = k.vkorg
join
	dados-dev.raw.KNKK as knkk	
    on knkk.kunnr  = K.kunnr 
    and knkk.mandt = K.mandt	
join 
    dados-dev.raw.KNA1 as kna1
	on kna1.kunnr = knkk.kunnr

WHERE 
	K.PARVW = 'Y1'
	--T3.LIFNR IN 
	--(
	--SELECT DISTINCT LIFNR 
	--FROM dados-dev.raw_cimed_tech.YDSD225
	--WHERE LIFNR like 'H%' AND ATIVO = 'S'
	--) 	
	AND coalesce(knkk.ctlpc, '') <> ''
	/*AEO 15.04.2020 - ZMEL 301973*/ 	
	and (kna1.aufsd <> '01')
	and K.VKORG <> '1100'