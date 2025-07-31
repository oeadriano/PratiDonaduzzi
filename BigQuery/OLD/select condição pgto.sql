-- consulta de combo
SELECT DISTINCT 
    VKORG, PRZ_MED, CODIGO, DESDOBRAMENTO, TIPO, QDE_PARCELAS, codigo_combo
FROM 
    `dados-dev.raw_cimed_tech.CV_COND_PGTO_IP_OFFLINE_T`    
WHERE 
    tipo = 'combo'
    and canal = '07'
    AND vkorg = '1000'
    and codigo_combo = '0022'

-- consulta geral 
SELECT DISTINCT 
    VKORG, PRZ_MED, CODIGO, DESDOBRAMENTO, TIPO, QDE_PARCELAS, codigo_combo
FROM 
    `dados-dev.raw_cimed_tech.CV_COND_PGTO_IP_OFFLINE_T`    
WHERE 
    (
        (    
            canal = '07'
            AND vkorg = '1000'            
            AND 800 between valor_de and valor_ate 
            AND 800 / qde_parcelas >= 250
            AND tipo = 'geral'
        )
        OR
        (    
            canal = '07'
            AND vkorg = '1000'
            AND 800 / qde_parcelas >= 250               
            AND cliente = '0001004775'        
        )
    )
    and tipo = 'combo'


