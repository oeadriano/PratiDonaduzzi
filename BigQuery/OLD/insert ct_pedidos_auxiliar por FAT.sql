/*
select 
  distinct pedido_portal, dt_ov_d
from
  `dados-dev.sap.VH_TR_DASH_MV_VISAO_FAT_F`
where
  dt_fatur_d >= '2024-11-01' and
  pedido_portal like 'CT%'
  and pedido_portal not in 
    (
        select distinct cabecalho.pedido--, integrador
        from `dados-dev.raw_cimed_tech.ct_pedidos_auxiliar` 
        where cabecalho.datapedido >= '2024-11-01' and cabecalho.pedido like 'CT%'
        ) 
  order by
    pedido_portal

*/
--FRCLEITON 22.10.2024
--Query para inserir um registro na tabela aninhada pedidos_auxiliar com dados da visao_fat

insert into raw_cimed_tech.ct_pedidos_auxiliar(cabecalho, itens, e_salesdocument, etl_timestamp,
   integrador, van, prefixo, data_hora_insert)
   --integrador, plataforma, prefixo, data_hora_insert)

with w_pedidos as (
select 
  distinct pedido_portal, dt_ov_d
from
  `dados-dev.sap.VH_TR_DASH_MV_VISAO_FAT_F`
where
  dt_fatur_d >= '2024-11-01' and
  pedido_portal like 'CT%'
  and pedido_portal not in 
    (
        select distinct cabecalho.pedido--, integrador
        from `dados-dev.raw_cimed_tech.ct_pedidos_auxiliar` 
        where cabecalho.datapedido >= '2024-11-01' and prefixo = 'CT'
        ) 
  order by
    pedido_portal
  --limit 1
)   
select
    STRUCT(
      vend.VND_CPF as cnpjvendedor, cond_pag as condpg, pedido_portal as pedido, '' as valid_est, cnpjcliente,
      CANAL_DISTR as canal, pedido_referencia as pedcliente, '' as observacao, org_venda as orgvendas,
      fat.DT_OV_D as datapedido, doc_venda as docvendas, '' as cod_gama, centro as i_werks, empresa as i_bukrs, cliente as sapIdClient,
      VND_COD_SAP as representante, razao_social, '' as campanhaId, '' as bloqueio, '' as cnpj_fornecedor, '' as pedido_referencia,
    '' as nome_arquivo
    ) as cabecalho,
    ARRAY_AGG(
      STRUCT( fat.DEPOSITO as lgort, '' as promocao, '' as tabela, fat.CENTRO as i_werks,
      '' as pedido,
      safe_divide(fat.VALOR_NF, fat.QTDECALCULADA) as precounitario,
      ltrim(doc_item, '0') as item,
      fat.matnr as produto,
      cast(fat.QTDECALCULADA as INT64) as quantidade,
      '' as categoria_comissao, '' as ean, '' as motivo_recusa, 0 as quantidade_atendida, 0.0 as desconto,
      0.0 as preco_final, '' as bonificado, '' as validade_curta, 0.0 as zpre, 0.0 as zpmi, 0.0 as zrps, 0.0 as perc_comis,
      '' as ident_comis, '' as combo, 0.0 as zrpf)
    ) AS itens,
    fat.DOC_VENDA as e_salesdocument,
    right(fat.PEDIDO_PORTAL, 13) as etl_timestamp,
    'Salesforce' as integrador,
    --null as supervisor,
    'CGCLOUD' as plataforma,
    --null as versao,
    --null as van,
    'CG' as prefixo,
    timestamp_millis(cast(replace(pedido_portal, 'CG-', '') as INT64)) as data_hora_insert
    from sap.VH_TR_DASH_MV_VISAO_FAT_F fat
    join sap.VH_MD_REPRESENTANTES vend
      on fat.VENDEDOR = vend.VND_COD_SAP
    where
      dt_fatur_d >= '2024-10-01' and pedido_portal in (select pedido_portal from w_pedidos)
    group by
      vend.VND_CPF, cond_pag, pedido_portal, cnpjcliente,
    CANAL_DISTR, pedido_referencia, org_venda, dt_ov_d, doc_venda, centro,
    empresa, cliente, VND_COD_SAP, razao_social