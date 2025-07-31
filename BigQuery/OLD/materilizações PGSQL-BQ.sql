1)Materializar
	de-> 
		SELECT 
			DISTINCT CODIGO_SAP__C, ID_CATEGORIA, CATEGORIA_PRODUTO__C   
		FROM 
		  EXTERNAL_QUERY("projects/dados-dev/locations/us/connections/cimed-postgres-us ", "SELECT codigo_sap__c, id_categoria, categoria_produto__c FROM sf.atrib_produto ORDER BY codigo_sap__c;")	
	para-> sap_view.TB_TR_ATRIB_PRODUTO
	OBS: tabela sap_view.TB_TR_ATRIB_PRODUTO já está criada em DEV e PROD, mas sem a coluna LAST_UPDATE, tem que incluir
	
2)Materializar
	de-> 
	CREATE TABLE sap_view.TB_TR_VIEW_DESTAQUE_COMBO
		AS 
		  SELECT 
			distinct COMBO, FILTRO_CONTEXTO_ID, FILTRO_CONTEXTO_NOME, PRODUTO, VKORG, current_timestamp as LAST_UPDATE
		  from 
			EXTERNAL_QUERY("projects/dados-prod/locations/southamerica-east1/connections/cimed-postgres ", "select * from sf.view_destaque_combos;")
	para-> sap_view.TB_TR_VIEW_DESTAQUE_COMBO
	OBS: tabela TB_TR_VIEW_DESTAQUE_COMBO já está criada em DEV e PROD

