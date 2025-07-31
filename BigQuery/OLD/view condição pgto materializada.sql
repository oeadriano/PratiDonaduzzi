
SELECT DISTINCT 
    VKORG, PRZ_MED, CODIGO, DESDOBRAMENTO, TIPO, QDE_PARCELAS, codigo_combo
FROM 
    --dados-dev.raw_cimed_tech.CV_COND_PGTO_IP_T
    dados-dev.visoes_cimed_tech.CV_COND_PGTO_IP 
WHERE 
    (
        (    vtweg = '07'
        AND 3100 between valor_de and valor_ate 
        AND vkorg = '1000'
        AND 3100 / qde_parcelas >= (select 250)                
        AND cliente = ''        
        )
        OR
        (    vtweg = '07'
        AND vkorg = '1000'
        AND 3100 / qde_parcelas >= (select 250)                
        AND cliente = '0001004775'        
        )
    )
    and tipo <> 'combo'


CREATE TABLE dados-dev.raw_cimed_tech.CV_COND_PGTO_IP_OFFLINE_T as 
(
    SELECT DISTINCT 
        VKORG, VTWEG AS CANAL, VALOR_DE, VALOR_ATE,  PRZ_MED, CODIGO, DESDOBRAMENTO, TIPO, QDE_PARCELAS, 250 AS VALOR_PARCELA, 
        CLIENTE, codigo_combo
    FROM 
        `dados-dev.visoes_cimed_tech.CV_COND_PGTO_IP_OFFLINE` 
)


--CV_COND_PGTO_IP
with w_cond_combo as (
	SELECT
		id as codigo_combo, codcondicaopagamento__c as condicao
	FROM
		EXTERNAL_QUERY("projects/dados-dev/locations/us/connections/cimed-postgres-us", "SELECT * from sf.cadastrocombo_condpg__c")
), w_kna1 as (
    select 
        kunnr, kdkg1
    from 
        dados-dev.raw.KNA1
),w_ydbi008 as (
    select y8.przmedio, y8.zterm 
    from dados-dev.raw.YDBI008 as y8
), 
w_ydsd003 as (
    select 
        y3.codigo, y3.org_vendas, y3.canal_distribuicao, y3.exc_rede,
		y3.exc_cliente, y3.rfc_combo, y3.descricao, y3.qde_parcelas
    from 
        dados-dev.raw_cimed_tech.YDSD003 y3
    where 
        length(ltrim(y3.descricao,' +-.0123456789/')) = 0
        -- AEO 04.01.22 filtro de inativos
        and coalesce(inativo, '') = ''
		and y3.canal_distribuicao in ('07', '10')				
),
w_ydsd005 as (
    select 
        y5.vkorg, y5.vtweg, y5.kdkg1_de, y5.kdkg1_ate, y5.przmed
    from 
        dados-dev.raw_cimed_tech.YDSD005 y5
)
SELECT
  vkorg,
  vtweg,
  valor_de,
  valor_ate ,
  cast(prz_med as integer) as prz_med,
  codigo,
  desdobramento ,
  qde_parcelas,
  tipo,
  cliente, 
  codigo_combo
from (
		select 
		distinct
		y5.vkorg, y5.vtweg, 
		cast(y5.kdkg1_de as numeric) as valor_de, 
		cast(y5.kdkg1_ate as numeric) as valor_ate, 
		cast(y8.przmedio as integer) as prz_med, 
		y8.zterm AS CODIGO, 
		y3.descricao as desdobramento, 
		y3.qde_parcelas, 
		'geral' as tipo, 
		'' as cliente, 
		'' as codigo_combo	
	from
		w_ydsd005 as y5
	join
		w_ydbi008 as y8
		on y8.przmedio <= cast(y5.przmed as int)
	join
		w_ydsd003 as y3 
		on y3.codigo = y8.zterm
		and y3.org_vendas = y5.vkorg
		and y3.canal_distribuicao = y5.vtweg
	where	
		coalesce(y3.exc_rede, '') = '' -- X é exclusivo rede
		and coalesce(y3.exc_cliente, '') = '' -- X é exclusivo cliente
		and coalesce(y3.rfc_combo, '') = '' -- X é exclusivo combo		
	union all
	-- condição da rede 
	-- o union com kna1 abaixo, vai trazer o codigo do cliente para filtrar
	-- na clausula where do pipeline
	select 
		distinct
		y4.vkorg, y3.canal_distribuicao as vtweg, 
		cast(0.01 as numeric) as valor_de, 
		cast(999999.99 as numeric) as valor_ate, 
		cast(999 as integer) as prz_med, 		
		y3.codigo, y3.descricao as desdobramento, 
		y3.qde_parcelas, 
		--'rede: ' || cast(k.kdkg1 as string) as tipo, 
		'rede' as tipo, 		
		k.kunnr as cliente, 
		'' as codigo_combo
	from
		dados-dev.raw_cimed_tech.YDSD004 as y4
	join	
		w_ydsd003 as y3 
		on y3.org_vendas = y4.vkorg
		and y3.canal_distribuicao = y4.vtweg
		and y3.codigo = y4.zterm
	join w_kna1 k
		on k.kdkg1 = y4.kdkg1
	where	
		cast(current_date as string) between y4.DESDE and y4.ate
		and coalesce(y3.exc_rede, '') = 'X' -- X é exclusivo rede
		and coalesce(y3.exc_cliente, '') = '' -- X é exclusivo cliente
		and coalesce(y3.rfc_combo, '') = '' -- X é exclusivo combo	
	union all
	-- condição da cliente
	select 
		distinct
		y224.vkorg, y3.canal_distribuicao as vtweg,  
		cast(0.01 as numeric) as valor_de, 
		cast(999999 as numeric) as valor_ate, 
		cast(999 as integer) as prz_med, 
		y3.codigo, y3.descricao as desdobramento, y3.qde_parcelas,
		--'cliente: ' || cast(k.kunnr as string) as tipo, 
		'cliente' as tipo, 		
		y224.kunnr as cliente, 
		'' as codigo_combo
	from
		dados-dev.raw_cimed_tech.YDSD224 as y224
	join	
		w_ydsd003 as y3 
		on y3.org_vendas = y224.vkorg
		and y3.canal_distribuicao = y224.vtweg
		and y3.codigo = y224.CONDPG
	join w_kna1 k
		on k.kunnr = y224.kunnr
	where	
		cast(current_date as string) between y224.DATADE and y224.DATAate
		and coalesce(y3.exc_cliente, '') = 'X' -- X é exclusivo cliente
		and coalesce(y3.rfc_combo, '') = '' -- X é exclusivo combo			
	--
	-- combos 
	--
	--CV_COND_PGTO_IP_COMBO
	union all
	select 
		distinct
		y3.org_vendas as vkorg, y3.canal_distribuicao as vtweg, 
		0.01 as valor_de, 
		999999.99 as valor_ate, 
		cast(y8.przmedio as integer) as prz_med, 
		y8.zterm AS CODIGO, 
		y3.descricao as desdobramento, 
		y3.qde_parcelas, 
		'combo' as tipo, 
		'' as cliente, 
		combo.codigo_combo
	from
		w_cond_combo as combo
	join
		w_ydbi008 as y8
		on y8.zterm = combo.condicao
	join
		w_ydsd003 as y3 
		on y3.codigo = y8.zterm
	where	
		coalesce(y3.rfc_combo, 'S') = '' -- X é exclusivo combo
		and length(ltrim(y3.descricao,' +-.0123456789/')) = 0

	order by
		prz_med, codigo


)


/* OLD VERSION 15.12.21 19:15
SELECT
  vkorg,
  vtweg,
  valor_de,
  valor_ate ,
  cast(prz_med as integer) as prz_med,
  codigo,
  desdobramento ,
  qde_parcelas,
  tipo,
  cliente
from (
		select 
		distinct
		y5.vkorg, y5.vtweg, 
		cast(y5.kdkg1_de as numeric) as valor_de, 
		cast(y5.kdkg1_ate as numeric) as valor_ate, 
		cast(y8.przmedio as integer) as prz_med, 
		y8.zterm AS CODIGO, 
		y3.descricao as desdobramento, 
		y3.qde_parcelas, 
		'prz medio' as tipo, 
		'' as cliente	
	from
		dados-dev.raw_cimed_tech.YDSD005 as y5
	join
		dados-dev.raw.YDBI008 as y8
		on y8.przmedio <= cast(y5.przmed as int)
	join
		dados-dev.raw_cimed_tech.YDSD003 as y3 
		on y3.codigo = y8.zterm
		and y3.org_vendas = y5.vkorg
		and y3.canal_distribuicao = y5.vtweg
	where	
		--y5.vkorg = :IP_VKORG
		--y5.vtweg = :IP_CANAL
		--and :IP_VALOR between 250 and y5.kdkg1_ate
		--and (:IP_VALOR / y3.qde_parcelas) >= 250
		coalesce(y3.exc_rede, '') = '' -- X é exclusivo rede
		and coalesce(y3.exc_cliente, '') = '' -- X é exclusivo cliente
		and coalesce(y3.rfc_combo, '') = '' -- X é exclusivo combo
		and length(ltrim(y3.descricao,' +-.0123456789/')) = 0
	union all
	-- condição da rede 
	-- o union com kna1 abaixo, vai trazer o codigo do cliente para filtrar
	-- na clausula where do pipeline
	select 
		distinct
		y4.vkorg, y3.canal_distribuicao as vtweg, 
		cast(0.01 as numeric) as valor_de, 
		cast(999999 as numeric) as valor_ate, 
		cast(999 as integer) as prz_med, 		
		y3.codigo, y3.descricao as desdobramento, 
		y3.qde_parcelas, 
		'prz rede: ' || cast(k.kdkg1 as string) as tipo, 
		k.kunnr as cliente
	from
		dados-dev.raw_cimed_tech.YDSD004 as y4
	join	
		dados-dev.raw_cimed_tech.YDSD003 as y3 
		on y3.org_vendas = y4.vkorg
		and y3.canal_distribuicao = y4.vtweg
		and y3.codigo = y4.zterm
	join dados-dev.raw.KNA1 k
		on k.kdkg1 = y4.kdkg1
	where	
		--y3.org_vendas = :IP_VALOR
		--and y3.canal_distribuicao = :IP_CANAL
		--and k.kunnr = :IP_CLIENTE -- achar rede
		cast(current_date as string) between y4.DESDE and y4.ate
		--and (:IP_VALOR / y3.qde_parcelas) >= 250
		and coalesce(y3.exc_rede, '') = 'X' -- X é exclusivo rede
		and coalesce(y3.exc_cliente, '') = '' -- X é exclusivo cliente
		and coalesce(y3.rfc_combo, '') = '' -- X é exclusivo combo	
		and length(ltrim(y3.descricao,' +-.0123456789/')) = 0
	union all
	-- condição da cliente
	select 
		distinct
		y224.vkorg, y3.canal_distribuicao as vtweg,  
		cast(0.01 as numeric) as valor_de, 
		cast(999999 as numeric) as valor_ate, 
		cast(999 as integer) as prz_med, 
		y3.codigo, y3.descricao as desdobramento, y3.qde_parcelas,
		'prz cliente: ' || cast(k.kunnr as string) as tipo, 
		y224.kunnr as cliente	
	from
		dados-dev.raw_cimed_tech.YDSD224 as y224
	join	
		dados-dev.raw_cimed_tech.YDSD003 as y3 
		on y3.org_vendas = y224.vkorg
		and y3.canal_distribuicao = y224.vtweg
		and y3.codigo = y224.CONDPG
	join dados-dev.raw.KNA1 k
		on k.kunnr = y224.kunnr
	where	
		--y3.org_vendas = :IP_VKORG
		--and k.kunnr = :IP_CLIENTE
		-- and y3.canal_distribuicao = :IP_CANAL
		cast(current_date as string) between y224.DATADE and y224.DATAate
		--and (:IP_VALOR / y3.qde_parcelas) >= 250	
	--	and coalesce(y3.exc_rede, '') = '' -- X é exclusivo rede
	-- tem q definir exc_rede e exc_cliente todos ou um só
		and coalesce(y3.exc_cliente, '') = 'X' -- X é exclusivo cliente
		and coalesce(y3.rfc_combo, '') = '' -- X é exclusivo combo	
		and length(ltrim(y3.descricao,' +-.0123456789/')) = 0	
		
	-- condição do combo - fazer junto ???
	-- condição da loja
	order by
		prz_med, codigo)

	*/