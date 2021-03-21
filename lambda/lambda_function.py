import datetime
import json

import boto3

DAYS_TO_KEEP = 1


def lambda_handler(event, context):
    my_session = boto3.session.Session()
    region_name = my_session.region_name
    client = my_session.client(
        service_name='secretsmanager',
        region_name=region_name
    )
    secrets = client.list_secrets()
    results = []
    now = datetime.datetime.date(datetime.datetime.now())
    print("Date now: %s" % now)
    for secret in secrets['SecretList']:
        created = datetime.datetime.date(secret['CreatedDate'])
        print("Created date: %s" % created)
        diff = now - created
        if diff.days > DAYS_TO_KEEP:
            info = [
                secret['ARN'],
                secret['Name']
            ]
            results.append(info)
            print("The insertion date is older than %s days" % DAYS_TO_KEEP)
            print(info)
    return json.dumps(results)
