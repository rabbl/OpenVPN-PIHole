#!/bin/bash

function valid_ip()
{
    local  ip=$1
    local  stat=1

    if [[ $ip =~ ^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$ ]]; then
        OIFS=$IFS
        IFS='.'
        ip=($ip)
        IFS=$OIFS
        [[ ${ip[0]} -le 255 && ${ip[1]} -le 255 \
            && ${ip[2]} -le 255 && ${ip[3]} -le 255 ]]
        stat=$?
    fi
    return $stat
}

OPENVPN_CONFIG_FILE=/openvpn/openvpn.conf

while [ ! -f ${OPENVPN_CONFIG_FILE} ]; do
    echo "   OpenVPN config file not found, waiting 1s"
    sleep 1
done

while true; do
    IP_PIHOLE=$(docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' pihole)
    echo "   The Pihole-IP is ${IP_PIHOLE}"

    if valid_ip ${IP_PIHOLE}; then
        sed -i -e 's/"dhcp-option DNS .*"/"dhcp-option DNS '${IP_PIHOLE}'"/g' ${OPENVPN_CONFIG_FILE}
        sleep infinity
    fi
done
