SELECT 
    pedido_sap, data, pedido_portal, forma_pagamento, razao_social, cnpj, valor, status, lifnr 
FROM 
    dados-dev.visoes_cimed_tech.CV_VIEW_PEDIDOS_CLIENTE 
WHERE 
    cliente = '0001005864' 
	AND data >= PARSE_DATE('%Y%m%d','20210101') AND data <= PARSE_DATE('%Y%m%d', '20210901')
