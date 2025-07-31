-- CV_LOJAS_OFFLINE
with 
	w_ydsd044 as	
	(
		select distinct
			werks, lgort, 'L'||meses as meses
		from			
            `dados-dev.raw_cimed_tech.YDSD044`
        where 
            -- AEO 05.01.2022 - retira o estoque 1005/1016
            lgort <> '1006'
            and werks <> '1001' 
            and werks <> '1100'
            and werks <> '1101'
            and werks <> '1010'			
	),
    w_url as (
        select
            cast(lower(relatorio) as string) as url
        from 
            `dados-dev.raw.YDBI001`
        where 
            filtro = 'GCP' 
            and NOME_VIEW = 'URL_GC_CONTEUDO'
    )
	, w_validade_curta as
	(
		SELECT
			PRODUTO, VALOR, SALDO, VKORG
		FROM
			dados-dev.visoes_auxiliares_cimed_tech.CV_VIEW_VALIDADE_CURTA
	)
	, w_material as
	(
		select
			codigo, codigobarras, DESCRICAO as descricao_material, principioativo, generico, lista, codigo_ms, 
			linha, status, c_controlado, produto_hierarquia, substring(hierarquia, 4, 3) as cod_hierarquia, hierarquia, CASE
				WHEN GRP_MERCADORIA IN ('PA01', 'PA02', 'PA03')
					THEN 'MIP'
				WHEN GRP_MERCADORIA IN ('PA04', 'PA05', 'PA06')
					THEN 'RX'
				WHEN GRP_MERCADORIA IN ('PA07', 'PA08', 'PA09', 'PA23', 'PA24', 'PA25')
					THEN 'Controlados'
				WHEN GRP_MERCADORIA IN ('PA10', 'PA16', 'PA17')
					THEN 'Genéricos'
				WHEN GRP_MERCADORIA IN ('PA11')
					THEN 'Cosméticos'
				WHEN GRP_MERCADORIA IN ('PA12')
					THEN 'Correlatos'
				WHEN GRP_MERCADORIA IN ('PA13')
					THEN 'Suprimentos'
				WHEN GRP_MERCADORIA IN ('PA14', 'PA18', 'PA19', 'PA20', 'PA21', 'PA22')
					THEN 'Hospitalar'
				WHEN GRP_MERCADORIA IN ('PA15')
					THEN 'Terceiros'
					ELSE GRP_MERCADORIA
			END AS grp_mercadoria, 
			grp_mercadoria as cod_grp_mercadoria, 
			
			fabricante, caixa_padrao, ipi,farm_popular, prod_marca, prod_classei, prod_fator, ncm, grpmercexterno, 
			MENU_CATEGORIA, NUM_CATEGORIA, COMBO, url.url
		from
			dados-dev.raw_cimed_tech.CV_CADASTRO_MATERIAL_T
        cross join 
            w_url as url
		where
			-- foi retirado o filtro de status na criação 
			-- da tabela de materiais, aqui precisa filtrar
			MSTAE in ('', 'Y5') 
	)
	, w_contexto AS
	(
		SELECT
			produto, NOME as FILTRO_CONTEXTO_NOME, id as FILTRO_CONTEXTO_ID, '' as VKORG
		FROM
			--DEV
			EXTERNAL_QUERY("projects/dados-dev/locations/us/connections/cimed-postgres-us", "SELECT * from sf.view_prd_destaque")
			--PROD
			--EXTERNAL_QUERY("projects/dados-prod/locations/southamerica-east1/connections/cimed-postgres", "SELECT * from sf.view_prd_destaque") 
		UNION ALL
  		SELECT
			PRODUTO, 'Outlet' as FILTRO_CONTEXTO_NOME, 'Outlet' as FILTRO_CONTEXTO_ID, VKORG
		FROM
			w_validade_curta				
	),
	w_ydsd218 as 
	(
		select * from dados-dev.raw.YDSD218
	)
select
	MAT.CODIGOBARRAS, MAT.DESCRICAO_MATERIAL, 
	MAT.PRINCIPIOATIVO, MAT.GENERICO, MAT.CODIGO_MS, MAT.LINHA, MAT.STATUS, MAT.C_CONTROLADO,
	-- ajusta num_categoria
	MAT.MENU_CATEGORIA, MAT.NUM_CATEGORIA, MAT.GRP_MERCADORIA, MAT.FABRICANTE, MAT.CAIXA_PADRAO, MAT.IPI, MAT.FARM_POPULAR, MAT.PROD_MARCA, 
	MAT.PROD_CLASSEI, MAT.PROD_FATOR, MAT.NCM, MAT.GRPMERCEXTERNO, P.COD_GAMA, P.DESCRICAO,
	substring(P.PRODUTO, 13, 6) AS PRODUTO, 0 AS PERC_COMIS, 
	mat.url||substring(MAT.hierarquia, 1, 3)
		|| '/'
		||substring(MAT.hierarquia, 4, 3)
		|| '/'
		||substring(MAT.hierarquia, 7, 3)
		||'/'
		||substring(MAT.hierarquia, 10, 3)
		||'/'
		||substring(P.produto,13,6)
		||'/'
		||substring(P.produto,13,6)
		||'-I.png' as IMAGEM, 
        mat.url||substring(MAT.hierarquia, 1, 3)
		|| '/'
		||substring(MAT.hierarquia, 4, 3)
		|| '/'
		||substring(MAT.hierarquia, 7, 3)
		||'/'
		||substring(MAT.hierarquia, 10, 3)
		||'/'
		||substring(P.produto,13,6)
		||'/'
		||substring(P.produto,13,6)
		||'-B.pdf' as BULA, 
        mat.url||substring(MAT.hierarquia, 1, 3)
		|| '/'
		||substring(MAT.hierarquia, 4, 3)
		|| '/'
		||substring(MAT.hierarquia, 7, 3)
		||'/'
		||substring(MAT.hierarquia, 10, 3)
		||'/'
		||substring(P.produto,13,6)
		||'/'
		||substring(P.produto,13,6)
		||'-F.pdf' as FICHA, 
    cast(p.TRANSITO as integer) AS TRANSITO, 
	cast(p.DISPONIVEL as integer) AS DISPONIVEL, '' as FILTRO_CONTEXTO, '' as NUM_FILTRO, 
	
	case 
		when coalesce(cont.FILTRO_CONTEXTO_ID, '') <> '' then coalesce(cont.FILTRO_CONTEXTO_ID, '')
		else COMBO
	end as FILTRO_CONTEXTO_ID, 
	case 
		when coalesce(cont.FILTRO_CONTEXTO_NOME, '') <> '' then coalesce(cont.FILTRO_CONTEXTO_NOME, '')
		else COMBO
	end as FILTRO_CONTEXTO_NOME,	
	300 as PEDIDO_MINIMO, 'P' as TIPO_P, 'M' as TIPO_M, 'G' as TIPO_G,
	-- se tem validade valor de VC, tem tag na api
	-- trazer VC de with
    'A' as GRUPO_A, 'B' as GRUPO_B,
	-- integração define o tipo de documento usado na integração da OV
	-- mockado para separar ZNOR, ZV12 e YTRI
	-- cabe uma versão da api com o tipo de documento
	'ZNOR' as INT_ZNOR, 'ZNOR-VC' as INT_ZV12
from
	w_material as mat
join
	( with w_loja as
	    (
		with w_gama_produto as
			(
				select
					c.cod_gama, c.matnr, 
					case 
						--PA13 alimentos - PA12 correlatos  - PA11 cosméticos 					
						when M.cod_grp_mercadoria in ('PA11', 'PA12', 'PA13') then 'ZOUT'
						else 'ZMED'
					end as material_zmed_zout, 
                    --case 
                    --    when M.cod_grp_mercadoria in ('PA07', 'PA08', 'PA09') then 'S'
                    --    else 'N'
                    --end as material_controlado
                    M.c_controlado as material_controlado
				from
					dados-dev.raw_cimed_tech.YDSD057 AS c
				join 
					w_material as M
					on m.codigo = c.matnr
				where
					c.ativo = 'S' and
					c.cod_gama in ('157','158','159')
					-- AEO 27.12.21
					-- necessario filtrar por lojas pois, por conta da visao
					-- varias lojas estarão ativas 						
			)
		SELECT DISTINCT
			A.BUKRS, A.COD_GAMA, b.descricao, b.vtweg, c.matnr
		FROM
			dados-dev.raw_cimed_tech.YDSD225 AS a
		JOIN
			dados-dev.raw_cimed_tech.YDSD056 AS b
	
			ON a.cod_gama = b.cod_gama
		join
			w_gama_produto as c	   
			on c.cod_gama = b.cod_gama				
		WHERE
			a.ativo      = 'S'
			AND b.ativo  = 'S'
	    )
    select
        loja.cod_gama, loja.descricao, loja.vtweg, loja.bukrs, loja.matnr as produto, 
        '0' as disponivel, '0' as transito
    from
        w_loja as loja
) P
on mat.codigo = P.produto
left join
	w_contexto as cont
	on cont.produto = P.produto
group by
	mat.codigo, mat.codigobarras, mat.descricao_material, mat.principioativo, mat.generico, mat.codigo_ms, mat.linha, mat.status, 
	MAT.C_CONTROLADO, MAT.PRODUTO_HIERARQUIA, MAT.cod_hierarquia, MAT.GRP_MERCADORIA, mat.fabricante, mat.caixa_padrao, mat.ipi, 
	mat.farm_popular, mat.prod_marca, mat.prod_classei, mat.prod_fator, mat.ncm, mat.grpmercexterno,MAT.hierarquia, P.cod_gama, 
	P.descricao, P.produto, 
	MAT.MENU_CATEGORIA, MAT.NUM_CATEGORIA, cont.FILTRO_CONTEXTO_ID, cont.FILTRO_CONTEXTO_NOME, p.TRANSITO, p.DISPONIVEL, COMBO, mat.url