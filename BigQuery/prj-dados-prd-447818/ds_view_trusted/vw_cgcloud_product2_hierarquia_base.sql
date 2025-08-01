CREATE VIEW `prj-dados-prd-447818.ds_view_trusted.vw_cgcloud_product2_hierarquia_base`
AS WITH w_materiais as
	( 
	  SELECT mara.matnr, makt.maktx, mara.mtart, mara.matkl, 
             mara.ean11, mara.mhdhb, mara.meins,
		      ( CASE WHEN coalesce(mara.mstae, '') <> '' OR coalesce(mara.mstav, '') <> '' THEN 'X' ELSE '' END ) AS bloqueado
		FROM `sap_raw.mara` AS mara
			JOIN `sap_raw.makt` AS makt ON makt.matnr = mara.matnr
							 AND makt.spras = 'P'
	   WHERE mara.mtart IN ('FERT', 'ZLIC')
		 AND mara.matkl NOT IN ('LP001','')
	   ORDER BY maktx 
	  ), 
		w_cabn as (
			SELECT atinn, atnam
			  FROM `sap_raw.cabn` 
			 WHERE atnam IN ('ZPROPAGANDA_MEDICA',
                             'CLASSE_TERAPEUTICA',
                             'PRINCIPIO_ATIVO',
                             'ZSETOR_PRODUTIVO',
                             'ZPORTARIA',
                             'VENDA_PROIBIDA',
                             'TARJA',
                             'REFERENCIA',
                             'FORMA_FARMACEUTICA',
                             'VIA_ADMINISTRACAO',
                             'USO_CONTINUO',
                             'ZDOSE',
                             'ZFARMAPOP',
                             'ZDATALANCAMENTO')			
		),
	  w_ausp as 
	  (
		SELECT ausp.atinn, ausp.objek as matnr, ausp.atwrt, cawnt.atwtb, cabn.atnam, ausp.atflv,
		       ROW_NUMBER() OVER(PARTITION BY objek, atnam) as nr_item
	      FROM `sap_raw.ausp` AS ausp
			   LEFT JOIN `sap_raw.cawn`  AS cawn  ON cawn.atinn = ausp.atinn 
				                   AND cawn.atwrt = ausp.atwrt
			   LEFT JOIN `sap_raw.cawnt` AS cawnt ON cawnt.atinn = cawn.atinn 
				   		                AND cawnt.atzhl = cawn.atzhl
                                        AND cawnt.spras = 'P'
			   JOIN w_cabn AS cabn ON cabn.atinn = ausp.atinn
		 WHERE ausp.klart  = '001' 		   		   
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
					'HOSPITALAR'    
			when res.mtart = 'ZLIC' then 
					'LICENCIADOS - REVENDA'
			when res.propaganda = 'CLONE' then 
					'SIMILAR - MARCA PRATI'
			when res.setor_produtivo = 'NUTRACÊUTICOS' then
        	        'NUTRACEUTICOS'			
			when res.controlado = 'SIM' then 
					'CONTROLADO'
			when COALESCE(res.grupo,'') = '' or res.grupo = 'Similar' or res.grupo = 'Notificação Simplif.' or res.grupo = 'A DEFINIR' 	or res.grupo = 'Fitoterapicos' then
					'OUTROS'			
			else 
					upper(res.grupo)
		end as grupo_novo
 
FROM (  
		SELECT  ltrim(mat.matnr, '0') as matnr,
                mat.maktx, 
                mat.mtart, 
                mat.matkl,
                mat.meins,
                mat.ean11, 
                mat.mhdhb,

				COALESCE(prop.atwrt,'NAO') AS propaganda, 
				CASE
					WHEN COALESCE(classe.atwtb, '') = '' THEN 'CT A DEFINIR'
					ELSE UPPER(classe.atwtb)
				END AS classe_terapeutica, 
				CASE
					WHEN COALESCE(princ.atwtb, '') = '' THEN 'PA A DEFINIR'
					ELSE UPPER(princ.atwtb)
				END AS principio_ativo, 
				CASE
					WHEN COALESCE(setor.atwtb, '') = '' THEN 'ST A DEFINIR'
					ELSE UPPER(setor.atwtb)
				END AS setor_produtivo,
				CASE 
				  when portaria.atwrt = '' or portaria.atwrt = 'ND' then 
					'NAO'
				  else 
					'SIM'
				end as controlado,
				
                COALESCE(proibida.atwtb, 'NAO') AS hospitalar,
                UPPER(COALESCE(tarja.atwtb, 'A DEFINIR')) AS tarja,
                UPPER(COALESCE(refer.atwtb, 'A DEFINIR')) AS referencia,
                UPPER(COALESCE(forma.atwtb, 'A DEFINIR')) AS forma_farmaceutica,
                UPPER(COALESCE(via.atwtb, 'A DEFINIR')) AS via_administracao,
								--AEO 190625 - ChronicUse__c é char(01)
                CASE
									WHEN UPPER(COALESCE(continuo.atwtb, 'NÃO')) = 'NÃO' THEN 'N'
									ELSE 'S'
								END AS uso_continuo,
                CAST(CAST(dose.atflv AS INT64) AS STRING) AS dose,
								--AEO 190625 - GovernmentSubsidyProgram__c é char(01)								
                CASE
									WHEN UPPER(COALESCE(farma.atwtb, 'NÃO')) = 'NÃO' THEN 'N'
									ELSE 'S'
								END AS farma_popular,
                PARSE_DATE('%Y%m%d', CAST(CAST(lanc.atflv AS INT64) AS STRING)) AS data_lancamento,

				mvke.grupo,
				mat.bloqueado
		  FROM w_materiais AS mat
 
			   LEFT JOIN w_ausp AS prop     ON prop.atnam = 'ZPROPAGANDA_MEDICA'
										   AND prop.matnr = mat.matnr

			   LEFT JOIN w_ausp AS classe   ON classe.atnam = 'CLASSE_TERAPEUTICA'
										   AND classe.matnr = mat.matnr									   

			   LEFT JOIN w_ausp AS princ    ON princ.atnam = 'PRINCIPIO_ATIVO'
										   AND princ.matnr = mat.matnr		
											 AND princ.nr_item = 1
 
 			   LEFT JOIN w_ausp AS setor    ON setor.atnam = 'ZSETOR_PRODUTIVO'
										   AND setor.matnr = mat.matnr								
 
			   LEFT JOIN w_ausp AS portaria ON portaria.atnam = 'ZPORTARIA'
										   AND portaria.matnr = mat.matnr	

			   LEFT JOIN w_ausp AS proibida ON proibida.atnam = 'VENDA_PROIBIDA'
										   AND proibida.matnr = mat.matnr	

			   LEFT JOIN w_ausp AS tarja    ON tarja.atnam = 'TARJA'
										   AND tarja.matnr = mat.matnr	                                          

			   LEFT JOIN w_ausp AS refer    ON refer.atnam = 'REFERENCIA'
										   AND refer.matnr = mat.matnr	

			   LEFT JOIN w_ausp AS forma    ON forma.atnam = 'FORMA_FARMACEUTICA'
										   AND forma.matnr = mat.matnr	

			   LEFT JOIN w_ausp AS via      ON via.atnam = 'VIA_ADMINISTRACAO'
										   AND via.matnr = mat.matnr	

			   LEFT JOIN w_ausp AS continuo ON continuo.atnam = 'USO_CONTINUO'
										   AND continuo.matnr = mat.matnr	

			   LEFT JOIN w_ausp AS dose     ON dose.atnam = 'ZDOSE'
										   AND dose.matnr = mat.matnr	                                           

			   LEFT JOIN w_ausp AS farma    ON farma.atnam = 'ZFARMAPOP'
										   AND farma.matnr = mat.matnr	                                           

			   LEFT JOIN w_ausp AS lanc     ON lanc.atnam = 'ZDATALANCAMENTO'
										   AND lanc.matnr = mat.matnr	                                           

			   LEFT JOIN w_mvke AS mvke     ON mvke.matnr = mat.matnr				
		  WHERE mat.bloqueado <> 'X'					   								   		   
	) AS res;