#!/bin/bash
# =========================================================================== #
# Description:        Backup WordPress or website to S3-Compatible Storage 
# Requirements:       s3cmd and optional Cloudpanel to use Cloudpanel CLI
# Author:             Brian Chin
# Author URI:         https://wpspeedexpert.com
# Make executable:    chmod +x /home/[website-path]/scripts/backup-s3.sh
# Execute the script: sudo /home/[website-path]/scripts/backup-s3.sh
# =========================================================================== #
#
# Variables
DATABASE=("database-name")
WP_DIR=("/home/[website-path]/htdocs/staging.wpspeedexpert.com")
UPLOADS_DIR=("/home/[website-path]/htdocs/staging.wpspeedexpert.com/wp-content/uploads")
THEMES_DIR=("/home/[website-path]/htdocs/staging.wpspeedexpert.com/wp-content/themes")
PLUGINS_DIR=("/home/[website-path]/htdocs/staging.wpspeedexpert.com/wp-content/plugins")
WPCONTENT_DIR=("/home/[website-path]/htdocs/staging.wpspeedexpert.com/wp-content")

BACKUP_DIR=/home/[website-path]/scripts/backups
SCRIPTS_DIR=/home/[website-path]/scripts
CURRENT_DATE=$(date +"%Y-%m-%d")

# s3cmd Information
S3_CMD="/usr/local/bin/s3cmd"
S3_BUCKET=s3://[bucket-name]/[folder-name]/

# Check for WP directory & wp-config.php
if [ ! -d ${WP_DIR} ]; then
  echo "[+] ERROR: Directory ${WP_DIR} does not exist"
  echo ""
  exit
fi
if [ ! -f ${WP_DIR}/wp-config.php ]; then
  echo "[+] ERROR: No wp-config.php in ${WP_DIR}"
  echo ""
  exit
fi
  echo "[+] Success: found wp-config.php in ${WP_DIR}"

# Make a backup directory if it does not already exist, and remove any files from that directory
mkdir -p $BACKUP_DIR
rm -rf "${BACKUP_DIR:?}/*"
  echo "[+] Success: created and cleaned ${BACKUP_DIR}"

# Dump database using mysqldump (optional)
#  echo "[+] Creating Database dump..."
# mysqldump --defaults-extra-file=${SCRIPTS_DIR}/my.cnf "$DB" | gzip > "$BACKUP_DIR/${DATABASE}.sql.gz"
#  echo "[+] Success: database dump ${BACKUP_DIR}/${DATABASE}.sql.gz"

# Dump database using Cloudpanel CLI
# https://www.cloudpanel.io/docs/v2/cloudpanel-cli/root-user-commands/
echo "[+] Creating Database dump..."
clpctl db:export --databaseName=${DATABASE} --file=$BACKUP_DIR/${DATABASE}.sql.gz
  echo "[+] Success: database dump ${BACKUP_DIR}/${DATABASE}.sql.gz"

# Create tar bzip2 of the WordPress installation directory and exclusions
echo "[+] Create TAR for WP files without the wp-content directory"
tar -cjvf ${BACKUP_DIR}/wp_files.tar.bz2 --exclude='wp-content' ${WP_DIR}

echo "[+] Creating others.tar.bz2"
tar -cjvf ${BACKUP_DIR}/others.tar.bz2 --exclude='themes' --exclude='plugins' --exclude='uploads' --exclude='cache' --exclude='updraft' --exclude='backups-dup-pro' --exclude='backups-dup' --exclude='ai1wm-backups' ${WPCONTENT_DIR}

echo "[+] Creating uploads.tar.bz2"
tar -cjvf ${BACKUP_DIR}/uploads.tar.bz2 ${UPLOADS_DIR}

echo "[+] Creating themes.tar.bz2"
tar -cjvf ${BACKUP_DIR}/themes.tar.bz2 ${THEMES_DIR}

echo "[+] Creating plugins.tar.bz2"
tar -cjvf ${BACKUP_DIR}/plugins.tar.bz2 ${PLUGINS_DIR}

# Rename backup directory
mv ${BACKUP_DIR} ${SCRIPTS_DIR}/${CURRENT_DATE}

# Rsync to remote server (optional) - edit remote location
# echo "[+] Rsync to remote server..."
# rsync -azP --update --delete --no-perms --no-owner --no-group --no-times ${SCRIPTS_DIR}/${CURRENT_DATE}/  /home/backups/${DATABASE}/{CURRENT_DATE}

# Sent to S3-compatible storage
echo "[+] Uploading backup to S3..."
$S3_CMD sync ${SCRIPTS_DIR}/${CURRENT_DATE} ${S3_BUCKET}
# $S3_CMD put -r ${SCRIPTS_DIR}/${CURRENT_DATE} ${S3_BUCKET}

# Clean up files
echo "[+] Removing local files..."
rm -rf ${SCRIPTS_DIR}/${CURRENT_DATE}
echo "[+] Finish!"
echo ""

# End of the script
exit
