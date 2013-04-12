//
//  Social_Media_ViewController.h
//  The Mobile Stage
//
//  Created by Mike Dai Wang on 2013-03-18.
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

#import <UIKit/UIKit.h>

#import "UIBubbleTableViewDataSource.h"

@interface Social_Media_ViewController : UIViewController <UIBubbleTableViewDataSource, UIGestureRecognizerDelegate>
{
    // Buble data
    NSMutableArray *bubbleData;
    
    // Twitter account information
    ACAccountStore *accountStore;
    ACAccount *twitterAccount;

    // Activity indicator
    IBOutlet UIActivityIndicatorView *activityIndicator;
}

@property (weak, nonatomic) IBOutlet UIBubbleTableView *bubbleTable;

- (IBAction)clickedBack:(id)sender;
- (IBAction)tweetButton:(id)sender;
- (IBAction)refreshButton:(id)sender;
@property (weak, nonatomic) IBOutlet UIImageView *resultImage;


@end
