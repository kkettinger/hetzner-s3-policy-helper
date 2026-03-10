# Hetzner Object Storage - Restrict S3 Credentials per Bucket

By default, all S3 credentials in a Hetzner project have full access to all buckets. These scripts generate bucket policies to restrict access to specific keys.

See [Hetzner docs](https://docs.hetzner.com/storage/object-storage/faq/s3-credentials#how-do-i-restrict-access-per-key) for background.

## Scripts

### `generate-single-key-policy.sh`

Restricts a bucket to a **single key**. All other keys in the project are denied access.

Use case: a backup bucket that only your restic/backup key should access.

### `generate-rw-ro-policy.sh`

Restricts a bucket to **two keys** — one with full read-write access, one with read-only access. All other keys are denied.

Use case: a backup key writes to the bucket, a second key syncs it read-only to a NAS.

## Usage

```bash
./generate-single-key-policy.sh
# or
./generate-rw-ro-policy.sh
```

The script prompts for your project ID, access key(s), and bucket name, then writes `policy.json`.

Apply the policy using the [MinIO Client](https://min.io/docs/minio/linux/reference/minio-mc.html):

```bash
mc anonymous set-json policy.json <alias>/<bucket_name>
```

## Finding your project ID

The project ID is in the Hetzner Console URL:

```
https://console.hetzner.com/projects/<project_id>/servers
```

## Notes

- Hetzner grants access implicitly at the platform level, so the policies only use `Deny` statements - no `Allow` needed.
- After applying a policy, Hetzner Console can no longer browse the bucket contents (expected).
- The scripts validate that you're entering an access key, not a secret key, to prevent accidental lockout.
