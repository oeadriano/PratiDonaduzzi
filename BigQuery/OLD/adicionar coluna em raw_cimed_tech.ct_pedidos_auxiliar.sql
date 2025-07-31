CREATE TABLE `dados-dev.raw_cimed_tech.ct_pedidos_auxiliar_2`
(
  cabecalho 
  STRUCT<
	cnpjvendedor STRING, condpg STRING, pedido STRING, valid_est STRING, cnpjcliente STRING, canal STRING, pedcliente STRING, observacao STRING, orgvendas STRING, datapedido DATE, docvendas STRING, cod_gama STRING, i_werks STRING, i_bukrs STRING, sapIdClient STRING, representante STRING, razao_social STRING, campanhaId STRING, bloqueio STRING, cnpj_fornecedor STRING, pedido_referencia STRING, nome_arquivo 
	STRING>,
  itens ARRAY<STRUCT<
	lgort STRING, promocao STRING, tabela STRING, i_werks STRING, pedido STRING, precounitario FLOAT64, item STRING, produto STRING, quantidade INT64, categoria_comissao STRING, ean STRING, motivo_recusa STRING, quantidade_atendida INT64, desconto FLOAT64, preco_final FLOAT64, bonificado STRING, validade_curta STRING, zpre FLOAT64, zpmi FLOAT64, zrps FLOAT64, perc_comis FLOAT64, ident_comis STRING>
	>,
  e_salesdocument STRING,
  etl_timestamp STRING,
  integrador STRING,
  supervisor STRING,
  plataforma STRING,
  versao STRING,
  van STRING,
  prefixo STRING
)
AS (
  SELECT
    ANY_VALUE(cabecalho)as cabecalho,
    ARRAY_AGG(STRUCT(lgort, promocao, tabela, i_werks, pedido, precounitario, item, produto, quantidade, categoria_comissao,
      ean, motivo_recusa, quantidade_atendida, desconto, preco_final, bonificado, validade_curta, zpre, zpmi, zrps, 0.0 as perc_comis, '' as ident_comis)) AS itens,
    e_salesdocument,
    etl_timestamp,
    integrador,
    supervisor,
    plataforma,
    versao,
    van,
    prefixo
  FROM
    `raw_cimed_tech.ct_pedidos_auxiliar`
  CROSS JOIN
    UNNEST(itens) i
  --where cabecalho.pedido IN ('CT-1681144357690','CT-1662647501003')
  GROUP BY
    e_salesdocument,
    etl_timestamp,
    integrador,
    supervisor,
    plataforma,
    versao,
    van,
    prefixo
);