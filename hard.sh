#!/usr/bin/env bash

###########################
###        Variaveis
###########################

VERSION="1.1"
CREATOR="Lucas_Zafalon"
TIME1=1
TIME2=2

###########################
###        Collor
###########################

RESET="\033[0m"
GREEN="\033[32;1m"
PURPLE="\033[35;1m"
YELLOW="\033[33;1m"
REDP="\033[31;5m"
RED="\033[31;1m"
BLUE="\033[36;4m"

###########################
###        Funcoes
###########################

show_version() {
    echo -e "${BLUE}$(basename $0) $VERSION\nCreate by $CREATOR.${RESET}\n"
}

main() {
    echo "$(clear)"
    echo -e "${YELLOW}Registros atuais: \n"
    echo -e "Usuário: $(whoami)"
    echo -e "Diretório: $(pwd)"
    echo -e "Uptime: $(uptime)"
    echo -e "Máquina: $(hostname) $(hostname -I)"
    echo -e "Versão do sistema: $(cat /etc/*-release | grep "PRETTY_NAME")${RESET}"
    echo -e "${PURPLE}Inicio do Script: $(date)${RESET}"
}

check_dependences() {
    echo -e "${YELLOW}Verificando dependências...${RESET}"

    if ! command -v smartctl &> /dev/null; then
        echo -e "${RED}Smartctl não encontrado. Instalando...${RESET}"
        sudo apt-get update && sudo apt-get install -y smartmontools
    fi

    echo -e "${GREEN}Dependências verificadas.${RESET}"
}

################################################################################
###       Comandos
################################################################################

if [ "$(whoami)" != "root" ] ; then
echo "Rode esse script como usuário root"
exit 1
fi

check_dependences
main

################################################################################

LSCPU=$(lscpu | head -n 14 | tail -n 13)

LSBLK=$(lsblk -i)

DF=$(df -H)

FREE=$(free -h)

DiskName=$(lsblk -o NAME,TYPE | awk '$2 == "disk" {print $1; exit}')

REBOOT=$(sudo last -n40 -xF shutdown reboot)

################################################################################|-Rede

IFCONF=$(ifconfig)


ROUTE=$(route -n)


WF=$(wf-info)

ARP=$(arp -a)

################################################################################

main

echo -e "\n###############################\++++++++++${GREEN}REQUISITOS MINIMOS${RESET}++++++++++/#############################\n"
sleep $TIME1

echo -e "${YELLOW}Servidor Central:
        Processador: i5 10ª Geração 10400f ou superior. Recomendado processadores da linha i9 ou i7. (4 - 6 Núcleos)
        Memória RAM mínimo: 16gb
        Memória RAM recomendado: 32GB.
        Armazenamento mínimo - SSD/NVME: 500Gb.
        Armazenamento recomendado - SSD/NVME: 1 TB ${RESET}\n"

echo -e "${YELLOW}Servidor loja:
        Processador: i5 10ª Geração 10400f ou superior. Recomendado processadores da linha i9 ou i7. (4 - 6 Núcleos)
        Memória RAM mínimo: 8gb
        Memória RAM recomendado: 16GB.
        Armazenamento mínimo - SSD/NVME: 500Gb.
        Armazenamento recomendado - SSD/NVME: 1 TB ${RESET}\n"

echo -e "\n#######################################################\++++++++++++++++++++|${GREEN}Informações sobre a CPU\n${RESET}"
sleep $TIME2

echo -e "[${GREEN}lscpu${RESET}]\n"
echo "$LSCPU"
sleep $TIME1

echo -e "\n#######################################################\++++++++++++++++++++|${GREEN}Estrutura de blocos e armazenamento\n${RESET}"
sleep $TIME2

echo -e "[${GREEN}lsblk -i${RESET}] - Repartições do disco\n"
echo -e "$LSBLK\n"
sleep $TIME1

echo -e "[${GREEN}df -h${RESET}] - Uso de espaço em disco\n"
echo -e "$DF\n"
sleep $TIME1

echo -e "[${GREEN}free -h${RESET}] - Uso de memória RAM e swap\n"
echo -e "$FREE\n"
sleep $TIME1


echo -e "\n#######################################################\++++++++++++++++++++|${GREEN}Ultimos 40 Desligamentos\n${RESET}"
sleep $TIME2

echo -e "[${GREEN}last -n40 -xF shutdown reboot${RESET}]\n"
echo -e "$REBOOT\n"

echo -e "\n#######################################################\++++++++++++++++++++|${GREEN}Verificação Smart\n${RESET}"
sleep $TIME2

echo -e "[${GREEN}smartctl -a /dev/"$DiskName"${RESET}]\n"

result1=$(sudo smartctl -a /dev/"$DiskName" -d cciss,0 2>&1)

if [[ "$?" -ne 0 ]]; then
    
    result2=$(sudo smartctl -a /dev/"$DiskName" 2>&1)

    echo "$result2"
else
    
    echo "$result1"
fi

sleep $TIME2
echo -e "\n#######################################################\++++++++++++++++++++|${GREEN}Erros de memória - hs_err\n${RESET}"

cd /usr/wildfly/bin 2>/dev/null || exit
hs_err_files=$(ls -lsth | grep "hs_err")

if [[ -n "$hs_err_files" ]]; then
    echo "${REDP}Apresentado possíveis erros de memória:${RESET}"
    echo "$hs_err_files"
else
    echo -e "${GREEN}\nNenhum 'hs_err' encontrado.\n${RESET}"
fi

echo -e "\n#######################################################\++++++++++++++++++++|${GREEN}Base Corrompida - Segmentation\n${RESET}"

for version in 9.6 14; do
    log_dir="/var/lib/pgsql/${version}/data/pg_log"
    if [[ -d "$log_dir" ]]; then
        cd "$log_dir" 2>/dev/null || continue
        segmentation_logs=$(ls -lsth | grep "Segmentation" postgresql-* | cut -d':' -f1 | uniq -dc)
        if [[ -n "$segmentation_logs" ]]; then
            echo "${REDP}Apresentado Segmentation nos seguintes log's do PG BASE CORROMPIDA! (Versão $version)${RESET}"
            echo "$segmentation_logs"
        else
            echo -e "${GREEN}\nNenhuma 'segmentation' encontrada\n${RESET}"
        fi
    fi
done

echo -e "\n#######################################################\++++++++++++++++++++|${GREEN}Verificação de Rede\n${RESET}"
sleep $TIME2

echo -e "[${GREEN}ifconfig${RESET}] - Interfaces de rede\n"
echo -e "$IFCONF\n"

echo -e "[${GREEN}route -n${RESET}] - Rotas\n"
echo -e "$ROUTE\n"

echo -e "[${GREEN}Placas de rede${RESET}] - Configurações das placas de rede\n"

# Identificando as interfaces de rede
if command -v ifconfig &> /dev/null
then
    # ifconfig para listar interfaces de rede
    interfaces=($(ifconfig -a | grep -o '^[a-zA-Z0-9]\+'))
else
    # ip como alternativa para listar interfaces de rede
    interfaces=($(ip -o link show | awk -F': ' '{print $2}'))
fi

# Caminhos de configuração para CentOS e Oracle Linux
config_paths=(
    "/etc/sysconfig/network-scripts/ifcfg-"
    "/etc/NetworkManager/system-connections/"
)

# Iterando sobre as interfaces encontradas
for interface in "${interfaces[@]}"; do
    for config_path in "${config_paths[@]}"; do
        config_file="${config_path}${interface}"

        if [ -f "$config_file" ]; then
            echo -e "[${BLUE}Placa de rede ${interface}${RESET}]\n$"
            cat "$config_file"
            echo -e "\n"
        fi
    done
done

echo -e "[${GREEN}arp - a${RESET}] - Dispositivos na mesma rede\n"
echo -e "$ARP\n"


sleep $TIME1
echo -e "[${GREEN}wf -info${RESET}] - Wildfly\n"
echo -e "$WF\n"

echo -e "\n"

show_version

