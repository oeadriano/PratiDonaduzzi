CREATE VIEW `prj-dados-prd-447818.ds_view_trusted.vw_user`
AS SELECT 
  ALIAS, TITLE, MOBILEPHONE, DEPARTMENT, STREET, CITY, STATE, POSTALCODE, COUNTRY, MANAGERID, FIRSTNAME, LASTNAME, MIDDLENAME, COMPANYNAME,
  replace(USERNAME,'.uat', '') as USERNAME, PROFILEID, PHONE, EMAIL, TIMEZONESIDKEY, LOCALESIDKEY, EMAILENCODINGKEY, LANGUAGELOCALEKEY, LEGACYUSER__C, USEREXTERNALID__C,
  REGISTRATIONID__C, ISACTIVE, ISCOMMISSIONABLE__C, coalesce(salestarget__c, 0) AS salestarget__c, 
  coalesce(sectorsalestarget__c, 0) AS sectorsalestarget__c, 
  coalesce(mixtarget__c, 0) AS mixtarget__c, 
  coalesce(positivationtarget__c, 0) AS positivationtarget__c
FROM 
  postgres_raw.user 
--where 
--  recordstamp >= date_sub(current_timestamp, interval 2 hour);