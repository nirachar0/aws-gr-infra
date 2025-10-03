import os
import json
import boto3

sns_arn = os.environ.get('SNS_TOPIC_ARN')
client = boto3.client('sns')


def lambda_handler(event, context):
    message = {
        'message': 'CloudTrail event received',
        'event': event
    }
    client.publish(
        TopicArn=sns_arn,
        Message=json.dumps(message),
        Subject='Guardrail Event'
    )

    return {
        'statusCode': 200,
        'body': json.dumps({'result': 'published'})
    }
