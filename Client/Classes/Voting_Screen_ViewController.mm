//
//  Voting_Screen_ViewController.mm
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

#import "Voting_Screen_ViewController.h"
#import "NetworkController.h"
#import "PlayModule.h"

@interface Voting_Screen_ViewController ()

@end

@implementation Voting_Screen_ViewController

// Countdown refresh label, in seconds
#define COUNTDOWN_REFRESH (1)

static NSMutableArray *gAnswers = NULL;

// Countdown time
static NSInteger countdownTime = 0;

static PlayModule *play = NULL;

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    // Hide the countdown in case it's broken
    [countdownTimer setText:@""];
    
    // Start the timing engine only once from here
    if (play == NULL)
        play = [PlayModule sharedInstance];

#ifndef DEBUG
    [debugLabel setHidden:TRUE];
#endif
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

// Pressed the vote button
- (IBAction)pressedVote:(id)sender
{
    // Return to main screen
    [self dismissViewControllerAnimated:YES completion:nil];
}

// Countdown Refresh
-(void)timerCountdownRefresh:(NSTimer *)theTimer
{
    // Cancel the timer on expiration
    if (countdownTime <= 0)
    {
        [theTimer invalidate];
        [countdownTimer setText:@""];
        return;
    }

    NSString *countdownString = [NSString stringWithFormat:@"%d", --countdownTime];
    [countdownTimer setText:countdownString];
}

- (void)setQuestion:(NSString *)question withanswers:(NSMutableArray *)answers withCountdown:(NSInteger)countDown
{
    NSLog(@"Set the question to: %@", question);
    NSLog(@"Set the answers to: %@", answers);
    NSLog(@"Delay set to: %d", countDown);

    // Set the question
    [pollLabel setText:question];
    
    // Set the answers
    gAnswers = answers;
    [answersView reloadData];
    
    // Set the countdown
    countdownTime = countDown;
    if (countdownTime)
    {
        NSString *countdownString = [NSString stringWithFormat:@"%d", countDown];
        [countdownTimer setText:countdownString];
        
        // Launch the timer
        [NSTimer scheduledTimerWithTimeInterval:COUNTDOWN_REFRESH
                                         target:self
                                       selector:@selector(timerCountdownRefresh:)
                                       userInfo:nil
                                        repeats:YES];
        
        return;
    }

    [countdownTimer setText:@""];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    NSLog(@"Answer count: %u",gAnswers.count );
    return gAnswers.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView
         cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Identifier for retrieving reusable cells.
    NSString *cellIdentifier = @"MyCellIdentifier"; // Attempt to request the reusable cell.
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    
    // If no cell available, create one.
    if(cell == nil)
    {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault
                                 reuseIdentifier:cellIdentifier];
    }

    // Set the text of the cell to the row index.
    cell.textLabel.text = gAnswers[indexPath.row];
    cell.textLabel.textColor=[UIColor colorWithWhite:1.0f alpha:1.0f];
    cell.textLabel.textAlignment = NSTextAlignmentCenter;
    UIFont *myFont = [UIFont systemFontOfSize:32];
    cell.textLabel.font  = myFont;
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
    
    NSString *message = [NSString stringWithFormat:@"$VOTE$%@$%@$", cell.textLabel.text, [pollLabel text]];
    
    [[play getNetworkController] sendMessage:self withMessage:message];
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
