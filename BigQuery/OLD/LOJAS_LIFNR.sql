SELECT * FROM `dados-dev.visoes_cimed_tech.CONSULTA_LOJAS_GERAL` where kunnr = '0001086112' and lifnr = '0000604354'

SELECT * FROM  `dados-dev.visoes_cimed_tech.CV_A996_LOJAS_GERAL` where kunnr = '0001086112' and lifnr = '0000604354'


with w_wyt3 as (
    select LIFN2, lifnr
    from `dados-dev.raw.WYT3`
    where 
        ekorg = '1000'
        AND parvw = 'Y1'
        AND defpa = 'X'	
        ANd coalesce(LIFN2, '') <> ''
),
w_gama_produto as (
        select 
            cod_gama, matnr
        from 
            dados-dev.raw_cimed_tech.YDSD057 AS c 	
        where	
            ativo = 'S'
    ),
w_lif_cli as (
    SELECT 
        DISTINCT VKORG, KUNNR, LIFNR
    FROM
        dados-dev.raw_cimed_tech.LIFNR_CLIENTE_T
)
SELECT 
    DISTINCT A.BUKRS, A.COD_GAMA, T3.LIFNR as CADEIRA, T3.LIFN2 as LIFNR, 
    i.vkorg, lf.kunnr, b.descricao, b.vtweg, a.werks, y94.func_par, 
	CURRENT_TIMESTAMP as last_update
    --, c.matnr
FROM 
    dados-dev.raw_cimed_tech.YDSD225 AS a
JOIN 
    dados-dev.raw_cimed_tech.YDSD056 AS b
    ON a.cod_gama = b.cod_gama
JOIN 
    dados-dev.raw.YDSD218 AS i
    ON i.werks = a.werks
JOIN
    w_wyt3 as T3
    ON T3.lifnr = A.lifnr
join 
    w_lif_cli as lf
    ON LF.LIFNR = T3.LIFN2
    AND LF.VKORG = i.VKORG
join 
    dados-dev.raw.YDSD094 Y94
    ON LF.LIFNR = Y94.repr	
--	join	
--		w_gama_produto as c 
--		on c.cod_gama = b.cod_gama
WHERE 
    a.ativo = 'S' 
    AND b.ativo = 'S'
    and a.werks <> '1100'  
order by lifnr, kunnr    
