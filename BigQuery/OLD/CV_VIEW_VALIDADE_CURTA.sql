with w_44_218 as (
	select 
        y218.vkorg, y218.werks, y44.lgort, y44.meses
	from 
        dados-dev.raw.YDSD218 y218
	join 
        dados-dev.raw_cimed_tech.YDSD044 y44
        on y44.werks = y218.werks
)
select 
	z.vkorg,
	z.matnr as produto,
	z.kbetr as valor
    ,sum(e.qtutil_livre) AS saldo
from (
	with w_konp as 
	(
		select 
			mandt, knumh, kbetr, kpein
		from 
			dados-dev.raw.KONP
		where 
			kschl IN('ZCO2','ZQCO', 'ZPTL')
			and loevm_ko <> 'X'
	),
	w_a850 as
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
	
/* ORIGINAL 	
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
		on E.MATERIAL = Z.PRODUTO
		and E.CENTRO = Y44.WERKS
		and E.DEPOSITO = Y44.LGORT
	where
		Z.TP_DOC = 'ZV12'
		AND E.DIASAVENCER <= (CAST(Y44.MESES AS float64) * 30)
	group by
		z.VKORG, z.PRODUTO, z.VALOR

ORDER BY produto

*/