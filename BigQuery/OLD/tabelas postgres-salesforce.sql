drop table sf.empresa;

select * from sf.empresa;

create table sf.empresa 
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

-- select para a api
select 
    y218.bukrs as Empresa__c, 
    y218.werks as Centro__c, 
    y218.vkorg as Organizacao_Vendas__c, 
    y44.lgort as Deposito__c,
    y218.NAME1 as name, 
    y218.UF__c, 
    y44.MESES as Meses__c, 
    'N' as Crossdocking__c
from 
    `dados-dev.raw.YDSD218` y218
join   
    `dados-dev.raw_cimed_tech.YDSD044` y44
    on y44.WERKS = y218.WERKS
order by
	y218.bukrs


