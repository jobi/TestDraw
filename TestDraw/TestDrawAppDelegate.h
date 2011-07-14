//
//  TestDrawAppDelegate.h
//  TestDraw
//
//  Created by Johan Bilien on 7/12/11.
//

#import <UIKit/UIKit.h>

@class CanvasController;

@interface TestDrawAppDelegate : NSObject <UIApplicationDelegate> {

}

@property (nonatomic, retain) IBOutlet UIWindow *window;
@property (nonatomic, retain) CanvasController *canvasController;

@end
