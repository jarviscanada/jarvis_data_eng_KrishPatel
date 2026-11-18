#!/bin/bash

# Usage: bash scripts/host_usage.sh psql_host psql_port db_name psql_user psql_password
# Example: bash scripts/host_usage.sh localhost 5432 host_agent postgres password1234

# Setup and validate arguments
psql_host=$1
psql_port=$2
db_name=$3
psql_user=$4
psql_password=$5

# Check # of args
if [ "$#" -ne 5 ]; then
  echo "Illegal number of parameters"
  echo "Usage: $0 psql_host psql_port db_name psql_user psql_password"
  exit 1
fi

# Save machine statistics in MB and the current machine hostname to variables
vmstat_mb=$(vmstat --unit M)
hostname=$(hostname -f)

# Retrieve usage variables (xargs trims leading and trailing white spaces)
memory_free=$(echo "$vmstat_mb" | tail -n1 | awk '{print $4}' | xargs)
cpu_idle=$(echo "$vmstat_mb" | tail -n1 | awk '{print $15}' | xargs)
cpu_kernel=$(echo "$vmstat_mb" | tail -n1 | awk '{print $14}' | xargs)
disk_io=$(vmstat -d | tail -n1 | awk '{print $10}' | xargs)
disk_available=$(df -BM / | tail -n1 | awk '{print $4}' | sed 's/M//' | xargs)

# Current time in `2019-11-26 14:40:19` UTC format
timestamp=$(date -u '+%Y-%m-%d %H:%M:%S')

# Subquery to find the matching id in the host_info table
host_id="(SELECT id FROM host_info WHERE hostname='$hostname')"

# PSQL command: inserts server usage data into the host_usage table
insert_stmt="INSERT INTO host_usage(\"timestamp\", host_id, memory_free, cpu_idle, cpu_kernel, disk_io, disk_available)
VALUES('$timestamp', $host_id, $memory_free, $cpu_idle, $cpu_kernel, $disk_io, $disk_available);"

# Set up env var for the psql command
export PGPASSWORD=$psql_password

# Insert the data into the database
psql -h "$psql_host" -p "$psql_port" -d "$db_name" -U "$psql_user" -c "$insert_stmt"
exit $?
