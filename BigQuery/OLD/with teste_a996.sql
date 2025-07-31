-- 20,6 s - 190,3MB
WITH
  gama AS (
  SELECT
    y218.vkorg,
    y225.lifn2 AS lifnr,
    t3.parvw AS func_par
  FROM
    `dados-dev.raw_cimed_tech.YDSD225` AS y225
  JOIN
    `dados-dev.raw.YDSD218` AS y218
  ON
    y218.werks = y225.werks
  JOIN
    `dados-dev.raw.WYT3` AS t3
  ON
    T3.lifnr = y225.lifnr
    AND T3.ekorg = '1000'
    AND T3.parvw = 'Y1'
    AND T3.defpa = 'X'
  WHERE
    y225.ativo = 'S'
    AND coalesce(T3.LIFN2,
      '') <> ''
    AND y218.werks <> '1100' )
SELECT
  ROW_NUMBER() OVER (PARTITION BY b.matnr ORDER BY b.matnr, k.kstbm)-3 AS faixa,
  CAST(CAST(b.matnr AS integer) AS string) AS produto,
  k.kstbm AS valor,
  ROUND((k.kbetr/10),2) AS perc_comis,
  g.lifnr,
  g.vkorg,
  g.func_par
FROM
  dados-dev.raw.KONP AS a
INNER JOIN
  dados-dev.raw_cimed_tech.A996 AS b
ON
  a.knumh = b.knumh
  AND a.mandt = b.mandt
INNER JOIN
  GAMA AS g
ON
  g.vkorg = b.vkorg
  AND g.func_par = b.WTY_V_PARVW
INNER JOIN
  dados-dev.raw_cimed_tech.KONM AS k
ON
  k.mandt = b.mandt
  AND k.knumh = b.knumh

-- 58,6s - 190,3MB

SELECT
  ROW_NUMBER() OVER (PARTITION BY b.matnr ORDER BY b.matnr, k.kstbm)-3 AS faixa,
  CAST(CAST(b.matnr AS integer) AS string) AS produto,
  k.kstbm AS valor,
  ROUND((k.kbetr/10),2) AS perc_comis, lj.*
FROM
  dados-dev.raw.KONP AS a
INNER JOIN
  dados-dev.raw_cimed_tech.A996 AS b
ON
  a.knumh = b.knumh
  AND a.mandt = b.mandt
INNER JOIN
  dados-dev.raw_cimed_tech.KONM AS k
ON
  k.mandt = b.mandt
  AND k.knumh = b.knumh
join (
  SELECT
    y218.vkorg,
    y225.lifn2 AS lifnr,
    t3.parvw AS func_par
  FROM
    `dados-dev.raw_cimed_tech.YDSD225` AS y225
  JOIN
    `dados-dev.raw.YDSD218` AS y218
  ON
    y218.werks = y225.werks
  JOIN
    `dados-dev.raw.WYT3` AS t3
  ON
    T3.lifnr = y225.lifnr
    AND T3.ekorg = '1000'
    AND T3.parvw = 'Y1'
    AND T3.defpa = 'X'
  WHERE
    y225.ativo = 'S'
    AND coalesce(T3.LIFN2,
      '') <> ''
    AND y218.werks <> '1100' 
) LJ
		ON LJ.vkorg = b.vkorg
			AND LJ.FUNC_PAR =  b.WTY_V_PARVW 	
