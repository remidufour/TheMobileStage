#Mike: Http server for control interface
#python twitter is needed for this to work
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
