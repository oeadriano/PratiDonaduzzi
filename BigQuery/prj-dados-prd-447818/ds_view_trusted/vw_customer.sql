CREATE VIEW `prj-dados-prd-447818.ds_view_trusted.vw_customer`
AS with w_iqvia as (
  /*
    qde de vinculos entre baseed e clientes: 
    - por cnpj: 80352
    - por codigo 71673
    por esse motivo o vinculo abaixo esta por cnpj 
    entre clientes Prati e IQVIA 
  */
  select 
    b.cnpj__c, ROUND(b.MarketTotal__c, 2) as MarketTotal__c, ROUND(b.PratiTotal__c, 2) as PratiTotal__c,   
    b.PratiPotential__c, b.BrickOld__c, b.BrickNew__c,
    case 
      when PratiPotential__c = '1' then 'Diamante'
      when PratiPotential__c = '2' then 'Platina'
      when PratiPotential__c in ('3', '4') then 'Ouro'
      when PratiPotential__c in ('5', '6') then 'Prata'
      when PratiPotential__c in ('7', '8') then 'Bronze'  
    end as Class__c, 
    b.openchannel__c, b.scorestatusppp__c
  from 
    postgres_raw.baseed b
),
w_user_ativo as (
  select userexternalid__c
  from `postgres_raw.user`
  where isactive = true
),
w_customer_credit_base as (
  select
    cgcloud__ExternalId__c, 
    Classe_de_risco__c, 
    Tabela_Preco__c, 
    Preco_Negociado__c, 
    CustomerGroup__c, 
    SalesDistrict__c,
    Industry,  
    AccountGroup__c, 
    ServiceTeam__c
  from 
    ds_view_trusted.vw_customer_credit_base  
),
w_warehouse as 
  (
  SELECT 
    distinct ExternalId__c 
  FROM 
    `ds_view_trusted.vw_cgcloud__warehouse__c`     
)
SELECT
  pa.cgcloud__externalid__c, pa.name, pa.cgcloud__name_2__c, pa.billingstreet, pa.billingcity, pa.billingstate, pa.billingpostalcode, pa.billingcountry,
  shippingstreet, pa.shippingcity, pa.shippingstate, pa.shippingpostalcode, pa.shippingcountry, pa.phone, pa.website, 
  -- AEO 03-07-2025
  -- pa.ownerid tem o codigo do televendor
  -- pa.vendor_code tem o codigo do reprensentante  
  -- AEO 09-10-2025
  -- se vendor_code estiver ativo em user, considera vendor_code,
  -- caso contratio mantem TV para nao dar erro na integração
  case
    when coalesce(us.UserExternalId__c, '') <> '' then pa.vendor_code 
    else pa.ownerid    
  end as ownerid, 
  pa.cgcloud__account_email__c,
  EINId__c, pa.nationalid__c, pa.stateregistration__c, pa.MunicipalRegistration__c, pa.customerstatus__c, pa.type, pa.servicepreference__c, 
  case
    when k.KNKLI = k.kunnr then ''
    else ltrim(k.KNKLI, '0')
  end as CreditAccount__c, 
  pa.recordstamp, 
  case
    when coalesce(w.ExternalId__c, '') <> '' then 'Warehouse'
    else 'Cliente'
  end as RecordType, 
  case
    when coalesce(w.ExternalId__c, '') <> '' then 'Warehouse'
    else 'Cliente'
  end as cgcloud__Account_Template__c,
  -- AEO 120625 - tipo warehouse precisa enviar o codigo dele mesmo
  case
    when coalesce(w.ExternalId__c, '') <> '' then pa.cgcloud__externalid__c
    else ''
  end as Warehouse__c, 
  -- base IQVIA
  coalesce(iq.PratiTotal__c,0) as PratiTotal__c,    
  coalesce(iq.PratiPotential__c, '') as PratiPotential__c, 
  coalesce(iq.BrickOld__c,'') as BrickOld__c,  
  coalesce(iq.BrickNew__c,'') as BrickNew__c, 
  coalesce(iq.Class__c,'') as Class__c, 
  coalesce(iq.openchannel__c,'') as openchannel__c,  
  coalesce(iq.scorestatusppp__c,'') as scorestatusppp__c,
  cb.Classe_de_risco__c, 
  cb.Tabela_Preco__c, 
  cb.Preco_Negociado__c, 
  cb.CustomerGroup__c, 
  cb.SalesDistrict__c,
  cb.Industry,  
  cb.AccountGroup__c, 
  cb.ServiceTeam__c
FROM 
  postgres_raw.account pa
left join 
  w_customer_credit_base as cb
  on cb.cgcloud__ExternalId__c = pa.cgcloud__externalid__c
left join 
  w_iqvia iq
  on ltrim(pa.EINId__c, '0') = ltrim(iq.cnpj__c, '0')  
left join
  w_user_ativo us
  on us.UserExternalId__c = vendor_code
join
  `sap_raw.knkk` k
  on ltrim(k.kunnr, '0') = pa.cgcloud__externalid__c
left join w_warehouse w
  on w.ExternalId__c = pa.cgcloud__externalid__c
where 
  pa.recordstamp >= date_sub(current_timestamp, interval 2 HOUR) 

;