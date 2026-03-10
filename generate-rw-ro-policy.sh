#!/usr/bin/env bash
set -euo pipefail

read -rp "Hetzner project ID: " project_id
read -rp "Read-write access key (e.g. backup/restic key): " rw_key
read -rp "Read-only access key (e.g. NAS sync key): " ro_key
read -rp "Bucket name: " bucket_name

# Hetzner access keys are uppercase alphanumeric, typically 20 chars
# Secret keys are longer (40 chars) and contain mixed case / special chars
for key in "$rw_key" "$ro_key"; do
  if [[ ${#key} -gt 30 ]]; then
    echo "ERROR: '$key' looks like a secret key (too long). Access keys are ~20 characters." >&2
    exit 1
  fi
  if [[ "$key" =~ [a-z] ]]; then
    echo "ERROR: '$key' looks like a secret key (contains lowercase). Access keys are uppercase alphanumeric." >&2
    exit 1
  fi
done

cat > policy.json <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "DenyAllExceptAllowed",
      "Effect": "Deny",
      "Action": "s3:*",
      "Resource": [
        "arn:aws:s3:::${bucket_name}",
        "arn:aws:s3:::${bucket_name}/*"
      ],
      "NotPrincipal": {
        "AWS": [
          "arn:aws:iam:::user/p${project_id}:${rw_key}",
          "arn:aws:iam:::user/p${project_id}:${ro_key}"
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
        "arn:aws:s3:::${bucket_name}",
        "arn:aws:s3:::${bucket_name}/*"
      ],
      "Principal": {
        "AWS": "arn:aws:iam:::user/p${project_id}:${ro_key}"
      }
    }
  ]
}
EOF

echo "Written to policy.json"
echo ""
echo "Apply with:"
echo "  mc anonymous set-json policy.json <alias>/${bucket_name}"
echo ""
echo "Repeat for each bucket you want to sync to the NAS."
