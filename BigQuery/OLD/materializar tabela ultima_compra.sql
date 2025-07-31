select * from dados-dev.raw_cimed_tech.CV_COND_PGTO_IP_T 

CREATE TABLE dados-dev.raw_cimed_tech.CV_COND_PGTO_IP_T as 
(
    SELECT DISTINCT 
        VKORG, VTWEG AS CANAL, VALOR_DE, VALOR_ATE,  PRZ_MED, CODIGO, DESDOBRAMENTO, TIPO, QDE_PARCELAS, 250 AS VALOR_PARCELA, 
        CLIENTE, '' as codigo_combo
    FROM 
        `dados-dev.visoes_cimed_tech.CV_COND_PGTO_IP` 
    union all 
    SELECT DISTINCT 
        VKORG, VTWEG AS CANAL, VALOR_DE, VALOR_ATE,  PRZ_MED, CODIGO, DESDOBRAMENTO, TIPO, QDE_PARCELAS, 250 AS VALOR_PARCELA, 
        CLIENTE, codigo_combo
    FROM 
        `dados-dev.visoes_cimed_tech.CV_COND_PGTO_IP_COMBO`
    ORDER BY 
        tipo, VKORG, CANAL, VALOR_DE, cliente
)

/*
select min(erdat),
    CAST(CONCAT(SUBSTR(ERDAT, 0 , 4), '-' ,SUBSTR(ERDAT, 5 , 2), '-' , SUBSTR(ERDAT, 7 , 2) ) AS DATE)  AS DT_OV_D, 
    DATETIME_SUB( 
        CAST(CONCAT(SUBSTR(ERDAT, 0 , 4), '-' ,SUBSTR(ERDAT, 5 , 2), '-' , SUBSTR(ERDAT, 7 , 2) ) AS DATE),
        INTERVAL 12 MONTH) as earlier
from `dados-dev.raw.VBAK` 
where 
    CAST(CONCAT(SUBSTR(ERDAT, 0 , 4), '-' ,SUBSTR(ERDAT, 5 , 2), '-' , SUBSTR(ERDAT, 7 , 2) ) AS DATE) >= 
    DATETIME_SUB( current_date, INTERVAL 1 MONTH) 
group by erdat