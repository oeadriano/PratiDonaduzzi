-- bloqueio de credito
INSERT INTO raw_cimed_tech.CLIENTES_BLQOUEIO_T (SELECT * FROM dados-dev.visoes_auxiliares_cimed_tech.CV_VIEW_CLIENTES_BLQOUEIO);
DELETE FROM raw_cimed_tech.CLIENTES_BLQOUEIO_T WHERE last_update < (SELECT MAX(last_update) from raw_cimed_tech.CLIENTES_BLQOUEIO_T);

--cadastro de clientes
INSERT INTO raw_cimed_tech.CADASTRO_CLIENTE_T (SELECT * FROM dados-dev.visoes_auxiliares_cimed_tech.CV_VIEW_CADASTRO_CLIENTE);
DELETE FROM raw_cimed_tech.CADASTRO_CLIENTE_T WHERE last_update < (SELECT MAX(last_update) from raw_cimed_tech.CADASTRO_CLIENTE_T);

-- rep_clientes
INSERT INTO raw_cimed_tech.REP_CLIENTES_IP_T (SELECT * FROM dados-dev.visoes_cimed_tech.CV_VIEW_REP_CLIENTES_IP);
DELETE FROM raw_cimed_tech.REP_CLIENTES_IP_T WHERE last_update < (SELECT MAX(last_update) from raw_cimed_tech.REP_CLIENTES_IP_T)


SELECT count(*) FROM `dados-dev.visoes_auxiliares_cimed_tech.CV_VIEW_PARTIDAS_ABERTO_GERAL`  

CREATE TABLE dados-dev.raw_cimed_tech.CV_VIEW_PARTIDAS_ABERTO_GERAL_T as (SELECT * FROM dados-dev.visoes_auxiliares_cimed_tech.CV_VIEW_PARTIDAS_ABERTO_GERAL )

SELECT count(*) FROM `dados-dev.raw_cimed_tech.CV_VIEW_PARTIDAS_ABERTO_GERAL_T`

