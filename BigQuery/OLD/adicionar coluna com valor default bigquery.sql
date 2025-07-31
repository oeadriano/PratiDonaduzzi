1) incluir a coluna
ALTER TABLE raw_cimed_tech.ct_pedidos_auxiliar add column data_hora_insert timestamp;
2) alterar o campo para default
ALTER TABLE raw_cimed_tech.ct_pedidos_auxiliar ALTER COLUMN data_hora_insert SET DEFAULT current_timestamp(); 