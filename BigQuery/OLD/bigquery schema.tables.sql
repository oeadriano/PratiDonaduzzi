https://storage.googleapis.com/storage/v1/b/gc-conteudo-prod/o?delimiter=%2F*&prefix=001%2F001%2F010%2F001%2F100183
 

SELECT table_name, partition_id, total_rows, *
FROM `Apoio.INFORMATION_SCHEMA.PARTITIONS`
WHERE table_name = 'FAT_F_TESTE'

SELECT table_name, partition_id, total_rows, *
FROM `sap.INFORMATION_SCHEMA.PARTITIONS`
WHERE table_name = 'VH_TR_DASH_MV_VISAO_FAT_F'


CREATE TABLE
  Apoio.teste_fat (    
    DOC_VENDA STRING,
    DT_FATUR_D DATE,
    EMPRESA STRING, 
    CENTRO STRING, 
    MATNR STRING
    )
PARTITION BY
  DATE_TRUNC(DT_FATUR_D, MONTH)
  
  --OPTIONS (    partition_expiration_days = 3,    require_partition_filter = TRUE);


INSERT INTO Apoio.teste_fat
SELECT
  DOC_VENDA, DT_FATUR_D, EMPRESA, CENTRO, MATNR
FROM 
  `dados-dev.sap.VH_TR_DASH_MV_VISAO_FAT_F`
WHERE
  DT_FATUR_D >= '2024-01-01'  



SELECT * 
FROM Apoio.teste_fat  
where DT_FATUR_D >= '2024-01-01'  



SELECT * FROM `dados-dev.sap.VH_TR_DASH_MV_VISAO_FAT_F` WHERE DT_FATUR_D >= "2021-08-22"






ALTER TABLE Apoio.teste_fat 
  SET OPTIONS (
    require_partition_filter = true);



VH_TR_DASH_MV_VISAO_FAT_F    

SELECT
 table_name, ddl
FROM
 `dados-dev`.sap.INFORMATION_SCHEMA.TABLES
WHERE
 table_name="VH_TR_DASH_MV_VISAO_FAT_F"


select _PARTITINDATE as pt, 
from `dados-dev.Apoio.FAT_F_TESTE`
where partition_id = "20221231"

select * from  `dados-dev.sap.VH_TR_DASH_MV_VISAO_FAT_F`
where dt_fatur_d > '2024-08-01'

DELETE FROM `dados-dev.Apoio.FAT_F_TESTE`
where dt_fatur_d > '2024-08-01'

INSERT INTO `dados-dev.Apoio.FAT_F_TESTE`
select * from `dados-dev.sap.VH_TR_DASH_MV_VISAO_FAT_F`
where dt_fatur_d > '2024-05-01'

INSERT INTO `dados-dev.Apoio.FAT_F_TESTE_TRUNC`
select * from `dados-dev.sap.VH_TR_DASH_MV_VISAO_FAT_F`
where dt_fatur_d > '2024-05-01'

select * from `dados-dev.Apoio.FAT_F_TESTE_TRUNC` where dt_fatur_d >= date_sub(current_date, interval 7 day)
--01/07
Bytes processed 399.45 KB
Bytes billed 10 MB
Slot milliseconds 306
--01/05
Bytes processed 10.1 MB
Bytes billed 11 MB
Slot milliseconds 830
--7 dias
Bytes processed 67.14 KB
Bytes billed 10 MB
Slot milliseconds 27

select * from `dados-dev.Apoio.FAT_F_TESTE` where dt_fatur_d >= date_sub(current_date, interval 7 day)
--01/07
Bytes processed 331.01 KB
Bytes billed 10 MB
Slot milliseconds 4232
--01/05
Bytes processed 10.1 MB
Bytes billed 11 MB
Slot milliseconds 6162
-- 7 dias
Bytes processed 10.24 KB
Bytes billed 10 MB
Slot milliseconds 178

select * from `dados-dev.sap.VH_TR_DASH_MV_VISAO_FAT_F` where dt_fatur_d >= date_sub(current_date, interval 7 day)
--01/07
Bytes processed 331.01 KB
Bytes billed 10 MB
Slot milliseconds 1447
--01/05
Bytes processed 10.1 MB
Bytes billed 11 MB
Slot milliseconds 3799
-- 7 dias
Bytes processed 10.24 KB
Bytes billed 10 MB
Slot milliseconds 145