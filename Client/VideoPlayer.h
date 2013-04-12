//
//  VideoPlayer.h
//  The Mobile Stage
//
//  Created by Remi Dufour on 2013-03-17.
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

#ifndef __The_Mobile_Stage__VideoPlayer__
#define __The_Mobile_Stage__VideoPlayer__

#include "Foundation/Foundation.h"
#include "AVFoundation/AVFoundation.h"

class VideoPlayer
{
public:
    // Constructor
    VideoPlayer(void);

    // Initialize
    bool Initialize(NSString *videoPath, EAGLContext *context);

    // Render
    // Note: Initialization must be performed and successful
    void Render(void);

private:
    // Video player
    AVPlayer *videoPlayer;
    
    // Video player layer
    AVPlayerLayer *videoLayer;
    
    // Video reader
    AVAssetReader *videoReader;
    
    // Video output
    AVAssetReaderTrackOutput *videoOutput;
    
    // Video texture
    CVOpenGLESTextureCacheRef videoTextureCache;
    
    GLuint frameBufferHandle;
    
    NSDictionary *settings;
};

#endif /* defined(__The_Mobile_Stage__VideoPlayer__) */
