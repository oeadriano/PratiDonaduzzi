CREATE VIEW `prj-dados-prd-447818.ds_view_trusted.vw_condicao_pagamento_flatten__c`
AS with w_payment as ( 
  -- regras de atribuição das condições de pagamento    
    select
      distinct 
      coalesce(customer_group, '') as customer_group, coalesce(risk_class, '') as risk_class, 
      coalesce(payment_key, '') as payment_key, coalesce(initial_value, 0) as initial_value, 
      coalesce(sell_for, '') as sell_for,       
      case 
        when coalesce(cast(network_code as string), '') <> '' then 'R'||cast(network_code as string)
        else coalesce(cast(network_code as string), '')
      end as network_code, 
      coalesce(customer_code, '') as customer_code, 
      case
        when sell_for in ('E', 'A') then 'true'
        else 'false'
      end as Venda_empresa__c, 
      case
        when sell_for in ('O', 'A') then 'true'
        else 'false'
      end as Venda_operador__c,
      rule_type, valid_thru
    from 
      postgres_raw.payment_condition
    where
      valid_thru >= '2025-01-01' -- tirando regras muito antigas do select
      and recordstamp >= date_sub(current_timestamp, interval 60 minute)
  )
-- condicoes por grupo+classe de risco
-- ExternalId__c = 'C---Y076-1-true-true--168827'
select   
  distinct 
    pa.rule_type ||'-'||pa.customer_group ||'-'|| pa.risk_class ||'-'|| pa.payment_key ||'-'|| 
    pa.initial_value  ||'-'|| pa.Venda_empresa__c ||'-'|| pa.Venda_operador__c ||'-'|| 
    pa.network_code   ||'-'|| pa.customer_code 
  as ExternalId__c,   
  c.Descricao__c, 
  case
    when valid_thru < current_date then false
    else true
  end as Ativo__c, c.Prazo_medio__c, c.Parcelas__c, 
  case
    when rule_type = 'G' then 'Grupo' 
    when rule_type = 'C' then 'Cliente' 
    when rule_type = 'R' then 'Rede' 
  end as Tipo_regra__c, 
  pa.customer_group as Grupo_do_cliente__c,
  network_code as Rede__c,
  customer_code as Account__c,
  pa.risk_class as Classe_de_risco__c,
  pa.initial_value as Valor_inicial__c, 
  pa.Venda_empresa__c, pa.Venda_operador__c,
  c.ExternalId__c as Condicao_pagamento__c, 
  rule_type
from 
  w_payment pa
join 
  `ds_view_trusted.vw_condicao_pagamento__c` as c 
  on c.ExternalId__c = pa.payment_key
order by
  rule_type, customer_group, risk_class, network_code, pa.customer_code, c.ExternalId__c;