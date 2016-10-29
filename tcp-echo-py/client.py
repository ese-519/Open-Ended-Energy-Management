import socket
import sys

def client_tcp_session(server_addr, server_port):
  # Create a TCP/IP socket
  sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)

  # Connect the socket to the port where the server is listening
  server_address = (server_addr, server_port)
  print >>sys.stderr, 'connecting to %s port %s' % server_address
  sock.connect(server_address)

  try:
    # Send data
    message = 'This is the message.  It will be repeated.'
    print >>sys.stderr, 'sending "%s"' % message
    sock.sendall(message)

    # Look for the response
    amount_received = 0
    amount_expected = len(message)

    while amount_received < amount_expected:
      data = sock.recv(16)
      amount_received += len(data)
      print >>sys.stderr, 'received "%s"' % data

  finally:
    print >>sys.stderr, 'closing socket'
    sock.close()

if __name__ == "__main__":
  if len(sys.argv) != 3:
    print 'Usage: client.py <server IP address> <server port>'
    sys.exit()
  server_addr = sys.argv[1]
  server_port = int(sys.argv[2])
  sys.exit(client_tcp_session(server_addr, server_port))
