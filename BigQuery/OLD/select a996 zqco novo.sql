with w_konp as (
    select knumh 
    from dados-dev.raw.KONP
    where mandt = '500'
    and loevm_ko <> 'X' -- marcado para exclusao
),
w_konm as (
    select kbetr, kstbm, knumh
    from dados-dev.raw_cimed_tech.KONM
),
w_a709 as (
    SELECT 
        i.vkorg, b.matnr as produto, cast(c.kbetr/10 as integer) as faixa, cast(c.kstbm as integer) as qtdmin
    FROM 
        w_konp AS a
    JOIN dados-dev.raw_cimed_tech.A709 AS b
        ON a.knumh = b.knumh
    JOIN w_konm AS c
        ON a.knumh = c.knumh
    CROSS JOIN dados-dev.raw.YDSD218 AS i
    WHERE (current_date between PARSE_DATE("%Y%m%d",b.datab) AND PARSE_DATE("%Y%m%d",b.datbi))        
        And b.kschl in ('ZQCO')
), 
w_a508 as (
    SELECT 
        b.vkorg, b.matnr as produto, cast(c.kbetr/10 as integer) as faixa, cast(c.kstbm as integer) as qtdmin
    FROM 
        w_konp AS a
    JOIN dados-dev.raw_cimed_tech.A508 AS b
        ON a.knumh = b.knumh
    JOIN w_konm AS c
        ON a.knumh = c.knumh
    JOIN dados-dev.raw.YDSD218 AS i
        ON i.vkorg = b.vkorg
    WHERE 
        b.kschl in ('ZQCO')
        AND (current_date between PARSE_DATE("%Y%m%d",b.datab) AND PARSE_DATE("%Y%m%d",b.datbi))
)
select 
    VKORG, PRODUTO, FAIXA, QTDMIN 
FROM 
    w_a508
union all 
(
select *
from w_a709
except distinct
    select 
        *
    FROM 
        w_a508    
)




/*

-- "_SYS_BIC"."VISAO/CV_A508_A709_ZQCO" ZQ	
	select 
		VKORG, PRODUTO, FAIXA, QTDMIN 
	FROM 
	   (select VKORG, PRODUTO, FAIXA, QTDMIN 
		from ( SELECT i.vkorg, 
                      b.matnr as produto,
                      cast(c.kbetr/10 as integer) as faixa, cast(c.kstbm as integer) as qtdmin
                 FROM dados-dev.raw.KONP AS a
                 JOIN dados-dev.raw_cimed_tech.A709 AS b
                   ON a.knumh = b.knumh
                 JOIN dados-dev.raw_cimed_tech.KONM AS c
                   ON a.knumh = c.knumh
                 CROSS JOIN	dados-dev.raw.YDSD218 AS i
                 WHERE a.loevm_ko <> 'X' -- marcado para exclusão
                   AND (current_date between PARSE_DATE("%Y%m%d",b.datab) AND PARSE_DATE("%Y%m%d",b.datbi))
                   and a.mandt = '500'
                   And b.kschl in ('ZQCO')
                 ORDER BY vkorg, produto, faixa
             )
		where
			VKORG||PRODUTO not in 
			(SELECT DISTINCT b.vkorg || b.matnr as produto,
                 FROM dados-dev.raw.KONP AS a
                 JOIN dados-dev.raw_cimed_tech.A508 AS b
                   ON a.knumh = b.knumh
                 JOIN dados-dev.raw.YDSD218 AS i
                   ON i.vkorg = b.vkorg
                 WHERE a.loevm_ko <> 'X' -- marcado para exclusão
                   AND (current_date between PARSE_DATE("%Y%m%d",b.datab) AND PARSE_DATE("%Y%m%d",b.datbi))
                   and a.mandt = '500'
                   And b.kschl in ('ZQCO') )
		union all
		-- todos os produtos da chave vkorg
		select 
			VKORG, PRODUTO, FAIXA, QTDMIN 
		from ( SELECT b.vkorg, 
                      b.matnr as produto,
                      cast(c.kbetr/10 as integer) as faixa, cast(c.kstbm as integer) as qtdmin
                 FROM dados-dev.raw.KONP AS a
                 JOIN dados-dev.raw_cimed_tech.A508 AS b
                   ON a.knumh = b.knumh
                 JOIN dados-dev.raw_cimed_tech.KONM AS c
                   ON a.knumh = c.knumh
                 JOIN dados-dev.raw.YDSD218 AS i
                   ON i.vkorg = b.vkorg
                 WHERE a.loevm_ko <> 'X' -- marcado para exclusão
                   AND (current_date between PARSE_DATE("%Y%m%d",b.datab) AND PARSE_DATE("%Y%m%d",b.datbi))
                   and a.mandt = '500'
                   And b.kschl in ('ZQCO')
                 ORDER BY vkorg, produto, faixa 
		      )
		) 
		
		*/