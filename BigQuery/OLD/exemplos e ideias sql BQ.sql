        WITH w_cat AS (
			SELECT * FROM EXTERNAL_QUERY("projects/dados-dev/locations/us/connections/cimed-postgres-us", "SELECT codigo_sap__c, id_categoria, categoria_produto__c FROM sf.atrib_produto ORDER BY codigo_sap__c;")
        ),
        w_array_categoria as (
            select array (
            SELECT as struct id_categoria, categoria_produto__c FROM EXTERNAL_QUERY("projects/dados-dev/locations/us/connections/cimed-postgres-us", "SELECT distinct id_categoria, categoria_produto__c FROM sf.atrib_produto")
            ) as menu_categ
        )        
