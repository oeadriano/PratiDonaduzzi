
-- update da materialização	
INSERT INTO raw_cimed_tech.CV_INDICADORES_REP_CATEGORIA_T
(SELECT * FROM dados-dev.visoes_cimed_tech.CV_INDICADORES_REP_CATEGORIA);

DELETE FROM raw_cimed_tech.CV_INDICADORES_REP_CATEGORIA_T
WHERE last_update < (SELECT MAX(last_update) from raw_cimed_tech.CV_INDICADORES_REP_CATEGORIA_T)

/*
1	 GENÉRICOS + EQ
2	 VITAMINAS + AL + SUP
3	 LANCAMENTO
4	 HB + OTC
5	 HOSPITALAR
*/
-- CV_INDICADORES_REP_CATEGORIA
with w_oportunidade_categoria_realizado AS (
  SELECT
      DVENDA.VENDEDOR,
      SUM(DVENDA.VALOR_NF) AS VALOR_NF,
      MAT.CAT_INDICADORES
  FROM
      `dados-dev.raw_cimed_tech.CV_DASH_MV_VISAO_T`  AS DVENDA 
  JOIN 
    `dados-dev.raw_cimed_tech.CV_CADASTRO_MATERIAL_T` AS MAT
    ON MAT.CODIGO = DVENDA.MATNR
  WHERE
      DVENDA.COCKPIT IN ('Faturamento')
      AND LEFT(DVENDA.DT_FATUR,6) = extract(YEAR from current_date) ||FORMAT('%02d', extract( MONTH from current_date))    
      AND DVENDA.VENDEDOR <> '?'
      AND COALESCE(DVENDA.VENDEDOR,'') <> ''
      AND DVENDA.VENDEDOR NOT LIKE 'H%' --
      --and doc_venda in ('0004784803', '0004784801')                      
  GROUP BY
      DVENDA.VENDEDOR, DVENDA.COCKPIT, MAT.CAT_INDICADORES
),
w_oportunidade_categoria as (
  select 
    vendedor, 
      GEN_EQ, HB_OTC, LANCTO, VIT_AL_SUP
  from `dados-dev.raw.YDSD125` 
  where  
    ANO = '2021' and mes = '12' 
    --ANO = cast(extract(month from current_date) as string)
    --and mes = FORMAT('%02d', extract( MONTH from current_date)) 
    --and vendedor = '0000603665'    
),
w_comissao_atu as (
  select 
    c.representante, sum(c.comissao_vlr) as comissao_vlr, c.cat_indicadores, 
    case 
        when c.cat_indicadores = 'GENÉRICOS + EQ' then GEN_EQ
        when c.cat_indicadores = 'VITAMINAS + AL + SUP' then VIT_AL_SUP
        when c.cat_indicadores = 'HB + OTC' then HB_OTC
        when c.cat_indicadores = 'LANCAMENTO' then LANCTO
    end as vlr_oportunidade
  from 
    (
    select 
      distinct representante, doc_venda, doc_item, comissao_vlr, cat_indicadores
      from 
        `dados-dev.visoes_auxiliares.CV_OV_TAB_PRECO`
    where 
    substring(data_fat,1,6) = extract(YEAR from current_date) ||FORMAT('%02d', extract( MONTH from current_date))    
    and coalesce(representante,'') <> ''
    --and representante = '0000604426'
    --and doc_venda in ('0004784803', '0004784801')                
    ) c
  left join
    w_oportunidade_categoria as op_cat
    on op_cat.vendedor = c.representante
  group by 
    c.representante, c.cat_indicadores, 
    GEN_EQ, HB_OTC, LANCTO, VIT_AL_SUP
),
w_comissao_ant as (
  select 
    representante, sum(comissao_vlr) as comissao_vlr, cat_indicadores
  from 
    (
    select 
      distinct representante, doc_venda, doc_item, comissao_vlr, cat_indicadores
      from 
        `dados-dev.visoes_auxiliares.CV_OV_TAB_PRECO`
      where 
        substring(data_fat,1,6) = extract(YEAR from date_sub(current_date, interval 1 month)) ||FORMAT('%02d', extract( MONTH from date_sub(current_date, interval 1 month)))    
        and coalesce(representante,'') <> ''
        --and representante = '0000604426'  
    )
  group by 
    representante, cat_indicadores
)
select 
    ind.representante, ind.cat_indicadores, 
    FORMAT('%.2f',ind.comissao_atual) as comissao_atual, 
    FORMAT('%.2f',ind.comissao_anterior) as comissao_anterior, 
    coalesce(ind.vlr_oportunidade, 0) as vlr_oportunidade, 
    FORMAT('%.2f',coalesce(opr.VALOR_NF,0)) as oportunidade_realizado, 
    FORMAT('%.2f',case when opr.VALOR_NF > 0 and coalesce(ind.vlr_oportunidade, 0) > 0
        then (opr.VALOR_NF / ind.vlr_oportunidade) * 100  
        else 0 
    end) as perc_oportunidade,          
    case 
        when opr.VALOR_NF = 0 or coalesce(ind.vlr_oportunidade, 0) = 0 then '#FE0000' -- vermelho 'alert'    
        when opr.VALOR_NF > 0 and coalesce(ind.vlr_oportunidade, 0) > 0 and ((opr.VALOR_NF / coalesce(ind.vlr_oportunidade,1))*100) between 0 and 49.99 then '#FE0000' -- vermelho 'alert'
        when opr.VALOR_NF > 0 and coalesce(ind.vlr_oportunidade, 0) > 0 and ((opr.VALOR_NF / coalesce(ind.vlr_oportunidade,1))*100) between 0 and 49.99 then '#FE0000' -- vermelho 'alert'
        when opr.VALOR_NF > 0 and coalesce(ind.vlr_oportunidade, 0) > 0 and ((opr.VALOR_NF / coalesce(ind.vlr_oportunidade,1))*100) between 50 and 99.99 then '#FEC400' -- amarelo 'warning'
        when opr.VALOR_NF <= 0 then '#FE0000' -- vermelho 'alert'
        else '#24AA52' -- verde - ok
  end as cor,
  CURRENT_TIMESTAMP() as last_update
from 
    (
    select 
        representante, cat_indicadores, 
        sum(comissao_atual) as comissao_atual, 
        sum(comissao_anterior) as comissao_anterior,
        vlr_oportunidade
    from (
        select 
            atu.representante, cat_indicadores, coalesce(atu.comissao_vlr,0) as comissao_atual, 0 as comissao_anterior, vlr_oportunidade
        from 
            w_comissao_atu as atu
        union all 
        select 
            ant.representante, cat_indicadores, 0 as comissao_atual, coalesce(ant.comissao_vlr,0) as comissao_anterior, 0 as vlr_oportunidade
        from 
            w_comissao_ant as ant
        )
    group by 
        representante, cat_indicadores, vlr_oportunidade
    ) as ind
LEFT JOIN 
  w_oportunidade_categoria_realizado AS opr
  on opr.vendedor = ind.representante
  and opr.cat_indicadores = ind.cat_indicadores
--where 
--  ind.representante = '0000604426'