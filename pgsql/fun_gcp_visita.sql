-- DROP FUNCTION public.fun_gcp_visita();

CREATE OR REPLACE FUNCTION public.fun_gcp_visita()
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$
DECLARE
	R_CON      record;
	R_AGENDA   record;
	R_NEW      record;
	R_OLD      record;
	R_TELEV    record;
	V_EXISTS   boolean;  	
	V_RET      boolean := TRUE;
BEGIN
	BEGIN	
		SELECT * INTO R_CON FROM fun_gcp_ambiente();

		FOR R_AGENDA IN (  SELECT *
				     FROM dblink(' hostaddr='|| R_CON.out_host_ps ||' dbname='|| R_CON.out_dbname_ps ||' user='|| R_CON.out_user_ps ||' password='|| R_CON.out_password_ps ||' ', 
						 ' SELECT a.age_codigo,    ' ||
						 '        a.age_datacomp,  ' ||
						 '        coalesce(f.cod_telev, cast(a.age_usuario as integer)) as cod_telev, ' ||
						 '        a.age_status,    ' ||
						 '        TO_CHAR(cast(age_datacomp ||'' ''|| age_horacomp ||''-03'' as character varying)::timestamptz,  ''YYYY-MM-DD"T"HH24:MI:SS.MS""OF'') as data_compromisso, '||					 
						 '	  TO_CHAR(CAST(a.age_datafinalizacao AS CHARACTER VARYING)::timestamptz,  ''YYYY-MM-DD"T"HH24:MI:SS.MS""OF'') as data_finalizacao, '||
						 '        a.age_assunto,   ' ||									 
						 '        a.age_texto,     ' ||									 									 
						 '        a.age_atccodigo, ' ||
						 '        b.atc_descricao, ' ||
						 '        a.age_codobspadrao,     ' ||
						 '        e.ds_obs,        ' || 
						 '        c.cli_codigo,    ' ||
						 '        c.cli_razsocial  ' ||
						 '   FROM agenda as a ' || 
						 '  	  left join agenda_tipo_compromisso as b on (b.atc_codigo = a.age_atccodigo)  ' || 
						 '	  left join cliente                 as c on (c.cli_cnpj   = a.age_cli_cnpj) ' || 
						 '	  left join agenda_compromisso      as d on (d.cod_agenda = a.age_codigo) ' || 
						 '	  left join observacaopadrao        as e on (e.cd_obs     = a.age_codobspadrao) ' ||  
						 '	  left join agenda_compromisso      as f on (f.cod_agenda = coalesce(a.age_codigo_pai, a.age_codigo)) ' || 
						 '  WHERE a.age_datacomp = '''|| to_char(current_date,'YYYYMMDD') ||''' '||
						 '    and a.age_atccodigo in (1,2,3) '||
						 '  order by age_status, data_compromisso, age_codigo ' ) as age ( age_codigo integer, 
														    age_datacomp character varying,
														    cod_telev integer,
														    age_status character varying,
														    data_compromisso character varying,
														    data_finalizacao character varying,
														    age_assunto character varying,
														    age_texto text,													
														    age_atccodigo integer,  
														    atc_descricao character varying, 
														    age_codobspadrao integer,
														    ds_obs character varying, 
														    cli_codigo character varying,  
														    cli_razsocial character varying ) ) LOOP	

			-- verifica se agenda é de algum usuário do salesforce
			SELECT * 
			  INTO R_TELEV
			  FROM public.user
			 WHERE legacyuser__c = R_AGENDA.cod_telev;

			IF NOT FOUND THEN
				CONTINUE;
			END IF;
														    
			IF COALESCE(R_AGENDA.cod_telev,0) > 0 THEN		

				-- registro atual
				SELECT * 
				  INTO R_OLD 
				  FROM public.visit 
				 WHERE schedulecode__c = R_AGENDA.age_codigo;	

				-- registro já finalizado
				IF trim(R_OLD.status) = 'Completed' THEN
					CONTINUE;
				END IF; 			 

				IF NOT FOUND THEN
					V_EXISTS := FALSE;

					-- registro já encerrado na agenda
					IF COALESCE(R_AGENDA.age_status,'A') = 'E' THEN
						CONTINUE;
					END IF;						
				ELSE
					V_EXISTS := TRUE;	
				END IF;
			
				R_NEW := R_OLD;

				-- formata registro 
				R_NEW.schedulecode__c         := R_AGENDA.age_codigo;
				R_NEW.accountid               := R_AGENDA.cli_codigo; 
				R_NEW.cgcloud__accountable__c := R_TELEV.userexternalid__c;
				R_NEW.cgcloud__responsible__c := R_TELEV.userexternalid__c;
							
				IF COALESCE(R_AGENDA.age_status,'A') = 'A' THEN
					R_NEW.status                := 'Planned';
					R_NEW.actualvisitendtime    := '';				
					R_NEW.plannedvisitstarttime := R_AGENDA.data_compromisso;
				ELSE
					R_NEW.status                := 'Completed';
					R_NEW.actualvisitendtime    := R_AGENDA.data_finalizacao;
				END IF;
				
				R_NEW.visitpriority	      := 'Médio';
				R_NEW.instructiondescription  := COALESCE(R_AGENDA.age_assunto,'');

				IF trim(COALESCE(R_AGENDA.age_texto,'')) <> '' THEN
					R_NEW.instructiondescription := R_NEW.instructiondescription || ' - ' || COALESCE(R_AGENDA.age_texto,'');
				END IF;
				
				R_NEW.placeid                 := '13088000003rVgfAAE';
				R_NEW.standardobservation__c  := R_AGENDA.age_codobspadrao;
				
				IF V_EXISTS THEN
					IF ROW(R_NEW) IS DISTINCT FROM ROW(R_OLD) THEN

						R_NEW.updatedate := current_timestamp;
					
						-- atualiza
						UPDATE 	public.visit 
						   SET 	accountid               = R_NEW.accountid,
							cgcloud__accountable__c = R_NEW.cgcloud__accountable__c,
							cgcloud__responsible__c = R_NEW.cgcloud__responsible__c, 
							plannedvisitstarttime   = R_NEW.plannedvisitstarttime,
							actualvisitendtime      = R_NEW.actualvisitendtime,
							status                  = R_NEW.status, 
							visitpriority           = R_NEW.visitpriority,
							instructiondescription  = R_NEW.instructiondescription,
							placeid                 = R_NEW.placeid,
							standardobservation__c  = R_NEW.standardobservation__c,
							updatedate              = R_NEW.updatedate					       		
						 WHERE  schedulecode__c         = R_NEW.schedulecode__c;
					END IF;
				ELSE
					R_NEW.updatedate := current_timestamp;			

					-- insere
					INSERT INTO public.visit VALUES ( R_NEW.schedulecode__c,
									  R_NEW.accountid,
									  R_NEW.cgcloud__accountable__c,
									  R_NEW.cgcloud__responsible__c, 
									  R_NEW.plannedvisitstarttime,
									  R_NEW.actualvisitendtime,
									  R_NEW.status, 
									  R_NEW.visitpriority,
									  R_NEW.instructiondescription,
									  R_NEW.placeid,
									  R_NEW.standardobservation__c,
									  R_NEW.updatedate );   
				END IF;
			END IF;
		END LOOP;
	EXCEPTION 
		WHEN OTHERS THEN
		V_RET := false;
	END; 
		
	RETURN V_RET;
end
$function$
;
