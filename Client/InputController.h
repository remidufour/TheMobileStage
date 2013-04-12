//
//  InputController.h
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

// Major error notification tag
#define EXIT_ALERT_TAG 2

// Character Array Indexes
#define INDEX_CHARACTER_NAME    0
#define INDEX_CHARACTER_PICTURE 1

// Event types
typedef enum
{
    // Select a character event
    EVENT_SELECT_CHARACTER = 0,
    
    // Polling event
    EVENT_POLL,

    // Augmented Reality event
    EVENT_AR,
    
    // Number of events
    NUMBER_EVENT_TYPES

} EVENT_TYPES;

// Trigger types
typedef enum
{
    // Automatic trigger
    EVENT_TRIGGER_AUTOMATIC = 0,
    
    // Manual trigger
    EVENT_TRIGGER_MANUAL

} EVENT_TRIGGER_TYPES;

// Event array indices
#define EVENT_TYPE_INDEX          0
#define EVENT_START_TRIGGER_INDEX 1
#define EVENT_END_TRIGGER_INDEX   2
#define EVENT_START_INDEX         3
#define EVENT_DELAY_INDEX         4

// Polling-specific indices
#define EVENT_POLL_STRING_INDEX  5
#define EVENT_POLL_ANSWERS_INDEX 6

// Augmented Reality-specific indices
#define EVENT_AR_MEDIA_INDEX 5
#define EVENT_AR_BLEND       6
#define EVENT_AR_CUTS        7

@interface InputController : NSObject

// Get an Input Controller instance
+ (InputController *)sharedInstance;

// Load a local XML
- (bool)loadXML: (NSString *)path;

// Get Play Title
- (NSString *)getTitle;

// Get Play Credits URL
- (NSString *)getURL;

// Get the Characters
- (NSArray *)getCharacters;

// Get the Character Selection Label
- (NSString *)getCharacterSelectionLabel;

// Get the Theatrical Play
- (NSArray *)getPlay;

@end
