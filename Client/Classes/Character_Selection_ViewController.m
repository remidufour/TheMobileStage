//
//  Character_Selection_ViewController.m
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

#import "Character_Selection_ViewController.h"
#import "InputController.h"

@interface Character_Selection_ViewController ()

@end

@implementation Character_Selection_ViewController

// Countdown refresh label, in seconds
#define COUNTDOWN_REFRESH (1)

// Countdown time
static NSInteger countdownTime = 0;

static InputController *input = NULL;

static NSArray *characters = nil;

- (void)awakeFromNib
{
    // Retrieve the Input Controller
    if (input == NULL)
        input = [InputController sharedInstance];
    
    // Load characters and their images
    characters = [input getCharacters];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    // Load the character selection label
    [selectionLabel setText:[input getCharacterSelectionLabel]];
    
    // Hide the countdown in case it's broken
    [countdownLabel setText:@""];
    
    // Configure carousel
    carousel.type = iCarouselTypeRotary;

#ifndef DEBUG
    [debugLabel setHidden:TRUE];
#endif
    
    NSLog(@"Characters count is %d", characters.count);
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    
    // Free up memory by releasing subviews
    carousel = nil;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

- (NSUInteger)numberOfItemsInCarousel:(iCarousel *)carousel
{
    // Return the total number of characters
    return [characters count];
}

- (CGFloat)carousel:(iCarousel *)carousel valueForOption:(iCarouselOption)option withDefault:(CGFloat)value
{
    switch (option)
    {
        case iCarouselOptionWrap:
            return TRUE;
        case iCarouselOptionSpacing:
            return 4.0f;
        default:
            return value;
    }
    
    return value;
}

- (UIView *)carousel:(iCarousel *)carousel viewForItemAtIndex:(NSUInteger)index reusingView:(UIView *)view
{
    // Reuse view if available for recycling
    if (view)
        return view;

    NSArray *character = characters[index];
    view = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 200.0f, 200.0f)];

    view.contentMode = UIViewContentModeCenter;
    
    // Set the text of the cell to the row index
    UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(0, 250.0f, 200.0f, 50.0f)];
    label.text = character[INDEX_CHARACTER_NAME];
    label.backgroundColor = [UIColor clearColor];

    label.textColor=[UIColor colorWithRed:0x4B/255.0f green:0x4B/255.0f blue:0x4B/255.0f alpha:1.0f];

    label.textAlignment = NSTextAlignmentCenter;
    UIFont *myFont = [UIFont systemFontOfSize:32];
    label.font = myFont;
    
    // Add an image to the row
    UIImage *cellImage = [UIImage imageNamed:character[INDEX_CHARACTER_PICTURE]];
    UIImageView *imageView = [[UIImageView alloc] initWithImage:cellImage];
    [imageView setCenter:CGPointMake(100.0, 0.0)];

    [view addSubview:imageView];
    [view addSubview:label];
    
    return view;
}

// Countdown Refresh
-(void)timerCountdownRefresh:(NSTimer *)theTimer
{
    // Cancel the timer on expiration
    if (countdownTime <= 0)
    {
        [theTimer invalidate];
        [countdownLabel setText:@""];
        return;
    }
    
    NSString *countdownString = [NSString stringWithFormat:@"%d", --countdownTime];
    [countdownLabel setText:countdownString];
}

- (void)setCountdown:(NSInteger)countDown
{
    NSLog(@"Delay set to: %d", countDown);

    countdownTime = countDown;
    if (countdownTime)
    {
        NSString *countdownString = [NSString stringWithFormat:@"%d", countDown];
        [countdownLabel setText:countdownString];

        // Launch the timer
        [NSTimer scheduledTimerWithTimeInterval:COUNTDOWN_REFRESH
                                         target:self
                                       selector:@selector(timerCountdownRefresh:)
                                       userInfo:nil
                                        repeats:YES];
        
        return;
    }

    [countdownLabel setText:@""];
}

- (IBAction)pressedBack:(id)sender
{
    // Return to main screen
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return characters.count;
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
