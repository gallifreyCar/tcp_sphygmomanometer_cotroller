import random
import socket

s = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
s.bind(("0.0.0.0", 1134))
s.listen()

while True:
    c, addr = s.accept()
    print(addr, "connected")
    # while True:
    #     data = c.recv(1024)
    #     # print(data)
    #     print(data.decode('utf-8'))
    #     if not data:
    #         break
    #     c.sendall(data)
    while True:
        a = input()
        message = 's:' + str(random.randint(70, 80)) + ',d:' + str(random.randint(80, 95)) + ',h:' + str(
            random.randint(0, 50))
        if a == 'send':
            c.sendall(message.encode())
            print('200 ok')
