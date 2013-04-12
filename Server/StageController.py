# The Mobile Stage
#
# Http server for control interface
# Created by Mike Dai Wang 
#
# Note: python twitter is needed for this to work
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
from twisted.web.resource import Resource
from twisted.internet import protocol 
from twitter import *
import StageServer

class StageController(Resource):
    isLeaf = True

    def __init__(self):
        self.factory = protocol.Factory()
        self.factory.clients = []
        self.factory.protocol = StageServer.StageServer
        return
    
    def render_POST(self,request):
        with open("index.html","r") as myfile:
            page=myfile.read()

        if request.args:
            action = request.args["action"][0]
            if action == "TWEET":
                chartURL = request.args["pollResult"][0]
                self.tweetResult(chartURL)
                self.factory.protocol.resetPoll()

        page=page.replace("$pollResult$", self.factory.protocol.getChart())
        page=page.replace("$pollTweet$", self.factory.protocol.getTweet())
        page=page.replace("$waitingForResults$", self.factory.protocol.getWaiting())
        return page

    def render_GET(self,request):
        with open ("index.html", "r") as myfile:
            page=myfile.read().replace('$pollResult$', self.factory.protocol.getChart())
            page=page.replace('$pollTweet$', self.factory.protocol.getTweet()) 
            page=page.replace("$waitingForResults$", self.factory.protocol.getWaiting())
        
        if request.args:
            action = request.args["action"][0]
            if action == "NOTIFY":
                action = "NOTIFY$" + request.args["msg"][0]
            elif action == "TRIGGER":
                action = "TRIGGER"
            action = "$" + action
            print "sending command: " + action
            self.factory.protocol.broadcast(action) 
        return page

    def tweetResult(self,chartURL):
        twitter = Twitter(auth=OAuth(
          '1283940984-WqdSUnkpRWKGf1ZyHK49TYNyMqyqwLoegzHWAjT',
          'Ek29WBOmDCixscqnyqxcB2WtSEsWj8gQQhjI1yfwzs',
          'KD9Q1Bnu1HoDLPsc6VJftg',
          '7SSNpGeYuC8paKqtcKO7CMqpaSu6XJwi0rWeM9HU'))

        #use a default result for the demo
        #chartURL = 'http://chart.googleapis.com/chart?chf=a,s,000000C8&chs=313x225&cht=p3&chd=s:MSf&chdl=Be+happy%7CBe+sad%7CBe+angry&chtt=Chart+Title'

        myStatus = '#TheMobileStage poll=' + chartURL.replace(' ', '+')
        twitter.statuses.update(status=myStatus)
