//
//  NSBubbleData.m
//
//  Created by Alex Barinov
//  Project home page: http://alexbarinov.github.com/UIBubbleTableView/
//
//  This work is licensed under the Creative Commons Attribution-ShareAlike 3.0 Unported License.
//  To view a copy of this license, visit http://creativecommons.org/licenses/by-sa/3.0/
//

#import "NSBubbleData.h"
#import <QuartzCore/QuartzCore.h>

@implementation NSBubbleData

#pragma mark - Properties

@synthesize date = _date;
@synthesize type = _type;
@synthesize view = _view;
@synthesize insets = _insets;
@synthesize avatar = _avatar;


#pragma mark - Text bubble

// updated insets with new "speech bubbles", won't stretch anything inside this box
// top left bottom right
const UIEdgeInsets textInsetsMine = {13, 25, 15, 46};
const UIEdgeInsets textInsetsSomeone = {13, 50, 15, 22};

+ (id)dataWithText:(NSString *)text date:(NSString *)date type:(NSBubbleType)type
{
    return [[NSBubbleData alloc] initWithText:text date:date type:type];
}

- (id)initWithText:(NSString *)text date:(NSString *)date type:(NSBubbleType)type
{
    UIFont *font = [UIFont systemFontOfSize:14];
    //text = [test stringByAppendingString:@"\n 15 min. ago"];
    CGSize size = [(text ? text : @"") sizeWithFont:font constrainedToSize:CGSizeMake(220, 9999) lineBreakMode:NSLineBreakByWordWrapping];
    
   // NSAttributedString *test = [[NSAttributedString alloc] initWithString:@"#TheMobileStage 15 min. ago"];
    
    UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, size.width, size.height)];
    label.numberOfLines = 0;
    label.lineBreakMode = NSLineBreakByWordWrapping;
    label.text = (text ? text : @"");
    label.font = font;
    label.backgroundColor = [UIColor clearColor];
    label.shadowColor = [UIColor lightGrayColor];
    label.textColor = [UIColor whiteColor];

    
    UIEdgeInsets insets = (type == BubbleTypeMine ? textInsetsMine : textInsetsSomeone);
    return [self initWithView:label date:date type:type insets:insets];
}

#pragma mark - Image bubble

// insets: top left bottom right from the view
// CGFloat values
const UIEdgeInsets imageInsetsMine = {11, 13, 16, 22};
const UIEdgeInsets imageInsetsSomeone = {13, 50, 15, 22};

+ (id)dataWithImage:(UIImage *)image date:(NSString *)date type:(NSBubbleType)type
{
    return [[NSBubbleData alloc] initWithImage:image date:date type:type];
}

- (id)initWithImage:(UIImage *)image date:(NSString *)date type:(NSBubbleType)type
{
    CGSize size = image.size;
    if (size.width > 220)
    {
        size.height /= (size.width / 220);
        size.width = 220;
    }
    
    UIImageView *imageView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, size.width, size.height)];
    imageView.image = image;
    imageView.layer.cornerRadius = 5.0;
    imageView.layer.masksToBounds = YES;

    UIEdgeInsets insets = (type == BubbleTypeMine ? imageInsetsMine : imageInsetsSomeone);
    return [self initWithView:imageView date:date type:type insets:insets];       
}

#pragma mark - Custom view bubble

+ (id)dataWithView:(UIView *)view date:(NSString *)date type:(NSBubbleType)type insets:(UIEdgeInsets)insets
{
    return [[NSBubbleData alloc] initWithView:view date:date type:type insets:insets];
}

- (id)initWithView:(UIView *)view date:(NSString *)date type:(NSBubbleType)type insets:(UIEdgeInsets)insets  
{
    self = [super init];
    if (self)
    {
        _view = view;
        _date = date;
        _type = type;
        _insets = insets;
    }
    return self;
}

@end
