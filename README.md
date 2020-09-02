# postfix-inbound-gateway
A Docker image based on Alpine Linux with Postfix running as an inbound gateway.

Configure the domains you want to receive mail for, and which domains to rewrite to.
This essentialy adds a domain as an alias for all (configurable) users in
another (currently used) domain.

Mail is never delivered locally. Configure your container using the environment
variables described on this page.

The container logs to stdout.

Run the image in a container
1. `docker pull tobiasbp/postfix-inbound-gateway`
2. `docker run --rm --hostname mymail.example.com --name postfix-demo  -p 2525:25 tobiasbp/postfix-inbound-gateway`
3. You can now connect to the gateway at `localhost:2525`.
4. Play around with [swaks](http://www.jetmore.org/john/code/swaks/) to test your configuration.

You may disable som of the sender restrictions (See below) when testing.
Also, a lot of ISPs will block outgoing traffic on port 25 (SMTP default),
so you may need to make Postfix avaliable on another port, like 2525, while testing.

Make sure:
1. The hostname of the container matches the [_fqdn_](https://en.wikipedia.org/wiki/Fully_qualified_domain_name) of your server
2. Configure [reverse DNS](https://en.wikipedia.org/wiki/Reverse_DNS_lookup) so the server's IP, resolves to your server's_FQDN_.

# Directories
You should probably create volumes for the following directories
* /var/spool/postfix: Mails beeing processed are stored here
* /etc/postfix/certs: Make certs available to postfix in this dir (See TLS)

# TLS
For TLS to work you need to add the following valid files in the container.
* */etc/postfix/certs/key.pem*
* */etc/postfix/certs/fullchain.pem*

You can run [this container](https://hub.docker.com/r/neilpang/acme.sh) to
create certificates using [acme.sh](https://github.com/acmesh-official/acme.sh/wiki/Run-acme.sh-in-docker)
and place them in */etc/postfix/certs*.

A cronjob in this image reloads Postfix daily to pick up (renewed) certificates.
If you do not supply certificates, support for TLS will be disabled.

# Environment variables
The container can be configured through the following environment variables.
The names of the variables correspond with the Postfix configuration parameters,
but with a prefix of *PF_*.


## PF_VIRTUAL_ALIAS_DOMAINS
Comma separated list of domains to receive mails for. If a domain is not
in this list, it will be rejected.

**Example**: *"example1.com, example2.com"*

## PF_VIRTUAL_ALIAS_MAPS
Lines of mappings for incoming mails. The following example will forward mail
for all users in the domain *example1.com* to the same user-name in domain *other-domain.com*.
Mappings are separated by new line characters. The source (first) domain MUST be in *PF_VIRTUAL_ALIAS_DOMAINS*.

**Example**: *"@example1.com @other-domain.com"*

## PF_TRANSPORT_MAPS
The mail servers to deliver mail to. If this value is not sent, postfix will
use the mail servers found in DNS when forwarding mail. If mappings are supplied here,
the server(s) specified will be used. Mappings are separated by new lines.

**Example**: *"@other.domain.com smtp:some-gateway-not_in_dns.other-domain.com:25"*


## PF_SMTPD_TLS_SECURITY_LEVEL
Configure the use of STARTTLS with incoming mail. [Postfix documentation](http://www.postfix.org/postconf.5.html#smtpd_tls_security_level).
* may: Prefer STARTLS to unencrypted connections
* encrypt: Demand STARTLS
* none: Don't use STARTLS

Default value: *none*

## PF_SMTP_TLS_SECURITY_LEVEL
Configure the use of STARTTLS with outgoing mail. [Postfix documentation](http://www.postfix.org/postconf.5.html#smtp_tls_security_level).
* may: Prefer STARTLS to unencrypted connections
* encrypt: Demand STARTLS
* none: Don't use STARTLS
* More options in documentation

Default value: *none*

## PF_SMTPD_HELO_REQUIRED
[Postfix documentation](http://www.postfix.org/postconf.5.html#smtpd_helo_required).
Default value: *yes*

If this is not enabled, none of the restrictions below will be enforced.

## PF_SMTPD_HELO_RESTRICTIONS
[Postfix documentation](http://www.postfix.org/postconf.5.html#smtpd_helo_restrictions).
Default value: *reject_unknown_helo_hostname,reject_invalid_helo_hostname,reject_non_fqdn_helo_hostname*

## PF_SMTPD_SENDER_RESTRICTIONS
[Postfix documentation](http://www.postfix.org/postconf.5.html#smtpd_sender_restrictions).
You can configure the use of real time blacklists here.
Default value: *"reject_unknown_client_hostname,reject_unknown_sender_domain"*

# Running a sidecar container creating certificates
In this example, */var/certs* is maped to a Docker volume which is mounted at */etc/postfix/certs* in the Postfix container.

Run acme.sh in a container. A cronjob in the container will renew certificates:
* `docker run --rm  -itd --name=acme.sh neilpang/acme.sh daemon`

Create a certficate in the acme.sh container:
* `docker exec acme.sh --issue -d mail02.everland.no --standalone --fullchain-file /var/certs/fullchain.pem --key-file /var/certs/key.pem --alpn`
