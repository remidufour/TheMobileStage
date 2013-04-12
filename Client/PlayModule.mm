//
//  PlayModule.mm
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

#import "PlayModule.h"
#import "Standby_ViewController.h"

// Server command indexes
enum
{
    // Mandatory indexes
    INVALID_INDEX = 0,
    COMMAND_INDEX = 1,

    INDEX_COUNT = 2,
    
    // Optional indexes
    PAYLOAD_INDEX = 2
};

// Play Module Singleton
static PlayModule *sharedInstance = NULL;

// Input Controller
static InputController *input = NULL;

// Theatrical Play
static NSArray *play = NULL;
static unsigned int current = 0;
static NSTimer *currentTimer = NULL;
static bool starting = FALSE;

// Current view controller
static UIViewController *viewController = NULL;

// Initial view controller (e.g standby screen)
static UIViewController *loadViewController = NULL;

// Augmented Reality (cuts) view controller
static AR_ViewController *arViewController = NULL;

@implementation PlayModule

// Constructor
- (id)init
{
    // initialize network connection
    networkController = [[NetworkController alloc] init];
    [networkController setDelegate:self];
    [networkController initializeNetwork];

    return self;
}

- (NetworkController *)getNetworkController
{
    return networkController;
}

// Get the shared instance and create it if necessary.
+ (PlayModule *)sharedInstance
{
    if (sharedInstance == nil)
    {
        sharedInstance = [[super allocWithZone:NULL] init];
    }
    
    return sharedInstance;
}

// Next event of play ends
-(void)timerEventEnd:(NSTimer *)theTimer
{
    NSLog(@"End Event arrived.");
    
    // Return to main screen
    [viewController dismissViewControllerAnimated:YES completion:^{

        // Next event is starting-type trigger
        starting = TRUE;
        
        // If is done, return
        if (current >= play.count)
            return;

        // Launch the next event
        NSArray *event = play[current];

        // For manual end trigger, wait for the message from server
        if ([event[EVENT_START_TRIGGER_INDEX] integerValue] == EVENT_TRIGGER_MANUAL)
            return;

        // Launch the timer
        currentTimer = [NSTimer scheduledTimerWithTimeInterval:[event[EVENT_START_INDEX] integerValue]
                                                        target:self
                                                      selector:@selector(timerEventStart:)
                                                      userInfo:nil
                                                       repeats:NO];
    }];
}

// Next event of play starts
-(void)timerEventStart:(NSTimer *)theTimer
{
    NSLog(@"Start Event arrived.");
    
    // Return to main screen and then jump to next event
    NSArray *event = play[current++];
    
    EVENT_TYPES type = (EVENT_TYPES)[event[EVENT_TYPE_INDEX] integerValue];
    switch (type)
    {
        case EVENT_SELECT_CHARACTER:
            [viewController performSegueWithIdentifier:@"character_selection" sender:self];
            break;
        case EVENT_POLL:
            [viewController performSegueWithIdentifier:@"event_poll" sender:self];
            break;
        case EVENT_AR:
            [viewController performSegueWithIdentifier:@"event_ar" sender:self];
            break;
        default:
            NSLog(@"Unrecognized event type");
            break;
    }
    
    // Next event is ending-type trigger
    starting = FALSE;

    // For manual end trigger, wait for the message from server
    if ([event[EVENT_END_TRIGGER_INDEX] integerValue] == EVENT_TRIGGER_MANUAL)
        return;

    // Launch the timer
    currentTimer = [NSTimer scheduledTimerWithTimeInterval:[event[EVENT_DELAY_INDEX] integerValue]
                                                    target:self
                                                  selector:@selector(timerEventEnd:)
                                                  userInfo:nil
                                                   repeats:NO];
}

- (void)Load:(InputController *)inputParam withView:(UIViewController *)currentView
{
    input = inputParam;
    loadViewController = currentView;
}

- (void)Start:(UIViewController *)currentView;
{
    if (viewController == nil)
    {
        if (currentView == nil)
        {
            NSLog(@"Error, no views to load");
            return;
        }
    }
    
    // Always refresh the current view controller
    if (currentView)
        viewController = currentView;

    // Retrieve the theatrical play
    play = [input getPlay];
    
    // Play the first event
    starting = TRUE;
    current = 0;
    NSArray *event = play[current];
    
    // For manual start trigger, wait for the message from server
    if ([event[EVENT_START_TRIGGER_INDEX] integerValue] == EVENT_TRIGGER_MANUAL)
        return;
    
    // Launch the timer
    currentTimer = [NSTimer scheduledTimerWithTimeInterval:[event[EVENT_START_INDEX] integerValue]
                                                    target:self
                                                  selector:@selector(timerEventStart:)
                                                  userInfo:nil
                                                   repeats:NO];
}

- (void)Stop
{
    NSLog(@"Play was stopped.");

    [currentTimer invalidate];
    currentTimer = NULL;
}

- (void)Resume
{
    // Retrieve the theatrical play
    play = [input getPlay];
    
    // Play the current event
    NSArray *event = play[current];

    // For manual start trigger, wait for the message from server
    if ([event[EVENT_START_TRIGGER_INDEX] integerValue] == EVENT_TRIGGER_MANUAL)
        return;

    // Launch the timer
    currentTimer = [NSTimer scheduledTimerWithTimeInterval:[event[EVENT_START_INDEX] integerValue]
                                                    target:self
                                                  selector:@selector(timerEventStart:)
                                                  userInfo:nil
                                                   repeats:NO];
}

- (void)setQuestion: (Voting_Screen_ViewController *)vc
{
    // Don't set polling question if play isn't started
    if (current == 0)
        return;

    NSArray *event = play[current - 1];

    // Set the polling question and answers
    [vc setQuestion:event[EVENT_POLL_STRING_INDEX]
        withanswers:event[EVENT_POLL_ANSWERS_INDEX]
      withCountdown:[event[EVENT_DELAY_INDEX] integerValue]];
}

- (void)setCountdown:(Character_Selection_ViewController *)vc
{
    // Don't set countdown play isn't started
    if (current == 0)
        return;

    NSArray *event = play[current - 1];
    
    // Set the polling question and answers
    [vc setCountdown:[event[EVENT_DELAY_INDEX] integerValue]];
}

- (void)setMedia:(AR_ViewController *)vc
{
    // Don't set countdown play isn't started
    if (current == 0)
        return;
    
    arViewController = vc;
    
    NSArray *event = play[current - 1];

    // Set the AR media
    [vc setMedia:event[EVENT_AR_MEDIA_INDEX]
       withblend:[event[EVENT_AR_BLEND] floatValue]
        withcuts:event[EVENT_AR_CUTS]];
}

- (void)processMessage:(NSString *)message
{
    NSLog(@"Play module is processing message.");
    
    NSArray *array = [message componentsSeparatedByString:@"$"];
    
    // Garanteed to have two components
    if ([array count] < INDEX_COUNT)
    {
        NSLog(@"Invalid message length!");
        return;
    }

    // Possible commands: LAUNCH, START, STOP, RESUME, TRIGGER, NOTIFY (with payload message).
    NSString *command = array[COMMAND_INDEX];
    NSLog(@"action received: %@", command);
    
    // Do switch statement here
    if ([command isEqualToString:@"LAUNCH"])
    {
        NSLog(@"Launch");
        Standby_ViewController *vc = (Standby_ViewController *)loadViewController;
        [vc launchPlay];
    }
    else if ([command isEqualToString:@"START"])
    {
        NSLog(@"Start");
        [self Start:viewController];
    }
    else if ([command isEqualToString:@"STOP"])
    {
        NSLog(@"Stop");
        [self Stop];
    }
    else if ([command isEqualToString:@"RESUME"])
    {
        NSLog(@"Resume");
        [self Resume];
    }
    else if ([command isEqualToString:@"TRIGGER"])
    {
        NSLog(@"Trigger");
        
        // If is done, return
        if (current >= play.count && starting == TRUE)
        {
            NSLog(@"Play is already over.");
            return;
        }

        if (starting)
            [self timerEventStart:nil];
        else
            [self timerEventEnd:nil];
    }
    else if ([command isEqualToString:@"NOTIFY"])
    {
        NSLog(@"Notify");
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Notification"
                                                        message:array[PAYLOAD_INDEX]
                                                       delegate:self
                                              cancelButtonTitle:@"Ok"
                                              otherButtonTitles:nil];
        [alert show];
    }
    else if ([command isEqualToString:@"AR_CUT"])
    {
        if (arViewController)
            [arViewController trigger];
    }
    else
    {
        NSLog(@"Unrecognized message!");
    }
}

@end
