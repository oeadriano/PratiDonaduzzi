CREATE VIEW `prj-dados-prd-447818.ds_view_trusted.vw_cgcloud__warehouse__c`
AS with w_uf as (
  SELECT 'AC' AS uf, 'ACRE' AS estado UNION ALL
  SELECT 'AL', 'ALAGOAS' UNION ALL
  SELECT 'AP', 'AMAPA' UNION ALL
  SELECT 'AM', 'AMAZONAS' UNION ALL
  SELECT 'BA', 'BAHIA' UNION ALL
  SELECT 'CE', 'CEARA' UNION ALL
  SELECT 'DF', 'DISTRITO FEDERAL' UNION ALL
  SELECT 'ES', 'ESPIRITO SANTO' UNION ALL
  SELECT 'GO', 'GOIAS' UNION ALL
  SELECT 'MA', 'MARANHAO' UNION ALL
  SELECT 'MT', 'MATO GROSSO' UNION ALL
  SELECT 'MS', 'MATO GROSSO DO SUL' UNION ALL
  SELECT 'MG', 'MINAS GERAIS' UNION ALL
  SELECT 'PA', 'PARA' UNION ALL
  SELECT 'PB', 'PARAIBA' UNION ALL
  SELECT 'PR', 'PARANA' UNION ALL
  SELECT 'PE', 'PERNAMBUCO' UNION ALL
  SELECT 'PI', 'PIAUI' UNION ALL
  SELECT 'RJ', 'RIO DE JANEIRO' UNION ALL
  SELECT 'RN', 'RIO GRANDE DO NORTE' UNION ALL
  SELECT 'RS', 'RIO GRANDE DO SUL' UNION ALL
  SELECT 'RO', 'RONDONIA' UNION ALL
  SELECT 'RR', 'RORAIMA' UNION ALL
  SELECT 'SC', 'SANTA CATARINA' UNION ALL
  SELECT 'SP', 'SAO PAULO' UNION ALL
  SELECT 'SE', 'SERGIPE' UNION ALL
  SELECT 'TO', 'TOCANTINS'
)
SELECT 
  ExternalId__c, 
  cgcloud__Sales_Org__c, 
  cgcloud__State__c, 
  cgcloud__City__c, 
  cgcloud__Country__c,   
  -- nome da empresa para facilitar o TV
  case 
    when EmpresaOperador__c = 'Empresa' and cgcloud__description_language_1__c like '%PRATI%' then SAPPlant__c ||' - '||'PRATI' ||' - ' || uf.uf
    when EmpresaOperador__c = 'Empresa' and cgcloud__description_language_1__c like '%NDS%' then  SAPPlant__c ||' - '||'NDS' ||' - ' || uf.uf    
    when EmpresaOperador__c <> 'Empresa' then  operador_code ||' - '|| cgcloud__description_language_1__c ||' - ' || uf.uf        
    else cgcloud__description_language_1__c
  end as cgcloud__description_language_1__c, 
  EmpresaOperador__c, 
  SAPSalesOrg__c, 
  SAPPlant__c, 
  SAPStoreLoc__c, 
  '' as SAPDivision__c, 
  operador_code
FROM   
  `postgres_raw.warehouse`  
left join w_uf as uf 
  on uf.estado = cgcloud__State__c

order by 
  ExternalId__c;