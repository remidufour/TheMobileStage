//
//  NetworkController.m
//
//  Created by Mike Dai Wang on 2013-02-21.
//  Copyright (c) 2013 Mike Dai Wang. All rights reserved.
//
//
//  Copyright (C) 2013 Remi Dufour & Mike Dai Wang
//
//  Permission is hereby granted, free of charge, to any person obtaining
//  a copy of this software and associated documentation files (the
//  "Software"), to deal in the Software without restriction, including
//  without limitation the rights to use, copy, modify, merge, publish,
//  distribute, sublicense, and/or sell copies of the Software, and to
//  permit persons to whom the Software is furnished to do so, subject to
//  the following conditions:
//
//  The above copyright notice and this permission notice shall be
//  included in all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
//  EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
//  MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
//  IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
//  CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
//  TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
//  SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
//

#import "NetworkController.h"

@implementation NetworkController

@synthesize delegate;

- (void)initializeNetwork
{
	CFReadStreamRef readStream;
	CFWriteStreamRef writeStream;
    
    // Control panel accessible @ http://tms.kiexi.com
    CFStreamCreatePairWithSocketToHost(NULL, (CFStringRef)@"tms.kiexi.com", 16384, &readStream, &writeStream);
	
	inputStream = (__bridge NSInputStream *)readStream;
	outputStream = (__bridge NSOutputStream *)writeStream;
	[inputStream setDelegate:self];
	[outputStream setDelegate:self];
	[inputStream scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
	[outputStream scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
	[inputStream open];
	[outputStream open];
}

- (IBAction)sendMessage:(id)sender withMessage:(NSString *)message
{
	NSData *data = [[NSData alloc] initWithData:[message dataUsingEncoding:NSASCIIStringEncoding]];
	[outputStream write:[data bytes] maxLength:[data length]];
}

- (void)stream:(NSStream *)theStream handleEvent:(NSStreamEvent)streamEvent
{
	//NSLog(@"stream event %i", streamEvent);
	
	switch (streamEvent)
    {
		case NSStreamEventOpenCompleted:
			//NSLog(@"Stream opened");
			break;
		case NSStreamEventHasBytesAvailable:
            
			if (theStream == inputStream)
            {
				uint8_t buffer[1024];
				int len;
				
				while ([inputStream hasBytesAvailable])
                {
					len = [inputStream read:buffer maxLength:sizeof(buffer)];
					if (len > 0)
                    {
						NSString *output = [[NSString alloc] initWithBytes:buffer length:len encoding:NSASCIIStringEncoding];
						
						if (nil != output)
                        {
							NSLog(@"Received message from server: %@", output);
							[[self delegate] processMessage:output];
						}
					}
				}
			}
			break;
            
			
		case NSStreamEventErrorOccurred:
			
			NSLog(@"Can not connect to the host!");
			break;
			
		case NSStreamEventEndEncountered:
            
            [theStream close];
            [theStream removeFromRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
			
			break;
		default:
            break;
            NSLog(@"Unknown event");
	}
    
}

@end
