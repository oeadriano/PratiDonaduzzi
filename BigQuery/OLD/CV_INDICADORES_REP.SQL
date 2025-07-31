5572469

-- cargar zip imagens bula ficha
	- ideia do luiz, é altera CF que faz leitura, para disponibilizar numa api a data da ultima alteração do zip

-- materialização
INSERT INTO raw_cimed_tech.CV_INDICADORES_REP_T
(SELECT * FROM dados-dev.visoes_cimed_tech.CV_INDICADORES_REP);

DELETE FROM raw_cimed_tech.CV_INDICADORES_REP_T
WHERE last_update < (SELECT MAX(last_update) from raw_cimed_tech.CV_INDICADORES_REP_T)

-- CV_INDICADORES_REP

with w_positivacao as (
  select 
      lifnr, sum(positivado) as positivado, sum(geral) as geral, 
      (sum(positivado) / sum(geral)*100) as percentual
  from 
      (        
      select 
          lifnr, count(*) as positivado, 0 as geral
      from 
          `dados-dev.raw_cimed_tech.REP_CLIENTES_IP_T` 
      where
          positivado = 'S'
      group by 
          lifnr
      union all
      select 
          lifnr, 0 positivado, count(*) * 0.70 as geral
          -- meta é atingir 70% da carteira do rep
      from 
          `dados-dev.raw_cimed_tech.REP_CLIENTES_IP_T` 
      group by     
          lifnr
      )
  group by
      lifnr    
  ),
w_dias as (
  select 
    (
      -- dias uteis do mes
      select count(*) from (
        select 
            last_day, extract(dayofweek from last_day) as a
        from 
            unnest(generate_date_array(date_trunc(current_date, month), last_day(current_date, month ))) last_day        
    ) where a not in (1, 7)
  ) as uteis_mes,   
  (
    -- dias uteis ate hoje
    select count(*) from (
      select 
          last_day, extract(dayofweek from last_day) as a
      from 
          unnest(generate_date_array(date_trunc(current_date, month), last_day(current_date, month ))) last_day        
      )  where a not in (1, 7) and last_day < current_date
  ) as uteis_hoje
),
w_ydsd125 as (
  select vendedor, objetivo, mix, freq, pos
  from `dados-dev.raw.YDSD125`      
  where 
    ANO = '2021' and mes = '12' 
    -- and vendedor = '0000604426'
    --ANO = cast(extract(month from current_date) as string)
    --and mes = FORMAT('%02d', extract( MONTH from current_date))    
),
w_dash_faturado as (
    SELECT
        DVENDA.VENDEDOR,
        ROUND(
            CASE
                WHEN DVENDA.COCKPIT = 'Faturamento' AND SUM(DVENDA.VALOR_NF) > 0 THEN COUNT(DISTINCT DVENDA.CHAVE_MIX) / COUNT(DISTINCT DVENDA.CLIENTE)
            ELSE
                0
            END,2) AS MIX_MEDIO
    FROM
        `dados-dev.raw_cimed_tech.CV_DASH_MV_VISAO_T`  AS DVENDA  
    WHERE
        DVENDA.COCKPIT IN ('Faturamento')
        AND LEFT(DVENDA.DT_FATUR,6) = extract(YEAR from current_date) ||FORMAT('%02d', extract( MONTH from current_date))    
        AND DVENDA.VENDEDOR <> '?'
        AND COALESCE(DVENDA.VENDEDOR,'') <> ''
        AND DVENDA.VENDEDOR NOT LIKE 'H%' --
    GROUP BY
        DVENDA.VENDEDOR, DVENDA.COCKPIT
),    
w_mix as (
    select 
      ind.VENDEDOR, ind.MIX_MEDIO as atual, y125.mix as total, (ind.MIX_MEDIO / y125.mix) * 100 as percentual
    from 
      w_dash_faturado as ind
    join 
      w_ydsd125 as y125
      on y125.vendedor = ind.VENDEDOR
),
w_dash_faseamento as (
    SELECT
        DVENDA.VENDEDOR, SUM(DVENDA.VALOR_NF) as VALOR_NF
    FROM
        `dados-dev.raw_cimed_tech.CV_DASH_MV_VISAO_T`  AS DVENDA  
    WHERE
        DVENDA.COCKPIT IN ('Faturamento')
        AND LEFT(DVENDA.DT_FATUR,6) = extract(YEAR from current_date) ||FORMAT('%02d', extract( MONTH from current_date))    
        AND DVENDA.VENDEDOR <> '?'
        AND COALESCE(DVENDA.VENDEDOR,'') <> ''
        AND DVENDA.VENDEDOR NOT LIKE 'H%' --
    GROUP BY
        DVENDA.VENDEDOR, DVENDA.COCKPIT
),  
w_faseamento as (
  select 
    f.VENDEDOR, f.valor_nf, y125.objetivo, 
    --calculo do faseamento
    y125.objetivo as fas_total, 
    (y125.objetivo - f.valor_nf) / (dias.uteis_mes - dias.uteis_hoje) as fas_dia, 
    (f.valor_nf / y125.objetivo) *100 as fas_percentual
  from 
    w_dash_faseamento as f 
  join
    w_ydsd125 as y125
    on y125.vendedor = f.VENDEDOR  
  cross join
    w_dias as dias
),
w_comissao_atu as (
  select 
    representante, sum(comissao_vlr) as comissao_vlr
  from 
    (
    select 
      distinct representante, doc_venda, doc_item, comissao_vlr
      from 
        `dados-dev.visoes_auxiliares.CV_OV_TAB_PRECO`
      where 
        substring(data_fat,1,6) = extract(YEAR from current_date) ||FORMAT('%02d', extract( MONTH from current_date))    
        and coalesce(representante,'') <> ''
        --and representante = '0000600037'  
    )
  group by 
    representante
),
w_comissao_ant as (
  select 
    representante, sum(comissao_vlr) as comissao_vlr
  from 
    (
    select 
      distinct representante, doc_venda, doc_item, comissao_vlr
      from 
        `dados-dev.visoes_auxiliares.CV_OV_TAB_PRECO`
      where 
        substring(data_fat,1,6) = extract(YEAR from date_sub(current_date, interval 1 month)) ||FORMAT('%02d', extract( MONTH from date_sub(current_date, interval 1 month)))    
        and coalesce(representante,'') <> ''
        --and representante = '0000600037'  
    )
  group by 
    representante  
),
w_comissao as (
	select 
		representante, sum(comissao_atual) as comissao_atual, sum(comissao_anterior) as comissao_anterior
	from (
		select 
			atu.representante, coalesce(atu.comissao_vlr,0) as comissao_atual, 0 as comissao_anterior, 
		from 
			w_comissao_atu as atu
		union all 
		select 
			ant.representante, 0 as comissao_atual, coalesce(ant.comissao_vlr,0) as comissao_anterior, 
		from 
			w_comissao_ant as ant
		)
	group by 
		representante
	),
w_rep_cli as (
    select  
      lifnr ,
        round(sum(credito_total),2)                      as credito_total
       ,round(sum(credito_consumido),2)                  as credito_consumido
       ,round(sum(oportunidade),2)                       as oportunidade
       ,round(sum(oportunidade_realizado),2)             as oportunidade_realizado
    from 
      `dados-dev.raw_cimed_tech.REP_CLIENTES_IP_T` as rep
    group by 
      lifnr
    )
select 
  rep.lifnr
  ,round(credito_total,2)                      as credito_total
  ,round(credito_consumido,2)                  as credito_consumido
  ,round(oportunidade,2)                       as oportunidade
  ,round(oportunidade_realizado,2)             as oportunidade_realizado
  ,comissao.comissao_atual
  ,comissao.comissao_anterior
  ,coalesce(mix.atual, 0) as mix_atual
  ,coalesce(mix.total, 0) as mix_total   
  ,coalesce(FORMAT('%.2f',mix.percentual), '0') as mix_percentual       
  -- '#FE0000' -- vermelho 'alert'
	-- '#FEC400' -- amarelo 'warning'
  -- '#24AA52' -- verde - ok
  ,case
    when mix.percentual between 0 and 49.99 then '#FE0000' -- vermelho 'alert'
    when mix.percentual between 50 and 99.99 then '#FEC400' -- amarelo 'warning'
    else '#24AA52' -- verde - ok
  end as mix_cor
  ,coalesce(FORMAT('%.2f',fas.valor_nf), '0') as faseamento_atual       
  ,coalesce(FORMAT('%.2f',fas.fas_dia), '0') as faseamento_dia
  ,coalesce(FORMAT('%.2f',fas.fas_percentual), '0') as faseamento_percentual
  ,coalesce(FORMAT('%.2f',fas.fas_total), '0') as fas_total       
  ,case
    when fas.fas_percentual between 0 and 49.99 then '#FE0000' -- vermelho 'alert'
    when fas.fas_percentual between 50 and 99.99 then '#FEC400' -- amarelo 'warning'
    else '#24AA52' -- verde - ok
  end as faseamento_cor
  ,pos.positivado as pos_atual
  ,pos.geral as pos_total
  ,coalesce(FORMAT('%.2f',pos.percentual), '0') as positivado_percentual
  ,case
    when pos.percentual between 0 and 49.99 then '#FE0000' -- vermelho 'alert'
    when pos.percentual between 50 and 99.99 then '#FEC400' -- amarelo 'warning'
    else '#24AA52' -- verde - ok
  end as positivado_cor
  ,CURRENT_TIMESTAMP() as last_update
from 
    w_rep_cli as rep
left join 
    w_comissao as comissao
    on comissao.representante = rep.lifnr
left join 
    w_mix as mix
    on mix.vendedor = rep.lifnr
left join 
  w_faseamento as fas
  on fas.vendedor = rep.lifnr
left join
  w_positivacao as pos
  on pos.lifnr = rep.lifnr
--where   rep.lifnr = '0000600037'
order by 
  lifnr
  