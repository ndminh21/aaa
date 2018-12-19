import json
from pprint import pprint

with open('data/182_instances.json') as f:
    for line in f:
        pprint(json.loads(line))
        break