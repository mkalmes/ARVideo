#import "MKMarker.h"

#define POOLSIZE 1

static markerPool_t		poolData[POOLSIZE];
static markerPool_t*	poolPointer = poolData;

markerPool_t* MKMarkerGetMemoryPools (size_t numberOfPools) {

	if (poolData + POOLSIZE - poolPointer >= numberOfPools) {
		poolPointer += numberOfPools;
		return poolPointer - numberOfPools;
	} else {
		return NULL;
	}
}

markerPool_t* MKMarkerGetMemoryPool (void) {
	return MKMarkerGetMemoryPools(1);
}

void MKMarkerFreeMemoryPool (markerPool_t* pool) {

	if (!pool) {
		return;
	}

	MKMarkerResetMemoryPool(pool);

	if (pool >= poolData && pool <= poolData + POOLSIZE) {
		poolPointer = pool;
	}
}

void MKMarkerResetMemoryPool (markerPool_t* pool) {

	if (!pool) {
		return;
	}

	pool->count = 0;
}

int MKMarkerGetMarkerCount (markerPool_t* pool) {

	if (!pool) {
		return -1;
	}

	return pool->count;
}

void MKMarkerAddMarker (markerPool_t* pool, marker_t marker) {

	if (!pool) {
		return;
	}

	int count = pool->count;
	if (!(count < MARKERSIZE)) {
		return;
	}

	pool->data[count++] = marker;
	pool->count = count;
}

marker_t MKMarkerGetMarker (markerPool_t* pool, unsigned int index) {

	marker_t error = {
		{-1.0f, -1.0f}, {-1.0f, -1.0f},
		{-1.0f, -1.0f}, {-1.0f, -1.0f}
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
