#!/usr/bin/env bash
set -euo pipefail

read -rp "Hetzner project ID: " project_id
read -rp "Access key to allow: " access_key
read -rp "Bucket name: " bucket_name

# Hetzner access keys are uppercase alphanumeric, typically 20 chars
# Secret keys are longer (40 chars) and contain mixed case / special chars
if [[ ${#access_key} -gt 30 ]]; then
  echo "ERROR: That looks like a secret key (too long). Access keys are ~20 characters." >&2
  exit 1
fi

if [[ "$access_key" =~ [a-z] ]]; then
  echo "ERROR: That looks like a secret key (contains lowercase). Access keys are uppercase alphanumeric." >&2
  exit 1
fi

cat > policy.json <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "DenyAllUsersButOne",
      "Effect": "Deny",
      "Action": "s3:*",
      "Resource": [
        "arn:aws:s3:::${bucket_name}",
        "arn:aws:s3:::${bucket_name}/*"
      ],
      "NotPrincipal": {
        "AWS": "arn:aws:iam:::user/p${project_id}:${access_key}"
      }
    }
  ]
}
EOF

echo "Written to policy.json"
echo ""
echo "Apply with:"
echo "  mc anonymous set-json policy.json <alias>/${bucket_name}"
