#!/bin/bash
set -euo pipefail

set -a
source $(pwd)/.env.babylon-integration
set +a

# reference: https://developers.cloudflare.com/api/operations/dns-records-for-a-zone-batch-dns-records
create_dns_records() {
    local names=("$@")
    local records=""
    
    for name in "${names[@]}"; do
        if [ -n "$records" ]; then
            records="${records},"
        fi
        records="${records}
        {
            \"type\": \"A\",
            \"name\": \"${name}.${CLOUDFLARE_DNS_SUBDOMAIN}\",
            \"content\": \"$FINALITY_SYSTEM_SERVER_IP\",
            \"proxied\": false
        }"
    done

    curl --request POST \
        --url "https://api.cloudflare.com/client/v4/zones/$CLOUDFLARE_ZONE_ID/dns_records/batch" \
        --header "Content-Type: application/json" \
        --header "X-Auth-Email: $CLOUDFLARE_AUTH_EMAIL" \
        --header "X-Auth-Key: $CLOUDFLARE_API_KEY" \
        --data "{
            \"posts\": [${records}]
        }"
}

# 1. create the DNS records for the subdomains
# (finality gadget RPC, demo app, finality explorer)
create_dns_records "finality-rpc" "demo" "finality"

# 2. obtain the SSL certificate for each subdomain
# the certs will be stored in /etc/letsencrypt/live/${CERTBOT_DOMAIN_SUFFIX}
# 
# note that Certbot creates a single certificate that's valid for all those 
# domains (called a SAN - Subject Alternative Names certificate)
# 
# after running the command, you can verify by:
#   sudo openssl x509 -in /etc/letsencrypt/live/${CERTBOT_DOMAIN_SUFFIX}/fullchain.pem -text | grep DNS:
# 
# reference: https://eff-certbot.readthedocs.io/en/latest/using.html
sudo certbot certonly --nginx --non-interactive --agree-tos -m ${CERTBOT_EMAIL} \
  --cert-name ${CERTBOT_DOMAIN_SUFFIX} \
  -d finality-rpc.${CERTBOT_DOMAIN_SUFFIX} \
  -d demo.${CERTBOT_DOMAIN_SUFFIX} \
  -d finality.${CERTBOT_DOMAIN_SUFFIX}
