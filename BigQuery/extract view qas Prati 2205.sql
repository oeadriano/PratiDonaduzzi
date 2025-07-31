/*
	SELECT table_name, cast(view_definition as STRING) as DML
	from ds_view_trusted.INFORMATION_SCHEMA.VIEWS
*/

create or replace view prj-dados-prd-447818.ds_view_trusted.vw_cgcloud__account_receivable__c 	as (
select 
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
  '' as cgcloud__Receipt_Date__c
);


create or replace view prj-dados-prd-447818.ds_view_trusted.vw_cgcloud__account_relationship__c as (
/*
cgcloud__Is_Primary_Relationship__c
cgcloud__Related_Account__c
cgcloud__Related_Account_Name__c
cgcloud__Relationship_Type__c
cgcloud__Self_Relationship__c
cgcloud__Start_Date__c
cgcloud__End_Date__c
*/
with w_uf as (
  SELECT 'AC' AS uf, 'ACRE' AS estado UNION ALL
  SELECT 'AL', 'ALAGOAS' UNION ALL
  SELECT 'AP', 'AMAPA' UNION ALL
  SELECT 'AM', 'AMAZONAS' UNION ALL
  SELECT 'BA', 'BAHIA' UNION ALL
  SELECT 'CE', 'CEARA' UNION ALL
  SELECT 'DF', 'DISTRITO FEDERAL' UNION ALL
  SELECT 'ES', 'ESPIRITO SANTO' UNION ALL
  SELECT 'GO', 'GOIAS' UNION ALL
  SELECT 'MA', 'MARANHAO' UNION ALL
  SELECT 'MT', 'MATO GROSSO' UNION ALL
  SELECT 'MS', 'MATO GROSSO DO SUL' UNION ALL
  SELECT 'MG', 'MINAS GERAIS' UNION ALL
  SELECT 'PA', 'PARA' UNION ALL
  SELECT 'PB', 'PARAIBA' UNION ALL
  SELECT 'PR', 'PARANA' UNION ALL
  SELECT 'PE', 'PERNAMBUCO' UNION ALL
  SELECT 'PI', 'PIAUI' UNION ALL
  SELECT 'RJ', 'RIO DE JANEIRO' UNION ALL
  SELECT 'RN', 'RIO GRANDE DO NORTE' UNION ALL
  SELECT 'RS', 'RIO GRANDE DO SUL' UNION ALL
  SELECT 'RO', 'RONDONIA' UNION ALL
  SELECT 'RR', 'RORAIMA' UNION ALL
  SELECT 'SC', 'SANTA CATARINA' UNION ALL
  SELECT 'SP', 'SAO PAULO' UNION ALL
  SELECT 'SE', 'SERGIPE' UNION ALL
  SELECT 'TO', 'TOCANTINS'
)
select 
  a.billingstate, w.cgcloud__State__c, a.cgcloud__externalid__c as Account_ExternalID, w.ExternalId__c as Warehouse_ExternalId, w.EmpresaOperador__c
from 
--select * from  
  `postgres_raw.account` a
join
  w_uf uf
  on uf.uf = a.billingstate  
join
  `ds_view_trusted.vw_cgcloud__warehouse__c` w
  on w.cgcloud__State__c = uf.estado
order by
  a.cgcloud__externalid__c, w.ExternalId__c
);

create or replace view prj-dados-prd-447818.ds_view_trusted.vw_cgcloud__org_unit__c as (
SELECT 
                externalid__c, 
                cgcloud__Description_Language_1__c,
                cgcloud__Org_Type__c,
                cgcloud__Org_Level__c, 
                cgcloud__Sales_Org__c,
                cgcloud__Main__c
from 
  prj-dados-prd-447818.postgres_raw.org_unit
);
  
create or replace view prj-dados-prd-447818.ds_view_trusted.vw_cgcloud__inventory__c as (  
select 
  distinct e.werks||"-"||e.matnr||"-"||e.kunnr as ExternalId__c, 
  'Active' cgcloud__Phase__c,
  '0001' as cgcloud__Sales_Org__c,
  p.cgcloud__Short_Description_Language_1__c as cgcloud__Description_Language_1__c,
  e.labst as cgcloud__Initial_Inventory__c, 
  'Estoque Padrão' as cgcloud__Inventory_Template__c,
  p.cgcloud__Product_Short_Code__c as cgcloud__Product__c,
  '' cgcloud__Tour__c,
  '2025-01-01' as cgcloud__Valid_From__c,
  '2099-12-31' as cgcloud__Valid_Thru__c,
  ltrim(e.kunnr, '0') as cgcloud__warehouse__c  
from 
  prj-dados-prd-447818.sap_raw.ztbsf001 e
join
  `prj-dados-prd-447818.ds_view_trusted.vw_product2` p
  on ltrim(e.matnr, '0') = p.ProductCode
);


create or replace view prj-dados-prd-447818.ds_view_trusted.vw_cgcloud__org_unit_user__c as (
select 
  cgcloud__Org_Unit__c,
  cgcloud__Management_Type__c, 
  cgcloud__Main__c, 
  cgcloud__User__c, 
  cgcloud__Valid_From__c, 
  cgcloud__Valid_Thru__c,
  cgcloud__Org_Unit__c ||'-'|| cgcloud__User__c as ExternalId__c
from   
  prj-dados-prd-447818.postgres_raw.org_unit_user
);

create or replace view prj-dados-prd-447818.ds_view_trusted.vw_customer_network as (
select 
  cgcloud__ExternalId__c, 
  name, 
  TradeName__c,
  case     
    when cgcloud__ExternalId__c in ('R11', 'R485') then 'Associativismo'
    else 'Rede'
  end as RecordType, 
  case     
    when cgcloud__ExternalId__c in ('R11', 'R485') then 'Associativismo'
    else 'Rede'
  end as cgcloud__Account_Template__c
 from 
  prj-dados-prd-447818.postgres_raw.customer_network  
 );
 
create or replace view prj-dados-prd-447818.ds_view_trusted.vw_cgcloud__account_org_unit__c as (
select 
  cgcloud__Org_Unit__c, 
  cgcloud__Account__c, 
  cgcloud__Active__c,
  cgcloud__Valid_From__c,
  cgcloud__Valid_Thru__c,
  externalid__c
from prj-dados-prd-447818.postgres_raw.account_org_unit
);

create or replace view prj-dados-prd-447818.ds_view_trusted.vw_condicao_pagamento_flatten__c as (
select 
  ExternalId__c||'-Grupo-01-02-100001-056' as ExternalId__c, 
  Descricao__c, 
  Ativo__c, 
  Prazo_medio__c, 
  Parcelas__c, 
  'Grupo' as Tipo_regra__c, 
  '01' as Grupo_do_cliente__c,
  '02' as Rede__c,
  '' as Account__c,
  '056' as Classe_de_risco__c,
  100.01 as Valor_inicial__c, 
  'true' as Venda_empresa__c, 
  'false' as Venda_operador__c, 
  ExternalId__c as Condicao_pagamento__c
from 
  `ds_view_trusted.vw_condicao_pagamento__c`
 );
 
 
create or replace view prj-dados-prd-447818.ds_view_trusted.vw_cgcloud__warehouse_product__c as (
select 
  LTRIM(cgcloud__product__c, '0') as cgcloud__Product__c, 
  cgcloud__Warehouse__c,
  '0001' as cgcloud__Sales_Org__c,
  'true' as cgcloud__Active__c,
  externalid__c as cgcloud__ExternalId__c      
  from 
    `prj-dados-prd-447818.postgres_raw.warehouse_product` 
); 

create or replace view prj-dados-prd-447818.ds_view_trusted.vw_condicao_pagamento__c as ( 
with w_parcelas as
  (
    select 
      zterm, count(*) as parcelas
    from 
      (
      select 
        zterm, parc
      from 
        `sap_raw.t052u`, unnest(split(replace(text1, ' DIAS', ''), '/')) parc
      where
        zterm like 'Y%'
      )    
    group by 
      zterm
  )      
select 
  t.zterm as ExternalId__c, t.text1 as Descricao__c, p.Parcelas as Parcelas__c, 10 as Prazo_medio__c, 'true' as Ativo__c
from 
  `sap_raw.t052u` t
join
  w_parcelas p
  on p.zterm = t.zterm
where 
  t.zterm like 'Y%'
order by t.zterm);

create or replace view prj-dados-prd-447818.ds_view_trusted.vw_cgcloud__warehouse__c as (
SELECT 
  ExternalId__c, cgcloud__Sales_Org__c, cgcloud__State__c, cgcloud__City__c, cgcloud__Country__c,   
  cgcloud__description_language_1__c, EmpresaOperador__c, SAPSalesOrg__c, SAPPlant__c, SAPStoreLoc__c, 
  '' as SAPDivision__c 
FROM   
  `prj-dados-prd-447818.postgres_raw.warehouse`  
order by 
  ExternalId__c
); 

create or replace view prj-dados-prd-447818.ds_view_trusted.vw_customer as (
with w_warehouse as 
  (
  SELECT 
    distinct ExternalId__c 
  FROM 
    `prj-dados-prd-447818.ds_view_trusted.vw_cgcloud__warehouse__c`     
)
SELECT
  pa.cgcloud__externalid__c, pa.name, pa.cgcloud__name_2__c, pa.billingstreet, pa.billingcity, pa.billingstate, pa.billingpostalcode, pa.billingcountry,
  shippingstreet, pa.shippingcity, pa.shippingstate, pa.shippingpostalcode, pa.shippingcountry, pa.phone, pa.website, pa.ownerid, pa.cgcloud__account_email__c,
  EINId__c, pa.nationalid__c, pa.stateregistration__c, pa.MunicipalRegistration__c, pa.customerstatus__c, pa.type, pa.servicepreference__c, 
  case
    when k.KNKLI = k.kunnr then ''
    else ltrim(k.KNKLI, '0')
  end as CreditAccount__c, 
  pa.recordstamp, 
  case
    when coalesce(w.ExternalId__c, '') <> '' then 'Warehouse'
    else 'Cliente'
  end as RecordType, 
  case
    when coalesce(w.ExternalId__c, '') <> '' then 'Warehouse'
    else 'Cliente'
  end as cgcloud__Account_Template__c
FROM 
  postgres_raw.account pa
join
  `sap_raw.knkk` k
  on ltrim(k.kunnr, '0') = pa.cgcloud__externalid__c
left join w_warehouse w
  on w.ExternalId__c = pa.cgcloud__externalid__c
WHERE 
  pa.recordstamp >= date_sub(current_timestamp, interval 10000 minute) 
limit 5000
);

create or replace view prj-dados-prd-447818.ds_view_trusted.vw_cgcloud_product2_hierarquia_base as (
WITH w_materiais as
	( 
	  SELECT mara.matnr, makt.maktx, mara.mtart, mara.matkl
		FROM `sap_raw.mara` AS mara
			JOIN `sap_raw.makt` AS makt ON makt.matnr = mara.matnr
							 AND makt.spras = 'P'
	   WHERE mara.mtart IN ('FERT', 'ZLIC')
		 AND mara.matkl NOT IN ('LP001','')
		 AND coalesce(mara.mstae, '') = ''
		 AND coalesce(mara.mstav, '') = ''
	   ORDER BY maktx 
	  ),
		w_cabn as (
			SELECT 
				atinn, atnam
			FROM `prj-dados-prd-447818.sap_raw.cabn` 
				where 
					atinn IN ('0000000290','0000000072','0000000073','0000000122','0000000182','0000000078')			
		),
	  w_ausp as 
	  (
		SELECT ausp.atinn, ausp.objek as matnr, ausp.atwrt, cawnt.atwtb, cabn.atnam
	      FROM `sap_raw.ausp` AS ausp
			   JOIN `sap_raw.cawn`  AS cawn  ON cawn.atinn = ausp.atinn 
				                  AND cawn.atwrt = ausp.atwrt
			   JOIN `sap_raw.cawnt` AS cawnt ON cawnt.atinn = cawn.atinn 
				   		          AND cawnt.atzhl = cawn.atzhl
			   JOIN w_cabn AS cabn ON cabn.atinn = ausp.atinn

		 WHERE 
		 	--ausp.atinn IN ('0000000290','0000000072','0000000073','0000000122','0000000182','0000000078')
		  -- AND 
			  ausp.klart  = '001' 
		   AND cawnt.spras = 'P'		   
      ),
	  w_mvke as
	  ( 
		SELECT mvke.matnr, mvke.versg,    
			   case			
				 when tvsmt.bezei20 = 'Outros' then 
				 	'OTC'
				 else 
				 	tvsmt.bezei20
				 end as grupo
		  FROM `sap_raw.mvke` AS mvke		 
		       JOIN `sap_raw.tvsmt` AS tvsmt ON tvsmt.mandt = mvke.mandt
			                      AND tvsmt.spras = 'P'
			                      AND tvsmt.stgma = mvke.versg
	     WHERE mvke.vkorg = '0050' 
           AND mvke.vtweg = '10'
       )		   
SELECT res.*,
		case
			when res.hospitalar = 'SIM' then 
				'Hospitalar'    
			when res.mtart = 'ZLIC' then 
				'Licenciados - Revenda'
			when res.propaganda = 'CLONE' then 
				'Similar – Marca Prati'
			when res.setor_produtivo = 'NUTRACÊUTICOS' then
                'Nutracêuticos'			
			when res.controlado = 'SIM' then 
				'Controlado'
			when COALESCE(res.grupo,'') = '' or res.grupo = 'Similar' or res.grupo = 'Notificação Simplif.' or res.grupo = 'A DEFINIR' or res.grupo = 'Fitoterapicos' then
				'Outros'			
			else 
				res.grupo
		end as grupo_novo
 
FROM (  
		SELECT 	mat.*, 
				COALESCE(prop.atwrt,'NAO') AS propaganda, 
				COALESCE(classe.atwtb, 'A DEFINIR') AS classe_terapeutica, 
				COALESCE(princ.atwtb, 'A DEFINIR') AS principio_ativo,
				COALESCE(setor.atwtb, 'A DEFINIR') AS setor_produtivo,
				CASE 
				  when portaria.atwrt = '' or portaria.atwrt = 'ND' then 
					'NAO'
				  else 
					'SIM'
				end as controlado,
				COALESCE(vd_proib.atwtb, 'NAO') AS hospitalar,
				mvke.grupo
		  FROM w_materiais AS mat
 
			   LEFT JOIN w_ausp AS prop     ON prop.atnam = 'ZPROPAGANDA_MEDICA'--'0000000290'
										   AND prop.matnr = mat.matnr
			   LEFT JOIN w_ausp AS classe   ON classe.atnam = 'CLASSE_TERAPEUTICA'--'0000000072'
										   AND classe.matnr = mat.matnr									   
 
			   LEFT JOIN w_ausp AS princ    ON princ.atnam = 'PRINCIPIO_ATIVO'--'0000000073' 
										   AND princ.matnr = mat.matnr								
 
			   LEFT JOIN w_ausp AS setor    ON setor.atnam = 'ZSETOR_PRODUTIVO'--'0000000122'
										   AND setor.matnr = mat.matnr								
 
			   LEFT JOIN w_ausp AS portaria ON portaria.atnam = 'ZPORTARIA'--'0000000182'
										   AND portaria.matnr = mat.matnr	
			   LEFT JOIN w_ausp AS vd_proib ON vd_proib.atnam = 'VENDA_PROIBIDA'--'0000000078'
										   AND vd_proib.matnr = mat.matnr									   
			   LEFT JOIN w_mvke AS mvke     ON mvke.matnr = mat.matnr									   								   		   
	) AS res
);

create or replace view prj-dados-prd-447818.ds_view_trusted.w_product2	as (
with
  w_recordtype as 
  (
    select id, ambiente
    from `ds_trusted.sf_recordtype`
    where name = 'Product' and SobjectType = 'Product2'     --and ambiente = 'QAS'
  ),
  w_cgcloud_template as 
  (
    select id, ambiente
    from `ds_trusted.sf_recordtype`
    where name = 'Product' and SobjectType = 'cgcloud__Product_Template__c' --and ambiente = 'QAS'
  ),
  w_id as (
      select rc.id as rc_id, tp.id as tp_id, rc.ambiente
      from w_recordtype as rc
      join w_cgcloud_template as tp on rc.ambiente = tp.ambiente
  )
SELECT
  distinct 
  ltrim(mara.matnr, '0') as ProductCode,
  ltrim(mara.matnr, '0') as cgcloud__Consumer_Goods_Product_Code__c,   
  ltrim(mara.matnr, '0') as cgcloud__Product_Short_Code__c,
  ltrim(mara.matnr, '0') as cgcloud__Consumer_Goods_External_Product_Id__c,
  makt.maktx as cgcloud__Short_Description_Language_1__c,
  true as IsActive,   
  '4' as cgcloud__State__c,
  mara.ean11 as cgcloud__GTIN__c, 
  makt.maktx as Name, 
  mara.mhdhb as cgcloud__Pack_Size__c,
  makt.maktx as cgcloud__Description_1_Language_1__c,  
  'Product' as cgcloud__Product_Level__c,
  
  FORMAT_DATE("%Y-%m-%d",current_date ) as cgcloud__Delivery_Valid_From__c,
  '2099-12-31' as cgcloud__Delivery_Valid_Thru__c,     
 
  FORMAT_DATE("%Y-%m-%d",current_date ) as cgcloud__Field_Valid_From__c,
  '2099-12-31' as cgcloud__Field_Valid_Thru__c,
  
  FORMAT_DATE("%Y-%m-%d",current_date ) as cgcloud__KAM_Valid_From__c,
  '2099-12-31' as cgcloud__KAM_Valid_Thru__c,
  
  FORMAT_DATE("%Y-%m-%d",current_date ) as cgcloud__New_Item_Valid_From__c,
  '2099-12-31' as cgcloud__New_Item_Valid_Thru__c, 
  id.rc_id as RecordTypeId, 
  id.tp_id as cgcloud__Product_Template__c, 
  '0001' as cgcloud__Sales_Org__c, 
  id.ambiente
FROM 
  sap_raw.mara AS mara

JOIN sap_raw.makt AS makt
  ON makt.mandt = mara.mandt
  AND makt.matnr = mara.matnr
  AND makt.spras = 'P'

join sap_raw.marm MAM
  on mara.matnr = MAM.matnr 
  AND mara.mtart in ('FERT', 'ZLIC')
 --AND MAM.meinh = 'CX'    
 --AND MAM.umren = 1
	
join sap_raw.marc mc
  on mc.matnr = mara.matnr 
--  and mc.werks = '3000'

cross join 
  w_id as id
	
WHERE LEFT(mara.matnr,6) = '000000'
  --AND mara.matnr NOT IN ('CFOP6603','LAVH')
  --and makt.maktx  like 'PARACETAMOL%'
ORDER BY ProductCode

-- ambiente de qas sf  tem limitação de espaço, integração é limitada.
);

create or replace view prj-dados-prd-447818.ds_view_trusted.vw_customer_credit_base as (
WITH
  w_knkk AS 
  (
     SELECT A.KKBER, A.KUNNR, A.KLIMK, A.SAUFT, A.SKFOR, A.SSOBL, A.KNKLI, A.DTREV, A.NXTRV, A.CTLPC
       FROM `sap_raw.knkk` AS A
      WHERE A.KKBER = '0050' 
  ),
  
  w_s066 AS 
  (  SELECT A.KKBER, A.KNKLI, SUM(A.OEIKW) AS OEIKW_SUM
       FROM `sap_raw.s066` AS A
            JOIN w_knkk AS B ON B.KUNNR = A.KNKLI
                            AND B.KKBER = A.KKBER
      GROUP BY A.KKBER, A.KNKLI
  ),
  
  w_s067 AS 
  (  SELECT A.KKBER, A.KNKLI, SUM(A.OLIKW) AS OLIKW_SUM, SUM(A.OFAKW) AS OFAKW_SUM
       FROM `sap_raw.s067` AS A
            JOIN w_knkk AS B ON B.KUNNR = A.KNKLI
                            AND B.KKBER = A.KKBER
      GROUP BY A.KKBER, A.KNKLI
  ),
  
  w_vbak AS  	
  ( SELECT RES.KUNNR, SUM(QUANTIDADE_PENDENTE * PRECO_UNITARIO) AS VALOR_PENDENTE_ORDEM
      FROM (  
	    SELECT A.KUNNR, A.VBELN, 
		   ( C.KWMENG - C.KLMENG ) AS QUANTIDADE_PENDENTE, 
       ( ( C.MWSBP + C.NETWR ) / C.KWMENG ) AS PRECO_UNITARIO
	      FROM `sap_raw.vbak` AS A
		    JOIN `sap_raw.vbap`   AS C ON C.VBELN = A.VBELN 
				    AND C.PSTYV = 'ZBN'
				    AND C.ABGRU = ''
	     WHERE A.KUNNR IN (SELECT kunnr FROM w_knkk )
	       AND A.AUART = 'YBOR' 
	       AND A.VKORG IN ('0030','0050') 
	       AND A.LIFSK NOT IN ('','02')
	   ) AS RES
      GROUP BY RES.KUNNR
  ), 
  w_fim as (     
    SELECT  A.CTLPC AS Classe_de_risco__c,
            A.KUNNR AS cgcloud__ExternalId__c,
            cast(KLIMK AS FLOAT64) AS Limite_de_credito__c,
            A.KNKLI AS Conta_credito__c, 
            --A.DTREV AS DATA_REVISAO,
            --A.NXTRV AS DATA_PROXIMA_REVISAO,
            A.CTLPC AS CLASSE_RISCO,
            cast(
              ( COALESCE(A.SKFOR,0) + 
                    COALESCE(A.SSOBL,0) +  
                    COALESCE(B.OEIKW_SUM,0) +
                    COALESCE(C.OFAKW_SUM,0) +                 
                    CASE WHEN COALESCE(C.OLIKW_SUM,0) < 0 THEN 0 ELSE COALESCE(C.OLIKW_SUM,0) END +                 
                    COALESCE(D.VALOR_PENDENTE_ORDEM,0)                 
              )  AS FLOAT64) AS Compromisso_total__c

                  
      FROM w_knkk AS A
          LEFT JOIN w_s066 AS B ON B.KKBER = A.KKBER
                                AND B.KNKLI = A.KUNNR 
          LEFT JOIN w_s067 AS C ON C.KKBER = A.KKBER
                                AND C.KNKLI = A.KUNNR                        
          LEFT JOIN w_vbak AS D ON D.KUNNR = A.KUNNR
  )          
select
  *, 
  CAST(CASE
    WHEN Limite_de_credito__c > Compromisso_total__c THEN (Limite_de_credito__c - Compromisso_total__c) 
    else 0
  END as FLOAT64) as Credito_disponivel__c
from 
  w_fim
  );

create or replace view prj-dados-prd-447818.ds_view_trusted.vw_cgcloud__Account_Trade_Org_Hierarchy__c	as (
select 
  cgcloud__Child_Account__c, 
  -- gambi para QAS
  case 
    when cgcloud__Child_Account__c in ('146556', '260965', '146808', '147237', '145969', '146923', '146597', '146388', '163371') then 'R11'
    when cgcloud__Child_Account__c in ('146368', '146409', '146382', '146619', '146321', '146142', '145875', '146818', '147014') then 'R485'
    else cgcloud__Parent_Account__c
  end as cgcloud__Parent_Account__c, 
  cgcloud__Valid_From__c, 
  cgcloud__Valid_Thru__c, ExternalId__c, 

from 
  prj-dados-prd-447818.postgres_raw.account_trade_org_hierarchy
where
  --  SOMENTE PARA VALIDAR QAS
  cgcloud__Child_Account__c
  in 
  (
    SELECT 
      r.cgcloud__Child_Account__c
    FROM 
      `postgres_raw.account_trade_org_hierarchy` r
    join
      `prj-dados-prd-447818.postgres_raw.account` c 
      on c.cgcloud__ExternalId__c = r.cgcloud__Child_Account__c
  )
  and cgcloud__Parent_Account__c in ('R11', 'R485')
);

create or replace view prj-dados-prd-447818.ds_view_trusted.vw_cgcloud_product2_hierarquia	as (
select 
  distinct
  grupo_novo as Name, '012as000000BxlrAAC' as RecordTypeId, 'a3788000000uWRqAAM' as cgcloud__Product_Template__c,
  grupo_novo as cgcloud__Description_1_Language_1__c,
  grupo_novo as ExternalId,
  grupo_novo as ProductCode,
  grupo_novo as cgcloud__Consumer_Goods_External_Product_Id__c,
  '' as cgcloud__category__c,
  'Category' as cgcloud__Product_Level__c, 	  
  'grupo' as tipo
FROM 
  `prj-dados-prd-447818.ds_view_trusted.vw_cgcloud_product2_hierarquia_base` 
where
  grupo_novo in ('Genérico', 'OTC')
union all
select 
  distinct
  classe_terapeutica as Name, '012as000000BxlrAAC' as RecordTypeId, 'a3788000000uWRrAAM' as cgcloud__Product_Template__c,
  classe_terapeutica as cgcloud__Description_1_Language_1__c,
  classe_terapeutica as ExternalId,
  classe_terapeutica as ProductCode,
  classe_terapeutica as cgcloud__Consumer_Goods_External_Product_Id__c,
  grupo_novo as cgcloud__category__c, 
  'SubCategory' as cgcloud__Product_Level__c, 	    
  'classe' as tipo
FROM 
  `prj-dados-prd-447818.ds_view_trusted.vw_cgcloud_product2_hierarquia_base` 
where
  grupo_novo in ('Genérico', 'OTC')  
union all
select 
  distinct
  principio_ativo as Name, '012as000000BxlrAAC' as RecordTypeId, 
  'a3788000000uWRsAAM' as cgcloud__Product_Template__c,
  principio_ativo as cgcloud__Description_1_Language_1__c,
  principio_ativo as ExternalId,
  principio_ativo as ProductCode,
  principio_ativo as cgcloud__Consumer_Goods_External_Product_Id__c,
  classe_terapeutica as cgcloud__category__c, 
  'Brand' as cgcloud__Product_Level__c, 	  
  'principio' as tipo
FROM 
  `prj-dados-prd-447818.ds_view_trusted.vw_cgcloud_product2_hierarquia_base` 
where
  grupo_novo in ('Genérico', 'OTC')
);

create or replace view prj-dados-prd-447818.ds_view_trusted.vw_customer_credit	as (
with 
  w_conta_credito as (
  select 
    Conta_credito__c, 
    cast( sum(Limite_de_credito__c) as FLOAT64) as Limite_consolidado__c, 
    cast(sum(Compromisso_total__c)  as FLOAT64) as Compromisso_consolidado__c, 
    cast(sum(Credito_disponivel__c)  as FLOAT64) as Credito_disponivel_consolidado__c
  from `ds_view_trusted.vw_customer_credit_base`
  group by Conta_credito__c 
)
SELECT
  ltrim(b.cgcloud__ExternalId__c, '0') as cgcloud__ExternalId__c,
  case
    when ltrim(b.Conta_credito__c, '0') <> ltrim(b.cgcloud__ExternalId__c, '0') then ltrim(b.Conta_credito__c, '0') 
    else ''
  end as Conta_credito__c, 
  b.Limite_de_credito__c,
  b.Compromisso_total__c,
  b.Credito_disponivel__c,
  c.Limite_consolidado__c,
  c.Compromisso_consolidado__c,
  c.Credito_disponivel_consolidado__c,
  b.Classe_de_risco__c
FROM 
  `ds_view_trusted.vw_customer_credit_base` b
JOIN 
  w_conta_credito c
  ON c.Conta_credito__c = b.Conta_credito__c
  );

create or replace view prj-dados-prd-447818.ds_view_trusted.vw_cgcloud__org_unit_hierarchy__c as (
select 
  "TESTE 001 AEO" as cgcloud__Parent_Org_Unit__c, 
  "TESTE 002 AEO" as cgcloud__Child_Org_Unit__c, 
  "2025-03-31" as cgcloud__Valid_From__c, 
  "2099-12-31" as cgcloud__Valid_Thru__c,
  "SalesRep" as cgcloud__Child_Org_Level__c,
  "Sales" as  cgcloud__Child_Org_Type__c,
  "TESTE 001 AEO xxx" as cgcloud__Description__c,
  "SalesRep" as cgcloud__Parent_Org_Level__c,
  "Sales" as cgcloud__Parent_Org_Type__c,
  "TESTE 001 AEO"||"TESTE 002 AEO" as cgcloud__externalId__c
);



create or replace view prj-dados-prd-447818.ds_view_trusted.vw_product2 as (
with
  w_recordtype as 
  (
    select id, ambiente
    from `ds_trusted.sf_recordtype`
    where name = 'Product' and SobjectType = 'Product2'     --and ambiente = 'QAS'
  ),
  w_cgcloud_template as 
  (
    select id, ambiente
    from `ds_trusted.sf_recordtype`
    where name = 'Product' and SobjectType = 'cgcloud__Product_Template__c' --and ambiente = 'QAS'
  ),
  w_id as (
      select rc.id as rc_id, tp.id as tp_id, rc.ambiente
      from w_recordtype as rc
      join w_cgcloud_template as tp on rc.ambiente = tp.ambiente
  )
SELECT
  distinct 
  ltrim(mara.matnr, '0') as ProductCode,
  ltrim(mara.matnr, '0') as cgcloud__Consumer_Goods_Product_Code__c,   
  ltrim(mara.matnr, '0') as cgcloud__Product_Short_Code__c,
  ltrim(mara.matnr, '0') as cgcloud__Consumer_Goods_External_Product_Id__c,
  makt.maktx as cgcloud__Short_Description_Language_1__c,
  true as IsActive,   
  '4' as cgcloud__State__c,
  mara.ean11 as cgcloud__GTIN__c, 
  makt.maktx as Name, 
  mara.mhdhb as cgcloud__Pack_Size__c,
  makt.maktx as cgcloud__Description_1_Language_1__c,  
  'Product' as cgcloud__Product_Level__c,
  
  FORMAT_DATE("%Y-%m-%d",current_date ) as cgcloud__Delivery_Valid_From__c,
  '2099-12-31' as cgcloud__Delivery_Valid_Thru__c,     

  FORMAT_DATE("%Y-%m-%d",current_date ) as cgcloud__Field_Valid_From__c,
  '2099-12-31' as cgcloud__Field_Valid_Thru__c,
  
  FORMAT_DATE("%Y-%m-%d",current_date ) as cgcloud__KAM_Valid_From__c,
  '2099-12-31' as cgcloud__KAM_Valid_Thru__c,
  
  FORMAT_DATE("%Y-%m-%d",current_date ) as cgcloud__New_Item_Valid_From__c,
  '2099-12-31' as cgcloud__New_Item_Valid_Thru__c, 
  id.rc_id as RecordTypeId, 
  id.tp_id as cgcloud__Product_Template__c, 
  '0001' as cgcloud__Sales_Org__c, 
  id.ambiente
FROM 
  sap_raw.mara AS mara

JOIN sap_raw.makt AS makt
  ON makt.mandt = mara.mandt
  AND makt.matnr = mara.matnr
  AND makt.spras = 'P'

join sap_raw.marm MAM
  on mara.matnr = MAM.matnr 
  AND mara.mtart in ('FERT', 'ZLIC')
--AND MAM.meinh = 'CX'    
--AND MAM.umren = 1
  
join sap_raw.marc mc
  on mc.matnr = mara.matnr 
--  and mc.werks = '3000'

cross join 
  w_id as id
  
WHERE LEFT(mara.matnr,6) = '000000'
  --AND mara.matnr NOT IN ('CFOP6603','LAVH')
  --and makt.maktx  like 'PARACETAMOL%'
ORDER BY ProductCode
-- ambiente de qas sf  tem limitação de espaço, integração é limitada.
);
