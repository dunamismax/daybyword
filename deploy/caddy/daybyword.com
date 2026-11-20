# daybyword.com's site file for the host's own Caddy (docs/deploy.md), copied
# to /etc/caddy/sites/daybyword.com once P7.1 has confirmed the include
# convention. Caddy obtains and renews its own certificates for both names;
# DNS is the owner's, DNS-only. No access log is written: the app logs one
# metadata-only line per request itself, and Caddy's log would hold the
# address and its query (E17, E38).

daybyword.com {
	encode zstd gzip
	header Strict-Transport-Security "max-age=31536000"
	reverse_proxy 127.0.0.1:4316
}

www.daybyword.com {
	redir https://daybyword.com{uri} permanent
}
