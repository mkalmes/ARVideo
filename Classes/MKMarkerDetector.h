#import <Foundation/Foundation.h>
#import "MKEdgel.h"
#import "MKLineSegment.h"
#import "MKMarker.h"

@class AVFoundation, MKMarkerDetector;

@protocol MKMarkerDetectorDelegate

- (void)detector:(MKMarkerDetector *)detector drawLineFromX1:(float)x1 y1:(float)y1 x2:(float)x2 y2:(float)y2 withRed:(short)red green:(short)green andBlue:(short)blue;
- (void)detector:(MKMarkerDetector *)detector drawEdgel:(edgel_t)edgel withRed:(short)red green:(short)green andBlue:(short)blue;
- (void)detector:(MKMarkerDetector *)detector drawLineSegment:(linesegment_t)line withRed:(short)red green:(short)green andBlue:(short)blue;
- (void)detector:(MKMarkerDetector *)detector drawMergedLines:(linesegment_t)line withRed:(short)red green:(short)green andBlue:(short)blue;
- (void)detector:(MKMarkerDetector *)detector drawExtendedLines:(linesegment_t)line withRed:(short)red green:(short)green andBlue:(short)blue;
- (void)detector:(MKMarkerDetector *)detector drawMarker:(marker_t)marker withRed:(short)red green:(short)green andBlue:(short)blue;

@end

enum {
	MKDetectionClarke = 0,
	MKDetectionHirzer
}; typedef NSUInteger MKDetectionAlgorithm;

@interface MKMarkerDetector : NSObject

- (void)detectMarkerInImageBuffer:(CVImageBufferRef)imageBuffer;
- (void)setDrawGrid:(BOOL)draw;
- (void)setDrawEdgels:(BOOL)draw;
- (void)setDrawLineSegments:(BOOL)draw;
- (void)setDrawMergedLines:(BOOL)draw;
- (void)setDrawExtendedLines:(BOOL)draw;
- (void)setDrawMarkers:(BOOL)draw;

@end

@interface MKMarkerDetector (MKMarkerDetectorCreation)

- (id)initWithDelegate:(id<MKMarkerDetectorDelegate>)aDelegate;
- (id)initWithDelegate:(id<MKMarkerDetectorDelegate>)aDelegate andDetectionAlgorithm:(MKDetectionAlgorithm)algorithm;


@end
