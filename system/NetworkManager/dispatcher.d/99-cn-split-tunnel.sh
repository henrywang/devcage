#!/bin/bash
ACTION="$2"
CN_LIST="/etc/chnroute.txt"

[ "$ACTION" = "vpn-up" ] || [ "$ACTION" = "vpn-down" ] || exit 0
[ -f "$CN_LIST" ] || exit 1

read -r LOCAL_GW LOCAL_DEV < <(
    ip route show default \
    | awk '!/ppp/ && /via/ {print $3, $5; exit}'
)
[ -n "$LOCAL_GW" ] || exit 1

case "$ACTION" in
    vpn-up)
        while IFS= read -r subnet; do
            [[ -z "$subnet" || "$subnet" == \#* ]] && continue
            ip route add "$subnet" via "$LOCAL_GW" dev "$LOCAL_DEV" 2>/dev/null
        done < "$CN_LIST"
        resolvectl dns ppp0 8.8.8.8 1.1.1.1
        resolvectl domain ppp0 '~.'
        logger "cn-split-tunnel: added China routes via $LOCAL_GW ($LOCAL_DEV), DNS via ppp0"
        ;;
    vpn-down)
        while IFS= read -r subnet; do
            [[ -z "$subnet" || "$subnet" == \#* ]] && continue
            ip route del "$subnet" 2>/dev/null
        done < "$CN_LIST"
        resolvectl revert ppp0
        logger "cn-split-tunnel: removed China routes, reverted DNS"
        ;;
esac
