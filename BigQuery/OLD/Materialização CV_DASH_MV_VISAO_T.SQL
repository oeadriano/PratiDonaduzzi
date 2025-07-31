REGRA no DATA FUSION: 
  INSERT INTO raw_cimed_tech.CV_DASH_MV_VISAO_T    
  (SELECT * FROM dados-prod.visoes_auxiliares_cimed_tech.CV_DASH_MV_VISAO);    
  
  DELETE FROM raw_cimed_tech.CV_DASH_MV_VISAO_T    
  WHERE last_update < (SELECT MAX(last_update) from dados-prod.raw_cimed_tech.CV_DASH_MV_VISAO_T)


- dados-dev:visoes_auxiliares_cimed_tech.CV_DASH_MV_VISAO
	- atualziar em PRD
	- Materializar a view em CV_DASH_MV_VISAO_T em DEV e PRD: 
	- atenção para o dataset pois temos duas materializações em dois dataset´s diferentes em PRD. 
		Fica a criterio de vcs qual deve ser o dataset correto para a tabela CV_DASH_MV_VISAO_T ok?
		Aten~ção para a estrutura da tabela materializada, as duas tem difrenças entre os dois datasets. 
		O correto é ser a mesma estrutura da view: visoes_auxiliares_cimed_tech.CV_DASH_MV_VISAO
		Importante apagar a tabela CV_DASH_MV_VISAO_T do dataset q nao vai ser usado
	- criar a orquestração para a materialzação EM DEV e PRD. 
		Ela deve ocorrer após o termino da materialzação de visoes_YDBI_0006.YDBI006_ITEM_T.
- CV_VIEW_PEDIDOS_CLIENTE_CANCELADO_T	
	- sem alteraç~eos  na view em DEV e PRD
	- somente criar a osquestração em DEV e PRD.
	- deve ocorrer apos a materailização de visoes_YDBI_0006.YDBI006_ITEM_T.
	
- dados-dev:visoes_cimed_tech.CV_VIEW_PEDIDOS_CLIENTE_CT	
	- atualizar view em PRD
	- importante me avisar qdo for atualizar em PRD, pois terei que subir nova versao de api, para assim, evitar impacto no front

- dados-dev:visoes_cimed_tech.CV_VIEW_PEDIDOS_CLIENTE_CT_TESTE
	- apagar em DEV e PRD
		

	
	
"query": {{ CONCAT( "SELECT * FROM visoes_cimed_tech.CV_VIEW_PEDIDOS_CLIENTE_CT WHERE cliente = '", message.queryAndPath.cliente, "' AND DATA >= '", message.queryAndPath.data_de, "' AND DATA <= '", message.queryAndPath.data_ate, "'  ORDER BY DATA")}},	

"query": {{ CONCAT( "SELECT * FROM visoes_cimed_tech.CV_VIEW_PEDIDOS_CLIENTE_CT WHERE VENDEDOR = '", message.queryAndPath.lifnr, "' AND DATA >= '", message.queryAndPath.data_de, "' AND DATA <= '", message.queryAndPath.data_ate, "' ORDER BY DATA, RAZAO_SOCIAL")}},


SELECT
  VENDEDOR,
  MANDANTE,
  DOC_FATUR,
  DOC_VENDA,
  EMPRESA,
  CENTRO,
  DEPOSITO,
  MATNR,
  SUM(COD_MATERIAL) AS COD_MATERIAL,
  DESCR_MATERIAL,
  CLIENTE,
  DOC_NOTAFISCAL,
  DT_FATUR,
  DT_OV,
  DT_OV_D,
  DOC_TIPO,
  ORG_VENDA,
  CANAL_DISTR,
  EQ_VENDAS,
  ESCR_VENDA,
  SET_ATIV,
  COND_PAG,
  LOC_EXP,
  COCKPIT,
  SUM(VLR_PRZ_MEDIO) AS VLR_PRZ_MEDIO,
  SUM(QTDECALCULADA) AS QTDECALCULADA,
  SUM(VLR_MONTIMPOSTO) AS VLR_MONTIMPOSTO,
  SUM(VLR_LIQUIDO) AS VLR_LIQUIDO,
  SUM(VLR_PEDIDO) AS VLR_PEDIDO,
  SUM(VLR_BOLETO) AS VLR_BOLETO,
  SUM(VALOR_NF) AS VALOR_NF,
  SUM(DEVOLUCAO_NF) AS DEVOLUCAO_NF,
  SUM(CUSTO_UNIT) AS CUSTO_UNIT,
  SUM(VLR_DESC_NF) AS VLR_DESC_NF,
  SUM(VLR_ICMSRET) AS VLR_ICMSRET,
  SUM(VLR_IPI) AS VLR_IPI,
  SUM(VLR_ST_BON) AS VLR_ST_BON,
  REPLACE(SUBSTR(CAST(CURRENT_DATE AS STRING),0,7),'-','') AS ANOMES_ATUAL,
  concat(COD_MATERIAL, cliente) as CHAVE_MIX, 
  nome_cliente as RAZAO_SOCIAL,
  cnpj_cliente as CNPJCLIENTE, 
  BSTNK as PEDIDO_PORTAL,   
  -- ajuste tecnico estruturado(gambiarra)
  -- qdo vier da YDBI retirar isso
  CASE 
    WHEN BSTNK like 'CT-%' then 'RFC_DIGIBEE'
    WHEN BSTNK like 'VISAO-%' OR BSTNK like 'B2B-%' then 'RFC_VISAO'    
    ELSE ERNAM
  end as ERNAM, 
  unix_millis(
    cast(substring(DT_OV,0,4)||"-"|| substring(DT_OV,5,2)||"-"|| substring(DT_OV,5,2)|| ' ' || substring(DOC_VHORA,0,2)||":"|| substring(DOC_VHORA,3,2)||":"|| substring(DOC_VHORA,5,2) as timestamp)
  ) as DATAHORA_TIMESTAMP, 
  current_timestamp() as ETL_TIMESTAMP
FROM
  `dados-dev.visoes_YDBI_0006.YDBI006_ITEM_T` Y
WHERE 
  Y.AUGRU <> 'ZBF'
GROUP BY 
  VENDEDOR,
  MANDANTE,
  DOC_FATUR,
  DOC_VENDA,
  EMPRESA,
  CENTRO,
  DEPOSITO,
  MATNR,
  DESCR_MATERIAL,
  CLIENTE,
  DOC_NOTAFISCAL,
  DT_FATUR,
  DT_OV,
  DT_OV_D,
  DOC_TIPO,
  ORG_VENDA,
  CANAL_DISTR,
  EQ_VENDAS,
  ESCR_VENDA,
  SET_ATIV,
  COND_PAG,
  LOC_EXP,
  COCKPIT,
  CHAVE_MIX,
  NOME_CLIENTE, BSTNK, DOC_VHORA, cnpj_cliente, ERNAM
