#-------------------------------------------
# Elasticsearch Imports
#-------------------------------------------
from elasticsearch import AsyncElasticsearch
from elasticsearch.helpers import async_bulk
#-------------------------------------------
# Alpaca Imports
#-------------------------------------------
from alpaca_trade_api.stream import Stream
from alpaca_trade_api.common import URL
#-------------------------------------------
# General Imports
#-------------------------------------------
from functools import partial
import pandas as pd
import asyncio
import json

#-------------------------------------------
# Elastic Global Variables
#-------------------------------------------
CLOUD_USERNAME = "elastic"
CLOUD_PASSWORD = ""
CLOUD_ID = ""
#-------------------------------------------
# ALPACA Global Variables
#-------------------------------------------
API_KEY = ""
API_SECRET = ""
ALPACA_ENDPOINT = "https://data.sandbox.alpaca.markets"

#-------------------------------------------
# Define Index Mappings
#-------------------------------------------
TRADE_MAPPING = '{"properties":{"conditions":{"type":"text","fields":{"keyword":{"type":"keyword","ignore_above":256}}},"exchange":{"type":"text","fields":{"keyword":{"type":"keyword","ignore_above":256}}},"id":{"type":"long"},"price":{"type":"float"},"size":{"type":"long"},"symbol":{"type":"text","fields":{"keyword":{"type":"keyword","ignore_above":256}}},"tape":{"type":"text","fields":{"keyword":{"type":"keyword","ignore_above":256}}},"timestamp":{"type":"date"}}}'
QUOTE_MAPPING = '{"properties":{"ask_exchange":{"type":"text","fields":{"keyword":{"type":"keyword","ignore_above":256}}},"ask_price":{"type":"float"},"ask_size":{"type":"long"},"bid_exchange":{"type":"text","fields":{"keyword":{"type":"keyword","ignore_above":256}}},"bid_price":{"type":"float"},"bid_size":{"type":"long"},"conditions":{"type":"text","fields":{"keyword":{"type":"keyword","ignore_above":256}}},"symbol":{"type":"text","fields":{"keyword":{"type":"keyword","ignore_above":256}}},"tape":{"type":"text","fields":{"keyword":{"type":"keyword","ignore_above":256}}},"timestamp":{"type":"date"}}}'

#-------------------------------------------
# Parse Alpaca Data
#-------------------------------------------
def parse_data(data):
  line = ''.join(str(data).split())
  line = line[6:]
  line = line[:-1]
  line = line.replace("'",'"')
  clean_data = json.loads(line)
  clean_data['timestamp'] = pd.Timestamp(clean_data['timestamp'])
  print('.', end='', flush=True)
  return clean_data

#-------------------------------------------
# Async Elastic Functions
#-------------------------------------------
async def create_index(es, index_name, mapping):
  if not await es.indices.exists(index=index_name):
    await es.indices.create(index=index_name,mappings=json.loads(mapping))

async def ingest_data_callback(t, es, index_name):
  parsed_data = parse_data(t)
  await es.index(index=index_name, document=parsed_data)

#-------------------------------------------
# Main Function
#-------------------------------------------
async def main():
  # Connect to Elasticsearch
  es = AsyncElasticsearch(
    cloud_id=CLOUD_ID,
    basic_auth=(CLOUD_USERNAME, CLOUD_PASSWORD)
    )
  # Create Elasticsearch indices if they don't already exist
  await create_index(es, "trade-index", TRADE_MAPPING)
  await create_index(es, "quote-index", QUOTE_MAPPING)

  # Connect to Alpaca
  stream = Stream(API_KEY,
                  API_SECRET,
                  base_url=URL(ALPACA_ENDPOINT),
                  data_feed='iex')  # <- replace with 'sip' if you have Alpaca PRO subscription
  # Create partial functions in order to pass arguments into our callback functions
  # See this article for more info: https://www.geeksforgeeks.org/partial-functions-python/
  partial_ingest_trade_data_callback = partial(ingest_data_callback, es=es, index_name="trade-index")
  partial_ingest_quote_data_callback = partial(ingest_data_callback, es=es, index_name="quote-index")
  # Subscribe to Alpaca websocket streams using market symbols
  #-- (Every time we receive a document from Alpaca, our
  #    callback functions will parse and ingest to Elasticsearch)
  stream.subscribe_trades(partial_ingest_trade_data_callback, "ESTC")
  stream.subscribe_quotes(partial_ingest_quote_data_callback, "ESTC")

  # Start the data stream from Alpaca
  await stream._run_forever()

#-------------------------------------------
# Run Main Function
#-------------------------------------------
try:
  asyncio.run(main())
except KeyboardInterrupt:
  print('keyboard interrupt, bye')
  pass
