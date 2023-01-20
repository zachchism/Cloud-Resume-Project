import logging

import azure.functions as func

from azure.cosmos import CosmosClient, PartitionKey

import json

def upsert_item(container, doc_id):
    print('\n1.6 Upserting an item\n')

    read_item = container.read_item(item=doc_id, partition_key=doc_id)
    read_item['amount'] = read_item['amount'] + 1
    response = container.upsert_item(body=read_item)
    print(response).__class__
    print('Upserted Item\'s Id is {0}, new subtotal={1}'.format(response['id'], response['amount']))
    return json.dumps(response)

def main(req: func.HttpRequest) -> func.HttpResponse:
    logging.info('Python HTTP trigger function processed a request.')

    endpoint = 'https://zachchismprod-cosmos-db.documents.azure.com:443/'
    key = ''
    client = CosmosClient(url=endpoint, credential=key)
    db = client.create_database_if_not_exists(id='visitors_db')
    # setup container for this sample
    container = db.create_container_if_not_exists(id='Amount', partition_key=PartitionKey(path='/id', kind='Hash'))
    response = upsert_item(container, 'VisitorCount')

    return func.HttpResponse(
         #"This HTTP triggered function executed successfully. Pass a name in the query string or in the request body for a personalized response.",
         json.dumps(response),
         mimetype="application/json",
         status_code=200
        )