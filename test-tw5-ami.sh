#!/usr/bin/env bash
# shellcheck disable=SC2119,SC2120
#
# MIT License
# Copyright (c) 2022-2022 Nicola Worthington <nicolaw@tfb.net>
#
# https://gitlab.com/nicolaw/tiddlywiki
# https://nicolaw.uk
# https://nicolaw.uk/#TiddlyWiki
#

set -Eeuo pipefail

# shellcheck disable=SC2154
trap 'declare rc=$?;
      >&2 echo "Unexpected error (exit-code $rc) executing $BASH_COMMAND at ${BASH_SOURCE[0]} line $LINENO";
      exit $rc' ERR

sg () {
  aws ec2 describe-security-groups \
    --group-names "${1:-default}" \
    --output text --query "SecurityGroups[-1].GroupId"
}

ami () {
  aws ec2 describe-images \
    --owners 172306058616 \
    --filters 'Name=name,Values=tiddlywiki-*' "Name=architecture,Values=${1:-arm64}" \
    --output text --query 'sort_by(Images, &CreationDate)[-1].ImageId'
}

instance () {
  aws ec2 run-instances \
    --output text \
    --query "Instances[-1].InstanceId" \
    --image-id "$(ami)" \
    --instance-type "t4g.nano" \
    --associate-public-ip-address \
    --tag-specifications "ResourceType=instance,Tags=[{Key=Name,Value=tiddlywiki-test},{Key=Foo,Value=Bar}]" \
    --security-group-ids "$(sg default)" \
    ${1:+--key-name "$1"} \
    ${2:+--iam-instance-profile "Name=$2"}
}

main () {
  if [[ $# -gt 2 ]]; then
    >&2 echo "Syntax: ${0##*/} [key-name] [iam-instance-profile-name]"
    exit 64
  fi

  >&2 echo "Creating EC2 instance ..."
  declare instance=""
  instance="$(instance "$@")"

  >&2 echo "Waiting for EC2 instance $instance ..."
  aws ec2 wait instance-status-ok \
    --instance-ids "$instance" \
    --output text \
    --query "Reservations[].Instances[].PublicIpAddress"

  # https://docs.aws.amazon.com/systems-manager/latest/userguide/setup-instance-profile.html
  echo aws ssm start-session --target "$instance"
}

main "$@"
