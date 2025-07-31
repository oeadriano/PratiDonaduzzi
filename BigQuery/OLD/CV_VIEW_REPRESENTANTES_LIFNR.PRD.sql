--CV_VIEW_REPRESENTANTES_LIFNR

-- AEO 10.01.22
-- nao precisa vincular com todos os reps
select 
  distinct 
  l.lifnr as vnd_cod, l.vkorg, y44.werks, y44.lgort, y225.cod_gama as loja, y056.vtweg as canal
from 
  `dados-prod.raw_cimed_tech.LIFNR_CLIENTE_T` l   
join
  `dados-prod.raw.YDSD218` as y218 
   on y218.vkorg = l.vkorg
join
  `dados-prod.raw_cimed_tech.YDSD044` y44
  on y44.werks = y218.werks
join 
  `dados-prod.raw_cimed_tech.YDSD225` y225
  on y225.werks = y44.werks  
  and y225.lifn2 = l.lifnr
join 
  `dados-prod.raw_cimed_tech.YDSD056` y056
  on y056.cod_gama = y225.cod_gama
where 
  y44.lgort <> '1006'
  and y225.COD_GAMA in ('157', '158', '159')
  and y225.ativo = 'S'
  and y056.ativo = 'S'  
  --and l.lifnr = '0000600037'
order by
  vnd_cod

  /*VERSAO OLD 
select 
  distinct 
  l.vkorg, y44.werks, y44.lgort, 
  r.vnd_cod, r.vnd_nom, r.vnd_cpf, r.vnd_tipo, r.vnd_cod_sap, r.adrnr, r.vnd_email, r.FUNC_PAR, 
	r.endereco, r.responsavel, r.cep, r.contato, 
  
 from 
  `dados-prod.visoes_cimed_tech.CV_VIEW_REPRESENTANTES` as r
join
  `dados-prod.raw_cimed_tech.LIFNR_CLIENTE_T` l
  on l.lifnr = r.vnd_cod
join
  `dados-prod.raw.YDSD218` as y218 
  on y218.vkorg = l.vkorg
join
  `dados-prod.raw.YDSD044` y44
  on y44.werks = y218.werks
where 
  y44.lgort <> '1006'
  */