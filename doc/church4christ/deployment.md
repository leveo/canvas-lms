# Church4Christ Learning — Canvas Edition operations

This derivative uses Canvas's supported Theme Editor `BrandConfig` and
account-level Help Links settings. It does not patch Canvas templates or
navigation. The configuration task adds a featured, all-user Help-menu entry
for the Corresponding Source offer required by GNU AGPL v3 §13.

## Required configuration

Set these non-secret deployment values in the process environment or your
orchestrator's ordinary configuration store. Do not put credentials in them.

| Name | Required | Meaning |
| --- | --- | --- |
| `C4C_CORRESPONDING_SOURCE_URL` | yes | Public `https://` URL from which every remote user can copy the exact Corresponding Source for the deployed build at no charge. Loopback, private, link-local, local-name, credentialed, fragment, and ambiguous numeric IPv4 URLs are rejected. |
| `C4C_ROOT_ACCOUNT_ID` | no | Root Canvas account to configure; uses `Account.default` when unset. |
| `C4C_THEME_PRIMARY` | no | Six-digit hex primary color; default `#1d5c3a`. |
| `C4C_THEME_NAV_BACKGROUND` | no | Six-digit hex global-navigation color; default `#143d29`. |

For every production release, publish the complete Corresponding Source first,
including this derivative's changes and any build/deployment scripts needed to
produce the running version. The configured URL must identify that exact source
release, not merely an upstream Canvas repository.

## Production deployment

1. Build an immutable Canvas image from the reviewed commit. Canvas's
   `Dockerfile.production` expects Ruby 3.4, Node 20, and runs asset
   compilation during the image build.
2. Provision PostgreSQL, Redis, durable file/object storage, and a background
   job worker in addition to the web service. Provide Canvas's normal
   `database.yml`, `file_store.yml`, `security.yml`, domain, mail, and dynamic
   settings through protected deployment configuration; do not commit them.
3. Store encryption keys, database credentials, OAuth/LTI secrets, SMTP
   credentials, and object-storage credentials in a secret manager (Canvas can
   use Vault; see `doc/docker/vault.md`) or protected orchestrator secrets.
   Rotate secrets with a tested runbook and never log, commit, or expose them
   in `C4C_*` values.
4. Run Canvas migrations using the deployment's normal, reviewed migration
   procedure. Once the application and its asset store are available, run:

   ```sh
   C4C_CORRESPONDING_SOURCE_URL=https://source.example.org/releases/RELEASE \
     bin/rake church4christ:configure
   ```

   The task persists the supported Theme Editor variables, publishes the
   resulting brand files through Canvas's `BrandConfig#save_and_sync_to_s3!`,
   then queues Canvas's `BrandConfigRegenerator` to attach the theme and
   regenerate branded descendants. It also installs the featured all-user Help
   link. Keep the background-job service running and wait for this regeneration
   progress before treating the theme change as active. Run the task again after
   changing a `C4C_*` value. Verify as an unauthenticated and authenticated user
   that the Help menu shows “Church4Christ Learning — Source Code & License” and
   that its link can download the corresponding source.
5. Keep the source offer available for as long as users can interact with that
   deployed modified version. Preserve `LICENSE`, `COPYRIGHT`, and
   `CHURCH4CHRIST_NOTICE.md` in each source release.

## Development

Follow Canvas's documented Docker bootstrap in
`doc/docker/developing_with_docker.md` (`./script/docker_dev_setup.sh`, then
`docker compose up -d`). Run focused Ruby specs inside the web container:

```sh
docker compose exec web bin/rspec spec/lib/church4christ/configuration_spec.rb
```

For local testing, point `C4C_CORRESPONDING_SOURCE_URL` at a locally reachable
source archive or development source server. Never use a production URL that
does not serve the precise checked-out derivative source.

## Backups and restores

Back up and periodically restore-test all state together: PostgreSQL (including
all Canvas shards), Canvas file/object storage, configured brand files/CDN
objects, and the protected configuration/secret references needed to decrypt
data. Encrypt backups, restrict access, retain them according to the
organization's policy, and record the application commit plus migration level.

Before restoring, stop writes and take a fresh safety backup. Restore the
database and object storage to an isolated environment first, use the matching
Canvas release and compatible secrets, run integrity checks, and confirm users
can access files and the Help-menu source offer. Do not overwrite a production
database until the restore rehearsal is accepted.

## Upstream update and rebase workflow

1. Fetch a reviewed commit from `https://github.com/instructure/canvas-lms`.
2. Create a dedicated integration branch, rebase or merge that upstream commit
   into the Church4Christ branch, and resolve conflicts without removing
   upstream copyright, AGPL, Instructure attribution, or non-endorsement
   notices.
3. Update the pinned upstream commit and dated modification log in
   `CHURCH4CHRIST_NOTICE.md`; record every functional derivative change there.
4. Re-run the focused Church4Christ spec and the proportionate Canvas test,
   lint, asset-build, migration, and restore checks. Publish the corresponding
   source release before deploying the updated image, update
   `C4C_CORRESPONDING_SOURCE_URL` if needed, then rerun
   `church4christ:configure`.
