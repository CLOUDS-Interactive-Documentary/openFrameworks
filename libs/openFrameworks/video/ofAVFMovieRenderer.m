//
//  ofxAVFVideoRenderer.m
//  AVFoundationTest
//
//  Created by Sam Kronick on 5/31/13.
//
//

#import "ofAVFMovieRenderer.h"
#import <Accelerate/Accelerate.h>

@interface AVFMovieRenderer ()

- (void)playerItemDidReachEnd:(NSNotification *) notification;
- (NSDictionary *)pixelBufferAttributes;

@property (nonatomic, retain) AVPlayerItem * playerItem;
@property (nonatomic, retain) id playerItemVideoOutput;

@end

@implementation AVFMovieRenderer

@synthesize player = _player;
@synthesize playerItem = _playerItem;
@synthesize playerItemVideoOutput = _playerItemVideoOutput;

@synthesize useTexture = _useTexture;
@synthesize useAlpha = _useAlpha;

@synthesize bLoading = _bLoading;
@synthesize bLoaded = _bLoaded;
@synthesize bAudioLoaded = _bAudioLoaded;
@synthesize bPaused = _bPaused;
@synthesize bMovieDone = _bMovieDone;

@synthesize frameRate = _frameRate;
@synthesize playbackRate = _playbackRate;
@synthesize bLoops = _bLoops;

@synthesize amplitudes = _amplitudes;
@synthesize numAmplitudes = _numAmplitudes;

int count = 0;

//--------------------------------------------------------------
- (id)init
{
    self = [super init];
    if (self) {
        
        self.player = [[AVPlayer alloc] init];
        [self.player autorelease];
        _amplitudes = [[NSMutableData data] retain];
        
        _bBuffering = NO;
        _bufferDuration = 0.0;
        
        _bLoading = NO;
        _bLoaded = NO;
        _bAudioLoaded = NO;
        _bPaused = NO;
        _bMovieDone = NO;
        
        _useTexture = YES;
        _useAlpha = NO;
        
        _frameRate = 0.0;
        _playbackRate = 1.0;
        _bLoops = false;
    }
    return self;
}

//--------------------------------------------------------------
- (NSDictionary *)pixelBufferAttributes
{
    // kCVPixelFormatType_32ARGB, kCVPixelFormatType_32BGRA, kCVPixelFormatType_422YpCbCr8
    return @{
             (NSString *)kCVPixelBufferOpenGLCompatibilityKey : [NSNumber numberWithBool:self.useTexture],
             (NSString *)kCVPixelBufferPixelFormatTypeKey     : [NSNumber numberWithInt:kCVPixelFormatType_32ARGB]
			 //[NSNumber numberWithInt:kCVPixelFormatType_422YpCbCr8]
            };
}

//--------------------------------------------------------------
- (void)loadFilePath:(NSString *)filePath
{
    [self loadURL:[NSURL fileURLWithPath:[filePath stringByStandardizingPath]]];
}

//--------------------------------------------------------------
- (void)loadURLPath:(NSString *)urlPath
{
    [self loadURL:[NSURL URLWithString:urlPath]];
}

//--------------------------------------------------------------
- (void)loadURL:(NSURL *)url
{
    _bBuffering = YES;
    _bufferDuration = 0.0;
    
    _bLoading = YES;
    _bLoaded = NO;
    _bAudioLoaded = NO;
    _bPaused = NO;
    _bWaitingForReady = NO;
    _bMovieDone = NO;
    
    _frameRate = 0.0;
    _playbackRate = 1.0;
    
//    _useTexture = YES;
//    _useAlpha = NO;
    
    if (_amplitudes) {
        [_amplitudes setLength:0];
    }
    _numAmplitudes = 0;
        
    NSLog(@"Loading %@", [url absoluteString]);
    self.loadedURL = [url absoluteString];
    
    AVURLAsset *asset = [AVURLAsset URLAssetWithURL:url options:nil];
    NSString *tracksKey = @"tracks";
    
    [asset loadValuesAsynchronouslyForKeys:@[tracksKey] completionHandler: ^{
        // Perform the following back on the main thread
        dispatch_async(dispatch_get_main_queue(), ^{
            // Check to see if the file loaded
            NSError *error;
            AVKeyValueStatus status = [asset statusOfValueForKey:tracksKey error:&error];
            
            if (status == AVKeyValueStatusLoaded) {
                // Asset metadata has been loaded, set up the player.
                AVAssetTrack *mainTrack = nil;
                NSArray *videoTracks = [asset tracksWithMediaType:AVMediaTypeVideo];
                if (videoTracks.count) {
                    // Extract the video track to get the video size and other properties.
                    mainTrack = [videoTracks objectAtIndex:0];
                }
                else {
                    // No video track, look for an audio track to read properties from.
                    NSArray *audioTracks = [asset tracksWithMediaType:AVMediaTypeAudio];
                    if (audioTracks.count) {
                        mainTrack = [audioTracks objectAtIndex:0];
                    }
                    else {
                        // No video or audio, get it together!
                        NSLog(@"Error loading URL %@: No video or audio tracks found!", [url absoluteString]);
                    }
                }
                
                _videoSize = [mainTrack naturalSize];
                _currentTime = kCMTimeZero;
                _duration = asset.duration;
                _frameRate = [mainTrack nominalFrameRate];
                _bWaitingForReady = YES;
                
                self.playerItem = [AVPlayerItem playerItemWithAsset:asset];
                [self.playerItem addObserver:self
                                  forKeyPath:@"status"
                                     options:NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld
                                     context:nil];
                
                
                // Notify this object when the player reaches the end
                // This allows us to loop the video
//                [[NSNotificationCenter defaultCenter] addObserver:self
//                                                         selector:@selector(playerItemDidReachEnd:)
//                                                             name:AVPlayerItemDidPlayToEndTimeNotification
//                                                           object:self.playerItem];
//                
                //Wait for status to be ready to play
                [self.player replaceCurrentItemWithPlayerItem:self.playerItem];
                /*
                // Create and attach video output.
                self.playerItemVideoOutput = [[AVPlayerItemVideoOutput alloc] initWithPixelBufferAttributes:[self pixelBufferAttributes]];
                [self.playerItemVideoOutput autorelease];
                if (self.playerItemVideoOutput) {
                    [(AVPlayerItemVideoOutput *)self.playerItemVideoOutput setSuppressesPlayerRendering:YES];
                }
                [self.player.currentItem addOutput:self.playerItemVideoOutput];
                
                // Create CVOpenGLTextureCacheRef for optimal CVPixelBufferRef to GL texture conversion.
                if (self.useTexture && !_textureCache) {
                    CVReturn err = CVOpenGLTextureCacheCreate(kCFAllocatorDefault, NULL,
                                                              CGLGetCurrentContext(), CGLGetPixelFormat(CGLGetCurrentContext()),
                                                              NULL, &_textureCache);
                    //(CFDictionaryRef)ctxAttributes, &_textureCache);
                    if (err != noErr) {
                        NSLog(@"Error at CVOpenGLTextureCacheCreate %d", err);
                    }
                }
                _bLoading = NO;
                _bLoaded = YES;
                 */
                
            }
            else {
                _bLoading = NO;
                _bLoaded = NO;
                NSLog(@"There was an error loading the file: %@", error);
            }
        });
    }];
}

//--------------------------------------------------------------
- (void)dealloc
{
    [self stop];

	self.playerItemVideoOutput = nil;

	if (_textureCache != NULL) {
		CVOpenGLTextureCacheRelease(_textureCache);
		_textureCache = NULL;
	}
	if (_latestTextureFrame != NULL) {
		CVOpenGLTextureRelease(_latestTextureFrame);
		_latestTextureFrame = NULL;
	}
	if (_latestPixelFrame != NULL) {
		CVPixelBufferRelease(_latestPixelFrame);
		_latestPixelFrame = NULL;
	}
	
	if (_amplitudes) {
		[_amplitudes release];
		_amplitudes = nil;
	}
	_numAmplitudes = 0;

    [[NSNotificationCenter defaultCenter] removeObserver:self];
	
    if (self.playerItem) {
        [self.playerItem removeObserver:self
                             forKeyPath:@"status"];
        self.playerItem = nil;
    }

    [self.player replaceCurrentItemWithPlayerItem:nil];
    self.player = nil;

    [super dealloc];
}

//--------------------------------------------------------------
- (void)play
{
    [self.player play];
    self.player.rate = _playbackRate;
}

//--------------------------------------------------------------
- (void)stop
{
    // Pause and rewind.
    [self.player pause];
    [self.player seekToTime:kCMTimeZero];
}

//--------------------------------------------------------------
- (void)setPaused:(BOOL)bPaused
{
    _bPaused = bPaused;
    if (_bPaused) {
        [self.player pause];
    }
    else {
        [self.player play];
        self.player.rate = _playbackRate;
    }
}

//--------------------------------------------------------------
- (BOOL)isPlaying
{
    if (![self isLoaded]) return NO;
    
	return ![self isMovieDone] && ![self isPaused];
}

//--------------------------------------------------------------
- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if ([keyPath isEqualToString:@"status"] && _bWaitingForReady) {
        
        //NSLog(@"Status changed.");
        //NSLog(@"%@", change);
        
        NSNumber* newValue = [change objectForKey:@"new"];
        if( [newValue intValue] == AVPlayerStatusReadyToPlay){
            
            // Notify this object when the player reaches the end
            // This allows us to loop the video
            [[NSNotificationCenter defaultCenter] addObserver:self
                                                     selector:@selector(playerItemDidReachEnd:)
                                                         name:AVPlayerItemDidPlayToEndTimeNotification
                                                       object:self.playerItem];
            // Create and attach video output.
            self.playerItemVideoOutput = [[AVPlayerItemVideoOutput alloc] initWithPixelBufferAttributes:[self pixelBufferAttributes]];
            [self.playerItemVideoOutput autorelease];
            if (self.playerItemVideoOutput) {
                [(AVPlayerItemVideoOutput *)self.playerItemVideoOutput setSuppressesPlayerRendering:YES];
            }
            [self.player.currentItem addOutput:self.playerItemVideoOutput];
            
            // Create CVOpenGLTextureCacheRef for optimal CVPixelBufferRef to GL texture conversion.
            if (self.useTexture && !_textureCache) {
                CVReturn err = CVOpenGLTextureCacheCreate(kCFAllocatorDefault, NULL,
                                                          CGLGetCurrentContext(), CGLGetPixelFormat(CGLGetCurrentContext()),
                                                          NULL, &_textureCache);
                //(CFDictionaryRef)ctxAttributes, &_textureCache);
                if (err != noErr) {
                    NSLog(@"Error at CVOpenGLTextureCacheCreate %d", err);
                }
            }
            
            _bWaitingForReady = NO;
            _bLoading = NO;
            _bLoaded = YES;

        }
        else if([newValue intValue] == AVPlayerStatusFailed){
            
            NSLog(@"AVPlayer status failed!");
            _bWaitingForReady = NO;
            _bLoading = NO;
            _bLoaded = NO;
        }
    }
}

//--------------------------------------------------------------
- (void)playerItemDidReachEnd:(NSNotification *)notification
{
    _bMovieDone = YES;
    
    if (self.bLoops) {
        //start over
        _bMovieDone = NO;
        [self stop];
        [self play];
    }
}

//--------------------------------------------------------------
- (BOOL)update
{
    if (![self isLoaded]) return NO;
    
    if (self.isBuffering || !self.isLikelyToKeepUp) {
        NSArray *loadedTimeRanges = [self.player.currentItem loadedTimeRanges];
        if (loadedTimeRanges.count > 0) {
            // Check how much we've buffered out of the total.
            CMTimeRange timeRange = [[loadedTimeRanges objectAtIndex:0] CMTimeRangeValue];
            Float64 startSeconds = CMTimeGetSeconds(timeRange.start);
            Float64 durationSeconds = CMTimeGetSeconds(timeRange.duration);
            _bufferDuration = startSeconds + durationSeconds;
            
            if ([self duration] > 0.0 && _bufferDuration == [self duration]) {
                _bBuffering = false;
            }
        }
    }
    
    // Update time.
    _currentTime = self.player.currentItem.currentTime;
    _duration = self.player.currentItem.duration;
    
    // Check our video output for new frames.
    CMTime outputItemTime = [self.playerItemVideoOutput itemTimeForHostTime:CACurrentMediaTime()];
    //NSLog(@"Player item? %@ - %lld ", self.loadedURL, outputItemTime.value );
    
    if ([self.playerItemVideoOutput hasNewPixelBufferForItemTime:outputItemTime]) {
        // Get pixels.
        if (_latestPixelFrame != NULL) {
            CVPixelBufferRelease(_latestPixelFrame);
            _latestPixelFrame = NULL;
        }
        _latestPixelFrame = [self.playerItemVideoOutput copyPixelBufferForItemTime:outputItemTime
                                                            itemTimeForDisplay:NULL];
        
        if (self.useTexture) {
            // Create GL texture.
            if (_latestTextureFrame != NULL) {
                CVOpenGLTextureRelease(_latestTextureFrame);
                _latestTextureFrame = NULL;
                CVOpenGLTextureCacheFlush(_textureCache, 0);
            }
            
            CVReturn err = CVOpenGLTextureCacheCreateTextureFromImage(NULL, _textureCache, _latestPixelFrame, NULL, &_latestTextureFrame);
            if (err != noErr) {
                NSLog(@"Error creating OpenGL texture %d", err);
            }
        }
        
        //NSLog(@"New Frame %@!", self.loadedURL);
        
        return YES;
    }
    
    return NO;
}

- (BOOL)isLikelyToKeepUp
{
    return self.player.currentItem && self.player.currentItem.isPlaybackLikelyToKeepUp;
}

#pragma mark - Pixels and Texture

//--------------------------------------------------------------
- (double)width
{
    return _videoSize.width;
}

//--------------------------------------------------------------
- (double)height
{
    return _videoSize.height;
}

//--------------------------------------------------------------
- (void)pixels:(unsigned char *)outbuf
{
    if (_latestPixelFrame == NULL) return;
		
//    NSLog(@"pixel buffer width is %ld height %ld and bpr %ld, movie size is %d x %d ",
//      CVPixelBufferGetWidth(_latestPixelFrame),
//      CVPixelBufferGetHeight(_latestPixelFrame),
//      CVPixelBufferGetBytesPerRow(_latestPixelFrame),
//      (NSInteger)movieSize.width, (NSInteger)movieSize.height);
    if ((NSInteger)self.width != CVPixelBufferGetWidth(_latestPixelFrame) || (NSInteger)self.height != CVPixelBufferGetHeight(_latestPixelFrame)) {
        NSLog(@"CoreVideo pixel buffer is %ld x %ld while self reports size of %ld x %ld. This is most likely caused by a non-square pixel video format such as HDV. Open this video in texture only mode to view it at the appropriate size",
              CVPixelBufferGetWidth(_latestPixelFrame), CVPixelBufferGetHeight(_latestPixelFrame), (long)self.width, (long)self.height);
        return;
    }
    
    if (CVPixelBufferGetPixelFormatType(_latestPixelFrame) != kCVPixelFormatType_32ARGB) {
        NSLog(@"QTKitMovieRenderer - Frame pixelformat not kCVPixelFormatType_32ARGB: %d, instead %ld", kCVPixelFormatType_32ARGB, (long)CVPixelBufferGetPixelFormatType(_latestPixelFrame));
        return;
    }
    
    CVPixelBufferLockBaseAddress(_latestPixelFrame, kCVPixelBufferLock_ReadOnly);
    //If we are using alpha, the ofxAVFVideoPlayer class will have allocated a buffer of size
    //video.width * video.height * 4
    //CoreVideo creates alpha video in the format ARGB, and openFrameworks expects RGBA,
    //so we need to swap the alpha around using a vImage permutation
    vImage_Buffer src = {
        CVPixelBufferGetBaseAddress(_latestPixelFrame),
        CVPixelBufferGetHeight(_latestPixelFrame),
        CVPixelBufferGetWidth(_latestPixelFrame),
        CVPixelBufferGetBytesPerRow(_latestPixelFrame)
    };
    vImage_Error err;
    if (self.useAlpha) {
        vImage_Buffer dest = { outbuf, self.height, self.width, self.width * 4 };
        uint8_t permuteMap[4] = { 1, 2, 3, 0 }; //swizzle the alpha around to the end to make ARGB -> RGBA
        err = vImagePermuteChannels_ARGB8888(&src, &dest, permuteMap, 0);
    }
    //If we are are doing RGB then ofxAVFVideoPlayer will have created a buffer of size video.width * video.height * 3
    //so we use vImage to copy them into the out buffer
    else {
        vImage_Buffer dest = { outbuf, self.height, self.width, self.width * 3 };
        err = vImageConvert_ARGB8888toRGB888(&src, &dest, 0);
    }
    
    CVPixelBufferUnlockBaseAddress(_latestPixelFrame, kCVPixelBufferLock_ReadOnly);
    
    if (err != kvImageNoError) {
        NSLog(@"Error in Pixel Copy vImage_error %ld", err);
    }
}

//--------------------------------------------------------------
- (BOOL)textureAllocated
{
    return self.useTexture && _latestTextureFrame != NULL;
}

//--------------------------------------------------------------
- (GLuint)textureID
{
    return CVOpenGLTextureGetName(_latestTextureFrame);
}

//--------------------------------------------------------------
- (GLenum)textureTarget
{
    return CVOpenGLTextureGetTarget(_latestTextureFrame);
}

//--------------------------------------------------------------
- (void)bindTexture
{
    if (!self.textureAllocated) return;
    
	GLuint texID = [self textureID];
	GLenum target = [self textureTarget];
	
	glEnable(target);
	glBindTexture(target, texID);
}

//--------------------------------------------------------------
- (void)unbindTexture
{
    if (!self.textureAllocated) return;
	
	GLenum target = [self textureTarget];
	glDisable(target);
}

#pragma mark - Playhead

//--------------------------------------------------------------
- (double)duration
{
    return CMTimeGetSeconds(_duration);
}

//--------------------------------------------------------------
- (int)totalFrames
{
    return self.duration * self.frameRate;
}

//--------------------------------------------------------------
- (double)currentTime
{
    return CMTimeGetSeconds(_currentTime);
}

//--------------------------------------------------------------
- (void)setCurrentTime:(double)currentTime
{
    [_player seekToTime:CMTimeMakeWithSeconds(currentTime, _duration.timescale)];
}

//--------------------------------------------------------------
- (int)currentFrame
{
    return self.currentTime * self.frameRate;
}

//--------------------------------------------------------------
- (void)setCurrentFrame:(int)currentFrame
{
    float position = currentFrame / (float)self.totalFrames;
    [self setPosition:position];
}

//--------------------------------------------------------------
- (double)position
{
    return self.currentTime / self.duration;
}

//--------------------------------------------------------------
- (void)setPosition:(double)position
{
    double time = self.duration * position;
//    [self.player seekToTime:CMTimeMakeWithSeconds(time, NSEC_PER_SEC)];
    [_player seekToTime:CMTimeMakeWithSeconds(time, _duration.timescale)];
}

//--------------------------------------------------------------
- (void)setPlaybackRate:(double)playbackRate
{
    _playbackRate = playbackRate;
    [_player setRate:_playbackRate];
}

//--------------------------------------------------------------
- (float)volume
{
    return self.player.volume;
}

//--------------------------------------------------------------
- (void)setVolume:(float)volume
{
    self.player.volume = volume;
}

@end
