-- CV_VIEW_LIFNR_CLIENTE

WITH Y255 AS
    (	
	SELECT DISTINCT LIFNR 
	FROM dados-dev.raw_cimed_tech.YDSD225
	WHERE LIFNR like 'H%' AND ATIVO = 'S' 
    )
SELECT 
	DISTINCT K.VKORG, K.KUNNR, T3.LIFN2 AS LIFNR
FROM
	dados-dev.raw.KNVP K
JOIN dados-dev.raw.WYT3 T3
	ON T3.LIFNR = K.LIFNR
	AND T3.EKORG = '1000'
	AND T3.PARVW = 'Y1'
	AND T3.DEFPA = 'X'
JOIN Y255
    ON Y255.LIFNR = T3.LIFNR    
JOIN 
	dados-dev.raw.KNKK as knkk
    on knkk.kunnr  = K.kunnr 
    and knkk.mandt = K.mandt	
join dados-dev.raw.KNA1 as kna1
	on kna1.kunnr = knkk.kunnr
WHERE 
	K.PARVW = 'Y1'
	--T3.LIFNR IN 
	--(
	--SELECT DISTINCT LIFNR 
	--FROM dados-dev.raw_cimed_tech.YDSD225
	--WHERE LIFNR like 'H%' AND ATIVO = 'S'
	--) 
	-- AEO 03/03/20 - ZMCG 900610
	-- ENVIA SOMENTE CLIENTES QUE TEM CLASSE DE RISCO PREENCHIDA	
	AND coalesce(knkk.ctlpc, '') <> '' 
	/*AEO 15.04.2020 - ZMEL 301973*/ 	
	and (kna1.aufsd <> '01')
	and K.VKORG <> '1100'