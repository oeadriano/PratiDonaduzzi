CREATE VIEW `prj-dados-prd-447818.ds_view_trusted.vw_pricing_customer_standard`
AS SELECT   
  'n' as cgcloud__Status__c, 
  case 
    when a.kschl = 'ZPMC' then 'PCT-250 Price PMC'
    else 'PCT-240 Price PMF'    
    end as cgcloud__Pricing_Condition_Template__c,     
   a.datab as cgcloud__Valid_From__c, 
  case 
    when a.datbi >= cast('2099-12-31' as date) then '2099-12-31'
    else a.datbi
  end as cgcloud__Valid_Thru__c, 
  b.kbetr as cgcloud__Value__c, 
  'SalesUnit' as cgcloud__Logistic_Unit__c, 
  ltrim(a.matnr, '0') as cgcloud__Product__c,
  'SalesUnit' as cgcloud__Threshold_Unit__c,
  b.konwa as cgcloud__Currency__c, 
  1 as cgcloud__Denominator__c, 
  '0001' as cgcloud__Sales_Org__c, 
  'KT-140' as cgcloud__Key_Type__c, 
  a.pltyp as cgcloud__Key_1__c,   
  '' as cgcloud__Key_2__c, '' as cgcloud__Key_3__c, '' as cgcloud__Key_4__c, '' as cgcloud__Key_5__c,         
  a.kschl||'-'||a.pltyp||'-'||ltrim(a.matnr, '0') as cgcloud__External_Id__c,
  -- menor recorstamp entre as duas tabelas para garantir
  -- que o reg seja atualizado
  case
    when a.recordstamp <= b.recordstamp then a.recordstamp
    else b.recordstamp
  end as recordstamp

  FROM `sap_raw.a903` AS a
      INNER JOIN `sap_raw.konp` AS b ON b.knumh = a.knumh      
 WHERE a.kappl = 'V'
   AND a.kschl IN ('ZPMC','ZPRF')
   AND b.kbetr >= 0
   AND a.datab <= current_date
   AND a.datbi >= current_date
   /*
   AND ( a.recordstamp >= date_sub(current_timestamp, interval 120 minute) 
         OR 
         b.recordstamp >= date_sub(current_timestamp, interval 120 minute) 
       )
  */       
   --AND a.matnr = '000000000000000023'   ;