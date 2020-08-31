# postfix-inbound-gateway
A Docker image based on Alpine Linux with Postfix running as an inbound gateway.

Configure the domains you want to receive mail for, and which domains to rewrite to.
This essentialy adds a domain as an alias for all (configurable) users in
another (currently used) domain.

Mail is never delivered locally.

# Volumes

* /var/spool/postfix: Mails beeing processed are stored here
* /etc/postfix/certs: Make certs available to postfix in this dir (See TLS)

# TLS
For TLS to work you need to add the following valid chain file in the container.
* */etc/postfix/certs/certs.pem*

Read more in the Postfix documentation for [smtpd_tls_chain_files]{http://www.postfix.org/postconf.5.html#smtpd_tls_chain_files}.
and [smtp_tls_chain_files]{http://www.postfix.org/postconf.5.html#smtp_tls_chain_files}.

You can run [this container]{https://hub.docker.com/r/neilpang/acme.sh} to
create certificates using [acme.sh]{https://github.com/acmesh-official/acme.sh}. 

A cronjob reloads Postfix daily to pick up (renewed) certificates.


# Environment variables
The container can be configured through the following environment variables.
The names of the variables correspond with the Postfix configuration parameters,
bit with a prefix of *PF_*.  


## PF_MYHOSTNAME
The fully qualified domain name of the mail server.

## PF_VIRTUAL_ALIAS_DOMAINS
Comma separated list of domains to receive mails for. If a domain is not
in this list, it will be rejected.
__Example__: *"example1.com, example2.com"*

## PF_VIRTUAL_ALIAS_MAPS
Lines of mappings for incoming mails. The following example will forward mail
for all users in the domain *example1.com* to the same user-name in domain *other-domain.com*.
Mappings are separated by new line characters. The source (first) domain MUST be in *PF_VIRTUAL_ALIAS_DOMAINS*.
__Example__: *"@example1.com @other-domain.com"*

## PF_TRANSPORT_MAPS
The mail servers to deliver mail to. If this value is not sent, postfix will
use the mail servers found in DNS when forwarding mail. If mappings are supplied here,
the server(s) specified will be used. Mappings are separated by new lines.
**Example**: *"@other.domain.com smtp:some-gateway-not_in_dns.other-domain.com:25"*


## PF_SMTPD_TLS_SECURITY_LEVEL
Configure the use of STARTTLS with incoming mail. [Postfix documentation]{http://www.postfix.org/postconf.5.html#smtpd_tls_security_level}.
* may: Prefer STARTLS to unencrypted connections
* encrypt: Demand STARTLS
* none: Don't use STARTLS

Default value: *none*

## PF_SMTP_TLS_SECURITY_LEVEL
Configure the use of STARTTLS with outgoing mail. [Postfix documentation]{http://www.postfix.org/postconf.5.html#smtp_tls_security_level}.
* may: Prefer STARTLS to unencrypted connections
* encrypt: Demand STARTLS
* none: Don't use STARTLS
* More options in documentation

Default value: *none*

## PF_SMTPD_HELO_REQUIRED
[Postfix documentation]{http://www.postfix.org/postconf.5.html#smtpd_helo_required}.
Default value: *yes*

## PF_SMTPD_HELO_RESTRICTIONS
[Postfix documentation]{http://www.postfix.org/postconf.5.html#smtpd_helo_restrictions}.
Default value: *reject_unknown_helo_hostname*

## PF_SMTPD_SENDER_RESTRICTIONS
[Postfix documentation]{http://www.postfix.org/postconf.5.html#smtpd_sender_restrictions}.
You can configure the use of real time blacklists here.
Default value: *"reject_unknown_client_hostname,reject_unknown_sender_domain"*

# Running a sidecar container creating certificates

* docker pull neilpang/acme.sh
