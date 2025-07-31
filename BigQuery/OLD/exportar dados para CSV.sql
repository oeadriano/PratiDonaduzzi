-- criar tabela com o select 

CREATE TABLE dados-dev.raw_cimed_tech.CV_MAT_ULTIMA_COMPRA_T as 
(SELECT * OM `dados-dev.visoes_auxiliares_cimed_tech.CV_MAT_ULTIMA_COMPRA`)

-- abria tabela, no canto superior direito exportar, escolhar caminho e salvar

-- url abaixo para baixar o arquivos
https://console.cloud.google.com/storage/browser/arqdados-data-loaders-prod


- dados-dev:visoes_cimed_tech.CV_SF_CONDICAO_PAGAMENTO
- dados-dev:visoes_cimed_tech.CV_SF_CONSULTA_PEDIDOS 



{

SELECT * FROM sap_view.VIEW_SF_CONSULTA_PEDIDOS 
where 

timestamp(LAST_UPDATE) >= timestamp_sub(current_timestamp , INTERVAL 1440 MINUTE) and Codigo_Pedido_SAP__c is not null order by LAST_UPDATE desc