#import <Foundation/Foundation.h>
#import <CoreVideo/CoreVideo.h>
#import "MKEdgel.h"
#import "MKLineSegment.h"
#import "MKMarker.h"


@class MKLinearFeatures;

@protocol MKLinearFeaturesDelegate

- (void)linearFeatures:(MKLinearFeatures *)features drawLineFromX1:(float)x1 y1:(float)y1 x2:(float)x2 y2:(float)y2 withRed:(short)red green:(short)green andBlue:(short)blue;
- (void)linearFeatures:(MKLinearFeatures *)features drawEdgel:(edgel_t)edgel withRed:(short)red green:(short)green andBlue:(short)blue;
- (void)linearFeatures:(MKLinearFeatures *)features drawLineSegment:(linesegment_t)line withRed:(short)red green:(short)green andBlue:(short)blue;
- (void)linearFeatures:(MKLinearFeatures *)features drawMergedLines:(linesegment_t)line withRed:(short)red green:(short)green andBlue:(short)blue;
- (void)linearFeatures:(MKLinearFeatures *)features drawExtendedLines:(linesegment_t)line withRed:(short)red green:(short)green andBlue:(short)blue;
- (void)linearFeatures:(MKLinearFeatures *)features drawMarker:(marker_t)marker withRed:(short)red green:(short)green andBlue:(short)blue;

@end



@interface MKLinearFeatures : NSObject {

	unsigned char* monochromeBuffer;
	edgelPool_t* edgels;
	linesegmentPool_t* linesegments;
	linesegmentPool_t* mergedLines;
	linesegmentPool_t* lineChains;
	markerPool_t* markers;

}

@property (nonatomic, assign, getter = isDrawingGrid) BOOL drawGrid;
@property (nonatomic, assign, getter = isDrawingEdgles) BOOL drawEdgels;
@property (nonatomic, assign, getter = isDrawingLineSegments) BOOL drawLineSegments;
@property (nonatomic, assign, getter = isDrawingMergedLines) BOOL drawMergedLines;
@property (nonatomic, assign, getter = isDrawingExtendedLines) BOOL drawExtendedLines;
@property (nonatomic, assign, getter = isDrawingMarkers) BOOL drawMarkers;

- (id)initWithDelegate:(id <MKLinearFeaturesDelegate>)aDelegate;
- (void)detectMarkerInImageBuffer:(CVImageBufferRef)imageBuffer;

@end
