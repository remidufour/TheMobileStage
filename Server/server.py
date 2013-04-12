#!/usr/bin/python
#Mike: server written with Python and Twisted
#2 servers:
#1. StageServer: custom protocol server for the mobile app clients
#2. StageController: http server for control interface
#Usage: python server.py to start server, connection mobile applications to ipOfServer:1234, connect to control page at ipOfServer:8080
#Valid outgoing commands: launch, start, stop, resume, notifications, trigger, ar_cut
#Valid incoming commands: receive vote$selection (not implemented yet)

# Shared imports
from twisted.internet import reactor, protocol
from twisted.web import server, resource
import StageServer, StageController

def main():
    resource = StageController.StageController()
    site = server.Site(resource)
    reactor.listenTCP(8080, site) 

    reactor.listenTCP(16384, resource.factory)
    print "Server Started..."
    reactor.run()

if __name__ == '__main__':
    main()
