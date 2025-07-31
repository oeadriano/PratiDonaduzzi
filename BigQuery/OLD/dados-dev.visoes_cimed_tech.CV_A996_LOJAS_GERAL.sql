--CV_A996_LOJAS_GERAL
with 
    w_konp as
    (
        select
            mandt, knumh, kbetr, kpein
        from
            dados-dev.raw.KONP
        where
            kschl in ('ZCO2', 'ZFAT', 'ZSTA', 'ZQCO', 'ZPFA', 'ZPMC')
            and loevm_ko <> 'X'
    ),
    w_konm as
    (
        select
            kbetr, kstbm, knumh
        from
            dados-dev.raw_cimed_tech.KONM
        where 
            mandt = '500'
    ),  
    w_ydsd044 as    
    (
        select distinct
            werks, lgort, 'L'||meses as meses
        from            
            `dados-dev.raw_cimed_tech.YDSD044`
        where 
            -- AEO 05.01.2022 - retira o estoque 1005/1016
            lgort <> '1006'
            and werks <> '1001' 
            and werks <> '1100'
            and werks <> '1101'
            and werks <> '1010'         
    ),
    w_url as (
        select
            cast(lower(relatorio) as string) as url
        from 
            `dados-dev.raw.YDBI001`
        where 
            filtro = 'GCP' 
            and NOME_VIEW = 'URL_GC_CONTEUDO'
    )
    , w_validade_curta as
    (
        SELECT
            PRODUTO, VALOR, SALDO, VKORG
        FROM
            dados-dev.visoes_auxiliares_cimed_tech.CV_VIEW_VALIDADE_CURTA
    )
    , w_material as
    (
        select
            codigo, codigobarras, DESCRICAO as descricao_material, principioativo, generico, lista, codigo_ms, 
            linha, status, c_controlado, produto_hierarquia, substring(hierarquia, 4, 3) as cod_hierarquia, hierarquia, CASE
                WHEN GRP_MERCADORIA IN ('PA01', 'PA02', 'PA03')
                    THEN 'MIP'
                WHEN GRP_MERCADORIA IN ('PA04', 'PA05', 'PA06')
                    THEN 'RX'
                WHEN GRP_MERCADORIA IN ('PA07', 'PA08', 'PA09', 'PA23', 'PA24', 'PA25')
                    THEN 'Controlados'
                WHEN GRP_MERCADORIA IN ('PA10', 'PA16', 'PA17')
                    THEN 'Genéricos'
                WHEN GRP_MERCADORIA IN ('PA11')
                    THEN 'Cosméticos'
                WHEN GRP_MERCADORIA IN ('PA12')
                    THEN 'Correlatos'
                WHEN GRP_MERCADORIA IN ('PA13')
                    THEN 'Suprimentos'
                WHEN GRP_MERCADORIA IN ('PA14', 'PA18', 'PA19', 'PA20', 'PA21', 'PA22')
                    THEN 'Hospitalar'
                WHEN GRP_MERCADORIA IN ('PA15')
                    THEN 'Terceiros'
                    ELSE GRP_MERCADORIA
            END AS grp_mercadoria, 
            grp_mercadoria as cod_grp_mercadoria, 
            
            fabricante, caixa_padrao, ipi,farm_popular, prod_marca, prod_classei, prod_fator, ncm, grpmercexterno, 
            MENU_CATEGORIA, NUM_CATEGORIA, COMBO, url.url
        from
            dados-dev.raw_cimed_tech.CV_CADASTRO_MATERIAL_T
        cross join 
            w_url as url
        where
            -- foi retirado o filtro de status na criação 
            -- da tabela de materiais, aqui precisa filtrar
            MSTAE in ('', 'Y5') 
    )
    , ultima_compra as
    (
        select        
            distinct
            kunnr, matnr, erdat, vlr_unit, ult_qde
        from
            dados-dev.raw_cimed_tech.CV_MAT_ULTIMA_COMPRA_T
    )
    , w_contexto AS
    (
        SELECT
            produto, NOME as FILTRO_CONTEXTO_NOME, id as FILTRO_CONTEXTO_ID, '' as VKORG
        FROM
            --DEV
            EXTERNAL_QUERY("projects/dados-dev/locations/us/connections/cimed-postgres-us", "SELECT * from sf.view_prd_destaque")
            --prod
            --EXTERNAL_QUERY("projects/dados-dev/locations/southamerica-east1/connections/cimed-postgres", "SELECT * from sf.view_prd_destaque") 
        UNION ALL
        SELECT
            PRODUTO, 'Outlet' as FILTRO_CONTEXTO_NOME, 'Outlet' as FILTRO_CONTEXTO_ID, VKORG
        FROM
            w_validade_curta                
    ),
    w_ydsd218 as 
    (
        select * from dados-dev.raw.YDSD218
    ),    
    w_J_1BTXIC1 as (
      select  
        SHIPFROM, SHIPTO, VALIDFROM, LAND1, 
        CASE
          when RATE = 17.5 then 97
          when RATE = 13.3 then 13
          else RATE
        end as RATE        
      from 
        dados-dev.raw_cimed_tech.J_1BTXIC1
      where   
        LAND1 = 'BR'
        AND SHIPFROM = SHIPTO
    )
select
    MAT.CODIGOBARRAS, MAT.DESCRICAO_MATERIAL, 
    MAT.PRINCIPIOATIVO, MAT.GENERICO, MAT.CODIGO_MS, MAT.LINHA, MAT.STATUS, MAT.C_CONTROLADO,
    -- ajusta num_categoria
    MAT.MENU_CATEGORIA, MAT.NUM_CATEGORIA, MAT.GRP_MERCADORIA, MAT.FABRICANTE, MAT.CAIXA_PADRAO, MAT.IPI, MAT.FARM_POPULAR, MAT.PROD_MARCA, 
    MAT.PROD_CLASSEI, MAT.PROD_FATOR, MAT.NCM, MAT.GRPMERCEXTERNO, P.COD_GAMA, P.DESCRICAO, P.VTWEG, P.BUKRS, P.WERKS,P.VKORG, P.FUNC_PAR, 
    P.KUNNR, P.LIFNR, substring(P.PRODUTO, 13, 6) AS PRODUTO, 0 AS PERC_COMIS, 
    FORMAT('%.2f',V_ZFAT) AS V_ZFAT, 
    FORMAT('%.2f',V_ZSTA) AS V_ZSTA, 
    FORMAT('%.2f',ZPFA) AS ZPFA, 
    FORMAT('%.2f',ZPMC) AS ZPMC, 
    
    max(FORMAT('%.2f',VALOR_P)) AS VALOR_P, max(FORMAT('%.2f',VALOR_M)) AS VALOR_M, max(FORMAT('%.2f',VALOR_G)) AS VALOR_G, 
    max(FORMAT('%.2f',VALOR_G1)) AS VALOR_G1, max(FORMAT('%.2f',VALOR_G2)) AS VALOR_G2,     
    
    max(QDE_P) AS QDE_P, max(QDE_M) AS QDE_M, max(QDE_G) AS QDE_G, max(QDE_G1) AS QDE_G1, max(QDE_G2) AS QDE_G2, 
    max(COMIS_P) AS COMIS_P, max(COMIS_M) AS COMIS_M, max(COMIS_G) AS COMIS_G, max(COMIS_G1) AS COMIS_G1, max(COMIS_G2) AS COMIS_G2, 

    mat.url||substring(MAT.hierarquia, 1, 3)
        || '/'
        ||substring(MAT.hierarquia, 4, 3)
        || '/'
        ||substring(MAT.hierarquia, 7, 3)
        ||'/'
        ||substring(MAT.hierarquia, 10, 3)
        ||'/'
        ||substring(P.produto,13,6)
        ||'/'
        ||substring(P.produto,13,6)
        ||'-I.png' as IMAGEM, 
        mat.url||substring(MAT.hierarquia, 1, 3)
        || '/'
        ||substring(MAT.hierarquia, 4, 3)
        || '/'
        ||substring(MAT.hierarquia, 7, 3)
        ||'/'
        ||substring(MAT.hierarquia, 10, 3)
        ||'/'
        ||substring(P.produto,13,6)
        ||'/'
        ||substring(P.produto,13,6)
        ||'-B.pdf' as BULA, 
        mat.url||substring(MAT.hierarquia, 1, 3)
        || '/'
        ||substring(MAT.hierarquia, 4, 3)
        || '/'
        ||substring(MAT.hierarquia, 7, 3)
        ||'/'
        ||substring(MAT.hierarquia, 10, 3)
        ||'/'
        ||substring(P.produto,13,6)
        ||'/'
        ||substring(P.produto,13,6)
        ||'-F.pdf' as FICHA, 
        FORMAT('%.2f',COALESCE(VC.VALOR, 0)) AS VALOR_VC, CASE
        WHEN COALESCE(VC.VALOR, 0) = 0
            THEN 0
            ELSE 1
    END AS QDE_VC, COALESCE(VC.SALDO, 0) AS DISPONIVEL_VC, 
    coalesce(ult.vlr_unit, 0) AS ULT_COMPRA_VALOR, 
    cast(coalesce(ult.ult_qde, 0) as integer) AS ULT_COMPRA_QDE, 
    coalesce(ult.erdat, '') AS ULT_COMPRA_DATA, P.LGORT, p.MESES, cast(p.TRANSITO as integer) AS TRANSITO, 
    cast(p.DISPONIVEL as integer) AS DISPONIVEL, '' as FILTRO_CONTEXTO, '' as NUM_FILTRO, 
    
    case 
        when coalesce(cont.FILTRO_CONTEXTO_ID, '') <> '' then coalesce(cont.FILTRO_CONTEXTO_ID, '')
        else COMBO
    end as FILTRO_CONTEXTO_ID, 
    case 
        when coalesce(cont.FILTRO_CONTEXTO_NOME, '') <> '' then coalesce(cont.FILTRO_CONTEXTO_NOME, '')
        else COMBO
    end as FILTRO_CONTEXTO_NOME,    
    300 as PEDIDO_MINIMO, 'P' as TIPO_P, 'M' as TIPO_M, 'G' as TIPO_G,
    -- se tem validade valor de VC, tem tag na api
    -- trazer VC de with
    CASE
        WHEN COALESCE(VC.VALOR, 0) = 0
            THEN NULL
            ELSE 'VC'
    END AS TIPO_VC, 'A' as GRUPO_A, 'B' as GRUPO_B,
    -- integração define o tipo de documento usado na integração da OV
    -- mockado para separar ZNOR, ZV12 e YTRI
    -- cabe uma versão da api com o tipo de documento
    'ZNOR' as INT_ZNOR, 'ZNOR-VC' as INT_ZV12
from
    w_material as mat
join
    ( with w_loja as
    (
        with w_gama_produto as
            (
                select
                    c.cod_gama, c.matnr, 
                    case 
                        --PA13 alimentos - PA12 correlatos  - PA11 cosméticos                   
                        when M.cod_grp_mercadoria in ('PA11', 'PA12', 'PA13') then 'ZOUT'
                        else 'ZMED'
                    end as material_zmed_zout, 
                    --case 
                    --    when M.cod_grp_mercadoria in ('PA07', 'PA08', 'PA09') then 'S'
                    --    else 'N'
                    --end as material_controlado
                    M.c_controlado as material_controlado
                from
                    dados-dev.raw_cimed_tech.YDSD057 AS c
                join 
                    w_material as M
                    on m.codigo = c.matnr
                where
                    c.ativo = 'S' and
                    c.cod_gama in ('157','158','159')
                    -- AEO 27.12.21
                    -- necessario filtrar por lojas pois, por conta da visao
                    -- varias lojas estarão ativas                      
            )
            , w_wyt3 as
            (
                select
                    LIFN2, lifnr
                from
                    `dados-dev.raw.WYT3`
                where
                    ekorg                    = '1000'
                    AND parvw                = 'Y1'
                    AND defpa                = 'X'
                    ANd coalesce(LIFN2, '') <> ''
            )
            , w_lif_cli as
            (
                SELECT DISTINCT
                    L.VKORG, L.KUNNR, L.LIFNR, 
                    C.GRUPO_CONTAS as cliente_zmed_zout, 
                    C.CONTROLADO as cliente_vende_controlado
                FROM
                    dados-dev.raw_cimed_tech.LIFNR_CLIENTE_T L
                JOIN 
                    `dados-dev.raw_cimed_tech.CADASTRO_CLIENTE_T` C
                    on C.codigo = L.kunnr
            )
        --select distinct g.cod_gama, l.descricao, l.vtweg, G.bukrs, g.werks, g.vkorg, y94.func_par, lf.kunnr, lf.lifnr, g.produto
        SELECT   DISTINCT
            A.BUKRS, A.COD_GAMA, T3.LIFNR as CADEIRA, T3.LIFN2 as LIFNR, i.vkorg, 
            lf.kunnr, b.descricao, b.vtweg, a.werks, coalesce(y94.func_par, 'X1') as func_par, c.matnr
        FROM
            dados-dev.raw_cimed_tech.YDSD225 AS a
        JOIN
            dados-dev.raw_cimed_tech.YDSD056 AS b
    
            ON a.cod_gama = b.cod_gama
        JOIN
            w_ydsd218 AS i  
            ON i.werks = a.werks
        JOIN
            w_wyt3 as T3    
            ON T3.lifnr = A.lifnr
        join
            w_lif_cli as lf 
            ON LF.LIFNR     = T3.LIFN2
            AND LF.VKORG = i.VKORG
        left join
            dados-dev.raw.YDSD094 Y94      
            ON LF.LIFNR = Y94.repr
        join
            w_gama_produto as c    
            on c.cod_gama = b.cod_gama              
        WHERE
            a.ativo      = 'S'
            AND b.ativo  = 'S'
            and a.werks <> '1100'   
            and (
                    (lf.cliente_zmed_zout = 'ZOUT' and c.material_zmed_zout = 'ZOUT' and c.material_controlado = 'N')
                    OR
                    (CASE 
                       WHEN lf.cliente_vende_controlado = 'S' THEN
                         lf.cliente_zmed_zout in('ZMED', 'ZSAC') and c.material_zmed_zout in ('ZOUT', 'ZMED')
                       ELSE 
                         lf.cliente_zmed_zout in('ZMED', 'ZSAC') and c.material_zmed_zout in ('ZOUT', 'ZMED') and c.material_controlado = 'N'
                    END)
                )
            --and c.material_controlado = lf.cliente_vende_controlado                
    )
    , w_zco2 as
    (
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
            ROW_NUMBER() OVER (PARTITION BY b.vkorg, b.wty_v_parvw, b.matnr 
                                order by b.vkorg, b.wty_v_parvw, b.matnr, k.kbetr, k.KSTBM )-3 AS faixa, 
                                b.matnr as produto, k.kstbm AS valor, 
                                ROUND((k.kbetr/10),2) AS perc_comis, b.vkorg, b.wty_v_parvw as func_par
        FROM
            w_konp AS a
        INNER JOIN
            w_a996 AS b
        ON  a.knumh     = b.knumh
            AND a.mandt = b.mandt
        INNER JOIN
            w_konm AS k
                ON k.knumh = b.knumh
            --ORDER BY
            --b.vkorg, b.WTy_v_parvw, b.matnr, k.kbetr
    )
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
            (
                current_date between PARSE_DATE("%Y%m%d",b.datab) AND PARSE_DATE("%Y%m%d",b.datbi)
            )
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
            (
                current_date between PARSE_DATE("%Y%m%d",b.datab) AND PARSE_DATE("%Y%m%d",b.datbi)
            )
            and a.mandt = '500'
            And b.kschl = 'ZSTA'
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
                    (
                        current_date between PARSE_DATE("%Y%m%d",b.datab) AND PARSE_DATE("%Y%m%d",b.datbi)
                    )
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
                    AND
                    (
                        current_date between PARSE_DATE("%Y%m%d",b.datab) AND PARSE_DATE("%Y%m%d",b.datbi)
                    )
            )
        select
            VKORG, PRODUTO, FAIXA, QTDMIN
        FROM
            w_a508
        union all
            (
                select *
                from w_a709
                except
                distinct
                select *
                FROM w_a508
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
                    (
                        current_date between PARSE_DATE("%Y%m%d",b.datab) AND PARSE_DATE("%Y%m%d",b.datbi)
                    )
                    and b.kschl in ('ZPFA')
            )
            q
            join
                w_J_1BTXIC1 J
                ON cast(J.RATE as string) = q.LISTA
            JOIN
                (
                    SELECT
                        SHIPFROM, Min(VALIDFROM) AS VALIDFROM
                    FROM
                        w_J_1BTXIC1
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
                ON y218.UF = J.SHIPFROM
        WHERE
            (
                PARSE_DATE("%Y%m%d",cast((99999999 - cast(J.validfrom as INTEGER)) as string)) <= current_date
            )
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
                    (
                        current_date between PARSE_DATE("%Y%m%d",b.datab) AND PARSE_DATE("%Y%m%d",b.datbi)
                    )
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
            (
                PARSE_DATE("%Y%m%d",cast((99999999 - cast(J.validfrom as INTEGER)) as string)) <= current_date
            )
            AND J.LAND1    = 'BR'
            AND J.SHIPFROM = J.SHIPTO
    )
select
    loja.cod_gama, loja.descricao, loja.vtweg, loja.bukrs, loja.werks, loja.vkorg, loja.func_par, loja.kunnr, 
    loja.lifnr, zco2.produto, zco2.faixa, 0 as perc_comis, 
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
    end as COMIS_G2, '0' as disponivel, '0' as transito, y44.meses, y44.lgort
from
    w_loja as loja -- SELECT distinct cod_gama FROM `dados-dev.visoes_cimed_tech.CV_LOJAS_OFFLINE_TESTE` 

join
    w_zco2 as zco2 -- "_SYS_BIC"."MAT_BQ/CV_TR_LOJAS_PRECO_GERAL"
    on zco2.vkorg        = loja.vkorg
        and zco2.func_par = loja.func_par
        and zco2.produto  = loja.matnr
join
    w_zfat as zfat -- "_SYS_BIC"."MAT_BQ/CV_TR_LOJAS_PRECO_GERAL"
    on zfat.produto = zco2.produto
left join
    w_zsta as zsta -- "_SYS_BIC"."MAT_BQ/CV_TR_LOJAS_PRECO_GERAL"
    on zsta.vkorg       = zco2.vkorg
        and zsta.produto = zco2.produto
left join
    w_zqco as zqco -- "_SYS_BIC"."MAT_BQ/CV_TR_LOJAS_PRECO_GERAL"
    on zqco.vkorg       = zco2.vkorg
        and zqco.produto = zco2.produto
        and zqco.faixa+2 = zco2.faixa
        --AEO 31.01.22 ajuste para PMG X carga
left join
    w_zpfa as zpfa -- "_SYS_BIC"."MAT_BQ/CV_TR_LOJAS_PRECO_GERAL"
    on zpfa.produto   = zco2.produto
        and zpfa.vkorg = zco2.vkorg
left join
    w_zpmc as zpmc -- "_SYS_BIC"."MAT_BQ/CV_TR_LOJAS_PRECO_GERAL"
    on zpmc.produto   = zco2.produto
        and zpmc.vkorg = zco2.vkorg
join
    w_ydsd044 as y44
    on y44.werks = loja.werks 
) P
on mat.codigo = P.produto
left join
    ultima_compra as ult -- "_SYS_BIC"."MAT_BQ/CV_TR_MAT_ULTIMA_COMPRA"
    on ult.kunnr     = P.kunnr
    and ult.matnr = P.produto
left join
    w_contexto as cont -- postgres
    on cont.produto = P.produto
        and (cont.vkorg = '' OR cont.vkorg = p.vkorg)
left join
    w_validade_curta as vc -- "_SYS_BIC"."MAT_BQ/CV_TR_LOJAS_PRECO_GERAL"
    on vc.vkorg       = p.vkorg
    AND vc.produto = p.produto
group by
    mat.codigo, mat.codigobarras, mat.descricao_material, mat.principioativo, mat.generico, mat.codigo_ms, mat.linha, mat.status, 
    MAT.C_CONTROLADO, MAT.PRODUTO_HIERARQUIA, MAT.cod_hierarquia, MAT.GRP_MERCADORIA, mat.fabricante, mat.caixa_padrao, mat.ipi, 
    mat.farm_popular, mat.prod_marca, mat.prod_classei, mat.prod_fator, mat.ncm, mat.grpmercexterno,MAT.hierarquia, P.cod_gama, 
    P.descricao, P.vtweg, P.bukrs, P.werks,P.vkorg, P.func_par, P.kunnr, P.lifnr, P.produto, ult.vlr_unit, ult.ult_qde, ult.erdat, 
    MAT.MENU_CATEGORIA, MAT.NUM_CATEGORIA, cont.FILTRO_CONTEXTO_ID, cont.FILTRO_CONTEXTO_NOME, vc.valor, vc.saldo, P.LGORT, p.MESES, p.TRANSITO, p.DISPONIVEL,
    V_ZFAT, V_ZSTA, ZPFA, ZPMC, COMBO, mat.url