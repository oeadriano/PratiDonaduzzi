/*
1	 GENÉRICOS + EQ
2	 VITAMINAS + AL + SUP
3	 LANCAMENTO
4	 HB + OTC
5	 HOSPITALAR
*/
-- CV_INDICADORES_REP_CATEGORIA
-- dados-prod.sap_view.VB_TR_INDICADORES_REP_CATEGORIA
with w_oportunidade_categoria_realizado AS (
  SELECT
      DVENDA.VENDEDOR,
      SUM(DVENDA.VALOR_NF) AS VALOR_NF,
      MAT.CAT_INDICADORES
  FROM
      `dados-prod.sap.VH_TR_DASH_MV_VISAO_FAT`  AS DVENDA 
  JOIN 
    `dados-prod.sap.VH_MD_MATERIAL` AS MAT
    ON MAT.MATNR = DVENDA.MATNR
  WHERE
      DVENDA.COCKPIT IN ('Faturamento')
      AND DT_OV_D >= date_trunc(date_sub(current_date(), INTERVAL 3 month) , month)
      AND LEFT(DVENDA.DT_FATUR,6) = extract(YEAR from current_date) ||FORMAT('%02d', extract( MONTH from current_date))    
      AND DVENDA.VENDEDOR <> '?'
      AND COALESCE(DVENDA.VENDEDOR,'') <> ''
      AND DVENDA.VENDEDOR NOT LIKE 'H%' --
    AND COALESCE(DVENDA.AUGRU,'') <> 'ZBF' 
		AND DVENDA.DOC_TIPO in ('ZNOR', 'ZGOV', 'YTRI', 'ZV12')
  GROUP BY
      DVENDA.VENDEDOR, DVENDA.COCKPIT, MAT.CAT_INDICADORES
),
w_oportunidade_categoria as (
  select 
    vendedor, cat_indicador as cat_indicadores, vlr_oportunidade
  from `dados-prod.sap.VH_TR_METAS_CATEGORIA` 
  where  
    data = date_trunc(current_date(), month)
    --data = "2022-04-01"
),
w_comissao as (
  select 
    c.representante, 
    sum(c.comissao_atual)  as comissao_atual, 
    sum(comissao_anterior) as comissao_anterior,
    c.cat_indicadores, 
    vlr_oportunidade
  from 
    (SELECT  representante
            ,CAT_INDICADORES
            ,sum(COMISSAO_ATUAL)    as comissao_atual
            ,sum(COMISSAO_ANTERIOR) as comissao_anterior
       FROM `dados-prod.sap.VH_TR_INDICADORES_REP_MATERIAL` a
       left join `dados-prod.sap.VH_MD_MATERIAL` b
         on b.MATNR = a.material
       group by representante
               ,CAT_INDICADORES
    ) c
  left join
    w_oportunidade_categoria as op_cat
    on op_cat.vendedor = c.representante
   and op_cat.cat_indicadores = c.cat_indicadores
  group by 
    c.representante, c.cat_indicadores, vlr_oportunidade
)
select 
    op_cat.vendedor as REPRESENTANTE, 
    op_cat.CAT_INDICADORES, 
    FORMAT('%.2f',coalesce(ind.comissao_atual,0)) as COMISSSAO_ATUAL, 
    FORMAT('%.2f',coalesce(ind.comissao_anterior,0)) as COMISSAO_ANTERIOR, 
    FORMAT('%.2f',coalesce(ind.vlr_oportunidade, 0)) as VLR_OPORTUNIDADE,
    FORMAT('%.2f',coalesce(opr.VALOR_NF,0)) as OPORTUNIDADE_REALIZADO, 
    FORMAT('%.2f',case when opr.VALOR_NF > 0 and coalesce(ind.vlr_oportunidade, 0) > 0
        then (opr.VALOR_NF / ind.vlr_oportunidade) * 100  
        else 0 
    end) as PERC_OPORTUNIDADE,          
    case 
        when opr.VALOR_NF = 0 or coalesce(ind.vlr_oportunidade, 0) = 0 then '#FE0000' -- vermelho 'alert'    
        when opr.VALOR_NF > 0 and coalesce(ind.vlr_oportunidade, 0) > 0 and ((opr.VALOR_NF / coalesce(ind.vlr_oportunidade,1))*100) between 0 and 49.99 then '#FE0000' -- vermelho 'alert'
        when opr.VALOR_NF > 0 and coalesce(ind.vlr_oportunidade, 0) > 0 and ((opr.VALOR_NF / coalesce(ind.vlr_oportunidade,1))*100) between 0 and 49.99 then '#FE0000' -- vermelho 'alert'
        when opr.VALOR_NF > 0 and coalesce(ind.vlr_oportunidade, 0) > 0 and ((opr.VALOR_NF / coalesce(ind.vlr_oportunidade,1))*100) between 50 and 99.99 then '#FEC400' -- amarelo 'warning'
        when opr.VALOR_NF <= 0 then '#FE0000' -- vermelho 'alert'
        else '#24AA52' -- verde - ok
  end as COR,
  CURRENT_TIMESTAMP() as LAST_UPDATE
from 
  w_oportunidade_categoria as op_cat
left join 
    (
    select 
        representante, cat_indicadores, 
        sum(comissao_atual) as comissao_atual, 
        sum(comissao_anterior) as comissao_anterior,
        sum(vlr_oportunidade) as vlr_oportunidade 
    from w_comissao as atu
    group by 
        representante, cat_indicadores
    ) as ind  
    on ind.representante = op_cat.vendedor
   and ind.cat_indicadores = op_cat.cat_indicadores
LEFT JOIN 
  w_oportunidade_categoria_realizado AS opr
  on opr.vendedor = ind.representante
  and opr.cat_indicadores = ind.cat_indicadores