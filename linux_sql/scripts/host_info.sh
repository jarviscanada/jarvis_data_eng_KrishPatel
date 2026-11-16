#! /bin/bash

# Usage: ./scripts/host_info.sh psql_host psql_port db_name psql_user psql_password
# Example: ./scripts/host_info.sh "localhost" 5432 "host_agent" "postgres" "password1234"

# Capture CLI(command-line arguments in order) arguments
# Coping them into named variables makes the reset of the script readable.
psql_host=$1
psql_port=$2
db_name=$3
psql_user=$4
psql_password=$5

# Validate the number of arguments
if [ "$#" -ne 5 ]; then
	echo "Illegal number of parameters"
	echo "Usage: $0 psql_host psql_port db_name psql_user psql_password"
	exit 1
fi

# Collect hardware spece (run lscpu once anf reuse the output)
lscpu_out=$(lscpu)
hostname=$(hostname -f)
cpu_number=$(echo "$lscpu_out" | egrep "^CPU\(s\):" | awk '{print $2}' | xargs)
cpu_architecture=$(echo "$lscpu_out" | egrep "^Architecture:" | awk '{print $2}' | xargs)
cpu_model=$(echo "$lscpu_out" | egrep "^Model name:" | awk -F: '{print $2}' | xargs)
cpu_mhz=$(grep -m1 "cpu MHz" /proc/cpuinfo | awk -F: '{print $2}' | xargs)
# L2 cache in kB (converts MiB to kB if lscpu reports MiB)
l2_cache=$(echo "$lscpu_out" | egrep "^L2 cache:" | awk '{v=$3+0; if ($4 ~ /^M/) v=v*1024; print v}')
total_mem=$(grep MemTotal /proc/meminfo | awk '{print $2}' | xargs)
# Current time in UTC
timestamp=$(date -u '+%Y-%m-%d %H:%M:%S')

# Construct the INSERT statement
insert_stmt="INSERT INTO host_info(hostname, cpu_number, cpu_architecture, cpu_model, cpu_mhz, l2_cache, \"timestamp\", total_mem)
VALUES('$hostname', $cpu_number, '$cpu_architecture', '$cpu_model', $cpu_mhz, $l2_cache, '$timestamp', $total_mem);"

# Set the password in an env var so psql doesn't prompt for it 
export PGPASSWORD=$psql_password

# Excecute the Insert statement through the psql CLI
psql -h "$psql_host" -p "$psql_port" -d "$db_name" -U "$psql_user" -c "$insert_stmt"
exit $?
