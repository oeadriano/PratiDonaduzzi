with 
  w_redes as (
    select id, Codigo_Rede__c
    from `dados-prod.sales_force.Account`
    where coalesce(Codigo_Rede__c, '') <> ''
  ),
  w_canal as 
  (
    select Id, Name from `dados-prod.sales_force.Canal__c`
  )
  ,  w_account_salesforce as (
  select 
    coalesce(Tipo_Bloqueio__c, '#N/A') as Tipo_Bloqueio__c, 
    Bloqueio__c,
    Limite_Credito__c, 
    Chave_Condicoes_Pagamento__c, 
    Pode_Comprar_Triangulacao__c, 
    Acc_Rede__c, 
    Associativismo_1_Codigo_SAP__c, 
    Associativismo_2_Codigo_SAP__c, 
    Distribuidor__c, Farmacia__c, Outras_Atividades__c, 
    Zona_Franca__c, 
    Responsavel_Tecnico__c, CRF_Responsavel_Tecnico__c, 
    Data_Vencimento_CRF_Responsavel_Tec__c, Tipo_Cobranca__c, 
    Classifica_o_de_Risco__c,
    Bloqueio_credito__c, 
    coalesce(Motivo_Bloqueio_credito__c, '#N/A') as Motivo_Bloqueio_credito__c, 
    Bloqueio_comercial__c, 
    coalesce(Motivo_Bloqueio_comercial__c, '#N/A') as Motivo_Bloqueio_comercial__c, 
    Documentos_Em_Dia__c, 
    ClientePositivado__c, 
    DuplicatasEmDia__c, 
    Codigo_sap__c,
    cast(Prazo_de_Validade_Outlet_Meses__c as integer) as Prazo_de_Validade_Outlet_Meses__c, 
    Business_Unit__c, Categoria_de_lista_de_precos__c,
    Canal_de_Vendas__c, r.Codigo_Rede__c
from 
    `dados-prod.sales_force.Account` a
join  
  w_canal c
  on c.id = a.Canal_de_Vendas__c
left join 
  w_redes r
  on r.id = a.Acc_Rede__c
--where 
  --c.name = 'CG Cloud'
  --and coalesce(Acc_Rede__c, '') <> ''
-- limit 10  
), 
w_cadastro_clientes as (
  select
    codigo, TIPO_BLOQUEIO, coalescew(AUFSD, '#N/A') as AUFSD, 
    cast(CLI_LIMITE as FLOAT64) as CLI_LIMITE, CONDICAOPG, 
    CROSSDOCKING, COD_REDE, ASSOCIATIVISMO1, ASSOCIATIVISMO2, FLAGDISTRIBUIDOR, 
    FLAGFARMACIA, FLAGOUTRATIV, FLAGZONAFRANCA, 
    RESPTECNICONOME, RESPTECNICOCRF, 
    CAST(DATACRF AS DATE) AS DATACRF, TIPOCOBRANCA, 
    coalesce(CTLPC, '') as CTLPC,
    Bloqueio_credito__c as CliBloqueio_credito, 
    Motivo_Bloqueio_credito__c as CliMotivo_Bloqueio_credito__c, 
    Bloqueio_comercial__c as CliBloqueio_comercial__c, 
    Motivo_Bloqueio_comercial__c as CliMotivo_Bloqueio_comercial__c, 
    DOCUMENTO_EM_DIA, POSITIVADO, 
    case when DUP_ATRASO = 'S' then 'N' else 'S' end as DUP_ATRASO, 
    OWNERID, cast(VALIDADE_MINIMA as integer) as VALIDADE_MINIMA, BusinessUnit__r_Chave_Externa__c, 
    LISTA_PRECO, Canal_de_Vendas__r_name, c.id as id_canal
  from 
    `dados-prod.sap_view.VB_TR_CGCLOUD_ACCOUNT` a
  join  
    w_canal c
    on c.name = a.Canal_de_Vendas__r_name    
 ),
w_clientes_update as (
  select
    c.codigo, a.codigo_sap__c, 
    c.AUFSD, a.bloqueio__c, 
    c.TIPO_BLOQUEIO, a.Tipo_Bloqueio__c,
    c.CLI_LIMITE, a.Limite_Credito__c,
    c.CROSSDOCKING, a.Pode_Comprar_Triangulacao__c,
    c.COD_REDE, a.Codigo_Rede__c, 
    c.ASSOCIATIVISMO1, a.Associativismo_1_Codigo_SAP__c,
    c.ASSOCIATIVISMO2, a.Associativismo_2_Codigo_SAP__c,
    c.FLAGDISTRIBUIDOR, a.Distribuidor__c,
    c.FLAGFARMACIA, a.Farmacia__c,
    c.FLAGOUTRATIV, a.Outras_Atividades__c,
    c.FLAGZONAFRANCA, a.Zona_Franca__c,
    c.RESPTECNICONOME, a.Responsavel_Tecnico__c,
    c.RESPTECNICOCRF, a.CRF_Responsavel_Tecnico__c,
    c.DATACRF, a.Data_Vencimento_CRF_Responsavel_Tec__c ,
    c.TIPOCOBRANCA, a.Tipo_Cobranca__c,
    c.CTLPC, a.Classifica_o_de_Risco__c ,
    c.CliBloqueio_credito, a.Bloqueio_credito__c ,
    c.CliMotivo_Bloqueio_credito__c , a.Motivo_Bloqueio_credito__c ,
    c.CliBloqueio_comercial__c, a.Bloqueio_comercial__c ,
    c.CliMotivo_Bloqueio_comercial__c, a.Motivo_Bloqueio_comercial__c ,
    c.DOCUMENTO_EM_DIA, a.Documentos_Em_Dia__c ,
    c.POSITIVADO, a.ClientePositivado__c ,
    c.DUP_ATRASO, a.DuplicatasEmDia__c ,
    c.VALIDADE_MINIMA, a.Prazo_de_Validade_Outlet_Meses__c ,
    c.BusinessUnit__r_Chave_Externa__c, a.Business_Unit__c ,
    c.LISTA_PRECO, a.Categoria_de_lista_de_precos__c ,
    c.Canal_de_Vendas__r_name, a.Canal_de_Vendas__c,
    c.id_canal,
    coalesce(c.LISTA_PRECO, a.Categoria_de_lista_de_precos__c) as SAPCategoria_de_lista_de_precos__c,
    a.Categoria_de_lista_de_precos__c
  from 
    w_account_salesforce a
  join 
    w_cadastro_clientes c
    on c.codigo = a.codigo_sap__c
  where
    c.TIPO_BLOQUEIO <> a.Tipo_Bloqueio__c or
    c.AUFSD <> a.bloqueio__c or
    c.CLI_LIMITE <> a.Limite_Credito__c or  
    c.CROSSDOCKING <> a.Pode_Comprar_Triangulacao__c or 
    c.COD_REDE <> a.Codigo_Rede__c or
    c.ASSOCIATIVISMO1 <> a.Associativismo_1_Codigo_SAP__c or
    c.ASSOCIATIVISMO2 <> a.Associativismo_2_Codigo_SAP__c or  
    c.FLAGDISTRIBUIDOR <> a.Distribuidor__c or
    c.FLAGFARMACIA <> a.Farmacia__c or
    c.FLAGOUTRATIV <> a.Outras_Atividades__c or
    c.FLAGZONAFRANCA <> a.Zona_Franca__c or
    c.RESPTECNICONOME <> a.Responsavel_Tecnico__c or
    c.RESPTECNICOCRF <> a.CRF_Responsavel_Tecnico__c or
    c.DATACRF <> a.Data_Vencimento_CRF_Responsavel_Tec__c or
    c.TIPOCOBRANCA <> a.Tipo_Cobranca__c or
    c.CTLPC <> a.Classifica_o_de_Risco__c or
    c.CliBloqueio_credito <> a.Bloqueio_credito__c or
    c.CliMotivo_Bloqueio_credito__c <> a.Motivo_Bloqueio_credito__c or
    c.CliBloqueio_comercial__c <> a.Bloqueio_comercial__c or
    c.CliMotivo_Bloqueio_comercial__c <> a.Motivo_Bloqueio_comercial__c or  
    c.DOCUMENTO_EM_DIA <> a.Documentos_Em_Dia__c or
    c.POSITIVADO <> a.ClientePositivado__c or
    c.DUP_ATRASO <> a.DuplicatasEmDia__c or
    c.VALIDADE_MINIMA <> a.Prazo_de_Validade_Outlet_Meses__c or
    c.BusinessUnit__r_Chave_Externa__c <> a.Business_Unit__c or    
    coalesce(c.LISTA_PRECO, a.Categoria_de_lista_de_precos__c) <> a.Categoria_de_lista_de_precos__c or  
    coalesce(a.Canal_de_Vendas__c, '') = ''
)
select 
    coalesce(c.TIPO_BLOQUEIO, '') as Tipo_Bloqueio__c, 		 
    coalesce(c.AUFSD, '') as Bloqueio__c, 
    c.CLI_LIMITE as Limite_Credito__c, 
    c.CROSSDOCKING AS Pode_Comprar_Triangulacao__c, 
    coalesce(c.COD_REDE, '') as Acc_Rede__c, 
    coalesce(c.ASSOCIATIVISMO1, '') as Associativismo_1__c, 
    coalesce(c.ASSOCIATIVISMO2, '') as Associativismo_2__c, 
    c.FLAGDISTRIBUIDOR as Distribuidor__c, c.FLAGFARMACIA as Farmacia__c, c.FLAGOUTRATIV as Outras_Atividades__c, 
    c.FLAGZONAFRANCA as Zona_Franca__c, 
    c.RESPTECNICONOME as Responsavel_Tecnico__c, c.RESPTECNICOCRF as CRF_Responsavel_Tecnico__c, 
    c.DATACRF as Data_Vencimento_CRF_Responsavel_Tec__c, c.TIPOCOBRANCA as Tipo_Cobranca__c, 
    c.CTLPC as Classifica_o_de_Risco__c,
    case 
      when c.CTLPC = '' then 'S'
      when c.CTLPC <> '' then coalesce(c.CliBloqueio_credito, '') 
    end as Bloqueio_credito__c, 
    coalesce(c.CliMotivo_Bloqueio_credito__c, '') as Motivo_Bloqueio_credito__c, 
    coalesce(c.CliBloqueio_comercial__c, '') as Bloqueio_comercial__c, 
    coalesce(c.CliMotivo_Bloqueio_comercial__c, '') as Motivo_Bloqueio_comercial__c, 
    c.DOCUMENTO_EM_DIA as Documentos_Em_Dia__c, 
    c.POSITIVADO as ClientePositivado__c, 
    c.DUP_ATRASO as DuplicatasEmDia__c, 
    c.codigo, 
    VALIDADE_MINIMA, 
    BusinessUnit__r_Chave_Externa__c, 
    SAPCategoria_de_lista_de_precos__c as LISTA_PRECO,
    Canal_de_Vendas__r_name  					
from 
  w_clientes_update c
