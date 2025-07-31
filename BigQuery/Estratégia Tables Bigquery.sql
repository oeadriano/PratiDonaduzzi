
/**************************************************
1) analisa ultima alteração da tabela origem
select max(recordstamp) from  `sap_raw.vbkd` --165851
select count(*) from  `sap_raw.vbkd` --6441982

2) dropa PK
ALTER TABLE `sap_raw.vbkd` DROP PRIMARY KEY;

3) renomear
ALTER TABLE sap_raw.vbkd RENAME TO vbkd_old

4) cria nova com partition e cluster
CREATE TABLE sap_raw.vbkd
PARTITION BY DATE(recordstamp)
CLUSTER BY vbeln 
AS
SELECT *
FROM `sap_raw.vbkd_old`

5) cria nova PK ou PK
--PK
ALTER TABLE `sap_raw.vbkd` ADD PRIMARY KEY (vbeln) NOT ENFORCED;

--FK
--ALTER TABLE `sap_raw.vbrp`
ADD CONSTRAINT fk_vbrp_vbeln -- Nome opcional para sua Foreign Key
FOREIGN KEY (vbeln) -- Coluna na tabela 'vbap' que é a Foreign Key
REFERENCES `sap_raw.vbrk` (vbeln) -- Tabela e coluna que ela referencia (a PK em 'vbak')
NOT ENFORCED;

select max(recordstamp) from  `sap_raw.vbkd` --165851
select count(*) from  `sap_raw.vbkd` --6441982

****************************************************/	
tabela PAI 
	- particionamento recorstamp
	- cluster por data
tabela filha
	- particionamento por recorstamp
	- cluster pela FK do PAI

-- faltou VBKD

VBAK(cabeçalho)
	PARTITION BY recorstamp
	CLUSTER BY erdat
VBAP(item)
	PARTITION BY recorstamp
	CLUSTER BY vbeln	
	
VBRK(cabeçalho)
	PARTITION BY recorstamp
	CLUSTER BY fkdat	
VBRP(item)
	PARTITION BY recorstamp
	CLUSTER BY vbeln	
	
ztbsf003
	PARTITION BY recorstamp
	CLUSTER BY vbeln

ztbsf004	
	PARTITION BY recorstamp
	CLUSTER BY vbeln
	
ztbsd058	
	PARTITION BY recorstamp
	CLUSTER BY vbeln
	



1) rename table to old	
2) create table new partition cluster

	
	
	
CREATE TABLE seu_projeto.seu_dataset.sua_tabela_exemplo (
    id STRING OPTIONS(description='Identificador único do registro'),
    timestamp_evento TIMESTAMP OPTIONS(description='Timestamp do evento, usado para particionamento'),
    valor NUMERIC OPTIONS(description='Algum valor numérico associado ao evento'),
    data_processamento DATE OPTIONS(description='Data de processamento, usada para clusterização'),
    descricao STRING OPTIONS(description='Descrição detalhada do evento')
)
PARTITION BY
    TIMESTAMP_TRUNC(timestamp_evento, DAY)
CLUSTER BY
    data_processamento
OPTIONS (
    description = 'Esta é uma tabela de exemplo particionada por timestamp_evento e clusterizada por data_processamento.'
);	