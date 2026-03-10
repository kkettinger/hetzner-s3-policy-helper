# Hetzner Object Storage - Restrict S3 Credentials per Bucket

By default, all S3 credentials in a Hetzner project have full access to all buckets. These scripts generate bucket policies to restrict access to specific keys.

See [Hetzner docs](https://docs.hetzner.com/storage/object-storage/faq/s3-credentials#how-do-i-restrict-access-per-key) for background.

## Table of contents

- [Scripts](#scripts)
- [Usage](#usage)
- [Finding your project ID](#finding-your-project-id)
- [Examples](#examples)
- [Notes](#notes)

## Scripts

### `generate-single-key-policy.sh`

Restricts a bucket to a **single key** with full read-write access. All other keys in the project are denied access.

Use case: a backup bucket that only your restic/backup key should access.

### `generate-rw-ro-policy.sh`

Restricts a bucket to **two keys** - one with full read-write access, one with read-only access. All other keys are denied.

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

## Examples

### Single key policy

```
$ ./generate-single-key-policy.sh
Hetzner project ID: 1234567
Access key to allow: EXAMPLEKEY1234567890
Bucket name: my-backups
Written to policy.json
```

Generated `policy.json`:

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "DenyAllUsersButOne",
      "Effect": "Deny",
      "Action": "s3:*",
      "Resource": [
        "arn:aws:s3:::my-backups",
        "arn:aws:s3:::my-backups/*"
      ],
      "NotPrincipal": {
        "AWS": "arn:aws:iam:::user/p1234567:EXAMPLEKEY1234567890"
      }
    }
  ]
}
```

### Read-write + read-only policy

```
$ ./generate-rw-ro-policy.sh
Hetzner project ID: 1234567
Read-write access key (e.g. backup/restic key): EXAMPLEKEY1234567890
Read-only access key (e.g. NAS sync key): EXAMPLEKEYRO12345678
Bucket name: my-backups
Written to policy.json
```

Generated `policy.json`:

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "DenyAllExceptAllowed",
      "Effect": "Deny",
      "Action": "s3:*",
      "Resource": [
        "arn:aws:s3:::my-backups",
        "arn:aws:s3:::my-backups/*"
      ],
      "NotPrincipal": {
        "AWS": [
          "arn:aws:iam:::user/p1234567:EXAMPLEKEY1234567890",
          "arn:aws:iam:::user/p1234567:EXAMPLEKEYRO12345678"
        ]
      }
    },
    {
      "Sid": "DenyWriteForReadOnly",
      "Effect": "Deny",
      "NotAction": [
        "s3:GetObject",
        "s3:GetObjectVersion",
        "s3:ListBucket",
        "s3:GetBucketLocation"
      ],
      "Resource": [
        "arn:aws:s3:::my-backups",
        "arn:aws:s3:::my-backups/*"
      ],
      "Principal": {
        "AWS": "arn:aws:iam:::user/p1234567:EXAMPLEKEYRO12345678"
      }
    }
  ]
}
```

## Notes

- Hetzner grants access implicitly at the platform level, so the policies only use `Deny` statements - no `Allow` needed.
- After applying a policy, Hetzner Console can no longer browse the bucket contents (expected).
- The scripts validate that you're entering an access key, not a secret key, to prevent accidental lockout.
