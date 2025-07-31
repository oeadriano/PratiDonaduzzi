--CV_VIEW_PARTIDAS_ABERTO_GERAL
-- NOVA VERSAO AEO 24.11.2021
--select count(*) from dados-dev.raw.BSID --860891
--select count(*) from dados-dev.raw.VBRP --10.868.442
--select count(*) from dados-dev.raw.BKPF --15.286.309

--CV_VIEW_PARTIDAS_ABERTO_GERAL
with 
w_vbrp as (
	select 
		distinct vbeln, vstel, aubel
	from 
		dados-dev.raw.VBRP
	where
		coalesce(aubel, '') <> ''
),
w_bsid as (
	-- AEO 06.01.2022 - retira titulos pagos
	with w_bsid_pagos as (
		select belnr 
		from dados-dev.raw.BSID as b
		where coalesce(augbl, '') <> ''
	)
	select 
		belnr, bukrs, gjahr, kunnr, blart, xblnr,		
		budat, zfbdt, zbd3t, zbd2t, zbd1t, SHKZG, bldat, rebzg,
		wrbtr, zuonr, bupla, buzei
	from
		dados-dev.raw.BSID as b
	where 
		(blart <> 'DC' AND umskz <> 'Y')
		and blart IN (SELECT low FROM dados-dev.raw_cimed_tech.YDFI_PARITENS WHERE name = 'RFC_PARTIDAS_DOCVENDA')
		and shkzg = 'S'
        --and augbl = ''
		and belnr not in (select belnr from w_bsid_pagos)		
),
w_boletos as (
	select 
		bukrs, gjahr, belnr, buzei, linhadigi
	from 
		dados-dev.raw.YBCONTROLBOLETOS
	),
w_lifnr as (
    select distinct kunnr, lifnr 
    from `dados-dev.raw_cimed_tech.LIFNR_CLIENTE_T`
),
w_vencimento as (
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
		w_bsid as b
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
    '' as nota_fiscal, 	
	b.budat as dataemissao, 
	replace(b.datavencimento, '-', '') as datavencimento, 
	b.wrbtr as valororiginal, 
	B.zuonr as duplicata, 	
	n.knkli AS conta_matriz, 
    case
        -- atrasado a mais de 7 dias é bloqueado
        when date(b.datavencimento) <= date_add(current_date, interval -7 day) then  ''
        else bol.linhadigi
    end as linhadigi, 
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
        when date(b.datavencimento) between date_add(current_date, interval -6 day) and date_add(current_date, interval -1 day) then 'VENCIDA'
        else 'A VENCER'     
    end as status, b.gjahr,
CURRENT_TIMESTAMP() as last_update	
FROM 	 
	w_vencimento AS b -- BSID	
JOIN 
	w_vbrp as v
	ON v.vbeln = b.belnr	
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
order by b.datavencimento

-- OLD VERSION
/*
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
	replace(b.datavencimento, '-', '') as datavencimento, 
	b.wrbtr as valororiginal, 
	B.zuonr as duplicata, 	
	n.knkli AS conta_matriz, 
    case
        -- atrasado a mais de 7 dias é bloqueado
        when date(b.datavencimento) <= date_add(current_date, interval -7 day) then  ''
        else bol.linhadigi
    end as linhadigi, 
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
        when date(b.datavencimento) between date_add(current_date, interval -1 day) and date_add(current_date, interval -6 day) then 'VENCIDA'
        else 'A VENCER'     
    end as status,b.gjahr
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
*/