***** ESTOQUE VIRTUAL *****
API estoque-hana-postgres
Incluir novo campo nos objetos de insert /update

1) Ler da View hana "_SYS_BIC"."CimedTech/CV_YDSD_ATUALIZAR_ESTOQUE_IP"
Novo campo: "CONSUMIDO"

2) Na API estoque-hana-postgres
Alterar SELECT Select HANA CV_YDSD_ATUALIZAR_ESTOQUE_IP, incluindo o campo "CONSUMIDO"
Incluir o campo Consumido no Objeto "insert estoque PGSQL", no insert e no update


***** API PREÇO FIXO *****
API consulta-lojas-preco-fixo
VIEW utilizada: VH_TR_LOJAS_PRECO_FIXO
Alteradas as colunas: 
	VALOR_G	-> VALOR_F
	QDE_G	-> QDE_F
	COMIS_G	-> COMIS_F
É preciso alterar na API: 
hoje o preço unico sai como tipo = G, o tipo deve ser sempre  = 'F'
OBS:
- itens de validade curta passarão a sair na API tb, da mesma forma que hj sai na api de lojas_off

API consulta-lojas-off
VIEW utilizada: VH_TR_LOJAS_PRECO_GERAL


***** OFF-LINE *****
CLIENTE COM PRECO-FIXO = 'S'
	- ler somente tabela sap.VH_TR_LOJAS_PRECO_FIXO, COMO É FEITO HJ.
	- temos que avaliar a validade curta 
	
CLIENTE COM PRECO-FIXO = 'N'
	- ler tabela sap.VH_TR_LOJAS_PRECO_GERAL
	- join com sap.VH_TR_LOJAS_PRECO_FIXO, (cliente, vkorg e matnr)
	

