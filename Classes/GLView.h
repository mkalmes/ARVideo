#import <UIKit/UIKit.h>
#import <OpenGLES/EAGL.h>
#import <OpenGLES/ES1/gl.h>
#import <OpenGLES/ES1/glext.h>
#import "MKEdgel.h"
#import "MKLineSegment.h"


// Multiple of 4 bytes
typedef struct linemodel_vertex_s {
	GLfloat coordinate[2];
	GLubyte color[4];
	GLfloat padding[1];
} linemodel_vertex_t;


@interface GLView : UIView {

	GLint backingWidth;
	GLint backingHeight;

	GLuint viewFramebuffer;
	GLuint viewRenderbuffer;
	GLuint depthRenderbuffer;

	GLuint linesVBO;
}

@property (nonatomic, strong) EAGLContext *context;
@property (nonatomic, strong) NSData *drawModel;
@property (nonatomic, strong) NSData *gridModel;

- (void)setupView;

// Update the model cache
- (void)updateModelCacheData:(NSData*)data;

// Clear the model cache
- (void)clearModelCache;

@end
