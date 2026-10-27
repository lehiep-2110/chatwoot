# Building the EasyHire custom image

For the shared Community image, use the release workflow and pinned reference in
[EASYHIRE_IMAGE.md](EASYHIRE_IMAGE.md). The team setup in EasyHire uses that image
for both the web server and Sidekiq worker.

The command below is for local development with the checked-out source. It
includes the Enterprise overlay when present and is subject to its license.
The release workflow prepares a separate Community context before building,
verifying and publishing the image.

```sh
docker build -f docker/Dockerfile \
  --build-arg GIT_SHA="$(git rev-parse HEAD)" \
  -t easyhire-chatwoot:custom .
```

`GIT_SHA` is required. For a source archive, pass its recorded source revision.
For uncommitted changes, record a source manifest and include its snapshot ID in
the revision/tag so the image cannot be confused with the unchanged base commit.
The image stores the value in `/app/.git_sha` and its OCI revision label.
Executable entrypoints and Ruby helpers are normalized to Linux LF line endings
during the build, including when the source was checked out on Windows.
Native gRPC compilation uses two processes by default to limit build memory.
Use `--build-arg GRPC_RUBY_BUILD_PROCS=<count>` to adjust it for the build host.

The build context excludes Git metadata, `.codex/`, local agent configuration,
environment files, installed dependencies and temporary working files. Do not
copy `.env`, credentials, databases or persistent storage into a release context.

The default Dockerfile installs the production dependencies from the lockfile,
compiles assets, and creates a fresh runtime stage. Enterprise/license behavior
is unchanged. Building this source does not grant an Enterprise license.

Start the web server using `docker/entrypoints/rails.sh`. Start the worker with
`bundle exec sidekiq -C config/sidekiq.yml` so messaging, notification, storage and
cleanup queues all use the repository's queue configuration.

`GET /api` checks PostgreSQL with a read-only `SELECT 1`, including on a cold
connection. It retains the existing `data_services` and `queue_services` fields.

Before rollout, validate the image with isolated PostgreSQL, Redis and storage,
including SSO, Inbox permission revocation, two-way messaging and background jobs.
Build completion alone does not confirm that validation or apply any migration.
