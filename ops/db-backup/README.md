# Nightly DB backup to S3

Production Postgres is a DigitalOcean Managed Database. DO keeps daily
backups with 7 days of point-in-time recovery; this adds an off-DO copy with
longer retention. The job runs from cron on the app (Dokku) droplet itself,
not inside the app container, which is rebuilt on every deploy.

Not in git, so redo these after a server or account loss: `/etc/pbm-db-backup.env`
on the droplet, the S3 bucket, and the `pbm-db-backup` IAM user.

## One-time AWS setup (from your machine)

Create the bucket and expire dumps after 90 days. `YOUR-BACKUP-BUCKET` is a
placeholder throughout; the real name is in `S3_BUCKET` in
`/etc/pbm-db-backup.env` on the droplet and isn't kept in this public repo.
Bucket names are global across AWS, so `create-bucket` fails with
`BucketAlreadyExists` if the name is taken. Use the same name in `S3_BUCKET`
and the IAM policy.

```bash
aws s3api create-bucket --bucket YOUR-BACKUP-BUCKET --region us-west-1 \
  --create-bucket-configuration LocationConstraint=us-west-1
aws s3api put-public-access-block --bucket YOUR-BACKUP-BUCKET \
  --public-access-block-configuration BlockPublicAcls=true,IgnorePublicAcls=true,BlockPublicPolicy=true,RestrictPublicBuckets=true
aws s3api put-bucket-lifecycle-configuration --bucket YOUR-BACKUP-BUCKET \
  --lifecycle-configuration '{"Rules":[{"ID":"expire-dumps","Status":"Enabled","Filter":{"Prefix":"pbm-"},"Expiration":{"Days":90},"AbortIncompleteMultipartUpload":{"DaysAfterInitiation":2}}]}'
```

Create an IAM user with an inline policy that only allows uploads. It can
write new dumps but can't list, read or delete them, so a compromised droplet
can't wipe the backups.

```bash
aws iam create-user --user-name pbm-db-backup
aws iam put-user-policy --user-name pbm-db-backup --policy-name pbm-db-backup-write \
  --policy-document '{"Version":"2012-10-17","Statement":[{"Effect":"Allow","Action":["s3:PutObject","s3:AbortMultipartUpload"],"Resource":"arn:aws:s3:::YOUR-BACKUP-BUCKET/*"}]}'
aws iam create-access-key --user-name pbm-db-backup   # secret is shown only once
```

Check the policy is actually on the user before going further (creating the
user without this step is what caused the first test run to fail):

```bash
aws iam list-user-policies --user-name pbm-db-backup    # must list pbm-db-backup-write
aws iam get-user-policy --user-name pbm-db-backup --policy-name pbm-db-backup-write
```

`list-attached-user-policies` only shows managed policies, so it stays `[]`
for this inline one. The `Resource` must end in `/*`.

### Verify the bucket is private

```bash
aws s3api get-public-access-block --bucket YOUR-BACKUP-BUCKET     # all four true
aws s3api get-bucket-policy --bucket YOUR-BACKUP-BUCKET           # NoSuchBucketPolicy error is good
aws s3api get-bucket-ownership-controls --bucket YOUR-BACKUP-BUCKET  # BucketOwnerEnforced (ACLs off)
# Unauthenticated requests must both return 403 AccessDenied:
curl -sI https://YOUR-BACKUP-BUCKET.s3.us-west-1.amazonaws.com/<some-dump-key> | head -1
curl -s  https://YOUR-BACKUP-BUCKET.s3.us-west-1.amazonaws.com/ | head -c 300
```

## Droplet setup

`ops/server-setup/pbm-server-setup` installs all of this on a new droplet;
then fill in `/etc/pbm-db-backup.env` and do the test run below. The manual
steps are for a droplet that wasn't built with that script.

Copy the files over from your machine first:

```bash
scp ops/db-backup/{pbm-db-backup,pbm-db-backup.cron,pbm-db-backup.env.example} root@your-droplet:/tmp/
```

Then on the droplet, from `/tmp`:

```bash
# AWS CLI v2
sudo snap install aws-cli --classic

# Postgres client matching the cluster's major version (check the DO panel)
sudo apt install -y postgresql-common
sudo /usr/share/postgresql-common/pgdg/apt.postgresql.org.sh
sudo apt install -y postgresql-client-17
/usr/lib/postgresql/17/bin/pg_dump --version   # should say 17.x

# Script, config, cron
sudo install -m 755 pbm-db-backup /usr/local/bin/pbm-db-backup
sudo install -m 600 pbm-db-backup.env.example /etc/pbm-db-backup.env
sudo nano /etc/pbm-db-backup.env   # fill in values, including DOKKU_APP=pbm
sudo install -m 644 pbm-db-backup.cron /etc/cron.d/pbm-db-backup
rm pbm-db-backup pbm-db-backup.cron pbm-db-backup.env.example

# Test run
sudo /usr/local/bin/pbm-db-backup
```

The droplet must be in the database's Trusted sources in the DO panel
(see `ops/server-setup/README.md` step 2), or the dump times out connecting.

A successful run ends with `backup complete: ...` and, if `DOKKU_APP` is set,
`env backup complete: ...`. If the dump succeeds but the upload fails with
`AccessDenied ... CreateMultipartUpload ... no identity-based policy allows the
s3:PutObject action`, the IAM policy is missing or names the wrong bucket; see
the checks above. A policy change can take a minute to apply.

Deploying the app doesn't update the droplet's copies. After changing the
script here, copy it over again and rerun the `install -m 755` line (or rerun
`pbm-server-setup`, which reinstalls it along with the cron file).

## Checking on it

```bash
journalctl -t pbm-db-backup --since "2 days ago"
aws s3 ls s3://YOUR-BACKUP-BUCKET/   # from your machine; the droplet key can't list
```

## Restoring

Download a dump with your own AWS credentials, then restore into a scratch
database. Don't restore over `pbm_development`; it holds test data that isn't
in prod.

```bash
aws s3 cp s3://YOUR-BACKUP-BUCKET/pbm-2026-10-22T0915Z.dump .
createdb pbm_restore_test
pg_restore --no-owner --no-acl -d pbm_restore_test pbm-2026-10-22T0915Z.dump
psql pbm_restore_test -c 'select count(*) from locations'
dropdb pbm_restore_test
rm pbm-2026-10-22T0915Z.dump
```

Your local `pg_restore` must be 17 or newer. Dumps include user emails,
password hashes and plaintext API tokens (`users.authentication_token`), so
don't leave copies in Downloads or synced folders.

Test a restore every so often so you know the backups actually work.

### Dokku env config

If `DOKKU_APP` is set, each run also uploads `pbm-env-<stamp>.txt`, holding
`dokku config:export --format shell` for the app and the global config. It
contains every app secret, so delete local copies once you're done. To restore
the app config, copy the app's line (without the leading `#` comment) to the
droplet as `app-env.txt`, then:

```bash
eval "dokku config:set --no-restart pbm $(cat app-env.txt)"
```

`eval` is needed so the shell strips the quotes around each value.
