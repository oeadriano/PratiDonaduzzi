
create table sf.empresa 
(
	empresa varchar(04), 
	centro varchar(04), 	
	organizacao_vendas varchar(04),
	deposito varchar(04) not null, 
	name varchar(50) not null,
	uf varchar(02) not null,
	meses varchar(02) not null,
	crossdocking varchar(01),
	CONSTRAINT empresa_pkey PRIMARY KEY (empresa, centro, organizacao_vendas)
);

-- select para a api
select 
    y218.bukrs as empresa, 
    y218.werks as centro, 
    y218.vkorg as organizacao_vendas, 
    y44.lgort as deposito,
    y218.NAME1 as name, 
    y218.uf, 
    y44.MESES as meses, 
    'N' as crossdocking
from 
    `dados-dev.raw.YDSD218` y218
join   
    `dados-dev.raw_cimed_tech.YDSD044` y44
    on y44.WERKS = y218.WERKS
