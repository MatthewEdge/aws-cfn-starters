#!/bin/sh
# Deployment script to automate the EKS provisioning using the awscli

# set -eo pipefail

printUsage() {
	echo "$0"
	echo " "
	echo "options:"
	echo "-h, --help        Show brief help"
	echo "--app             App Name"
    echo "--cluster-name    Name for the Cluster. Default: Combine --app and --env input"
    echo "--env             Environment being deployed to (value from CloudFormation template)"
    echo "--keypair         Name of the KeyPair to use for SSH access"
	echo "--region          AWS Region resources will reside in. Default: us-east-1"
}

# Parse flags
while test $# -gt 0; do
	case "$1" in
	-h | --help)
		printUsage
		exit 0
		;;
	--app)
		shift
		export APP_NAME=$(echo $1)
		shift
		;;
	--cluster-name)
		shift
		export CLUSTER_NAME=$(echo $1)
		shift
		;;
    --env)
		shift
		export CFN_ENV=$(echo $1)
		shift
		;;
    --keypair)
		shift
		export KEYPAIR_NAME=$(echo $1)
		shift
		;;
	--region)
		shift
		export AWS_REGION=$(echo $1)
		shift
		;;
	--repo-name)
		shift
		export REPO_NAME=$(echo $1)
		shift
		;;
	*)
		echo "Invalid option $1"
		printUsage
		exit 1
		;;
	esac
done

# Validate required params
# errIfMissing "$VAR", "ERROR_MESSAGE"
errIfMissing() {
	if [ -z "$1" ]; then
		echo "$2"
		exit 1
	fi
}

errIfMissing "${APP_NAME}" "App Name (--app) is null/empty"
errIfMissing "${CFN_ENV}" "Environment (--env) is null/empty"
errIfMissing "${KEYPAIR_NAME}" "Keypair Name (--keypair) is null/empty"
# errIfMissing "${REPO_NAME}" "ECR Repo name (--repo-name) is null/empty"

AWS_ACCOUNT_ID=$(aws sts get-caller-identity --output text --query 'Account')

# Default Region if not set
if [ -z "${AWS_REGION}" ]; then
    AWS_REGION="us-east-1"
fi

# Upload sub-templates to S3
BUCKET_NAME="${APP_NAME}-eks-${CFN_ENV}"
aws s3 mb s3://${BUCKET_NAME}
aws s3 sync ./sub s3://${BUCKET_NAME}

# Default Cluster Name if not set
if [ -z "${CLUSTER_NAME}" ]; then
    CLUSTER_NAME="${APP_NAME}-${CFN_ENV}"
fi

STACK_NAME="${APP_NAME}-EKS-${CFN_ENV}"
aws cloudformation deploy \
    --stack-name "${STACK_NAME}" \
    --template-file ./master.yml \
    --parameter-overrides AppName="${APP_NAME}" EnvName="${CFN_ENV}" S3BucketName="${BUCKET_NAME}" ClusterName="${CLUSTER_NAME}" KeyName="${KEYPAIR_NAME}" \
    --no-fail-on-empty-changeset \
    --capabilities CAPABILITY_NAMED_IAM

# Update Kube Config for new cluster
aws eks --region us-east-1 update-kubeconfig --name "${CLUSTER_NAME}"

# Allows nodes to join to the Cluster...apparently
NODE_ROLE_ARN=$(aws cloudformation describe-stacks --stack-name "${STACK_NAME}" | jq -r '.Stacks[0] | .Outputs[] | select(.OutputKey == "NodeInstanceRole") | .OutputValue')

# Source: curl -O https://amazon-eks.s3-us-west-2.amazonaws.com/cloudformation/2019-01-09/aws-auth-cm.yaml
read -r -d '' CONFIG_MAP <<EOCONFIG
---
apiVersion: v1
kind: ConfigMap
metadata:
  name: aws-auth
  namespace: kube-system
data:
  mapRoles: |
    - rolearn: ${NODE_ROLE_ARN}
      username: system:node:{{EC2PrivateDNSName}}
      groups:
        - system:bootstrappers
        - system:nodes
EOCONFIG

echo "Running config map..."
echo "${CONFIG_MAP}" > ./cluster-config-map.yml
kubectl apply -f cluster-config-map.yml

rm -f ./cluster-config-map.yml
