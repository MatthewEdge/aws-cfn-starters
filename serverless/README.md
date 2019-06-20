# Encore API

## Serverless Deployments

This service is deployed as a Lambda Function behind API Gateway Rest APIs. See the [Serverless Docs](https://serverless.com) for more information.

Deploys occur through the serverless CLI:

`./node_modules/.bin/serverless deploy --stage ENV --hash GIT_HASH`

This does not need to be done manually as this is run through the CI/CD pipeline. The GIT_HASH flag is purely for documentation purposes on
what is deployed. It is stored as an environment variable on the Lambda function.

## Debugging

There are two CloudWatch sources for logging - API Gateway logs and Lambda Function Logs:
- For API Gateway Logs you must search for `API-Gateway-Execution-Logs_{rest-api-id}` in Cloudwatch where `rest-api-id` is the APIG ID
- For Lambda Function direct logs search for `/aws/lambda/api`

## Local Runs

A local copy can be run using the `serverless-offline` plugin:

`./node_modules/.bin/serverless offline start`

This starts up the services on `localhost:3000`.

You can also invoke the Lambda directly with `./node_modules/.bin/serverless invoke local --function accountBalance --data 'JSON_HERE'`.

The difference is `serverless offline start` emulates the full API Gateway deployment and is called through the REST API. `serverless invoke local`
is for debugging the Lambda function directly which is useful for debugging issues with the integration from API Gateway.
