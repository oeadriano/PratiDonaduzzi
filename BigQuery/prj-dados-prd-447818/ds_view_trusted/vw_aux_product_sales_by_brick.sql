CREATE VIEW `prj-dados-prd-447818.ds_view_trusted.vw_aux_product_sales_by_brick`
AS SELECT
    -- Código do agrupamento Brick anterior
    CUSTOMER.BrickOld__c,
    -- Código do agrupamento Brick atual
    CUSTOMER.BrickNew__c,
    -- UF do cliente
    CUSTOMER.billingstate AS UF,
    -- Código do produto
    PRODUCT.ProductCode AS ProductCode__c,
    -- CNPJ do cliente (padronizado)
    LPAD(CUSTOMER.cgcloud__externalid__c, 10, '0') AS client_id,
    -- Quantidade vendida
    CII.fkimg,
    -- Mês de referência da venda
    FORMAT_DATE('%m/%Y', CII.erdat) AS ReferenceMonth__c,
    -- Data original da venda (para filtro posterior)
    CII.erdat AS erdat
FROM `prj-dados-prd-447818.ds_view_trusted.vw_customer` AS CUSTOMER
JOIN `prj-dados-prd-447818.ds_view_trusted.vw_customer_invoice_items` AS CII
  ON LPAD(CUSTOMER.cgcloud__externalid__c, 10, '0') = CII.kunnr
LEFT JOIN `prj-dados-prd-447818.ds_view_trusted.vw_cgcloud_product2_hierarquia` AS PRODUCT
  ON REGEXP_REPLACE(CII.matnr, r'^0+', '') = REGEXP_REPLACE(PRODUCT.matnr, r'^0+', '')
WHERE CII.fkimg IS NOT NULL
  AND CII.erdat >= DATE_SUB(CURRENT_DATE(), INTERVAL 12 MONTH)
  AND CUSTOMER.BrickOld__c IS NOT NULL AND CUSTOMER.BrickOld__c != ''
  AND CUSTOMER.BrickNew__c IS NOT NULL AND CUSTOMER.BrickNew__c != ''
  AND LPAD(CUSTOMER.cgcloud__externalid__c, 10, '0') NOT IN (
      SELECT LPAD(ExternalId__c, 10, '0')
      FROM `prj-dados-prd-447818.ds_view_trusted.vw_cgcloud__warehouse__c`
      WHERE EmpresaOperador__c = 'Operador Logístico'
  );