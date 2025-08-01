CREATE VIEW `prj-dados-prd-447818.ds_view_trusted.vw_cgcloud__pricing_condition_stage`
AS with w_base as (
    select matnr 
    from `ds_view_trusted.vw_cgcloud_product2_hierarquia_base`
)
select 
  cgcloud__account__c, cgcloud__Status__c, cgcloud__Pricing_Condition_Template__c, 
  cgcloud__Key_Type__c, cgcloud__Valid_From__c, cgcloud__Valid_Thru__c, cgcloud__Value__c, 
  cgcloud__Logistic_Unit__c, cgcloud__Product__c, cgcloud__Threshold_Unit__c, 
  cgcloud__Currency__c, cgcloud__Denominator__c, cgcloud__Sales_Org__c, 
  cgcloud__Key_1__c, cgcloud__Key_2__c, cgcloud__Key_3__c, cgcloud__Key_4__c, 
  cgcloud__Key_5__c, cgcloud__external_id__c, recordstamp  
from 
  (
    select
      distinct coalesce(st.cgcloud__account__c, '') as cgcloud__account__c, st.cgcloud__Status__c, st.cgcloud__Pricing_Condition_Template__c, 
      st.cgcloud__Key_Type__c, st.cgcloud__Valid_From__c, st.cgcloud__Valid_Thru__c, st.cgcloud__Value__c, 
      st.cgcloud__Logistic_Unit__c, ltrim(st.cgcloud__Product__c, '0') as cgcloud__Product__c, 
      st.cgcloud__Threshold_Unit__c, st.cgcloud__Currency__c, st.cgcloud__Denominator__c, 
      st.cgcloud__Sales_Org__c, st.cgcloud__Key_1__c, st.cgcloud__Key_2__c, st.cgcloud__Key_3__c, st.cgcloud__Key_4__c, 
      st.cgcloud__Key_5__c, st.cgcloud__external_id__c, st.recordstamp
    FROM 
      `postgres_raw.pricing_condition_stage` st
    join   
      w_base as base
      on base.matnr = ltrim(cgcloud__Product__c, '0')
    where   
      current_date between cgcloud__valid_from__c and cgcloud__valid_thru__c
      --and st.recordstamp >= date_sub(current_timestamp,  INTERVAL 2 HOUR)
    union all 
    SELECT 
      distinct '' as cgcloud__account__c, st.cgcloud__Status__c, st.cgcloud__Pricing_Condition_Template__c, 
        st.cgcloud__Key_Type__c, st.cgcloud__Valid_From__c, st.cgcloud__Valid_Thru__c, st.cgcloud__Value__c, 
        st.cgcloud__Logistic_Unit__c, st.cgcloud__Product__c, 
        st.cgcloud__Threshold_Unit__c, st.cgcloud__Currency__c, st.cgcloud__Denominator__c, 
        st.cgcloud__Sales_Org__c, st.cgcloud__Key_1__c, st.cgcloud__Key_2__c, st.cgcloud__Key_3__c, st.cgcloud__Key_4__c, 
        st.cgcloud__Key_5__c, st.cgcloud__external_id__c, st.recordstamp
      FROM 
        `ds_view_trusted.vw_pricing_customer_standard` st
    join   
      w_base as base
      on base.matnr = ltrim(st.cgcloud__Product__c, '0')
    --where
      --st.recordstamp >= date_sub(current_timestamp,  INTERVAL 2 HOUR)
  ) 
where 
  -- DT esta rodando a cada 6 horas.
  -- a ideia é no começo, enviar todos os registros atualizados a cada 2 horas
  -- acrescido dos registros q nao estao no tabela atualizada pelo DT.
  cgcloud__external_id__c not in (select cgcloud__external_id__c from `Temp.cgcloud__CP_Pricing_Condition_Stage__c`)
  OR recordstamp >= date_sub(current_timestamp,  INTERVAL 2 HOUR)
order by cgcloud__external_id__c    
;