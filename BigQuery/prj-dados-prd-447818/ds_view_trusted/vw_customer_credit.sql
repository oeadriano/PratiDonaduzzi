CREATE VIEW `prj-dados-prd-447818.ds_view_trusted.vw_customer_credit`
AS with 
  w_conta_credito as (
  select 
    Conta_credito__c, 
    ROUND( cast( sum(Limite_de_credito__c) as FLOAT64 ), 2) as Limite_consolidado__c, 
    ROUND( cast( sum(Compromisso_total__c)  as FLOAT64 ), 2) as Compromisso_consolidado__c, 
    ROUND( cast( sum(Credito_disponivel__c)  as FLOAT64 ), 2) as Credito_disponivel_consolidado__c    
  from `ds_view_trusted.vw_customer_credit_base`
  group by Conta_credito__c 
)
SELECT
  ltrim(b.cgcloud__ExternalId__c, '0') as cgcloud__ExternalId__c,
  case
    when ltrim(b.Conta_credito__c, '0') <> ltrim(b.cgcloud__ExternalId__c, '0') then ltrim(b.Conta_credito__c, '0') 
    else ''
  end as Conta_credito__c,   
  
  case
    when ltrim(b.Conta_credito__c, '0') <> ltrim(b.cgcloud__ExternalId__c, '0') then 0.0
    else b.Limite_de_credito__c
  end as Limite_de_credito__c,  

  b.Compromisso_total__c,
  b.Credito_disponivel__c,
  c.Limite_consolidado__c,
  c.Compromisso_consolidado__c,
  c.Credito_disponivel_consolidado__c,
  b.Classe_de_risco__c, 
  b.Tabela_Preco__c, 
  b.Preco_Negociado__c, 
  b.CustomerGroup__c, 
  b.SalesDistrict__c,
  b.Industry,  
  b.AccountGroup__c,
  b.ServiceTeam__c
FROM 
  `ds_view_trusted.vw_customer_credit_base` b
JOIN 
  w_conta_credito c
  ON c.Conta_credito__c = b.Conta_credito__c
order by
  b.cgcloud__ExternalId__c
;