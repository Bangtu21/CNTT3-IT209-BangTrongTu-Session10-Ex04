#!/bin/bash
set -e

# 1. Tao Custom Bridge Network
docker network inspect app-net >/dev/null 2>&1 || docker network create app-net

# 2. Tao Named Volume
docker volume inspect db-data >/dev/null 2>&1 || docker volume create db-data

# 3. Xoa container cu neu da ton tai
docker rm -f app-container db-server 2>/dev/null || true

# 4. Khoi chay PostgreSQL
docker run -d \
  --name db-server \
  --network app-net \
  --restart unless-stopped \
  -e POSTGRES_USER=appuser \
  -e POSTGRES_PASSWORD=appsecret \
  -e POSTGRES_DB=appdb \
  -v db-data:/var/lib/postgresql/data \
  postgres:15-alpine

# 5. Cho PostgreSQL san sang
until docker exec db-server pg_isready -U appuser -d appdb >/dev/null 2>&1
do
  sleep 2
done
# Dong bo mat khau PostgreSQL
docker exec db-server psql -U appuser -d appdb -c \
  "ALTER USER appuser WITH PASSWORD 'appsecret';"

# 6. Tao du lieu kiem thu Persistence
docker exec db-server psql -U appuser -d appdb -c "
CREATE TABLE IF NOT EXISTS persistence_test (
    id SERIAL PRIMARY KEY,
    message VARCHAR(100) NOT NULL
);
"

docker exec db-server psql -U appuser -d appdb -c "
INSERT INTO persistence_test (message)
SELECT 'Du lieu van con sau khi tao lai container'
WHERE NOT EXISTS (
    SELECT 1 FROM persistence_test
    WHERE message = 'Du lieu van con sau khi tao lai container'
);
"

# 7. Tao Backend container de kiem thu DNS va truy van DB
docker run -d \
  --name app-container \
  --network app-net \
  -e DB_HOST=db-server \
  -e DB_PORT=5432 \
  -e DB_NAME=appdb \
  -e DB_USER=appuser \
  -e DB_PASSWORD=appsecret \
  alpine:3.22 \
  sh -c "apk add --no-cache postgresql-client iputils && sleep infinity"

# 8. Cho Backend cai dat cong cu kiem thu xong
until docker exec app-container sh -c "command -v ping >/dev/null && command -v psql >/dev/null" >/dev/null 2>&1
do
  sleep 2
done

# 9. Kiem tra DNS va ket noi PostgreSQL
docker exec app-container ping -c 2 db-server

docker exec app-container sh -c \
  'PGPASSWORD="$DB_PASSWORD" psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$DB_NAME" -c "SELECT * FROM persistence_test;"'

# 10. Xoa cung container DB
docker rm -f db-server

# 11. Tao lai container DB, su dung lai volume cu
docker run -d \
  --name db-server \
  --network app-net \
  --restart unless-stopped \
  -e POSTGRES_USER=appuser \
  -e POSTGRES_PASSWORD=appsecret \
  -e POSTGRES_DB=appdb \
  -v db-data:/var/lib/postgresql/data \
  postgres:15-alpine

# 12. Cho DB khoi dong lai
until docker exec db-server pg_isready -U appuser -d appdb >/dev/null 2>&1
do
  sleep 2
done

# 13. Xac minh du lieu sau khi tao lai container
docker exec app-container sh -c \
  'PGPASSWORD="$DB_PASSWORD" psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$DB_NAME" -c "SELECT * FROM persistence_test;"'

echo "HOAN THANH: Network, Volume, DNS va Data Persistence da duoc kiem tra."