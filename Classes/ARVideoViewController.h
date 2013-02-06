#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>
#import "GLView.h"
#import "MKLinearFeatures.h"
#import "MKMarkerDetector.h"

@interface ARVideoViewController : UIViewController <AVCaptureVideoDataOutputSampleBufferDelegate, MKMarkerDetectorDelegate> {

}

@property (nonatomic, strong) AVCaptureSession* captureSession;
@property (nonatomic, strong) AVCaptureVideoPreviewLayer* previewLayer;
@property (nonatomic, strong) MKMarkerDetector *detector;
@property (nonatomic, assign) double startTime;
@property (nonatomic, assign) double endTime;
@property (nonatomic, assign) double fpsValue;
@property (weak) NSTimer* updateTimer;
@property (nonatomic, assign) int counter;

@property (nonatomic, strong) IBOutlet GLView* arView;
@property (nonatomic, weak) IBOutlet UILabel* fpsLabel;

- (void)readSettings;
- (void)settingsChanged:(id)sender;

@end

