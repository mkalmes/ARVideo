#import "Vector2f.h"

#define DATASIZE 8192

typedef struct edgel_s {
	vector_t	coordinate;
	vector_t	slope;
} edgel_t;

typedef struct edgelPool_s {
	edgel_t		data[DATASIZE];
	int			count;
} edgelPool_t;

bool MKEdgelIsCompatible (edgel_t first, edgel_t last);

edgelPool_t* MKEdgelGetMemoryPools (size_t numberOfPools);

edgelPool_t* MKEdgelGetMemoryPool (void);

void MKEdgelFreeMemoryPool (edgelPool_t* pool);

void MKEdgelResetMemoryPool (edgelPool_t* pool);

// Returns the number of edgels in pool.
// Returns -1 if an error occured.
unsigned int MKEdgelGetEdgelCount (edgelPool_t* pool);

void MKEdgelAddEdgel (edgelPool_t* pool, edgel_t edgel);

// Returns the edgel at index from pool.
// Returns {-1, -1, -1.0} if an error occured.
edgel_t MKEdgelGetEdgel (edgelPool_t* pool, unsigned int index);

int MKEdgelEdgelPosition (edgelPool_t* pool, edgel_t edgel);

void MKEdgelRemoveEdgel (edgelPool_t* pool, edgel_t edgel);
