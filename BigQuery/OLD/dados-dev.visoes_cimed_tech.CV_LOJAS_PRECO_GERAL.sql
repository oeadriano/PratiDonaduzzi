CREATE TABLE dados-dev.raw_cimed_tech.CV_LOJAS_PRECO_GERAL_T AS
SELECT * FROM dados-dev.visoes_cimed_tech.CV_LOJAS_PRECO_GERAL

INSERT INTO raw_cimed_tech.CV_LOJAS_PRECO_GERAL_T
(SELECT * FROM dados-dev.visoes_cimed_tech.CV_LOJAS_PRECO_GERAL);

DELETE FROM raw_cimed_tech.CV_LOJAS_PRECO_GERAL_T
WHERE last_update < (SELECT MAX(last_update) from raw_cimed_tech.CV_LOJAS_PRECO_GERAL_T)

select * from (

with w_konm as
(
    select
        kbetr, kstbm, knumh
    from
        dados-dev.raw_cimed_tech.KONM
    where 
        mandt = '500'
),
w_konp as (
    select
        mandt, knumh, kbetr, kpein
    from
        dados-dev.raw.KONP
    where
        kschl in ('ZCO2', 'ZFAT', 'ZSTA', 'ZQCO', 'ZPFA', 'ZPMC')
        and loevm_ko <> 'X'
),
w_zco2 as (    
    with w_a996 as
    (
        select
            distinct mandt, knumh, vkorg, wty_v_parvw, matnr
        from
            dados-dev.raw_cimed_tech.A996
        where
            kschl = 'ZCO2'
            AND
            (
                current_date between PARSE_DATE("%Y%m%d",datab) AND PARSE_DATE("%Y%m%d",datbi)
            )
    )
    SELECT
        ROW_NUMBER() OVER (PARTITION BY b.vkorg, b.wty_v_parvw, b.matnr order by
                            b.vkorg, b.wty_v_parvw, b.matnr, k.kbetr )-3 AS faixa, b.matnr as produto, k.kstbm AS valor, 
                            ROUND((k.kbetr/10),2) AS perc_comis, b.vkorg, b.wty_v_parvw as func_par
    FROM
        w_konp AS a
    JOIN
        w_a996 AS b
        ON	a.knumh     = b.knumh
        AND a.mandt = b.mandt
    JOIN
        w_konm AS k
        ON k.knumh = b.knumh
    --where vkorg = '3000'
    ORDER BY
        b.vkorg, b.WTy_v_parvw, b.matnr, k.kbetr
)
-- inicio outras tabelas 
, w_zfat as
(
    SELECT
        b.kschl as tabela, b.matnr as produto, a.kbetr as valor, a.kpein as qtdmin
    FROM
        w_konp AS a
    JOIN
        dados-dev.raw.A937 AS b
        ON a.knumh = b.knumh
    WHERE
        (current_date between PARSE_DATE("%Y%m%d",b.datab) AND PARSE_DATE("%Y%m%d",b.datbi))
        and a.mandt = '500'
        AND b.kschl = 'ZFAT'
)
, w_zsta as
(
    SELECT
        b.kschl as tabela, b.vkorg, b.matnr as produto, a.kbetr as valor, a.kpein as qtdmin, b.kschl as codigo
    FROM
        w_konp AS a
    left JOIN
        dados-dev.raw_cimed_tech.A508 AS b
        ON a.knumh = b.knumh
    WHERE
        (current_date between PARSE_DATE("%Y%m%d",b.datab) AND PARSE_DATE("%Y%m%d",b.datbi))        
        and a.mandt = '500'
        And b.kschl = 'ZSTA'
),
w_ydsd218 as 
	(
		select * from dados-dev.raw.YDSD218
	)
, w_zqco as
    (
    with  w_a709 as
        (
            SELECT
                i.vkorg, b.matnr as produto, cast(c.kbetr/10 as integer) as faixa, cast(c.kstbm as integer) as qtdmin
            FROM
                w_konp AS a
            JOIN
                dados-dev.raw_cimed_tech.A709 AS b
                ON a.knumh = b.knumh
            JOIN
                w_konm AS c
                ON a.knumh = c.knumh
            CROSS JOIN
                w_ydsd218 AS i
            WHERE
                (current_date between PARSE_DATE("%Y%m%d",b.datab) AND PARSE_DATE("%Y%m%d",b.datbi))
                And b.kschl in ('ZQCO')
        )
        , w_a508 as
        (
            SELECT
                b.vkorg, b.matnr as produto, cast(c.kbetr/10 as integer) as faixa, cast(c.kstbm as integer) as qtdmin
            FROM
                w_konp AS a
            JOIN
                dados-dev.raw_cimed_tech.A508 AS b
                ON a.knumh = b.knumh
            JOIN
                w_konm AS c
                ON a.knumh = c.knumh
            JOIN
                w_ydsd218 AS i
                ON i.vkorg = b.vkorg
            WHERE
                b.kschl in ('ZQCO')
                AND (current_date between PARSE_DATE("%Y%m%d",b.datab) AND PARSE_DATE("%Y%m%d",b.datbi)))
    select
        VKORG, PRODUTO, FAIXA, QTDMIN
    FROM
        w_a508
    union all
        (
            select * from w_a709
            except
            distinct select * FROM w_a508
        )
)
, w_zpfa as
(
    -- precisa da UF DO cliente para joinda lista
    -- "_SYS_BIC"."CimedTech/CV_A954_955_ZPFA_ZPMC" ZPFA
    select
        q.tabela, q.produto, q.valor, q.lista, j.SHIPFROM, Y218.VKORG
    from
        (
            SELECT
                b.kschl as tabela, b.matnr as produto, a.kbetr as valor, b.PLTYP as LISTA
            FROM
                w_konp AS a
            left JOIN
                dados-dev.raw_cimed_tech.A954 AS b
                ON a.knumh = b.knumh
            WHERE
                (current_date between PARSE_DATE("%Y%m%d",b.datab) AND PARSE_DATE("%Y%m%d",b.datbi))
                and b.kschl in ('ZPFA')
        )
        q
        join
            dados-dev.raw_cimed_tech.J_1BTXIC1 J
            ON cast(J.RATE as string) = q.LISTA
        JOIN
            (
                SELECT
                    SHIPFROM, Min(VALIDFROM) AS VALIDFROM
                FROM
                    dados-dev.raw_cimed_tech.J_1BTXIC1
                WHERE
                    SHIPFROM       =SHIPTO
                    --AND specf_rate = 0
                GROUP BY
                    SHIPFROM
            )
            U
            ON U.SHIPFROM      = J.SHIPFROM
               AND U.VALIDFROM = J.VALIDFROM
        join
            w_ydsd218 Y218
            ON y218.UF = J.SHIPFROM
    WHERE
        ( PARSE_DATE("%Y%m%d",cast((99999999 - cast(J.validfrom as INTEGER)) as string)) <= current_date)
        AND J.LAND1    = 'BR'
        AND J.SHIPFROM = J.SHIPTO
)
, w_zpmc as
(
    -- CV_A954_955_ZPFA_ZPMC
    select
        q.tabela, q.produto, q.valor, q.lista, j.SHIPFROM, Y218.VKORG
    from
        (
            SELECT
                b.kschl as tabela, b.matnr as produto, a.kbetr as valor, b.PLTYP as LISTA
            FROM
                w_konp AS a
            left JOIN
                dados-dev.raw_cimed_tech.A955 AS b
                ON a.knumh = b.knumh
            WHERE
                (current_date between PARSE_DATE("%Y%m%d",b.datab) AND PARSE_DATE("%Y%m%d",b.datbi))
                and b.kschl in ('ZPMC')
        )
        q
        join
            dados-dev.raw_cimed_tech.J_1BTXIC1 J
            ON
                cast(J.RATE as string) = q.LISTA
        JOIN
            (
                SELECT
                    SHIPFROM, Min(VALIDFROM) AS VALIDFROM
                FROM
                    dados-dev.raw_cimed_tech.J_1BTXIC1
                WHERE
                    SHIPFROM       =SHIPTO
                    --AND specf_rate = 0
                GROUP BY
                    SHIPFROM
            )
            U
            ON
                U.SHIPFROM      = J.SHIPFROM
                AND U.VALIDFROM = J.VALIDFROM
        join
            w_ydsd218 Y218
            ON Y218.UF = J.SHIPFROM
    WHERE
        -- (to_date(to_nvarchar(99999999 - J.validfrom)) <= current_date)
        (PARSE_DATE("%Y%m%d",cast((99999999 - cast(J.validfrom as INTEGER)) as string)) <= current_date)
        AND J.LAND1    = 'BR'
        AND J.SHIPFROM = J.SHIPTO
),
w_validade_curta as (
    SELECT
        PRODUTO, VALOR, SALDO, VKORG
    FROM
        dados-dev.visoes_auxiliares_cimed_tech.CV_VIEW_VALIDADE_CURTA
)
select 
    p.func_par, p.vkorg, p.produto, p.perc_comis, p.V_ZFAT, p.V_ZSTA, p.ZPFA, p.ZPMC,
    max(FORMAT('%.2f',VALOR_P)) AS VALOR_P, max(FORMAT('%.2f',VALOR_M)) AS VALOR_M, max(FORMAT('%.2f',VALOR_G)) AS VALOR_G, 
	max(FORMAT('%.2f',VALOR_G1)) AS VALOR_G1, max(FORMAT('%.2f',VALOR_G2)) AS VALOR_G2,     	
	max(QDE_P) AS QDE_P, max(QDE_M) AS QDE_M, max(QDE_G) AS QDE_G, max(QDE_G1) AS QDE_G1, max(QDE_G2) AS QDE_G2, 
	max(COMIS_P) AS COMIS_P, max(COMIS_M) AS COMIS_M, max(COMIS_G) AS COMIS_G, max(COMIS_G1) AS COMIS_G1, max(COMIS_G2) AS COMIS_G2,
    -- sobre validade curta
    -- quantidade minima 1 fixa, se precisar mudar incluir aqui.
    -- comissao é comissao G, pois valor de VC tende a ser menor que o valor G da PMG
    coalesce(vc.valor, 0) as VALOR_VC,  1 as QDE_VC,  max(COMIS_G) as COMIS_VC,    
    current_timestamp() as last_update
from 
    (
    select 
        zco2.func_par, zco2.vkorg, zco2.produto, zco2.faixa, 0 as perc_comis, 
        coalesce(zfat.valor,0) as V_ZFAT, 
        coalesce(zsta.valor,0) as V_ZSTA, 
        coalesce(zpfa.valor,0) as ZPFA, 
        coalesce(zpmc.valor,0) as ZPMC,
        case
            when zco2.faixa = 2
                then round(((zfat.valor / (1 - zco2.valor/100)) + coalesce(zsta.valor,0)),2)
                else 0
        end as VALOR_P, case
            when zco2.faixa = 1
                then round(((zfat.valor / (1 - zco2.valor/100)) + coalesce(zsta.valor,0)),2)
                else 0
        end as VALOR_M, case
            when zco2.faixa = 0
                then round(((zfat.valor / (1 - zco2.valor/100)) + coalesce(zsta.valor,0)),2)
                else 0
        end as VALOR_G, case
            when zco2.faixa = -1
                then round(((zfat.valor / (1 - zco2.valor/100)) + coalesce(zsta.valor,0)),2)
                else 0
        end as VALOR_G1, case
            when zco2.faixa = -2
                then round(((zfat.valor / (1 - zco2.valor/100)) + coalesce(zsta.valor,0)),2)
                else 0
        end as VALOR_G2, case
            when zco2.faixa = 2
                then COALESCE(zqco.QTDMIN, 1)
                else 0
        end as QDE_P, case
            when zco2.faixa = 1
                then COALESCE(zqco.QTDMIN, 1)
                else 0
        end as QDE_M, case
            when zco2.faixa = 0
                then COALESCE(zqco.QTDMIN, 1)
                else 0
        end as QDE_G, case
            when zco2.faixa = -1
                then COALESCE(zqco.QTDMIN, 1)
                else 0
        end as QDE_G1, case
            when zco2.faixa = -2
                then COALESCE(zqco.QTDMIN, 1)
                else 0
        end as QDE_G2, case
            when zco2.faixa = 2
                then zco2.perc_comis
                else 0
        end as COMIS_P, case
            when zco2.faixa = 1
                then zco2.perc_comis
                else 0
        end as COMIS_M, case
            when zco2.faixa = 0
                then zco2.perc_comis
                else 0
        end as COMIS_G, case
            when zco2.faixa = -1
                then zco2.perc_comis
                else 0
        end as COMIS_G1, case
            when zco2.faixa = -2
                then zco2.perc_comis
                else 0
        end as COMIS_G2    
    from 
        w_zco2 as zco2
    join
        w_zfat as zfat
        on zfat.produto = zco2.produto    
    left join
        w_zsta as zsta
        on zsta.vkorg       = zco2.vkorg
            and zsta.produto = zco2.produto
    left join
        w_zqco as zqco
        on zqco.vkorg       = zco2.vkorg
            and zqco.produto = zco2.produto
            and zqco.faixa+2 = zco2.faixa
    left join
        w_zpfa as zpfa
        on zpfa.produto   = zco2.produto
            and zpfa.vkorg = zco2.vkorg
    left join
        w_zpmc as zpmc
        on zpmc.produto   = zco2.produto
            and zpmc.vkorg = zco2.vkorg    
    where
        zco2.func_par in ('X1', 'Y1')  
    ) as p
left join
    w_validade_curta as vc
    on vc.vkorg = p.vkorg 
    and vc.produto = p.produto
group by 
    func_par, vkorg, produto, perc_comis, V_ZFAT, V_ZSTA, ZPFA, ZPMC, vc.vkorg, vc.produto, vc.valor
union all
-- precos func_par = N - sem comissao
-- precos iguais ao X1 e comissao zero, vai ser usada como preços gerais no online e offline
select 
    'N' as func_par, p.vkorg, p.produto, p.perc_comis, p.V_ZFAT, p.V_ZSTA, p.ZPFA, p.ZPMC,
    max(FORMAT('%.2f',VALOR_P)) AS VALOR_P, max(FORMAT('%.2f',VALOR_M)) AS VALOR_M, max(FORMAT('%.2f',VALOR_G)) AS VALOR_G, 
	max(FORMAT('%.2f',VALOR_G1)) AS VALOR_G1, max(FORMAT('%.2f',VALOR_G2)) AS VALOR_G2,     	
	max(QDE_P) AS QDE_P, max(QDE_M) AS QDE_M, max(QDE_G) AS QDE_G, max(QDE_G1) AS QDE_G1, max(QDE_G2) AS QDE_G2, 
	max(COMIS_P) AS COMIS_P, max(COMIS_M) AS COMIS_M, max(COMIS_G) AS COMIS_G, max(COMIS_G1) AS COMIS_G1, max(COMIS_G2) AS COMIS_G2,
    -- sobre validade curta
    -- quantidade minima 1 fixa, se precisar mudar incluir aqui.
    -- comissao é comissao G, pois valor de VC tende a ser menor que o valor G da PMG
    coalesce(vc.valor, 0) as VALOR_VC,  1 as QDE_VC,  max(COMIS_G) as COMIS_VC,
    current_timestamp() as last_update
from 
    (
    select 
        zco2.func_par, zco2.vkorg, zco2.produto, zco2.faixa, 0 as perc_comis, 
        coalesce(zfat.valor,0) as V_ZFAT, 
        coalesce(zsta.valor,0) as V_ZSTA, 
        coalesce(zpfa.valor,0) as ZPFA, 
        coalesce(zpmc.valor,0) as ZPMC,
        case
            when zco2.faixa = 2
                then round(((zfat.valor / (1 - zco2.valor/100)) + coalesce(zsta.valor,0)),2)
                else 0
        end as VALOR_P, case
            when zco2.faixa = 1
                then round(((zfat.valor / (1 - zco2.valor/100)) + coalesce(zsta.valor,0)),2)
                else 0
        end as VALOR_M, case
            when zco2.faixa = 0
                then round(((zfat.valor / (1 - zco2.valor/100)) + coalesce(zsta.valor,0)),2)
                else 0
        end as VALOR_G, case
            when zco2.faixa = -1
                then round(((zfat.valor / (1 - zco2.valor/100)) + coalesce(zsta.valor,0)),2)
                else 0
        end as VALOR_G1, case
            when zco2.faixa = -2
                then round(((zfat.valor / (1 - zco2.valor/100)) + coalesce(zsta.valor,0)),2)
                else 0
        end as VALOR_G2, case
            when zco2.faixa = 2
                then COALESCE(zqco.QTDMIN, 1)
                else 0
        end as QDE_P, case
            when zco2.faixa = 1
                then COALESCE(zqco.QTDMIN, 1)
                else 0
        end as QDE_M, case
            when zco2.faixa = 0
                then COALESCE(zqco.QTDMIN, 1)
                else 0
        end as QDE_G, case
            when zco2.faixa = -1
                then COALESCE(zqco.QTDMIN, 1)
                else 0
        end as QDE_G1, case
            when zco2.faixa = -2
                then COALESCE(zqco.QTDMIN, 1)
                else 0
        end as QDE_G2, case
            when zco2.faixa = 2
                then zco2.perc_comis
                else 0
        end as COMIS_P, case
            when zco2.faixa = 1
                then zco2.perc_comis
                else 0
        end as COMIS_M, case
            when zco2.faixa = 0
                then zco2.perc_comis
                else 0
        end as COMIS_G, case
            when zco2.faixa = -1
                then zco2.perc_comis
                else 0
        end as COMIS_G1, case
            when zco2.faixa = -2
                then zco2.perc_comis
                else 0
        end as COMIS_G2    
    from 
        w_zco2 as zco2
    join
        w_zfat as zfat
        on zfat.produto = zco2.produto    
    left join
        w_zsta as zsta
        on zsta.vkorg       = zco2.vkorg
            and zsta.produto = zco2.produto
    left join
        w_zqco as zqco
        on zqco.vkorg       = zco2.vkorg
            and zqco.produto = zco2.produto
            and zqco.faixa+2 = zco2.faixa
    left join
        w_zpfa as zpfa
        on zpfa.produto   = zco2.produto
            and zpfa.vkorg = zco2.vkorg
    left join
        w_zpmc as zpmc
        on zpmc.produto   = zco2.produto
            and zpmc.vkorg = zco2.vkorg    
    where
        zco2.func_par in ('X1')  
    ) as p
left join
    w_validade_curta as vc
    on vc.vkorg = p.vkorg 
    and vc.produto = p.produto
group by 
    func_par, vkorg, produto, perc_comis, V_ZFAT, V_ZSTA, ZPFA, ZPMC, vc.vkorg, vc.produto, vc.valor
order by
    func_par, vkorg, produto, perc_comis, V_ZFAT, V_ZSTA, ZPFA, ZPMC
) 
where 
    valor_vc <> 0
