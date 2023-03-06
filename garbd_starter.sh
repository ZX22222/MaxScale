#!/bin/bash

red='\033[0;31m';green='\033[0;32m';yellow='\033[0;33m';cyan='\033[0;36m';clean='\033[0m';

is_running() {
        printf "${yellow}Please start this script on the second maxscale node\n"
        printf "to make sure the arbitrator IS running on it${clean}\n\n"
}

is_not_running() {
        printf "${yellow}Please start this script on the second maxscale node\n"
        printf "to make sure the arbitrator IS NOT running on it${clean}\n\n"
}

if pgrep maxscale &>/dev/null; then
        printf "\nMaxScale is ${green}RUNNING${clean}\n"
        if pgrep -f 'garbd -c /etc/my.cnf.d/galera.cnf -d' &>/dev/null; then
                printf "Galera Arbitrator is ${green}RUNNING${clean}"
                printf " -> ${cyan}CHECK OK${clean}\n\n"
                is_not_running
        else
                printf "Galera Arbitrator is ${red}NOT RUNNING${clean}"
                printf " -> ${yellow}CHECK NOT OK${clean}\n\n"
                printf "${yellow}Starting Galera Arbitrator${clean}\n"
                garbd -c /etc/my.cnf.d/galera.cnf -d
                if pgrep -f 'garbd -c /etc/my.cnf.d/galera.cnf -d' &>/dev/null; then
                        printf "Galera Arbitrator is ${green}RUNNING${clean}"
                        printf " -> ${cyan}RESTART SUCCEED${clean}\n\n"
                        is_not_running
                else
                        printf "Galera Arbitrator is ${red}NOT RUNNING${clean}"
                        printf "${red} -> RESTART FAILED${clean}\n\n"
                        printf "${red}Please investigate this issue${clean}\n\n"
                fi
        fi
else
        printf "\nMaxScale is ${yellow}NOT RUNNING${clean}\n"
        if pgrep -f 'garbd -c /etc/my.cnf.d/galera.cnf -d' &>/dev/null; then
                printf "Galera Arbitrator is ${red}RUNNING${clean}"
                printf " -> ${yellow}CHECK NOT OK${clean}\n\n"
                printf "${yellow}Stopping Galera Arbitrator${clean}\n"
                kill -9 $(pgrep -f 'garbd -c /etc/my.cnf.d/galera.cnf -d')
                if pgrep -f 'garbd -c /etc/my.cnf.d/galera.cnf -d' &>/dev/null; then
                        printf "Galera Arbitrator is ${red}RUNNING${clean}"
                        printf " -> ${red}STOP FAILED${clean}\n\n"
                        printf "${yellow}Please kill the arbitrator process manually${clean}\n"
                        printf "${yellow}and start this script on the second maxscale node${clean}\n\n"
                else
                        printf "Galera Arbitrator is ${green}NOT RUNNING${clean}"
                        printf " -> ${cyan}STOP SUCCEED${clean}\n\n"
                        is_running
                fi
        else
                printf "Galera Arbitrator is ${green}NOT RUNNING${clean}"
                printf " -> ${cyan}CHECK OK${clean}\n\n"
                is_running
        fi
fi
