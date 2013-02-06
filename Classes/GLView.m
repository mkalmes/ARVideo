#import <OpenGLES/EAGLDrawable.h>
#import <QuartzCore/QuartzCore.h>

#import "GLView.h"

#define GLdebug(e) \
{	\
	glGetError();	\
	((void) ((e))); \
	GLenum error = glGetError(); \
	if (error != GL_NO_ERROR) {	\
		printf("%s:%d error code %d\n", __FILE__, __LINE__, error);	\
	} \
}	\


const int kMaxLinesegments	= 8192 * 2; // 8192 Lines w/ 2 vertices


@interface GLView (GLRenderer)

- (void)setupGLView;
- (void)renderLines;
- (void)renderGLView;
- (BOOL)createFramebuffer;
- (void)createVertexBuffer;
- (void)updateVertexBuffer;
- (void)destroyFramebuffer;
- (void)destroyVertexBuffer;
- (void)clearVertexBuffer;

@end


@implementation GLView (GLRenderer)

- (void)setupGLView {

	glDisable(GL_DEPTH_TEST);

	float aspectRatio	= self.bounds.size.width / self.bounds.size.height;
	float imageWidth	= 640.0f / aspectRatio;
	float screenOffset	= (self.bounds.size.width - imageWidth) / 2.0f;
	glViewport((GLint)screenOffset, 0, self.bounds.size.width, self.bounds.size.height);
	// setup projection
	glMatrixMode(GL_PROJECTION);
	glLoadIdentity();
	glOrthof(0.0f, self.bounds.size.width, self.bounds.size.height, 0.0f, -1.0f, 1.0f);

	glMatrixMode(GL_MODELVIEW);

	glEnable(GL_NORMALIZE);
}

- (void)renderLines {

	glLineWidth(2);
	const int numberOfLines = ([self.drawModel length] / sizeof(linemodel_vertex_t));
	glBindBuffer(GL_ARRAY_BUFFER, linesVBO);
	glVertexPointer(2, GL_FLOAT, sizeof(linemodel_vertex_t), 0);
	glColorPointer(4, GL_UNSIGNED_BYTE, sizeof(linemodel_vertex_t), (GLvoid*)8);
	glDrawArrays(GL_LINES, 0, numberOfLines);
}

- (void)renderGLView {

	[EAGLContext setCurrentContext:self.context];
	glBindFramebufferOES(GL_FRAMEBUFFER_OES, viewFramebuffer);

	glLoadIdentity();
	glClearColor(0.0f, 0.0f, 0.0f, 0.0f);
	glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);

	// Enable states
	glEnableClientState(GL_VERTEX_ARRAY);
	glEnableClientState(GL_COLOR_ARRAY);

	[self renderLines];

	// disable states
	glDisableClientState(GL_VERTEX_ARRAY);
	glDisableClientState(GL_COLOR_ARRAY);

	glBindRenderbufferOES(GL_RENDERBUFFER_OES, viewRenderbuffer);
	[self.context presentRenderbuffer:GL_RENDERBUFFER_OES];
}

- (BOOL)createFramebuffer {

	// Generate two identifiers for a framebuffer and a renderbuffer
	glGenFramebuffersOES(1, &viewFramebuffer);
	glGenRenderbuffersOES(1, &viewRenderbuffer);

	glBindFramebufferOES(GL_FRAMEBUFFER_OES, viewFramebuffer);
	glBindRenderbufferOES(GL_RENDERBUFFER_OES, viewRenderbuffer);

	[self.context renderbufferStorage:GL_RENDERBUFFER_OES fromDrawable:(id <EAGLDrawable>)self.layer];
	glFramebufferRenderbufferOES(GL_FRAMEBUFFER_OES, GL_COLOR_ATTACHMENT0_OES, GL_RENDERBUFFER_OES, viewRenderbuffer);

	glGetRenderbufferParameterivOES(GL_RENDERBUFFER_OES, GL_RENDERBUFFER_HEIGHT_OES, &backingHeight);
	glGetRenderbufferParameterivOES(GL_RENDERBUFFER_OES, GL_RENDERBUFFER_WIDTH_OES, &backingWidth);

	// We use a depth buffer
	glGenFramebuffersOES(1, &depthRenderbuffer);
	glBindRenderbufferOES(GL_RENDERBUFFER_OES, depthRenderbuffer);
	glRenderbufferStorageOES(GL_RENDERBUFFER_OES, GL_DEPTH_COMPONENT16_OES, backingWidth, backingHeight);
	glFramebufferRenderbufferOES(GL_FRAMEBUFFER_OES, GL_DEPTH_ATTACHMENT_OES, GL_RENDERBUFFER_OES, depthRenderbuffer);

	if (glCheckFramebufferStatusOES(GL_FRAMEBUFFER_OES) != GL_FRAMEBUFFER_COMPLETE_OES) {
		NSLog(@"failed to make complete framebuffer object %x", glCheckFramebufferStatusOES(GL_FRAMEBUFFER_OES));
        return NO;
	}

	return YES;
}

- (void)createVertexBuffer {

	glGenBuffers(1, &linesVBO);
	glBindBuffer(GL_ARRAY_BUFFER, linesVBO);
	glBufferData(GL_ARRAY_BUFFER, sizeof(linemodel_vertex_t) * kMaxLinesegments, 0, GL_DYNAMIC_DRAW);

}

- (void)updateVertexBuffer {

	glBindBuffer(GL_ARRAY_BUFFER, linesVBO);
	glBufferSubData(GL_ARRAY_BUFFER, 0, [self.drawModel length], (GLvoid*)[self.drawModel bytes]);
}

- (void)destroyFramebuffer {
	glDeleteFramebuffersOES(1, &viewFramebuffer);
	viewFramebuffer = 0;
	glDeleteRenderbuffersOES(1, &viewRenderbuffer);
	viewRenderbuffer = 0;

	glDeleteRenderbuffersOES(1, &depthRenderbuffer);
	depthRenderbuffer = 0;
}

- (void)destroyVertexBuffer {

	glDeleteBuffers(1, &linesVBO);

}

- (void)clearVertexBuffer {

//	glBindBuffer(GL_ARRAY_BUFFER, linesVBO);
//	glBufferData(GL_ARRAY_BUFFER, sizeof(linemodel_vertex_t) * kMaxLinesegments, 0, GL_DYNAMIC_DRAW);
}

@end


@interface GLView ()

@property (nonatomic, retain, readwrite) CADisplayLink *displayLink;

- (void)drawScene:(CADisplayLink *)sender;

- (void)createGridModel;

@end


@implementation GLView

@synthesize displayLink;
@synthesize drawModel;
@synthesize gridModel;
@synthesize context;

#pragma mark -
#pragma mark Init

+ (Class)layerClass {
	return [CAEAGLLayer class];
}

- (id)initWithCoder:(NSCoder *)coder {

	self = [super initWithCoder:coder];
	if (!self) {
		return nil;
	}

	CAEAGLLayer* eaglLayer = (CAEAGLLayer*)self.layer;

	eaglLayer.opaque = NO;
	eaglLayer.drawableProperties = @{kEAGLDrawablePropertyRetainedBacking: @NO, kEAGLDrawablePropertyColorFormat: kEAGLColorFormatRGBA8};

	eaglLayer.contentsGravity = kCAGravityResizeAspectFill;
	eaglLayer.transform = CATransform3DRotate(CATransform3DIdentity, M_PI/2.0f, 0, 0, 1);
	eaglLayer.frame = self.bounds;

	self.context = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES1];

	if (!self.context || ![EAGLContext setCurrentContext:self.context]) {
		[self release];
		return nil;
	}

	self.displayLink = [CADisplayLink displayLinkWithTarget:self selector:@selector(drawScene:)];
	self.displayLink.frameInterval = 12;
	[self.displayLink addToRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];

	// Add model for grid
	[self createGridModel];

	return self;
}

- (void)setupView {
	[self setupGLView];
}

#pragma mark -
#pragma mark Drawing

- (void)layoutSubviews {

	[EAGLContext setCurrentContext:self.context];
	[self destroyFramebuffer];
	[self createFramebuffer];

	[self destroyVertexBuffer];
	[self createVertexBuffer];
}

- (void)drawScene:(CADisplayLink *)sender {
	[self renderGLView];
}

#pragma mark -
#pragma mark Model

- (void)updateModelCacheData:(NSData*)data {

	self.drawModel = data;
	[self updateVertexBuffer];
}

- (void)clearModelCache {
	[self clearVertexBuffer];
}

- (void)createGridModel {

	NSMutableData *gridData = [NSMutableData data];

	const int width			= 640;
	const int height		= 480;
	const float aspectRatio	= self.bounds.size.width / self.bounds.size.height;

	for (int i = 1; i < width; i += 40) {

		linemodel_vertex_t start;
		start.coordinate[0]	= i / aspectRatio;
		start.coordinate[1]	= 0;
		start.color[0]		= 203;
		start.color[1]		= 203;
		start.color[2]		= 203;
		start.color[3]		= 0;

		linemodel_vertex_t end;
		end.coordinate[0]	= i / aspectRatio;
		end.coordinate[1]	= height / aspectRatio;
		end.color[0]		= 203;
		end.color[1]		= 203;
		end.color[2]		= 203;
		end.color[3]		= 0;

		[gridData appendBytes:&start length:sizeof(linemodel_vertex_t)];
		[gridData appendBytes:&end length:sizeof(linemodel_vertex_t)];
	}

	for (int j = 1; j < height; j += 40) {

		linemodel_vertex_t start;
		start.coordinate[0]	= 0;
		start.coordinate[1]	= j / aspectRatio;
		start.color[0]		= 203;
		start.color[1]		= 203;
		start.color[2]		= 203;
		start.color[3]		= 0;

		linemodel_vertex_t end;
		end.coordinate[0]	= width / aspectRatio;
		end.coordinate[1]	= j / aspectRatio;
		end.color[0]		= 203;
		end.color[1]		= 203;
		end.color[2]		= 203;
		end.color[3]		= 0;

		[gridData appendBytes:&start length:sizeof(linemodel_vertex_t)];
		[gridData appendBytes:&end length:sizeof(linemodel_vertex_t)];
	}

	self.gridModel = [NSData dataWithData:gridData];
}

#pragma mark -
#pragma mark Memory Management

- (void)dealloc {
	if ([EAGLContext currentContext] == self.context) {
		[EAGLContext setCurrentContext:nil];
	}
	self.context = nil;

	[self.displayLink invalidate];
	self.displayLink = nil;

	self.drawModel = nil;
	self.gridModel = nil;

    [super dealloc];
}

@end
