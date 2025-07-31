create table dados-dev.visoes_cimed_tech.A996_LOJAS_ZCO2_T as 
(
select * 
from dados-dev.visoes_cimed_tech.A996_LOJAS_ZCO2
order by 
	vkorg, func_par, produto, faixa
)

with w_konp as (
	select 
		mandt, knumh, from dados-dev.raw.KONP
	where 
		kschl IN('ZCO2','ZQCO')
		and loevm_ko <> 'X'
),
w_a996 as (
    select 
        mandt, knumh, vkorg, wty_v_parvw, matnr
    from 
        dados-dev.raw_cimed_tech.A996
    where 
        kschl in ('ZCO2', 'ZQCO')
        AND (current_date between PARSE_DATE("%Y%m%d",datab) AND PARSE_DATE("%Y%m%d",datbi))
)

    SELECT
        ROW_NUMBER() OVER (PARTITION BY b.vkorg, b.wty_v_parvw, b.matnr order by b.vkorg, b.wty_v_parvw, b.matnr, k.kbetr )-3 AS faixa,
        b.matnr as produto,
        k.kstbm AS valor, ROUND((k.kbetr/10),2) AS perc_comis, 
        b.vkorg, b.wty_v_parvw as func_par
    FROM
        w_konp AS a
    INNER JOIN
        w_a996 AS b    
        ON a.knumh = b.knumh
        AND a.mandt = b.mandt
    INNER JOIN
        dados-dev.raw_cimed_tech.KONM AS k
    
        ON k.mandt = b.mandt
        AND k.knumh = b.knumh     															
    --ORDER BY