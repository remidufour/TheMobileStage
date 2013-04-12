//
//  Programme_ViewController.m
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

#import "Programme_ViewController.h"
#import "InputController.h"

@interface Programme_ViewController ()

@end

@implementation Programme_ViewController

static InputController *input = NULL;

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    // Load the XML only once from here
    if (input == NULL)
    {
        // Retrieve the Input Controller
        input = [InputController sharedInstance];
    }

    // Load the web view
    NSURL *url = [NSURL URLWithString:[input getURL]];
    NSURLRequest *loadRequest = [NSURLRequest requestWithURL:url];
    [urlLabel loadRequest:loadRequest];
    [urlLabel setHidden:TRUE];
    [webActivity startAnimating];
}

- (void)webViewDidFinishLoad:(UIWebView *)webView
{
    // We can display the webview now that it's loaded
    [urlLabel setHidden:FALSE];
    [webActivity stopAnimating];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

- (IBAction)pressedBack:(id)sender
{
    // Return to main screen
    [self dismissViewControllerAnimated:YES completion:nil];
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
