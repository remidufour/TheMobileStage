//
//  AR_ViewController.h
//  The Mobile Stage
//
//  Created by Remi Dufour on 2013-02-20.
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
#import <GLKit/GLKit.h>

#import <OpenGLES/EAGL.h>

#import <OpenGLES/ES2/gl.h>
#import <OpenGLES/ES2/glext.h>

#import "StringOGL.h"
#import "VideoPlayer.h"

// Cuts state
enum CUT_STATE
{
    HIDDEN = 0,
    FADE_IN,
    SHOWN,
    FADE_OUT,
};

@class StringOGL;

@interface AR_ViewController : GLKViewController <StringOGLDelegate>
{
    // GL context
    EAGLContext *context;

    GLuint program;
    
    BOOL animating;
	
	StringOGL *stringOGL;
	
    // Projection matrix
	float projectionMatrix[16];
    
    // Video player
    VideoPlayer *player;
    
    // The OpenGL names for the framebuffer and renderbuffer used to render to this view
	GLuint defaultFramebuffer, colorRenderbuffer;
    
    // The pixel dimensions of the CAEAGLLayer
	GLint backingWidth;
	GLint backingHeight;

    // Shader slots
    GLuint _positionSlot;
    GLuint _normalSlot;
    GLuint _texCoordSlot;

    // Textures
    //GLuint _ghostTexture;
    GLuint _textureUniform;
    
    // GL View Overlay
    GLKView *glViewOverlay;
    
    // Debug items
    IBOutlet UIButton *debugLabel;
    IBOutlet UISlider *blendSlider;
    IBOutlet UILabel *blendDebugLabel;
    
    // Cuts
    NSArray *cuts;
    unsigned int current;
    NSTimer *currentTimer;
    CUT_STATE state;
    uint64_t start;
    
    /* Cuts Fade-in / Fade-out blend */
    float cut_blend;
}

@property (readonly, nonatomic, getter=isAnimating) BOOL animating;

- (void)startAnimation;
- (void)stopAnimation;

// Set the AR media. Needs to be called before loading.
- (void)setMedia: (NSString *)media withblend:(float)blend withcuts:(NSArray *)aCuts;

// Trigger a cut
- (void)trigger;

@end
