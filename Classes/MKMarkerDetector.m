#import <AVFoundation/AVFoundation.h>

#import "MKMarkerDetector.h"
#import "MKDetectorClarke.h"
#import "MKDetectorHirzer.h"


@implementation MKMarkerDetector

- (void)detectMarkerInImageBuffer:(CVImageBufferRef)imageBuffer {
	NSAssert(NO, @"Must be implemented in concrete subclass");
}

- (void)setDrawGrid:(BOOL)draw {
	NSAssert(NO, @"Must be implemented in concrete subclass");
}

- (void)setDrawEdgels:(BOOL)draw {
	NSAssert(NO, @"Must be implemented in concrete subclass");
}

- (void)setDrawLineSegments:(BOOL)draw {
	NSAssert(NO, @"Must be implemented in concrete subclass");
}

- (void)setDrawMergedLines:(BOOL)draw {
	NSAssert(NO, @"Must be implemented in concrete subclass");
}

- (void)setDrawExtendedLines:(BOOL)draw {
	NSAssert(NO, @"Must be implemented in concrete subclass");
}

- (void)setDrawMarkers:(BOOL)draw {
	NSAssert(NO, @"Must be implemented in concrete subclass");
}


@end

@implementation MKMarkerDetector (MKMarkerDetectorCreation)

- (id)initWithDelegate:(id<MKMarkerDetectorDelegate>)aDelegate {
	return [self initWithDelegate:aDelegate andDetectionAlgorithm:MKDetectionClarke];
}

- (id)initWithDelegate:(id<MKMarkerDetectorDelegate>)aDelegate andDetectionAlgorithm:(MKDetectionAlgorithm)algorithm {

	switch (algorithm) {

		case MKDetectionClarke:
			return [[MKDetectorClarke alloc] initWithDelegate:aDelegate];
			break;

		case MKDetectionHirzer:
			return [[MKDetectorHirzer alloc] initWithDelegate:aDelegate];
			break;

		default:
			return nil;
			break;
	}
}

@end
