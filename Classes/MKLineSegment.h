#import "MKEdgel.h"

#define MAXEDGELS 32
#define LINESIZE 512

typedef struct linesegment_s {
	edgel_t start;
	edgel_t end;
	vector_t slope;
	int supportCount;
	bool remove;
	bool startCorner;
	bool endCorner;
	edgel_t support[MAXEDGELS];
} linesegment_t;

// Line Memory Pool
typedef struct linesegmentPool_s {
	linesegment_t	data[LINESIZE];
	int				count;
} linesegmentPool_t;

typedef struct linesegmentDistance_s {
	float	distance;
	int		index;
} linesegmentDistance_t;

typedef struct distancePool_s {
	linesegmentDistance_t data[LINESIZE];
	int		count;
} distancePool_t;

bool MKLineSegmentIsEdgelNearLine (linesegment_t line, edgel_t edgel);
bool MKLineSegmentIsOrientationCompatible(linesegment_t left, linesegment_t right);
void MKLineSegmentAddEdgel (linesegment_t *line, edgel_t edgel, int pos);
vector_t MKLineSegmentIntersection(linesegment_t left, linesegment_t right);

linesegmentPool_t* MKLineSegmentGetMemoryPools (size_t numberOfPools);
linesegmentPool_t* MKLineSegmentGetMemoryPool (void);
void MKLineSegmentFreeMemoryPool (linesegmentPool_t* pool);
void MKLineSegmentResetMemoryPool (linesegmentPool_t* pool);
int MKLineSegmentGetLineCount (linesegmentPool_t* pool);
void MKLineSegmentAddLine (linesegmentPool_t* pool, linesegment_t line);
linesegment_t MKLineSegmentGetLineSegment (linesegmentPool_t* pool, unsigned int index);
int MKLineSegmentDistanceCompare (const void* a, const void* b);
int MKLineSegmentDistanceGetDistanceCount (distancePool_t* pool);
void MKLineSegmentDistanceAddToPool (distancePool_t *pool, linesegmentDistance_t distance);
void MKLineSegmentDistanceFreePool (distancePool_t *pool);
void MKLineSegmentRemoveLine (linesegmentPool_t* pool, const int index);
