BTC: bc1qttzg9yww3nv5dg2d5ja95txmt0mrw9dltfqj57

Monero(XMR): 8AyWrMwPCxrcbcmVDj3Y5RCfcSQtBBVE2JK9qJ4WqrPpaoa3uNvLReQXPXGj7D5zEsMjBKeWWdyDD4gerqzTtKKS36zSfnM

LTC: LfMJCyxxg65sA3X9XEze157D16ztszndqk

USDT(TRC-20): TTZGfnhurU62VRRGYUHMPJ8q6U8rn5xG5a

USDT(ERC-20): 0xbdfec67586a78e5d3b58dfb70aa181823c8deafa

DOGE: D6kb8jcVXYTi82nsoACAYKYhtA5EJ4D9Jg

# Backup and Cleanup Script for PostgreSQL in Docker with FTP Upload

## Overview
This guide explains how to modify a Bash script for backing up a PostgreSQL database inside a Docker container, uploading the backup to an FTP server, and deleting old backup files.

## Prerequisites
- Docker installed
- Access to a PostgreSQL container
- FTP server credentials

## Steps
0. **Install pack on ubuntu**
   
    ```bash
    sudo apt install curl lftp
    ```

2. **Set Variables**: Define variables for directory paths, container names, database details, and FTP credentials at the beginning of your script.

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

3. **Find Container ID**: Use `docker ps` to find your container's ID by matching part of its name.

    ```bash
    CONTAINER_ID=$(docker ps | grep $CONTAINER_NAME_PART | awk '{print $1}')
    ```

4. **Backup Database**: Perform the `pg_dump` command inside your container to create the backup.

    ```bash
    docker exec -e PGPASSWORD=$POSTGRES_PASSWORD $CONTAINER_ID pg_dump -U $POSTGRES_USER $POSTGRES_DB > $BACKUP_FILE_NAME
    ```

5. **Upload to FTP**: Use `curl` to upload the backup file to your FTP server.

    ```bash
    curl -T ${BACKUP_FILE_NAME} --user ${FTP_USER}:${FTP_PASSWORD} ftp://${FTP_HOST}${FTP_DIR}/
    ```

6. **Delete Old Files Locally**: Use `find` to delete backup files older than `DAYS_OLD` days.

    ```bash
    find $BACKUP_DIR -type f -name "*.sql" -mtime +$DAYS_OLD -exec rm {} \;
    ```

7. **Delete Old Files on FTP**: Utilize `lftp` to connect to the FTP server and delete old files.

    ```bash
    lftp -u ${FTP_USER},${FTP_PASSWORD} ${FTP_HOST} <<EOF
    set ssl:verify-certificate no
    cd ${FTP_DIR}
    cls -1 --sort=date | awk 'NR>$DAYS_OLD' | xargs -r -d '\n' rm
    bye
    EOF
    ```
