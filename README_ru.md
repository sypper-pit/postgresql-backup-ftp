# Скрипт для резервного копирования и очистки PostgreSQL в Docker с загрузкой на FTP

## Обзор
Руководство описывает, как модифицировать Bash скрипт для создания резервной копии базы данных PostgreSQL внутри Docker контейнера, загрузки бэкапа на FTP-сервер и удаления старых файлов бэкапа.

## Предварительные требования
- Установленный Docker
- Доступ к контейнеру с PostgreSQL
- Данные для доступа к FTP-серверу

## Шаги

1. **Установка переменных**: В начале скрипта определите переменные для путей к директориям, именам контейнеров, деталям базы данных и учётным данным FTP.

    ```bash
    BACKUP_DIR="/путь/к/бэкапу"
    CONTAINER_NAME_PART="часть-имени-контейнера"
    POSTGRES_DB="имя_вашей_бд"
    POSTGRES_USER="пользователь_бд"
    FTP_USER="пользователь_ftp"
    FTP_PASSWORD="пароль_ftp"
    FTP_HOST="ftp.server.com"
    FTP_DIR="/путь/на/ftp"
    DAYS_OLD=7
    ```

2. **Поиск ID контейнера**: Используйте `docker ps` для поиска ID вашего контейнера по части его имени.

    ```bash
    CONTAINER_ID=$(docker ps | grep $CONTAINER_NAME_PART | awk '{print $1}')
    ```

3. **Бэкап базы данных**: Выполните команду `pg_dump` внутри вашего контейнера для создания бэкапа.

    ```bash
    docker exec -e PGPASSWORD=$POSTGRES_PASSWORD $CONTAINER_ID pg_dump -U $POSTGRES_USER $POSTGRES_DB > $BACKUP_FILE_NAME
    ```

4. **Загрузка на FTP**: Используйте `curl` для загрузки файла бэкапа на ваш FTP-сервер.

    ```bash
    curl -T ${BACKUP_FILE_NAME} --user ${FTP_USER}:${FTP_PASSWORD} ftp://${FTP_HOST}${FTP_DIR}/
    ```

5. **Удаление старых файлов локально**: Используйте `find` для удаления файлов бэкапа, которым больше `DAYS_OLD` дней.

    ```bash
    find $BACKUP_DIR -type f -name "*.sql" -mtime +$DAYS_OLD -exec rm {} \;
    ```

6. **Удаление старых файлов на FTP**: Используйте `lftp` для подключения к FTP-серверу и удаления старых файлов.

    ```bash
    lftp -u ${FTP_USER},${FTP_PASSWORD} ${FTP_HOST} <<EOF
    set ssl:verify-certificate no
    cd ${FTP_DIR}
    cls -1 --sort=date | awk 'NR>$DAYS_OLD' | xargs -r -d '\n' rm
    bye
    EOF
    ```
