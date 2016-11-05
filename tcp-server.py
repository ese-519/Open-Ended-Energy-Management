import socket
import sys
import subprocess
import pymongo

def update_db():
  pass

def query_kdd(data):
  pass

def start_server(ipaddr, port):
  # Create a TCP/IP socket
  sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)

  # Bind the socket to the port
  server_address = (ipaddr, port)
  print >>sys.stderr, 'starting up on %s port %s' % server_address
  sock.bind(server_address)

  # Listen for incoming connections
  sock.listen(1)

  while True:
    # Wait for a connection
    print >>sys.stderr, 'waiting for a connection'
    connection, client_address = sock.accept()

    try:
      print >>sys.stderr, 'connection from', client_address

      # Receive the data in small chunks and retransmit it
      query_from_lambda = []
      while True:
        data = connection.recv(16)
        print >>sys.stderr, 'received "%s"' % data
        if data:
#TODO: remove          print >>sys.stderr, 'sending data back to the client'
#          connection.sendall(data)
          # build query from lambda
          query_from_lambda.append(data)
        else:
          print >>sys.stderr, 'no more data from', client_address
          # reconstruct query string
          query = ''.append([s for s in query_from_lambda])
          # TODO: parse query type and parameters
          # TODO: use subprocess.call to query KDD
          # TODO: wait for KDD query to complete
          # TODO: update DB with query result to update graphical output with pymongo.MongoClient
          # TODO: determine content for vocal response, send back to lambda using connection.sendall(some_data_here)
          break
            
    finally:
      # Clean up the connection
      connection.close()

if __name__ == "__main__":
  sys.exit(start_server('0.0.0.0', 9000))
