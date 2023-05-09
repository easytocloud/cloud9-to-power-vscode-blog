#!/usr/bin/env bash

# Derived from original by Amazon.com
# Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
# SPDX-License-Identifier: MIT-0

# Changes by Erik Meinders / easytocloud to integrate with profile organizer

# Arguments passed from SSH client

HOST=$1
PORT=$2
PUBLIC_KEY_PATH="${3:-cloud9.pub}"
export AWS_PROFILE="${4:-cloud9}"
AWS_ENV="${5:-standard}"
export AWS_REGION="${6:-eu-west-1}"

# assume we can find the cloud9-mod.json in the same directory as 'self'

C9MODSFILE="${BASH_SOURCE[0]%/*}"/cloud9-mod.json

# Parameters to control patience when instance has to be resumed before connection is possible
# give it a minute ...

MAX_ITERATION=20
SLEEP_DURATION=3

getHostStatus()
{
    aws ssm describe-instance-information \
    --filters Key=InstanceIds,Values=${HOST} \
    --query 'InstanceInformationList[0].PingStatus' \
    --output text || echo 'Failed' 2>/dev/null
}

# using easytocloud profile-organizer?

if [ "${AWS_ENV}" != 'standard' ]
then
  export AWS_CONFIG_FILE=~/.aws/aws-envs/${AWS_ENV}/config
  export AWS_SHARED_CREDENTIALS_FILE=~/.aws/aws-envs/${AWS_ENV}/credentials
fi

# If the instance is not Online, start the instance first and wait for it to be alive

if [ $( getHostStatus ) != 'Online' ]; then

    # Instance is offline - start the instance first

    aws ec2 start-instances --instance-ids ${HOST}

    COUNT=0

    while 
        sleep ${SLEEP_DURATION} 
        [ $( getHostStatus ) != 'Online' ]
    do

        let COUNT=COUNT+1

        # Max attempts reached, exit proxy script

        [ ${COUNT} -eq ${MAX_ITERATION} ] && exit 1
        
    done
fi

# PubIP=$(aws ec2 describe-instances --query 'Reservations[].Instances[?InstanceId==`'${HOST}'`].PublicIpAddress' --output text)

# Instance is online now

# optionally make some mods to the instance

aws ssm send-command \
    --document-name "AWS-RunShellScript" \
    --targets "Key=InstanceIds,Values=${HOST}" \
    --cli-input-json file://${C9MODSFILE}

# actually setup SSM session ..
# .. by first pushing a public key to the instance
aws ec2-instance-connect send-ssh-public-key \
    --instance-id "${HOST}" \
    --instance-os-user "ec2-user" \
    --ssh-public-key file://${PUBLIC_KEY_PATH} 
# .. and then start the session
aws ssm start-session \
    --target $HOST \
    --document-name AWS-StartSSHSession \
    --parameters portNumber=${PORT} 
