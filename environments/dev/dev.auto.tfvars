project = "nvoss-dogcat-dev"
region = "europe-west3"

# The cluster will also manage a DNS-zone, so a pre-existing DNS-zone managed
# by Google Cloud is required for this to work. Alternatively you'll have to point
# a Route53 zone to the nameservers used by the create sub-zone.
# The project-name, zone-name and desired fqdn for dedidcated zone are required:
dns_project        = "nvoss-demo-dns"
dns_zone_name      = "nvoss-demo"
dns_dedicated_fqdn = "shared.dogcat.nvoss.demo.altostrat.com."

# Cert-Manager will use let's encrypt and to self-register we need an email as well
letsencrypt_email    = "nvoss@google.com"
cert_manager_version = "v1.11.0" # chart-version

# We use external-dns to setup DNS records for our Ingress resources
external_dns_version = "v6.14.0" # chart-version
