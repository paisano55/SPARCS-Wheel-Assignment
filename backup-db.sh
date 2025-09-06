# DB S3 Backup Script - TODO

echo "DB backup start"

source .env

BACKUP_FILE="wheel_db_backup_$(date +%Y%m%d_%H%M%S).sql"
BACKUP_PATH="/tmp/$BACKUP_FILE"

echo "Dumping MySQL"
docker exec wheel-mysql mysqldump -u root -p $MYSQL_ROOT_PASSWORD $MYSQL_DATABASE > $BACKUP_PATH

if [ $? -eq 0 ]; then
    echo "Dump completed: $BACKUP_FILE"
    
    if [ ! -z "$AWS_S3_BACKUP_BUCKET" ]; then
        echo "Uploading to S3"
        aws s3 cp $BACKUP_PATH s3://$AWS_S3_BACKUP_BUCKET/db-backups/$BACKUP_FILE
        
        if [ $? -eq 0 ]; then
            echo "S3 upload completed"
        else
            echo "S3 upload failed"
        fi
    fi
    
    find /tmp -name "wheel_db_backup_*.sql" -mtime +7 -delete
    
else
    echo "DB dump failed"
    exit 1
fi

echo "DB backup completed"
