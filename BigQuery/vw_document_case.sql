CREATE VIEW `prj-dados-prd-447818.ds_view_trusted.vw_document_case`
AS SELECT 
  account as account__c, 
  '' as type, 
  'Atualização de Documento' as recordtype, 
  'Encerrado' as status, 
  true as isclosed,   
  docoriginalorcopy__c as DocCopy__c,
  docdaystonotice__c,
  codedoc as DocDescription__c,    
  docdate__c as DocExpiration__c,  
  docidentificationnote__c,
  DocDaysToBlock__c,   
  doctype__c, 
  case
    when Coalesce(FORMAT_DATE("%Y%m%d", docdate__c), '') = '' 
      then account ||'-'|| codedoc
      else account ||'-'|| codedoc ||'-'|| Coalesce(FORMAT_DATE("%Y%m%d", docdate__c), '') 
    end as externalid__c,   
  blocksell__c, 
  'Atualizado pelo Esfera' as RequiredJustification__c
FROM 
  postgres_raw.document_customer_case
where
  recordstamp >= date_sub(current_timestamp, interval 120 minute)
order by account, DocDescription__c
;