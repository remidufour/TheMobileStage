//
//  VideoPlayer.mm
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

#include <iostream>

#include <CoreVideo/CoreVideo.h>

#include "VideoPlayer.h"

using namespace std;

VideoPlayer::VideoPlayer(void) : videoPlayer(NULL), videoLayer(NULL), videoReader(NULL), videoOutput(NULL), videoTextureCache(NULL)
{
    
}

bool VideoPlayer::Initialize(NSString *videoPath, EAGLContext *context)
{
    if (videoPlayer)
    {
        cerr << "Video player already initialized." << endl;
        return true;
    }
    
    NSString* fileName = [[videoPath lastPathComponent] stringByDeletingPathExtension];
    NSString* extension = [videoPath pathExtension];
    NSString *path = [[NSBundle mainBundle] pathForResource:fileName ofType:extension];
    NSURL *urlstring = [[NSURL alloc] initFileURLWithPath: path];

    NSLog(@"Attempting to load - %@", [urlstring filePathURL]);
    
    videoPlayer = [[AVPlayer alloc] initWithURL:urlstring];
    if (videoPlayer == NULL)
    {
        NSLog(@"videoPlayer == nil ERROR LOADING %@\n", [urlstring filePathURL]);
        return false;
    }

    NSLog(@"videoPlayer %@", videoPlayer);

    AVAsset *asset = videoPlayer.currentItem.asset;
    
    if (asset == NULL)
    {
        NSLog(@"Failed to load asset");
        return false;
    }

    NSArray *tracks = [asset tracksWithMediaType:AVMediaTypeVideo];
    
    if (tracks == NULL || tracks.count == 0)
    {
        NSLog(@"Failed to load tracks");
        return false;
    }

    settings = [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithInt:kCVPixelFormatType_32BGRA], (NSString*)kCVPixelBufferPixelFormatTypeKey, nil];
    
    if (settings == NULL)
    {
        NSLog(@"Failed to load settings");
        return false;
    }

    NSError * error = nil;
    videoReader = [[AVAssetReader alloc] initWithAsset:asset error:&error];
    
    if (videoReader == NULL)
    {
        NSLog(@"Failed to load video reader - %@", error.localizedDescription);
        return false;
    }

    videoOutput = [[AVAssetReaderTrackOutput alloc] initWithTrack:[tracks objectAtIndex:0] outputSettings:settings];
    
    if (videoOutput == NULL)
    {
        NSLog(@"Failed to load video output");
        return false;
    }

    CGRect rect = CGRectMake(1,2,3,4);
    videoLayer.frame = rect;

    [videoReader addOutput:videoOutput];
    [videoReader startReading];
    
    NSLog(@"Video load success");
    
    glGenFramebuffers(1, &frameBufferHandle);
    
    CVReturn err = CVOpenGLESTextureCacheCreate(kCFAllocatorDefault,
                                                NULL,
                                                context,
                                                NULL,
                                                &videoTextureCache);
    if (err)
    {
        NSLog(@"Error at CVOpenGLESTextureCacheCreate (error: %d)", err);
        return false;
    }

    return true;
}

void VideoPlayer::Render(void)
{
    CMSampleBufferRef sampleBuffer = [videoOutput copyNextSampleBuffer];

    if (sampleBuffer == 0)
    {
        NSLog(@"Shot::drawVideo: sampleBuffer == 0, status: %i", videoReader.status);
        AVAsset *asset = videoPlayer.currentItem.asset;
        NSArray *tracks = [asset tracksWithMediaType:AVMediaTypeVideo];
        videoReader = [[AVAssetReader alloc] initWithAsset:asset error:nil];
        videoOutput = [[AVAssetReaderTrackOutput alloc] initWithTrack:[tracks objectAtIndex:0] outputSettings:settings];
        [videoReader addOutput:videoOutput];
        [videoReader startReading];
        return;
    }

    CVImageBufferRef imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer);

    CVPixelBufferLockBaseAddress(imageBuffer, 0);

    int width = CVPixelBufferGetWidth(imageBuffer);
    int height = CVPixelBufferGetHeight(imageBuffer);

    // Create texture from image
    CVOpenGLESTextureRef texture = NULL;
    
    CVReturn err = CVOpenGLESTextureCacheCreateTextureFromImage(kCFAllocatorDefault,
                                                                videoTextureCache,
                                                                imageBuffer,
                                                                NULL,
                                                                GL_TEXTURE_2D,
                                                                GL_RGBA,
                                                                width,
                                                                height,
                                                                GL_BGRA,
                                                                GL_UNSIGNED_BYTE,
                                                                0,
                                                                &texture);
    
    CVPixelBufferUnlockBaseAddress(imageBuffer, 0);
    CFRelease(sampleBuffer);

    if (texture == NULL || err)
    {
        NSLog(@"CVOpenGLESTextureCacheCreateTextureFromImage failed (error: %d)", err);
        return;
    }
    
    glBindTexture(CVOpenGLESTextureGetTarget(texture), CVOpenGLESTextureGetName(texture));
    CFRelease(texture);

    glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
	glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
}