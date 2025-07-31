select 
    q.tabela, substring(q.produto, 13, 6) as produto,
    case
        when j.SHIPFROM in ('MG', 'SP') and generico = 'S' then valor_12
        else valor
    end as valor,
    q.lista, j.SHIPFROM, Y218.VKORG
    --, generico, valor_12
from 
    (        
    select 
        tabela, matnr as produto, sum(valor) as valor, sum(valor_12) as valor_12,
        LISTA, generico
    from 
        (        
        with w_konp as (
            select 
                knumh, kbetr
            from 
                `dados-dev.raw.KONP`
            where 
                loevm_ko <> 'X' -- marcado para exclusão 
                and mandt = '500'
        ),
        w_mara as (
            select matnr, 
                case when matkl in ('PA07','PA08', 'PA09', 'PA10', 'PA16', 'PA17', 'PA20', 'PA21', 'PA22') then 'S'
                else 'N'
            end as generico    
            from 
                `dados-dev.raw.MARA`
            where 
                MTPOS_MARA in ('YLOT', 'YMKT')
        )
        -- ZPFA GERAL
        SELECT
            b.kschl AS tabela, b.matnr, a.kbetr AS valor, 0 as valor_12,
            CASE
                WHEN b.PLTYP = '97' THEN '17.5'
            ELSE
                b.PLTYP
            END AS LISTA, 
            m.generico
        FROM
            w_konp AS a
        JOIN
            `dados-dev.raw_cimed_tech.A954` AS b
            ON a.knumh = b.knumh
        join
            w_mara as m
            on m.matnr = b.matnr
        WHERE     
            (current_date BETWEEN PARSE_DATE("%Y%m%d",b.datab) AND PARSE_DATE("%Y%m%d", b.datbi))
            AND b.kschl IN ('ZPFA')
        -- ZPMC GERAL 
        union all
        SELECT
            b.kschl AS tabela, b.matnr, a.kbetr AS valor, 0 as valor_12,
            CASE
                WHEN b.PLTYP = '97' THEN '17.5'
            ELSE
                b.PLTYP
            END AS LISTA, 
            m.generico
        FROM
            w_konp AS a
        JOIN
            `dados-dev.raw_cimed_tech.A955` AS b
            ON a.knumh = b.knumh
        join
            w_mara as m
            on m.matnr = b.matnr
        WHERE
            (current_date BETWEEN PARSE_DATE("%Y%m%d",b.datab) AND PARSE_DATE("%Y%m%d", b.datbi))
            AND b.kschl IN ('ZPMC')

        UNION ALL
        -- ZPFA 12% PARA GENERICO MG E SP
        SELECT
            b.kschl AS tabela, b.matnr, 0 AS valor, a.kbetr as valor_12,
            '18' AS LISTA, m.generico
        FROM
            w_konp AS a
        JOIN
            `dados-dev.raw_cimed_tech.A954` AS b
            ON a.knumh = b.knumh
        join
            w_mara as m
            on m.matnr = b.matnr
        WHERE     
            (current_date BETWEEN PARSE_DATE("%Y%m%d",b.datab) AND PARSE_DATE("%Y%m%d", b.datbi))
            AND b.kschl IN ('ZPFA')
            AND b.PLTYP = '12' 
            and m.generico = 'S'    

        -- ZPMC DE 12% para GENERICO MG E SP
        union all
        SELECT
            b.kschl AS tabela, b.matnr, 0 AS valor, a.kbetr as valor_12,
            '18' AS LISTA, m.generico
        FROM
            w_konp AS a
        JOIN
            `dados-dev.raw_cimed_tech.A955` AS b
            ON a.knumh = b.knumh
        join
            w_mara as m
            on m.matnr = b.matnr
        WHERE
            (current_date BETWEEN PARSE_DATE("%Y%m%d",b.datab) AND PARSE_DATE("%Y%m%d", b.datbi))
            AND b.kschl IN ('ZPMC')
            AND b.PLTYP = '12' 
            and m.generico = 'S'
        )    
    group by
        tabela, matnr, LISTA, generico
    ) as q
join	
    `dados-dev.raw_cimed_tech.J_1BTXIC1` J
    ON J.RATE  = cast(q.LISTA as numeric)
    JOIN
        (SELECT 
            SHIPFROM, Min(VALIDFROM) AS VALIDFROM
        FROM 
            `dados-dev.raw_cimed_tech.J_1BTXIC1`
        WHERE 
            SHIPFROM=SHIPTO
            -- AEO 07.12.21 AND specf_rate = 0
        GROUP BY SHIPFROM	
    ) U	
    ON U.SHIPFROM = J.SHIPFROM
    AND U.VALIDFROM = J.VALIDFROM	
join 
    `dados-dev.raw.YDSD218` Y218
    ON Y218.UF = J.SHIPFROM
WHERE 
    PARSE_DATE("%Y%m%d",cast((cast(99999999 as int64) - cast(J.validfrom as int64)) as string)) <= current_date
    AND J.LAND1 = 'BR'
    AND J.SHIPFROM = J.SHIPTO
    --AND J.SHIPFROM in ('MG', 'SP')
    AND Y218.vkorg <> '1100'