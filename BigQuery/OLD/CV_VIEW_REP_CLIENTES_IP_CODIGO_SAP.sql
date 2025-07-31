SELECT 
	DISTINCT 	
	CLI.CODIGO, 
	CLI.CLI_RZS, CLI.CLI_CGC, CLI.CLI_END, '' as CLI_NUM, CLI.CLI_BAI, 
	CLI.CLI_CEP, CLI.CLI_EST, 
	CLI.CLI_CID, CLI.CLI_TEL, CLI.CLI_EMAIL, CLI.CLI_LIMITE,
	CLI.ALVARANUMERO, CLI.ALVARADATA, CLI.ALVARANUMEROSANIT, CLI.ALVARADATASANIT, 
	CLI.RESPTECNICONOME, CLI.RESPTECNICOCRF, CLI.DATACRF, CLI.ALVARANUMEROSIVISA,
	CLI.ALVARADATASIVISA, CLI.CONTROLADO, CLI.NUMERO_AE, CLI.CAIXA_FECHADA,
	CLI.BLOQUEIO, CLI.GRUPO_CONTAS, CLI.CROSSDOCKING, CLI.CONTA_MATRIZ,
	CLI.BU, CLI.ASSOCIATIVISMO1, CLI.ASSOCIATIVISMO2, 
	'' as NOME_ASS1, '' as NOME_ASS2,	
	CLI.COD_REDE, CLI.NOME_REDE,
    case
    	when coalesce(bloq_credito.codigo, '') <> '' then 'Bloq. Crédito'
    	else ''
    end as BLOQ_FINANCEIRO,
    case
    	when coalesce(pos.kunnr, '') <> '' then 'S'
    	else 'N'
    end as POSITIVADO, 
    case
    	when coalesce(CLI.BLOQUEIO, '') = '' then 'S'
    	else 'N'
    end as BLOQ_DOCUMENTO,
    CLI.CLI_LIMITE AS CREDITO_TOTAL, 
	CLI.CLI_LIMITE_CONSUMIDO AS CREDITO_CONSUMIDO, 
	27 AS MIX_PLANEJADO, coalesce(MIX.MIX_REALIZADO,0) as MIX_REALIZADO,
	0 AS OPORTUNIDADE, 0 AS OPORTUNIDADE_REALIZADO, 
	case
		when coalesce(dup.qde, 0) >= 1 then 'S'
		else 'N'
	end as dup_atraso 
FROM 
	"_SYS_BIC"."CimedTech/CV_VIEW_CADASTRO_CLIENTE" CLI
left join
	(
	select kunnr as codigo
	from "_SYS_BIC"."CimedTech/CV_VIEW_CLIENTES_BLQOUEIO"
	union all
	select knkli as codigo
	from "_SYS_BIC"."CimedTech/CV_VIEW_CLIENTES_BLQOUEIO"
	) as bloq_credito	
	on bloq_credito.codigo = CLI.CODIGO
LEFT JOIN
	(
	select 
		distinct kunnr
	from
		vbak
	where
		-- mes atual a partir do dia 1º	
		erdat >= extract(year from current_date)||TO_VARCHAR(extract(month from current_date),'00')||'01'
	) as pos	
	on pos.kunnr = cli.codigo
LEFT JOIN
	(
	select
		"DVENDA"."CLIENTE", 
		CAST(
	  		CASE 
	     		WHEN "DVENDA"."COCKPIT" = 'Faturamento' AND SUM("DVENDA"."VALOR_NF") > 0 
	     			THEN COUNT(DISTINCT "DVENDA"."CHAVE_MIX") / COUNT(DISTINCT "DVENDA"."CLIENTE")
	     		ELSE
		       		0
	  		END AS INTEGER) AS "MIX_REALIZADO"	
	  FROM 
	  	"_SYS_BIC"."VISAO_INDICADORES/CV_DASH_MV_VISAO" AS "DVENDA"   
	  WHERE 
	  	"DVENDA"."COCKPIT"          IN ('Faturamento','Devolução')    
	    --AND LEFT("DVENDA"."DT_FATUR",6) = LEFT(REPLACE(TO_CHAR(TO_DATE(CURRENT_DATE)),'-',''),6)
	    -- AND "DVENDA"."DT_FATUR" BETWEEN '20210201' AND '20210228'    
		AND substring(DT_FATUR, 1,6) = CAST(YEAR(ADD_DAYS(CURRENT_DATE, -180)) AS VARCHAR)||to_varchar(MONTH(ADD_DAYS(CURRENT_DATE, -180)), '00' )
	    AND "DVENDA"."VENDEDOR" <> '?'
	    AND COALESCE("DVENDA"."VENDEDOR", '') <> ''
	    AND "DVENDA"."VENDEDOR" NOT LIKE 'H%'
		and "DVENDA"."CLIENTE" = :IP_CODIGO_SAP
	  GROUP BY     
	    "DVENDA"."CLIENTE", "DVENDA"."COCKPIT"		
	) MIX	
	ON MIX.CLIENTE = CLI.CODIGO
LEFT JOIN
	(	
	-- qde de titulos em atraso	
	SELECT 
		CLIENTE, COUNT(*) as qde
	FROM 
		"_SYS_BIC"."CimedTech/CV_VIEW_PARTIDAS_ABERTO_IP"
		(PLACEHOLDER."$$IP_CLIENTE$$"=>:IP_CODIGO_SAP )	
	where
		vencimento < current_date	
	GROUP BY
		CLIENTE
	 ) as dup
	 on dup.cliente = CLI.CODIGO
WHERE
	CLI.CODIGO = :IP_CODIGO_SAP
ORDER BY 
	CLI.CLI_RZS
;	

END /********* End Procedure Script ************/