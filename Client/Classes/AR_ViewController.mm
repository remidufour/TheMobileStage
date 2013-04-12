//
//  AR_ViewController.mm
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

// Needed for cuts fading
#include <mach/mach_time.h>

#import <QuartzCore/QuartzCore.h>

#import "AR_ViewController.h"
#import "EAGLView.h"
#import "InputController.h"

// Fade-in and fade-out period, in milliseconds
#define FADE_IN_PERIOD  500
#define FADE_OUT_PERIOD 500

// Cut array indices
#define TRIGGER_INDEX 0
#define START_INDEX   1
#define DELAY_INDEX   2

// Uniform index.
enum
{
    UNIFORM_MVP,
    UNIFORM_COLOR,
    NUM_UNIFORMS
};

GLint uniforms[NUM_UNIFORMS];

// Attribute index.
enum
{
    ATTRIB_VERTEX,
    ATTRIB_NORMAL,
    NUM_ATTRIBUTES
};

@interface AR_ViewController ()
- (BOOL)loadShaders;
- (BOOL)compileShader:(GLuint *)shader type:(GLenum)type file:(NSString *)file;
- (BOOL)linkProgram:(GLuint)prog;
- (BOOL)validateProgram:(GLuint)prog;
@end

@implementation AR_ViewController

static const float cubeScale = 0.75f;

static VideoPlayer *gPlayer;

/* Media path */
NSString *gMedia = @"monty.mov";

/* Media blend */
float gBlend = 0.5f;

// Input Controller
static InputController *input = NULL;

@synthesize animating;

// Creates a standard projection matrix much like glFrustum
+ (void)createProjectionMatrix: (float *)matrix verticalFOV: (float)verticalFOV aspectRatio: (float)aspectRatio nearClip: (float)nearClip farClip: (float)farClip
{
	memset(matrix, 0, sizeof(*matrix) * 16);
	
	float tan = tanf(verticalFOV * M_PI / 360.f);
	
	matrix[0] = 1.f / (tan * aspectRatio);
	matrix[5] = 1.f / tan;
	matrix[10] = (farClip + nearClip) / (nearClip - farClip);
	matrix[11] = -1.f;
	matrix[14] = (2.f * farClip * nearClip) / (nearClip - farClip);
}

- (GLuint)setupTexture:(NSString *)fileName
{    
    // Load the image
    CGImageRef spriteImage = [UIImage imageNamed:fileName].CGImage;
    if (!spriteImage)
    {
        NSLog(@"Failed to load image %@", fileName);
        exit(1);
    }
    
    // Allocate memory to save the image
    size_t width = CGImageGetWidth(spriteImage);
    size_t height = CGImageGetHeight(spriteImage);
    
    GLubyte * spriteData = (GLubyte *)calloc(width * height * 4, sizeof(GLubyte));
    
    CGContextRef spriteContext = CGBitmapContextCreate(spriteData,
                                                       width,
                                                       height,
                                                       8,
                                                       width * 4,
                                                       CGImageGetColorSpace(spriteImage),
                                                       kCGImageAlphaPremultipliedLast);
    
    // Save the image and release it
    CGContextDrawImage(spriteContext, CGRectMake(0, 0, width, height), spriteImage);
    
    CGContextRelease(spriteContext);
    
    // Bind the image data to a texture
    GLuint texName;
    glGenTextures(1, &texName);
    glBindTexture(GL_TEXTURE_2D, texName);
    
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_NEAREST);
    
    glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, width, height, 0, GL_RGBA, GL_UNSIGNED_BYTE, spriteData);
    
    free(spriteData);
    
    return texName;
}

typedef struct
{
    float Position[3];
    float Normal[3];
    float TexCoord[2];
} Vertex;

#define TEX_COORD_MAX 1.0f
static const float aspect = 4.0f / 3.0f;

const Vertex Vertices[] =
{
    // Front
    {{cubeScale * aspect, 0,-cubeScale}, {1, 0, 0}, {TEX_COORD_MAX, 0}},
    {{cubeScale * aspect, 0, cubeScale}, {0, 1, 0}, {TEX_COORD_MAX, TEX_COORD_MAX}},
    {{-cubeScale * aspect, 0, cubeScale}, {0, 0, 1}, {0, TEX_COORD_MAX}},
    {{-cubeScale * aspect, 0,-cubeScale}, {0, 0, 0}, {0, 0}}
};

const GLubyte Indices[] =
{
    // Front
    0, 1, 2,
    2, 3, 0,
};

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    // Load the XML only once from here
    if (input == NULL)
    {
        // Retrieve the Input Controller
        input = [InputController sharedInstance];
    }

    // Load the video player
    player = new VideoPlayer;

    EAGLContext *aContext = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES2];
    
    if (aContext == NULL)
    {
        NSLog(@"Failed to create ES context");
        return;
    }

    if (![EAGLContext setCurrentContext:aContext])
    {
        NSLog(@"Failed to set ES context current");
        return;
    }
    
	context = aContext;
	
    // Define the AR view
    EAGLView *eaglView = [[EAGLView alloc] initWithFrame:self.view.frame];
    
    glViewOverlay = (EAGLView *)self.view;
    self.view = eaglView;

    [eaglView setContext:context];
    [eaglView setFramebuffer];
    
    if ([context API] == kEAGLRenderingAPIOpenGLES2)
        [self loadShaders];
    
    animating = NO;
    
    // Create square
    GLuint vertexBuffer, indexBuffer;

    glGenBuffers(1, &vertexBuffer);
    glBindBuffer(GL_ARRAY_BUFFER, vertexBuffer);
    glBufferData(GL_ARRAY_BUFFER, sizeof(Vertices), Vertices, GL_STATIC_DRAW);
    
    glGenBuffers(1, &indexBuffer);
    glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, indexBuffer);
    glBufferData(GL_ELEMENT_ARRAY_BUFFER, sizeof(Indices), Indices, GL_STATIC_DRAW);

	// Set up viewport in landscape mode and projection matrix
	int viewport[4] = {0, 0, eaglView.framebufferWidth, eaglView.framebufferHeight};
	glViewport(viewport[0], viewport[1], viewport[2], viewport[3]);

    float newFOV = 180.0 * atan(tan(M_PI * [StringOGL getDeviceVerticalFOV] / (180.0 *2.0)) * 4.0 / 3.0) * 2.0 / M_PI;
    [AR_ViewController createProjectionMatrix:projectionMatrix
                                  verticalFOV:newFOV
                                  aspectRatio:(float)eaglView.framebufferWidth / (float)eaglView.framebufferHeight
                                     nearClip:0.1f
                                      farClip:100.f];
	
	// Initialize String
    stringOGL = [[StringOGL alloc] initWithDelegate:self
                                            context:aContext
                                        frameBuffer:[eaglView defaultFramebuffer]
                                         leftHanded:NO];
    
    // Set projection matrix
    [stringOGL setProjectionMatrix:projectionMatrix
                          viewport:viewport
                       orientation:[self interfaceOrientation]
              reorientIPhoneSplash:YES];
	
	[stringOGL pause];
	
	// Load image markers
	[stringOGL loadImageMarker: @"Ghost Marker" ofType: @"png"];

#ifdef DEBUG
    [blendSlider setValue:gBlend];
    [blendDebugLabel setHidden:FALSE];
    [debugLabel setHidden:FALSE];
    [blendSlider setHidden:FALSE];
#endif
}

-(void)timerCutStart:(NSTimer *)theTimer
{
    // Issue the fade-in state
    start = mach_absolute_time();
    state = FADE_IN;
    
    // Start the fade-out timer
    NSArray *cut = cuts[current];

    // Start the fade-out timer
    currentTimer = [NSTimer scheduledTimerWithTimeInterval:[cut[DELAY_INDEX] integerValue]
                                                    target:self
                                                  selector:@selector(timerCutStop:)
                                                  userInfo:nil
                                                   repeats:NO];
}

-(void)timerCutStop:(NSTimer *)theTimer
{
    // Issue the fade-in state
    start = mach_absolute_time();
    state = FADE_OUT;
    
    // Next cut
    ++current;

    // Cuts are done
    if (current >= cuts.count)
        return;
    
    NSArray *cut = cuts[current];
    
    // Next cut is manual
    if ([cut[TRIGGER_INDEX] isEqualToString:@"MANUAL"])
        return;
    
    // Fade-in
    if ([cut[START_INDEX] integerValue])
    {
        // Launch fade-in timer
        currentTimer = [NSTimer scheduledTimerWithTimeInterval:[cut[START_INDEX] integerValue]
                                                        target:self
                                                      selector:@selector(timerCutStart:)
                                                      userInfo:nil
                                                       repeats:NO];
        
        return;
    }
    
    // Issue the fade-in state
    start = mach_absolute_time();
    state = FADE_IN;
    
    // Start the fade-out timer
    currentTimer = [NSTimer scheduledTimerWithTimeInterval:[cut[DELAY_INDEX] integerValue]
                                                    target:self
                                                  selector:@selector(timerCutStop:)
                                                  userInfo:nil
                                                   repeats:NO];
}

- (void)viewDidAppear:(BOOL)animated
{
    // Initialize the video player
    if (player->Initialize(gMedia, context) == true)
        gPlayer = player;
    
    // Debug only - initialize a basic texture
    //_ghostTexture = [self setupTexture:@"ghost.png"];
    //NSLog(@"textures %d %d", _ghostTexture, _textureUniform);
    
    // Cuts are optional
    if (cuts == NULL || cuts.count == 0)
        return;
    
    // Start the first cut if automatic
    NSArray *cut = cuts[0];
    if ([cut[TRIGGER_INDEX] isEqualToString:@"AUTOMATIC"])
    {
        NSLog(@"First cut is automatic");
        
        // Fade-in
        if ([cut[START_INDEX] integerValue])
        {
            // Launch fade-in timer
            currentTimer = [NSTimer scheduledTimerWithTimeInterval:[cut[START_INDEX] integerValue]
                                                            target:self
                                                          selector:@selector(timerCutStart:)
                                                          userInfo:nil
                                                           repeats:NO];
            return;
        }
        
        // Issue the fade-in state
        start = mach_absolute_time();
        state = FADE_IN;
        
        // Start the fade-out timer
        currentTimer = [NSTimer scheduledTimerWithTimeInterval:[cut[START_INDEX] integerValue]
                                                        target:self
                                                      selector:@selector(timerCutStop:)
                                                      userInfo:nil
                                                       repeats:NO];
    }
}

- (void)viewWillAppear:(BOOL)animated
{
    [self startAnimation];
    
    [super viewWillAppear:animated];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [self stopAnimation];
    
    [super viewWillDisappear:animated];
}

- (void)viewDidUnload
{
	[super viewDidUnload];
	
    if (program)
    {
        glDeleteProgram(program);
        program = 0;
    }
    
    // Tear down context.
    if ([EAGLContext currentContext] == context)
        [EAGLContext setCurrentContext:nil];
    
	context = nil;
}

- (void)startAnimation
{
    if (!animating)
    {
        [stringOGL resume];
        
        animating = TRUE;
    }
}

- (void)stopAnimation
{
    if (animating)
    {
        [stringOGL pause];
        
        animating = FALSE;
    }
}

+ (void)multiplyMatrix: (const float *)ma withMatrix: (const float *)mb into: (float *)dest
{
	float temp[16] = {
		ma[0]*mb[0] + ma[1]*mb[4] + ma[2]*mb[8] + ma[3]*mb[12],
		ma[0]*mb[1] + ma[1]*mb[5] + ma[2]*mb[9] + ma[3]*mb[13],
		ma[0]*mb[2] + ma[1]*mb[6] + ma[2]*mb[10] + ma[3]*mb[14],
		ma[0]*mb[3] + ma[1]*mb[7] + ma[2]*mb[11] + ma[3]*mb[15],
		
		ma[4]*mb[0] + ma[5]*mb[4] + ma[6]*mb[8] + ma[7]*mb[12],
		ma[4]*mb[1] + ma[5]*mb[5] + ma[6]*mb[9] + ma[7]*mb[13],
		ma[4]*mb[2] + ma[5]*mb[6] + ma[6]*mb[10] + ma[7]*mb[14],
		ma[4]*mb[3] + ma[5]*mb[7] + ma[6]*mb[11] + ma[7]*mb[15],
		
		ma[8]*mb[0] + ma[9]*mb[4] + ma[10]*mb[8] + ma[11]*mb[12],
		ma[8]*mb[1] + ma[9]*mb[5] + ma[10]*mb[9] + ma[11]*mb[13],
		ma[8]*mb[2] + ma[9]*mb[6] + ma[10]*mb[10] + ma[11]*mb[14],
		ma[8]*mb[3] + ma[9]*mb[7] + ma[10]*mb[11] + ma[11]*mb[15],
		
		ma[12]*mb[0] + ma[13]*mb[4] + ma[14]*mb[8] + ma[15]*mb[12],
		ma[12]*mb[1] + ma[13]*mb[5] + ma[14]*mb[9] + ma[15]*mb[13],
		ma[12]*mb[2] + ma[13]*mb[6] + ma[14]*mb[10] + ma[15]*mb[14],
		ma[12]*mb[3] + ma[13]*mb[7] + ma[14]*mb[11] + ma[15]*mb[15]};
    
	for (int i = 0; i < 16; i++) dest[i] = temp[i];
}

- (void)render
{
    [(EAGLView *)self.view setFramebuffer];
    
    // Enable blending
    glBlendFunc(GL_ONE_MINUS_SRC_ALPHA, GL_SRC_ALPHA);
    glEnable(GL_BLEND);

	glDisable(GL_CULL_FACE);
	glEnable(GL_DEPTH_TEST);

	struct MarkerInfoMatrixBased markerInfo[10];
	
	int markerCount = [stringOGL getMarkerInfoMatrixBased: markerInfo maxMarkerCount:10];

    // Return if we have no markers
    if (markerCount == 0)
        return;

    if ([context API] != kEAGLRenderingAPIOpenGLES2)
    {
        NSLog(@"Only GLES2 is supported");
        return;
    }

    glUseProgram(program);
    
    // Set the cuts fade
    float blend = [blendSlider value];
    mach_timebase_info_data_t info;
    uint64_t duration;
    switch (state)
    {
        case HIDDEN:
            // Setting this to one will effectivelly hide it
            blend = 0.0f;
            break;
        case FADE_IN:
            duration = mach_absolute_time() - start;
            
            // Convert to nanoseconds
            mach_timebase_info(&info);
            duration *= info.numer;
            duration /= info.denom;
            
            // Convert to msecs
            duration /= 1000000;
    
            if (duration < FADE_IN_PERIOD)
                cut_blend = duration / (float)FADE_IN_PERIOD;
            else
            {
                cut_blend = 1.0;
                state = SHOWN;
                NSLog(@"Fade-in completed");
            }
            blend *= cut_blend;
            break;
        case SHOWN:
            // No changes needed here
            break;
        case FADE_OUT:
            duration = mach_absolute_time() - start;
            mach_timebase_info(&info);
            duration *= info.numer;
            duration /= info.denom;
            
            // Convert to msecs
            duration /= 1000000;
            
            if (duration < FADE_OUT_PERIOD)
                cut_blend = 1.0 - duration / (float)FADE_OUT_PERIOD;
            else
            {
                cut_blend = 0.0;
                state = HIDDEN;
                NSLog(@"Fade-out completed");
            }
            blend *= cut_blend;
            break;
        default:
            break;
    }

    // Set the diffuse color to white
    float diffuse[4] = {1.0, 1.0, 1.0, 1.0 - blend};
    glUniform4fv(uniforms[UNIFORM_COLOR], 1, diffuse);
    
    // Set the world projection
    const float translationMatrix[16] = {1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1, 0, 0, 0, -cubeScale, 1};
    float modelViewMatrix[16];
    float modelViewProjectionMatrix[16];
    
    [AR_ViewController multiplyMatrix: translationMatrix withMatrix: markerInfo[0].transform into: modelViewMatrix];
    [AR_ViewController multiplyMatrix: modelViewMatrix withMatrix: projectionMatrix into: modelViewProjectionMatrix];
    
    glUniformMatrix4fv(uniforms[UNIFORM_MVP], 1, GL_FALSE, modelViewProjectionMatrix);
    
    // Positions
    glVertexAttribPointer(_positionSlot, 3, GL_FLOAT, GL_FALSE, sizeof(Vertex), 0);
    
    // Normals
    glVertexAttribPointer(_normalSlot, 3, GL_FLOAT, GL_FALSE, sizeof(Vertex), (GLvoid*) (sizeof(float) * 3));
    
    // Sets the video texture
    glVertexAttribPointer(_texCoordSlot, 2, GL_FLOAT, GL_FALSE, sizeof(Vertex), (GLvoid*) (sizeof(float) * 6));
    glActiveTexture(GL_TEXTURE0);
    
    // Renders the video texture
    player->Render();
    
    // Disabled: A ghost texture image
    //glBindTexture(GL_TEXTURE_2D, _ghostTexture);
    
    glUniform1i(_textureUniform, 0);
    
    glDrawElements(GL_TRIANGLES, 6, GL_UNSIGNED_BYTE, NULL);
}

- (void)didReceiveMemoryWarning
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc. that aren't in use.
}

- (BOOL)compileShader:(GLuint *)shader type:(GLenum)type file:(NSString *)file
{
    GLint status;
    const GLchar *source;
    
    source = (GLchar *)[[NSString stringWithContentsOfFile:file encoding:NSUTF8StringEncoding error:nil] UTF8String];
    if (!source)
    {
        NSLog(@"Failed to load vertex shader");
        return FALSE;
    }
    
    *shader = glCreateShader(type);
    glShaderSource(*shader, 1, &source, NULL);
    glCompileShader(*shader);
    
    glGetShaderiv(*shader, GL_COMPILE_STATUS, &status);
    if (status == 0)
    {
        glDeleteShader(*shader);
        return FALSE;
    }

    return TRUE;
}

- (BOOL)linkProgram:(GLuint)prog
{
    GLint status;
    
    glLinkProgram(prog);
    
    glGetProgramiv(prog, GL_LINK_STATUS, &status);
    if (status == 0)
        return FALSE;
    
    return TRUE;
}

- (BOOL)validateProgram:(GLuint)prog
{
    GLint logLength, status;
    
    glValidateProgram(prog);
    glGetProgramiv(prog, GL_INFO_LOG_LENGTH, &logLength);
    if (logLength > 0)
    {
        GLchar *log = (GLchar *)malloc(logLength);
        glGetProgramInfoLog(prog, logLength, &logLength, log);
        NSLog(@"Program validate log:\n%s", log);
        free(log);
    }
    
    glGetProgramiv(prog, GL_VALIDATE_STATUS, &status);
    if (status == 0)
        return FALSE;
    
    return TRUE;
}

- (BOOL)loadShaders
{
    GLuint vertShader, fragShader;
    NSString *vertShaderPathname, *fragShaderPathname;
    
    // Create shader program.
    program = glCreateProgram();
    
    // Create and compile vertex shader.
    vertShaderPathname = [[NSBundle mainBundle] pathForResource:@"Shader" ofType:@"vsh"];
    if (![self compileShader:&vertShader type:GL_VERTEX_SHADER file:vertShaderPathname])
    {
        NSLog(@"Failed to compile vertex shader");
        return FALSE;
    }
    
    // Create and compile fragment shader.
    fragShaderPathname = [[NSBundle mainBundle] pathForResource:@"Shader" ofType:@"fsh"];
    if (![self compileShader:&fragShader type:GL_FRAGMENT_SHADER file:fragShaderPathname])
    {
        NSLog(@"Failed to compile fragment shader");
        return FALSE;
    }
    
    // Attach vertex shader to program.
    glAttachShader(program, vertShader);
    
    // Attach fragment shader to program.
    glAttachShader(program, fragShader);
    
    // Bind attribute locations.
    // This needs to be done prior to linking.
    glBindAttribLocation(program, ATTRIB_VERTEX, "position");
    glBindAttribLocation(program, ATTRIB_NORMAL, "normal");
    
    // Link program.
    if (![self linkProgram:program])
    {
        NSLog(@"Failed to link program: %d", program);
        
        if (vertShader)
        {
            glDeleteShader(vertShader);
            vertShader = 0;
        }
        if (fragShader)
        {
            glDeleteShader(fragShader);
            fragShader = 0;
        }
        if (program)
        {
            glDeleteProgram(program);
            program = 0;
        }
        
        return FALSE;
    }
    
    // Get uniform locations.
    uniforms[UNIFORM_MVP] = glGetUniformLocation(program, "mvp");
	uniforms[UNIFORM_COLOR] = glGetUniformLocation(program, "color");
    
    // 4
    glUseProgram(program);
    
    // Position and color information
    _positionSlot = glGetAttribLocation(program, "position");
    _normalSlot = glGetAttribLocation(program, "normal");
    glEnableVertexAttribArray(_positionSlot);
    glEnableVertexAttribArray(_normalSlot);

    // Texture information
    _texCoordSlot = glGetAttribLocation(program, "TexCoordIn");
    glEnableVertexAttribArray(_texCoordSlot);

    _textureUniform = glGetUniformLocation(program, "Texture");

    glEnableVertexAttribArray(0);
    glEnableVertexAttribArray(1);

    // Release vertex and fragment shaders.
    if (vertShader)
        glDeleteShader(vertShader);
    if (fragShader)
        glDeleteShader(fragShader);
    
    return TRUE;
}

- (IBAction)pressedDebug:(id)sender
{
    // Temporarly dismiss view
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)splashScreenFinished
{
    [self.view insertSubview:glViewOverlay aboveSubview:self.view];
    [self.view updateConstraints];
    [self.view setNeedsDisplay];
    
    NSLog(@"Splash screen finished");
}

- (void)setMedia: (NSString *)media withblend:(float)blend withcuts:(NSArray *)aCuts
{
    if (media != nil)
    {
        NSLog(@"Media is set to %@", media);
        gMedia = media;
    }
    
    // Set desired blending
    gBlend = blend;
    NSLog(@"Blend set to %f", blend);
    
    current = 0;
    currentTimer = NULL;
    
    // Set the cuts
    if (aCuts && aCuts.count)
    {
        cuts = aCuts;
        state = HIDDEN;
        cut_blend = 0.0f;
        
        NSLog(@"Augmented Reality - Cuts are %@", cuts);
        
        return;
    }

    cuts = NULL;
    state = SHOWN;
    cut_blend = 1.0f;
    
    NSLog(@"Augmented Reality - No cuts");
}

-(BOOL)shouldAutorotate
{
    return YES;
}

- (NSUInteger)supportedInterfaceOrientations
{
    // Support portrait orientation only
    return UIInterfaceOrientationMaskPortrait;
}

- (void)trigger
{
    if (cuts == NULL || cuts.count == 0)
    {
        NSLog(@"Error - Augmented Reality doesn't have cuts.");
        return;
    }
    
    // Cuts are done
    if (current >= cuts.count)
    {
        NSLog(@"Error - Augmented Reality cuts are done.");
        return;
    }
    
    NSArray *cut = cuts[current];
    
    // Next cut is automatic
    if ([cut[TRIGGER_INDEX] isEqualToString:@"AUTOMATIC"])
    {
        NSLog(@"Error - Trying to trigger an automatic cut.");
        return;
    }
    
    // Fade-in
    if ([cut[START_INDEX] integerValue])
    {
        // Launch fade-in timer
        currentTimer = [NSTimer scheduledTimerWithTimeInterval:[cut[START_INDEX] integerValue]
                                                        target:self
                                                      selector:@selector(timerCutStart:)
                                                      userInfo:nil
                                                       repeats:NO];
        return;
    }

    // Issue the fade-in state
    start = mach_absolute_time();
    state = FADE_IN;
        
    // Start the fade-out timer
    currentTimer = [NSTimer scheduledTimerWithTimeInterval:[cut[DELAY_INDEX] integerValue]
                                                    target:self
                                                    selector:@selector(timerCutStop:)
                                                    userInfo:nil
                                                    repeats:NO];
}

@end
