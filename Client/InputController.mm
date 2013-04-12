//
//  InputController.mm
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

#import <Foundation/Foundation.h>

#import "InputController.h"

#include "XMLHelper.h"

#define PLAY_NAME       "PLAY"
#define TITLE_NAME      "TITLE"
#define URL_NAME        "URL"
#define CHARACTERS_NAME "CHARACTERS"
#define SELECTION_NAME  "SELECTION"
#define CHARACTER_NAME  "CHARACTER"
#define NAME_NAME       "NAME"
#define NAME_PICTURE    "PICTURE"

// Event XML tags
#define EVENTS_NAME                "EVENTS"
#define EVENT_NAME                 "EVENT"
#define TYPE_NAME                  "TYPE"
#define START_TRIGGER_NAME         "START_TRIGGER"
#define END_TRIGGER_NAME           "END_TRIGGER"
#define AUTOMATIC_NAME             "AUTOMATIC"
#define MANUAL_NAME                "MANUAL"
#define SELECT_CHARACTER_TYPE_NAME "SELECT_CHARACTER"
#define POLL_TYPE_NAME             "POLL"
#define START_NAME                 "START"
#define TIME_NAME                  "TIME"
#define DELAY_NAME                 "DELAY"
#define AR_TYPE_NAME               "AR"
#define QUESTION_NAME              "QUESTION"
#define ANSWERS_NAME               "ANSWERS"
#define ANSWER_NAME                "ANSWER"
#define MEDIA_NAME                 "MEDIA"
#define BLEND_NAME                 "BLEND"
#define CUTS_NAME                  "CUTS"
#define CUT_NAME                   "CUT"
#define TRIGGER_NAME               "TRIGGER"
#define START_NAME                 "START"
#define DELAY_NAME                 "DELAY"

@implementation InputController

static InputController *sharedInstance;

// XML Helper
XMLHelper helper;

// Play root Element
Element playElement = NULL;

// Get the shared instance and create it if necessary.
+ (InputController *)sharedInstance
{
    if (sharedInstance == nil)
    {
        sharedInstance = [[super allocWithZone:NULL] init];
    }
    
    return sharedInstance;
}

- (bool)loadXML: (NSString *)path
{
    NSString *message;

    NSBundle *mainBundle = [NSBundle mainBundle];
    NSString *myFile = [mainBundle pathForResource:path ofType:@""];

    bool success = helper.Load([myFile UTF8String]);
    if (success == false)
    {
        message = @"Failed to Load Play";
        goto error;
    }
    
    playElement = helper.GetRootElement();
    
    NSLog(@"Loaded %@", path);
    return true;
    
error:
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Error"
                                                    message:message
                                                   delegate:self
                                          cancelButtonTitle:@"Ok"
                                          otherButtonTitles:nil];
    [alert setTag:EXIT_ALERT_TAG];
    [alert show];
    
    return false;
}

-(void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    // If major error notification
    if (alertView.tag == EXIT_ALERT_TAG)
    {
        // Exit programatically
        exit(0);
    }
}

// Retriede the Play Title
- (NSString *)getTitle
{
    if (playElement == NULL)
        return NULL;

    NSString *title = [NSString stringWithFormat:@"%s", helper.GetElement(playElement).GetElement(TITLE_NAME).GetValue()];
    return title;
}

// Retrieve the Play Credits URL
- (NSString *)getURL
{
    if (playElement == NULL)
        return NULL;

    return [NSString stringWithFormat:@"%s", helper.GetElement(playElement).GetElement(URL_NAME).GetValue()];
}

// Get the Characters
- (NSArray *)getCharacters
{
    NSMutableArray *array = [[NSMutableArray alloc] init];
    
    Element characters = helper.GetElement(playElement).GetElement(CHARACTERS_NAME).GetElement(CHARACTER_NAME).GetElementNode();
    
    while (characters != InvalidElement)
    {
        NSString *name = [NSString stringWithFormat:@"%s", helper.GetElement(characters).GetElement(NAME_NAME).GetValue()];
        NSString *imageLocation = [NSString stringWithFormat:@"%s", helper.GetElement(characters).GetElement(NAME_PICTURE).GetValue()];
        NSArray *arrayRow = [[NSArray alloc] initWithObjects:name,imageLocation,nil];
        [array addObject:arrayRow];

        characters = helper.NextElement(characters);
    }
        
    return [NSArray arrayWithArray:array];
}

// Get the Character Selection Label
- (NSString *)getCharacterSelectionLabel
{
    if (playElement == NULL)
        return NULL;
    
    return [NSString stringWithFormat:@"%s", helper.GetElement(playElement).GetElement(CHARACTERS_NAME).GetElement(SELECTION_NAME).GetValue()];
}

// Get the Theatrical Play
- (NSArray *)getPlay
{
    NSMutableArray *array = [[NSMutableArray alloc] init];
    
    Element event = helper.GetElement(playElement).GetElement(EVENTS_NAME).GetElement(EVENT_NAME).GetElementNode();
    
    // Parse through all the events
    while (event != InvalidElement)
    {
        // Check the start trigger type
        NSNumber *start_trigger_type;
        const char *start_trigger_string = helper.GetElement(event).GetString(START_TRIGGER_NAME);
        
        if (start_trigger_string == NULL)
        {
            NSLog(@"Error loading event start trigger type");
            event = helper.NextElement(event);
            continue;
        }

        if (strcmp(start_trigger_string, AUTOMATIC_NAME) == 0)
            start_trigger_type = [[NSNumber alloc] initWithUnsignedInt:EVENT_TRIGGER_AUTOMATIC];
        else if (strcmp(start_trigger_string, MANUAL_NAME) == 0)
            start_trigger_type = [[NSNumber alloc] initWithUnsignedInt:EVENT_TRIGGER_MANUAL];
        else
        {
            NSLog(@"Error loading event start trigger type: %s", start_trigger_string);
            event = helper.NextElement(event);
            continue;
        }
        
        // Check the end trigger type
        NSNumber *end_trigger_type;
        const char *end_trigger_string = helper.GetElement(event).GetString(END_TRIGGER_NAME);
        
        if (end_trigger_string == NULL)
        {
            NSLog(@"Error loading event end trigger type");
            event = helper.NextElement(event);
            continue;
        }
        
        if (strcmp(end_trigger_string, AUTOMATIC_NAME) == 0)
            end_trigger_type = [[NSNumber alloc] initWithUnsignedInt:EVENT_TRIGGER_AUTOMATIC];
        else if (strcmp(end_trigger_string, MANUAL_NAME) == 0)
            end_trigger_type = [[NSNumber alloc] initWithUnsignedInt:EVENT_TRIGGER_MANUAL];
        else
        {
            NSLog(@"Error loading event end trigger type: %s", end_trigger_string);
            event = helper.NextElement(event);
            continue;
        }

        // Check the event type
        const char *type_string = helper.GetElement(event).GetString(TYPE_NAME);
        
        if (type_string == NULL)
        {
            NSLog(@"Error loading event type");
            event = helper.NextElement(event);
            continue;
        }
        
        NSArray *arrayRow = NULL;

        if (strcmp(type_string,SELECT_CHARACTER_TYPE_NAME) == 0)
        {
            // Select Character Event
            NSNumber *type = [[NSNumber alloc] initWithUnsignedInt:EVENT_SELECT_CHARACTER];
            
            // Assign the trigger and event types
            unsigned int value = helper.GetElement(event).GetElement(START_NAME).GetUInt(TIME_NAME);
            NSNumber *start = [[NSNumber alloc] initWithUnsignedInt:value];
            value = helper.GetElement(event).GetElement(DELAY_NAME).GetUInt(TIME_NAME);
            NSNumber *delay = [[NSNumber alloc] initWithUnsignedInt:value];
            arrayRow = [[NSArray alloc] initWithObjects:type,start_trigger_type,end_trigger_type,start,delay,nil];
        }
        else if (strcmp(type_string,POLL_TYPE_NAME) == 0)
        {
            // Polling Event
            NSNumber *type = [[NSNumber alloc] initWithUnsignedInt:EVENT_POLL];
            
            // Assign the trigger and event types
            unsigned int value = helper.GetElement(event).GetElement(START_NAME).GetUInt(TIME_NAME);
            NSNumber *start = [[NSNumber alloc] initWithUnsignedInt:value];
            value = helper.GetElement(event).GetElement(DELAY_NAME).GetUInt(TIME_NAME);
            NSNumber *delay = [[NSNumber alloc] initWithUnsignedInt:value];
            NSString *poll_string = [NSString stringWithFormat:@"%s", helper.GetElement(event).GetElement(QUESTION_NAME).GetValue()];
            Element answer_element = helper.GetElement(event).GetElement(ANSWERS_NAME).GetElement(ANSWER_NAME).GetElementNode();
            NSMutableArray *answers = [[NSMutableArray alloc] init];
            
            while (answer_element != InvalidElement)
            {
                NSString *answer = [NSString stringWithFormat:@"%s", helper.GetElement(answer_element).GetValue()];
                [answers addObject:answer];
                answer_element = helper.NextElement(answer_element);
            }
            
            arrayRow = [[NSArray alloc] initWithObjects:type,start_trigger_type,end_trigger_type,start,delay,poll_string,answers,nil];
        }
        else if (strcmp(type_string,AR_TYPE_NAME) == 0)
        {
            // Augmented Reality Event
            NSNumber *type = [[NSNumber alloc] initWithUnsignedInt:EVENT_AR];
            
            // Assign the trigger and event types
            unsigned int value = helper.GetElement(event).GetElement(START_NAME).GetUInt(TIME_NAME);
            NSNumber *start = [[NSNumber alloc] initWithUnsignedInt:value];
            value = helper.GetElement(event).GetElement(DELAY_NAME).GetUInt(TIME_NAME);
            NSNumber *delay = [[NSNumber alloc] initWithUnsignedInt:value];
            
            NSString *media = [NSString stringWithFormat:@"%s", helper.GetElement(event).GetElement(MEDIA_NAME).GetValue()];
            float blend = helper.GetElement(event).GetElement(MEDIA_NAME).GetFloat(BLEND_NAME);
            NSNumber *blend_object = [[NSNumber alloc] initWithFloat:blend];
            
            // Cuts
            Element cut_element = helper.GetElement(event).GetElement(CUTS_NAME).GetElement(CUT_NAME).GetElementNode();
            NSMutableArray *cuts = [[NSMutableArray alloc] init];
            
            while (cut_element != InvalidElement)
            {
                NSString *cut_trigger = [NSString stringWithFormat:@"%s", helper.GetElement(cut_element).GetString(TRIGGER_NAME)];
                unsigned int start = helper.GetElement(cut_element).GetUInt(START_NAME);
                NSNumber *cut_start = [[NSNumber alloc] initWithUnsignedInt:start];
                unsigned int delay = helper.GetElement(cut_element).GetUInt(DELAY_NAME);
                NSNumber *cut_delay = [[NSNumber alloc] initWithUnsignedInt:delay];
                NSArray *cut = [[NSArray alloc] initWithObjects:cut_trigger,cut_start,cut_delay,nil];
                [cuts addObject:cut];
                
                cut_element = helper.NextElement(cut_element);
            }
            
            arrayRow = [[NSArray alloc] initWithObjects:type,start_trigger_type,end_trigger_type,start,delay,media,blend_object,cuts,nil];
        }
        else
        {
            NSLog(@"Error loading event: %s", type_string);
            event = helper.NextElement(event);
            continue;
        }

        [array addObject:arrayRow];
        
        event = helper.NextElement(event);
    }
    
    return [NSArray arrayWithArray:array];
}

@end
