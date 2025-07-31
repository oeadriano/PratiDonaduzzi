-- dados-dev.sap_view.VB_TR_PEDIDOS_CLIENTE_OV
with w_cidade as (
  select distinct codigo, cli_cid as cidade 
  from `dados-dev.sap.VH_TR_CADASTRO_CLIENTES`

), w_representante as (
  select 
    distinct VND_COD_SAP as representante, LIFNR_SUP_IMEDIATO as supervisor 
    from `dados-dev.sap.VH_MD_REPRESENTANTES`

), w_dash as (
  SELECT 
    DOC_VENDA as PEDIDO_SAP, DT_OV_D as DATA, COND_PAG, CLIENTE, 
    case
      when COCKPIT = 'Faturamento' then 'Faturado'
      when COCKPIT in ('Bloqueio Comercial', 'Bloqueio de Estoque', 'Bloqueio Financeiro') then 'Bloqueado' 
      when COCKPIT in ('Ordem Sem Remessa') then 'Liberado'
      when COCKPIT in ('Ordem Com Remessa') then 'Separação'
      when COCKPIT in ('Cancelado', 'Itens Cancelados', 'Recusa Financeiro') then 'Cancelado'        
      else COCKPIT
		end AS STATUS, 
    SUM(VLR_PEDIDO)+SUM(VLR_ICMSRET) AS VALOR, 
    CNPJCLIENTE AS CNPJ, 
    RAZAO_SOCIAL,	VENDEDOR, PEDIDO_PORTAL, 
    --DATAHORA_TIMESTAMP, 
    --unix_millis(      cast(substring(DT_OV,0,4)||"-"|| substring(DT_OV,5,2)||"-"|| substring(DT_OV,7,2)|| ' ' || substring(DOC_VHORA,0,2)||":"|| substring(DOC_VHORA,3,2)||":"|| substring(DOC_VHORA,5,2) as timestamp)    ) as DATAHORA_TIMESTAMP,           
    UNIX_MILLIS(timestamp(etl_venda)) as DATAHORA_TIMESTAMP,     
    case
      when CANAL_DISTR = '04' then 'Hospitalar'
      else ERNAM
    end as ERNAM, CENTRO,
    case		
      when COCKPIT = 'Faturamento' then 'Faturado'
      when COCKPIT = 'Bloqueio Comercial'  then 'Bloq Coml'
      when COCKPIT = 'Bloqueio de Estoque' then 'Bloq Estq'
      when COCKPIT = 'Bloqueio Financeiro' then 'Bloq Fin'
      when COCKPIT in ('Ordem Sem Remessa') then 'S/Remessa'
      when COCKPIT in ('Ordem Com Remessa') then 'C/Remessa'
      when COCKPIT in ('Cancelado', 'Itens Cancelados', 'Recusa Financeiro') then 'Cancelado'
      else COCKPIT
  end AS STATUS_FINAL
  from `dados-dev.sap.VH_TR_DASH_MV_VISAO_OV` D
  where
    DT_OV_D >= date_trunc(date_sub(current_date, interval 3 month), month)
    and ERNAM <> 'RFC_DIGIBEE'
    and COALESCE(AUGRU,'') <> 'ZBF' 
    AND DOC_TIPO in ('ZNOR', 'ZGOV', 'YTRI', 'ZV12')
    AND COCKPIT <> 'Itens Cancelados' -- AEO Pedidos com itens alguns cancelados estavam gerando duplicidade de pedidos

	GROUP BY
		DOC_VENDA, DT_OV_D, COND_PAG, CLIENTE, RAZAO_SOCIAL, COCKPIT, RAZAO_SOCIAL,
		VENDEDOR, PEDIDO_PORTAL, ETL_VENDA, CNPJCLIENTE, ERNAM, centro
),
w_TVZBT as (
    select ZTERM, vtext
    from `dados-dev.sap.VH_MD_TVZBT`
    where ZTERM between '1000' and '1999'
),
w_cancelado as (
  select 
    * 
  from 
    dados-dev.sap.VH_TR_PEDIDOS_CLIENTE_CANCELADO C 
  where 
    DATA_D >= date_trunc(date_sub(current_date, interval 4 month), month)
)
-- todos os pedidos que já estão nas dash_visao
select
    D.PEDIDO_SAP, D.DATA, D.COND_PAG, D.CLIENTE
    ,
    CASE 
      WHEN COALESCE(C.PEDIDO_SAP, '') = '' 
      THEN D.STATUS 
      ELSE C.MOTIVO 
    END AS STATUS,
    D.VALOR, D.CNPJ
    , D.RAZAO_SOCIAL, 
    T.vtext || ' dias' AS forma_pagamento, D.VENDEDOR,     
    D.PEDIDO_PORTAL,
    D.STATUS_FINAL, 
    cast(D.DATAHORA_TIMESTAMP as INT64) as TIMESTAMP_PEDIDO-- D.DATAHORA_TIMESTAMP as TIMESTAMP_PEDIDO
    ,D.ERNAM, D.CENTRO,
    w_c.cidade as CIDADE, w_rep.supervisor as SUPERVISOR    
from 
    w_dash AS D
left join
		w_TVZBT T        
		on T.ZTERM = D.COND_PAG    
LEFT JOIN 
    w_cancelado C
    on C.PEDIDO_SAP = D.PEDIDO_SAP
join
  w_cidade as w_c
  on w_c.codigo = D.CLIENTE
join 
  w_representante as w_rep
  on w_rep.representante = D.VENDEDOR    