FROM alpine:3.12

# A list of domains to accept mail for
ENV PF_VIRTUAL_ALIAS_DOMAINS "example1.com,example2.com"

# Domain mappings (From domain -> to domain)
ENV PF_VIRTUAL_ALIAS_MAPS "@example1.com @other-domain.com\n@example2.com @other-domain.com"

# Require HELO
ENV PF_SMTPD_HELO_REQUIRED "yes"

# HELO restrictions for serveres sending us mail
ENV PF_SMTPD_HELO_RESTRICTIONS "reject_unknown_helo_hostname,reject_invalid_helo_hostname,reject_non_fqdn_helo_hostname"

# Restrictions on senders
ENV  PF_SMTPD_SENDER_RESTRICTIONS "reject_unknown_client_hostname,reject_unknown_sender_domain"

# Install dependencies
#RUN apk add --no-cache --update postfix ca-certificates socat acme.sh bash && \
RUN apk add --no-cache --update postfix ca-certificates bash && \
    # Clean up
    (rm "/tmp/"* 2>/dev/null || true) && (rm -rf /var/cache/apk/* 2>/dev/null || true)

# Expose smtp port
EXPOSE 25

# Configure postfix
RUN mkdir /etc/postfix/certs && \
    # Postfix logs to stdout
    postconf -e "maillog_file=/dev/stdout" && \
    # Relay for no domains. Virtual domains added later
    postconf -e "relay_domains=" && \
    # Accept mail from outside for "user@example.com" but not for "user@anything.example.com"
    postconf -e "parent_domain_matches_subdomains=debug_peer_list,smtpd_access_maps" && \
    # Only accept mail from self
    postconf -e "mynetworks=127.0.0.0/8" && \
    # Only accept mail for mynetworks and domains in relay_domains
    postconf -e "smtpd_relay_restrictions=permit_mynetworks,reject_unauth_destination" && \
    # No local delivery
    postconf -e "mydestination=" && \
    postconf -e "local_recipient_maps=" && \
    postconf -e "local_transport=error:local mail delivery is disabled" && \
    # Trust these CAs
    postconf -e "smtpd_tls_CAfile=/etc/ssl/certs/ca-certificates.crt" && \
    # Comment out local delivery agent
    sed -i -E 's/(local[[:space:]]+unix)/#\1/g' /etc/postfix/master.cf && \
    # Outgoing TLS
    postconf -e "smtp_tls_loglevel=1" && \
    postconf -e "smtp_tls_key_file=/etc/postfix/certs/key.pem" && \
    postconf -e "smtp_tls_cert_file=/etc/postfix/certs/fullchain.pem" && \
    # Incoming TLS
    postconf -e "smtpd_tls_loglevel=1" && \
    postconf -e "smtpd_tls_received_header=yes" && \
    postconf -e "smtpd_tls_key_file=/etc/postfix/certs/key.pem" && \
    postconf -e "smtpd_tls_cert_file=/etc/postfix/certs/fullchain.pem" && \
    # Anti mail address harvesting
    postconf -e "disable_vrfy_command=yes"

# Script to reload postfix via cron (For reloading certificates)
COPY src/reload-postfix /etc/periodic/daily/

# Script to configure, and start postfix
COPY src/entrypoint.sh /usr/local/bin/

# Configure postfix, and start in foreground mode
ENTRYPOINT ["entrypoint.sh"]
