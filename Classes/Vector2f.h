#import <math.h>

typedef struct vector_s {
	float x;
	float y;
} vector_t;

static inline void Vector2fSetCoordinate (vector_t *vector, const float x, const float y) {
	vector->x = x;
	vector->y = y;
}

static inline float Vector2fGetSquaredLength (vector_t *vector) {
	return (vector->x * vector->x) + (vector->y * vector->y);
}

static inline float Vector2fGetLength (vector_t *vector) {
	return sqrtf(Vector2fGetSquaredLength(vector));
}

static inline void Vector2fGetNormalized (vector_t *vector) {
	float invertedLength = 1.0f / Vector2fGetLength(vector);
	vector->x *= invertedLength;
	vector->y *= invertedLength;
}

static inline float Vector2fDotProduct (vector_t left, vector_t right) {
	return (left.x * right.x) + (left.y * right.y);
}

static inline vector_t Vector2fSubtract (vector_t left, vector_t right) {
	vector_t vector;
	Vector2fSetCoordinate(&vector, left.x - right.x, left.y - right.y);
	return vector;
}

static inline vector_t Vector2fAddition (vector_t left, vector_t right) {
	vector_t vector;
	Vector2fSetCoordinate(&vector, left.x + right.x, left.y + right.y);
	return vector;
}
