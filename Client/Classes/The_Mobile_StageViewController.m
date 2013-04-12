//
//  The_Mobile_StageViewController.m
//  The Mobile Stage
//
//  Created by Remi Dufour on 2013-02-18.
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

#import "The_Mobile_StageViewController.h"
#import "PlayModule.h"

@interface The_Mobile_StageViewController ()

@end

@implementation The_Mobile_StageViewController

static PlayModule *play = NULL;

- (void)viewDidLoad
{
    [super viewDidLoad];

    // Start the timing engine only once from here
    if (play == NULL)
        play = [PlayModule sharedInstance];
    
#ifndef DEBUG
    [debugLabel setHidden:TRUE];
#endif
}

- (void)viewWillAppear:(BOOL)animated
{    
    [super viewWillAppear:animated];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
}

- (void)viewDidAppear:(BOOL)animated
{
    // Perform this only on initial appear
    static bool once = false;
    if (once == false)
    {
        once = true;
        
        // Launch the Play Module
        [play Start:self];
        
#ifdef DEBUG
        // Hack to prevent launching automation
        [play Stop];
#endif
    }
}

- (void)didReceiveMemoryWarning
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc. that aren't in use.
}

- (IBAction)pressedBack:(id)sender
{
    // Return to main screen
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (IBAction)pressedDebug:(id)sender
{
    [play Stop];
    [self performSegueWithIdentifier:@"debug_segue" sender:self];
}

// This will get called too before the view appears
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    // Set the poll question
    if ([[segue identifier] isEqualToString:@"event_poll"])
    {
        // Must dispatch to the main thread as UI elements will be modified
        dispatch_async(dispatch_get_main_queue(), ^{
            [play setQuestion: [segue destinationViewController]];
        });
        
        return;
    }
    
    // Set the character selection countdown
    if ([[segue identifier] isEqualToString:@"character_selection"])
    {
        // Must dispatch to the main thread as UI elements will be modified
        dispatch_async(dispatch_get_main_queue(), ^{
            [play setCountdown: [segue destinationViewController]];
        });
        
        return;
    }
    
    // Set the augmented reality parameters
    if ([[segue identifier] isEqualToString:@"event_ar"])
    {
        // Must dispatch to the main thread as UI elements will be modified
        dispatch_async(dispatch_get_main_queue(), ^{
            [play setMedia: [segue destinationViewController]];
        });
    }
}

-(BOOL)shouldAutorotate
{
    return YES;
}

- (NSUInteger)supportedInterfaceOrientations
{
    // Support landscape orientations only
    return UIInterfaceOrientationMaskLandscape;
}

@end
