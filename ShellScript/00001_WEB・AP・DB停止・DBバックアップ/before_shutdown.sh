#!/bin/bash
# EC2: kakeibo-web
# 格納パス: /home/ec2-user/sh/before_shutdown.sh

# WEBサーバ停止
sudo systemctl stop httpd.service

# APサーバ停止
sudo systemctl stop tomcat.service

# MariaDB接続設定
DBHOST="127.0.0.1"
DBUSER="XXXXX"
DBPASS="XXXXX"
DBNAME="XXXXX"

# DBバックアップ設定
BACKUP_DIR="/tmp/db_backup"
BACKUP_ROTATE=3
MYSQLDUMP="/usr/bin/mysqldump"

# バックアップ出力先ディレクトリのチェック
if [ ! -d "$BACKUP_DIR" ]; then
        echo "バックアップ出力先ディレクトリが存在しません: $BACKUP_DIR" >&2
        exit 1
fi

# 今日の日付をYYYYMMDDで取得
today=$(date '+%Y%m%d')

# mysqldumpコマンドでDBのバックアップを取得
$MYSQLDUMP -h "${DBHOST}" -u "${DBUSER}" -p"${DBPASS}" "${DBNAME}" > "${BACKUP_DIR}/${DBNAME}-${today}.dump"

# mysqldumpコマンドの終了ステータスで成功・失敗を確認
if [ $? -eq 0 ]; then
        gzip "${BACKUP_DIR}/${DBNAME}-${today}.dump"

        # 古いバックアップファイルを削除する
        find "$BACKUP_DIR" -name "${DBNAME}-*.dump.gz" -mtime +${BACKUP_ROTATE} | xargs rm -f
else
        echo "バックアップ作成失敗: ${BACKUP_DIR}/${DBNAME}-${today}.dump"
        exit 2
fi

# DBサーバ停止
sudo systemctl stop mariadb
