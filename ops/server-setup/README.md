# App droplet setup

Rebuilds the pbm app droplet from a fresh Ubuntu install. Use it for Ubuntu
upgrades (build a new droplet instead of running `do-release-upgrade`) and
for disaster recovery. The main Postgres database is a DO Managed Database.
The droplet only holds the Solid Cache database (Dokku postgres service
`pbm-cache`), which is fine to lose, so the droplet can be replaced at any
time. Solid Queue's jobs are in the managed database, so both droplets share
one queue during cutover and nothing is stranded.

- `pbm-server-inventory` is read-only. It prints the droplet's Dokku and host
  settings, with config var names but not their values.
- `settings.sh` holds the non-secret settings that `pbm-server-setup` applies.
- `pbm-server-setup` does the install. It's safe to rerun.
- `logrotate-dokku-pbm` rotates the app logs written by the Vector sink.
- `abuseipdb.sh`, `.service` and `.timer` load the ipset blocklist at boot
  and refresh it daily: the ipsum list plus `/home/dokku/tmp/banned_ips.txt`,
  which isn't in git. After editing that file, apply it with
  `systemctl start abuseipdb`.
- `blocked-agents.conf` is the nginx user-agent blocklist. It's kept out of
  git on purpose, so blocked clients can't see what to change to get around
  it. Copy it from the old droplet (step 1). `blocked-agents.conf.example`
  shows the format and blocks nothing; the script falls back to it, with a
  warning, if there's no copy.

Secrets aren't kept here. App config comes from the nightly `pbm-env-*.txt`
backup (see `ops/db-backup/README.md`), and the Let's Encrypt email is passed
in when you run the script.

## What a rebuild depends on

The goal is that a rebuild works from the repo and backups alone, even if
the old droplet is gone. The old droplet is only a fallback during cutover.

| Item | Source |
|---|---|
| Dokku, app settings, nginx, logs, blocklist, backup tooling | this repo (`ops/`) |
| `settings.sh` values | taken from the inventory once, then kept in git |
| `blocked-agents.conf` | copied from the old droplet; not in git. Fine to lose, but it starts empty |
| App env vars | nightly `pbm-env-*.txt` in S3 |
| `/etc/pbm-db-backup.env` | DO panel for the DB; a new IAM access key if the old one is lost |
| TLS certificate | issued fresh by Let's Encrypt |
| SSH keys | your machine / DO account |
| `banned_ips.txt` | copied if available; fine to lose |
| Database | DO Managed Database, not on the droplet |
| Cache database | created empty |
| Job queue | in the managed database |

If a rehearsal needs anything else from the old droplet, add it to the repo or
to a backup.

Third-party Dokku plugins have to be installed by the script; the built-in
ones come with Dokku. Compare the inventory's `plugin:list` against the
script. A plugin that holds data (e.g. a new service in `dokku postgres:list`
besides `pbm-cache`) means data on the droplet that may need
its own backup.

## One-time prep

- Give the current droplet a **Reserved IP** and point DNS at it. Cutover
  and rollback then mean moving the IP in the DO panel, which takes seconds
  and doesn't wait for DNS to update. DO hands out a new address; it can't
  reserve the droplet's current one. The droplet keeps its own IP too, so
  nothing goes down while DNS changes over:
  1. Lower the TTL on the DNS records a day ahead.
  2. Check nginx listens on all addresses: `ss -tlnp | grep nginx` should
     show `0.0.0.0` and `[::]` on 80 and 443, not a specific IP.
  3. Reserve the IP and assign it to the droplet.
  4. From your machine, check it answers, TLS and firewall included:
     `curl -sI --resolve pinballmap.com:443:RESERVED_IP https://pinballmap.com/`
  5. Point DNS at the Reserved IP. Update anything else that has the old IP
     written down, such as firewall allowlists or monitoring.

  Outbound traffic still leaves from the droplet's own IP, which changes with
  every rebuild. Anything that allowlists the server's IP (DB Trusted
  sources, API key IP restrictions) has to be updated per droplet.
- Set a root password on the droplet (`passwd`). The DO Recovery Console
  needs one, and it's the only way in if SSH breaks.

## Building a new droplet

### 1. Inventory the old droplet

From the project folder on your machine:

```bash
mkdir -p ~/pbm-ops
ssh root@OLD 'bash -s' < ops/server-setup/pbm-server-inventory > ~/pbm-ops/old-inventory.txt
scp root@OLD:/home/dokku/pbm/nginx.conf.d/blocked-agents.conf ops/server-setup/
```

The inventory goes outside the repo because it's only a reference and lists
IPs, domains and config var names. Fill in the blanks in `settings.sh` from
`~/pbm-ops/old-inventory.txt` and commit it. Look over
`blocked-agents.conf` but don't commit it; `.gitignore` keeps it out. Look
through the inventory for anything the
script doesn't handle, such as extra plugins, `docker-options`, `checks`,
`resource` limits, custom `ports`, files in `/etc/nginx/conf.d`, or other
`/etc/cron.d` jobs. Add those to the script or note them here.

Check that the Dokku release in `DOKKU_TAG` supports the new Ubuntu version.
Its bootstrap installs Docker from Docker's apt repo, which also has to
support that release.

### 2. Create and set up the droplet

Create a droplet on the new Ubuntu LTS with your SSH key, in the same region
as the managed DB. Add it to the database's **Trusted sources** in the DO
panel. Then:

```bash
scp -r ops root@NEW:/root/
ssh root@NEW 'mkdir -p /home/dokku/tmp'
scp root@OLD:/home/dokku/tmp/banned_ips.txt root@NEW:/home/dokku/tmp/
ssh root@NEW
LETSENCRYPT_EMAIL=you@example.com bash /root/ops/server-setup/pbm-server-setup
passwd   # for the Recovery Console
```

The script ends by listing anything left to do. On a new app it suspends the
`app.json` cron jobs so digest emails don't go out from both droplets.

### 3. Restore app config

Download the latest `pbm-env-*.txt` from the backup bucket with your own AWS
credentials. Copy the app's line (without the leading `#` comment) to the
droplet as `app-env.txt`, then:

```bash
eval "dokku config:set --no-restart pbm $(cat app-env.txt)"
shred -u app-env.txt
```

Then link the cache database. The alias gives the env var name
`config/database.yml` reads. The restore just set it to the old droplet's
URL, and `postgres:link` won't overwrite it, so unset it first.
`DOKKU_POSTGRES_AQUA_URL` is left over from an unused queue database, so it
goes too if it's there:

```bash
dokku config:unset --no-restart pbm DOKKU_POSTGRES_BLACK_URL DOKKU_POSTGRES_AQUA_URL
dokku postgres:link pbm-cache pbm --alias DOKKU_POSTGRES_BLACK
dokku config:show pbm | grep DOKKU_POSTGRES   # one URL, naming pbm-cache
```

Delete your local copy too. Then fill in `/etc/pbm-db-backup.env` (the values
are in the same DO panel page as before) and test it with
`/usr/local/bin/pbm-db-backup`.

### 4. Deploy

Deploy the same commit production is running. The `release` phase runs
`db:migrate` against the production database.

```bash
git remote add new dokku@NEW:pbm
git push new master
```

If the script warned that this Dokku can't suspend cron for an app, run
`crontab -r -u dokku` on the droplet after every deploy until cutover.

### 5. Test before cutover

Compare the two droplets:

```bash
ssh root@NEW 'bash -s' < ops/server-setup/pbm-server-inventory > ~/pbm-ops/new-inventory.txt
diff ~/pbm-ops/old-inventory.txt ~/pbm-ops/new-inventory.txt
```

Then give the new droplet a temporary self-signed certificate. The app
redirects to HTTPS, and nothing answers there until cutover:

```bash
dokku certs:generate pbm pinballmap.com
```

Then open a throwaway Chrome profile that sends pinballmap.com to the new
droplet, while your other windows stay on production (`chromium` works too):

```bash
google-chrome --user-data-dir=/tmp/pbm-test --host-resolver-rules="MAP pinballmap.com NEW_IP, MAP www.pinballmap.com NEW_IP"
```

Expect a certificate warning, since Let's Encrypt isn't set up yet; click
Advanced, then Proceed. The warning is also how you know you're on the new
droplet. Images load from www.pinballmap.com, so open
`https://www.pinballmap.com` once and Proceed there too, or they show broken. Use a fresh profile rather than `/etc/hosts`: a browser that has
visited pinballmap.com remembers to require HTTPS (HSTS) and won't let you
past the warning.

Check the map, search, login, an API call, and an image upload. These all
hit the production database and S3, so clean up anything you create. Close
the window and `rm -rf /tmp/pbm-test` when you're done.

For a quick check without a browser:

```bash
curl -k --resolve pinballmap.com:443:NEW_IP https://pinballmap.com/api/v1/regions.json | head -c 300
```

Reboot the new droplet once and confirm it comes back with SSH and the app up.

### 6. Cutover

1. Move the Reserved IP to the new droplet.
2. From your machine, confirm traffic reaches the new droplet. The issuer is
   your self-signed `pinballmap.com` cert there, and Let's Encrypt (`R11` or
   similar) while it's still the old one:

   ```bash
   curl -vsI https://pinballmap.com 2>&1 | grep -i issuer
   ```

   Then right away, `dokku letsencrypt:enable pbm`. Until it finishes,
   browsers get a certificate error they can't click past (the site requires
   HTTPS). It usually takes under a minute; if it fails, wait a minute and
   rerun it.
3. `dokku cron:set pbm maintenance false` on the new droplet. On the old
   one, run `dokku cron:set pbm maintenance true` (or, if that errors on its
   older Dokku, `crontab -r -u dokku`) and
   `rm /etc/cron.d/pbm-db-backup`.
4. Point your `dokku` git remote at the new droplet.

### Rollback

Move the Reserved IP back, and swap the cron steps above. Keep the old
droplet powered off for a couple of weeks before destroying it.

## Keeping this current

Anything changed on the droplet by hand is lost the next time it's rebuilt,
unless it's also added here. After changing server settings, update
`settings.sh` or the script, and rerun the inventory to check the result.
