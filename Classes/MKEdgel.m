#include "MKEdgel.h"

#define POOLSIZE 2

static edgelPool_t	poolData[POOLSIZE];
static edgelPool_t*	poolPointer = poolData;

bool MKEdgelIsCompatible (edgel_t left, edgel_t right) {
	return Vector2fDotProduct(left.slope, right.slope) > 0.38f; // 0.38f = cos(67.5 deg) as deg
}

edgelPool_t* MKEdgelGetMemoryPools (size_t numberOfPools) {
	if (poolData + POOLSIZE - poolPointer >= numberOfPools) {
		poolPointer += numberOfPools;
		return poolPointer - numberOfPools;
	} else {
		return NULL;
	}
}

edgelPool_t* MKEdgelGetMemoryPool (void) {
	return MKEdgelGetMemoryPools(1);
}

void MKEdgelFreeMemoryPool (edgelPool_t* pool) {
	if (!pool) {
		return;
	}
	MKEdgelResetMemoryPool(pool);
	if (pool >= poolData && pool <= poolData + POOLSIZE) {
		poolPointer = pool;
	}
}

void MKEdgelResetMemoryPool (edgelPool_t* pool) {
	if (!pool) {
		return;
	}
	pool->count = 0;
}

unsigned int MKEdgelGetEdgelCount (edgelPool_t* pool) {
	if (!pool) {
		return 0;
	}
	return pool->count;
}

void MKEdgelAddEdgel (edgelPool_t* pool, edgel_t edgel) {
	if (!pool) {
		return;
	}
	int count = pool->count;
	if (!(count < DATASIZE)) {
		printf("Edgel-Speicher voll\n");
		return;
	}
	pool->data[count++] = edgel;
	pool->count = count;
}

edgel_t MKEdgelGetEdgel (edgelPool_t* pool, unsigned int index) {
	edgel_t error = {-1, -1, -1.0};

	if (!pool) {
		return error;
	}
	int count = pool->count;
	if (!(count > index)) {
		return error;
	}
	return pool->data[index];
}

int MKEdgelEdgelPosition (edgelPool_t* pool, edgel_t edgel) {
	if (!pool) {
		return -1;
	}

	const int edgels	= pool->count;
	const float slopex	= edgel.slope.x;
	const float slopey	= edgel.slope.y;
	const float x		= edgel.coordinate.x;
	const float y		= edgel.coordinate.y;

	for (int i = 0; i < edgels; i++) {
		edgel_t compare = pool->data[i];
		if (slopex == compare.slope.x &&
			slopey == compare.slope.y &&
			x == compare.coordinate.x &&
			y == compare.coordinate.y) {
			return i;
		}
	}
	return -1;
}

void MKEdgelRemoveEdgel (edgelPool_t* pool, edgel_t edgel) {
	int position = MKEdgelEdgelPosition(pool, edgel);
	if (position < 0) {
		return;
	}

	const int count = pool->count;

	if(count > position + 1) {
		memmove(&pool->data[position], &pool->data[position + 1] , (count - (position + 1)) * sizeof(edgel_t) );
	}
	pool->count--;
}
