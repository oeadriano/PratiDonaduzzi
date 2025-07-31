-- CV_SF_CADASTRO_REPRESENTANTES

with w_sup as 
(
	with w_cad2 as (
		SELECT LIFN2 as ID_REPRESENTANTE_Y2
		FROM dados-dev.raw.WYT3
		WHERE PARVW = 'Y2' AND DEFPA = 'X'
	),
	w_cad3 as (
		SELECT LIFN2 as ID_REPRESENTANTE_Y3
		FROM dados-dev.raw.WYT3
		WHERE PARVW = 'Y3' AND DEFPA = 'X'),
	w_cad4 as (
		SELECT LIFN2 as ID_REPRESENTANTE_Y4
		FROM dados-dev.raw.WYT3
		WHERE PARVW = 'Y4' AND DEFPA = 'X'),
	w_cad5 as (
		SELECT LIFN2 as ID_REPRESENTANTE_Y5
		FROM dados-dev.raw.WYT3
		WHERE PARVW = 'Y5' AND DEFPA = 'X'),
	w_cad6 as (
		SELECT LIFN2 as ID_REPRESENTANTE_Y6
		FROM dados-dev.raw.WYT3
		WHERE PARVW = 'Y6' AND DEFPA = 'X'),
	w_lfa1 as (
		select lifnr, name1
		from `dados-dev.raw.LFA1`
		)
	SELECT 
		id_Representante as lifnr, id_representante_y2 as superior
	FROM 
		`dados-dev.visoes_auxiliares_dash_MKT.CV_HIER_VENDAS` 
	WHERE 
		situacao_cadeira = 'ATIVA'
		and id_Representante not in
		(
			select distinct id_representante_y2 id from w_cad2 union all 
			select distinct id_representante_y3 id from w_cad3 union all         
			select distinct id_representante_y4 id from w_cad4 union all 
			select distinct id_representante_y5 id from w_cad5 union all 
			select distinct id_representante_y6 id from w_cad6 
		)
	union all 
	SELECT 
		id_Representante_y2 as lifnr, id_representante_y3 as superior
	FROM 
		`dados-dev.visoes_auxiliares_dash_MKT.CV_HIER_VENDAS` 
	WHERE 
		situacao_cadeira = 'ATIVA'
		and id_Representante_y2 not in
		(
			select distinct id_representante_y3 id from w_cad3 union all         
			select distinct id_representante_y4 id from w_cad4 union all 
			select distinct id_representante_y5 id from w_cad5 union all 
			select distinct id_representante_y6 id from w_cad6 
		)    
	union all 
	SELECT 
		id_Representante_y3 as lifnr, id_representante_y4 as superior
	FROM 
		`dados-dev.visoes_auxiliares_dash_MKT.CV_HIER_VENDAS` 
	WHERE 
		situacao_cadeira = 'ATIVA'
		and id_Representante_y3 not in
		(
			select distinct id_representante_y4 id from w_cad4 union all 
			select distinct id_representante_y5 id from w_cad5 union all 
			select distinct id_representante_y6 id from w_cad6 
		)        
	union all 
	SELECT 
		id_Representante_y4 as lifnr, id_representante_y5 as superior
	FROM 
		`dados-dev.visoes_auxiliares_dash_MKT.CV_HIER_VENDAS` 
	WHERE 
		situacao_cadeira = 'ATIVA'
		and id_Representante_y4 not in
		(
			select distinct id_representante_y5 id from w_cad5 union all 
			select distinct id_representante_y6 id from w_cad6 
		)            
	union all 
	SELECT 
		id_Representante_y5 as lifnr, id_representante_y6 as superior
	FROM 
		`dados-dev.visoes_auxiliares_dash_MKT.CV_HIER_VENDAS` 
	WHERE 
		situacao_cadeira = 'ATIVA'
		and id_Representante_y5 not in
		(
			select distinct id_representante_y6 id from w_cad6 
		) 	
),
---------------------------------
w_cad as (
	with w_cad2 as (
		SELECT LIFN2 as ID_REPRESENTANTE_Y2
		FROM dados-dev.raw.WYT3
		WHERE PARVW = 'Y2' AND DEFPA = 'X'
	),
	w_cad3 as (
		SELECT LIFN2 as ID_REPRESENTANTE_Y3
		FROM dados-dev.raw.WYT3
		WHERE PARVW = 'Y3' AND DEFPA = 'X'),
	w_cad4 as (
		SELECT LIFN2 as ID_REPRESENTANTE_Y4
		FROM dados-dev.raw.WYT3
		WHERE PARVW = 'Y4' AND DEFPA = 'X'),
	w_cad5 as (
		SELECT LIFN2 as ID_REPRESENTANTE_Y5
		FROM dados-dev.raw.WYT3
		WHERE PARVW = 'Y5' AND DEFPA = 'X'),
	w_cad6 as (
		SELECT LIFN2 as ID_REPRESENTANTE_Y6
		FROM dados-dev.raw.WYT3
		WHERE PARVW = 'Y6' AND DEFPA = 'X'),
	w_lfa1 as (
		select lifnr, name1
		from `dados-dev.raw.LFA1`
	)
-- supervisor
	select
		id_representante_y2 as lifnr, 'Y2' as func_par
	from 
		w_cad2 as cad2
	where 
		id_representante_y2 not in
		(
			select distinct id_representante_y3 id from w_cad3 union all 
			select distinct id_representante_y4 id from w_cad4 union all 
			select distinct id_representante_y5 id from w_cad5 union all 
			select distinct id_representante_y6 id from w_cad6 
		)
	union all 
	-- gerente distrital
	select
		id_representante_y3 as lifnr, 'Y3' as func_par
	from 
		w_cad3 as cad3
	where 
		id_representante_y3 not in
		(
			select distinct id_representante_y4 id from w_cad4 union all 
			select distinct id_representante_y5 id from w_cad5 union all 
			select distinct id_representante_y6 id from w_cad6 
		)
	union all 
	-- gerente Regional
	select
		id_representante_y4 as lifnr, 'Y4' as func_par
	from 
		w_cad4 as cad4
	where 
		id_representante_y4 not in
		(
			select distinct id_representante_y5 id from w_cad5 union all 
			select distinct id_representante_y6 id from w_cad6 
		)
	union all     
	-- gerente Divisional/Nacional
	select
		id_representante_y5 as lifnr, 'Y5' as func_par
	from 
		w_cad5 as cad5
	where 
		id_representante_y5 not in
		(
			select distinct id_representante_y6 id from w_cad6 
		)
	union all 
	select 
		distinct id_representante_y6 as lifnr, 'Y6' as func_par 
		from w_cad6 
  )
SELECT DISTINCT
    a.lifnr AS vnd_cod,	
    a.name1 AS vnd_nom,
    case
      when coalesce(a.stcd1, '') = '' then a.stcd2
      else a.stcd1
    end as vnd_cpf,
    a.ktokk AS vnd_tipo,
    a.lifnr AS vnd_cod_sap,
    a.adrnr,
    coalesce(d.smtp_addr, '') AS vnd_email,
    coalesce(
    	case
    		when e.func_par not in ('X1', 'Y1') then e.func_par
    		else cad.func_par
    	end
    	, 'N') as func_par,
    case
    	when coalesce(a.loevm, '')||coalesce(b.loevm, '')||coalesce(c.loevm, '') <> '' then 'I'
    	else 'A'
    end as status,
	sup.superior
  FROM dados-dev.raw.LFA1 AS a
    LEFT JOIN dados-dev.raw_cimed_tech.LFB1 AS b ON ( a.lifnr = b.lifnr )
    LEFT JOIN dados-dev.raw_cimed_tech.LFM1 AS c ON ( a.lifnr = c.lifnr )
    LEFT JOIN dados-dev.raw.ADR6 AS d ON ( a.adrnr = d.addrnumber )
    LEFT join dados-dev.raw.YDSD094 AS e ON (a.lifnr = e.repr)
JOIN
	dados-dev.raw.WYT3 as T3
	ON T3.LIFN2 = A.LIFNR
	AND T3.EKORG = '1000'
--	AND T3.PARVW = 'Y1'
	--AND T3.DEFPA = 'X'		
join 
  w_cad as cad 
  on cad.lifnr = a.lifnr
join 	
	w_sup as sup 
	on sup.lifnr = a.lifnr
WHERE
	a.ktokk BETWEEN 'YB14' AND 'YB16'
    -- AND a.loevm = ''
    AND a.sperr = ''
    AND a.nodel = ''
    AND b.sperr = ''
    AND b.nodel = ''
    AND c.sperm = ''
    --AND c.loevm = ''
    AND d.FLGDEFAULT = 'X' -- email default standard - AEO 06/12/19
    AND coalesce(d.PERSNUMBER, '') = '' -- endereço principal - AEO 06/12/19
ORDER BY -- a.loevm||b.loevm||c.loevm desc
	func_par, a.lifnr
