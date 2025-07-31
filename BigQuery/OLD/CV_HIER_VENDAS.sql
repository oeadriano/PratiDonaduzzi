X1	Consultor
X5	Empresa Represent.
Y1	Representante
Y2	Supervisor
Y3	Distrital
Y4	Regional
Y5	Divisional/Nacional
Y6	Diretoria


--CV_HIER_VENDAS --
SELECT
	Q1.*
FROM
	(
		SELECT
			CAD1.mandt ,CAD1.ID_CADEIRA_Y1 AS id_cadeira ,CAD1N.N_CADEIRA_Y1 AS n_cadeira ,CAD1.SITUACAO_CADEIRA AS situacao_cadeira ,
			CAD1.ID_REPRESENTANTE_Y1 AS id_Representante ,CAD1R.N_REPRESENTANTE_Y1 AS n_representante ,CAD2.id_cadeira_y2 ,CAD2N.n_cadeira_y2 ,REP2.id_representante_y2 ,REP2N.n_representante_y2 ,
			CAD3.id_cadeira_y3 ,CAD3N.n_cadeira_y3 ,REP3.id_representante_y3 ,REP3N.n_representante_y3 ,CAD4.id_cadeira_y4 ,CAD4N.n_cadeira_y4 ,REP4.id_representante_y4 ,REP4N.n_representante_y4 ,CAD5.id_cadeira_y5 ,CAD5N.n_cadeira_y5 ,REP5.id_representante_y5 ,REP5N.n_representante_y5 ,CAD6.id_cadeira_y6 ,CAD6N.n_cadeira_y6 ,REP6.id_representante_y6 ,REP6N.n_representante_y6
			--,ROW_NUMBER() OVER (PARTITION BY CAD1.ID_CADEIRA_Y1 ORDER BY CAD1.ID_CADEIRA_Y1 ) AS LINHA
			,ROW_NUMBER() OVER (PARTITION BY ID_REPRESENTANTE_Y1, CAD1.ID_CADEIRA_Y1 ORDER BY
								ID_REPRESENTANTE_Y1, CAD1.ID_CADEIRA_Y1 ) AS linha
		FROM
			(
				SELECT
					MANDT ,LIFN2 AS iD_rEPresentante_y1 ,LIFNR AS id_cadeira_y1 ,CASE
						WHEN DEFPA = 'X'
							THEN 'ATIVA'
							ELSE 'INATIVA'
					END AS situacao_cadeira
				FROM
					dados-dev.raw.WYT3
				WHERE
					PARVW = 'Y1'
					--AND DEFPA = 'X' -- pega a cadeira ativa somente ( mas dá problema em cobranca )
					--AND LIFNR LIKE 'H07_MG1__' --- para teste. DEPOIS TIRAR ISSO
			)
			AS CAD1
			LEFT JOIN
				(
					SELECT
						NAME1 AS n_cadeira_y1 ,LIFNR
					FROM
						dados-dev.raw.LFA1
				)
				AS CAD1N
				ON
					CAD1N.LIFNR = CAD1.ID_CADEIRA_Y1
			LEFT JOIN
				(
					SELECT
						NAME1 AS n_representante_y1 ,LIFNR
					FROM
						dados-dev.raw.LFA1
				)
				CAD1R
				ON
					CAD1R.LIFNR = CAD1.ID_REPRESENTANTE_Y1
			--****************************************************************
			LEFT JOIN
				(
					SELECT
						LIFN2 AS ID_CADEIRA_Y1 ,LIFNR AS ID_CADEIRA_Y2
					FROM
						dados-dev.raw.WYT3
					WHERE
						PARVW = 'Y1'
				)
				AS CAD2
				ON
					CAD2.ID_CADEIRA_Y1 = CAD1.ID_CADEIRA_Y1
			LEFT JOIN
				(
					SELECT
						NAME1 AS N_CADEIRA_Y2 ,LIFNR
					FROM
						dados-dev.raw.LFA1
				)
				AS CAD2N
				ON
					CAD2N.LIFNR = CAD2.ID_CADEIRA_Y2
			LEFT JOIN
				(
					SELECT
						LIFNR AS ID_CADEIRA_Y2 ,LIFN2 AS ID_REPRESENTANTE_Y2
					FROM
						dados-dev.raw.WYT3
					WHERE
						PARVW     = 'Y2'
						AND DEFPA = 'X'
				)
				AS REP2
				ON
					REP2.ID_CADEIRA_Y2 = CAD2.ID_CADEIRA_Y2
			LEFT JOIN
				(
					SELECT
						NAME1 AS n_representante_y2 ,LIFNR
					FROM
						dados-dev.raw.LFA1
				)
				AS REP2N
				ON
					REP2N.LIFNR = REP2.ID_REPRESENTANTE_Y2
			--****************************************************************
			LEFT JOIN -- 1 ESTE - LINK COM ID_CADEIRA ANTERIOR
				(
					SELECT
						LIFNR AS ID_CADEIRA_Y2 ,LIFN2 AS ID_CADEIRA_Y3
					FROM
						dados-dev.raw.WYT3
					WHERE
						PARVW = 'Y3'
				)
				AS CAD3
				ON
					CAD3.ID_CADEIRA_Y2 = CAD2.ID_CADEIRA_Y2
			LEFT JOIN
				(
					SELECT
						NAME1 AS n_cadeira_y3 ,LIFNR
					FROM
						dados-dev.raw.LFA1
				)
				AS CAD3N
				ON
					CAD3N.LIFNR = CAD3.ID_CADEIRA_Y3
			LEFT JOIN -- 2 ESTE - LINK COM ID_CADEIRA DESTE COM O DO 1
				(
					SELECT
						LIFNR AS ID_CADEIRA_Y3 ,LIFN2 AS ID_REPRESENTANTE_Y3
					FROM
						dados-dev.raw.WYT3
					WHERE
						PARVW     = 'Y3'
						AND DEFPA = 'X'
				)
				AS REP3
				ON
					REP3.ID_CADEIRA_Y3 = CAD3.ID_CADEIRA_Y3
			LEFT JOIN
				(
					SELECT
						NAME1 AS n_representante_y3 ,LIFNR
					FROM
						dados-dev.raw.LFA1
				)
				AS REP3N
				ON
					REP3N.LIFNR = REP3.ID_REPRESENTANTE_Y3
			--****************************************************************
			LEFT JOIN -- 1º ESTE - LINK COM ID_CADEIRA ANTERIOR
				(
					SELECT
						LIFNR AS ID_CADEIRA_Y3 ,LIFN2 AS ID_CADEIRA_Y4
					FROM
						dados-dev.raw.WYT3
					WHERE
						PARVW = 'Y4'
				)
				AS CAD4
				ON
					CAD4.ID_CADEIRA_Y3 = CAD3.ID_CADEIRA_Y3
			LEFT JOIN
				(
					SELECT
						NAME1 AS N_CADEIRA_Y4 ,LIFNR
					FROM
						dados-dev.raw.LFA1
				)
				AS CAD4N
				ON
					CAD4N.LIFNR = CAD4.ID_CADEIRA_Y4
			LEFT JOIN -- 2º ESTE - LINK COM ID_CADEIRA DESTE COM O DO 1
				(
					SELECT
						LIFNR AS ID_CADEIRA_Y4 ,LIFN2 AS ID_REPRESENTANTE_Y4
					FROM
						dados-dev.raw.WYT3
					WHERE
						PARVW     = 'Y4'
						AND DEFPA = 'X'
				)
				AS REP4
				ON
					REP4.ID_CADEIRA_Y4 = CAD4.ID_CADEIRA_Y4
			LEFT JOIN
				(
					SELECT
						NAME1 AS N_REPRESENTANTE_Y4 ,LIFNR
					FROM
						dados-dev.raw.LFA1
				)
				AS REP4N
				ON
					REP4N.LIFNR = REP4.ID_REPRESENTANTE_Y4
			--****************************************************************
			LEFT JOIN -- 1º ESTE - LINK COM ID_CADEIRA ANTERIOR
				(
					SELECT
						LIFNR AS ID_CADEIRA_Y4 ,LIFN2 AS ID_CADEIRA_Y5
					FROM
						dados-dev.raw.WYT3
					WHERE
						PARVW = 'Y5'
				)
				AS CAD5
				ON
					CAD5.ID_CADEIRA_Y4 = CAD4.ID_CADEIRA_Y4
			LEFT JOIN
				(
					SELECT
						NAME1 AS N_CADEIRA_Y5 ,LIFNR
					FROM
						dados-dev.raw.LFA1
				)
				AS CAD5N
				ON
					CAD5N.LIFNR = CAD5.ID_CADEIRA_Y5
			LEFT JOIN -- 2º ESTE - LINK COM ID_CADEIRA DESTE COM O DO 1
				(
					SELECT
						LIFNR AS ID_CADEIRA_Y5 ,LIFN2 AS ID_REPRESENTANTE_Y5
					FROM
						dados-dev.raw.WYT3
					WHERE
						PARVW     = 'Y5'
						AND DEFPA = 'X'
				)
				AS REP5
				ON
					REP5.ID_CADEIRA_Y5 = CAD5.ID_CADEIRA_Y5
			LEFT JOIN
				(
					SELECT
						NAME1 AS N_REPRESENTANTE_Y5 ,LIFNR
					FROM
						dados-dev.raw.LFA1
				)
				AS REP5N
				ON
					REP5N.LIFNR = REP5.ID_REPRESENTANTE_Y5
			--****************************************************************
			LEFT JOIN -- 1º ESTE - LINK COM ID_CADEIRA ANTERIOR
				(
					SELECT
						LIFNR AS ID_CADEIRA_Y5 ,LIFN2 AS ID_CADEIRA_Y6
					FROM
						dados-dev.raw.WYT3
					WHERE
						PARVW = 'Y6'
				)
				AS CAD6
				ON
					CAD6.ID_CADEIRA_Y5 = CAD5.ID_CADEIRA_Y5
			LEFT JOIN
				(
					SELECT
						NAME1 AS N_CADEIRA_Y6 ,LIFNR
					FROM
						dados-dev.raw.LFA1
				)
				AS CAD6N
				ON
					CAD6N.LIFNR = CAD6.ID_CADEIRA_Y6
			LEFT JOIN -- 2º ESTE - LINK COM ID_CADEIRA DESTE COM O DO 1
				(
					SELECT
						LIFNR AS ID_CADEIRA_Y6 ,LIFN2 AS ID_REPRESENTANTE_Y6
					FROM
						dados-dev.raw.WYT3
					WHERE
						PARVW     = 'Y6'
						AND DEFPA = 'X'
				)
				AS REP6
				ON
					REP6.ID_CADEIRA_Y6 = CAD6.ID_CADEIRA_Y6
			LEFT JOIN
				(
					SELECT
						NAME1 AS N_REPRESENTANTE_Y6 ,LIFNR
					FROM
						dados-dev.raw.LFA1
				)
				AS REP6N
				ON
					REP6N.LIFNR = REP6.ID_REPRESENTANTE_Y6
		ORDER BY
			CAD1.ID_CADEIRA_Y1
	)
	AS Q1
WHERE
	Q1.LINHA                       = 1
	AND Q1.ID_REPRESENTANTE NOT LIKE '%H%' -- PRA EVITAR ERRO DE CADASTRO
;

--END
/********* End Procedure Script ************/
