import socket
import sys
import json
from subprocess import call
import pymongo

def update_db():
  pass

def query_kdd(data):
  pass

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

      # TODO: use subprocess.call to query KDD
      call(["./MATLAB/Penn-Analytics/run_searchbin_HuntsmanHall.sh", str(1)])
      # TODO: wait for KDD query to complete
      # TODO: update DB with query result to update graphical output with pymongo.MongoClient
      # TODO: determine content for vocal response, send back to lambda using connection.sendall(some_data_here)
      response = {'param1': 'value1', 'param2': 2, 'param3': 'value3'}
      response_str = json.dumps(response) + end_flag
      connection.sendall(response_str)
      print "sent:", response_str

    finally:
      # Clean up the connection
      connection.close()

if __name__ == "__main__":
  sys.exit(start_server('0.0.0.0', 9000))
