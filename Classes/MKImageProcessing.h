static inline unsigned char MKImageProcessingGetUnsignedCharValue (const unsigned char* buffer, short x, short y, const int width, const int height) {
	if (x < 0) {
		x = 0;
	}

	if (y < 0) {
		y = 0;
	}

	if (x >= width) {
		x = (width - 1);
	}

	if (y >= height) {
		y = (height - 1);
	}

	const unsigned int offset = x + (y * width);
	return *(buffer + offset);
}