#!/bin/bash

# Comma separated list of domains to accept mail for
postconf -e "virtual_alias_domains = ${PF_VIRTUAL_ALIAS_DOMAINS}"

# FIXME: Test  Maps must include @
# Mapings between domains to accept mail for, and other domains
echo -e "${PF_VIRTUAL_ALIAS_MAPS}" > /etc/postfix/virtual

# Run postmap to hash virtual domains
postmap /etc/postfix/virtual

# Use virtual aliases
postconf -e "virtual_alias_maps = hash:/etc/postfix/virtual"


# Next hop for (final) destinations
if [ -z "${PF_TRANSPORT_MAPS}" ]; then
    postconf -e "transport_maps="
else
    echo -e "${PF_TRANSPORT_MAPS}" > /etc/postfix/transport
    postmap /etc/postfix/transport
    postconf -e "transport_maps=hash:/etc/postfix/transport"
fi

# Sender must send HELO
postconf -e "smtpd_helo_required=${PF_SMTPD_HELO_REQUIRED}"

# Helo restrictions
postconf -e "smtpd_helo_restrictions=${PF_SMTPD_HELO_RESTRICTIONS}"

# Sender restrictions
postconf -e "smtpd_sender_restrictions=${PF_SMTPD_SENDER_RESTRICTIONS}"

# TLS on incoming traffic
postconf -e "smtpd_tls_security_level=${PF_SMTPD_TLS_SECURITY_LEVEL}"

# TLS on outgoing traffic
postconf -e "smtp_tls_security_level=${PF_SMTP_TLS_SECURITY_LEVEL}"


# Run crond in the background (For daily reload of Postfix to pick up fresh certs)
crond -b -l 8 -L /dev/stdout

# Run postfix in the foreground
postfix start-fg
