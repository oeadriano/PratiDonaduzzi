-- dados-dev.sap_view.VB_TR_MATERIAL_CONTEXTOS
with 
    w_categoria as (
        SELECT codigo_sap__c as PRODUTO, id_categoria AS NUM_CATEGORIA, categoria_produto__c AS MENU_CATEGORIA
        FROM 
		--prod
		EXTERNAL_QUERY("projects/dados-dev/locations/us/connections/cimed-postgres-us", "SELECT codigo_sap__c, id_categoria, categoria_produto__c FROM sf.atrib_produto ORDER BY codigo_sap__c;")
        --PROD	
       --EXTERNAL_QUERY("projects/dados-prod/locations/southamerica-east1/connections/cimed-postgres ", "SELECT codigo_sap__c, id_categoria, categoria_produto__c FROM sf.atrib_produto ORDER BY codigo_sap__c;")   
    ),
    w_combo as (        
        --DEV
        SELECT * FROM EXTERNAL_QUERY("projects/dados-dev/locations/us/connections/cimed-postgres-us", "SELECT DISTINCT 'Combo' AS id, p.produto__c as produto FROM  SF.CADASTROCOMBO__C AS C JOIN  SF.PRODUTOSCOMBO__C AS P  ON P.CADASTROCOMBO__C = C.ID WHERE  c.tipocombo__c ILIKE 'Combo%'  AND c.ativo__c = 'true';")        
        --EXTERNAL_QUERY("projects/dados-dev/locations/us/connections/cimed-postgres-us", "SELECT DISTINCT 'Combo' AS id, p.produto__c as produto FROM  SF.CADASTROCOMBO__C AS C JOIN  SF.PRODUTOSCOMBO__C AS P  ON P.CADASTROCOMBO__C = C.ID WHERE  c.tipocombo__c ILIKE 'Combo%'  AND c.ativo__c = 'true';")        
        --prod
        --SELECT * FROM EXTERNAL_QUERY("projects/dados-prod/locations/southamerica-east1/connections/cimed-postgres ", "SELECT DISTINCT 'Combo' AS id, p.produto__c as produto FROM  SF.CADASTROCOMBO__C AS C JOIN  SF.PRODUTOSCOMBO__C AS P  ON P.CADASTROCOMBO__C = C.ID WHERE  c.tipocombo__c ILIKE 'Combo%'  AND c.ativo__c = 'true';")
    )    
    , w_material as
    (   
        select
            matnr, w_cat.MENU_CATEGORIA, w_cat.NUM_CATEGORIA, 
            coalesce(combo.id, '') as COMBO
        from
            `dados-dev.sap.VH_MD_MATERIAL` as mat
        left join 
            w_categoria as w_cat
            on w_cat.produto = matnr
        left join 
            w_combo as combo
            on combo.produto = matnr            
        where
            -- foi retirado o filtro de status na criação 
            -- da tabela de materiais, aqui precisa filtrar
            MATNR between '000000000000100000' and '000000000000199999'            
            AND coalesce(MSTAE, '') in ('', 'Y5') 
            AND mtart IN ('FERT', 'HAWA', 'YMKT') 
    )
    , w_contexto AS
    (
        SELECT
            produto, NOME as FILTRO_CONTEXTO_NOME, id as FILTRO_CONTEXTO_ID, '' as VKORG
        FROM
            --prod
            EXTERNAL_QUERY("projects/dados-dev/locations/us/connections/cimed-postgres-us", "SELECT * from sf.view_prd_destaque")
            --PROD
            --EXTERNAL_QUERY("projects/dados-prod/locations/southamerica-east1/connections/cimed-postgres", "SELECT * from sf.view_prd_destaque") 
        --UNION ALL
        --SELECT
        --    PRODUTO, 'Outlet' as FILTRO_CONTEXTO_NOME, 'Outlet' as FILTRO_CONTEXTO_ID, VKORG
        --FROM            
        --    `dados-dev.sap.VH_TR_VALIDADE_CURTA`
    )
select
    matnr as PRODUTO, 
    coalesce(MAT.MENU_CATEGORIA, '') as MENU_CATEGORIA, 
    coalesce(MAT.NUM_CATEGORIA, '') as NUM_CATEGORIA,
    case 
        when coalesce(cont.FILTRO_CONTEXTO_ID, '') <> '' then coalesce(cont.FILTRO_CONTEXTO_ID, '')
        else COMBO
    end as FILTRO_CONTEXTO_ID, 
    case 
        when coalesce(cont.FILTRO_CONTEXTO_NOME, '') <> '' then coalesce(cont.FILTRO_CONTEXTO_NOME, '')
        else COMBO
    end as FILTRO_CONTEXTO_NOME,
    coalesce(cont.vkorg, '') as VKORG, 
    CURRENT_TIMESTAMP AS LAST_UPDATE
from
    w_material as mat
left join
    w_contexto as cont -- postgres
    on cont.produto = mat.matnr
order by matnr