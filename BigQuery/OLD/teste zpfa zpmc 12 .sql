select * from (
    SELECT 
         b.kschl as tabela, b.matnr as produto,         
        case 
            when b.PLTYP = '97' then '17.5'
            else b.PLTYP
        end as LISTA, 
        case 
            when b.PLTYP = '12' then a.kbetr
            else 0
        end as gen_12, 
        a.kbetr as valor
    FROM `dados-dev.raw.KONP` AS a 
        left JOIN `dados-dev.raw_cimed_tech.A954` AS b
        ON a.knumh = b.knumh
    WHERE a.loevm_ko <> 'X' -- marcado para exclusão
        AND (current_date between PARSE_DATE("%Y%m%d",b.datab) AND PARSE_DATE("%Y%m%d",b.datbi))
        and a.mandt = '500'  
        and b.kschl in ('ZPFA')
    union all 
    SELECT 
     b.kschl as tabela, b.matnr as produto, 
        case 
            when b.PLTYP = '97' then '17.5'
            else b.PLTYP
        end as LISTA, 
        case 
            when b.PLTYP = '12' then a.kbetr
            else 0
        end as gen_12, 
        a.kbetr as valor
    FROM `dados-dev.raw.KONP` AS a 
        left JOIN `dados-dev.raw_cimed_tech.A955` AS b
        ON a.knumh = b.knumh   
    WHERE a.loevm_ko <> 'X' -- marcado para exclusão
        AND (current_date between PARSE_DATE("%Y%m%d",b.datab) AND PARSE_DATE("%Y%m%d",b.datbi))
        and a.mandt = '500'  
        and b.kschl in ('ZPMC')	    
)
where  lista = '12'
order by  lista, produto