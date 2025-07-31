-- dados-dev.b2b.VB_TR_LOJAS_PRECOS_B2B
with 
    w_cat_old AS (
        SELECT * FROM 
		--DEV
		EXTERNAL_QUERY("projects/dados-dev/locations/us/connections/cimed-postgres-us", "SELECT codigo_sap__c, id_categoria, categoria_produto__c FROM sf.atrib_produto ORDER BY codigo_sap__c;")		
        --PROD	
	    --EXTERNAL_QUERY("projects/dados-dev/locations/southamerica-east1/connections/cimed-postgres ", "SELECT codigo_sap__c, id_categoria, categoria_produto__c FROM sf.atrib_produto ORDER BY codigo_sap__c;")
    ),
    w_preco_geral as  
    (
        SELECT * FROM `dados-dev.sap.VH_TR_LOJAS_PRECO_GERAL` 
    ),
    w_categoria as (
        select 
            distinct PRODUTO, MENU_CATEGORIA, NUM_CATEGORIA	
        from 
            `dados-dev.sap.VH_TR_MATERIAL_CONTEXTOS`            
        where
            coalesce(NUM_CATEGORIA||MENU_CATEGORIA, '') <> ''
    ), 
    w_empresa as    
    (
        select distinct
            bukrs, werks, vkorg, lgort, 'L'||meses as meses, UF
        from            
            `dados-dev.sap.VH_MD_EMPRESAS`
        where 
            -- AEO 05.01.2022 - retira o estoque 1005/1016
            lgort <> '1006'
            and werks <> '1001' 
            and werks <> '1100'
            and werks <> '1101'
            and werks <> '1010'         
            and ativa = 'S'
    ),
    w_url as (
        select
            cast(lower(relatorio) as string) as url
        from 
          `dados-dev.sap.VH_MD_YDBI001`
        where 
            filtro = 'GCP' 
            and NOME_VIEW = 'URL_GC_CONTEUDO'
    ),
    w_combo as (        
		SELECT 
            PRODUTO, ID as FILTRO_CONTEXTO_ID, ID asFILTRO_CONTEXTO_NOME, '' as VKORG        
        FROM 
        --DEV
        EXTERNAL_QUERY("projects/dados-dev/locations/us/connections/cimed-postgres-us", "SELECT DISTINCT 'Combo' AS id, p.produto__c as produto FROM  SF.CADASTROCOMBO__C AS C JOIN  SF.PRODUTOSCOMBO__C AS P  ON P.CADASTROCOMBO__C = C.ID WHERE  c.tipocombo__c ILIKE 'Combo%'  AND c.ativo__c = 'true';")        
        --PROD
        --EXTERNAL_QUERY("projects/dados-dev/locations/southamerica-east1/connections/cimed-postgres ", "SELECT DISTINCT 'Combo' AS id, p.produto__c as produto FROM  SF.CADASTROCOMBO__C AS C JOIN  SF.PRODUTOSCOMBO__C AS P  ON P.CADASTROCOMBO__C = C.ID WHERE  c.tipocombo__c ILIKE 'Combo%'  AND c.ativo__c = 'true';")
    )    
    , w_material as
    (   
        select
            matnr as codigo, ean11 as codigobarras, MAKTX as descricao_material, 
            principioativo, generico, lista, coalesce(codigo_ms, '') as codigo_ms, 
            linha, status, c_controlado, PRDHA as produto_hierarquia, 
            substring(PRDHA, 4, 3) as cod_hierarquia, 
            --CLASSEI_DESCR as hierarquia, 
            PRDHA as hierarquia, 
            CASE
                WHEN MATKL IN ('PA01', 'PA02', 'PA03') THEN 'MIP'
                WHEN MATKL IN ('PA04', 'PA05', 'PA06') THEN 'RX'
                WHEN MATKL IN ('PA07', 'PA08', 'PA09', 'PA23', 'PA24', 'PA25') THEN 'Controlados'
                WHEN MATKL IN ('PA10', 'PA16', 'PA17') THEN 'Genéricos'
                WHEN MATKL IN ('PA11') THEN 'Cosméticos'
                WHEN MATKL IN ('PA12') THEN 'Correlatos'
                WHEN MATKL IN ('PA13') THEN 'Suprimentos'
                WHEN MATKL IN ('PA14', 'PA18', 'PA19', 'PA20', 'PA21', 'PA22') THEN 'Hospitalar'
                WHEN MATKL IN ('PA15') THEN 'Terceiros'
                ELSE MATKL
            END AS grp_mercadoria, 
            MATKL as cod_grp_mercadoria,             
            BU_DESCR as fabricante, umrez as caixa_padrao, '' as ipi, farm_popular, prod_marca, 
            ''as prod_classei, '' as prod_fator, 
            steuc as ncm, extwg as grpmercexterno, 
            --w_cat.MENU_CATEGORIA, w_cat.NUM_CATEGORIA, 
            coalesce(cat.categoria_produto__c, '') as MENU_CATEGORIA, coalesce(cat.id_categoria, '') as NUM_CATEGORIA,             
            coalesce(combo.FILTRO_CONTEXTO_ID, '') as COMBO, url.url, 
            case 
                --PA13 alimentos - PA12 correlatos  - PA11 cosméticos                   
                when MATKL in ('PA11', 'PA12', 'PA13') then 'ZOUT'
                else 'ZMED'
            end as material_zmed_zout
													 
        from
            `dados-dev.sap.VH_MD_MATERIAL` as mat
        left join 
            w_cat_old as cat
            on cat.codigo_sap__c = matnr
        left join 
            w_combo as combo
            on combo.produto = matnr            
        cross join 
            w_url as url
        where
            -- foi retirado o filtro de status na criação 
            -- da tabela de materiais, aqui precisa filtrar
            --MATNR between '000000000000100000' and '000000000000199999'            
            --AND 
            coalesce(MSTAE, '') in ('', 'Y5') 
            AND mtart IN ('FERT', 'HAWA', 'YMKT') 
    ),
    w_lif_cli_new as 
    (
        SELECT DISTINCT
            L.VKORG, L.KUNNR, L.LIFNR, 
            C.GRUPO_CONTAS as cliente_zmed_zout, 
            C.CONTROLADO as cliente_vende_controlado
																	 
        FROM
            `dados-dev.sap.VH_MD_LIFNR_CLIENTE` L
        JOIN 
            `dados-dev.sap.VH_TR_CADASTRO_CLIENTES` C
            on C.codigo = L.kunnr
    ),
    w_loja_new as (
    SELECT 
        distinct LJ.BUKRS, LJ.COD_GAMA, LJ.CADEIRA, LJ.LIFNR, LJ.vkorg, LJ.kunnr, LJ.descricao, LJ.vtweg, 
        LJ.werks, coalesce(LJ.func_par, 'X1') as func_par, LP.matnr
    FROM 
        `dados-dev.sap.VH_MD_LOJAS_LIFNR` LJ
    JOIN 
        `dados-dev.sap.VH_MD_LOJAS_PRODUTOS` LP
        ON LP.COD_GAMA = LJ.COD_GAMA
    JOIN 
        w_lif_cli_new lf
        ON LF.LIFNR = LJ.LIFNR
        AND LF.KUNNR = LJ.KUNNR        
        AND LF.VKORG = LJ.VKORG
    JOIN 
        w_material as mat
        on mat.codigo = LP.Matnr
    WHERE 
        (
            (lf.cliente_zmed_zout = 'ZOUT' and mat.material_zmed_zout = 'ZOUT' and mat.c_controlado = 'N')
            OR
            (CASE 
                WHEN lf.cliente_vende_controlado = 'S' THEN
                    lf.cliente_zmed_zout in('ZMED', 'ZSAC') and mat.material_zmed_zout in ('ZOUT', 'ZMED')
                ELSE 
                    lf.cliente_zmed_zout in('ZMED', 'ZSAC') and mat.material_zmed_zout in ('ZOUT', 'ZMED') and mat.c_controlado = 'N'
            END)
        ) 
    )   
    , w_validade_curta as
    (
		
    SELECT
            --PRODUTO, '0' as VALOR, '0' as SALDO, VKORG
            PRODUTO, VALOR, SALDO, VKORG, 'Outlet' as FILTRO_CONTEXTO_ID, 'Outlet' as FILTRO_CONTEXTO_NOME
        FROM            
            `dados-dev.sap.VH_TR_VALIDADE_CURTA`            
    )
    , w_contexto AS
    (
        select 
            distinct C.PRODUTO, 0 AS VALOR, 0 AS SALDO, E.VKORG, C.FILTRO_CONTEXTO_ID, C.FILTRO_CONTEXTO_NOME, 
        from 
            `dados-dev.sap.VH_TR_MATERIAL_CONTEXTOS` C
        cross join
          `dados-dev.sap.VH_MD_EMPRESAS` E
        where
            coalesce(C.FILTRO_CONTEXTO_ID, '') <> ''
        UNION ALL
        SELECT
            --PRODUTO, '0' as VALOR, '0' as SALDO, VKORG
            PRODUTO, VALOR, SALDO, VKORG, 'Outlet' as FILTRO_CONTEXTO_ID, 'Outlet' as FILTRO_CONTEXTO_NOME
        FROM            
            `dados-dev.sap.VH_TR_VALIDADE_CURTA`                    
        order by
            produto, filtro_contexto_id, vkorg        
    )    
select
    MAT.CODIGOBARRAS, MAT.DESCRICAO_MATERIAL, 
    coalesce(MAT.PRINCIPIOATIVO, '') as PRINCIPIOATIVO, MAT.GENERICO, MAT.CODIGO_MS, coalesce(MAT.LINHA, '') as LINHA, MAT.STATUS, MAT.C_CONTROLADO,
    -- ajusta num_categoria
    MAT.MENU_CATEGORIA, MAT.NUM_CATEGORIA, MAT.GRP_MERCADORIA, MAT.FABRICANTE, FORMAT('%.0f',MAT.CAIXA_PADRAO) as CAIXA_PADRAO, MAT.IPI, 
    MAT.FARM_POPULAR, MAT.PROD_MARCA, 
    MAT.PROD_CLASSEI, MAT.PROD_FATOR, MAT.NCM, coalesce(MAT.GRPMERCEXTERNO, '') as GRPMERCEXTERNO, P.COD_GAMA, P.DESCRICAO, P.VTWEG, 
    P.BUKRS, P.WERKS,P.VKORG, P.FUNC_PAR, 
    P.KUNNR, P.LIFNR, substring(P.PRODUTO, 13, 6) AS PRODUTO, 0 AS PERC_COMIS, 
    FORMAT('%.2f',V_ZFAT) AS V_ZFAT, 
    FORMAT('%.2f',V_ZSTA) AS V_ZSTA, 
    FORMAT('%.2f',ZPFA) AS ZPFA, 
    FORMAT('%.2f',ZPMC) AS ZPMC, 
    
    max(FORMAT('%.2f',VALOR_P)) AS VALOR_P, max(FORMAT('%.2f',VALOR_M)) AS VALOR_M, max(FORMAT('%.2f',VALOR_G)) AS VALOR_G, 
    max(FORMAT('%.2f',VALOR_G1)) AS VALOR_G1, max(FORMAT('%.2f',VALOR_G2)) AS VALOR_G2,     
    
    max(QDE_P) AS QDE_P, max(QDE_M) AS QDE_M, max(QDE_G) AS QDE_G, max(QDE_G1) AS QDE_G1, max(QDE_G2) AS QDE_G2, 
    max(COMIS_P) AS COMIS_P, max(COMIS_M) AS COMIS_M, max(COMIS_G) AS COMIS_G,max(COMIS_G1) AS COMIS_G1, max(COMIS_G2) AS COMIS_G2, 
    mat.URL, 
    substring(MAT.hierarquia, 1, 3)
        || '/'
        ||substring(MAT.hierarquia, 4, 3)
        || '/'
        ||substring(MAT.hierarquia, 7, 3)
        ||'/'
        ||substring(MAT.hierarquia, 10, 3)
        ||'/'
        ||substring(P.produto,13,6)
        ||'/' as PATH,       
    substring(P.produto,13,6)||'-I.png' as IMAGEM, 
    substring(P.produto,13,6)||'-B.pdf' as BULA, 
    substring(P.produto,13,6)||'-F.pdf' as FICHA,

    MAX(FORMAT('%.2f',COALESCE(VALOR_VC, 0))) AS VALOR_VC, 
        CASE WHEN MAX(COALESCE(QDE_VC, 0)) = 0 THEN 0 ELSE 1 END AS QDE_VC, 
        0 AS DISPONIVEL_VC, 
    coalesce(ult.vlr_unit, 0) AS ULT_COMPRA_VALOR, 
    cast(coalesce(ult.ult_qde, 0) as integer) AS ULT_COMPRA_QDE, 
    coalesce(ult.erdat, '') AS ULT_COMPRA_DATA, P.LGORT, p.MESES, cast(p.TRANSITO as integer) AS TRANSITO, 
    cast(p.DISPONIVEL as integer) AS DISPONIVEL, 
    '' as FILTRO_CONTEXTO, '' as NUM_FILTRO,     
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
    -- se tem validade valor de VC, tem tag na api
    -- trazer VC de with
    CASE
        WHEN MAX(COALESCE(VALOR_VC, 0)) = 0
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
    (
    select
        loja.cod_gama, loja.descricao, loja.vtweg, loja.bukrs, loja.werks, loja.vkorg, loja.func_par, loja.kunnr, 
        loja.lifnr, zco2.produto, 
        --zco2.faixa, 
        '' as faixa, 0 as perc_comis, 
        coalesce(zco2.V_ZFAT,0) as V_ZFAT, 
        coalesce(zco2.V_ZSTA,0) as V_ZSTA, 
        coalesce(zco2.ZPFA,0) as ZPFA, 
        coalesce(zco2.ZPMC,0) as ZPMC, 
        cast(VALOR_P as numeric) as VALOR_P, 
        cast(VALOR_M as numeric) as VALOR_M, 
        cast(VALOR_G as numeric) as VALOR_G, 
        cast(VALOR_G1 as numeric) as VALOR_G1, 
        cast(VALOR_G2 as numeric) as VALOR_G2, 
        COALESCE(zco2.QDE_P, 1) as QDE_P, 
        COALESCE(zco2.QDE_M, 1) as QDE_M, 
        COALESCE(zco2.QDE_G, 1) as QDE_G, 
        COALESCE(zco2.QDE_G1, 1) as QDE_G1, 
        COALESCE(zco2.QDE_G2, 1) as QDE_G2, 
        COMIS_P, COMIS_M, COMIS_G, COMIS_G1, COMIS_G2,
        vc.VALOR as VALOR_VC, vc.SALDO as QDE_VC, '0' as disponivel, '0' as transito, y44.meses, y44.lgort
    from
        w_loja_new as loja
    join
        w_preco_geral as zco2
        on zco2.vkorg     = loja.vkorg
        and zco2.func_par = loja.func_par
        and zco2.produto  = loja.matnr
    join
        w_empresa as y44
        on y44.werks = loja.werks
        and y44.bukrs = loja.bukrs
        and y44.vkorg = loja.vkorg
    left join 
        w_validade_curta as vc
        on vc.vkorg = loja.vkorg 
        and vc.produto = loja.matnr        
    ) P
    on mat.codigo = P.produto
left join
    --ultima_compra as ult -- "_SYS_BIC"."MAT_BQ/CV_TR_MAT_ULTIMA_COMPRA"
    dados-dev.sap.VH_TR_MAT_ULTIMA_COMPRA as ult
    on ult.kunnr     = P.kunnr
    and ult.vendedor = P.LIFNR
    and ult.matnr = P.produto
left join
    w_contexto as cont -- postgres
    on cont.produto = P.produto
    and cont.vkorg = p.vkorg
--left join
    --w_validade_curta as val -- postgres
    --on val.produto = P.produto
        --and (val.vkorg = p.vkorg)
group by
    mat.codigo, mat.codigobarras, mat.descricao_material, mat.principioativo, mat.generico, mat.codigo_ms, mat.linha, mat.status, 
    MAT.C_CONTROLADO, MAT.PRODUTO_HIERARQUIA, MAT.cod_hierarquia, MAT.GRP_MERCADORIA, mat.fabricante, mat.caixa_padrao, mat.ipi, 
    mat.farm_popular, mat.prod_marca, mat.prod_classei, mat.prod_fator, mat.ncm, mat.grpmercexterno,MAT.hierarquia, P.cod_gama, 
    P.descricao, P.vtweg, P.bukrs, P.werks,P.vkorg, P.func_par, P.kunnr, P.lifnr, P.produto, ult.vlr_unit, ult.ult_qde, ult.erdat, 
    MAT.MENU_CATEGORIA, MAT.NUM_CATEGORIA, cont.FILTRO_CONTEXTO_ID, cont.FILTRO_CONTEXTO_NOME, P.LGORT, p.MESES, p.TRANSITO, p.DISPONIVEL,
    V_ZFAT, V_ZSTA, ZPFA, ZPMC, COMBO, mat.url, cont.FILTRO_CONTEXTO_NOME, cont.FILTRO_CONTEXTO_ID