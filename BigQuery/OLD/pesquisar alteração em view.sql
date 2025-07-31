  SELECT

    dataset_id,

    table_id,

    row_count,

    ROUND(safe_divide(size_bytes,

        (1000*1000)),3) AS size_mb,

    TIMESTAMP_MILLIS(creation_time) AS create_date,

    TIMESTAMP_MILLIS(last_modified_time) AS modify_date

  FROM

    `dados-dev.visoes_painel_vendas.__TABLES__`

  ORDER BY

    dataset_id,

    table_id