EXPORT DATA
  OPTIONS( uri='gs://arqdados-data-loaders/CADASTRO_CLIENTE_T*.csv',
    format='CSV',
    overwrite=TRUE,
    header=TRUE,
    field_delimiter=';') AS
SELECT
  *
FROM
  `dados-dev.raw_cimed_tech.CADASTRO_CLIENTE_T`
  
  
  entra em dados-dev / arqdados-data-loaders/...
  
  
  