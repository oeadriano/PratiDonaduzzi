-- funcão
-- codigo superiro 
-- CV_VIEW_SF_CADASTRO_REPRESENTANTES

-- limpar emrpesas antigas na condicao de pagamento

api de cadeira incremental na lifnr cliente 
cadeira -> representante wyt3 ? 
cadeira -> cliente ???

@Adriano Oliveira segue EXTERNAL_QUERY com o problema resolvido:

WITH Q1 AS (
    SELECT * FROM EXTERNAL_QUERY("projects/dados-dev/locations/us/connections/cimed-postgres-us", "SELECT codigo_sap_C, categoria_produtoc FROM sf.atrib_produto ORDER BY codigo_sap_c ASC;")
)
SELECT * FROM `dados-dev.raw_cimed_tech.CV_CADASTRO_MATERIAL_T` as MAT
JOIN Q1 AS M ON MAT.CODIGO = M.codigo_sap__C

duvidas:
- atributo é qual categoria do sf q eta mockado no tfransform da api

-campanha
	type destaque ? filgro de contexto type=destaque usar tipo_de_destaque
	.PRODUTOS_DESTAQUE__C cabelho e filtro
	
- promocao

- produtos_destaque?

