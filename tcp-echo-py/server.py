import socket
import sys

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
      received_data = []
      while True:
        data = connection.recv(16)
        print >>sys.stderr, 'received "%s"' % data
        if data:
          received_data.append(data)
          if end_flag in data:
            break
      print >>sys.stderr, 'no more data from', client_address
      print >>sys.stderr, 'sending data back to the client'
      connection.sendall(''.join([s for s in received_data]))
            
    finally:
      # Clean up the connection
      connection.close()

if __name__ == "__main__":
  sys.exit(start_server('127.0.0.1', 9000))
