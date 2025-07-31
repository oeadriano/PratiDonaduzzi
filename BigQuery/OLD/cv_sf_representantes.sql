-- CV_SF_CADASTRO_REPRESENTANTES
with w_cad as (
	with w_cad1 as (
		SELECT y1.LIFN2        as ID_REPRESENTANTE_Y1,
               sup.id_superior as id_superior_y1
        FROM dados-prod.raw.WYT3 as y1
        LEFT JOIN (select cad_sup.lifnr,
                          id_sup.lifn2 as id_superior 
                   from ( select *
                          from dados-prod.raw.WYT3
                          where PARVW = 'Y1' 
                            AND DEFPA = 'X') as cad_sup
                   inner join dados-prod.raw.WYT3 as id_sup_aux
                     on cad_sup.mandt = id_sup_aux.MANDT
                    and cad_sup.lifnr = id_sup_aux.LIFN2
                    and cad_sup.PARVW =  'Y1' 
                    and id_sup_aux.DEFPA  != 'X'
                   inner join dados-prod.raw.WYT3 as id_sup
                     on id_sup.mandt = id_sup.MANDT
                    and id_sup.lifnr = id_sup_aux.lifnr
                    and id_sup.PARVW = 'Y2' 
                    and id_sup.DEFPA = 'X'
                  ) as sup
        on sup.lifnr = Y1.LIFNR
        WHERE y1.PARVW = 'Y1' AND y1.DEFPA = 'X'),
    w_cad2 as (
		SELECT y2.LIFN2        as ID_REPRESENTANTE_Y2,
               sup.id_superior as id_superior_y2
        FROM dados-prod.raw.WYT3 as y2
        LEFT JOIN (select cad_sup.lifnr,
                          id_sup.lifn2 as id_superior 
                   from ( select *
                          from dados-prod.raw.WYT3
                          where PARVW = 'Y3' 
                            AND DEFPA != 'X') as cad_sup
                   inner join dados-prod.raw.WYT3 as id_sup
                     on cad_sup.mandt = id_sup.MANDT
                    and cad_sup.lifn2 = id_sup.LIFNR
                    and cad_sup.PARVW = 'Y3' 
                    and id_sup.DEFPA  = 'X'
                  ) as sup
        on sup.lifnr = Y2.LIFNR
        WHERE y2.PARVW = 'Y2' AND y2.DEFPA = 'X'),
	w_cad3 as (
		SELECT y3.LIFN2        as ID_REPRESENTANTE_Y3,
               sup.id_superior as id_superior_y3
        FROM dados-prod.raw.WYT3 as y3
        LEFT JOIN (select cad_sup.lifnr,
                          id_sup.lifn2 as id_superior 
                   from ( select *
                          from dados-prod.raw.WYT3
                          where PARVW = 'Y4' 
                            AND DEFPA != 'X') as cad_sup
                   inner join dados-prod.raw.WYT3 as id_sup
                     on cad_sup.mandt = id_sup.MANDT
                    and cad_sup.lifn2 = id_sup.LIFNR
                    and cad_sup.PARVW = 'Y4' 
                    and id_sup.DEFPA  = 'X'
                  ) as sup
        on sup.lifnr = Y3.LIFNR
        WHERE y3.PARVW = 'Y3' AND y3.DEFPA = 'X'),
	w_cad4 as (
		SELECT y4.LIFN2        as ID_REPRESENTANTE_Y4,
               sup.id_superior as id_superior_y4
        FROM dados-prod.raw.WYT3 as y4
        LEFT JOIN (select cad_sup.lifnr,
                          id_sup.lifn2 as id_superior 
                   from ( select *
                          from dados-prod.raw.WYT3
                          where PARVW = 'Y5' 
                            AND DEFPA != 'X') as cad_sup
                   inner join dados-prod.raw.WYT3 as id_sup
                     on cad_sup.mandt = id_sup.MANDT
                    and cad_sup.lifn2 = id_sup.LIFNR
                    and cad_sup.PARVW = 'Y5' 
                    and id_sup.DEFPA  = 'X'
                  ) as sup
        on sup.lifnr = Y4.LIFNR
        WHERE y4.PARVW = 'Y4' AND y4.DEFPA = 'X'),
	w_cad5 as (
		SELECT y5.LIFN2        as ID_REPRESENTANTE_Y5,
               sup.id_superior as id_superior_y5
        FROM dados-prod.raw.WYT3 as y5
        LEFT JOIN (select cad_sup.lifnr,
                          id_sup.lifn2 as id_superior 
                   from ( select *
                          from dados-prod.raw.WYT3
                          where PARVW = 'Y6' 
                            AND DEFPA != 'X') as cad_sup
                   inner join dados-prod.raw.WYT3 as id_sup
                     on cad_sup.mandt = id_sup.MANDT
                    and cad_sup.lifn2 = id_sup.LIFNR
                    and cad_sup.PARVW = 'Y6' 
                    and id_sup.DEFPA  = 'X'
                  ) as sup
        on sup.lifnr = Y5.LIFNR
        WHERE y5.PARVW = 'Y4' AND y5.DEFPA = 'X'),
	w_cad6 as (
		SELECT LIFN2 as ID_REPRESENTANTE_Y6,
               ''    as id_superior_y6
		FROM dados-prod.raw.WYT3
		WHERE PARVW = 'Y6' AND DEFPA = 'X'),
	w_lfa1 as (
		select lifnr, name1
		from `dados-prod.raw.LFA1`
	)
-- representante
	select
		id_representante_y1 as lifnr, 'Y1' as func_par,
        id_superior_y1      as id_superior
	from 
		w_cad1 as cad1
	where 
		id_representante_y1 not in
		(
			select distinct id_representante_y2 id from w_cad2 union all 
			select distinct id_representante_y3 id from w_cad3 union all 
			select distinct id_representante_y4 id from w_cad4 union all 
			select distinct id_representante_y5 id from w_cad5 union all 
			select distinct id_representante_y6 id from w_cad6 
		)
	union all 
-- supervisor
	select
		id_representante_y2 as lifnr, 'Y2' as func_par,
        id_superior_y2      as id_superior
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
		id_representante_y3 as lifnr, 'Y3' as func_par,
        id_superior_y3      as id_superior
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
		id_representante_y4 as lifnr, 'Y4' as func_par,
        id_superior_y4      as id_superior
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
		id_representante_y5 as lifnr, 'Y5' as func_par,
        id_superior_y5      as id_superior
	from 
		w_cad5 as cad5
	where 
		id_representante_y5 not in
		(
			select distinct id_representante_y6 id from w_cad6 
		)
	union all 
	select 
		distinct id_representante_y6 as lifnr, 'Y6' as func_par,
        id_superior_y6      as id_superior
		from w_cad6 
  )
SELECT DISTINCT
    coalesce(cad.id_superior, '') AS vnd_cod,
    a.name1 AS vnd_nom,
    case
      when coalesce(a.stcd1, '') = '' then a.stcd2
      else a.stcd1
    end as vnd_cpf,
    a.ktokk AS vnd_tipo,
    a.lifnr AS vnd_cod_sap,
    a.adrnr,
    case 
      when coalesce(a.loevm, '')||coalesce(b.loevm, '')||coalesce(c.loevm, '') <> '' then coalesce(d.smtp_addr, '') ||'.inativo'
      else coalesce(d.smtp_addr, '') 
    end AS vnd_email,
    coalesce(
    	case
    		when e.func_par in ('X1', 'Y1') then e.func_par
    		else cad.func_par
    	end
    	, 'N') as func_par,
    case
    	when coalesce(a.loevm, '')||coalesce(b.loevm, '')||coalesce(c.loevm, '') <> '' then 'I'
    	else 'A'
    end as status, 
    t3.parvw
  FROM dados-prod.raw.LFA1 AS a
    LEFT JOIN dados-prod.raw_cimed_tech.LFB1 AS b ON ( a.lifnr = b.lifnr )
    LEFT JOIN dados-prod.raw_cimed_tech.LFM1 AS c ON ( a.lifnr = c.lifnr )
    LEFT JOIN dados-prod.raw.ADR6 AS d ON ( a.adrnr = d.addrnumber )
    LEFT join dados-prod.raw.YDSD094 AS e ON (a.lifnr = e.repr)
JOIN
	dados-prod.raw.WYT3 as T3
	ON T3.LIFN2 = A.LIFNR
	AND T3.EKORG = '1000'
--	AND T3.PARVW = 'Y1'
	--AND T3.DEFPA = 'X'		
left join 
  w_cad as cad 
  on cad.lifnr = a.lifnr
--------- inicio - trecho inserido para validação do cimed tech, retirar após acertar hierarquia --------------------
-- AEO 02.03.22 - todos os reps
--inner join `dados-prod.visoes_auxiliares_dash_MKT.CV_HIER_VENDAS` as var_ind
--  on var_ind.id_Representante = a.lifnr
 --and var_ind.id_cadeira_y6 = 'H10_0000'
--inner join `dados-prod.visoes_auxiliares_dash_MKT.CV_HIER_VENDAS` as var_indsup
--  on var_indsup.id_Representante = cad.id_superior
 --and var_indsup.id_cadeira_y6 = 'H10_0000'
--left join 
    
--------- fim - trecho inserido para validação do cimed tech, retirar após acertar hierarquia -----------------------
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
	a.lifnr