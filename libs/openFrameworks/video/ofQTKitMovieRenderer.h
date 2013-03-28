
// Copyright (c) 2012 openFrameworks team
// openFrameworks is released under the MIT License. See libs/_Licence.txt

#import <Cocoa/Cocoa.h>
#import <Quartz/Quartz.h>
#import <QTKit/QTKit.h>
#import <OpenGL/OpenGL.h>


@interface QTKitMovieRenderer : NSObject
{
	QTMovie * _movie;
	QTVisualContextRef _visualContext;
    
	CVOpenGLTextureCacheRef _textureCache;
	CVOpenGLTextureRef _latestTextureFrame;
	CVPixelBufferRef _latestPixelFrame;

    BOOL _audioFrequencyMeteringEnabled;
//    NSInteger _numAudioFrequencyChannels;
//    NSInteger _numAudioFrequencyBands;
    FourCharCode _audioFrequencyMixToMeter;
    BOOL _audioVolumeMeteringEnabled;
//    NSInteger _numAudioVolumeChannels;
    QTAudioFrequencyLevels * _audioFrequencyLevels;
    QTAudioVolumeLevels * _audioVolumeLevels;
    Float32 * _audioFrequencyMeteringBandFrequencies;

	NSSize movieSize;
	QTTime movieDuration;
	NSInteger frameCount;
//	double frameStep;
    QTTime lastMovieTime;
	BOOL frameUpdated;
	BOOL useTexture;
	BOOL usePixels;
	BOOL useAlpha;
	BOOL synchronousSeek;
	BOOL justSetFrame;
	BOOL frameIsNew;
	BOOL hasVideo;
	BOOL hasAudio;
	BOOL loadedFirstFrame;
	NSArray* frameTimeValues;
	NSCondition* synchronousSeekLock;
}

@property (nonatomic, readonly) NSSize movieSize;
@property (nonatomic, readonly) BOOL useTexture;
@property (nonatomic, readonly) BOOL usePixels;
@property (nonatomic, readonly) BOOL useAlpha;
@property (nonatomic, readonly) NSTimeInterval duration; //duration in seconds
@property (nonatomic, readonly) NSInteger frameCount;  //total frames
@property (nonatomic, readonly) BOOL isFinished;  //returns true if the movie is not looping and over
@property (readwrite) BOOL justSetFrame; //this needs to be set *before* calls to _movie.setTime to allow synchronous seeking
@property (nonatomic, readwrite) BOOL synchronousSeek;

@property (nonatomic, readonly) BOOL hasAudio;
@property (nonatomic, readonly) BOOL hasVideo;

@property (nonatomic, readonly) BOOL audioFrequencyMeteringEnabled;
@property (nonatomic, readonly) QTAudioFrequencyLevels * audioFrequencyLevels;
@property (nonatomic, readonly) Float32 * audioFrequencyMeteringBandFrequencies;
@property (nonatomic, readonly) BOOL audioVolumeMeteringEnabled;
@property (nonatomic, readonly) QTAudioVolumeLevels * audioVolumeLevels;

@property (nonatomic, readwrite) float rate;
@property (nonatomic, readwrite) float volume;
@property (nonatomic, readonly) CGFloat time;
@property (nonatomic, readonly) long long timeValue;
@property (nonatomic, readwrite) CGFloat position;  //set and get frame position by percent
@property (nonatomic, readwrite) NSInteger frame;  //set and get frame position by percent
@property (nonatomic, readwrite) BOOL loops;  //set and get loopstate
@property (nonatomic, readwrite) BOOL palindrome;  //set and get palindrome state

@property (nonatomic, readonly) BOOL textureAllocated;
@property (nonatomic, readonly) GLuint textureID;
@property (nonatomic, readonly) GLenum textureTarget;

- (NSDictionary *)pixelBufferAttributes;

- (void)draw:(NSRect)drawRect;
- (BOOL)loadMovie:(NSString *)moviePath pathIsURL:(BOOL)isURL allowTexture:(BOOL)useTexture allowPixels:(BOOL)usePixels allowAlpha:(BOOL)useAlpha;
- (void)enableAudioFrequencyMetering:(NSInteger)numChannels numBands:(NSInteger)numBands;
- (void)enableAudioVolumeMetering:(NSInteger)numChannels;
- (BOOL)update;

- (void)bindTexture;
- (void)unbindTexture;

//copies ARGB pixels to RGB or RGBA depending on allowAlpha
//outbuf must be allocated with enough space depending on movieSize
- (void)pixels:(unsigned char *)outbuf;
- (void)setBalance:(float)balance;
- (void)stepForward;
- (void)stepBackward;
- (void)gotoBeginning;

- (void)frameAvailable:(CVImageBufferRef)image;
- (void)frameFailed;

- (void)synchronizeSeek;

@end
