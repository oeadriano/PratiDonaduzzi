select * from dados-prod.sales_force.cgcloud_usuarios_ativos

CALL `dados-prod.sales_force.prc_user_ativo_ct_cg`()

CREATE OR REPLACE PROCEDURE `dados-prod.sales_force.prc_user_ativo_ct_cg`()
BEGIN

  MERGE `dados-prod.sales_force.cgcloud_usuarios_ativos` atv
  USING `dados-prod.sap.VH_MD_CGCLOUD_USERS` us
  ON	atv.LIFNR = us.CODIGO_SAP__C  
  WHEN NOT MATCHED THEN
  INSERT (LIFNR, ATIVO_CT, ATIVO_CG, LAST_UPDATE) 
  VALUES (US.CODIGO_SAP__C, 'N', 'N', CURRENT_TIMESTAMP())
  ;

END;



select 
  *
from 
  `dados-prod.sales_force.cgcloud_usuarios_ativos`
where 
ativo_cg = 'S' and 
lifnr in 


update `dados-prod.sales_force.cgcloud_usuarios_ativos`
set ativo_cg = 'S', OBSERVACAO = 'Planlha de 08-10-24'
where 
ativo_cg = 'N' and 
lifnr in 