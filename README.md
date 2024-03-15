# Backup and Cleanup Script for PostgreSQL in Docker with FTP Upload

## Overview
This guide explains how to modify a Bash script for backing up a PostgreSQL database inside a Docker container, uploading the backup to an FTP server, and deleting old backup files.

## Prerequisites
- Docker installed
- Access to a PostgreSQL container
- FTP server credentials

## Steps

1. **Set Variables**: Define variables for directory paths, container names, database details, and FTP credentials at the beginning of your script.

    ```bash
    BACKUP_DIR="/path/to/backup"
    CONTAINER_NAME_PART="db-container-name-part"
    POSTGRES_DB="your_db_name"
    POSTGRES_USER="your_db_user"
    FTP_USER="your_ftp_user"
    FTP_PASSWORD="your_ftp_password"
    FTP_HOST="ftp.server.com"
    FTP_DIR="/path/on/ftp"
    DAYS_OLD=7
    ```

2. **Find Container ID**: Use `docker ps` to find your container's ID by matching part of its name.

    ```bash
    CONTAINER_ID=$(docker ps | grep $CONTAINER_NAME_PART | awk '{print $1}')
    ```

3. **Backup Database**: Perform the `pg_dump` command inside your container to create the backup.

    ```bash
    docker exec -e PGPASSWORD=$POSTGRES_PASSWORD $CONTAINER_ID pg_dump -U $POSTGRES_USER $POSTGRES_DB > $BACKUP_FILE_NAME
    ```

4. **Upload to FTP**: Use `curl` to upload the backup file to your FTP server.

    ```bash
    curl -T ${BACKUP_FILE_NAME} --user ${FTP_USER}:${FTP_PASSWORD} ftp://${FTP_HOST}${FTP_DIR}/
    ```

5. **Delete Old Files Locally**: Use `find` to delete backup files older than `DAYS_OLD` days.

    ```bash
    find $BACKUP_DIR -type f -name "*.sql" -mtime +$DAYS_OLD -exec rm {} \;
    ```

6. **Delete Old Files on FTP**: Utilize `lftp` to connect to the FTP server and delete old files.

    ```bash
    lftp -u ${FTP_USER},${FTP_PASSWORD} ${FTP_HOST} <<EOF
    set ssl:verify-certificate no
    cd ${FTP_DIR}
    cls -1 --sort=date | awk 'NR>$DAYS_OLD' | xargs -r -d '\n' rm
    bye
    EOF
    ```
