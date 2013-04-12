#Mike: Custom protocol server for the mobile app clients
#send launch, start, stop, resume, notifications, trigger, ar_cut
#receive vote$selection

from twisted.internet.protocol import Protocol

class StageServer(Protocol):
    clientIP = []
    clientList = set()
    pollResult = ""
    pollTweet = ""
    waiting = "hidden"
    prevPollTitle = ""
    currentPollTitle = "How do you feel?"
    result = {'Be Happy' : 3, 'Be Sad' : 4, 'Be Angry':9}
    
    def __init__(self):
        self.resetPoll()
        return
        #constrcutor, nothing in it right now
    
    #add new connection to an array when they connect
    def connectionMade(self):
        self.factory.clients.append(self)
        ip = self.transport.getPeer().host
        self.clientIP.append(ip)
        StageServer.clientList.add(self)
        print "Server: a new client has connected "	+ ip

	#get rid of connection if they are gone
    def connectionLost(self, reason):
        StageServer.clientList.remove(self)
        print "lost connection"
        ip = self.transport.getPeer().host
        self.clientIP.remove(ip)
        print "connection from: " + ip + "lost"
        self.factory.clients.remove(self)

	#receive data from clients
	#need to define the types of control messages here
    def dataReceived(self, data):
        chunks = data.split('$')

        if len(chunks) > 1:
            command = chunks[1]
            payload = chunks[2]

            if command == "VOTE":
                clientIP = self.transport.getPeer().host
                self.addPoll(chunks[2],chunks[3])
            elif command == "ID":
                print "A new client has joined: " + payload
    
    @classmethod
    def broadcast(self, broadcastMessage):
        for client in self.clientList:
            client.transport.write(broadcastMessage)
    
    @classmethod
    def resetPoll(cls):
        StageServer.prevPollTitle = StageServer.currentPollTitle
        StageServer.currentPollTitle = ""
        StageServer.result = {}
        StageServer.pollResult = ""
        StageServer.pollTweet = ""
        StageServer.waiting="hidden"
        return

    def addPoll(self, vote, pollTitle):
        # if you don't want duplicate polls, uncomment the following 2 lines
        #if (pollTitle == StageServer.prevPollTitle):
        #    return
        if (StageServer.currentPollTitle == ""):
            StageServer.currentPollTitle = pollTitle
        if (pollTitle == StageServer.currentPollTitle):
            if vote in StageServer.result:
                StageServer.result[vote] += 1
            else:
                StageServer.result[vote] = 1
        StageServer.waiting = ""
        self.buildChart()
        return

    def buildChart(self):
        head = ''
        tail = ''
        for k, v in self.result.iteritems():
            head = head + str(v) + ','
            tail = tail + k + '%7C'
        StageServer.pollResult = '$' + head[:-1] + '$' + tail[:-3] + "$" + self.currentPollTitle
        self.buildTweet()
        return

    def buildTweet(self):
        head = "http://chart.googleapis.com/chart?chf=a,s,000000C8&chs=350x225&cht=p3&chd=t:"
        tail = "&chts=a&chdl="

        for k, v in self.result.iteritems():
            head = head + str(v) + ','
            tail = tail + k + '%7C'
        StageServer.pollTweet = head[:-1] + tail[:-3] + "&chtt=" + self.currentPollTitle
    
    @classmethod
    def getChart(cls):
        #maybe for demo use
        #return "http://chart.googleapis.com/chart?chf=a,s,000000C8&chs=350x225&cht=p3&chd=t:3,4,5&chts=a&chdl=Be Happy%7CBe Sad%7CBe Angry&chtt=How Do You Feel?" 
        return StageServer.pollTweet

    @classmethod
    def getTweet(cls):
        return StageServer.pollResult

    @classmethod
    def getWaiting(cls):
        return StageServer.waiting

    def sendTrigger(self):
        message = "$TRIGGER$"
        self.broadcast(message)

    def sendAR_CUT(self):
        message = "$AR_CUT$"
        self.broadcast(message)
