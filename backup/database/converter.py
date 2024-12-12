import json
import os
import random
import time
from hashlib import md5

with open("cars.hex.ixt", "r") as f:
    cars = json.loads(f.read())
for hex in cars:
    try:
        if not os.path.exists(f"cars\{hex}.ixt"):
            continue
        with open(f"cars\{hex}.ixt", "r") as f:
            print(hex)
            data = json.load(f)
            lisc = data.get('licenss_plate', None)
        with open(f"cars\{hex}.ixt", "w") as f:
            data.pop('licenss_plate', None)
            json.dump(f,data, indent=4)
        with open(f"cars\{hex}.metadata", "r") as f:
            metadata = json.load(f)
            metadata['licenseText'] = lisc
        with open(f"cars\{hex}.metadata", "w") as f:
            json.dump(metadata, f, indent=4)
        cars[hex].pop('licenseText')
        with open(f"cars\{hex}.ixt", "w") as f:
            json.dump(f,data, indent=4)
    except Exception as e:
        print(e)

with open("cars.hex.ixt", "w") as f:
    json.dump(f,cars, indent=4)

