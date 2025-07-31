X1	Consultor
X5	Empresa Represent.
Y1	Representante
Y2	Supervisor
Y3	Distrital
Y4	Regional
Y5	Divisional/Nacional
Y6	Diretoria

------------------------------------------------------------------------------------
with 
	w_cad1 as (
		SELECT LIFN2 as ID_REPRESENTANTE_Y1
		FROM dados-dev.raw.WYT3
		WHERE PARVW = 'Y1' AND DEFPA = 'X'
		),
	w_cad2 as (
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
		id_Representante as lifnr, id_representante_y1 as superior
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
		and id_Representante not in
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
		and id_Representante not in
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
		and id_Representante not in
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
		and id_Representante not in
		(
			select distinct id_representante_y6 id from w_cad6 
		)                


---------------------------------------------------------------------------------------------------------
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
