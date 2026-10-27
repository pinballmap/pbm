# shellcheck shell=bash disable=SC2034
# Non-secret settings for pbm-server-setup. Fill the blanks from the
# pbm-server-inventory output of the current droplet. Secrets don't go here:
# app config is restored from the nightly pbm-env-*.txt backup instead.

APP=pbm

# Dokku release to install, e.g. v0.35.20. Use the current droplet's version
# unless a newer one is needed to support the Ubuntu release.
DOKKU_TAG="v0.38.32"

# From `dokku domains:report pbm` (Domains app vhosts).
DOMAINS="pinballmap.com www.pinballmap.com"

# From `dokku domains:report --global`; blank clears it. Only used for apps
# without their own domains (pbm has DOMAINS), but leaving it unset gets a
# "set a global domain" notice at every SSH login.
GLOBAL_DOMAIN="pinballmap.com"

# Order matters: jemalloc must come before ruby.
BUILDPACKS=(
  https://github.com/gaffneyc/heroku-buildpack-jemalloc.git
  https://github.com/heroku/heroku-buildpack-ruby.git
)

# Builder image, e.g. gliderlabs/herokuish:latest-24. Blank uses Dokku's
# default, which moves to newer stacks with Dokku releases. Pin it here only if
# the test deploy fails on a new default (e.g. no Ruby build for that stack).
BUILDPACK_STACK=""

# From `dokku ps:report pbm`, e.g. (web=1).
PS_SCALE=(web=1)

# Non-secret app config set by this script, on top of the restored env.
APP_CONFIG=(
  JEMALLOC_ENABLED=true
)

# From `dokku nginx:report pbm` (Nginx <property>, not computed). Uploads over
# the default 1m client-max-body-size fail.
NGINX_PROPERTIES=(
  client-max-body-size=12m
  proxy-buffer-size=30720
  "proxy-buffers=4 30720"
  proxy-busy-buffers-size=61440
)

# Let's Encrypt account email is a personal address, so it's passed at run
# time instead of kept in this public repo:
#   LETSENCRYPT_EMAIL=you@example.com bash pbm-server-setup
LETSENCRYPT_EMAIL="${LETSENCRYPT_EMAIL:-}"

# App logs, written by Vector to a file and rotated by logrotate-dokku-pbm.
VECTOR_IMAGE=timberio/vector:latest-debian
VECTOR_SINK="file://?encoding[codec]=text&path=/var/log/dokku/apps/pbm/pbm.log"

# Must match the old droplet: app.json cron schedules and the db backup cron
# run in this timezone.
TIMEZONE=Etc/UTC

# Swap file size; blank to skip. Prod has enough memory to build without it,
# but has swap anyway as a cushion. The low-memory staging droplet does need
# it, or asset builds get "Killed":
# https://dokku.com/docs/getting-started/troubleshooting/#build-fails-with-killed-message
SWAP_SIZE=2G

# Postgres client major version, matching the managed cluster.
PG_MAJOR=17
