import socket
import sys
import json
from subprocess import call
from pymongo import MongoClient
import time
from watchdog.observers import Observer
from watchdog.events import FileSystemEvent, FileSystemEventHandler
import matlab.engine

class MyFileHandler(FileSystemEventHandler):
  def __init__(self, target_file_path):
    self.target_file_path = target_file_path
    self.flag_done = False

  def process_done(self):
    return self.flag_done

  def on_created(self, event):
    if event.src_path == self.target_file_path:
      self.flag_done = True

  def on_modified(self, event):
    if event.src_path == self.target_file_path:
      self.flag_done = True



def read_json(target_path):
  with open(target_path, 'r') as json_data:
    response_data = json.load(json_data)
  return response_data 

def write_json(target_path, json_data):
  with open(target_path, 'w') as fout:
    json.dump(json_data, fout)

def db_insert(db_name, collection_name, data_obj):
  client = MongoClient('localhost:27017')
  db = client[db_name]
  coll = db[collection_name]
  id_val = data_obj['_id']
  result = coll.replace_one({'_id': id_val}, data_obj, upsert=True) 
  return result # return ObjectId of item inserted 

def db_update(db_name, collection_name, id_val, data):
  client = MongoClient('localhost:27017')
  db = client[db_name]
  coll = db[collection_name]
  result = coll.UpdateOne({'_id': id_val}, data, upsert=False) 
  return result # return ObjectId of item inserted 

def calc_auc(y_predict, time):
  sum=0
  for y in y_predict:
    sum += (float(y)*5/60)
  return sum

def transform_time_series(y_input,time):
  y_predict = []
  max_kW = 0
  for yval in y_input:
    val = round(yval[0]/1000, 2)
    if val > max_kW:
      max_kW = val
    y_predict.append(val)
  times = range(0, 5*len(time), 5)
  max_kW = round(max_kW / 1000 , 1)
  return y_predict,times,max_kW

def call_baseline(query, dayQuery, matlab_engine=None):
  # wait until output json file is generated by executable matlab
  observer_path = '.'
  target_path = './response.json'   
  observer = Observer()
  handler = MyFileHandler(target_path)
  observer.schedule(handler, observer_path)
  observer.start()

  if matlab_engine is None:
    # use subprocess.call to execute query
    pass
  else:
    if dayQuery:
      # only day available is July 17 for provided data
      matlab_engine.baseline_july17(nargout=0)
    else:
      # only month available is July for provided data
      matlab_engine.baseline_july(nargout=0)

  # wait for query to complete and output file to be created/modified
  while handler.process_done == False:
    time.sleep(1)
  observer.stop()
  observer.join()

  # read query output file
  response = read_json(target_path)
  print 'read data from response file {}: {}'.format(target_path, response)

  # transform response data into name-value pairs
  y_predict = []
  max_kW = 0
  for yval in response['y_predict']:
    val = round(yval[0]/1000, 2)
    if val > max_kW:
      max_kW = val
    y_predict.append(val)
  times = range(0, 5*len(response['time']), 5)
  db_data = {'y_predict': y_predict, 'time': times}
  db_data['_id'] = 1
  if dayQuery:
    db_data['day_flag'] = True
  else:
    db_data['day_flag'] = False

  # calculate metrics
  auc_baseline = calc_auc(y_predict, times)
  max_kW = round(max_kW / 1000 , 1)
  db_data['peak_power'] = max_kW
  db_data['total_energy'] = auc_baseline
  if dayQuery:
    db_data['target_calendar'] = query['day']
  else:
    db_data['target_calendar'] = query['month']

  # update DB with query result to update graphical output 
  db_name = 'energydata'
  coll_name = 'baseline_data'
  inserted_obj_id = db_insert(db_name, coll_name, db_data)
  print 'inserted into:', db_name, coll_name, inserted_obj_id

  ## update DB with baseline chart
  db_name = 'energydata'
  coll_name = 'pagename'
  db_data_page = {}
  db_data_page['_id'] =1
  db_data_page['name'] = 'oneplot'
  inserted_obj_id = db_insert(db_name, coll_name, db_data_page)
  print 'inserted into:', db_name, coll_name, inserted_obj_id


  res = {'peak_kW': max_kW}
  return res

def call_evaluator(query, matlab_engine=None):
  # validate set point values, determine which is being set
  input_data = {'cwsetp': 6.7, 'clgsetp': 26.7, 'lil': 0.7, 'start': 0, 'end': 23}
  setpoint_type = query['setpoint_type'].lower()
  setpoint_val = float(query['setpoint_val'])
  if setpoint_type in ('chilled water', 'chilled water temperature', 'cold water temperature'):
    input_data['cwsetp'] = setpoint_val
  elif setpoint_type in ('lighting level', 'lighting'):
    input_data['lil'] = float(setpoint_val)/100 
  elif setpoint_type in ('room temperature', 'zone temperature'):
    input_data['clgsetp'] = setpoint_val
  else:
    pass
    # TODO: handle error, inform user if invalid setpoint type
  # write input json file needed by matlab function
  input_data['start'] = int(query['start_time'][0:2])
  input_data['end'] = int(query['end_time'][0:2]) 
  input_file = 'input_evaluator.json'
  print "input",input_data
  write_json(input_file, input_data)

  # wait until output json file is generated by executable matlab
  observer_path = '.'
  target_path = './response.json'   
  observer = Observer()
  handler = MyFileHandler(target_path)
  observer.schedule(handler, observer_path)
  observer.start()

  # read db.baseline_data, determine if latest is for a month or day
  client = MongoClient()
  db = client.energydata
  cursor = db.baseline_data.find({'_id': 1})
  baseline_data = cursor[0]
  isDay = baseline_data['day_flag']  
  # calculate max peak for baseline
  # y_predict_baseline,times_baseline,max_kW_baseline = transform_time_series(baseline_data['y_predict'],baseline_data['time'])
  # calculate auc for baseline
  auc_baseline = calc_auc(baseline_data['y_predict'],baseline_data['time'])
  print "auc_baseline",auc_baseline
  if matlab_engine is None:
    # use subprocess.call to execute query 
    pass
  else:
    if isDay:
      matlab_engine.evaluator_ka(nargout=0)
    else:
      matlab_engine.evaluator_july(nargout=0)

  # wait for query to complete and output file to be created/modified
  while handler.process_done == False:
    time.sleep(1)
  observer.stop()
  observer.join()

  # read query output file
  response = read_json(target_path)
  print 'read data from response file {}: {}'.format(target_path, response)

  # transform response data into name-value pairs 
  y_predict_evaluator,times_evaluator,max_kW_evaluator = transform_time_series(response['y_predict'],response['time'])
  # calculate auc for baseline

  print "evalutator after transform", y_predict_evaluator
  auc_evaluator= calc_auc(y_predict_evaluator,times_evaluator)

  print "auc_evaluator",auc_evaluator
  db_data = {'y_predict': y_predict_evaluator, 'time': times_evaluator}
  db_data['_id'] = 1
  if isDay:
    db_data['day_flag'] = True
  else:
    db_data['day_flag'] = False
  
  # update DB with query result to update graphical output 
  db_name = 'energydata'
  coll_name = 'evaluator_data'
  inserted_obj_id = db_insert(db_name, coll_name, db_data)
  print 'inserted into:', db_name, coll_name, inserted_obj_id

  energy_saving = round(((auc_baseline- auc_evaluator)/auc_baseline)*100,1)
  print "energy_saving", energy_saving
  # return content for vocal response
#  max_kW = (max_kW // 100) * 100

  ## update DB with baseline chart
  db_name = 'energydata'
  coll_name = 'pagename'
  db_data_page = {}
  db_data_page['_id'] =1
  db_data_page['name'] = 'twoplots'
  inserted_obj_id = db_insert(db_name, coll_name, db_data_page)
  print "inserted_into:", db_name, coll_name, inserted_obj_id
  res = {'percentage' : energy_saving}
  # res = {'peak_kW': max_kW}
  return res

def call_setp_options(query, matlab_engine=None):

  # read db.baseline_data, determine if latest is for a month or day
  client = MongoClient()
  db = client.energydata
  cursor = db.baseline_data.find({'_id': 1})
  baseline_data = cursor[0]
  isDay = baseline_data['day_flag']  
 
  min_energy = Integer.MAX_VALUE
  id_val = 0
  
  for i in range(1, 3):
      # validate set point values, determine which is being set
      
      input_data = {'cwsetp': 6.7, 'clgsetp': 26.7, 'lil': 0.7, 'start': 0, 'end': 23}
      if i == 2:
          input_data['cwsetp'] = 25
      elif i == 3:
          input_data['lil'] = 0.6

      # TODO: handle error, inform user if invalid setpoint type
      # write input json file needed by matlab function
      # input_data['start'] = int(query['start_time'][0:2])
      # input_data['end'] = int(query['end_time'][0:2]) 
      input_file = 'input_evaluator.json'
      print "input",input_data
      write_json(input_file, input_data)

      # wait until output json file is generated by executable matlab
      observer_path = '.'
      target_path = './response.json'   
      observer = Observer()
      handler = MyFileHandler(target_path)
      observer.schedule(handler, observer_path)
      observer.start()
      if matlab_engine is None:
        # use subprocess.call to execute query 
        pass
      else:
        if isDay:
          matlab_engine.evaluator_ka(nargout=0)
        else:
          matlab_engine.evaluator_july(nargout=0)

      # wait for query to complete and output file to be created/modified
      while handler.process_done == False:
        time.sleep(1)
      observer.stop()
      observer.join()

      # read query output file
      response = read_json(target_path)
      print 'read data from response file {}: {}'.format(target_path, response)

      # transform response data into name-value pairs 
      y_predict_evaluator,times_evaluator,max_kW_evaluator = transform_time_series(response['y_predict'],response['time'])
      # calculate auc for baseline

      print "evalutator after transform", y_predict_evaluator
      auc_evaluator= calc_auc(y_predict_evaluator,times_evaluator)

      print "auc_evaluator",auc_evaluator
      db_data = {'y_predict': y_predict_evaluator, 'time': times_evaluator}
      db_data['_id'] = i
      if isDay:
        db_data['day_flag'] = True
      else:
        db_data['day_flag'] = False
      
      if min_energy > auc_evaluator:
          min_energy = auc_evaluator
          id_val = i

      # update DB with query result to update graphical output 
      db_name = 'energydata'
      coll_name = 'setp_options_data'
      inserted_obj_id = db_insert(db_name, coll_name, db_data)
      print 'inserted into:', db_name, coll_name, inserted_obj_id

  # insert new fields best_id and best_energy which contain the curve number
  # and the corresponding energy respectively

  energy_and_id = {'best_id' : id_val, 'best_energy' : min_energy}
  
  for x in range(1, 3):
      db_update(db_name, coll_name, x, energy_and_id)

  res = {'peak_kW' : min_energy}
  # res = {'peak_kW': max_kW}
  return res

def call_searchbin(query, matlab_engine=None):
  # extract and normalize building name - no spaces, all lowercase
  building = ''.join(query['building'].split(' ')).lower()
  # extract usage in kilowatts
  usagekW = query['usagekW']

  if usagekW < 37:
    binNum = 1
  elif usagekW <= 55:
    binNum = 2
  elif usagekW <= 74:
    binNum = 3
  elif usagekW <= 92:
    binNum = 4
  elif usagekW <= 111:
    binNum = 5
  else:
    # error case, inform user that max usage is 111 kW
    result_error = {'error_msg': 'power greater than one hundred eleven kilowatts is an invalid input'}
    return result_error

  # wait until output json file is generated by executable matlab
  observer_path = '.'
  target_path = './response.json'
  observer = Observer()
  handler = MyFileHandler(target_path)
  observer.schedule(handler, observer_path)
  observer.start()

  if matlab_engine is None:
    # use subprocess.call to execute query 
    script_name = ''.join(['run_searchbin_', building, '.sh'])
    script_path = '/'.join(['.', 'MATLAB', 'Penn-Analytics', script_name])
    call(['sudo', script_path, str(binNum)])
  else:
    func_name = ''.join(['searchbin_',building])
    if building == 'huntsmanhall':
      #TODO: need to hard-code for each supported building
      matlab_engine.searchbin_HuntsmanHall(str(binNum))

  # wait for query to complete and output file to be created/modified
  while handler.process_done == False:
    time.sleep(1)
  observer.stop()
  observer.join()

  # read query output file
  response = read_json(target_path)
#  print 'read data from response file {}: {}'.format(target_path, response)

  # transform response data into name-value pairs
  response_transformed = {}
  names = response['names']
  vals = response['values']
  for i in range(0, len(names)):
    response_transformed[names[i]] = vals[i]

  # update DB with query result to update graphical output 
  db_name = 'energydata'
  coll_name = 'searchbin_results'
  db_data = {}
  for k in response_transformed.keys():
    val = response_transformed[k]
    if isinstance(val, float):
      val = round(val, 3)
      response_transformed[k] = round(response_transformed[k], 1)
    db_data[k] = val 
  db_data['building'] = building
  db_data['usagekW'] = usagekW
  db_data['_id'] = 1
  inserted_obj_id = db_insert(db_name, coll_name, db_data)
  print 'inserted into:', db_name, coll_name, inserted_obj_id

  db_name = 'energydata'
  coll_name = 'pagename'
  db_data_page = {}
  db_data_page['_id'] =1
  db_data_page['name'] = 'building_conditions'
  inserted_obj_id = db_insert(db_name, coll_name, db_data_page)
  print "inserted_into:", db_name, coll_name, inserted_obj_id

  # return content for vocal response 
  return response_transformed

def start_server(ipaddr, port):
  #eng = None
  eng = matlab.engine.start_matlab()
  eng.addpath('./MATLAB')
  eng.addpath_all(nargout=0)

  # Create a TCP/IP socket
  sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
  sock.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)

  # Bind the socket to the port
  server_address = (ipaddr, port)
  print >>sys.stderr, 'starting up on %s port %s' % server_address
  sock.bind(server_address)

  # Listen for incoming connections
  sock.listen(1)

  end_flag = '$'

  while True:
    # Wait for a connection
    print >>sys.stderr, 'waiting for a connection'
    connection, client_address = sock.accept()

    try:
      print >>sys.stderr, 'connection from', client_address

      # Receive the data in small chunks and retransmit it
      query_parts= []
      while True:
        data = connection.recv(16)
        print >>sys.stderr, 'received "%s"' % data
        if data:
          # build query from lambda
          query_parts.append(data)
          if end_flag in data:
            break

      print >>sys.stderr, 'no more data from', client_address
      # reconstruct query string
      query_str = ''.join([s for s in query_parts])
      query_str = query_str[0:-1]
      # parse query type and parameters
      query = json.loads(query_str)
      print "received query:", query
      
      if query['type'] == 1:
        response = call_searchbin(query, eng)
      elif query['type'] == 2:
        response = call_baseline(query, True, eng)
      elif query['type'] == 3:
        response = call_baseline(query, False, eng)
      elif query['type'] == 4:
        response = call_evaluator(query, eng)

      response_str = json.dumps(response) + end_flag
      print "response", response_str
      connection.sendall(response_str)
      print "sent:", response_str

    finally:
      # Clean up the connection
      connection.close()

if __name__ == "__main__":
  sys.exit(start_server('0.0.0.0', 9000))
