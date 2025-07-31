--CV_VIEW_PARTIDAS_ABERTO_GERAL

--select count(*) FROM dados-dev.raw.BKPF 15.285.535
--select count(*) FROM dados-dev.raw.VBRP 10.868.166
--select count(*) FROM dados-dev.raw.YBCONTROLBOLETOS 3.407.666 - ok 
--select count(*) FROM dados-dev.raw.BSID 822.709
--select count(*) FROM dados-dev.raw.KNKK 115.327


--CV_VIEW_PARTIDAS_ABERTO_IP
{
"query": {{ CONCAT("SELECT PEDIDO, datavencimento as VENCIMENTO, linhadigi as CODIGO_BARRAS, valororiginal as VALOR, STATUS, BUKRS, GJAHR, CODIGO AS BELNR FROM  dados-dev.visoes_auxiliares_cimed_tech.CV_VIEW_PARTIDAS_ABERTO_GERAL WHERE LIFNR = '" , message.queryAndPath.lifnr , "' " ) }},
"useLegacySql": false
}

{
"query": {{ CONCAT("SELECT PEDIDO, datavencimento as VENCIMENTO, linhadigi as CODIGO_BARRAS, valororiginal as VALOR, STATUS, BUKRS, GJAHR, BELNR FROM  dados-dev.visoes_auxiliares_cimed_tech.CV_VIEW_PARTIDAS_ABERTO_GERAL WHERE LIFNR = '" , message.queryAndPath.lifnr , "' " ) }},
"useLegacySql": false
}


SELECT PEDIDO, datavencimento as VENCIMENTO, linhadigi as CODIGO_BARRAS, valororiginal as VALOR, STATUS, BUKRS, GJAHR, BELNR
FROM 
    "_SYS_BIC"."CimedTech/CV_VIEW_PARTIDAS_ABERTO_IP"
    
     (PLACEHOLDER."$$IP_CLIENTE$$" => {{ message.queryAndPath.cliente }});

$.queryAndPath.[?(@.cliente)]



--CV_VIEW_PARTIDAS_ABERTO_GERAL
with w_lifnr as (
    select distinct kunnr, lifnr 
    from `dados-dev.raw_cimed_tech.LIFNR_CLIENTE_T`
),
w_boletos as (
	select 
		bukrs, gjahr, belnr, buzei, linhadigi
	from 
		dados-dev.raw.YBCONTROLBOLETOS
	),
w_bsid as (
	select 
		belnr, bukrs, gjahr, kunnr, blart, xblnr,		
		budat, zfbdt, zbd3t, zbd2t, zbd1t, SHKZG, bldat, rebzg,
		wrbtr, zuonr, bupla, buzei, 
		cast(case
			-- zfbdt = null
			when coalesce(b.zfbdt, '') <> '' AND cast(b.zbd3t as string) <> '0' then cast(date_add(PARSE_DATE("%Y%m%d",b.zfbdt),interval b.zbd3t day)as string)
			when coalesce(b.zfbdt, '') <> '' AND cast(b.zbd3t as string) = '0' AND cast(b.zbd2t as string) > '0' then cast(date_add(PARSE_DATE("%Y%m%d",b.zfbdt),interval b.zbd2t day)as string)
			when coalesce(b.zfbdt, '') <> '' AND cast(b.zbd3t as string) = '0' AND cast(b.zbd2t as string) = '0'  then cast(date_add(PARSE_DATE("%Y%m%d",b.zfbdt),interval b.zbd1t day)as string)
			when coalesce(b.rebzg, '') <> '' AND b.SHKZG = 'H' then b.zfbdt
			when coalesce(b.rebzg, '') <> '' AND b.SHKZG = 'K' then b.zfbdt
		  -- zfbdt > null
			when coalesce(b.zfbdt, '') = '' AND cast(b.zbd3t as string) <> '0' then cast(date_add(PARSE_DATE("%Y%m%d",b.bldat),interval b.zbd3t day)as string)
			when coalesce(b.zfbdt, '') = '' AND cast(b.zbd3t as string) = '0' AND cast(b.zbd2t as string) > '0' then cast(date_add(PARSE_DATE("%Y%m%d",b.bldat),interval b.zbd2t day)as string)
			when coalesce(b.zfbdt, '') = '' AND cast(b.zbd3t as string) = '0' AND cast(b.zbd2t as string) = '0'  then cast(date_add(PARSE_DATE("%Y%m%d",b.bldat),interval b.zbd1t day)as string )       	
			when coalesce(b.rebzg, '') = '' AND b.SHKZG = 'H' then b.bldat
			when coalesce(b.rebzg, '') = '' AND b.SHKZG = 'K' then b.bldat
			else '0' end
		as string) as datavencimento
	from
		dados-dev.raw.BSID as b
	where 
		(blart <> 'DC' AND umskz <> 'Y')
		and blart IN (SELECT low FROM dados-dev.raw_cimed_tech.YDFI_PARITENS WHERE name = 'RFC_PARTIDAS_DOCVENDA')
		and shkzg = 'S'
        and augbl = ''
),
w_vbrp as (
	select 
		distinct vbeln, vstel, aubel
	from 
		dados-dev.raw.VBRP
	where
		coalesce(aubel, '') <> ''
)
SELECT 
	-- predileta RJ era bukrs/bupla 4000/0001, a chamada na RFC é pelo novo codigo
	-- portanto, o que era 4000/0001, vira 3000/0002
    lif.lifnr, 
 	case 
 		when b.bukrs = '4000' then '3000'
 		when b.bukrs = '4500' then '3000'
 		else b.bukrs
 	end as bukrs,  	 	
 	b.belnr as codigo, b.kunnr as cliente, v.aubel as pedido, 
	replace(case
		when b.blart = 'DC' then k.bktxt
		when b.blart <> 'DC' then b.xblnr		
	end, '-20', '') as nota_fiscal, 	
	b.budat as dataemissao, 
	b.datavencimento,
	b.wrbtr as valororiginal, 
	B.zuonr as duplicata, 	
	n.knkli AS conta_matriz, 
	bol.linhadigi, 
	-- predileta RJ era bukrs/bupla 4000/0001, a chamada na RFC é pelo novo codigo
	-- portanto, o que era 4000/0001, vira 3000/0002
 	case 
 		when b.bukrs = '4000' then '0002'
 		when b.bukrs = '4500' then '0005'-- RS de 4500/0001 para 3000/005
 		else b.bupla
 	end as bupla, 
    case
        -- atrasado a mais de 7 dias é bloqueado
        when date(b.datavencimento) <= date_add(current_date, interval -7 day) then 'BLOQUEADA'
        when date(datavencimento) between date_add(current_date, interval -1 day) and date_add(current_date, interval -6 day) then 'VENCIDA'
        else 'A VENCER'     
    end as status
FROM 
	dados-dev.raw.BKPF AS k
JOIN 
	w_bsid AS b
	ON b.belnr = k.belnr
    AND b.bukrs = k.bukrs
    AND b.gjahr = k.gjahr    
JOIN 
	w_vbrp as v
	ON v.vbeln = k.belnr	
JOIN
	dados-dev.raw.KNKK as n
    on n.kunnr = b.kunnr
JOIN
	w_boletos as bol
	ON b.bukrs  = bol.bukrs
    AND b.gjahr = bol.gjahr
    AND b.belnr = bol.belnr
    AND b.buzei = bol.buzei			
join 
    w_lifnr as lif
    on lif.kunnr = n.kunnr

/* VERSAO OLD AEO 18.11.21
SELECT 
	-- predileta RJ era bukrs/bupla 4000/0001, a chamada na RFC é pelo novo codigo
	-- portanto, o que era 4000/0001, vira 3000/0002
 	case 
 		when b.bukrs = '4000' then '3000'
 		when b.bukrs = '4500' then '3000'
 		else b.bukrs
 	end as bukrs,  	 	
 	b.belnr as codigo, b.kunnr as cliente, v.aubel as pedido, 
	replace(case
		when b.blart = 'DC' then k.bktxt
		when b.blart <> 'DC' then b.xblnr		
	end, '-20', '') as nota_fiscal, 	
	b.budat as dataemissao, 
	cast(case
	 	-- zfbdt = null
	 	when coalesce(b.zfbdt, '') <> '' AND cast(b.zbd3t as string) <> '0' then cast(date_add(PARSE_DATE("%Y%m%d",b.zfbdt),interval b.zbd3t day)as string)
	 	when coalesce(b.zfbdt, '') <> '' AND cast(b.zbd3t as string) = '0' AND cast(b.zbd2t as string) > '0' then cast(date_add(PARSE_DATE("%Y%m%d",b.zfbdt),interval b.zbd2t day)as string)
	 	when coalesce(b.zfbdt, '') <> '' AND cast(b.zbd3t as string) = '0' AND cast(b.zbd2t as string) = '0'  then cast(date_add(PARSE_DATE("%Y%m%d",b.zfbdt),interval b.zbd1t day)as string)
	 	when coalesce(b.rebzg, '') <> '' AND b.SHKZG = 'H' then b.zfbdt
	 	when coalesce(b.rebzg, '') <> '' AND b.SHKZG = 'K' then b.zfbdt
 	  -- zfbdt > null
	 	when coalesce(b.zfbdt, '') = '' AND cast(b.zbd3t as string) <> '0' then cast(date_add(PARSE_DATE("%Y%m%d",b.bldat),interval b.zbd3t day)as string)
	 	when coalesce(b.zfbdt, '') = '' AND cast(b.zbd3t as string) = '0' AND cast(b.zbd2t as string) > '0' then cast(date_add(PARSE_DATE("%Y%m%d",b.bldat),interval b.zbd2t day)as string)
	 	when coalesce(b.zfbdt, '') = '' AND cast(b.zbd3t as string) = '0' AND cast(b.zbd2t as string) = '0'  then cast(date_add(PARSE_DATE("%Y%m%d",b.bldat),interval b.zbd1t day)as string )       	
	 	when coalesce(b.rebzg, '') = '' AND b.SHKZG = 'H' then b.bldat
	 	when coalesce(b.rebzg, '') = '' AND b.SHKZG = 'K' then b.bldat
	 	else '0' end
    as string) as datavencimento,
	b.wrbtr as valororiginal, 
	B.zuonr as duplicata, 	
	n.knkli AS conta_matriz, 
	bol.linhadigi, 
	-- predileta RJ era bukrs/bupla 4000/0001, a chamada na RFC é pelo novo codigo
	-- portanto, o que era 4000/0001, vira 3000/0002
 	case 
 		when b.bukrs = '4000' then '0002'
 		when b.bukrs = '4500' then '0005'-- RS de 4500/0001 para 3000/005
 		else b.bupla
 	end as bupla
FROM dados-dev.raw.BSID AS b
JOIN dados-dev.raw.BKPF AS k
	ON b.belnr = k.belnr
    AND b.bukrs = k.bukrs
    AND b.gjahr = k.gjahr
JOIN 
	(
	  select vbeln, vstel, aubel
	  from dados-dev.raw.VBRP
	  group by vbeln, vstel, aubel
	) as v
	ON v.vbeln = b.belnr
JOIN
	dados-dev.raw.KNKK as n
    on n.kunnr = b.kunnr
JOIN
	dados-dev.raw.YBCONTROLBOLETOS bol
	ON b.bukrs  = bol.bukrs
    AND b.gjahr = bol.gjahr
    AND b.belnr = bol.belnr
    AND b.buzei = bol.buzei			
WHERE 
	B.MANDT = '500'
    and (b.blart <> 'DC' AND b.umskz <> 'Y')
    AND b.blart IN (SELECT low FROM dados-dev.raw_cimed_tech.YDFI_PARITENS WHERE name = 'RFC_PARTIDAS_DOCVENDA')
	AND b.shkzg = 'S'
	and coalesce(v.aubel, '') <> ''
ORDER BY 
	b.kunnr, b.belnr, b.buzei
*/