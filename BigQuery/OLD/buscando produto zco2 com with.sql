with q as (
  SELECT
    ROW_NUMBER() OVER (PARTITION BY b.matnr order by b.vkorg, b.wty_v_parvw, b.matnr )-3 AS faixa,
    CAST(CAST(b.matnr AS integer) AS string) AS produto,
    k.kstbm AS valor, ROUND((k.kbetr/10),2) AS perc_comis, 
    b.vkorg, b.wty_v_parvw
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
  where  
      b.kschl = 'ZCO2'
      AND (current_date between PARSE_DATE("%Y%m%d",b.datab) AND PARSE_DATE("%Y%m%d",b.datbi))
      --and vkorg in('4500')
      --and b.wty_v_parvw = 'Y1'
  ORDER BY
      b.vkorg, b.WTy_v_parvw, b.matnr, k.kbetr
)
select  distinct produto
from q
where faixa > 2