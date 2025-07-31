SELECT * FROM `dados-dev.visoes_cimed_tech.CV_LOJAS_CONTEXTOS` LIMIT 1000

SELECT * FROM dados-dev.raw_cimed_tech.CV_LOJAS_CONTEXTOS_T

CREATE TABLE dados-dev.raw_cimed_tech.CV_LOJAS_CONTEXTOS_T AS
SELECT * FROM dados-dev.visoes_cimed_tech.CV_LOJAS_CONTEXTOS

INSERT INTO raw_cimed_tech.CV_LOJAS_CONTEXTOS_T (SELECT * FROM dados-dev.visoes_cimed_tech.CV_LOJAS_CONTEXTOS);

DELETE FROM raw_cimed_tech.CV_LOJAS_CONTEXTOS_T WHERE last_update < (SELECT MAX(last_update) from raw_cimed_tech.CV_LOJAS_CONTEXTOS_T)


-- CV_LOJAS_CONTEXTOS
with w_categoria as (
    select                
        codigo, MENU_CATEGORIA, NUM_CATEGORIA, COMBO
    from
        dados-dev.raw_cimed_tech.CV_CADASTRO_MATERIAL_T
    where
        -- foi retirado o filtro de status na criação 
        -- da tabela de materiais, aqui precisa filtrar
        MSTAE in ('', 'Y5')  
)
, w_validade_curta as
(
    SELECT
        PRODUTO, VALOR, SALDO, VKORG
    FROM
        dados-dev.visoes_auxiliares_cimed_tech.CV_VIEW_VALIDADE_CURTA
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
)
select
    substring(mat.codigo, 13, 6) AS PRODUTO,
    mat.MENU_CATEGORIA, mat.NUM_CATEGORIA, 
    case 
        when coalesce(cont.FILTRO_CONTEXTO_ID, '') <> '' then coalesce(cont.FILTRO_CONTEXTO_ID, '')
        else COMBO
    end as FILTRO_CONTEXTO_ID, 
    case 
        when coalesce(cont.FILTRO_CONTEXTO_NOME, '') <> '' then coalesce(cont.FILTRO_CONTEXTO_NOME, '')
        else COMBO
    end as FILTRO_CONTEXTO_NOME, 
    coalesce(cont.vkorg, '') as VKORG,
	CURRENT_TIMESTAMP as last_update
from 
    w_categoria as mat
left join
    w_contexto as cont
    on cont.produto = mat.codigo