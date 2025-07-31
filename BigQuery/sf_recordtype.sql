SELECT *
from ds_trusted.INFORMATION_SCHEMA.TABLES

select Id, Name, DeveloperName, NamespacePrefix, Description,  SobjectType
from RecordType 
where SobjectType = 'Product2'

select Id, Name, cgcloud__Description__c, cgcloud__Active__c
from cgcloud__Product_Template__c  

CREATE TABLE `prj-dados-qas.ds_trusted.sf_recordtype_template`

(
  objeto STRING,
  Id STRING,
  name STRING,
  DeveloperName STRING,
  NamespacePrefix STRING,
  Description STRING,
  SobjectType STRING,
  ambiente STRING
);

select * from  ds_trusted.sf_recordtype_template

delete from  ds_trusted.sf_recordtype_template where id <> ''

insert into ds_trusted.sf_recordtype_template (Objeto, Id, name, DeveloperName, NamespacePrefix, Description, SobjectType, ambiente) values ('RecordType', '012as000000BxlqAAC', 'Product', 'Product', 'cgcloud', 'This record type is for creating CGCloud Products', 'Product2', 'QAS');
insert into ds_trusted.sf_recordtype_template (Objeto, Id, name, DeveloperName, NamespacePrefix, Description, SobjectType, ambiente) values ('RecordType', '012as000000BxlrAAC', 'Product Group', 'Product_Group', 'cgcloud', 'This record type is for creating CGCloud Product Groups', 'Product2', 'QAS');
insert into ds_trusted.sf_recordtype_template (Objeto, Id, name, DeveloperName, NamespacePrefix, Description, SobjectType, ambiente) values ('cgcloud__Product_Template__c', 'a3788000000uNI5AAM', 'Product', '', '', 'Produto', '', 'QAS');
insert into ds_trusted.sf_recordtype_template (Objeto, Id, name, DeveloperName, NamespacePrefix, Description, SobjectType, ambiente) values ('cgcloud__Product_Template__c', 'a3788000000uWRpAAM', 'Produto', '', '', 'Produto', '', 'QAS');
insert into ds_trusted.sf_recordtype_template (Objeto, Id, name, DeveloperName, NamespacePrefix, Description, SobjectType, ambiente) values ('cgcloud__Product_Template__c', 'a3788000000uWRqAAM', 'Grupo', '', '', 'Grupo', '', 'QAS');
insert into ds_trusted.sf_recordtype_template (Objeto, Id, name, DeveloperName, NamespacePrefix, Description, SobjectType, ambiente) values ('cgcloud__Product_Template__c', 'a3788000000uWRrAAM', 'Classe Terapêutica', '', '', 'Classe Terapêutica', '', 'QAS');
insert into ds_trusted.sf_recordtype_template (Objeto, Id, name, DeveloperName, NamespacePrefix, Description, SobjectType, ambiente) values ('cgcloud__Product_Template__c', 'a3788000000uWRsAAM', 'Princípio Ativo', '', '', 'Princípio Ativo', '', 'QAS');
insert into ds_trusted.sf_recordtype_template (Objeto, Id, name, DeveloperName, NamespacePrefix, Description, SobjectType, ambiente) values ('cgcloud__Product_Template__c', 'a3788000000uWRtAAM', 'Farmácia Popular', '', '', 'Farmácia Popular', '', 'QAS');
insert into ds_trusted.sf_recordtype_template (Objeto, Id, name, DeveloperName, NamespacePrefix, Description, SobjectType, ambiente) values ('cgcloud__Product_Template__c', 'a3788000000vBYDAA2', 'Vitamina', '', '', 'Vitamina', '', 'QAS');
