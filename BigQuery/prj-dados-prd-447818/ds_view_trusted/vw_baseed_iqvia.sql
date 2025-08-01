/*
  qde de vinculos entre baseed e clientes: 
  - por cnpj: 80352
  - por codigo 71673
  por esse motivo o vinculo abaixo esta por cnpj 
  entre clientes Prati e IQVIA 
*/

select 
  --b.praticode__c, 
  pa.cgcloud__externalid__c as praticode__c, 
  ROUND(b.MarketTotal__c, 2) as MarketTotal__c, ROUND(b.PratiTotal__c, 2) as PratiTotal__c,   
  b.PratiPotential__c, b.BrickOld__c, b.BrickNew__c,
  case 
    when PratiPotential__c = '1' then 'Diamante'
    when PratiPotential__c = '2' then 'Platina'
    when PratiPotential__c in ('3', '4') then 'Ouro'
    when PratiPotential__c in ('5', '6') then 'Prata'
    when PratiPotential__c in ('7', '8') then 'Bronze'  
  end as Class__c, 
  b.openchannel__c, b.scorestatusppp__c, b.recordstamp
from 
  postgres_raw.baseed b
join 
  postgres_raw.account pa
  on ltrim(pa.einid__c, '0') = ltrim(b.cnpj__c, '0')  
order by 
  praticode__c
