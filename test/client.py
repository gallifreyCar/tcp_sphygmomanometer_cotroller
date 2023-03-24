import socket

with socket.socket(socket.AF_INET, socket.SOCK_STREAM) as s:
    s.connect(("192.168.0.160", 1134))
    s.sendall(b"Hello,Ross!")
    data = s.recv(1024)
    print("Receive:", repr(data))
