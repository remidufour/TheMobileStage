//
//  NSBubbleData.h
//
//  Created by Alex Barinov
//  Project home page: http://alexbarinov.github.com/UIBubbleTableView/
//
//  This work is licensed under the Creative Commons Attribution-ShareAlike 3.0 Unported License.
//  To view a copy of this license, visit http://creativecommons.org/licenses/by-sa/3.0/
//

#import <Foundation/Foundation.h>

typedef enum _NSBubbleType
{
    BubbleTypeMine = 0,
    BubbleTypeSomeoneElse = 1
} NSBubbleType;

@interface NSBubbleData : NSObject

@property (readonly, nonatomic, strong) NSString *date;
@property (readonly, nonatomic) NSBubbleType type;
@property (readonly, nonatomic, strong) UIView *view;
@property (readonly, nonatomic) UIEdgeInsets insets;
@property (nonatomic, strong) UIImage *avatar;

- (id)initWithText:(NSString *)text date:(NSString *)date type:(NSBubbleType)type;
+ (id)dataWithText:(NSString *)text date:(NSString *)date type:(NSBubbleType)type;
- (id)initWithImage:(UIImage *)image date:(NSString *)date type:(NSBubbleType)type;
+ (id)dataWithImage:(UIImage *)image date:(NSString *)date type:(NSBubbleType)type;
- (id)initWithView:(UIView *)view date:(NSString *)date type:(NSBubbleType)type insets:(UIEdgeInsets)insets;
+ (id)dataWithView:(UIView *)view date:(NSString *)date type:(NSBubbleType)type insets:(UIEdgeInsets)insets;

@end
