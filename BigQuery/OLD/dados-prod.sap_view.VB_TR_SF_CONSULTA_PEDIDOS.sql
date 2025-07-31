-- CV_SF_CONSULTA_PEDIDOS 
WITH w_dash_ov_fat as 
(
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
      when CANAL_DISTR = '04' then 'HOSPITALAR'
      else ERNAM
    end as ERNAM, CENTRO,
    ETL_VENDA, ETL_REMESSA, ETL_FATURAMENTO,
    case		
      when COCKPIT = 'Faturamento' then 'Faturado'
      when COCKPIT = 'Bloqueio Comercial'  then 'Bloqueio Comercial'
      when COCKPIT = 'Bloqueio de Estoque' then 'Bloqueio de Estoque'
      when COCKPIT = 'Bloqueio Financeiro' then 'Bloqueio Financeiro'
      when COCKPIT in ('Ordem Sem Remessa') then 'Ordem Sem Remessa'
      when COCKPIT in ('Ordem Com Remessa') then 'Ordem Com Remessa'
      when COCKPIT in ('Cancelado', 'Itens Cancelados', 'Recusa Financeiro') then 'Cancelado'
      else COCKPIT
    end AS STATUS_FINAL, ORG_VENDA, CANAL_DISTR
    from `dados-prod.sap.VH_TR_DASH_MV_VISAO_OV`
    where
    DT_OV_D >= date(extract(year from date_sub(current_date, interval 11 month))||'-'||FORMAT('%02d', extract(month from date_sub(current_date, interval 11 month)))||'-01')    
    AND DOC_TIPO in ('ZNOR', 'ZGOV', 'YTRI', 'ZV12')     
    GROUP BY
		DOC_VENDA, DT_OV_D, COND_PAG, CLIENTE, RAZAO_SOCIAL, COCKPIT, RAZAO_SOCIAL,
		VENDEDOR, PEDIDO_PORTAL, ETL_VENDA, ETL_REMESSA, ETL_FATURAMENTO, CNPJCLIENTE, ERNAM, CENTRO, ORG_VENDA, CANAL_DISTR
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
    round(SUM(VALOR_NF),2) AS VALOR, 
    CNPJCLIENTE AS CNPJ, 
    RAZAO_SOCIAL,	VENDEDOR, PEDIDO_PORTAL, 
    UNIX_MILLIS(timestamp(etl_venda)) as DATAHORA_TIMESTAMP, 
    case
      when CANAL_DISTR = '04' then 'HOSPITALAR'
      else ERNAM
    end as ERNAM, CENTRO,
    ETL_VENDA, ETL_REMESSA, 
    -- max de etl_faturaento necessario pois no caso de Alagoas, pode haver o desmembramento de NF´s para a mesma OV
    -- gerando duplicidade de registro no insert do SF
    max(ETL_FATURAMENTO) as ETL_FATURAMENTO,
    case		
      when COCKPIT = 'Faturamento' then 'Faturado'
      when COCKPIT = 'Bloqueio Comercial'  then 'Bloqueio Comercial'
      when COCKPIT = 'Bloqueio de Estoque' then 'Bloqueio de Estoque'
      when COCKPIT = 'Bloqueio Financeiro' then 'Bloqueio Financeiro'
      when COCKPIT in ('Ordem Sem Remessa') then 'Ordem Sem Remessa'
      when COCKPIT in ('Ordem Com Remessa') then 'Ordem Com Remessa'
      when COCKPIT in ('Cancelado', 'Itens Cancelados', 'Recusa Financeiro') then 'Cancelado'
      else COCKPIT
  end AS STATUS_FINAL, ORG_VENDA, CANAL_DISTR
  from 
     `dados-prod.sap.VH_TR_DASH_MV_VISAO_FAT` 
  where
    DT_OV_D >= date(extract(year from date_sub(current_date, interval 11 month))||'-'||FORMAT('%02d', extract(month from date_sub(current_date, interval 11 month)))||'-01')
    AND DOC_TIPO in ('ZNOR', 'ZGOV', 'YTRI', 'ZV12') 
    GROUP BY
		DOC_VENDA, DT_OV_D, COND_PAG, CLIENTE, RAZAO_SOCIAL, COCKPIT, RAZAO_SOCIAL,
		VENDEDOR, PEDIDO_PORTAL, ETL_VENDA, ETL_REMESSA, CNPJCLIENTE, ERNAM, CENTRO, ORG_VENDA, CANAL_DISTR
), 
w_pgsl_status as (
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
            when status in ('Cancelado', 'Itens Cancelados', 'Recusa Financeira') then 'Cancelado'                    
            else status
        end status_final, 
        motivo
    FROM
        --DEV
        --EXTERNAL_QUERY("projects/dados-prod/locations/us/connections/cimed-postgres-us", "SELECT * from ct.status_pedido")
        --PROD
        EXTERNAL_QUERY("projects/dados-prod/locations/southamerica-east1/connections/cimed-postgres", "SELECT * from ct.status_pedido") 
),
w_TVZBT as (
    select 
        ZTERM, vtext, 
        cast(length(vtext)-length(replace(vtext, '/', ''))+1 as string) as parcelas
    from `dados-prod.sap.VH_MD_TVZBT`
    where ZTERM between '1000' and '1999'
),
w_ped_aux as (
    SELECT 
        E_SALESDOCUMENT as PEDIDO_SAP, STRING(cabecalho.datapedido) AS DATA, cabecalho.condpg as COND_PAG, 
        cabecalho.cnpjcliente as cnpj, 'Integrado' as status, cabecalho.cnpjvendedor, cabecalho.pedido as pedido_portal, 
        round(sum(itens.precounitario*itens.quantidade),2) as valor,
        T.vtext || ' dias' forma_pagamento, cabecalho.representante, cabecalho.sapIdClient as cliente,
        cast(REPLACE(cabecalho.pedido, 'CT-', '') as INT64) as timestamp_pedido, cabecalho.razao_social, 
        cabecalho.orgvendas, cabecalho.canal, integrador as ERNAM,t.parcelas as qde_parcelas, 'Integrado' as status_final,         
        t.parcelas|| '_' || t.zterm || '_' || t.vtext as id_unico, etl_timestamp
    FROM 
        `dados-prod.raw_cimed_tech.ct_pedidos_auxiliar`, UNNEST(itens) as itens
    LEFT JOIN 
        w_TVZBT AS T
        on T.ZTERM = cabecalho.condpg
    group by 
        E_SALESDOCUMENT,
        cabecalho.datapedido, cabecalho.condpg, cabecalho.cnpjcliente, cabecalho.cnpjvendedor, cabecalho.pedido, T.zterm, T.vtext, 
        cabecalho.representante, cabecalho.sapIdClient, cabecalho.razao_social, cabecalho.orgvendas, cabecalho.canal, 
		integrador, t.parcelas, etl_timestamp
),
w_cancelado as (
  select 
    * 
  from 
    dados-prod.sap.VH_TR_PEDIDOS_CLIENTE_CANCELADO C 
  where 
    DATA_D >= date(extract(year from date_sub(current_date, interval 11 month))||'-'||FORMAT('%02d', extract(month from date_sub(current_date, interval 11 month)))||'-01')  
),
w_dash as (
	SELECT 
		D.PEDIDO_SAP, D.DATA, 
		coalesce(D.COND_PAG, '') as COND_PAG, D.CLIENTE,    
		case
            when coalesce(c.pedido_sap, '') <> '' then 'Cancelado' -- pedido cancelado no SAP
            else             
                case
                when D.STATUS = 'Faturamento' then 'Faturado'
                when D.STATUS in ('Bloqueio Comercial', 'Bloqueio de Estoque', 'Bloqueio Financeiro') then 'Bloqueado' 
                when D.STATUS in ('Ordem Sem Remessa') then 'Liberado'
                when D.STATUS in ('Ordem Com Remessa') then 'Separação'
                when D.STATUS in ('Cancelado', 'Itens Cancelados', 'Recusa Financeiro') then 'Cancelado'        
                else D.STATUS
            end
		end AS STATUS, VALOR, D.CNPJ, 
		D.RAZAO_SOCIAL, coalesce(T.vtext || ' dias', '') as forma_pagamento, 
		D.VENDEDOR, D.PEDIDO_PORTAL, 
		case
            when coalesce(c.pedido_sap, '') <> '' then 'Cancelado' -- pedido cancelado no SAP
            else D.STATUS
		end AS STATUS_FINAL, 
        coalesce(c.motivo, '') as  motivo_cancelamento, 
        d.DATAHORA_TIMESTAMP, D.ERNAM, D.ORG_VENDA, D.CANAL_DISTR, t.parcelas as qde_parcelas, 
        D.ETL_VENDA, D.ETL_REMESSA, D.ETL_FATURAMENTO, 
        t.parcelas|| '_' || t.zterm || '_' || t.vtext as id_unico
	FROM 
		w_dash_ov_fat as D
	left join
		w_TVZBT T        
		on T.ZTERM = D.COND_PAG
    LEFT JOIN 
        w_cancelado as C
        on C.pedido_sap = D.PEDIDO_SAP
)
-- select principal, primeiro somente pedido CT-DIGIBEE
select 
    aux.DATA AS Data_OV__c, aux.PEDIDO_PORTAL as Pedido_Portal__c,     
    aux.VALOR as Valor_do_pedido_original__c, 
    0 as valor_faturado, 
		case 
			when coalesce(pg.pedido_sap, '') = '' then 'Integrado' 
			else pg.status
		end as status,   
		case 
			when coalesce(pg.pedido_sap, '') = '' then 'Integrado' 
			else pg.status_final
		end as status_final
    , '' as motivo_cancelamento, 
    aux.PEDIDO_SAP as Codigo_Pedido_SAP__c, '' as Mensagem_Integracao__c,
    aux.COND_PAG as Codigo_Condicao_Pagamento__c,     
    aux.cliente as Codigo_SAP__c, aux.orgvendas as Organizacao_Vendas__c, 
    aux.canal as Canal__c, aux.representante as Codigo_Vendedor_SAP__c, 
    aux.forma_pagamento as desdobramento, 
    replace(aux.forma_pagamento, ' dias', '') as parcelas, 
    aux.ERNAM as Ernam__c, aux.id_unico as Id_unico__c
    -- TIMESTAMP_MILLIS(case when coalesce(d.pedido_sap, '') = '' then aux.timestamp_pedido else D.DATAHORA_TIMESTAMP end) as Data_Hora_Pedido,     
    ,replace(substring(cast(TIMESTAMP_MILLIS(aux.timestamp_pedido) as STRING), 1, 10)||'T'||substring(cast(TIMESTAMP_MILLIS(aux.timestamp_pedido) as STRING), 12, 10)||'Z','+0', '') as Data_Hora_Pedido,    
    --2021-12-10 10:43:39+00 / 2022-01-27T17:23:11Z    
    substring(cast(TIMESTAMP_MILLIS(aux.timestamp_pedido) as STRING), 1, 10)||'T'||substring(cast(TIMESTAMP_MILLIS(aux.timestamp_pedido) as STRING), 12, 10)||'Z' as ETL_VENDA, 
    '' as ETL_REMESSA,     
    '' as ETL_FATURAMENTO,     
    cast(SUBSTRING(cast(TIMESTAMP_MILLIS(aux.timestamp_pedido) as STRING), 1, 19) as timestamp)AS LAST_UPDATE,
    'w_ped_aux' as tipo
from 
    w_ped_aux as aux
LEFT JOIN 
  w_pgsl_status as pg
  on pg.pedido_sap = aux.PEDIDO_SAP		  
where 
    aux.pedido_sap not in (select distinct pedido_sap from w_dash)

union all 
-- aqui tudo que não é RFC_DIGIBEE
select 
    cast(D.DATA as string) as Data_OV__c, D.PEDIDO_PORTAL as Pedido_Portal__c, 
    D.VALOR as Valor_do_pedido_original__c, D.VALOR as valor_faturado,
    CASE WHEN COALESCE(C.PEDIDO_SAP, '') = ''  THEN D.STATUS  ELSE C.MOTIVO END AS STATUS,
    D.status_final, '' as motivo_cancelamento, D.PEDIDO_SAP as Codigo_Pedido_SAP__c, '' as Mensagem_Integracao__c, 
    D.COND_PAG as Codigo_Condicao_Pagamento__c, 
    D.CLIENTE as Codigo_SAP__c, D.ORG_VENDA as Organizacao_Vendas__c, D.CANAL_DISTR as Canal__c, 
    D.VENDEDOR as Codigo_Vendedor_SAP__c, D.forma_pagamento as desdobramento,
    replace(D.forma_pagamento, ' dias', '') as parcelas, 
    D.ERNAM as Ernam__c, 
    coalesce(D.id_unico, '1_1000_7') as Id_Unico__c
    ,cast(TIMESTAMP_MILLIS(D.DATAHORA_TIMESTAMP) AS STRING) as Data_Hora_Pedido,     
    case when coalesce(D.ETL_VENDA, '') = '' then '' else substring(D.ETL_VENDA, 1, 10)||'T'||substring(D.ETL_VENDA, 12, 10)||'Z' end as ETL_VENDA, 
    case when coalesce(D.ETL_REMESSA, '') = '' then '' else substring(D.ETL_REMESSA, 1, 10)||'T'||substring(D.ETL_REMESSA, 12, 10)||'Z' end as ETL_REMESSA,     
    case when coalesce(D.ETL_FATURAMENTO, '') = '' then '' else substring(D.ETL_FATURAMENTO, 1, 10)||'T'||substring(D.ETL_FATURAMENTO, 12, 10)||'Z' end as ETL_FATURAMENTO,
        cast(SUBSTRING(CAST(case 
            when ETL_FATURAMENTO > ETL_VENDA then ETL_FATURAMENTO
            else ETL_VENDA
        end AS STRING),1,19) AS TIMESTAMP) AS LAST_UPDATE, 
    'w_dash' as tipo
from 
    w_dash AS D
LEFT JOIN 
    w_cancelado C
    on C.PEDIDO_SAP = D.PEDIDO_SAP