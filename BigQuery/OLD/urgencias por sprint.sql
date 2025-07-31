Lista em ordem de importancia:
***** 25/10/2021 *****
- cadastro cliente, cadeira e vendedor 
- duplicatas - corrigido  - passar para GCP - 
- produto duplicado - qual codigo? - ok
- comissao sem cadastro - ok
- indicadores...


***** 23/10/2021 *****
- plano de carga de dados SF 
	- export para cloud storage - ok
- produto duplicatado noa view - ok
- definição alert / cores
  WARNING = #FEC400 
  ALERT = #FE0000 
  OK = #24AA52
- combo fica para sprint 13

***** 22/10/2021*****
- enriquenciemeto SF-GCP
	- criar tabelas postgres - ok
	- fazer join GCP / postgres
- teste monalisa upload documentos para GCP
- ZPMI incluir os dados corretos ja no GCP 
	- passar rfc para atualizar zpmi para cast
- views de forma de pagamento para sf, tem outras  
	EMPRESA__C
	CONDICAO_PAGAMENTO__C
	DUPLICATA__C
	LOJA__C
	LOJA_AUTORIZACAO__C
	ORDERITEM
	EMPRESA_DA_CONTA__C
- cadasttros de combos
	- zpmi 
- bloqueios e warnings - ok
- revisar API indicadores clientes
	- cv_dash_visao
- levantar duplicatas vencidadas para validar app
- api de preços
	- contextos, 
	- comissoes
	- combos tem q ser automatico o contexto

***** 21/10/2021 *****
1 - View de clientes (REP CLIENTES) - ja validado pela evolve V2  - ok
2 - ZPMI no PRICING - ja esta na api
3 - LSMW pera naão replicar as condições comerciais - ja rodou, preço tao ok na api
4 - Status da mercadoria na view de produtos - ok