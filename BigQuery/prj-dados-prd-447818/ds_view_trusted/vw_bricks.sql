CREATE VIEW `prj-dados-prd-447818.ds_view_trusted.vw_bricks`
AS WITH base AS (
  -- Base de vendas detalhada por produto, cliente, brick, UF e mês
  SELECT
    BrickOld__c,
    BrickNew__c,
    UF,
    ProductCode__c,
    client_id,
    fkimg,
    ReferenceMonth__c,
    erdat
  FROM `prj-dados-prd-447818.ds_view_trusted.vw_aux_product_sales_by_brick`
  WHERE erdat >= DATE_SUB(CURRENT_DATE(), INTERVAL 12 MONTH)
    AND BrickOld__c IS NOT NULL AND BrickOld__c != ''
    AND BrickNew__c IS NOT NULL AND BrickNew__c != ''
),
pdv_counts AS (
  -- Conta a quantidade de CNPJs (PDVs) distintos por BrickNew
  SELECT
    BrickNew__c,
    COUNT(DISTINCT EINId__c) AS qtd_pdv
  FROM `prj-dados-prd-447818.ds_view_trusted.vw_customer`
  WHERE EINId__c IS NOT NULL
  GROUP BY BrickNew__c
),
fallback_bricks AS (
  -- Fallback: para Bricks com 2 ou menos PDVs, usa BrickOld como referência
  SELECT
    b.BrickOld__c,
    b.BrickNew__c,
    b.UF,
    b.ProductCode__c,
    -- Quantidade de PDVs no BrickNew
    pc.qtd_pdv AS PdvCount__c,
    -- Soma das unidades vendidas
    SUM(b.fkimg) AS TotalUnitsSold__c,
    b.ReferenceMonth__c,
    -- Data da última atualização
    CURRENT_DATE() AS LastUpdateDate__c,
    -- Indica que houve fallback para BrickOld
    TRUE AS Fallback__c
  FROM base b
  JOIN pdv_counts pc ON b.BrickNew__c = pc.BrickNew__c
  WHERE pc.qtd_pdv <= 2
  GROUP BY b.BrickOld__c, b.BrickNew__c, b.UF, b.ProductCode__c, b.ReferenceMonth__c, pc.qtd_pdv
),
normal_bricks AS (
  -- Normal: para Bricks com mais de 2 PDVs, usa BrickNew normalmente
  SELECT
    b.BrickOld__c,
    b.BrickNew__c,
    b.UF,
    b.ProductCode__c,
    -- Quantidade de PDVs no BrickNew
    pc.qtd_pdv AS PdvCount__c,
    -- Soma das unidades vendidas
    SUM(b.fkimg) AS TotalUnitsSold__c,
    b.ReferenceMonth__c,
    -- Data da última atualização
    CURRENT_DATE() AS LastUpdateDate__c,
    -- Indica que NÃO houve fallback
    FALSE AS Fallback__c
  FROM base b
  JOIN pdv_counts pc ON b.BrickNew__c = pc.BrickNew__c
  WHERE pc.qtd_pdv > 2
  GROUP BY b.BrickOld__c, b.BrickNew__c, b.UF, b.ProductCode__c, b.ReferenceMonth__c, pc.qtd_pdv
)

-- Consolida os resultados finais, unindo os casos de fallback e normais
SELECT * FROM fallback_bricks
UNION ALL
SELECT * FROM normal_bricks;