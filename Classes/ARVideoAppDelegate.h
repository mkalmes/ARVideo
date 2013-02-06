#import <UIKit/UIKit.h>

@class ARVideoViewController;

@interface ARVideoAppDelegate : NSObject <UIApplicationDelegate> {
    UIWindow *window;
    ARVideoViewController *viewController;
}

@property (nonatomic, strong) IBOutlet UIWindow *window;
@property (nonatomic, strong) IBOutlet ARVideoViewController *viewController;

@end

