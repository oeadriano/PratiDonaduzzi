--sap_view.VB_TR_LOJAS_PRECOS
with 
    w_url as (
        select
            'https://bula.cimedremedios.com.br/' as url
    )    
    , w_material as
    (   
        select
            matnr as codigo, ean11 as codigobarras, MAKTX as descricao_material, 
            principioativo, generico, lista, codigo_ms, 
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
            steuc as ncm, extwg as grpmercexterno, url.url
        from
            `dados-prod.sap.VH_MD_MATERIAL` as mat
        cross join 
            w_url as url
        where
            -- foi retirado o filtro de status na criação 
            -- da tabela de materiais, aqui precisa filtrar
            --MATNR between '000000000000100000' and '000000000000199999'            
            --AND 
            coalesce(MSTAE, '') in ('', 'Y5') 
            AND mtart IN ('FERT', 'HAWA', 'YMKT') 
    )
select
    mat.DESCRICAO_MATERIAL, substring(mat.codigo, 13, 6) AS PRODUTO,
    mat.url||substring(MAT.hierarquia, 1, 3) 
    || '/'
    ||substring(MAT.hierarquia, 4, 3)
    || '/'
    ||substring(MAT.hierarquia, 7, 3)
    ||'/'
    ||substring(MAT.hierarquia, 10, 3)
    ||'/'
    ||substring(mat.codigo,13,6)
    ||'/'
    ||substring(mat.codigo,13,6)
    ||'-B.pdf' as BULA
from
    w_material as mat
where
    coalesce(mat.hierarquia, '') <> ''