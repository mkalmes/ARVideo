#import "MKLineSegment.h"

#define POOLSIZE 3

static linesegmentPool_t	poolData[POOLSIZE];
static linesegmentPool_t*	poolPointer = poolData;

bool MKLineSegmentIsEdgelNearLine (linesegment_t line, edgel_t edgel) {
	if (!MKEdgelIsCompatible(line.start, edgel)) {
		return NO;
	}

	// AB x AC / |AB|
	// AB = Vektor der Ortsvektoren A und B  -  Bx - Ax, By - Ay
	// AC = Vektor der Ortsvektoren A und C  -  Cx - Ax, Cy - Ay
	// AB x AC = Kreuzprodukt der Vektoren  -  (AB1 * AC2) - (AC1 * AB2)
	// |AB| = c^2 = a^2 + b^2  -  Pythagorean theorem

	const edgel_t lineStart	= line.start;
	const edgel_t lineEnd	= line.end;

	const float a = (lineEnd.coordinate.x - lineStart.coordinate.x);
	const float b = (lineEnd.coordinate.y - lineStart.coordinate.y);
	const float c = sqrtf( (a * a) + (b * b) );

	float crossproduct = ((lineEnd.coordinate.x - lineStart.coordinate.x) * (edgel.coordinate.y - lineStart.coordinate.y)) -
	((edgel.coordinate.x - lineStart.coordinate.x) * (lineEnd.coordinate.y - lineStart.coordinate.y));
	float distance = ABS((crossproduct / c));

	return distance < 0.75f;
}

bool MKLineSegmentIsOrientationCompatible(linesegment_t left, linesegment_t right) {
	return Vector2fDotProduct(left.slope, right.slope) > 0.92f; //0.38f; //cosf( 67.5f / 2 pi )
}

void MKLineSegmentAddEdgel (linesegment_t *line, edgel_t edgel, int pos) {
	if (pos > MAXEDGELS - 1) {
		printf("Error: to many supporting edgels\n");
	}

	line->support[pos] = edgel;
}

vector_t MKLineSegmentIntersection(linesegment_t left, linesegment_t right) {

	vector_t intersection;

	const float x1 = left.start.coordinate.x;
	const float y1 = left.start.coordinate.y;
	const float x2 = left.end.coordinate.x;
	const float y2 = left.end.coordinate.y;

	const float x3 = right.start.coordinate.x;
	const float y3 = right.start.coordinate.y;
	const float x4 = right.end.coordinate.x;
	const float y4 = right.end.coordinate.y;

	const float numerator	= ((x4 - x3) * (y1 - y3)) - ((y4 - y3) * (x1 - x3));
	const float denumerator	= ((y4 - y3) * (x2 - x1)) - ((x4 - x3) * (y2 - y1));
	const float u_a			= numerator / denumerator;

	intersection.x = x1 + u_a * (x2 - x1);
	intersection.y = y1 + u_a * (y2 - y1);

	return intersection;
}

linesegmentPool_t* MKLineSegmentGetMemoryPools (size_t numberOfPools) {
	if (poolData + POOLSIZE - poolPointer >= numberOfPools) {
		poolPointer += numberOfPools;
		return poolPointer - numberOfPools;
	} else {
		return NULL;
	}
}

linesegmentPool_t* MKLineSegmentGetMemoryPool (void) {
	return MKLineSegmentGetMemoryPools(1);
}

void MKLineSegmentFreeMemoryPool (linesegmentPool_t* pool) {
	if (!pool) {
		return;
	}

	MKLineSegmentResetMemoryPool(pool);

	if (pool >= poolData && pool <= poolData + POOLSIZE) {
		poolPointer = pool;
	}
}

void MKLineSegmentResetMemoryPool (linesegmentPool_t* pool) {
	if (!pool) {
		return;
	}

	pool->count = 0;
}

int MKLineSegmentGetLineCount (linesegmentPool_t* pool) {
	if (!pool) {
		return -1;
	}

	return pool->count;
}

void MKLineSegmentAddLine (linesegmentPool_t* pool, linesegment_t line) {
	if (!pool) {
		return;
	}

	int count = pool->count;
	if (!(count < LINESIZE)) {
		return;
	}

	pool->data[count++] = line;
	pool->count = count;
}

linesegment_t MKLineSegmentGetLineSegment (linesegmentPool_t* pool, unsigned int index) {
	linesegment_t error = {
		{{-1.0f, -1.0f},{-1.0f, -1.0f}},
		{{-1.0f, -1.0f},{-1.0f, -1.0f}},
		{-1.0f, -1.0f}
	};

	if (!pool) {
		return error;
	}

	int count = pool->count;
	if (!(count > index)) {
		return error;
	}

	return pool->data[index];
}

int MKLineSegmentDistanceCompare (const void* a, const void* b) {
	linesegmentDistance_t *ad = (linesegmentDistance_t *)a;
	linesegmentDistance_t *bd = (linesegmentDistance_t *)b;

	return (int) (ad->distance - bd->distance);
}

int MKLineSegmentDistanceGetDistanceCount (distancePool_t* pool) {
	if (!pool) {
		return -1;
	}

	return pool->count;
}

void MKLineSegmentDistanceAddToPool (distancePool_t *pool, linesegmentDistance_t distance) {

	if (!pool) {
		return;
	}

	int count = pool->count;
	if (!(count < LINESIZE)) {
		return;
	}

	pool->data[count++] = distance;
	pool->count = count;
}

void MKLineSegmentDistanceFreePool (distancePool_t *pool) {

	if (!pool) {
		return;
	}

	pool->count = 0;
}

void MKLineSegmentRemoveLine (linesegmentPool_t* pool, const int index) {

	if (!pool) {
		return;
	}

	const int count = pool->count;

	if (index < 0 || index > count) {
		return;
	}

	if(count > index + 1) {
		memmove(&pool->data[index], &pool->data[index + 1] , (count - (index + 1)) * sizeof(linesegment_t) );
	}
	pool->count--;
}
