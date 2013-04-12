//
//  PlayModule.h
//  The Mobile Stage
//
//  Created by Remi Dufour on 2013-02-21.
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

#import <Foundation/Foundation.h>
#import "InputController.h"
#import "NetworkController.h"
#import "AR_ViewController.h"
#import "Character_Selection_ViewController.h"
#import "Voting_Screen_ViewController.h"

@interface PlayModule : NSObject <NetworkDelegate>
{
    NetworkController *networkController;
}

- (NetworkController *)getNetworkController;

// Get a Play Module instance
//
// Retrieves a singleton of the play
//
// Parameters: None
// Returns: A play module instance
+ (PlayModule *)sharedInstance;

// Load the Play Input
//
// The play must be stopped before loading an input.
//
// Parameters: inputParam[in] The play input parameter
// Returns: Nothing
- (void)Load:(InputController *)inputParam withView:(UIViewController *)currentView;

// Starts the Play Module from the beginning
//
// The play must be loaded, but not started.
//
// Parameters: currentView[in] The current view
// Returns: Nothing
- (void)Start:(UIViewController *)currentView;

// Stops the Play Module
//
// The play must be started.
//
// Parameters: None
// Returns: Nothing
- (void)Stop;

// Resume the Play Module from its current location
//
// The play must be stopped.
//
// Parameters: None
// Returns: Nothing
- (void)Resume;

// Set the polling question
- (void)setQuestion:(Voting_Screen_ViewController *)vc;

// Set the character selection countdown
- (void)setCountdown:(Character_Selection_ViewController *)vc;

// Set the Augmented Reality media
- (void)setMedia:(AR_ViewController *)vc;

@end
