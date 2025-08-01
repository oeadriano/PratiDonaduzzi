CREATE VIEW `prj-dados-prd-447818.ds_view_trusted.vw_cgcloud__account_receivable__c`
AS select 
  '240968'||'1234' as cgcloud__External_Id__c,
  240968 as cgcloud__Account__c,
  1000.01 as cgcloud__Amount__c,
  1000.01 as cgcloud__Amount_Open__c,
  'Invoice' as cgcloud__Document_Type__c,
  '2025-03-30' as cgcloud__Due_Date__c,
  'PartiallyPaid' as cgcloud__Invoice_Status__c,
  '' as cgcloud__Receipt_Date__c
union all 
select
  '240970'||'1234' as cgcloud__External_Id__c,
  240970 as cgcloud__Account__c,
  1000.01 as cgcloud__Amount__c,
  1000.01 as cgcloud__Amount_Open__c,
  'Invoice' as cgcloud__Document_Type__c,
  '2025-03-30' as cgcloud__Due_Date__c,
  'UnPaid' as cgcloud__Invoice_Status__c,
  '' as cgcloud__Receipt_Date__c;