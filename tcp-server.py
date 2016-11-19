import socket
import sys
import json
from subprocess import call
import pymongo

def call_searchbin(query):
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
    binNum = 5
    #TODO: add error case, inform user that max usage is 111 kW

  # use subprocess.call to query KDD
  scriptName = ''.join(['run_searchbin_', building, '.sh'])
  scriptPath = '/'.join(['.', 'MATLAB', 'Penn-Analytics', scriptName])
  call([scriptPath, str(binNum)])
  # TODO: wait for KDD query to complete
  # TODO: read query output file
  # TODO: update DB with query result to update graphical output with pymongo.MongoClient
  # TODO: return content for vocal response 
  response = {'param1': 'value1', 'param2': 2, 'param3': 'value3'}
  return response

def start_server(ipaddr, port):
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
        response = call_searchbin(query)

      response_str = json.dumps(response) + end_flag
      connection.sendall(response_str)
      print "sent:", response_str

    finally:
      # Clean up the connection
      connection.close()

if __name__ == "__main__":
  sys.exit(start_server('0.0.0.0', 9000))
