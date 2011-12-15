#import "MKLinearFeatures.h"
#import "MKImageProcessing.h"
#import "Vector2f.h"


const int kImageWidth	= 320;
const int kImageHeight	= 240;
const int kRegionSize	= 40;
const int kThreshold	= 256;
const int kMinEdgels	= 5;

@interface MKLinearFeatures ()

@property (nonatomic, assign, readwrite) id delegate;
@property (nonatomic, assign, readwrite) int imageWidth;
@property (nonatomic, assign, readwrite) int imageHeight;


- (void)imageSizedChangedWidht:(int)width height:(int)height;

- (void)findEdgelsInFrame:(const unsigned char*)frame andCopyToEdgelPool:(edgelPool_t*)pool forRegionLeft:(const short)left andRegionTop:(const short)top;

- (void)detectLinesFromEdgels:(edgelPool_t *)edgels copyToLinePool:(linesegmentPool_t *)pool;

- (void)mergeLinesInLinePool:(linesegmentPool_t *)pool;

- (void)extendLinesInLinePool:(linesegmentPool_t *)pool;

- (void)findLinesWithCornersInLinePool:(linesegmentPool_t *)pool copyToLinePool:(linesegmentPool_t *)linesWithCorners;

- (void)findChainOfLinesInBuffer:(linesegmentPool_t*)searchBuffer withStartChain:(linesegment_t*)start fromStart:(BOOL)fromStart chainLength:(int*)chainLength copyToBuffer:(linesegmentPool_t*)chainBuffer;

- (marker_t)reconstructCornersFromChains:(linesegmentPool_t*)chains;


int MKLinearFeaturesConvoluteKernelX (const unsigned char *buffer, short x, short y, const int width, const int height);

int MKLinearFeaturesConvoluteKernelY (const unsigned char *buffer, short x, short y, const int width, const int height);

vector_t MKLinearFeaturesGradientIntensity (const unsigned char* buffer, const unsigned int width, const unsigned int height, const int x, const int y);

bool MKLinearFeaturesExtendLine (vector_t start, const vector_t slope, const vector_t gradient, vector_t *end, const int maxLength, const unsigned char* buffer);

void MKLinearFeaturesExtendLineSegment (linesegmentPool_t* lines, const unsigned char* buffer);

@end



@implementation MKLinearFeatures

@synthesize delegate;
@synthesize imageWidth;
@synthesize imageHeight;
@synthesize drawGrid;
@synthesize drawEdgels;
@synthesize drawLineSegments;
@synthesize drawMergedLines;
@synthesize drawExtendedLines;
@synthesize drawMarkers;

#pragma mark -
#pragma mark Init
- (id)initWithDelegate:(id <MKLinearFeaturesDelegate>)aDelegate {

	self = [super init];
	if (!self) {
		return nil;
	}

	self.delegate			= aDelegate;
	self.imageWidth			= kImageWidth;
	self.imageHeight		= kImageHeight;
	self.drawGrid			= NO;
	self.drawEdgels			= NO;
	self.drawLineSegments	= NO;
	self.drawMergedLines	= NO;
	self.drawExtendedLines	= NO;
	self.drawMarkers		= YES;

	monochromeBuffer		= (unsigned char*)calloc(1, (kImageWidth * kImageHeight) * sizeof(unsigned char));
	edgels					= MKEdgelGetMemoryPool();
	linesegments			= MKLineSegmentGetMemoryPool();
	mergedLines				= MKLineSegmentGetMemoryPool();
	lineChains				= MKLineSegmentGetMemoryPool();
	markers					= MKMarkerGetMemoryPool();

	return self;
}

#pragma mark -
#pragma mark Marker Detection
- (void)detectMarkerInImageBuffer:(CVImageBufferRef)imageBuffer {

	const BOOL shouldDrawLineSegments	= [self isDrawingLineSegments];
	const BOOL shouldDrawMergedLines	= [self isDrawingMergedLines];
	const BOOL shouldDrawExtendedLine	= [self isDrawingExtendedLines];
	const BOOL shouldDrawMarkers		= [self isDrawingMarkers];

	// get the pixelbuffer
	CVPixelBufferLockBaseAddress(imageBuffer, 0);
	const int width		= CVPixelBufferGetWidth(imageBuffer);
	const int height	= CVPixelBufferGetHeight(imageBuffer);
	if (self.imageWidth != width || self.imageHeight != height) {
		[self imageSizedChangedWidht:width height:height];
	}
	MKImageProcessingConvert420VPixelBufferToMonochrome(imageBuffer, monochromeBuffer);
	CVPixelBufferUnlockBaseAddress(imageBuffer, 0);

	MKLineSegmentResetMemoryPool(mergedLines);
	MKLineSegmentResetMemoryPool(linesegments);

	// calculate the region
	for (short y = 0; y < height; y += kRegionSize) {
		for (short x = 0; x < width; x += kRegionSize) {

			[self findEdgelsInFrame:monochromeBuffer andCopyToEdgelPool:edgels forRegionLeft:x andRegionTop:y];

			[self detectLinesFromEdgels:edgels copyToLinePool:linesegments];
			if (shouldDrawLineSegments) {

				const int numberOfSegments = MKLineSegmentGetLineCount(linesegments);
				for (int i = 0; i < numberOfSegments; i++) {
					[self.delegate linearFeatures:self drawLineSegment:linesegments->data[i] withRed:255 green:255 andBlue:0];
				}
			}

			[self mergeLinesInLinePool:linesegments];

			for (int i = 0; i < MKLineSegmentGetLineCount(linesegments); i++) {
				MKLineSegmentAddLine(mergedLines, MKLineSegmentGetLineSegment(linesegments, i));
			}

			MKEdgelResetMemoryPool(edgels);
			MKLineSegmentResetMemoryPool(linesegments);
		}
	}

	if (MKLineSegmentGetLineCount(mergedLines) > 0) {

		[self mergeLinesInLinePool:mergedLines];
		if (shouldDrawMergedLines) {

			const int numberOfMergedLines = MKLineSegmentGetLineCount(mergedLines);
			for (int i = 0; i < numberOfMergedLines; i++) {
				[self.delegate linearFeatures:self drawMergedLines:mergedLines->data[i] withRed:255 green:255 andBlue:0];
			}
		}

		[self extendLinesInLinePool:mergedLines];
		if (shouldDrawExtendedLine) {

			const int numberOfExtendedLines = MKLineSegmentGetLineCount(mergedLines);
			for (int i = 0; i < numberOfExtendedLines; i++) {
				[self.delegate linearFeatures:self drawMergedLines:mergedLines->data[i] withRed:255 green:0 andBlue:0];
			}
		}

		[self findLinesWithCornersInLinePool:mergedLines copyToLinePool:linesegments];

		do {

			MKLineSegmentResetMemoryPool(lineChains);

			linesegment_t chain = linesegments->data[0];
			MKLineSegmentRemoveLine(linesegments, 0);

			int length = 1;

			[self findChainOfLinesInBuffer:linesegments withStartChain:&chain fromStart:TRUE chainLength:&length copyToBuffer:lineChains];

			MKLineSegmentAddLine(lineChains, chain);

			if (length < 4) {
				[self findChainOfLinesInBuffer:linesegments withStartChain:&chain fromStart:FALSE chainLength:&length copyToBuffer:lineChains];
			}

			if (length > 2) {

				marker_t marker = [self reconstructCornersFromChains:lineChains];
				MKMarkerAddMarker(markers, marker);
			}

		} while (MKLineSegmentGetLineCount(linesegments));
	}

	if (shouldDrawMarkers) {

		const int numberOfMarkers = MKMarkerGetLineCount(markers);
		for (int i = 0; i < numberOfMarkers; i++) {
			[self.delegate linearFeatures:self drawMarker:markers->data[i] withRed:255 green:0 andBlue:0];
		}
	}

	MKMarkerResetMemoryPool(markers);
}

#pragma mark -
#pragma mark MKLinearFeatures Extension
- (void)imageSizedChangedWidht:(int)width height:(int)height {

	self.imageWidth		= width;
	self.imageHeight	= height;

	monochromeBuffer	= reallocf(monochromeBuffer, (self.imageHeight * self.imageWidth * sizeof(unsigned char)));
}

- (void)findEdgelsInFrame:(const unsigned char*)frame andCopyToEdgelPool:(edgelPool_t*)pool forRegionLeft:(const short)left andRegionTop:(const short)top {

	int prev1 = 0;
	int prev2 = 0;

	if (self.drawGrid) {
		[self.delegate linearFeatures:self drawLineFromX1:left y1:top x2:left + kRegionSize y2:top withRed:255 green:255 andBlue:0];
		[self.delegate linearFeatures:self drawLineFromX1:left y1:top x2:left y2:top + kRegionSize withRed:255 green:255 andBlue:0];
		[self.delegate linearFeatures:self drawLineFromX1:left y1:top + kRegionSize x2:left + kRegionSize y2:top + kRegionSize withRed:255 green:255 andBlue:0];
		[self.delegate linearFeatures:self drawLineFromX1:left + kRegionSize y1:top x2:left + kRegionSize y2:top + kRegionSize withRed:255 green:255 andBlue:0];
	}

	const int width				= self.imageWidth;
	const int height			= self.imageHeight;
	const BOOL shouldDrawEdgels	= [self isDrawingEdgles];

	// find edgels along the horizontal (x) scanline
	for (short y = top; y < top + kRegionSize; y += 5) {

		prev1 = 0;
		prev2 = 0;

		for (short x = left; x < left + kRegionSize; x++) {

			int currentEdgel = MKLinearFeaturesConvoluteKernelX(frame, x, y, width, height);

			if (currentEdgel > kThreshold) {
				// probably an edgel
			} else {
				currentEdgel = 0;
			}

			if (prev1 > 0 && prev1 > prev2 && prev1 > currentEdgel) {

				edgel_t edgel;
				Vector2fSetCoordinate(&edgel.coordinate, x - 1, y);
				edgel.slope = MKLinearFeaturesGradientIntensity(frame, width, height, x - 1, y);
				MKEdgelAddEdgel(pool, edgel);

				if (shouldDrawEdgels) {
					[self.delegate linearFeatures:self drawEdgel:edgel withRed:0 green:255 andBlue:0];
				}
			}

			prev2 = prev1;
			prev1 = currentEdgel;
		}
	}

	// find edgels along the vertical (y) scnaline
	for (short x = left; x < left + kRegionSize; x += 5) {

		prev1 = 0;
		prev2 = 0;

		for (short y = top; y < top + kRegionSize; y++) {

			int currentEdgel = MKLinearFeaturesConvoluteKernelY(frame, x, y, width, height);

			if (currentEdgel > kThreshold) {
				// probably an edgel
			} else {
				currentEdgel = 0;
			}

			if (prev1 > 0 && prev1 > prev2 && prev1 > currentEdgel) {

				edgel_t edgel;
				Vector2fSetCoordinate(&edgel.coordinate, x, y - 1);
				edgel.slope = MKLinearFeaturesGradientIntensity(frame, width, height, x, y - 1);
				MKEdgelAddEdgel(pool, edgel);

				if (shouldDrawEdgels) {
					[self.delegate linearFeatures:self drawEdgel:edgel withRed:0 green:0 andBlue:255];
				}
			}

			prev2 = prev1;
			prev1 = currentEdgel;
		}
	}
}

- (void)detectLinesFromEdgels:(edgelPool_t *)edgelpool copyToLinePool:(linesegmentPool_t *)linesegmentPool {

	linesegment_t presentLine;
	int edgelsInRegion = 0;

	do {
		presentLine.supportCount = 0;

		for (int i = 0; i < 25; i++) {
			edgel_t start;
			edgel_t end;

			const int maxIteration	= 64;
			int iterator			= 0;
			int first;
			int last;

			const unsigned int numberOfEdgels = MKEdgelGetEdgelCount(edgelpool);

			// create line w/ two random edgels which are compatible
			do {
				first	= (rand() % numberOfEdgels);
				last	= (rand() % numberOfEdgels);

				start	= MKEdgelGetEdgel(edgels, first);
				end		= MKEdgelGetEdgel(edgels, last);

				iterator++;
			} while ( (first == last || !MKEdgelIsCompatible(start, end)) &&  iterator < maxIteration);

			if (iterator < maxIteration) {
				// found a line
				linesegment_t segment;
				segment.start			= start;
				segment.end				= end;
				segment.slope			= start.slope;
				segment.supportCount	= 0;
				segment.remove			= NO;
				segment.startCorner		= NO;
				segment.endCorner		= NO;

				// check for supporting edgels
				for (int j = 0; j < numberOfEdgels; j++) {
					// is edgel near to the line?
					edgel_t supportEdgel = MKEdgelGetEdgel(edgels, j);
					if (MKLineSegmentIsEdgelNearLine(segment, supportEdgel)) {
						MKLineSegmentAddEdgel(&segment, supportEdgel, segment.supportCount);
						segment.supportCount++;
					}
				}

				if (segment.supportCount > presentLine.supportCount) {
					// found a line with more support edgels
					presentLine = segment;
				}
			}
		}

		if (presentLine.supportCount > kMinEdgels) {

			// which edgel is at the beginning of the line
			// which edgel is at the end of the line
			float start	= 0;
			float end	= FLT_MAX;
			const vector_t slope		= Vector2fSubtract(presentLine.start.coordinate, presentLine.end.coordinate);
			const vector_t orientation	= {-presentLine.start.slope.y, presentLine.start.slope.x};

			if ( fabsf(slope.x) <= fabsf(slope.y)) {
				for(int k = 0; k < presentLine.supportCount; k++) {

					edgel_t edgel = presentLine.support[k];

					if (edgel.coordinate.y > start) {
						start = edgel.coordinate.y;
						presentLine.start = edgel;
					}

					if (edgel.coordinate.y < end) {
						end = edgel.coordinate.y;
						presentLine.end = edgel;
					}
				}
			} else {
				for(int k = 0; k < presentLine.supportCount; k++) {

					edgel_t edgel = presentLine.support[k];

					if (edgel.coordinate.x > start) {
						start = edgel.coordinate.x;
						presentLine.start = edgel;
					}

					if (edgel.coordinate.x < end) {
						end = edgel.coordinate.x;
						presentLine.end = edgel;
					}
				}
			}

			vector_t magnitude	= Vector2fSubtract(presentLine.end.coordinate, presentLine.start.coordinate);
			const float angle	= Vector2fDotProduct(magnitude, orientation);

			if (angle < 0.0f) {
				// swap start and end of line segment
				edgel_t newEnd		= presentLine.start;
				presentLine.start	= presentLine.end;
				presentLine.end		= newEnd;
			}

			magnitude = Vector2fSubtract(presentLine.end.coordinate, presentLine.start.coordinate);
			Vector2fGetNormalized(&magnitude);
			presentLine.slope = magnitude;

			// add line to line pool
			MKLineSegmentAddLine(linesegmentPool, presentLine);

			// remove support edgels from edgel pool
			int supportCount = presentLine.supportCount;
			for (int i = 0; i < supportCount; i++) {
				edgel_t remove = presentLine.support[i];
				MKEdgelRemoveEdgel(edgels, remove);
			}
		}

		edgelsInRegion = MKEdgelGetEdgelCount(edgels);

	} while (presentLine.supportCount > kMinEdgels && edgelsInRegion > kMinEdgels);
}

- (void)mergeLinesInLinePool:(linesegmentPool_t *)pool {

	distancePool_t distancepool;

	for (int i = 0; i < MKLineSegmentGetLineCount(pool); i++) {
		MKLineSegmentDistanceFreePool(&distancepool);
		linesegment_t start = MKLineSegmentGetLineSegment(pool, i);

		for (int j = 0; j < MKLineSegmentGetLineCount(pool); j++) {

			if (i == j) {
				continue;
			}

			linesegment_t tmp = MKLineSegmentGetLineSegment(pool, j);

			// orientation of the linesegments
			float lineOrientation = Vector2fDotProduct(tmp.slope, start.slope);

			// orientation of the line connection the linesegments
			vector_t connectionLine = Vector2fSubtract(tmp.end.coordinate, start.start.coordinate);
			Vector2fGetNormalized(&connectionLine);
			float connectionOrientation = Vector2fDotProduct(connectionLine, start.slope);

			if (lineOrientation > 0.99f && connectionOrientation > 0.99f) {
				vector_t connectionLine = Vector2fSubtract(tmp.start.coordinate, start.end.coordinate);
				const int squardLength = (int) Vector2fGetSquaredLength(&connectionLine);

				if (squardLength < (25 * 25)) {
					linesegmentDistance_t distance;
					distance.distance = squardLength;
					distance.index = j;
					MKLineSegmentDistanceAddToPool(&distancepool, distance);
				}
			}
		}

		if (!MKLineSegmentDistanceGetDistanceCount(&distancepool)) {
			continue;
		}

		const int numberOfDistances = MKLineSegmentDistanceGetDistanceCount(&distancepool);
		// sort the distances
		qsort(&distancepool, numberOfDistances, sizeof(linesegmentDistance_t), MKLineSegmentDistanceCompare);

		// loop over the distances
		for (int k = 0; k < numberOfDistances; k++) {
			const int j = distancepool.data[k].index;

			const vector_t startpoint	= start.end.coordinate;
			vector_t endpoint			= MKLineSegmentGetLineSegment(pool, j).start.coordinate;

			vector_t lineLength	= Vector2fSubtract(endpoint, startpoint);
			vector_t lineSlope	= Vector2fSubtract(endpoint, startpoint);
			const int length = Vector2fGetLength(&lineLength);
			Vector2fGetNormalized(&lineSlope);

			if (MKLinearFeaturesExtendLine(startpoint,
										   lineSlope,
										   start.end.slope,
										   &endpoint,
										   length,
										   monochromeBuffer)) {

				pool->data[i].end = pool->data[j].end;

				vector_t newLineSlope = Vector2fSubtract(pool->data[i].end.coordinate, pool->data[i].start.coordinate);
				Vector2fGetNormalized(&newLineSlope);
				pool->data[i].slope	= newLineSlope;

				// mark line for deletion
				pool->data[j].remove = true;

			} else {
				break;
			}
		}

		bool merged = false;

		for (int j = 0; j < MKLineSegmentGetLineCount(pool); j++) {
			if (pool->data[j].remove == true) {

				MKLineSegmentRemoveLine(pool, j);
				j--;
				merged = true;
			}
		}

		if (merged) {
			i = -1;
		}
	}
}

- (void)extendLinesInLinePool:(linesegmentPool_t *)pool {

	const int lineCount = MKLineSegmentGetLineCount(pool);
	for (int i = 0; i < lineCount; i++) {

		vector_t slope = pool->data[i].slope;

		MKLinearFeaturesExtendLine(pool->data[i].end.coordinate,
								   slope,
								   pool->data[i].end.slope,
								   &pool->data[i].end.coordinate,
								   999,
								   monochromeBuffer);

		slope.x *= -1;
		slope.y *= -1;

		MKLinearFeaturesExtendLine(pool->data[i].start.coordinate,
								   slope,
								   pool->data[i].end.slope,
								   &pool->data[i].start.coordinate,
								   999,
								   monochromeBuffer);
	}
}

- (void)findLinesWithCornersInLinePool:(linesegmentPool_t *)pool copyToLinePool:(linesegmentPool_t *)linesWithCorners {

	MKLineSegmentResetMemoryPool(linesWithCorners);

	const int numberOfLines = MKLineSegmentGetLineCount(pool);
	for (int i = 0; i < numberOfLines; i++) {

		const int dx = pool->data[i].slope.x * 4.0f;
		const int dy = pool->data[i].slope.x * 4.0f;

		int x = pool->data[i].start.coordinate.x - dx;
		int y = pool->data[i].start.coordinate.y - dy;
		if (MKImageProcessingGetUnsignedCharValue(monochromeBuffer, x, y, 640, 480) > 10) {
			pool->data[i].startCorner = YES;
		}

		x = pool->data[i].start.coordinate.x + dx;
		y = pool->data[i].start.coordinate.y + dy;
		if (MKImageProcessingGetUnsignedCharValue(monochromeBuffer, x, y, 640, 480) > 10) {
			pool->data[i].endCorner = YES;
		}

		if (pool->data[i].startCorner || pool->data[i].endCorner) {
			MKLineSegmentAddLine(linesWithCorners, pool->data[i]);
		}
	}
}

- (void)findChainOfLinesInBuffer:(linesegmentPool_t*)searchBuffer withStartChain:(linesegment_t*)start fromStart:(BOOL)fromStart chainLength:(int*)chainLength copyToBuffer:(linesegmentPool_t*)chainBuffer {

	const vector_t startPoint = fromStart ? start->start.coordinate : start->end.coordinate;

	for (int i = 0; i < searchBuffer->count; i++) {

		// no parallel lines
		if (MKLineSegmentIsOrientationCompatible(*start, searchBuffer->data[i])) {
			continue;
		}

		// point should be close to eachother
		vector_t endpoint = fromStart ? linesegments->data[i].end.coordinate : linesegments->data[i].start.coordinate;
		vector_t distance = Vector2fSubtract(startPoint, endpoint);
		float squaredLength = Vector2fGetSquaredLength(&distance);
		if (squaredLength > 16.0f) {
			continue;
		}

		// Check the orientation of the lines
		float test = (start->slope.x * linesegments->data[i].slope.y) - (start->slope.y * linesegments->data[i].slope.x);
		if ((fromStart &&	test <= 0) ||
			 (!fromStart &&	test >= 0)) {
			continue;
		}

		*chainLength += 1;
		linesegment_t chainSegment = linesegments->data[i];
		MKLineSegmentRemoveLine(linesegments, i);

		if (*chainLength == 4) {
			MKLineSegmentAddLine(lineChains, chainSegment);
			return;
		}

		if (!fromStart) {
			MKLineSegmentAddLine(lineChains, chainSegment);
		}

		[self findChainOfLinesInBuffer:searchBuffer withStartChain:&chainSegment fromStart:fromStart chainLength:chainLength copyToBuffer:chainBuffer];
		if (fromStart) {
			MKLineSegmentAddLine(lineChains, chainSegment);
		}
		return;
	}
}

- (marker_t)reconstructCornersFromChains:(linesegmentPool_t*)chains {

	marker_t marker = {{-1.0f, -1.0f},{-1.0f, -1.0f},{-1.0f, -1.0f},{-1.0f, -1.0f}};

	vector_t c1 = MKLineSegmentIntersection(chains->data[0], chains->data[1]);
	vector_t c2 = MKLineSegmentIntersection(chains->data[1], chains->data[2]);
	vector_t c3 = {-1.0f, -1.0f};
	vector_t c4 = {-1.0f, -1.0f};

	if (MKLineSegmentGetLineCount(chains) == 4) {

		c3 = MKLineSegmentIntersection(chains->data[2], chains->data[3]);
		c4 = MKLineSegmentIntersection(chains->data[3], chains->data[0]);
	} else {

		c3 = chains->data[2].end.coordinate;
		c4 = chains->data[0].start.coordinate;
	}

	marker.c1 = c1;
	marker.c2 = c2;
	marker.c3 = c3;
	marker.c4 = c4;

	return marker;
}

int MKLinearFeaturesConvoluteKernelX (const unsigned char *buffer, short x, short y, const int width, const int height) {
	int value = -3 * MKImageProcessingGetUnsignedCharValue(buffer, x - 2 , y, width, height);
	value += -5 * MKImageProcessingGetUnsignedCharValue(buffer, x - 1, y, width, height);
	value += 5 * MKImageProcessingGetUnsignedCharValue(buffer, x + 1, y, width, height);
	value += 3 * MKImageProcessingGetUnsignedCharValue(buffer, x + 2, y, width, height);

	return abs(value);
}

int MKLinearFeaturesConvoluteKernelY (const unsigned char *buffer, short x, short y, const int width, const int height) {
	int value = -3 * MKImageProcessingGetUnsignedCharValue(buffer, x , y - 2, width, height);
	value += -5 * MKImageProcessingGetUnsignedCharValue(buffer, x, y - 1, width, height);
	value += 5 * MKImageProcessingGetUnsignedCharValue(buffer, x, y + 1, width, height);
	value += 3 * MKImageProcessingGetUnsignedCharValue(buffer, x, y + 2, width, height);

	return abs(value);
}

vector_t MKLinearFeaturesGradientIntensity (const unsigned char* buffer, const unsigned int width, const unsigned int height, const int x, const int y) {
	
	int gx = MKImageProcessingGetUnsignedCharValue(buffer, (x - 1), (y - 1), width, height);
	gx += MKImageProcessingGetUnsignedCharValue(buffer, x, (y - 1), width, height) * 2;
	gx += MKImageProcessingGetUnsignedCharValue(buffer, (x + 1), (y - 1), width, height);
	
	gx -= MKImageProcessingGetUnsignedCharValue(buffer, (x - 1), (y + 1), width, height);
	gx -= MKImageProcessingGetUnsignedCharValue(buffer, x, (y + 1), width, height) * 2;
	gx -= MKImageProcessingGetUnsignedCharValue(buffer, (x + 1), (y + 1), width, height);
	
	
	int gy = MKImageProcessingGetUnsignedCharValue(buffer, (x - 1), (y - 1), width, height);
	gy += MKImageProcessingGetUnsignedCharValue(buffer, (x - 1), y, width, height) * 2;
	gy += MKImageProcessingGetUnsignedCharValue(buffer, (x - 1), (y + 1), width, height);
	
	gy -= MKImageProcessingGetUnsignedCharValue(buffer, (x + 1), (y - 1), width, height);
	gy -= MKImageProcessingGetUnsignedCharValue(buffer, (x + 1), y, width, height) * 2;
	gy -= MKImageProcessingGetUnsignedCharValue(buffer, (x + 1), (y + 1), width, height);

	vector_t slope;
	Vector2fSetCoordinate(&slope, gy, gx);
	Vector2fGetNormalized(&slope);

	return slope;
}

void MKLinearFeaturesExtendLineSegment (linesegmentPool_t* lines, const unsigned char* buffer) {

	const int lineCount = MKLineSegmentGetLineCount(lines);
	for (int i = 0; i < lineCount; i++) {

		linesegment_t line = MKLineSegmentGetLineSegment(lines, i);
		vector_t slope = line.slope;

		MKLinearFeaturesExtendLine(line.end.coordinate,
								   slope,
								   line.end.slope,
								   &line.end.coordinate,
								   999,
								   buffer);

		slope.x *= -1;
		slope.y *= -1;

		MKLinearFeaturesExtendLine(line.end.coordinate,
								   slope,
								   line.end.slope,
								   &line.end.coordinate,
								   999,
								   buffer);
	}
}

bool MKLinearFeaturesExtendLine (vector_t start, const vector_t slope, const vector_t gradient, vector_t *end, const int maxLength, const unsigned char* buffer) {

	const vector_t normal	= {slope.y, -slope.x};
	bool merge				= true;

	for (int i = 0; i < maxLength; i++) {
		start = Vector2fAddition(start, slope);

		// 640 pixel width, 480 pixel height, refactor to variables
		if (MKLinearFeaturesConvoluteKernelX(buffer, start.x, start.y, 640, 480) < kThreshold/2 &&
			MKLinearFeaturesConvoluteKernelY(buffer, start.x, start.y, 640, 480) < kThreshold/2 ) {
			merge = false;
			break;
		}

		vector_t intensity = MKLinearFeaturesGradientIntensity(buffer, 640, 480, start.x, start.y);
		float tmp = Vector2fDotProduct(intensity, gradient);
		if ( tmp > 0.38f) {
			continue;
		}

		intensity = MKLinearFeaturesGradientIntensity(buffer, 640, 480, start.x + normal.x, start.y + normal.y);
		tmp = Vector2fDotProduct(intensity, gradient);
		if ( tmp > 0.38f) {
			continue;
		}

		intensity = MKLinearFeaturesGradientIntensity(buffer, 640, 480, start.x - normal.x, start.y - normal.y);
		tmp = Vector2fDotProduct(intensity, gradient);
		if ( tmp > 0.38f) {
			continue;
		}

		merge = false;
		break;
	}

	*end = Vector2fSubtract(start, slope);
	return merge;
}

#pragma mark -
#pragma mark Memory Management

- (void)dealloc {

	free(monochromeBuffer);
	MKEdgelFreeMemoryPool(edgels);
	MKLineSegmentFreeMemoryPool(linesegments);
	MKLineSegmentFreeMemoryPool(mergedLines);
	MKLineSegmentFreeMemoryPool(lineChains);
	MKMarkerFreeMemoryPool(markers);

	[super dealloc];
}

@end
