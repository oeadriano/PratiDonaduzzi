--CV_CADASTRO_MATERIAL


SELECT DISTINCT
	MAR.EAN11 as CODIGOBARRAS, 
	MAR.MATNR as CODIGO, 
	MAK.MAKTX as DESCRICAO, 
	coalesce(YDM.FICHA, '') as PRINCIPIOATIVO, 
	coalesce(case
		when MAR.SPART = '03' then 'S'
		else 'N'
	end, '')  as GENERICO, 
	coalesce(case
		when MVK.KONDM = '01' then 'N'
		when MVK.KONDM = '02' then 'P' 
		when MVK.KONDM = '03' then 'X'
 	 end
	, '') as LISTA, 	
	coalesce(MAT.ATWRT, '') as CODIGO_MS,
	coalesce(case
		when MAR.SPART = '01' then 'X'
		when MAR.SPART = '02' then 'C' 
		when MAR.SPART = '03' then 'G'   
		when MAR.SPART = '04' then 'P' 
		when MAR.SPART = '05' then 'S' 
		when MAR.SPART = '06' then 'T' 
		when MAR.SPART = '07' then 'H'
	end, '') as LINHA, 
	case
	 	when MAR.LVORM = 'X' then 'I'
	 	else 'A'
	end as STATUS, 
	coalesce(case 
		when CON.ATWRT = 'S' then 'S'
		else 'N'
		end 
	, '') as C_CONTROLADO,	
	MAR.MATKL as GRP_MERCADORIA, 
	COALESCE(HIE.BU_DESCR, 'CIMED') as FABRICANTE, 
	MAM.umrez as CAIXA_PADRAO, 
	'' as IPI, 
	'' as FARM_POPULAR, 
	'' as PROD_MARCA,
	'' as PROD_CLASSEI,
	'' as PROD_FATOR, 
	mc.steuc as NCM, 
	MAR.extwg as GRPMERCEXTERNO, 
	MAR.PRDHA as HIERARQUIA, 
	'/'||substring(MAR.PRDHA, 1, 3)|| 
	'/'||substring(MAR.PRDHA, 4, 3)|| 
	'/'||substring(MAR.PRDHA, 5, 3)||
	'/'||substring(MAR.PRDHA, 10, 3)||'/' as caminho
from 
	dados-dev.raw.MARA AS MAR
join
	dados-dev.raw.MAKT AS MAK
	on MAK.MANDT = MAR.MANDT 
	and MAK.MATNR = MAR.MATNR	
left join
	( select
		MANDT, MATNR, KONDM
	from
		dados-dev.raw_cimed_tech.MVKE
	where 
		 VTWEG in (SELECT VALOR from dados-dev.raw.YDBI001 WHERE RELATORIO ='CV_YDSD_MATERIAIS_MARA' 
		 AND FILTRO ='VTWEG')
		 AND MANDT = '500' 
		 AND VKORG = '3000'
	group by 
		MANDT, MATNR, KONDM
	) as MVK
	on MVK.MANDT = MAR.MANDT
	and MVK.MATNR = MAR.MATNR	
left join 
	dados-dev.raw_cimed_tech.YDMM_001 YDM
	on YDM.MANDT = MAR.MANDT
	and YDM.MATNR = MAR.MATNR		
left join
	dados-dev.visoes_auxiliares_cimed_tech.CV_DIM_CLASSIFIC_MAT MAT
	on MAT.MANDT = MAR.MANDT
	and MAT.OBJEK = MAR.MATNR 
	and MAT.ATNAM ='MAT_REGISTRO_MS'
	and MAR.MATKL not in ('PA11', 'PA12')
left join
	dados-dev.visoes_auxiliares_cimed_tech.CV_DIM_CLASSIFIC_MAT CON
	on CON.MANDT = MAR.MANDT
	and CON.OBJEK = MAR.MATNR 
	AND CON.ATNAM = 'MAT_CONTROLADO'		
left join 
	dados-dev.visoes_auxiliares_cimed_tech.CV_DIM_MAT_HIER_PROD HIE
	on HIE.MANDT = MAR.MANDT	
	and HIE.Cod_Material = CAST(MAR.MATNR AS INT)
left join 
	dados-dev.raw.MARM MAM
	on MAR.matnr = MAM.matnr 
	AND MAR.mtart IN ('FERT', 'HAWA', 'YMKT') 
	AND MAM.meinh = 'CX'    
	AND MAM.umren = 1
left join
	(SELECT COD_MAT
		 ,sum(cast(DISPONIVEL as integer)) as saldo
	-- FROM dados-dev.visoes_auxiliares_cimed_tech.CV_YDSD_ATUALIZAR_ESTOQUE_R
	from dados-dev.raw_cimed_tech.CV_YDSD_ATUALIZAR_ESTOQUE_T
	group by COD_MAT	
	) as est
	ON cast(mar.matnr as int) = cast(est.cod_mat as int)	     
join
	dados-dev.raw.MARC mc
	on mc.matnr = mar.matnr and mc.werks = '3000'
where
	MAR.MATKL in (SELECT LOW FROM dados-dev.raw.TVARVC WHERE NAME = 'YSD_MATKL' AND MANDT = '500')
	and MAR.MANDT = '500'
	and MAR.MSTAE in ('', 'Y5') 
	and MAR.MTPOS_MARA in ('YLOT', 'YMKT')
	and coalesce(MAR.EAN11, 'SEM GTIN') <> 'SEM GTIN'
	and coalesce(MAR.EAN11, '') <> ''
order by
	MAR.MATNR;
