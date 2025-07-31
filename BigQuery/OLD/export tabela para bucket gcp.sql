CREATE TABLE dados-prod.Apoio.export_0101_2905 as 
(SELECT * FROM `dados-prod.sap_view.VB_TR_SF_CONSULTA_PEDIDOS` order by data_ov__c)


-- abria tabela, no canto superior direito exportar, escolhar caminho e salvar
-- url abaixo para baixar o arquivos

*** Export table to Google Cloud Storage

https://console.cloud.google.com/storage/browser/arqdados-data-loaders-prod

exemplo:
	arqdados-data-loaders-prod/pedidos_cgcloud_101124

despois de salvar no GCS, baixar a tabela


CREATE TABLE  dados-prod.Apoio.EXPORT_PEDIDOS_ as 
(
select * from `dados-prod.visoes_cimed_tech.CV_SF_CONSULTA_PEDIDOS`
WHERE DATA_OV__C between '2022-03-21' and  '2022-03-21'
)

CREATE TABLE  dados-prod.Apoio.EXPORT_PEDIDOS_2706_2906 as 
(
select * 
FROM `dados-prod.sap_view.VB_TR_SF_CONSULTA_PEDIDOS` 
WHERE DATA_OV__C between '2022-06-27' and  '2022-06-29'
)

 limit 1