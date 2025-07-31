create table dados-dev.visoes_cimed_tech.A996_LOJAS_PRECOS_T as 
(
    select * 
from dados-dev.visoes_cimed_tech.A996_LOJAS_PRECOS
order by vkorg, matnr
)

with w_a508 as (
    SELECT 
		b.vkorg, b.matnr, b.knumh
	FROM 
        dados-dev.raw_cimed_tech.A508 b
	WHERE 
        (current_date between PARSE_DATE("%Y%m%d",b.datab) AND PARSE_DATE("%Y%m%d",b.datbi))
		and b.kschl = 'ZSTA'
),
w_konp as (
    select 
        knumh, kbetr, kpein
    from 
        dados-dev.raw.KONP
    where 
        loevm_ko <> 'X' 
		and KSCHL in ('ZFAT', 'ZSTA', 'ZPFA', 'ZPMC')
),
w_a937 as (
    SELECT 
		b.matnr, b.knumh
    FROM 
        dados-dev.raw.A937 AS b
	WHERE 
        (current_date between PARSE_DATE("%Y%m%d",b.datab) AND PARSE_DATE("%Y%m%d",b.datbi))
		AND b.kschl = 'ZFAT' 
), 
w_y218 as (
    select distinct vkorg, uf
    from dados-dev.raw.YDSD218
),
w_a954 as (
    SELECT 
		b.matnr, b.PLTYP, b.knumh
	from 
        dados-dev.raw_cimed_tech.A954 AS b
	WHERE 
        (current_date between PARSE_DATE("%Y%m%d",b.datab) AND PARSE_DATE("%Y%m%d",b.datbi))
		and b.kschl in ('ZPFA')
), 
w_a955 as (
    SELECT 
        b.matnr, b.PLTYP, b.knumh
    FROM 
        dados-dev.raw_cimed_tech.A955 AS b
    WHERE
        (current_date between PARSE_DATE("%Y%m%d",b.datab) AND PARSE_DATE("%Y%m%d",b.datbi))
        and b.kschl in ('ZPMC')
)
-- ZFAT 
SELECT 
    zfat.vkorg, zfat.matnr, zfat.kbetr AS V_ZFAT, 
    zsta.kbetr AS V_ZSTA, zpfa.kbetr AS V_ZPFA, zpmc.kbetr AS V_ZPMC
FROM 
    (
    SELECT 
        b.matnr, 
        a.kbetr,
        y.vkorg         
    FROM 
        w_konp AS a 
    JOIN w_a937 AS b
        ON a.knumh = b.knumh
    CROSS JOIN 
        w_y218 as y
    ) zfat
LEFT JOIN 
    -- ZSTA
    (
    SELECT 
        b.vkorg, b.matnr, a.kbetr
    FROM w_a508 AS b 
    JOIN w_konp AS a
        ON a.knumh = b.knumh   	
    ) zsta
    on zsta.matnr = zfat.matnr
    and zsta.vkorg = zfat.vkorg
------------------- ZPFA        
JOIN
    (
    select q.matnr, q.kbetr, q.lista, j.SHIPFROM, Y218.VKORG
    from 	
	    (	
        SELECT 
            b.matnr, a.kbetr, b.PLTYP as LISTA
        FROM 
            w_konp AS a 
        JOIN w_a954 AS b
            ON a.knumh = b.knumh
        ) q
        join	
            dados-dev.raw_cimed_tech.J_1BTXIC1 J
        ON cast(J.RATE as string)  = q.LISTA
        JOIN	
            (
                SELECT SHIPFROM, Min(VALIDFROM) AS VALIDFROM
                FROM dados-dev.raw_cimed_tech.J_1BTXIC1
                WHERE SHIPFROM=SHIPTO AND specf_rate = 0
                GROUP BY SHIPFROM	
            ) U	
        ON U.SHIPFROM = J.SHIPFROM
        AND U.VALIDFROM = J.VALIDFROM	
        join
            w_y218 as Y218
            ON Y218.UF = J.SHIPFROM
        WHERE
            (PARSE_DATE("%Y%m%d",cast((99999999 - cast(J.validfrom as INTEGER)) as string)) <= current_date)		
            AND J.LAND1 = 'BR'
            AND J.SHIPFROM = J.SHIPTO 
        ) as zpfa
        on zpfa.matnr = zfat.matnr
        and zpfa.vkorg = zfat.vkorg
--ZPMC 
JOIN 
(
    select
        q.matnr, q.kbetr, q.lista, j.SHIPFROM, Y218.VKORG    
	from 
		(	
		SELECT 
			b.matnr, a.kbetr, b.PLTYP as LISTA
		FROM 
			w_konp AS a 
		JOIN w_a955 AS b
			ON a.knumh = b.knumh   
		) q
	join	
		dados-dev.raw_cimed_tech.J_1BTXIC1 J
		ON cast(J.RATE as string)  = q.LISTA
	JOIN	
		(
			SELECT SHIPFROM, Min(VALIDFROM) AS VALIDFROM
			FROM dados-dev.raw_cimed_tech.J_1BTXIC1
			WHERE SHIPFROM=SHIPTO AND specf_rate = 0
			GROUP BY SHIPFROM	
		) U	
		ON U.SHIPFROM = J.SHIPFROM
		AND U.VALIDFROM = J.VALIDFROM	
	join
		w_y218 as Y218
		ON Y218.UF = J.SHIPFROM
	WHERE
	-- (to_date(to_nvarchar(99999999 - J.validfrom)) <= current_date)
	(PARSE_DATE("%Y%m%d",cast((99999999 - cast(J.validfrom as INTEGER)) as string)) <= current_date)		
	AND J.LAND1 = 'BR'
	AND J.SHIPFROM = J.SHIPTO
) as zpmc
    on zpmc.matnr = zfat.matnr
    and zpmc.vkorg = zfat.vkorg
--where zsta.vkorg = '3000'