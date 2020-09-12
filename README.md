# An OpenVPN-server combined with PI-Hole

This project provides ready to use setup for an openvpn-server combined with the advertisement-blocker PI-Hole.

## Why?

To get rid of internet advertisements on your devices you have an endless list of filters and extensions for each platform or device.  

Another approach is to block it directly in your router or setup a device which is doing this job.  

[PI-Hole](https://pi-hole.net/) does "Network-wide ad blocking via your own Linux hardware" without client software needed. It runs on every Linux-based OS, is easy to install and runs happily on a Raspberry-Pi inside of your network.  

The only think you have to do is routing your DNS-Requests through the PI-Hole machine.

I wanted to have the choice to block or not so my idea was to setup a VPN-Server together with PI-Hole on my local network. So I am free to use it or not. I can use the openVPN-client from everywhere to connect to my home-zone and surf the web at the same time without spending mobile-data for advertisements.  

The infrastructure consists of 4 parts:

* the [openVPN-Server](https://github.com/kylemanna/docker-openvpn)
* the [PI-Hole DNS-Server](https://github.com/pi-hole/docker-pi-hole)
* a startup-container to set the correct PI-Hole-DNS-IPs in openVPN
* a DynDNS-container for announcing my home-IP regularly 

## How to install?

Make sure you have docker and docker-compose installed.  
Download or clone this repository. 

```
$ git clone https://github.com/rabbl/OpenVPN-PIHole.git
$ cd OpenVPN-PIHole
```

### Configuration

We need to configure the OpenVPN-Server as in the [instructions from kylemanna](https://github.com/kylemanna/docker-openvpn/blob/master/docs/docker-compose.md).  

### Copy and adapt the .env-file

```
$ cp .env.example .env
```

The env-file has the following env-variables:

* PIHOLE_SERVER_IP: put the internal IP of the machine here (e.g. 192.168.1.112)
* PIHOLE_TIMEZONE: the [IANA](https://www.iana.org/time-zones)-Timezone (e.g. Europe/Berlin)
* PIHOLE_WEBPASSWORD: you need it if you want to login to the PI-Hole dashboard
* PIHOLE_DNS1: Primary DNS (e.g. 8.8.8.8)
* PIHOLE_DNS2: Secondary DNS (e.g. 8.8.4.4)
* PIHOLE_VIRTUAL_HOST: the name of the virtual host, like defined with your dyndns-provider (e.g. pihole.example.org)
* PIHOLE_HTTP_PORT: The port on the host-machine which is mapped to the server (e.g. 8080)

### Initialize the configuration files and certificates

```
$ docker-compose run --rm openvpn ovpn_genconfig -u udp://VPN.YOUR-SERVER-NAME.HERE
$ docker-compose run --rm openvpn ovpn_initpki
```

### Fix ownerships (optional)

```
$ sudo chown -R $(whoami): ./openvpn-data
```

### Copy and adapt the crontab-file for dyndns updates

```
$ cp ./crontabs/root.example ./crontabs/root
```

In my case (working with [kasserver from all-inkl](https://all-inkl.com/)) the cronjob is a simple curl-request to my provider with the credentials set.

```
# File ./contabs/root, executed every 5 minutes
*/5 * * * * curl https://ddns_username:ddns_password@dyndns.kasserver.com 
```

Now you can startup the containers with docker-compose

```
$ docker-compose up -d
```

You can access the container logs with

```
$ docker-compose logs -f
```

### Generate a client-certificate

With a passphrase (recommended)

```
$ export CLIENTNAME="your_client_name"
$ docker-compose run --rm openvpn easyrsa build-client-full $CLIENTNAME
```

Without a passphrase (not recommended)

```
$ export CLIENTNAME="your_client_name"
$ docker-compose run --rm openvpn easyrsa build-client-full $CLIENTNAME nopass
```

Retrieve the client configuration with embedded certificates

```
$ docker-compose run --rm openvpn ovpn_getclient $CLIENTNAME > $CLIENTNAME.ovpn

```

Now you can import the certificate in your openVPN-client.

### Revoke a client certificate

Keep the corresponding crt, key and req files.

```
$ docker-compose run --rm openvpn ovpn_revokeclient $CLIENTNAME
```

Remove the corresponding crt, key and req files.

```
$ docker-compose run --rm openvpn ovpn_revokeclient $CLIENTNAME remove
```

## Debugging

Create an environment variable with the name DEBUG and value of 1 to enable debug output (using "docker -e").

```
$ docker-compose run -e DEBUG=1 openvpn
```

## Known problems

I have some issues with the Mac-OpenVPN client Tunnelblick establishing reliable connections. But I'm working on it.  


## Happy surfing without advertisements ;)
