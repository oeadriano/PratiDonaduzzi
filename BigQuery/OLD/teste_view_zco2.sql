with 
lif as (
        select distinct l.lifnr, l.vkorg, y94.func_par 
        from `dados-dev.raw_cimed_tech.LIFNR_CLIENTE_T` l
        join `dados-dev.raw.YDSD094` y94 
        on y94.repr = l.lifnr
        ),
gama_autorizacoes as (
    SELECT
          DISTINCT A.BUKRS,
          A.WERKS,
          A.COD_GAMA,
          CAST(T3.LIFN2 AS string) AS LIFNR,
          i.vkorg
        FROM
          dados-dev.raw_cimed_tech.YDSD225 AS a
        JOIN
          dados-dev.raw_cimed_tech.YDSD056 AS b
        ON
          a.cod_gama = b.cod_gama
        LEFT JOIN
          dados-dev.raw.YDSD218 AS i
        ON
          i.werks = a.werks
        LEFT JOIN
          dados-dev.raw.WYT3 T3
        ON
          T3.lifnr = A.lifnr
          AND T3.ekorg = '1000'
          AND T3.parvw = 'Y1'
          AND T3.defpa = 'X'
        WHERE
          a.ativo = 'S'
          AND b.ativo = 'S'
          AND coalesce(T3.LIFN2,
            '') <> ''
          AND a.werks <> '1100'    
),
zco2 as (
    SELECT * FROM `dados-dev.visoes_auxiliares_cimed_tech.teste_zco2_t` 
    order by func_par, vkorg, produto, faixa
)
select 
    l.lifnr, l.vkorg, l.func_par, z.faixa, z.produto, z.valor, z.perc_comis
from lif as l
join gama_autorizacoes as g
    on g.lifnr  = l.lifnr 
    and g.vkorg = l.vkorg
join zco2 as z 
    on z.vkorg = l.vkorg 
    and z.func_par = l.func_par
--where 
    --l.lifnr = '0000601029'
order by 
    z.func_par, z.vkorg, z.produto, z.faixa