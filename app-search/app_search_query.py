import requests

api_endpoint = 'my_api_endpoint' + '/api/as/v1/engines/movies/search'
api_key = 'my_api_key'

headers = {'Content-Type': 'application/json',
           'Authorization': 'Bearer {0}'.format(api_key)}
query = {'query': 'family'}

response = requests.post(api_endpoint, headers=headers, json=query)
print(response.text)