********* ACESSO ADM CIMEDTECH *********
- funcionario cimed: ler da lfa1, apos cadastro de caracteristica habilitadora
- fornecedor Evolve, ler da lfa1, apos cadastro de caracteristica habilitadora

view de representantes para SF
- incluir tipo de registro: V-endedor, S-upervisor, C-omercial, A-dministrativo, F-ornecedor
- atualizar tabela representante-login

objetos cadastro de rep no SF
- Diego vai analisar qual objeto utilizar

Processo de login
- processo mantem o mesmo caminho com senha no SF

LISTA DE REPS E CLIENTES
O adm, ao logar, deve executar api para obter lista de supervisores
ao selecionar o supervisor, executar api com lista de reps
ou 
executar api unica com supervisores e seus subordinados

Chamada de tela de seleção de supervisores deve ser objeto exclusivo ja pensando na estrutura do IM
chamada de lista de reps, pode ser objeto ja utilizado para acesso delegado do supervisor
objeto com simulação de perfil do vendedor deve ser o mesmo do acesso delegado.


Feature
user adm solicita login, chama api com lista de supervisores

