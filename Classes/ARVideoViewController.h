#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>
#import "GLView.h"
#import "MKLinearFeatures.h"
#import "MKMarkerDetector.h"

@interface ARVideoViewController : UIViewController <AVCaptureVideoDataOutputSampleBufferDelegate, MKMarkerDetectorDelegate> {

}

@property (nonatomic, retain) AVCaptureSession* captureSession;
@property (nonatomic, retain) AVCaptureVideoPreviewLayer* previewLayer;
@property (nonatomic, retain) MKMarkerDetector *detector;
@property (nonatomic, assign) double startTime;
@property (nonatomic, assign) double endTime;
@property (nonatomic, assign) double fpsValue;
@property (assign) NSTimer* updateTimer;
@property (nonatomic, assign) int counter;

@property (nonatomic, retain) IBOutlet GLView* arView;
@property (nonatomic, assign) IBOutlet UILabel* fpsLabel;

- (void)readSettings;
- (void)settingsChanged:(id)sender;

@end

