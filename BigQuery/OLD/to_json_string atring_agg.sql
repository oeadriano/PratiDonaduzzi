filtro_contexto: [ {"nome: "promoção", id: "1"},  {"nome: "lancamentos", id: "2"} ]

/*
SELECT 
  id, 
  STRING_AGG(name ORDER BY name) AS Text 
FROM yourTable 
GROUP BY id

*/

SELECT lifnr, to_json_string(string_agg(kunnr order by kunnr)) as kunnr
FROM `dados-dev.raw_cimed_tech.LIFNR_CLIENTE_T`
where lifnr  = '0000601126'
group by lifnr

SELECT lifnr, string_agg(to_json_string(kunnr) order by kunnr) as kunnr
FROM `dados-dev.raw_cimed_tech.LIFNR_CLIENTE_T`
where lifnr  = '0000601126'
group by lifnr