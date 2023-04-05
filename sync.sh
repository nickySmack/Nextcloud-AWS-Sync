#!/bin/sh

# This bash script is used to backup a Nextcloud instance to an AWS S3 bucket.
# It takes one argument, which is the name of the Nextcloud app to be backed up.
# I do not usually run it with an argument and I am not sure why it is in here.
# Must be run as root!!!

# Set the AWS S3 bucket name
s3_bucket='aws bucket name'

# Set the directory where Nextcloud is installed
nextcloud_dir='/var/www/nextcloud'

# Set the directory where Nextcloud data is stored
data_dir='/mnt/ncdata'

# Set the database host, username, password, and name
db_host='localhost'
db_user='db_user'
db_pass='strong_password'
db_name='nextcloud_db_or_similar'

# Get the name of the Nextcloud app from the argument
app=$1

# Print a message indicating that the backup has started
echo 'started'

# Create a timestamp for the backup file
timestamp=$(date +%F_%T | tr ':' '-')

# Create a temporary file for the database dump
temp_file=$(mktemp tmp.XXXXXXXXXX)

# Set the destination for the backup file in the AWS S3 bucket
s3_file="s3://$s3_bucket/$app/$app-backup-$timestamp"

# Put Nextcloud into maintenance mode
sudo -u www-data php $nextcloud_dir/occ maintenance:mode --on

# Dump the Nextcloud database to the temporary file
PGPASSWORD=$db_pass pg_dump -Fc --no-acl -h localhost -U $db_user $db_name > $temp_file

# Sync the Nextcloud data directory to the AWS S3 bucket, excluding the cache directory
s3cmd sync --recursive --preserve --exclude 'cache/*' $data_dir s3://$s3_bucket/

# Remove the temporary file
rm "$temp_file"

# Turn off maintenance mode for Nextcloud
sudo -u www-data php $nextcloud_dir/occ maintenance:mode --off

# Print a message indicating that the backup has finished
echo 'finished'
