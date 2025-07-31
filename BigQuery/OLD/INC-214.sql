-- CORREÇÃO  INC00000214
de: cast(REPLACE(cabecalho.pedido, 'CT-', '') as INT64) as timestamp_pedido
para: cast(REPLACE(REPLACE(cabecalho.pedido, 'CT-', ''), '-B', '') as INT64) as timestamp_pedido

view´s em DEV
- dados-dev.sap_view.VB_TR_PEDIDOS_CLIENTE
	-- INC00000214 cast(REPLACE(cabecalho.pedido, 'CT-', '') as INT64) as timestamp_pedido, cabecalho.razao_social,         
		
- dados-dev.sap_view.VB_TR_PEDIDOS_COMBO
	-- INC00000214 cast(REPLACE(cabecalho.pedido, 'CT-', '') as INT64) as timestamp_pedido, cabecalho.razao_social,         
	
- dados-dev.sap_view.VB_TR_SF_CONSULTA_PEDIDOS	
	-- INC00000214 cast(REPLACE(cabecalho.pedido, 'CT-', '') as INT64) as timestamp_pedido, cabecalho.razao_social,         