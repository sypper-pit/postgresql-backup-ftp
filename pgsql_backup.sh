#!/bin/bash

# Переменные
BACKUP_DIR="/www/backup/database/"
CONTAINER_NAME_PART="pgsql-db"
POSTGRES_DB="name-db"
POSTGRES_USER="postgres"
POSTGRES_PASS_FILE="/run/secrets/db_passwd"
FTP_USER="backup"
FTP_PASSWORD="backup123"
FTP_HOST="192.168.0.200"
FTP_DIR="/backup"
DAYS_OLD=4

cd $BACKUP_DIR

# Находим ID контейнера
CONTAINER_ID=$(docker ps | grep $CONTAINER_NAME_PART | awk '{print $1}')
if [ -z "$CONTAINER_ID" ]; then
    echo "Контейнер не найден."
    exit 1
fi

# Чтение пароля
POSTGRES_PASSWORD=$(docker exec $CONTAINER_ID cat $POSTGRES_PASS_FILE)

# Формирование имени файла бэкапа
BACKUP_FILE_NAME="backup_$(date +%Y%m%d_%H%M%S).sql"

# Создание бэкапа
docker exec -e PGPASSWORD=$POSTGRES_PASSWORD $CONTAINER_ID pg_dump -U $POSTGRES_USER $POSTGRES_DB > $BACKUP_FILE_NAME
echo "Бэкап $POSTGRES_DB сохранен в файл $BACKUP_FILE_NAME"

# Отправка файла на FTP
curl -T ${BACKUP_FILE_NAME} --user ${FTP_USER}:${FTP_PASSWORD} ftp://${FTP_HOST}${FTP_DIR}/
echo "Файл ${BACKUP_FILE_NAME} успешно отправлен на FTP сервер."

# Удаление старых файлов локально
find $BACKUP_DIR -type f -name "*.sql" -mtime +$DAYS_OLD -exec echo "Удаляется локальный файл: {}" \; -exec rm {} \;

lftp -u ${FTP_USER},${FTP_PASSWORD} ${FTP_HOST} <<EOF
set ssl:verify-certificate no
cd ${FTP_DIR}
cls -1 --sort=date | awk 'NR>$DAYS_OLD' | xargs -r -d '\n' rm
bye
EOF

echo "Старые файлы на FTP сервере удалены."
