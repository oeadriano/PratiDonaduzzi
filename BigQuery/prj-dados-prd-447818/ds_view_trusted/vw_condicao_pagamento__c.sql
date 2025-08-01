CREATE VIEW `prj-dados-prd-447818.ds_view_trusted.vw_condicao_pagamento__c`
AS with w_parcelas as
  (
    select 
      zterm, count(*) as parcelas
    from 
      (
      select 
        zterm, parc
      from 
        `sap_raw.t052u`, unnest(split(replace(text1, ' DIAS', ''), '/')) parc
      where
        zterm like 'Y%' 
        -- and    
        -- recordstamp >= date_sub(current_timestamp, interval 2 HOUR)
      )    
    group by 
      zterm
  )      
select 
  t.zterm as ExternalId__c, t.text1 as Descricao__c, p.Parcelas as Parcelas__c, 10 as Prazo_medio__c, 'true' as Ativo__c
from 
  `sap_raw.t052u` t
join
  w_parcelas p
  on p.zterm = t.zterm
where 
  t.zterm like 'Y%'
order by t.zterm;