import json
from pymongo import MongoClient

# read json file
with open('data_baseline.json', 'r') as filein:
  matlab_data = json.load(filein)

# transform data for db
y_predict = []
for yval in matlab_data['y_predict']:
  y_predict.append(round(yval[0]/1000, 2))
times = range(0, 5*len(matlab_data['time']), 5)
db_data = {'y_predict': y_predict, 'time': times}
db_data['_id'] = 1

# write to db
db_name = 'energydata'
coll_name = 'baseline_data'
client = MongoClient('localhost:27017')
db = client[db_name]
coll = db[coll_name]
result = coll.insert_one(db_data)
print result
