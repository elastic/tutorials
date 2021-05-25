from elastic_enterprise_search import AppSearch
import glob, os
import json

app_search = AppSearch(
    "app_search_api_endpoint",
    http_auth="api_private_key"
)

response = []

print("Uploading movies to App Search...")

os.chdir("movies_directory")
for file in glob.glob("*.json"):
  with open(file, 'r') as json_file:
    try:
      response = app_search.index_documents(engine_name="movies",documents=json.load(json_file))
      print(".", end='', flush=True)
    except:
      print("Fail!")
      print(response)
      break
