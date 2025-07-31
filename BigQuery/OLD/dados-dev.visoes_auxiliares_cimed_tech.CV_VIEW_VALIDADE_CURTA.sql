------------------------------------------------------------------------------------
	SELECT
		PRODUTO, VALOR, SALDO, VKORG
	FROM 
		dados-dev.visoes_auxiliares_cimed_tech.CV_VIEW_VALIDADE_CURTA
	) VC
	ON VC.VKORG = P.VKORG 
	
------------------------------------------------------------------------------------	
-- CV_VIEW_VALIDADE_CURTA

SELECT
		z.vkorg,
		z.produto,
		z.valor, 
		sum(e.qtutil_livre) AS saldo
	FROM 
		dados-dev.visoes_auxiliares_cimed_tech.CV_A850_TPDOC_VKORG_MATERIAL Z
	join
		dados-dev.raw.YDSD218 y218
		on y218.vkorg = z.vkorg
	join
		dados-dev.raw_cimed_tech.YDSD044 y44
		on y44.werks = y218.werks
	join 
		dados-dev.visoes_auxiliares_cimed_tech.CV_ESTOQUE_LOTES_MCH1_MCHB_INF_06MESES E
		on SUBSTRING(E.MATERIAL, 13, 6) = Z.PRODUTO
		and E.CENTRO = Y44.WERKS
		and E.DEPOSITO = Y44.LGORT
	where
		Z.TP_DOC = 'ZV12'
		AND E.DIASAVENCER <= (CAST(Y44.MESES AS float64) * 30)
	group by
		z.VKORG, z.PRODUTO, z.VALOR

ORDER BY produto	
------------------------------------------------------------------------------------		
--CV_A850_TPDOC_VKORG_MATERIAL
- dados-dev.visoes_auxiliares_cimed_tech.CV_A850_TPDOC_VKORG_MATERIAL Z
SELECT
	a.mandt, b.kschl AS tabela, '' AS escala, '' AS uf, b.vkorg, '' AS canal, '' AS cliente, '' AS rede, b.datab AS data, b.datbi AS validade, CAST(CAST(b.matnr AS integer) AS string) AS produto, a.kbetr AS valor, a.kpein AS qtdmin, b.kschl AS codigo, b.AUART_SD AS tp_doc, i.id AS id_distribuidora
FROM
	dados-dev.raw.KONP AS a
	LEFT JOIN
		dados-dev.raw_cimed_tech.A850 AS b
		ON
			a.knumh = b.knumh
	LEFT JOIN
		dados-dev.raw.YDSD218 AS i
		ON
			i.vkorg = b.vkorg
WHERE
	a.loevm_ko <> 'X' -- marcado para exclusão
	AND current_date BETWEEN PARSE_DATE("%Y%m%d",b.datab) AND PARSE_DATE("%Y%m%d",b.datbi)
	AND a.mandt = '500'
	AND b.kschl IN ('ZPTL')
ORDER BY
	b.kschl, b.vkorg, DATA, validade, produto
;

