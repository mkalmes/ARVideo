#define VIDEO 0
#define RUNTIME 0

#import "ARVideoViewController.h"
#import "MKEdgel.h"
#import "MKMarkerDetector.h"

@interface ARVideoViewController ()

@property (nonatomic, retain) NSMutableData *lines;

- (void)initCapture;
- (void)updateFPSLabel;
- (void)clearLines;
- (void)drawLineX1:(int)x1 Y1:(int)y1 X2:(int)x2 Y2:(int)y2 red:(int)r green:(int)g blue:(int)b;
- (void)drawArrowX1:(int)x1 Y1:(int)y1 X2:(int)x2 Y2:(int)y2 XN:(float)xn YN:(float)yn red:(int)r green:(int)g blue:(int)b;

@end


@implementation ARVideoViewController

@synthesize lines;
@synthesize captureSession;
@synthesize previewLayer;
@synthesize detector;
@synthesize startTime;
@synthesize endTime;
@synthesize fpsValue;
@synthesize updateTimer;
@synthesize fpsLabel;
@synthesize arView;
@synthesize counter;


#pragma mark -
#pragma mark Init

- (void)viewDidLoad {
    [super viewDidLoad];

	self.counter = 0;

	self.lines = [NSMutableData data];

	self.updateTimer = [NSTimer scheduledTimerWithTimeInterval:1.0 target:self selector:@selector(updateFPSLabel) userInfo:nil repeats:YES];
	[self initCapture];

	[self.view addSubview:self.arView];
	[self.view sendSubviewToBack:self.arView];
	[self.arView setupView];

	self.detector = [[MKMarkerDetector alloc] initWithDelegate:self andDetectionAlgorithm:MKDetectionHirzer];
	if (!self.detector) {
		NSLog(@"Error");
	}

	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(settingsChanged:) name:NSUserDefaultsDidChangeNotification object:nil];

	[self readSettings];
}

- (void)readSettings {
	[self settingsChanged:nil];
}

- (void)settingsChanged:(id)sender {

	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	[self.detector setDrawGrid:[defaults boolForKey:@"enabled_grid"]];
	[self.detector setDrawEdgels:[defaults boolForKey:@"enabled_edgels"]];
	[self.detector setDrawLineSegments:[defaults boolForKey:@"enabled_linesegments"]];
	[self.detector setDrawMergedLines:[defaults boolForKey:@"enabled_mergedlines"]];
	[self.detector setDrawExtendedLines:[defaults boolForKey:@"enabled_extendedlines"]];
	[self.detector setDrawMarkers:[defaults boolForKey:@"enabled_marker"]];
}

- (void)initCapture {
	AVCaptureDeviceInput* captureDevice = [AVCaptureDeviceInput deviceInputWithDevice:[AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo] error:nil];
	AVCaptureVideoDataOutput *captureOutput = [[AVCaptureVideoDataOutput alloc] init];
	captureOutput.alwaysDiscardsLateVideoFrames = YES;

	dispatch_queue_t queue = dispatch_queue_create("net.mkalmes.markerqueue", DISPATCH_QUEUE_SERIAL);
	[captureOutput setSampleBufferDelegate:self queue:queue];

	// Pixelformat YCbCr, RGB
	NSString* key = (NSString*)kCVPixelBufferPixelFormatTypeKey;
	// kCVPixelFormatType_420YpCbCr8BiPlanarVideoRange - default pixelformat ipod touch
	// kCVPixelFormatType_32BGRA
	NSNumber* value = [NSNumber numberWithUnsignedInt:kCVPixelFormatType_32BGRA];
	NSDictionary* videoSettings = @{key: value};
	[captureOutput setVideoSettings:videoSettings];

	// Session presets low, medium, high, 640x480
	self.captureSession = [[AVCaptureSession alloc] init];
	self.captureSession.sessionPreset = AVCaptureSessionPreset640x480;

	[self.captureSession addInput:captureDevice];
	[self.captureSession addOutput:captureOutput];

	self.previewLayer = [AVCaptureVideoPreviewLayer layerWithSession:self.captureSession];
	self.previewLayer.frame = self.view.bounds;
	self.previewLayer.videoGravity = AVLayerVideoGravityResizeAspect;
	self.previewLayer.zPosition = -5;
	[self.view.layer addSublayer:self.previewLayer];
}

#pragma mark -
#pragma mark View

- (void)viewWillAppear:(BOOL)animated {

	[self.captureSession startRunning];
	self.startTime = CACurrentMediaTime();
}

- (void)viewWillDisappear:(BOOL)animated {
	[self.captureSession stopRunning];
}

#pragma mark AVCaptureSession delegate

- (void)captureOutput:(AVCaptureOutput *)captureOutput didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection {

#if RUNTIME
	if (self.counter < 1800) {
		self.counter++;
#endif
#if VIDEO
		self.endTime = CACurrentMediaTime();
		self.fpsValue = 1.0 / (self.endTime - self.startTime);
		self.startTime = self.endTime;

		printf("FPS: %.1f\n", self.fpsValue);

		return;
#endif
		
		[self clearLines];
		
		CVImageBufferRef imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer);
		[self.detector detectMarkerInImageBuffer:imageBuffer];

		dispatch_async(dispatch_get_main_queue(), ^{
			[self.arView updateModelCacheData:self.lines];
		});
		
		self.endTime = CACurrentMediaTime();
		self.fpsValue = 1.0 / (self.endTime - self.startTime);
		self.startTime = self.endTime;
#if RUNTIME
		printf("FPS: %.1f\n", self.fpsValue);
	} else {
		[self.captureSession stopRunning];
	}
#endif
}

- (void)updateFPSLabel {
	[self.fpsLabel setText:[NSString stringWithFormat:@"FPS: %.1f", self.fpsValue]];
}

#pragma mark -
#pragma mark Delegate

- (void)drawLineX1:(int)x1 Y1:(int)y1 X2:(int)x2 Y2:(int)y2 red:(int)r green:(int)g blue:(int)b {

	const float aspectRatio	= self.arView.bounds.size.width / self.arView.bounds.size.height;

	linemodel_vertex_t start;
	linemodel_vertex_t end;

	start.coordinate[0]	= x1 / aspectRatio;
	start.coordinate[1]	= y1 / aspectRatio;
	start.color[0]		= r;
	start.color[1]		= g;
	start.color[2]		= b;
	start.color[3]		= 255;

	end.coordinate[0]	= x2 / aspectRatio;
	end.coordinate[1]	= y2 / aspectRatio;
	end.color[0]		= r;
	end.color[1]		= g;
	end.color[2]		= b;
	end.color[3]		= 255;

	[self.lines appendBytes:&start length:sizeof(linemodel_vertex_t)];
	[self.lines appendBytes:&end length:sizeof(linemodel_vertex_t)];
}

- (void)drawArrowX1:(int)x1 Y1:(int)y1 X2:(int)x2 Y2:(int)y2 XN:(float)xn YN:(float)yn red:(int)r green:(int)g blue:(int)b {

	[self drawLineX1:x1 Y1:y1 X2:x2 Y2:y2 red:r green:g blue:b];
	[self drawLineX1:x2 Y1:y2 X2:x2 + (15.0f * (-xn + yn)) Y2:y2 + (15.0f * (-yn - xn)) red:0 green:255 blue:0];
	[self drawLineX1:x2 Y1:y2 X2:x2 + (15.0f * (-xn - yn)) Y2:y2 + (15.0f * (-yn + xn)) red:0 green:255 blue:0];
}

- (void)detector:(MKMarkerDetector *)detector drawLineFromX1:(float)x1 y1:(float)y1 x2:(float)x2 y2:(float)y2 withRed:(short)red green:(short)green andBlue:(short)blue {

	[self drawLineX1:x1 Y1:y1 X2:x2 Y2:y2 red:red green:green blue:blue];

}

- (void)detector:(MKMarkerDetector *)detector drawEdgel:(edgel_t)edgel withRed:(short)red green:(short)green andBlue:(short)blue {

	int x = edgel.coordinate.x;
	int y = edgel.coordinate.y;

#if 1
	[self drawLineX1:x - 0 Y1:y - 1 X2:x + 0 Y2:y + 1 red:red green:green blue:blue];
	[self drawLineX1:x - 1 Y1:y - 0 X2:x + 1 Y2:y + 0 red:red green:green blue:blue];
#else
	[self drawLineX1:x Y1:y X2:x + (50.0f * edgel.slope.x) Y2:y + (50.0f * edgel.slope.y) red:red green:green blue:blue];
#endif
}

- (void)detector:(MKMarkerDetector *)detector drawLineSegment:(linesegment_t)line withRed:(short)red green:(short)green andBlue:(short)blue {
	[self drawArrowX1:line.start.coordinate.x
				   Y1:line.start.coordinate.y
				   X2:line.end.coordinate.x
				   Y2:line.end.coordinate.y
				   XN:line.slope.x
				   YN:line.slope.y
				  red:red
				green:green
				 blue:blue];
}

- (void)detector:(MKMarkerDetector *)aDetector drawMergedLines:(linesegment_t)line withRed:(short)red green:(short)green andBlue:(short)blue {
	[self detector:aDetector drawLineSegment:line withRed:red green:green andBlue:blue];
}

- (void)detector:(MKMarkerDetector *)aDetector drawExtendedLines:(linesegment_t)line withRed:(short)red green:(short)green andBlue:(short)blue {
	[self detector:aDetector drawLineSegment:line withRed:red green:green andBlue:blue];
}

- (void)detector:(MKMarkerDetector *)detector drawMarker:(marker_t)marker withRed:(short)red green:(short)green andBlue:(short)blue {
	
	[self drawLineX1:marker.c1.x Y1:marker.c1.y X2:marker.c2.x Y2:marker.c2.y red:red green:green blue:blue];
	[self drawLineX1:marker.c2.x Y1:marker.c2.y X2:marker.c3.x Y2:marker.c3.y red:red green:green blue:blue];
	[self drawLineX1:marker.c3.x Y1:marker.c3.y X2:marker.c4.x Y2:marker.c4.y red:red green:green blue:blue];
	[self drawLineX1:marker.c4.x Y1:marker.c4.y X2:marker.c1.x Y2:marker.c1.y red:red green:green blue:blue];
}

- (void)clearLines {

	[self.lines setLength:0];
	[self.arView clearModelCache];
}

#pragma mark -
#pragma mark Memory Management

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

- (void)viewDidUnload {
}

- (void)dealloc {
	self.lines = nil;
	self.captureSession = nil;
	self.previewLayer = nil;
	self.detector = nil;
    [super dealloc];
}

@end
