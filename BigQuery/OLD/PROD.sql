SELECT 
	DISTINCT
 	kna1.mandt as MANDT,
 	--knvv.vkorg as VKORG,
    '' as VKORG,  
    --kna1.zterm as CONDICAOPG, 
	'' as CONDICAOPG, 
    kna1.kunnr as CODIGO, 
    case when coalesce(kna1.cassd, '') = 'X' then 'X' else 'A' end as STATUS,
    case when coalesce(kna1.loevm, '') = 'X' then 'X' else 'A' end as FILTRO,
    substring(
    	case when coalesce(kna1.name2, '') = '' then kna1.name1
    	else kna1.name1||' ' ||kna1.name2
    end, 1, 254) as CLI_RZS, 
	substring(	
		case
    	when coalesce(kna1.name2, '') = '' then kna1.name1
    	else kna1.name1||' ' ||kna1.name2
    end, 1, 254) as NOME_FANTASIA, 
	kna1.stcd1 as CLI_CGC,
	kna1.stcd3 as CLI_INE,
	kna1.STCD4 as CLI_INS_MUNICIPAL,
    --kna1.stras  as CLI_END,
	adrc.street as CLI_END,
	adrc.house_num1 as CLI_NUM,
	adrc.house_num2  as CLI_COMPL,
	kna1.ort02    as CLI_BAI, 
    kna1.pstlz  as CLI_CEP,
	kna1.ort01      as CLI_CID, 
    kna1.regio  as CLI_EST,
	kna1.telf1      as CLI_TEL,
	kna1.telfx       as CLI_TEL2,
	adr6.smtp_addr as CLI_EMAIL, 
    coalesce (adrt.remark, '') as CLI_CNT, 
    coalesce(round(lim.limite,2),0) as CLI_LIMITE, 
    coalesce(round(lim.comprometido,2), 0) as CLI_LIMITE_CONSUMIDO,
    coalesce(cli_mix_op.oportunidade_plan,0) as oportunidade,
	coalesce(vnd_mes.valor_nf,0) as venda_mes,
    (select cast(descricao as int) from `dados-prod.raw.YDBI001` 
          where relatorio = 'MIX_PROD_PLANEJADO') as mix_planejado,
    coalesce(cli_mix_op.mix_real,0) as mix_realizado, 
    --case when coalesce(knvv.kdgrp, '') = '02' then 'S' else 'N' end as  FLAGDISTRIBUIDOR,
	--case when coalesce(knvv.kdgrp, '') = '04' then 'S' else 'N' end as  FLAGFARMACIA,
    '' as FLAGDISTRIBUIDOR, '' as FLAGFARMACIA, 
    coalesce(cli_alvaranumero.ATWRT,'')             as ALVARANUMERO,
    case 
        when CHAR_LENGTH(coalesce(cast(cli_ALVARADATA.ATFLV as string),'')) < 8 then ''
        else coalesce(cast(cli_ALVARADATA.ATFLV as string),'')
    end as ALVARADATA,
    coalesce(cli_ALVARANUMEROSANIT.ATWRT,'')        as ALVARANUMEROSANIT,
    case 
        when CHAR_LENGTH(coalesce(cast(cli_ALVARADATASANIT.ATFLV as string),'')) < 8 then ''
        else coalesce(cast(cli_ALVARADATASANIT.ATFLV as string),'')
    end as ALVARADATASANIT,
    'N' as FLAGOUTRATIV,
	'B' as TIPOCOBRANCA,
	--case when coalesce(knvv.pltyp, '') = '98' then 'S' else 'N' end as  FLAGZONAFRANCA,
    '' as FLAGZONAFRANCA,
    coalesce(cli_RESPTECNICONOME.ATWRT,'')           as RESPTECNICONOME,
    coalesce(cli_RESPTECNICOCRF.ATWRT,'')            as RESPTECNICOCRF,
    coalesce(cli_ALVARANUMEROSIVISA.ATWRT,'')        as ALVARANUMEROSIVISA,
    case 
        when CHAR_LENGTH(coalesce(cast(cli_ALVARADATASIVISA.ATFLV as string),'')) < 8 then ''
        else coalesce(cast(cli_ALVARADATASIVISA.ATFLV as string),'')
    end as ALVARADATASIVISA,
    coalesce(cli_CONTROLADO.ATWRT,'N') as CONTROLADO,
    case when coalesce(kna1.katr4, '') = '02' then 'S' else 'N' end as  CAIXA_FECHADA,
    case when (coalesce(tvast.vtext,'') = '' AND coalesce(kna1.ktokd,'') = 'ZMED' AND coalesce(cast(cli_ALVARADATASIVISA.ATFLV as string),'') = '') then 'ALVARA SIVISA'
    else coalesce(tvast.vtext,'') end as BLOQUEIO,    
    coalesce(kna1.ktokd,'') as GRUPO_CONTAS,
    case 
        when CHAR_LENGTH(coalesce(cast(cli_DATACRF.ATFLV as string),'')) < 8 then ''
        else coalesce(cast(cli_DATACRF.ATFLV as string),'')
    end as DATACRF,
    case when kna1.katr1 = 'BO' then 'S' else 'N' end as ACEITA_FALTA, 
    case when kna1.katr3 = 'TR' then 'S' else 'N' end as CROSSDOCKING, 
    coalesce(knkk.knkli, '') as CONTA_MATRIZ, 
    case when PARSE_DATE("%Y%m%d",ult.ultima_compra) >= DATE_ADD(current_date, interval -180 day) then 'S' else 'N' end as ATIVO, 
    coalesce(cli_NUMERO_AE.ATWRT,'') as NUMERO_AE,   
    coalesce(KNA1.KUKLA, '') as BU, 
	coalesce(kna1.BRAN1, '') as ASSOCIATIVISMO1,	
	coalesce(kna1.BRAN2, '') as ASSOCIATIVISMO2,
    coalesce(kna1.kdkg1, '') as COD_REDE, 
    coalesce(t.vtext, '') as NOME_REDE,
    coalesce(KNA1.XSUBT, '') as GRUSUBCLI,
    --i.id as DISTRIBUIDORAID,
	PARSE_TIMESTAMP("%Y%m%d %H%M%S", concat(kna1.UDATE, kna1.UTIME)) as UDATE,
	CURRENT_TIMESTAMP() as last_update,
	coalesce(knkk.ctlpc, '') as ctlpc,
	coalesce(kna1.aufsd, '') as aufsd
	--FORMAT_TIMESTAMP("%d/%m/%Y %H:%M:%S", CURRENT_TIMESTAMP()) as last_update
FROM 
	dados-prod.raw.KNA1 as kna1
--left join
    --dados-prod.raw.KNVV as knvv
    --on knvv.kunnr  = kna1.kunnr 
    --and knvv.mandt = kna1.mandt
left join 
	dados-prod.raw.KNKK as knkk
    on knkk.kunnr  = kna1.kunnr 
    and knkk.mandt = kna1.mandt
left join 
	(
	select 
		knkli, round(sum(klimk),2) as limite, round((sum(SKFOR) + sum(SSOBL) + sum(SAUFT)),2) as comprometido
	from dados-prod.raw.KNKK as knkk
    WHERE COALESCE(KLIMK,0)<> 0
	group by kunnr, knkli	
	ORDER BY KNKLI	
	) lim
	on lim.knkli = knkk.knkli 
left join
	dados-prod.raw_cimed_tech.TVKGG as g
	on g.kdkgr = kna1.kdkg1
	AND g.mandt = kna1.mandt	
left JOIN dados-prod.raw.TVKGGT AS t
	ON g.kdkgr = t.kdkgr
	AND g.mandt = t.mandt	
left join
	dados-prod.raw.ADRC as adrc
	on adrc.addrnumber        = kna1.adrnr 
	and adrc.client           = kna1.mandt
	and PARSE_DATE("%Y%m%d",adrc.date_to) >= current_date
left join 
	dados-prod.raw.ADR6 as adr6
	on adr6.addrnumber  = kna1.adrnr 
	and adr6.client     = kna1.mandt
	and adr6.FLGDEFAULT = 'X'
left join 
	dados-prod.raw.ADRT as adrt
	on adrt.addrnumber = kna1.adrnr 
left join 
	dados-prod.raw.TVAST as tvast
	on tvast.aufsp  = kna1.aufsd 
	and tvast.spras = 'P'  
	and tvast.mandt = kna1.mandt
left join 
	dados-prod.visoes_auxiliares_cimed_tech.CV_DIM_CLASSIF_CLIENTE  as cli_alvaranumero
	on cli_alvaranumero.mandt  = kna1.mandt
	and cli_alvaranumero.OBJEK = kna1.kunnr 
	and cli_alvaranumero.ATNAM = 'NR_ALVARA_ANVISA'
left join 
	dados-prod.visoes_auxiliares_cimed_tech.CV_DIM_CLASSIF_CLIENTE  as cli_ALVARADATA
	on  cli_ALVARADATA.mandt = kna1.mandt
	and cli_ALVARADATA.OBJEK = kna1.kunnr 
	and cli_ALVARADATA.ATNAM = 'DT_VENC_ALV_ANVISA'
left join 
	dados-prod.visoes_auxiliares_cimed_tech.CV_DIM_CLASSIF_CLIENTE  as cli_ALVARANUMEROSANIT
	on cli_ALVARANUMEROSANIT.mandt  = kna1.mandt
	and cli_ALVARANUMEROSANIT.OBJEK = kna1.kunnr 
	and cli_ALVARANUMEROSANIT.ATNAM = 'NR_ALVARA_ANVISA'
left join 
	dados-prod.visoes_auxiliares_cimed_tech.CV_DIM_CLASSIF_CLIENTE  as cli_ALVARADATASANIT
	on cli_ALVARADATASANIT.mandt  = kna1.mandt
	and cli_ALVARADATASANIT.OBJEK = kna1.kunnr 
	and cli_ALVARADATASANIT.ATNAM = 'DT_VENC_ALV_ANVISA'
left join 
	dados-prod.visoes_auxiliares_cimed_tech.CV_DIM_CLASSIF_CLIENTE  as cli_RESPTECNICONOME
	on cli_RESPTECNICONOME.mandt  = kna1.mandt
	and cli_RESPTECNICONOME.OBJEK = kna1.kunnr 
	and cli_RESPTECNICONOME.ATNAM = 'NOME_FARMACEUT_RESP'
left join 
	dados-prod.visoes_auxiliares_cimed_tech.CV_DIM_CLASSIF_CLIENTE  as cli_RESPTECNICOCRF
	on cli_RESPTECNICOCRF.mandt  = kna1.mandt
	and cli_RESPTECNICOCRF.OBJEK = kna1.kunnr 
	and cli_RESPTECNICOCRF.ATNAM = 'NR_CRF_FARM_RESP'
left join 
	dados-prod.visoes_auxiliares_cimed_tech.CV_DIM_CLASSIF_CLIENTE  as cli_ALVARANUMEROSIVISA
	on cli_ALVARANUMEROSIVISA.mandt  = kna1.mandt
	and cli_ALVARANUMEROSIVISA.OBJEK = kna1.kunnr 
	and cli_ALVARANUMEROSIVISA.ATNAM = 'NR_ALVARA_SIVISA'
left join 
	dados-prod.visoes_auxiliares_cimed_tech.CV_DIM_CLASSIF_CLIENTE  as cli_ALVARADATASIVISA
	on cli_ALVARADATASIVISA.mandt  = kna1.mandt
	and cli_ALVARADATASIVISA.OBJEK = kna1.kunnr 
	and cli_ALVARADATASIVISA.ATNAM = 'DT_VENC_ALV_SIVISA'
left join 
	dados-prod.visoes_auxiliares_cimed_tech.CV_DIM_CLASSIF_CLIENTE  as cli_CONTROLADO
	on cli_CONTROLADO.mandt  = kna1.mandt
	and cli_CONTROLADO.OBJEK = kna1.kunnr 
	and cli_CONTROLADO.ATNAM = 'AE_CONTROLADOS'
left join 
	dados-prod.visoes_auxiliares_cimed_tech.CV_DIM_CLASSIF_CLIENTE  as cli_NUMERO_AE
	on cli_CONTROLADO.mandt  = kna1.mandt
	and cli_CONTROLADO.OBJEK = kna1.kunnr 
	and cli_CONTROLADO.ATNAM = 'NUMERO_AE'	
left join 
	dados-prod.visoes_auxiliares_cimed_tech.CV_DIM_CLASSIF_CLIENTE  as NUMERO_AE
	on cli_CONTROLADO.mandt  = kna1.mandt
	and cli_CONTROLADO.OBJEK = kna1.kunnr 
	and cli_CONTROLADO.ATNAM = 'NUMERO_AE'	
left join 
	dados-prod.visoes_auxiliares_cimed_tech.CV_DIM_CLASSIF_CLIENTE  as cli_DATACRF
	on cli_DATACRF.mandt  = kna1.mandt
	and cli_DATACRF.OBJEK = kna1.kunnr 
	and cli_DATACRF.ATNAM = 'DT_VENC_CRF'
 left join
 	(
	select kunnr, max(erdat) as ultima_compra
	from dados-prod.raw.VBAK
	group by kunnr
	order by kunnr 	
 	) as ult 
 	on ult.kunnr = kna1.kunnr
left join
  (
  select
   q2.cliente
  ,case
     when count(*) = 3 then
       round((sum(valor_nf) / 3),2)
     when count(*) = 2 then
       round((sum(valor_nf) / 2),2)
     else
       round(sum(valor_nf),2)
   end as oportunidade_plan
  ,case
     when count(*) = 3 then
       cast(round((sum(mix) / 3),0) as int64)
     when count(*) = 2 then
       cast(round((sum(mix) / 2),0) as int64)
     else
       cast(round(sum(mix),0) as int64)
   end as mix_real
   
from (
select
   q1.cliente
  ,q1.anomes
  ,sum(q1.valor_nf) as valor_nf
  ,count(distinct q1.matnr) as mix
  ,ROW_NUMBER() OVER (PARTITION BY q1.cliente
                          ORDER BY q1.cliente
                                 ,left(q1.anomes,6) desc
                     ) AS LINHA
from( 
select
   venda.cliente
  ,left(venda.dt_fatur,6) as anomes
  ,sum(venda.valor_nf) as valor_nf
  ,venda.matnr
FROM `dados-prod.visoes_auxiliares_cimed_tech.CV_DASH_MV_VISAO` as venda
WHERE venda.cockpit          = 'Faturamento'
  and cast(left(venda.dt_fatur,6) as numeric) <  cast(substr(replace(cast(current_date() as string),'-',''),0,6) as numeric)
  and cast(left(venda.dt_fatur,6) as numeric) >= cast(substr(replace(cast(date_add(current_date(), interval -3 month)as string),'-',''),0,6) as numeric)
/*
  and cast(left(venda.dt_fatur,6) as numeric) <  cast(substr(replace(cast(date_add(current_date(), interval -3 month)as string),'-',''),0,6) as numeric)
  and cast(left(venda.dt_fatur,6) as numeric) >= cast(substr(replace(cast(date_add(current_date(), interval -6 month)as string),'-',''),0,6) as numeric)
*/
group by
   venda.cliente
  ,venda.matnr
  ,venda.dt_fatur
order by
   venda.cliente
  ,venda.dt_fatur desc
  
) as q1

group by
   q1.cliente
  ,q1.anomes
order by
   q1.cliente
  ,q1.anomes desc
) as q2
where q2.linha <= 3
group by q2.cliente
  ) as cli_mix_op
  on cli_mix_op.cliente  = kna1.kunnr 
left join (
select
   venda.cliente
  ,round(sum(venda.valor_nf),2) as valor_nf
FROM `dados-prod.visoes_auxiliares_cimed_tech.CV_DASH_MV_VISAO` as venda
WHERE venda.cockpit          = 'Faturamento'
  and cast(left(venda.dt_fatur,6) as numeric) = cast(substr(replace(cast(current_date() as string),'-',''),0,6) as numeric)
group by
   venda.cliente
order by
   venda.cliente
) as vnd_mes
  on vnd_mes.cliente  = kna1.kunnr 
--join
	--dados-prod.raw.YDSD218 as i
	--on i.vkorg = knvv.vkorg
--left join
--	(
--	SELECT
--		'ASS_OK' as ASS, ass1, ass2
--	FROM 
--	 dados-prod.visoes_auxiliares_cimed_tech.CV_VIEW_ZCO2_ASSOCIATIVISMO 		
--	) ass
--	on coalesce(ass.ass1, '') = coalesce(kna1.BRAN1, '')
--	and coalesce(ass.ass2, '') = coalesce(kna1.BRAN2, '')
--where 
	--knvv.vtweg in ( SELECT DISTINCT vtweg FROM dados-prod.raw_cimed_tech.YDSD056) 
	--and knvv.spart = '99'
	--and 
--    kna1.mandt = '500'
--	and coalesce(knkk.ctlpc, '') <> ''	
--	and kna1.aufsd  <> '01'	
    --and kna1.kunnr in ('0001079241')