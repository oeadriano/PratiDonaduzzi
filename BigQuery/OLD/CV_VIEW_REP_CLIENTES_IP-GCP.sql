--CV_VIEW_REP_CLIENTES_IP

SELECT 
	DISTINCT 
	LCLI.lifnr, 
	CLI.codigo, 
	CLI.cli_rzs, 
	CLI.cli_cgc, 
	CLI.cli_end, 
	'' AS cli_num, 
	CLI.cli_bai, 
	CLI_cep, cli_est, 
	CLI.cli_cid, 
	CLI.cli_tel, 
	CLI.cli_email, 
	CLI.cli_limite, 
	CLI.alvaranumero, 
	CLI.alvaradata, 
	CLI.alvaranumerosanit, 
	CLI.alvaradatasanit, 
	CLI.resptecniconome, 
	CLI.resptecnicocrf, 
	CLI.datacrf, 
	CLI.alvaranumerosivisa,
	CLI.alvaradatasivisa, 
	CLI.controlado, 
	CLI.numero_ae, 
	CLI.caixa_fechada,
	CLI.bloqueio, 
	CLI.grupo_contas, 
	CLI.crossdocking, 
	CLI.conta_matriz,
	CLI.bu, 
	CLI.associativismo1, 
	CLI.associativismo2, 
	'' as nome_ass1, '' as nome_ass2,	
	CLI.cod_rede, 
	CLI.nome_rede,		  
    CASE WHEN coalesce(bloq_credito.codigo, '') <> '' then 'Bloq. Crédito' ELSE '' END AS bloq_financeiro,
    CASE WHEN coalesce(pos.kunnr, '') <> '' then 'S' ELSE 'N' END AS positivado, 
    CASE WHEN coalesce(CLI.BLOQUEIO, '') = '' then 'N' ELSE 'S' END AS bloq_documento,							
    CLI.CLI_LIMITE AS credito_total, 
	CLI.CLI_LIMITE_CONSUMIDO AS credito_consumido, 
	27 AS mix_planejado, coalesce(MIX.MIX_REALIZADO,0) as mix_realizado,
	0 AS oportunidade, 0 AS oportunidade_realizado, 
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
	end as tag_duplicatas,
	FORMAT_TIMESTAMP("%d/%m/%Y %H:%M:%S", CURRENT_TIMESTAMP()) as last_update
FROM 
	-- substituit por tabela CV_VIEW_CADASTRO_CLIENTE
	 dados-dev.raw_cimed_tech.CADASTRO_CLIENTE_T CLI
	-- join abaixo comentado pois o conteudo da view abaixo ja esta dentro da view de clientes acima
JOIN 
	dados-dev.raw_cimed_tech.LIFNR_CLIENTE_T LCLI
	ON LCLI.KUNNR = CLI.CODIGO
left join	
	(
	-- substituir por tabela CV_VIEW_CLIENTES_BLQOUEIO
	select kunnr as codigo
	from  dados-dev.raw_cimed_tech.CLIENTES_BLQOUEIO_T
	union all
	select knkli as codigo
	from  dados-dev.raw_cimed_tech.CLIENTES_BLQOUEIO_T 
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
	  	dados-dev.raw_cimed_tech.CV_DASH_MV_VISAO_T DVENDA
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
-- where lcli.lifnr = '0000602640'
ORDER BY 
	CLI.CLI_RZS