-- dados-dev.sap_view.VB_TR_PEDIDOS_CLIENTE
with w_cidade as (
  select distinct codigo, cli_cid as cidade 
  from `dados-dev.sap.VH_TR_CADASTRO_CLIENTES`

), w_representante as (
  select 
    distinct VND_COD_SAP as representante, LIFNR_SUP_IMEDIATO as supervisor 
    from `dados-dev.sap.VH_MD_REPRESENTANTES`

), w_pgsl_status as (
    SELECT
        pedido_sap,         
        pedido_portal, 
        case
            when status in ('Bloqueio Comercial', 'Bloqueio de Estoque', 'Bloqueio Financeiro') then 'Bloqueado' 
            when status in ('Ordem Sem Remessa') then 'Liberado'
            when status in ('Ordem Com Remessa') then 'Separação'
            when status in ('Cancelado', 'Itens Cancelados', 'Recusa Financeira') then 'Cancelado'        
            else status
        end AS status, 
        case        
            when status = 'Faturamento' then 'Faturado'
            when status = 'Bloqueio Comercial'  then 'Bloq Coml'
            when status = 'Bloqueio de Estoque' then 'Bloq Estq'
            when status = 'Bloqueio Financeiro' then 'Bloq Fin'

            when status in ('Ordem Sem Remessa') then 'S/Remessa'
            when status in ('Ordem Com Remessa') then 'C/Remessa'
            when status in ('Cancelado', 'Itens Cancelados', 'Recusa Financeira') then 'Cancelado'        
            else status
        end status_final, 
        motivo
    FROM
        --DEV
        EXTERNAL_QUERY("projects/dados-dev/locations/us/connections/cimed-postgres-us", "SELECT * from ct.status_pedido")
        --PROD
        --EXTERNAL_QUERY("projects/dados-prod/locations/southamerica-east1/connections/cimed-postgres", "SELECT * from ct.status_pedido") 
),
w_dash as (
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
    DT_OV_D >= date(extract(year from date_sub(current_date, interval 11 month))||'-'||FORMAT('%02d', extract(month from date_sub(current_date, interval 11 month)))||'-01')    
    and COALESCE(AUGRU,'') <> 'ZBF' 
    AND DOC_TIPO in ('ZNOR', 'ZGOV', 'YTRI', 'ZV12')
    AND COCKPIT <> 'Itens Cancelados' -- AEO Pedidos com itens alguns cancelados estavam gerando duplicidade de pedidos    
	GROUP BY
		DOC_VENDA, DT_OV_D, COND_PAG, CLIENTE, RAZAO_SOCIAL, COCKPIT, RAZAO_SOCIAL,
		VENDEDOR, PEDIDO_PORTAL, ETL_VENDA, CNPJCLIENTE, ERNAM, centro
  UNION ALL
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
    round(SUM(VALOR_NF),2) AS VALOR, CNPJCLIENTE AS CNPJ, 
    RAZAO_SOCIAL,	VENDEDOR, PEDIDO_PORTAL, 
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
  from 
     `dados-dev.sap.VH_TR_DASH_MV_VISAO_FAT` 
  where
    DT_OV_D >= date(extract(year from date_sub(current_date, interval 11 month))||'-'||FORMAT('%02d', extract(month from date_sub(current_date, interval 11 month)))||'-01')
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
  w_ped_aux as (
    SELECT 
        E_SALESDOCUMENT as PEDIDO_SAP, cabecalho.datapedido AS DATA, cabecalho.condpg as COND_PAG, 
        cabecalho.cnpjcliente as cnpj, 
		case 
			when coalesce(pg.pedido_sap, '') = '' then 'Integrado' 
			else pg.status
		end as status, 
		cabecalho.cnpjvendedor, cabecalho.pedido as pedido_portal, 
        round(sum(itens.precounitario*itens.quantidade),2) as valor,
        T.vtext || ' dias' forma_pagamento, cabecalho.representante, cabecalho.sapIdClient as cliente,
        cast(REPLACE(cabecalho.pedido, 'CT-', '') as INT64) as timestamp_pedido, cabecalho.razao_social, 
        integrador as ERNAM, cabecalho.i_werks as centro
    FROM 
        dados-dev.raw_cimed_tech.ct_pedidos_auxiliar, UNNEST(itens) as itens
    left join
        w_TVZBT AS T
        on T.ZTERM = cabecalho.condpg
	LEFT JOIN 
		w_pgsl_status as pg
	on pg.pedido_sap = E_SALESDOCUMENT		
    group by 
        E_SALESDOCUMENT,
        cabecalho.datapedido, cabecalho.condpg, cabecalho.cnpjcliente, cabecalho.cnpjvendedor, cabecalho.pedido, T.zterm, T.vtext, 
        cabecalho.representante, cabecalho.sapIdClient, cabecalho.razao_social, integrador, cabecalho.i_werks, pg.pedido_sap, pg.status
),
w_cancelado as (
  select 
    * 
  from 
    dados-dev.sap.VH_TR_PEDIDOS_CLIENTE_CANCELADO C 
  where 
    DATA_D >= date(extract(year from date_sub(current_date, interval 11 month))||'-'||FORMAT('%02d', extract(month from date_sub(current_date, interval 11 month)))||'-01')  
)
-- todos os pedidos que já estão nas dash_visao
select
    D.PEDIDO_SAP, D.DATA, D.COND_PAG, D.CLIENTE,
    CASE 
      WHEN COALESCE(C.PEDIDO_SAP, '') = '' 
      THEN D.STATUS 
      ELSE C.MOTIVO 
    END AS STATUS,
    D.VALOR, D.CNPJ
    , D.RAZAO_SOCIAL, 
    T.vtext || ' dias' AS forma_pagamento, D.VENDEDOR,     
    case
      when coalesce(aux.PEDIDO_PORTAL, '') <> '' then aux.PEDIDO_PORTAL
      else D.PEDIDO_PORTAL
    end as PEDIDO_PORTAL,
    D.STATUS_FINAL, 
    cast(D.DATAHORA_TIMESTAMP as INT64) as TIMESTAMP_PEDIDO-- D.DATAHORA_TIMESTAMP as TIMESTAMP_PEDIDO
    ,D.ERNAM, D.CENTRO, 
    w_c.cidade as CIDADE, w_rep.supervisor as SUPERVISOR
from 
    w_dash AS D
left join 
    w_ped_aux as aux
    on aux.pedido_sap = D.PEDIDO_SAP
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
union all
select 
    aux.PEDIDO_SAP, cast(aux.DATA as date) as DATA, aux.COND_PAG, aux.CLIENTE
    ,'Integrado' as STATUS, 
    aux.VALOR, aux.CNPJ ,
    aux.razao_social, aux.forma_pagamento, aux.representante as VENDEDOR, coalesce(aux.PEDIDO_PORTAL, '') as PEDIDO_PORTAL,
    aux.status as STATUS_FINAL,aux.timestamp_pedido, aux.ernam, aux.centro, 
    w_c.cidade as CIDADE, w_rep.supervisor as SUPERVISOR
from 
    w_ped_aux as aux
join
  w_cidade as w_c
  on w_c.codigo = aux.cliente
join 
  w_representante as w_rep
  on w_rep.representante = aux.representante
where 
    aux.pedido_sap not in (select distinct pedido_sap from w_dash)