-- CV_VIEW_CADASTRO_CLIENTE
WITH LIF AS (
	-- substituir pela tabela materializada
	SELECT * FROM `dados-dev.visoes_auxiliares_cimed_tech.CV_VIEW_LIFNR_CLIENTE` 
)
SELECT 
	DISTINCT
 	knb1.mandt as MANDT,
	lif.lifnr, 
 	knvv.vkorg as VKORG,
    knb1.zterm as CONDICAOPG, 
    knb1.kunnr as CODIGO, 
    case when coalesce(kna1.cassd, '') = 'X' then 'X' else 'A' end as STATUS,
    case when coalesce(kna1.loevm, '') = 'X' then 'X' else 'A' end as FILTRO,
    kna1.name1  as CLI_RZS,
	kna1.name2      as NOME_FANTASIA,
	kna1.stcd1 as CLI_CGC,
	kna1.stcd3      as CLI_INE,
    kna1.stras  as CLI_END,
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
    coalesce(lim.limite,0) as CLI_LIMITE, 
    coalesce(lim.comprometido, 0) as CLI_LIMITE_CONSUMIDO,
    case when coalesce(knvv.kdgrp, '') = '02' then 'S' else 'N' end as  FLAGDISTRIBUIDOR,
	case when coalesce(knvv.kdgrp, '') = '04' then 'S' else 'N' end as  FLAGFARMACIA,
    coalesce(cli_alvaranumero.ATWRT,'')             as ALVARANUMERO,
    coalesce(cast(cli_ALVARADATA.ATFLV as string),'')      as ALVARADATA,
    coalesce(cli_ALVARANUMEROSANIT.ATWRT,'')        as ALVARANUMEROSANIT,
    coalesce(cast(cli_ALVARADATASANIT.ATFLV as string),'') as ALVARADATASANIT,
	'N' as FLAGOUTRATIV,
	'B' as TIPOCOBRANCA,
	case when coalesce(knvv.pltyp, '') = '98' then 'S' else 'N' end as  FLAGZONAFRANCA,
    coalesce(cli_RESPTECNICONOME.ATWRT,'')           as RESPTECNICONOME,
    coalesce(cli_RESPTECNICOCRF.ATWRT,'')            as RESPTECNICOCRF,
    coalesce(cli_ALVARANUMEROSIVISA.ATWRT,'')        as ALVARANUMEROSIVISA,
    coalesce(cast(cli_ALVARADATASIVISA.ATFLV as string),'') as ALVARADATASIVISA,
    coalesce(cli_CONTROLADO.ATWRT,'')                as CONTROLADO,
    case when coalesce(kna1.katr4, '') = '02' then 'S' else 'N' end as  CAIXA_FECHADA,
    case when (coalesce(tvast.vtext,'') = '' AND coalesce(kna1.ktokd,'') = 'ZMED' AND coalesce(cast(cli_ALVARADATASIVISA.ATFLV as string),'') = '') then 'ALVARA SIVISA'
    else coalesce(tvast.vtext,'') end as BLOQUEIO,    
    coalesce(kna1.ktokd,'') as GRUPO_CONTAS,
    coalesce(cast(cli_DATACRF.ATFLV as string),'') as DATACRF, 
    case when kna1.katr1 = 'BO' then 'S' else 'N' end as ACEITA_FALTA, 
    case when kna1.katr3 = 'TR' then 'S' else 'N' end as CROSSDOCKING, 
    coalesce(knkk.knkli, '') as CONTA_MATRIZ, 
    case when PARSE_DATE("%Y%m%d",ult.ultima_compra) >= DATE_ADD(current_date, interval -180 day) then 'S' else 'N' end as ATIVO, 
    coalesce(cli_NUMERO_AE.ATWRT,'') as NUMERO_AE,   
    coalesce(KNA1.KUKLA, '') as BU, 
	coalesce(kna1.BRAN1, '') as ASSOCIATIVISMO1,	
	coalesce(kna1.BRAN2, '') as ASSOCIATIVISMO2,
    --coalesce(case when coalesce(ass.ass,'')= 'ASS_OK' 
    	--then coalesce(kna1.BRAN1, '') 
    --end, '') as ASSOCIATIVISMO1,
    --coalesce(case
    	--when coalesce(ass.ass,'')= 'ASS_OK' 
    	--then coalesce(kna1.BRAN2, '') 
    --end, '') as ASSOCIATIVISMO2,    

    coalesce(kna1.kdkg1, '') as COD_REDE, 
    coalesce(t.vtext, '') as NOME_REDE,
    coalesce(KNA1.XSUBT, '') as GRUSUBCLI,
    i.id as DISTRIBUIDORAID
FROM 
	dados-dev.raw.KNB1 as knb1
left join
    dados-dev.raw.KNVV as knvv
    on knvv.kunnr  = knb1.kunnr 
    and knvv.mandt = knb1.mandt
JOIN LIF 
	on lif.vkorg = knvv.vkorg
	and lif.kunnr = knb1.kunnr
left join 
	dados-dev.raw.KNKK as knkk
    on knkk.kunnr  = knb1.kunnr 
    and knkk.mandt = knb1.mandt
left join 
	(
	select 
		knkli, sum(klimk) as limite, (sum(SKFOR) + sum(SSOBL) + sum(SAUFT)) as comprometido
	from dados-dev.raw.KNKK as knkk
    WHERE COALESCE(KLIMK,0)<> 0
	group by kunnr, knkli	
	ORDER BY KNKLI	
	) lim
	on lim.knkli = knkk.knkli 
left join 
	dados-dev.raw.KNA1 as kna1
	on knb1.kunnr  = kna1.kunnr 
	and knb1.mandt = kna1.mandt
left join
	dados-dev.raw_cimed_tech.TVKGG as g
	on g.kdkgr = kna1.kdkg1
	AND g.mandt = kna1.mandt	
left JOIN dados-dev.raw.TVKGGT AS t
	ON g.kdkgr = t.kdkgr
	AND g.mandt = t.mandt	
left join
	dados-dev.raw.ADRC as adrc
	on adrc.addrnumber        = kna1.adrnr 
	and adrc.client           = kna1.mandt
	and PARSE_DATE("%Y%m%d",adrc.date_to) >= current_date
left join 
	dados-dev.raw.ADR6 as adr6
	on adr6.addrnumber  = kna1.adrnr 
	and adr6.client     = kna1.mandt
	and adr6.FLGDEFAULT = 'X'
left join 
	dados-dev.raw.ADRT as adrt
	on adrt.addrnumber = kna1.adrnr 
left join 
	dados-dev.raw.TVAST as tvast
	on tvast.aufsp  = kna1.aufsd 
	and tvast.spras = 'P'  
	and tvast.mandt = kna1.mandt
left join 
	dados-dev.visoes_auxiliares_cimed_tech.CV_DIM_CLASSIF_CLIENTE  as cli_alvaranumero
	on cli_alvaranumero.mandt  = knb1.mandt
	and cli_alvaranumero.OBJEK = kna1.kunnr 
	and cli_alvaranumero.ATNAM = 'NR_ALVARA_ANVISA'
left join 
	dados-dev.visoes_auxiliares_cimed_tech.CV_DIM_CLASSIF_CLIENTE  as cli_ALVARADATA
	on  cli_ALVARADATA.mandt = knb1.mandt
	and cli_ALVARADATA.OBJEK = kna1.kunnr 
	and cli_ALVARADATA.ATNAM = 'DT_VENC_ALV_ANVISA'
left join 
	dados-dev.visoes_auxiliares_cimed_tech.CV_DIM_CLASSIF_CLIENTE  as cli_ALVARANUMEROSANIT
	on cli_ALVARANUMEROSANIT.mandt  = knb1.mandt
	and cli_ALVARANUMEROSANIT.OBJEK = kna1.kunnr 
	and cli_ALVARANUMEROSANIT.ATNAM = 'NR_ALVARA_ANVISA'
left join 
	dados-dev.visoes_auxiliares_cimed_tech.CV_DIM_CLASSIF_CLIENTE  as cli_ALVARADATASANIT
	on cli_ALVARADATASANIT.mandt  = knb1.mandt
	and cli_ALVARADATASANIT.OBJEK = kna1.kunnr 
	and cli_ALVARADATASANIT.ATNAM = 'DT_VENC_ALV_ANVISA'
left join 
	dados-dev.visoes_auxiliares_cimed_tech.CV_DIM_CLASSIF_CLIENTE  as cli_RESPTECNICONOME
	on cli_RESPTECNICONOME.mandt  = knb1.mandt
	and cli_RESPTECNICONOME.OBJEK = kna1.kunnr 
	and cli_RESPTECNICONOME.ATNAM = 'NOME_FARMACEUT_RESP'
left join 
	dados-dev.visoes_auxiliares_cimed_tech.CV_DIM_CLASSIF_CLIENTE  as cli_RESPTECNICOCRF
	on cli_RESPTECNICOCRF.mandt  = knb1.mandt
	and cli_RESPTECNICOCRF.OBJEK = kna1.kunnr 
	and cli_RESPTECNICOCRF.ATNAM = 'NR_CRF_FARM_RESP'
left join 
	dados-dev.visoes_auxiliares_cimed_tech.CV_DIM_CLASSIF_CLIENTE  as cli_ALVARANUMEROSIVISA
	on cli_ALVARANUMEROSIVISA.mandt  = knb1.mandt
	and cli_ALVARANUMEROSIVISA.OBJEK = kna1.kunnr 
	and cli_ALVARANUMEROSIVISA.ATNAM = 'NR_ALVARA_SIVISA'
left join 
	dados-dev.visoes_auxiliares_cimed_tech.CV_DIM_CLASSIF_CLIENTE  as cli_ALVARADATASIVISA
	on cli_ALVARADATASIVISA.mandt  = knb1.mandt
	and cli_ALVARADATASIVISA.OBJEK = kna1.kunnr 
	and cli_ALVARADATASIVISA.ATNAM = 'DT_VENC_ALV_SIVISA'
left join 
	dados-dev.visoes_auxiliares_cimed_tech.CV_DIM_CLASSIF_CLIENTE  as cli_CONTROLADO
	on cli_CONTROLADO.mandt  = knb1.mandt
	and cli_CONTROLADO.OBJEK = kna1.kunnr 
	and cli_CONTROLADO.ATNAM = 'AE_CONTROLADOS'
left join 
	dados-dev.visoes_auxiliares_cimed_tech.CV_DIM_CLASSIF_CLIENTE  as cli_NUMERO_AE
	on cli_CONTROLADO.mandt  = knb1.mandt
	and cli_CONTROLADO.OBJEK = kna1.kunnr 
	and cli_CONTROLADO.ATNAM = 'NUMERO_AE'	
left join 
	dados-dev.visoes_auxiliares_cimed_tech.CV_DIM_CLASSIF_CLIENTE  as NUMERO_AE
	on cli_CONTROLADO.mandt  = knb1.mandt
	and cli_CONTROLADO.OBJEK = kna1.kunnr 
	and cli_CONTROLADO.ATNAM = 'NUMERO_AE'	
left join 
	dados-dev.visoes_auxiliares_cimed_tech.CV_DIM_CLASSIF_CLIENTE  as cli_DATACRF
	on cli_DATACRF.mandt  = knb1.mandt
	and cli_DATACRF.OBJEK = kna1.kunnr 
	and cli_DATACRF.ATNAM = 'DT_VENC_CRF'
 left join
 	(
	select kunnr, max(erdat) as ultima_compra
	from dados-dev.raw.VBAK
	group by kunnr
	order by kunnr 	
 	) as ult 
 	on ult.kunnr = knvv.kunnr	
join
	dados-dev.raw.YDSD218 as i
	on i.vkorg = knvv.vkorg
--left join
--	(
--	SELECT
--		'ASS_OK' as ASS, ass1, ass2
--	FROM 
--	 dados-dev.visoes_auxiliares_cimed_tech.CV_VIEW_ZCO2_ASSOCIATIVISMO 		
--	) ass
--	on coalesce(ass.ass1, '') = coalesce(kna1.BRAN1, '')
--	and coalesce(ass.ass2, '') = coalesce(kna1.BRAN2, '')
where 
	knvv.vtweg in ( SELECT DISTINCT vtweg FROM dados-dev.raw_cimed_tech.YDSD056) 
	and knvv.spart = '99'
	and knb1.mandt = '500'
	and coalesce(knkk.ctlpc, '') <> ''	
	and kna1.aufsd  <> '01'	
	--and knb1.kunnr = '0001056644'
	--and lif.lifnr = '0000601100'

