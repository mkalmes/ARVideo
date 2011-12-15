#import <UIKit/UIKit.h>

@class ARVideoViewController;

@interface ARVideoAppDelegate : NSObject <UIApplicationDelegate> {
    UIWindow *window;
    ARVideoViewController *viewController;
}

@property (nonatomic, retain) IBOutlet UIWindow *window;
@property (nonatomic, retain) IBOutlet ARVideoViewController *viewController;

@end

