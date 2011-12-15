#import "Vector2f.h"

#define MARKERSIZE	16

typedef struct marker_s {
	vector_t c1;
	vector_t c2;
	vector_t c3;
	vector_t c4;
} marker_t;

typedef struct markerPool_s {
	marker_t	data[MARKERSIZE];
	int			count;
} markerPool_t;


markerPool_t* MKMarkerGetMemoryPools (size_t numberOfPools);

markerPool_t* MKMarkerGetMemoryPool (void);

void MKMarkerFreeMemoryPool (markerPool_t* pool);

void MKMarkerResetMemoryPool (markerPool_t* pool);

int MKMarkerGetMarkerCount (markerPool_t* pool);

void MKMarkerAddMarker (markerPool_t* pool, marker_t marker);

marker_t MKMarkerGetLineSegment (markerPool_t* pool, unsigned int index);
