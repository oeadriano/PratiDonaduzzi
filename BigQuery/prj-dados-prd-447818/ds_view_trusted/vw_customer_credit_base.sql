CREATE VIEW `prj-dados-prd-447818.ds_view_trusted.vw_customer_credit_base`
AS WITH
  w_condition_stage as (
    SELECT distinct cgcloud__account__c, 'S' as tem_pn
    FROM `postgres_raw.pricing_condition_stage` 
    where coalesce(cgcloud__account__c, '') <> ''
      and cgcloud__key_type__c = 'KT-110' -- preço negociado do cliente
      and current_date between cgcloud__valid_from__c AND cgcloud__valid_thru__c 
  ), 
  w_kna1 as (
    select 
      KUNNR, -- codigo do cliente
      BRSCH, -- Industry
      KTOKD, --	AccountGroup__c
    from `sap_raw.kna1`
  ),
  w_knvv as (
    -- service tem é picklist no salesforce
    with w_service_team as (
      select '00' as cod, 'Ambos' as descricao union all -- 'Sujeito Desc.antesNF
      select '01' as cod, 'Ambos' as descricao union all -- 'Sujeito Desc.só naNF
      select '02' as cod, 'Institucional' as descricao union all -- 'Órgão Público
      select '03' as cod, 'Institucional' as descricao union all -- 'Distribuidor
      select '04' as cod, 'Institucional' as descricao union all -- 'Hospital Privado
      select '05' as cod, 'Key Account & Grandes Contas' as descricao union all -- 'Rede de Farmacia
      select '06' as cod, 'Televendas & Representantes' as descricao union all -- 'Farmacia Independent
      select '07' as cod, 'Ambos' as descricao union all -- 'Pessoa Física
      select '08' as cod, 'Ambos' as descricao union all -- 'Outros
      select '09' as cod, 'Ambos' as descricao union all -- 'Transportadoras
      select '10' as cod, 'Ambos' as descricao union all -- 'Manipulação
      select '11' as cod, 'Ambos' as descricao union all -- 'Farma + Manipula
      select '12' as cod, 'Ambos' as descricao union all -- 'Fármacos
      select '13' as cod, 'Ambos' as descricao union all -- 'Bazar
      select '14' as cod, 'Ambos' as descricao union all -- 'Gráfica
      select '15' as cod, 'Ambos' as descricao union all -- 'Industria
      select '16' as cod, 'Institucional' as descricao union all -- 'Distribuidor Hospita
      select '17' as cod, 'Ambos' as descricao union all -- 'Comércio
      select '18' as cod, 'Ambos' as descricao union all -- 'Distribuidor Farma
      select '19' as cod, 'Ambos' as descricao union all -- 'Logística Farma
      select '20' as cod, 'Ambos' as descricao union all -- 'Cliente Estratégico
      select '21' as cod, 'Key Account & Grandes Contas' as descricao union all -- 'Farmacia Popular
      select '22' as cod, 'Key Account & Grandes Contas' as descricao union all -- 'Grandes Contas Rede
      select '23' as cod, 'Key Account & Grandes Contas' as descricao union all -- 'Bandeiras/Outra Rede
      select '24' as cod, 'Televendas & Representantes' as descricao union all -- 'Farmacia Indepen PR
      select '25' as cod, 'Televendas & Representantes' as descricao union all -- 'Farmacia Indep Norte
      select '26' as cod, 'Televendas & Representantes' as descricao -- 'Farmacia Indep RJ
    )
    select 
      k.kunnr, 
      k.PLTYP, -- Tabela_Preco__c
      k.KDGRP, -- CustomerGroup__c
      k.BZIRK, --	SalesDistrict__c
      st.descricao as ServiceTeam__c
    from `sap_raw.knvv` k
    join w_service_team as st on st.cod = k.KDGRP
    where k.vtweg = '10' and k.VKORG = '0050'  
  ),
  w_knkk AS 
  (
     SELECT A.KKBER, A.KUNNR, A.KLIMK, A.SAUFT, A.SKFOR, A.SSOBL, A.KNKLI, A.DTREV, A.NXTRV, 
      coalesce(A.CTLPC, '') as CTLPC
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
            LTRIM(A.KUNNR, '0') AS cgcloud__ExternalId__c,
            ROUND( cast(KLIMK AS FLOAT64), 2) AS Limite_de_credito__c,
            LTRIM(A.KNKLI, '0') AS Conta_credito__c, 
            --A.DTREV AS DATA_REVISAO,
            --A.NXTRV AS DATA_PROXIMA_REVISAO,
            round(
              cast(
                ( COALESCE(A.SKFOR,0) + 
                    COALESCE(A.SSOBL,0) +  
                    COALESCE(B.OEIKW_SUM,0) +
                    COALESCE(C.OFAKW_SUM,0) +                 
                    CASE WHEN COALESCE(C.OLIKW_SUM,0) < 0 THEN 0 ELSE COALESCE(C.OLIKW_SUM,0) END +                 
                    COALESCE(D.VALOR_PENDENTE_ORDEM,0)                 
                ) AS FLOAT64)
              , 2) AS Compromisso_total__c, 
              coalesce(E.PLTYP, '') as Tabela_Preco__c, 
              coalesce(F.tem_pn, 'N') as Preco_Negociado__c, 
              coalesce(E.KDGRP, '') as CustomerGroup__c, 
              coalesce(E.BZIRK, '') as SalesDistrict__c,
              coalesce(G.BRSCH, '') as Industry,
              coalesce(G.KTOKD, '') as AccountGroup__c,
              coalesce(E.ServiceTeam__c, '') as ServiceTeam__c

      FROM w_knkk AS A
          LEFT JOIN w_s066 AS B ON B.KKBER = A.KKBER
                                AND B.KNKLI = A.KUNNR 
          LEFT JOIN w_s067 AS C ON C.KKBER = A.KKBER
                                AND C.KNKLI = A.KUNNR                        
          LEFT JOIN w_vbak AS D ON D.KUNNR = A.KUNNR          

          LEFT JOIN w_knvv AS E ON E.KUNNR = A.KUNNR          
          
          LEFT JOIN w_condition_stage F ON F.cgcloud__account__c = ltrim(A.KUNNR, '0')
          
          LEFT JOIN w_kna1 AS G ON G.KUNNR = A.KUNNR                    
  )          
select
  Classe_de_risco__c, cgcloud__ExternalId__c, Limite_de_credito__c, Conta_credito__c, 
  case
    when Compromisso_total__c < 0 then 0.0
    else Compromisso_total__c
  end as Compromisso_total__c
  , round(CAST(CASE
    WHEN Limite_de_credito__c > Compromisso_total__c THEN (Limite_de_credito__c - Compromisso_total__c) 
    else 0.0
  END as FLOAT64),2) as Credito_disponivel__c, 
  Tabela_Preco__c, 
  Preco_Negociado__c, 
  CustomerGroup__c, 
  SalesDistrict__c,
  Industry,
  AccountGroup__c, 
  ServiceTeam__c
from 
  w_fim
--where 
--  cgcloud__ExternalId__c in ('170188', '170187', '170189')      ;