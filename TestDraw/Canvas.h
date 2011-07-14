//
//  Canvas.h
//  TestDraw
//
//  Created by Johan Bilien on 7/12/11.
//

#import <UIKit/UIKit.h>


@interface Canvas : UIView {
@private
    CGContextRef _imageContext;
    void *_imageData;
    NSMutableDictionary *_activeTouches;
}

@property (nonatomic, readonly) CGImageRef content;

@end
