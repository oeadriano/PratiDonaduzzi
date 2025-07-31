--CV_VIEW_CLIENTES_BLQOUEIO
with w_bsid as (
	-- AEO 06.01.2022 - retira titulos pagos
	with w_bsid_pagos as (
		select belnr 
		from dados-dev.raw.BSID
		where coalesce(augbl, '') <> ''
	)
	select 
		mandt, belnr, bukrs, gjahr, kunnr, blart, xblnr,		
		budat, zfbdt, zbd3t, zbd2t, zbd1t, SHKZG, bldat, rebzg,
		wrbtr, zuonr, bupla, buzei
	from
		dados-dev.raw.BSID
	where 
		mandt = '500'
		and shkzg = 'S'
		and HBKID not in ('DEV', 'PCAR')			
		and belnr not in (select belnr from w_bsid_pagos)		
)
select
	distinct
	q3.kunnr, q3.stcd1, q3.knkli, q3.stcd2, 
	case when q3.kunnr = q3.knkli then 'X' else '' end as bloq_cli,
	case when q3.kunnr <> q3.knkli then 'X' else '' end as bloq_conta,
	CURRENT_TIMESTAMP() as last_update
	--FORMAT_TIMESTAMP("%d/%m/%Y %H:%M:%S", CURRENT_TIMESTAMP()) as last_update
from 
	(
	select 
		k1.kunnr, k1.stcd1, kk.knkli, k2.stcd1 as stcd2
	from
		dados-dev.raw.KNKK as kk
	join 
		dados-dev.raw.KNA1 as k1
        on k1.kunnr = kk.kunnr
	join 
		dados-dev.raw.KNA1 as k2
        on k2.kunnr = kk.knkli
	where
		kk.knkli in
		(
		-- contas bloqueadas:
		-- conta individual e conta coligada principal
		SELECT 
		    distinct b.knkli--, crblb, kunnr
		FROM 
			dados-dev.raw.KNKK as b
		WHERE 
			b.mandt = '500'
		AND b.crblb = 'X' 
		AND b.kkber = '1000' 
		AND b.kunnr = b.knkli 
		--AND b.knkli = '0001024052'
		union all	
		-- todos os knkli com individual e conta coligada principal q tenham
		-- duplicatas em atraso	
		select 
			knkli--, 'knkli' as tipo
		from
		 (	
		 -- todas as contas de credito que tem duplicatas
		 -- com vencimento acima da classe de risco
		 select 
		 	distinct knk.knkli, 
		 	case
		 	 when date_diff (
				CURRENT_DATE,
		 	 	date(
		 	 	 case
		 	 	  	-- zfbdt = null
		 	 	  	when coalesce(dup.zfbdt, '') <> '' AND dup.zbd3t <> 0 then date_add(PARSE_DATE("%Y%m%d",dup.zfbdt),interval dup.zbd3t day)
		 	 	  	when coalesce(dup.zfbdt, '') <> '' AND dup.zbd3t = 0 AND dup.zbd2t <> 0 then date_add(PARSE_DATE("%Y%m%d",dup.zfbdt),interval dup.zbd2t day)
		 	 	  	when coalesce(dup.zfbdt, '') <> '' AND dup.zbd3t = 0 AND dup.zbd2t = 0  then date_add(PARSE_DATE("%Y%m%d",dup.zfbdt ),interval dup.zbd1t day)
		 	 	  	when coalesce(dup.rebzg, '') <> '' AND dup.SHKZG = 'H' then DATE(dup.zfbdt) 
		 	 	  	when coalesce(dup.rebzg, '') <> '' AND dup.SHKZG = 'K' then DATE(dup.zfbdt)
		 	 	   -- zfbdt > null
		 	 	  	when coalesce(dup.zfbdt, '') = '' AND dup.zbd3t <> 0 then date_add(PARSE_DATE("%Y%m%d",dup.bldat ),interval dup.zbd3t day)
		 	 	  	when coalesce(dup.zfbdt, '') = '' AND dup.zbd3t = 0 AND dup.zbd2t <> 0 then date_add(PARSE_DATE("%Y%m%d",dup.bldat),interval dup.zbd2t day)
		 	 	  	when coalesce(dup.zfbdt, '') = '' AND dup.zbd3t = 0 AND dup.zbd2t = 0  then date_add(PARSE_DATE("%Y%m%d",dup.bldat ), interval dup.zbd1t day)       	
		 	 	  	when coalesce(dup.rebzg, '') = '' AND dup.SHKZG = 'H' then DATE(dup.bldat)
		 	 	  	when coalesce(dup.rebzg, '') = '' AND dup.SHKZG = 'K' then DATE(dup.bldat)
		 	 	  	else DATE(dup.zfbdt)
		 	 	 	 end), day) > cast(case when cr.ctlpc = '050' then '999' else cr.oitol end as int) then 'X' else '' end as status	
		 		
				 --AEO 24/08
		 		-- cliente bloqueado ja esta no
		 		-- union acima
		 		--when knk.crblb = 'X' then 'X'
		 				
			from 
				w_bsid dup
			join 
				dados-dev.raw.KNA1 kna 
				on kna.kunnr = dup.kunnr
				and kna.mandt = dup.mandt
			join 
				dados-dev.raw.KNKK knk 
					on knk.kunnr = dup.kunnr
					--and knk.kunnr = knk.knkli
					and knk.mandt = dup.mandt
				-- Join com tabela de cadastro de classe de risco							
				join
					dados-dev.raw.T691F cr
					on cr.ctlpc  = knk.ctlpc
					and cr.CTLPC = knk.CTLPC								
				where 
					dup.blart IN (SELECT LOW FROM dados-dev.raw_cimed_tech.YDFI_PARITENS WHERE name = 'RFC_ADM_CREDITO_TPDOC')
					and cr.kkber = '1000'
					and cr.crmgr = '01'
					and dup.mandt = '500'
					and kna.ktokd <> 'ZSAC'
					and kna.ktokd <> 'ZFIS' 		
					-- AEO 24/06/2020 - ZMEL-Melhoria: 302085, Automatização de Desbloqueio de vencidos
					--and knk.knkli = '0001024052'				
				) q1
			where 
				q1.status = 'X' 
		)	
		and k1.ktokd <> 'ZSAC'
		and k1.ktokd <> 'ZFIS'
		and k2.ktokd <> 'ZSAC'
		and k2.ktokd <> 'ZFIS'
	
/****************************************************************************	
contas coligadas bloqueadas, com conta principal desbloqueada
****************************************************************************/	
	union all
	select 
		k1.kunnr, k1.stcd1, k1.kunnr as knkli, k1.stcd1 as stcd2
	from
		dados-dev.raw.KNKK as kk
	join 
		dados-dev.raw.KNA1 as k1
		on k1.kunnr = kk.kunnr
	where
		kk.kunnr in
		(
			-- contas bloqueadas:
			-- conta individual e conta coligada principal
			SELECT 
				distinct b.kunnr--, crblb, knkli
			FROM 
				dados-dev.raw.KNKK as b
			WHERE 
				b.mandt = '500'
			  	AND b.crblb = 'X'
			  	AND b.kkber = '1000'
				AND b.kunnr <> b.knkli
				--AND b.knkli = '0001024052'
			union all	
			-- todos os knkli com individual e conta coligada principal q tenham
			-- duplicatas em atraso	
			select 
				kunnr--, 'knkli' as tipo
			from
			 (	
			 -- todas as contas de credito que tem duplicatas
			 -- com vencimento acima da classe de risco
			 select 
			 	distinct knk.kunnr, 
			 	case
			 	 when date_diff (
					  current_date,
			 	  date(
			 	  	case
			 	  	 	-- zfbdt = null
			 	  	 	when coalesce(dup.zfbdt, '') <> '' AND zbd3t <> 0 then date_add(PARSE_DATE("%Y%m%d",dup.zfbdt),interval dup.zbd3t day)
			 	  	 	when coalesce(dup.zfbdt, '') <> '' AND zbd3t = 0 AND dup.zbd2t <> 0 then date_add(PARSE_DATE("%Y%m%d",dup.zfbdt),interval dup.zbd2t day)
			 	  	 	when coalesce(dup.zfbdt, '') <> '' AND zbd3t = 0 AND dup.zbd2t = 0 then date_add(PARSE_DATE("%Y%m%d",dup.zfbdt ),interval dup.zbd1t day)
			 	  	 	when coalesce(dup.rebzg, '') <> '' AND dup.SHKZG = 'H' then DATE(dup.zfbdt)
			 	  	 	when coalesce(dup.rebzg, '') <> '' AND dup.SHKZG = 'K' then DATE(dup.zfbdt)
			 	  	  -- zfbdt > null
			 	  	 	when coalesce(dup.zfbdt, '') = '' AND dup.zbd3t <> 0 then date_add(PARSE_DATE("%Y%m%d",dup.bldat ),interval dup.zbd3t day)
			 	  	 	when coalesce(dup.zfbdt, '') = '' AND dup.zbd3t = 0 AND  dup.zbd2t <> 0 then date_add(PARSE_DATE("%Y%m%d",dup.bldat),interval dup.zbd2t day)
			 	  	 	when coalesce(dup.zfbdt, '') = '' AND dup.zbd3t = 0 AND dup.zbd2t = 0 then date_add(PARSE_DATE("%Y%m%d",dup.bldat ), interval dup.zbd1t day)       	
			 	  	 	when coalesce(dup.rebzg, '') = '' AND dup.SHKZG = 'H' then DATE(dup.bldat)
			 	  	 	when coalesce(dup.rebzg, '') = '' AND dup.SHKZG = 'K' then DATE(dup.bldat)
			 	  	 	else DATE(dup.zfbdt)
						 end), day) > cast(case when cr.ctlpc = '050' then '999' else cr.oitol end as int) then 'X'
			 	  
			 	 when knk.crblb = 'X' then 'X' else '' end as status			
				from 
					w_bsid dup
				join 
					dados-dev.raw.KNA1 kna 
					on kna.kunnr = dup.kunnr
					and kna.mandt = dup.mandt
				join 
					dados-dev.raw.KNKK knk 
					on knk.kunnr = dup.kunnr
					and knk.kunnr <> knk.knkli
					and knk.mandt = dup.mandt
				-- Join com tabela de cadastro de classe de risco							
				join
					dados-dev.raw.T691F cr
					on cr.ctlpc  = knk.ctlpc
					and cr.CTLPC = knk.CTLPC								
				where 
					dup.blart IN (SELECT LOW FROM dados-dev.raw_cimed_tech.YDFI_PARITENS WHERE name = 'RFC_ADM_CREDITO_TPDOC')
					and cr.kkber = '1000'
					and cr.crmgr = '01'
					and dup.mandt = '500'
					and kna.ktokd <> 'ZSAC'
					and kna.ktokd <> 'ZFIS' 		
					-- AEO 24/06/2020 - ZMEL-Melhoria: 302085, Automatização de Desbloqueio de vencidos
					--and knk.knkli = '0001024052'				
				) q1
			where 
				q1.status = 'X' 
		) 
		and k1.ktokd <> 'ZSAC'
		and k1.ktokd <> 'ZFIS'
--    order by 
--		kk.kunnr	
	) q3
join
	dados-dev.raw.KNVV kv
	on kv.kunnr = q3.kunnr
where
	kv.VTWEG in ('07', '10')
order by 
	q3.knkli, q3.kunnr
	
;