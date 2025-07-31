INSERT INTO raw_cimed_tech.CADASTRO_CLIENTE_T (SELECT * FROM dados-dev.visoes_auxiliares_cimed_tech.CV_VIEW_CADASTRO_CLIENTE);
DELETE FROM raw_cimed_tech.CADASTRO_CLIENTE_T WHERE last_update < (SELECT MAX(last_update) from raw_cimed_tech.CADASTRO_CLIENTE_T);


INSERT INTO raw_cimed_tech.REP_CLIENTES_IP_T (SELECT * FROM dados-dev.visoes_cimed_tech.CV_VIEW_REP_CLIENTES_IP);
DELETE FROM raw_cimed_tech.REP_CLIENTES_IP_T WHERE last_update < (SELECT MAX(last_update) from raw_cimed_tech.REP_CLIENTES_IP_T)

--CV_VIEW_REP_CLIENTES_IP
WITH w_pos as (
	SELECT
		 "VENDEDOR",
		 "CLIENTE" 
	FROM "_SYS_BIC"."MAT_BQ/CV_TR_CLIENTE_POSITIVADO"
), 
w_ultima_compra as (
	select        
		distinct kunnr, max(erdat) as erdat, vendedor
	from
		`dados-dev.raw_cimed_tech.CV_MAT_ULTIMA_COMPRA_T` 
	group by
		kunnr, vendedor
), 
w_preco_fixo as (
	select distinct cliente 
	from `dados-dev.raw_cimed_tech.CV_LOJAS_PRECO_FIXO_T`
)

SELECT 
	DISTINCT 
	lcli.vkorg, 	
	LCLI.lifnr, 
	CLI.codigo, 
	CLI.cli_rzs, 
	CLI.cli_cgc, 
	CLI.cli_end, 
	CLI.cli_num, 
	CLI.cli_bai, 
	CLI.cli_compl, 
	cli.CLI_cep, 
	cli.cli_est, 
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
    CASE WHEN coalesce(pos.cliente, '') <> '' then 'S' ELSE 'N' END AS positivado, 
    CASE WHEN coalesce(CLI.BLOQUEIO, '') = '' then 'N' ELSE 'S' END AS bloq_documento,							
    CLI.CLI_LIMITE AS credito_total, 
	CLI.CLI_LIMITE_CONSUMIDO AS credito_consumido, 
	cli.mix_planejado as mix_planejado, 
	cast(coalesce(cli.MIX_REALIZADO,0) as int) as mix_realizado,
	--round(op.objetivo,2)  as objetivo_tot_rep,
	--round(op.objetivo, 2) AS oportunidade, 
	round(cli.oportunidade,2) as oportunidade,
	/*round(case 
	  when op.objetivo > 0 then
	    round((cli.oportunidade / op.objetivo) * 100,2)
      else 
	    0
	end, 2) AS oportunidade_realizado, */
	cli.venda_mes as oportunidade_realizado,
	case
		when coalesce(dup._menor_0, 0) + coalesce(dup._de_0_4, 0) <> 0  then 'S'
		else 'N'
	end as dup_atraso,	
	-- novos status
	case
		when coalesce(bloq_credito.codigo, '') <> '' OR ((CLI.CLI_LIMITE - CLI.CLI_LIMITE_CONSUMIDO) < 250) then '#FE0000' -- vermelho 'alert'
		when coalesce(bloq_credito.codigo, '') = '' and (CLI.CLI_LIMITE - CLI.CLI_LIMITE_CONSUMIDO) between 250 and 500 then '#FEC400' -- amarelo 'warning'
		when coalesce(bloq_credito.codigo, '') = '' and (CLI.CLI_LIMITE - CLI.CLI_LIMITE_CONSUMIDO) > 500 then '#24AA52' -- verde 'ok'
	end as tag_credito, 
	case
		when coalesce(CLI.BLOQUEIO, '') <> '' then '#FE0000' -- vermelho 'alert'
        WHEN 
            (CLI.ALVARADATA != '' AND DATE_DIFF(current_date, SAFE.PARSE_DATE("%Y%m%d",CLI.ALVARADATA), day) > 0) OR
            (CLI.ALVARADATASANIT != '' AND DATE_DIFF(current_date, SAFE.PARSE_DATE("%Y%m%d",   CLI.ALVARADATA), day) > 0)
  		then '#FEC400'
		else '#24AA52' -- verde 'ok'
	end as tag_documentacao, 
    case
    	when coalesce(pos.cliente, '') <> '' then '#24AA52' -- verde 'ok'
    	else '#FE0000' -- vermelho 'alert'
    end as tag_positivado, 
	case
		when coalesce(dup._menor_0, 0) >= 1 then '#FE0000' -- vermelho 'alert'
		when coalesce(dup._menor_0, 0) = 0 AND coalesce(dup._de_0_4, 0) >= 1 then '#FEC400' -- amarelo 'warning'
		when coalesce(dup._menor_0, 0) = 0 AND coalesce(dup._de_0_4, 0) = 0 then '#24AA52' -- verde
		else '#24AA52' -- verde 'ok'
	end as tag_duplicatas,
  CASE
    WHEN CLI.ALVARADATA != '' THEN -- valor positivo significa dias vencido 
    CASE WHEN DATE_DIFF(current_date, SAFE.PARSE_DATE("%Y%m%d",CLI.ALVARADATA), day) > 0 THEN 'S'
         ELSE 'N'
    END
    WHEN CLI.ALVARADATASANIT != '' THEN 
    CASE WHEN DATE_DIFF(current_date, SAFE.PARSE_DATE("%Y%m%d",   CLI.ALVARADATA), day) > 0 THEN 'S'
         ELSE 'N'
    END
    ELSE 'N'
  END AS documento_em_atraso,
  --FORMAT_TIMESTAMP("%d/%m/%Y %H:%M:%S", CURRENT_TIMESTAMP()) as last_update
  coalesce(ult.erdat, '') as data_ultima_compra, 
  case 
  	when coalesce(fx.cliente, '') = '' then 'N'
	  else 'S'
	end as preco_fixo,	
  CURRENT_TIMESTAMP() as last_update
FROM 
	-- substituit por tabela CV_VIEW_CADASTRO_CLIENTE
		 --`dados-dev.visoes_auxiliares_cimed_tech.CV_VIEW_CADASTRO_CLIENTE` CLI
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
	w_pos as pos
	on pos.cliente = cli.codigo
	and pos.vendedor = LCLI.lifnr
LEFT JOIN
	-- esse trecho pode ir para cima com WITH? 
	-- ou uma tabela materializada?
	(	
	-- qde de titulos em atraso	
	select
		cliente, sum(_menor_0) as _menor_0, sum(_de_0_4) as _de_0_4, sum(_maior_4) as _maior_4
	from
		(
		SELECT 
			cliente,
			case
				when DATE_DIFF(current_date, SAFE.PARSE_DATE("%Y%m%d",datavencimento), day) < 0 then 1 
				else 0
			end as _menor_0,	
			case
				when DATE_DIFF(current_date, SAFE.PARSE_DATE("%Y%m%d",datavencimento), day) between 0 and 4 then 1
				else 0
			end as _de_0_4,
			case
				when DATE_DIFF(current_date, SAFE.PARSE_DATE("%Y%m%d",datavencimento), day) > 4 then 1
				else 0
			end as _maior_4	
	  	  --FROM dados-dev.visoes_auxiliares_cimed_tech.CV_VIEW_PARTIDAS_ABERTO_GERAL 
		  FROM `dados-dev.raw_cimed_tech.CV_VIEW_PARTIDAS_ABERTO_GERAL_T`
		) dup
	group by
		cliente		
	 ) as dup
	 on dup.cliente = CLI.CODIGO

--left join `dados-dev.raw.YDSD125` as op
	--on op.VENDEDOR = LCLI.lifnr
	--and op.ANO      = SUBSTR(CAST(CURRENT_DATE AS STRING),0,4)
	--and op.MES      = SUBSTR(CAST(CURRENT_DATE AS STRING),4,2)
left join 
	w_ultima_compra as ult
	on ult.kunnr = cli.codigo 
	and lcli.lifnr = ult.vendedor
left join 
	w_preco_fixo as fx 
	on fx.cliente = cli.codigo
 WHERE  
	CLI.ctlpc <> ''
	and CLI.aufsd <> '01'
	--and cli.cli_cgc = '31435881000105'

--where cli.codigo = '0001071537'
ORDER BY 
	CLI.CLI_RZS