# VPN Split-Tunnel Setup

L2TP/IPsec VPN managed by NetworkManager, with split-tunnel routing so Chinese traffic goes directly through the local gateway and foreign traffic goes through the VPN.

## How it works

### Routing

On `vpn-up`, `99-cn-split-tunnel.sh` reads `/etc/chnroute.txt` and adds a route for every Chinese subnet via the local gateway (`wlp2s0`). The VPN default route (`ppp0`) handles everything else.

On `vpn-down`, those routes are removed.

### DNS

The local router (`192.168.50.1`) is GFW-poisoned — it returns bogus IPs for foreign domains (Google, DuckDuckGo, etc.). The VPN server pushes `8.8.8.8`/`8.8.4.4` via pppd, but NetworkManager doesn't apply them to `systemd-resolved` by default.

The dispatcher fixes this on `vpn-up`:

```bash
resolvectl dns ppp0 8.8.8.8 1.1.1.1
resolvectl domain ppp0 '~.'
```

`~.` makes `ppp0` the default DNS route for all domains. On `vpn-down`, `resolvectl revert ppp0` restores the router DNS for Chinese sites.

DNS queries all go to `8.8.8.8`/`1.1.1.1`, including Chinese domains — that's fine because `8.8.8.8` returns real IPs, and the China routing table then sends that traffic through the local gateway as expected.

## Initial setup

Fetch the China IP list:

```bash
sudo curl -o /etc/chnroute.txt https://raw.githubusercontent.com/17mon/china_ip_list/master/china_ip_list.txt
```

Deploy the dispatcher script:

```bash
sudo cp system/NetworkManager/dispatcher.d/99-cn-split-tunnel.sh /etc/NetworkManager/dispatcher.d/
```

## Refreshing the China IP list

The list changes infrequently; re-fetch it every few months:

```bash
sudo curl -o /etc/chnroute.txt https://raw.githubusercontent.com/17mon/china_ip_list/master/china_ip_list.txt
```
