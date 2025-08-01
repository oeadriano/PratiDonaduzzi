CREATE VIEW `prj-dados-prd-447818.ds_view_trusted.vw_cgcloud__Unit_of_Measure__c`
AS SELECT 
  distinct productcode as cgcloud__Product__c, UnitofMeasure as cgcloud__Unit_Type__c, 
  'Never' as cgcloud__Rounding_Rule__c,
  'true' as cgcloud__Is_Consumer_Unit__c,
  'true' as 	cgcloud__Is_Order_Unit__c,
  'true' as cgcloud__Is_Price_Unit__c,
  'true' as cgcloud__Order_Ability__c,
  1	as cgcloud__Pieces_per_Smallest_Unit__c,
  1	as cgcloud__Pieces_per_parent_unit__c,
  'false' as cgcloud__Rounding_Target__c,
  1	as cgcloud__Sort__c,
  0	as cgcloud__Volume__c,
  0	as cgcloud__Weight__c, 
  productcode||"-"||UnitofMeasure as ExternalId__c
FROM 
  `ds_view_trusted.vw_product2` 
where 
  coalesce(UnitofMeasure, '') <> ''
  and recordstamp >= date_sub(current_timestamp, interval 2 hour )
  ;