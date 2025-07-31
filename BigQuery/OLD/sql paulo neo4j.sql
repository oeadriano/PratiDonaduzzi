-- Custo do produto (ZFAT)
SELECT  
  distinct produto, V_ZFAT, V_ZSTA
FROM 
  `dados-prod.sap.VH_TR_LOJAS_PRECO_GERAL` 
order by produto


-- Relação entre clientes e o CD origem
SELECT 
  distinct C.codigo, C.vkorg, C.cli_est, E.VKORG AS VKORG_EMP
FROM 
  `dados-prod.sap.VH_TR_REP_CLIENTES` C 
LEFT JOIN
  `dados-prod.sap.VH_MD_EMPRESAS` E
  ON E.UF = C.CLI_EST
WHERE 
  E.ATIVA = 'S' AND E.VKORG <> '1100' 
  AND C.VKORG = E.VKORG
ORDER BY 
  VKORG, CODIGO
  
-- Equivalencia categorias  
select Codigo_SAP__c, Categoria_Produto__r.name, Family, cgcloud__Criterion_1_Product__r.name, cgcloud__Criterion_2_Product__r.name
from Product2 
where
RecordType.name = 'Product' and cgcloud__Criterion_1_Product__r.name = 'VITAMINAS' and (NOT name LIKE '%Outlet%')