//
//  Social_Media_ViewController.m
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

#import <Twitter/Twitter.h>
#import <Accounts/Accounts.h>
#import <QuartzCore/QuartzCore.h>

#import "Social_Media_ViewController.h"
#import "UIBubbleTableView.h"
#import "UIBubbleTableViewDataSource.h"
#import "NSBubbleData.h"

@interface Social_Media_ViewController ()
@end

@implementation Social_Media_ViewController

@synthesize bubbleTable;
@synthesize resultImage;

// check user access
bool granted;

// configuerable for each play
static const NSString *HASHTAG = @"TheMobileStage";
NSString *producer = @"TheMobileStage";

// twitter related misc.
NSString *dateForTwitter;
NSString *latestIdForTwitter;
NSTimer *tweetTimer;

// tap gesture recognizer to view poll results
UITapGestureRecognizer* tapRecognizer;

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    // hide the poll results initially
    resultImage.alpha = 0.0f;
    [resultImage setHidden:false];
    resultImage.userInteractionEnabled = NO;
    
    // get today's date, twitter will use it as a cut-off date to fetch new tweets
    NSDate *date = [NSDate date];
    NSCalendar *gregorian = [[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar];
    unsigned unitFlags = NSYearCalendarUnit | NSMonthCalendarUnit |  NSDayCalendarUnit;
    
    NSDateComponents *components = [gregorian components:unitFlags fromDate:date];
    dateForTwitter = [NSString stringWithFormat:@"%d-%d-%d", components.year, components.month, components.day];

    latestIdForTwitter = @"0";
    
    twitterAccount = nil;
    
    [self findTwitterAccount];
    
    if (twitterAccount == nil)
    {
        //not logged in
        //page will display tweets still, might add something here
    }

    bubbleData = [[NSMutableArray alloc] init];
    
    bubbleTable.bubbleDataSource = self;
    
    bubbleTable.showAvatars = YES;
    
    [bubbleTable reloadData];
    
    // fetch tweets with the hashtag
    [self fetchTweets];
    
    tweetTimer = [NSTimer scheduledTimerWithTimeInterval: 9.0
                       target: self
                       selector: @selector(timerEvent:)
                       userInfo: nil
                       repeats: YES];
    
    tapRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleTap:)];
    [bubbleTable addGestureRecognizer:tapRecognizer];
}

- (void)handleTap:(UITapGestureRecognizer*)gestureRecognizer
{
    if (gestureRecognizer.state == UIGestureRecognizerStateEnded)
    {
        CGPoint tapLocation = [gestureRecognizer locationInView:self.bubbleTable];
        NSIndexPath *tappedIndexPath = [self.bubbleTable indexPathForRowAtPoint:tapLocation];
        UIBubbleTableViewCell* tappedCell = (UIBubbleTableViewCell *)([self.bubbleTable cellForRowAtIndexPath:tappedIndexPath]);
        
        // won't show if it's a headercell
        if (![tappedCell isKindOfClass:[UIBubbleTableViewCell class]])
        {
            return;
        }
        
        UIView *tappedImage = tappedCell.data.view;
        
        // won't show if it's just a regular tweet
        if ([tappedImage class] == [UILabel class])
        {
            return;
        }
        
        UIImage *temp_img = ((UIImageView *)tappedImage).image;
        
        if (temp_img == nil) return;
        
        CGImageRef cgImage = [temp_img CGImage];
        
        // Make a new image from the CG Reference
        UIImage *img = [[UIImage alloc] initWithCGImage:cgImage];
        
        [resultImage setImage:img];
        
        [bubbleTable removeGestureRecognizer:tapRecognizer];
        [tapRecognizer removeTarget:self action:@selector(handleTap:)];
        [tapRecognizer addTarget:self action:@selector(closePollView:)];
        [resultImage addGestureRecognizer:tapRecognizer];
        
        resultImage.userInteractionEnabled = YES;
        
        [UIView beginAnimations:nil context:NULL];
        [UIView setAnimationDuration:1.0f];
        resultImage.alpha = 1.0f;
        [UIView commitAnimations];
        
        resultImage.layer.cornerRadius = 36.5;
        resultImage.layer.masksToBounds = YES;
        //resultImage.layer.borderColor = [UIColor colorWithWhite:0.0 alpha:0.2].CGColor;
        resultImage.layer.borderColor = [UIColor colorWithRed:75/255.0f green:75/255.0f blue:75/255.0f alpha:0.5f].CGColor;
        resultImage.layer.borderWidth = 3.0;
    }
}

- (void)closePollView:(UITapGestureRecognizer*)gestureRecognizer
{
    if (gestureRecognizer.state == UIGestureRecognizerStateEnded)
    {
        [UIView beginAnimations:nil context:NULL];
        [UIView setAnimationDuration:1.0f];
        resultImage.alpha = 0.0f;
        [UIView commitAnimations];
        
        resultImage.userInteractionEnabled = NO;
        [resultImage removeGestureRecognizer:tapRecognizer];
        [tapRecognizer removeTarget:self action:@selector(closePollView:)];
        [tapRecognizer addTarget:self action:@selector(handleTap:)];
        [bubbleTable addGestureRecognizer:tapRecognizer];
    }
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

// Clicked the Back button
- (IBAction)clickedBack:(id)sender
{
    [tweetTimer invalidate];
    // Return to main screen
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (IBAction)tweetButton:(id)sender
{
    [self showTweetSheet];
}

- (IBAction)refreshButton:(id)sender
{
    [self fetchTweets];
}

#pragma mark - UIBubbleTableViewDataSource implementation

- (NSInteger)rowsForBubbleTable:(UIBubbleTableView *)tableView
{
    return [bubbleData count];
}

- (NSBubbleData *)bubbleTableView:(UIBubbleTableView *)tableView dataForRow:(NSInteger)row
{
    return [bubbleData objectAtIndex:row];
}

#pragma mark - Actions

- (BOOL)userHasAccessToTwitter
{
    return [SLComposeViewController isAvailableForServiceType:SLServiceTypeTwitter];
}

- (void)showTweetSheet
{
    //  Create an instance of the Tweet Sheet
    SLComposeViewController *tweetSheet = [SLComposeViewController
                                           composeViewControllerForServiceType:
                                           SLServiceTypeTwitter];
    
    // Sets the completion handler.  Make sure UI updated by main thread
    tweetSheet.completionHandler = ^(SLComposeViewControllerResult result)
    {
        switch(result)
        {
             // cancelled
            case SLComposeViewControllerResultCancelled:
                break;
            // send
            case SLComposeViewControllerResultDone:
                break;
        }
        
        // Cancell or Send, dismiss tweet sheet
        dispatch_async(dispatch_get_main_queue(), ^
        {
            [self dismissViewControllerAnimated:NO completion:^
            {
                //NSLog(@"Tweet Sheet has been dismissed.");
            }];
        });
    };
    
    //  Set the initial body of the Tweet, set with hashtag
    NSString *initialString = [NSString stringWithFormat:@"#%@ ", HASHTAG];
    [tweetSheet setInitialText:initialString];
    
    //  Presents the Tweet Sheet to the user
    [self presentViewController:tweetSheet animated:NO completion:^
    {
        //NSLog(@"Tweet sheet has been presented.");
    }];
}

- (void)findTwitterAccount
{
    // Create an account store object.
	accountStore = [[ACAccountStore alloc] init];
    
	// Create an account type that ensures Twitter accounts are retrieved.
    ACAccountType *accountType = [accountStore accountTypeWithAccountTypeIdentifier:ACAccountTypeIdentifierTwitter];
	
	// Request access from the user to use their Twitter accounts.
    [accountStore requestAccessToAccountsWithType:accountType options:NULL completion:^(BOOL granted, NSError *error)
    {
        if(granted)
        {
			// Get the list of Twitter accounts.
            NSArray *accountsArray = [accountStore accountsWithAccountType:accountType];
			
            // might be more than 1 account present, we only use the 1st one.
			if ([accountsArray count] > 0)
            {
				twitterAccount = [accountsArray objectAtIndex:0];
            }
        }
	}];
}

-(void) timerEvent:(NSTimer*) t
{
    [self fetchTweets];
}

- (void)fetchTweets
{
    if ([self userHasAccessToTwitter])
    {
        NSString *twitterQuery = [NSString stringWithFormat:@"http://search.twitter.com/search.json?q=%%23%@+since%%3A%@+since_id%%3A%@", HASHTAG, dateForTwitter, latestIdForTwitter];
        NSURL *url = [NSURL URLWithString:twitterQuery];
        SLRequest *request =[SLRequest requestForServiceType:SLServiceTypeTwitter
                                       requestMethod:SLRequestMethodGET
                                       URL:url
                                       parameters:nil];
        
        [request performRequestWithHandler:^(NSData *responseData,
                                             NSHTTPURLResponse *urlResponse,
                                             NSError *error)
        {            
            if (responseData)
            {
                if (urlResponse.statusCode >= 200 && urlResponse.statusCode < 300)
                {
                    NSError *jsonError=nil;
                    NSDictionary *queryReturn = [NSJSONSerialization JSONObjectWithData:responseData
                                                                     options:NSJSONReadingMutableContainers
                                                                     error:&jsonError];
                             
                    NSString *userName, *profilePic, *tweetTime, *tweet, *displayName, *pollResults;
                             
                    if (queryReturn)
                    {
                        NSArray *queryResults = [queryReturn objectForKey: @"results"];
                        
                        bool foundLatest = false;
                        NSMutableArray *currentRefresh = [[NSMutableArray alloc] init];
                    
                        for (NSDictionary *item in queryResults)
                        {
                            if (!foundLatest)
                            {
                                foundLatest = true;
                                latestIdForTwitter = [item objectForKey:@"id_str"];
                            }
                            tweetTime = [self convertTweetTime:[item objectForKey:@"created_at"]];
                            userName = [item objectForKey:@"from_user"];
                            displayName = [item objectForKey:@"from_user_name"];
                            profilePic = [[item objectForKey:@"profile_image_url"] stringByReplacingOccurrencesOfString:@"normal" withString:@"bigger"];
                                     
                            NSString *text = [item objectForKey:@"text"];
                            tweet = [text stringByReplacingOccurrencesOfString:[NSString stringWithFormat:@"#%@", HASHTAG]
                                          withString:@""
                                          options:NSCaseInsensitiveSearch
                                          range:NSMakeRange(0, [text length])];
                            
                            unsigned int picLocation = [tweet rangeOfString:@"poll="].location;
                            if ([userName isEqualToString:producer] && picLocation != NSNotFound)
                            {
                                /* need to try these options:
                                 //chart.googleapis.com/chart
                                 ?chf=a,s,000000F0
                                 &chs=650x437
                                 &cht=p3
                                 &chd=t:3,4,5
                                 &chdl=option+1|option+2|option+3
                                 &chdlp=b
                                 &chma=0,5,50|55,50
                                 &chtt=title
                                 &chts=000000,24
                                 */
                                NSArray *pollData = [tweet componentsSeparatedByString:@"$"];
                                pollResults = [NSString stringWithFormat:@"http://chart.googleapis.com/chart?chf=a,s,000000F0&chs=600x450&cht=p3&chd=t:%@&chts=a&chdl=%@&&chdlp=b&chma=%%7C55,50&chtt=Poll+Results+-+%@", pollData[1], pollData[2], pollData[3]];
                            }
                            
                            
                                     
                            tweet = [displayName stringByAppendingString: [NSString stringWithFormat:@"\r%@", tweet]];
                            
                            dispatch_async(dispatch_get_main_queue(), ^
                            {
                                NSBubbleData *sayBubble;
                                if ([userName isEqualToString:[twitterAccount username]])
                                {
                                    sayBubble = [NSBubbleData dataWithText:tweet date:tweetTime type: BubbleTypeMine];
                                }
                                else
                                {
                                    if (picLocation == NSNotFound)
                                    {
                                        sayBubble = [NSBubbleData dataWithText:tweet date:tweetTime type: BubbleTypeSomeoneElse];
                                    }
                                    else
                                    {
                                        sayBubble = [NSBubbleData dataWithImage:[UIImage imageWithData:[NSData dataWithContentsOfURL:[NSURL URLWithString:pollResults]]]
                                                                  date:tweetTime
                                                                  type:BubbleTypeSomeoneElse];
                                    }
                                }
                                sayBubble.avatar = [UIImage imageWithData:[NSData dataWithContentsOfURL:[NSURL URLWithString:profilePic]]];
                                [currentRefresh addObject:sayBubble];
                            });
                        }
                                 
                        dispatch_async(dispatch_get_main_queue(), ^
                        {
                            [currentRefresh addObjectsFromArray:bubbleData];
                            bubbleData = currentRefresh;
                            [bubbleTable reloadData];
                        });
                    }
                    else
                    {
                        NSLog(@"JSON Error: %@", [jsonError localizedDescription]);
                    }
                }
                else
                {
                    // The server did not respond successfully... were we rate-limited?
                    NSLog(@"The response status code is %d", urlResponse.statusCode);
                }
            }
            
            // Response or not, stop the indicator
            dispatch_async(dispatch_get_main_queue(), ^
            {
                [activityIndicator stopAnimating];
            });
        }];
    }
}

-(NSString*)convertTweetTime:(NSString*)created_at
{

    // Convert received date to NSDate object
    static NSDateFormatter* df = nil;
    
    df = [[NSDateFormatter alloc] init];
    [df setTimeStyle:NSDateFormatterFullStyle];
    [df setFormatterBehavior:NSDateFormatterBehavior10_4];
    [df setDateFormat:@"EEE, d LLL yyyy HH:mm:ss Z"];
    
    NSDate* convertedDate = [df dateFromString:created_at];
    
    // Find out what time it is right now
    NSDate *now = [NSDate date];
    
    // See how long has it been since the tweet was created
    NSTimeInterval secondsElapsed = [now timeIntervalSinceDate:convertedDate];
    
    if(secondsElapsed < 60)
    {
        return [NSString stringWithFormat:@"1 min ago"];
    }
    else if(secondsElapsed < 3600)
    {
        return [NSString stringWithFormat:@"%.0f mins ago", ceil(secondsElapsed/60)];
    }
    else if (secondsElapsed < 86400)
    {
        return [NSString stringWithFormat:@"%.0f hours ago", ceil(secondsElapsed/3600)];
    }
    
    return @"1 day ago";
}

-(BOOL)shouldAutorotate
{
    return YES;
}

- (NSUInteger)supportedInterfaceOrientations
{
    // Support landscape orientations only
    return UIInterfaceOrientationMaskAll;
}

-(IBAction) handleTapGesture:(UIGestureRecognizer *) sender {
    NSLog(@"tap detected");
}

@end
