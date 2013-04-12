#!/usr/bin/python
#
# Server written with Python and Twisted
# Created by Mike Dai Wang
#
# Copyright (C) 2013 Remi Dufour, Mike Dai Wang & Montgomery Martin
#
# Permission is hereby granted, free of charge, to any person obtaining
# a copy of this software and associated documentation files (the
# "Software"), to deal in the Software without restriction, including
# without limitation the rights to use, copy, modify, merge, publish,
# distribute, sublicense, and/or sell copies of the Software, and to
# permit persons to whom the Software is furnished to do so, subject to
# the following conditions:
#
# The above copyright notice and this permission notice shall be
# included in all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
# EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
# MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
# IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
# CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
# TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
# SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
#

# 2 servers:
# 1. StageServer: custom protocol server for the mobile app clients
# 2. StageController: http server for control interface
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
