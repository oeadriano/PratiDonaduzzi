--CV_VIEW_PARTIDAS_ABERTO_IP
{
"query": {{ CONCAT("SELECT * FROM  dados-dev.visoes_auxiliares_cimed_tech.CV_VIEW_PARTIDAS_ABERTO_GERAL WHERE CLIENTE = '" , message.queryAndPath.cliente , "' " ) }},
"useLegacySql": false
}

{
"query": {{ CONCAT("SELECT * FROM  dados-dev.visoes_auxiliares_cimed_tech.CV_VIEW_PARTIDAS_ABERTO_GERAL WHERE LIFNR = '" , message.queryAndPath.lifnr , "' " ) }},
"useLegacySql": false
}


SELECT
	 "PEDIDO",
	 "VENCIMENTO",
	 "CODIGO_BARRAS",
	 "VALOR",
	 "STATUS",
	 "BUKRS", "GJAHR", "BELNR"
FROM 
    "_SYS_BIC"."CimedTech/CV_VIEW_PARTIDAS_ABERTO_IP"
    
     (PLACEHOLDER."$$IP_CLIENTE$$" => {{ message.queryAndPath.cliente }});

$.queryAndPath.[?(@.cliente)]

with w_lifnr as (
  select distinct lifnr, kunnr from dados-dev.raw_cimed_tech.LIFNR_CLIENTE_T
)
select 
    lifnr, 
    cliente, 
    pedido, 
    vencimento, 
    case
        when date(vencimento) <= date_add(current_date, interval -7 day) then ''
        else codigo_barras
    end as codigo_barras,
    valororiginal AS VALOR,
    case
        -- atrasado a mais de 7 dias é bloqueado
        when date(vencimento) <= date_add(current_date, interval -7 day) then 'BLOQUEADA'
        when date(vencimento) between date_add(current_date, interval -1 day) and date_add(current_date, interval -6 day) then 'VENCIDA'
        else 'A VENCER'     
    end as status
from 
    (
    SELECT 
        b.kunnr as cliente,
        lif.lifnr, 
        v.aubel as pedido, 
        cast(case
            -- zfbdt = null
            when coalesce(b.zfbdt, '') <> '' AND b.zbd3t  <> 0 then cast(date_add(PARSE_DATE("%Y%m%d",b.zfbdt),interval b.zbd3t day) as string)
            when coalesce(b.zfbdt, '') <> '' AND b.zbd3t = 0 AND b.zbd2t <> 0 then cast(date_add(PARSE_DATE("%Y%m%d",b.zfbdt),interval b.zbd2t day)as string)
            when coalesce(b.zfbdt, '') <> '' AND b.zbd3t = 0 AND b.zbd2t = 0  then cast(date_add(PARSE_DATE("%Y%m%d",b.zfbdt ),interval b.zbd1t day)as string)
            when coalesce(b.rebzg, '') <> '' AND b.SHKZG = 'H' then b.zfbdt
            when coalesce(b.rebzg, '') <> '' AND b.SHKZG = 'K' then b.zfbdt
          -- zfbdt > null
            when coalesce(b.zfbdt, '') = '' AND b.zbd3t <> 0 then cast(date_add(PARSE_DATE("%Y%m%d",b.bldat ),interval b.zbd3t day)as string)
            when coalesce(b.zfbdt, '') = '' AND b.zbd3t = 0 AND b.zbd2t <> 0 then cast(date_add(PARSE_DATE("%Y%m%d",b.bldat),interval b.zbd2t day)as string)
            when coalesce(b.zfbdt, '') = '' AND b.zbd3t = 0 AND b.zbd2t = 0  then cast(date_add(PARSE_DATE("%Y%m%d",b.bldat ), interval b.zbd1t day)as string)          
            when coalesce(b.rebzg, '') = '' AND b.SHKZG = 'H' then b.bldat
            when coalesce(b.rebzg, '') = '' AND b.SHKZG = 'K' then b.bldat
            else '0' end
        as string) as vencimento, 
        b.wrbtr as valororiginal,   
        bol.linhadigi as codigo_barras
    FROM dados-dev.raw.BSID AS b
    JOIN dados-dev.raw.BKPF AS k
        ON b.belnr = k.belnr
        AND b.bukrs = k.bukrs
        AND b.gjahr = k.gjahr
    JOIN 
        (
          select vbeln, vstel, aubel
          from dados-dev.raw.VBRP
          group by vbeln, vstel, aubel
        ) as v
        ON v.vbeln = b.belnr
    JOIN
        dados-dev.raw.KNKK as n
    ON  
     n.kunnr = b.kunnr
	JOIN 
		w_lifnr as lif
		ON lif.kunnr = n.kunnr     
    JOIN dados-dev.raw.YBCONTROLBOLETOS AS bol
        ON b.bukrs  = bol.bukrs
        AND b.gjahr = bol.gjahr
        AND b.belnr = bol.belnr
        AND b.buzei = bol.buzei         
    WHERE 
        B.MANDT = '500'
        and (b.blart <> 'DC' AND b.umskz <> 'Y')
        AND b.blart IN (SELECT low FROM `dados-dev.raw_cimed_tech.YDFI_PARITENS` WHERE name = 'RFC_PARTIDAS_DOCVENDA')
        AND b.shkzg = 'S'
        and coalesce(v.aubel, '') <> ''
)
order by vencimento