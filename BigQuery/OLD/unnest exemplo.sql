
SELECT codigo_pedido_sap__c, ct_campanha
FROM `dados-dev.sap_view.VB_TR_SF_CONSULTA_PEDIDOS` 
where data_ov__C >= '2022-05-01'  and ct_campanha <> ''

SELECT codigo_pedido_sap__c, ct_campanha, campanhaId
FROM `dados-dev.sap_view.VB_TR_SF_CONSULTA_PEDIDOS` , unnest(split(ct_campanha,',')) as campanhaId
where 
  data_ov__c >= '2022-05-10' 
  and codigo_pedido_sap__C in ('0005743347', '0005743830', '0004785264')
--where data_ov__C >= '2022-05-01'  and ct_campanha <> ''