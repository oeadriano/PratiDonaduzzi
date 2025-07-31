----------Mapa de Dados - Empresas da Con-----------------------------------------------------------------------------
SELECT 
    Conta__c, Empresa__c
FROM `dados-dev.visoes_cimed_tech.CV_VIEW_SF_EMPRESA_CONTA` LIMIT 1000
  {
    "Conta__c": "0000900000",
    "Empresa__c": "1000"
  },
----------Mapa de Dados - Lojas Autoriza-----------------------------------------------------------------------------
SELECT
    bukrs as Empresa__c, 
    werks as Centro__c, 
    cod_gama as Loja__c,  
    lifnr as Representante__c
   FROM 
    `dados-dev.visoes_auxiliares_cimed_tech.CV_YDSD_GAMA_AUTORIZACOES` LIMIT 1000
    "Empresa__c": "1000",
    "Centro__c": "1005",
    "Loja__c": "159",
    "Representante__c": "0000600017"
  }
----------Mapa de Dados - Lojas-----------------------------------------------------------------------------
SELECT * FROM `dados-dev.visoes_cimed_tech.CV_VIEW_SF_LOJAS_PRODUTOS` LIMIT 1000
  {
    "Codigo_Loja__c": "001",
    "Empresa__c": "",
    "Name": "LOJA 1FARMA",
    "Tipo_Loja__c": "C",
    "Produto__c": "100000"
  }
Nesta view tem lojas ativas e os produtos ativos vinculados. 

----------Mapa de Dados - Cond Pagamento-----------------------------------------------------------------------------
SELECT * FROM `dados-dev.visoes_cimed_tech.CV_SF_CONDICAO_PAGAMENTO` 
  {
    "Org_Vendas__c": "2000",
    "Codigo_Condicao_Pagamento__c": "1000",
    "Name": "7",
    "Quantidade_Parcelas__c": "1",
    "Exclusiva_Cliente__c": "N",
    "Exclusiva_Combo__c": "N",
    "Exclusiva_Rede__c": "N"
  }

----------Mapa de Dados - Empresa-----------------------------------------------------------------------------
table sf.empresa 
(
	Empresa__c varchar(04), 
	Centro__c varchar(04), 	
	Organizacao_Vendas__c varchar(04),
	Deposito__c varchar(04) not null, 
	name varchar(50) not null,
	UF__c varchar(02) not null,
	Meses__c varchar(02) not null,
	Crossdocking__c varchar(01),
	CONSTRAINT empresa_pkey PRIMARY KEY (Empresa__c, Centro__c, Organizacao_Vendas__c)
);
SELECT * FROM `dados-dev.visoes_cimed_tech.CV_VIEW_SF_EMPRESA` LIMIT 1000  
  {
    "Empresa__c": "1000",
    "Centro__c": "1005",
    "Organizacao_Vendas__c": "1000",
    "Deposito__c": "1006",
    "name": "PREDILETA-MG",
    "UF__c": "MG",
    "Meses__c": "06",
    "Crossdocking__c": "N"
  }