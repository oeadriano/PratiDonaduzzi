SELECT 
	DISTINCT 
	--LCLI.LIFNR, 
	CLI.LIFNR, 
	CLI.CODIGO, 
	CLI.CLI_RZS, 
	CLI.CLI_CGC, 
	CLI.CLI_END, 
	'' AS CLI_NUM, 
	CLI.CLI_BAI, 
	CLI_CEP, CLI_EST, 
	CLI.CLI_CID, 
	CLI.CLI_TEL, 
	CLI.CLI_EMAIL, 
	CLI.CLI_LIMITE, 
	CLI.ALVARANUMERO, 
	CLI.ALVARADATA, 
	CLI.ALVARANUMEROSANIT, 
	CLI.ALVARADATASANIT, 
	CLI.RESPTECNICONOME, 
	CLI.RESPTECNICOCRF, 
	CLI.DATACRF, 
	CLI.ALVARANUMEROSIVISA,
	CLI.ALVARADATASIVISA, 
	CLI.CONTROLADO, 
	CLI.NUMERO_AE, 
	CLI.CAIXA_FECHADA,
	CLI.BLOQUEIO, 
	CLI.GRUPO_CONTAS, 
	CLI.CROSSDOCKING, 
	CLI.CONTA_MATRIZ,
	CLI.BU, 
	CLI.ASSOCIATIVISMO1, 
	CLI.ASSOCIATIVISMO2, 
	'' as NOME_ASS1, '' as NOME_ASS2,	
	CLI.COD_REDE, 
	CLI.NOME_REDE,		  
    CASE WHEN coalesce(bloq_credito.codigo, '') <> '' then 'Bloq. Crédito' ELSE '' END AS BLOQ_FINANCEIRO,
    CASE WHEN coalesce(pos.kunnr, '') <> '' then 'S' ELSE 'N' END AS POSITIVADO, 
    CASE WHEN coalesce(CLI.BLOQUEIO, '') = '' then 'S' ELSE 'N' END AS BLOQ_DOCUMENTO,							
    CLI.CLI_LIMITE AS CREDITO_TOTAL, 
	CLI.CLI_LIMITE_CONSUMIDO AS CREDITO_CONSUMIDO, 
	27 AS MIX_PLANEJADO, coalesce(MIX.MIX_REALIZADO,0) as MIX_REALIZADO,
	0 AS OPORTUNIDADE, 0 AS OPORTUNIDADE_REALIZADO, 
	case
		when coalesce(dup.qde, 0) >= 1 then 'S'
		else 'N'
	end as dup_atraso,	
	-- novos status
	case
		when coalesce(bloq_credito.codigo, '') <> '' OR (CLI.CLI_LIMITE - CLI.CLI_LIMITE_CONSUMIDO <  250) then 'alert'
		when coalesce(bloq_credito.codigo, '') = '' and (CLI.CLI_LIMITE - CLI.CLI_LIMITE_CONSUMIDO) between 250 and 500 then 'warning'
		when coalesce(bloq_credito.codigo, '') = '' and (CLI.CLI_LIMITE - CLI.CLI_LIMITE_CONSUMIDO) > 500 then 'ok'
	end as tag_credito, 
	case
		when coalesce(CLI.BLOQUEIO, '') <> '' then 'alert'
		else 'ok'
	end as tag_documentacao, 
    case
    	when coalesce(pos.kunnr, '') <> '' then 'ok'
    	else 'alert'
    end as tag_positivado, 
	case
		when coalesce(dup.qde, 0) >= 1 then 'alert'
		when coalesce(dup.qde, 0) >= 1 then 'warning' -- validar regra e refazer
		else 'ok'
	end as tag_duplicatas
FROM 
	-- substituit por tabela CV_VIEW_CADASTRO_CLIENTE
	 dados-dev.visoes_auxiliares_cimed_tech.CV_VIEW_CADASTRO_CLIENTE CLI
	-- join abaixo comentado pois o conteudo da view abaixo ja esta dentro da view de clientes acima
--JOIN 
--	dados-dev.visoes_auxiliares_cimed_tech.CV_VIEW_LIFNR_CLIENTE  LCLI
--	ON LCLI.KUNNR = CLI.CODIGO
left join	
	(
	-- substituir por tabela CV_VIEW_CLIENTES_BLQOUEIO
	select kunnr as codigo
	from  dados-dev.visoes_auxiliares_cimed_tech.CV_VIEW_CLIENTES_BLQOUEIO 
	union all
	select knkli as codigo
	from  dados-dev.visoes_auxiliares_cimed_tech.CV_VIEW_CLIENTES_BLQOUEIO 
	) as bloq_credito	
	on bloq_credito.codigo = CLI.CODIGO
LEFT JOIN
	(
	-- esse trecho pode ir para cima com WITH? 
	select 
		distinct kunnr
	from
		dados-dev.raw.VBAK
	where
	--mes atual a partir do dia 1º	
	erdat >= REPLACE(SUBSTR(CAST(CURRENT_DATE AS STRING),0,7),'-','')||'01'
	) as pos	
	on pos.kunnr = cli.codigo
LEFT JOIN
	(
	select
		DVENDA.CLIENTE,
		CAST(
	  		CASE 
	     		WHEN DVENDA.COCKPIT = 'Faturamento' AND SUM(DVENDA.VALOR_NF) > 0 
	     			THEN COUNT(DISTINCT DVENDA.CHAVE_MIX) / COUNT(DISTINCT DVENDA.CLIENTE)
	     		ELSE
		       		0
	  		END AS INTEGER) AS MIX_REALIZADO
	  FROM 
	  	dados-dev.visoes_auxiliares_cimed_tech.CV_DASH_MV_VISAO DVENDA
	  WHERE 
	  	DVENDA.COCKPIT IN ('Faturamento','Devolução')    
		--AND substring(DT_FATUR, 1,6) = CAST(YEAR(ADD_DAYS(CURRENT_DATE, -180)) AS VARCHAR)||to_varchar(MONTH(ADD_DAYS(CURRENT_DATE, -180)), '00' )
	    AND DVENDA.VENDEDOR <> '?'
	    AND COALESCE(DVENDA.VENDEDOR, '') <> ''
	    AND DVENDA.VENDEDOR NOT LIKE 'H%'
		--and DVENDA.CLIENTE = :IP_CODIGO_SAP
	  GROUP BY     
	    DVENDA.CLIENTE, DVENDA.COCKPIT
	) MIX	
	ON MIX.CLIENTE = CLI.CODIGO
LEFT JOIN
	-- esse trecho pode ir para cima com WITH? 
	-- ou uma tabela materializada?
	(	
	-- qde de titulos em atraso	
							
	SELECT cliente, COUNT(*) as qde
			
	FROM  dados-dev.visoes_auxiliares_cimed_tech.CV_VIEW_PARTIDAS_ABERTO_GERAL 

	where
	DATE(datavencimento) < current_date
	GROUP BY
		cliente
	 ) as dup
	 on dup.cliente = CLI.CODIGO
--where LCLI.LIFNR = :IP_LIFNR
--where lcli.lifnr = '0000601328'
ORDER BY 
	CLI.CLI_RZS
																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																													   
																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																													   
																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																													   