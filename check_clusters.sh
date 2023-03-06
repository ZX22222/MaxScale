#!/bin/bash
 
### COLORS DEFINITION ###
red='\033[0;31m';green='\033[0;32m';yellow='\033[0;33m';cyan='\033[0;36m';clean='\033[0m';
 
### NODES DEFINITION ###
bdds=("SLT10670" "SLT10671")
maxscales=("SLT10673" "SLT10674")
 
### TEMPORARY LOG ###
output_file="/home/zabbix/scripts/check_cluster.log"
[ -f "$output_file" ] && rm "$output_file"
 
### BDD STATUS CHECK ###
printf "\n#############################\n\n" >> "$output_file"
printf "### BDD STATUS CHECK ###\n\n" >> "$output_file"
for bdd in "${bdds[@]}"
do
    printf "=> Mariadb on $bdd is : " >> "$output_file"
    echo "Connecting to $bdd for checking Mariadb status"
    ssh -q zabbix@"$bdd" -o StrictHostKeyChecking=no << EOF | sed '/Last login:/d' >> "$output_file"
        if netstat -tln | grep -q :3306 ; then printf "${green}Available${clean}\n\n";
        else
                printf "${red}Unavailable${clean}\n"
                sudo /bin/su - mysql -s /bin/bash << EOF2 | sed '/Last login:/d'
                sed -i '/^$/d' /logs/mariadb/mariadb.log
                tail -n1 /logs/mariadb/mariadb.log | sed 's/^\([^ ]*\) \([^ ]*\) \([^ ]*\).*/\1 \2 \3/'
EOF2
        fi
EOF
    done
 
datetime=$(grep -Eo '^20[0-9]{2}-[0-9]{2}-[0-9]{2}\s+[0-9]{1,2}:[0-9]{2}:[0-9]{2}\s+[0-9]+$' "$output_file")
if [[ -n "$datetime" ]]; then
    while read -r line; do
        date=$(echo "$line" | awk '{print $1}')
        time=$(echo "$line" | awk '{print $2}')
        if [[ -n "$date" ]] && [[ -n "$time" ]]; then
            saved_timestamp=$(date -d "$date $time" +"%s")
            current_timestamp=$(date +"%s")
            diff_seconds=$((current_timestamp - saved_timestamp))
            diff_days=$((diff_seconds / 86400)); diff_hours=$((diff_seconds / 3600 % 24)); diff_minutes=$((diff_seconds / 60 % 60)); diff_seconds=$((diff_seconds % 60));
            new_line="   KO since : $diff_days days, $diff_hours hours, $diff_minutes minutes, $diff_seconds seconds\n\n"
            sed -i "s/$line/$new_line/" "$output_file"
        fi
    done <<< "$datetime"
fi
 
unavailable_count=$(grep -c "Unavailable" "$output_file")
if [ "$unavailable_count" -eq 0 ]; then
    printf "All nodes are ${green}available${clean} -> ${green}CHECK OK${clean}\n" >> "$output_file"
elif [ "$unavailable_count" -eq 1 ]; then
    printf "One node is ${yellow}unavailable${clean} -> ${red}CHECK NOT OK${clean}\n" >> "$output_file"
    printf "${red}/!\ PLEASE INVESTIGATE THE SITUATION ON THE BDD CLUSTER /!\ ${clean}\n\n" >> "$output_file"
else
    printf "Both nodes are ${red}unavailable${clean} -> ${red}CHECK NOT OK${clean}\n" >> "$output_file"
    printf "${red}/!\ PLEASE INVESTIGATE THE SITUATION ON THE BDD CLUSTER /!\ ${clean}\n\n" >> "$output_file"
fi
 
### MAXSCALE STATUS CHECK ###
printf "\n#############################\n\n" >> "$output_file"
printf "### MAXSCALE STATUS CHECK ###\n" >> "$output_file"
 
maxscale_m_status=0
maxscale_s_status=0
 
for node in "${maxscales[@]}"
do
    case "$node" in
        "SLT10673")
            printf "\n=> MaxScale on $node is : " >> $output_file
            echo "Connecting to $node for checking MaxScale status"
            if ssh -q zabbix@"$node" -o StrictHostKeyChecking=no "pgrep maxscale &>/dev/null"; then
                maxscale_m_status=1
                maxscale_m_status_str="${green}Available${clean}"
            else
                maxscale_m_status_str="${red}Unavailable${clean}"
            fi
            printf "$maxscale_m_status_str\n" >> "$output_file"
            ;;
        "SLT10674")
            printf "\n=> MaxScale on $node is : " >> $output_file
            echo "Connecting to $node for checking MaxScale status"
            if ssh -q zabbix@"$node" -o StrictHostKeyChecking=no "pgrep maxscale &>/dev/null"; then
                maxscale_s_status=1
                maxscale_s_status_str="${green}Available${clean}"
            else
                maxscale_s_status_str="${red}Unavailable${clean}"
            fi
            printf "$maxscale_s_status_str\n\n" >> "$output_file"
            ;;
    esac
done
 
if [ $maxscale_m_status -eq 1 ] && [ $maxscale_s_status -eq 1 ]; then
    printf "Both MaxScale are running -> ${red}CHECK NOT OK${clean}\n" >> "$output_file"
elif [ $maxscale_m_status -eq 1 ] || [ $maxscale_s_status -eq 1 ]; then
    printf "Only one MaxScale is running -> ${green}CHECK OK${clean}\n" >> "$output_file"
else
    printf "None MaxScale are running -> ${red}CHECK NOT OK${clean}\n" >> "$output_file"
fi
 
### GARBD STATUS CHECK ###
printf "\n#############################\n\n" >> "$output_file"
printf "### GARB STATUS CHECK ###\n" >> "$output_file"
 
garbd_m_status=0
garbd_s_status=0
 
for node in "${maxscales[@]}"
do
    case "$node" in
        "SLT10673")
            printf "\n=> Galera Arbitrator on $node is : " >> $output_file
            echo "Connecting to $node for checking Galera Arbitrator status"
            if ssh -q zabbix@"$node" -o StrictHostKeyChecking=no "pgrep garb &>/dev/null"; then
                garbd_m_status=1
                garbd_m_status_str="${green}Available${clean}"
            else
                garbd_m_status_str="${red}Unavailable${clean}"
            fi
            printf "$garbd_m_status_str\n" >> "$output_file"
            ;;
        "SLT10674")
            printf "\n=> Galera Arbitrator on $node is : " >> $output_file
            echo "Connecting to $node for checking Galera Arbitrator status"
            if ssh -q zabbix@"$node" -o StrictHostKeyChecking=no "pgrep garb &>/dev/null"; then
                garbd_s_status=1
                garbd_s_status_str="${green}Available${clean}"
            else
                garbd_s_status_str="${red}Unavailable${clean}"
            fi
            printf "$garbd_s_status_str\n\n" >> "$output_file"
            ;;
    esac
done
 
if [ $garbd_m_status -eq 1 ] && [ $garbd_s_status -eq 1 ]; then
    printf "Both Galera Arbitrator are running -> ${red}CHECK NOT OK${clean}\n" >> "$output_file"
    printf "${red}/!\ PLEASE INVESTIGATE THE SITUATION ON THE GALERA CLUSTER /!\ ${clean}\n\n" >> "$output_file"
elif [ $garbd_m_status -eq 1 ] || [ $garbd_s_status -eq 1 ]; then
    printf "Only one Galera Arbitrator is running -> ${green}CHECK OK${clean}\n" >> "$output_file"
else
    printf "None Galera Arbitrator are running -> ${red}CHECK NOT OK${clean}\n" >> "$output_file"
    printf "${red}/!\ PLEASE INVESTIGATE THE SITUATION ON THE GALERA CLUSTER /!\ ${clean}\n\n" >> "$output_file"
fi
 
### RESULT DISPLAY ###
printf "\n#############################\n\n" >> "$output_file"
clear && cat $output_file
rm $output_file -f
