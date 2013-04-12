//
//  Standby_ViewController.mm
//  The Mobile Stage
//
//  Created by Remi Dufour on 2013-02-22.
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

#import "Standby_ViewController.h"
#import "InputController.h"
#import "PlayModule.h"

// Default XML filename
#define XML_FILENAME @"final_demo.xml"

@interface Standby_ViewController ()

@end

@implementation Standby_ViewController

static InputController *input = NULL;
static PlayModule *play = NULL;

// Is in programme view
bool isInProgramme = false;

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    // Load the XML only once from here
    if (input == NULL)
    {
        // Retrieve the Input Controller
        InputController *instance = [InputController sharedInstance];
        
        // Load the XML
        if ([instance loadXML:XML_FILENAME] == false)
            return;
        
        input = instance;
    }

    if (play == NULL)
    {
        play = [PlayModule sharedInstance];
        [play Load:input withView:self];
    }
    
#ifndef DEBUG
    [debugLabel setHidden:TRUE];
#endif
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

// Next event of play starts
-(void)launchPlay
{
    // Go to welcome screen
    if (isInProgramme)
    {
        [self dismissViewControllerAnimated:YES completion:^{
            [self performSegueWithIdentifier:@"launch_segue" sender:self];
            return;
        }];
    }
    
    [self performSegueWithIdentifier:@"launch_segue" sender:self];
}

- (IBAction)pressedProgramme:(id)sender
{
    isInProgramme = true;
    [self performSegueWithIdentifier:@"launch_programme" sender:self];
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