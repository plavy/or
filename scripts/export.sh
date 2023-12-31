#!/bin/bash

# Directory to export
DIR=${PWD}/../web-app/public

# Set postgres variables
export PGUSER=postgres
export PGPASSWORD=postgres
export PGDATABASE=or

# Dump database
pg_dump --clean > ${DIR}/dump.sql

# Export to CSV
psql -c "\copy
  (SELECT locations.*,
    maintainers.id AS maintainer_id, maintainers.name AS maintainer_name, maintainers.street AS maintainer_street,
    maintainers.city AS maintainer_city, maintainers.province AS maintainer_province, maintainers.country AS maintainer_country
		FROM locations
    INNER JOIN locations_maintainers on locations.id = locations_maintainers.location_id
    INNER JOIN maintainers ON locations_maintainers.maintainer_id = maintainers.id
    ORDER BY locations.id
  )
TO '${DIR}/locations.csv' DELIMITER ',' CSV HEADER"

# Export to JSON
psql -At -c "
SELECT JSON_AGG(tab)
FROM
  (SELECT locations.*, JSON_AGG(maintainers.*) AS maintainers
    FROM locations
    INNER JOIN locations_maintainers on locations.id = locations_maintainers.location_id
    INNER JOIN maintainers ON locations_maintainers.maintainer_id = maintainers.id
    GROUP BY locations.id
    ORDER BY locations.id
  ) AS tab;
" -o ${DIR}/locations.json

jq . ${DIR}/locations.json
