//
//  Canvas.m
//  TestDraw
//
//  Created by Johan Bilien on 7/12/11.
//

#import "Canvas.h"

@interface TouchPath : NSObject {
}

@property CGPoint pointNMinus2;
@property CGPoint controlPoint2NMinus2;

@end

@implementation TouchPath

@synthesize pointNMinus2;
@synthesize controlPoint2NMinus2;

- (id) init
{
    if ((self = [super init])) {
        self.pointNMinus2 = CGPointMake(-1, -1);
        self.controlPoint2NMinus2 = CGPointMake(-1, -1);
    }
    
    return self;
}

@end


@implementation Canvas

@synthesize content=_content;

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    
    if (self) {
        self.backgroundColor = [UIColor whiteColor];
        self.multipleTouchEnabled = YES;
        
        _activeTouches = [[[NSMutableDictionary alloc] initWithCapacity:11] retain];
    }
    
    return self;
}

- (void)setFrame:(CGRect)frame
{
    [super setFrame:frame];
        
    if (_imageContext) {
        free(_imageData);
        _imageData = NULL;
        
        CGContextRelease(_imageContext);
        _imageContext = 0;
    }

    if (frame.size.width &&
        frame.size.height) {
        CGColorSpaceRef rgb;
        
        _imageData = malloc(frame.size.width * frame.size.height * 4);
        
        rgb = CGColorSpaceCreateDeviceRGB();
        _imageContext = CGBitmapContextCreate(_imageData,
                                              frame.size.width, frame.size.height,
                                              8, frame.size.width * 4, rgb,
                                              kCGImageAlphaPremultipliedLast|
                                              kCGBitmapByteOrder32Big);
        CGColorSpaceRelease(rgb);
        
        CGContextSetRGBStrokeColor(_imageContext, 1, 0, 0, 1);
        CGContextSetLineWidth(_imageContext, 4);
        CGContextSetLineCap(_imageContext, kCGLineCapRound);
        CGContextSetLineJoin(_imageContext, kCGLineJoinBevel);
    }
}

- (void)drawRect:(CGRect)rect
{
    CGContextRef ctx = UIGraphicsGetCurrentContext();
    CGImageRef image = CGBitmapContextCreateImage(_imageContext);
    
    CGContextDrawImage(ctx, self.bounds, image);
    
    CGImageRelease(image);
}

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    NSEnumerator *enumerator = [touches objectEnumerator];
    UITouch *touch;
    
    while ((touch = [enumerator nextObject])) {
        TouchPath *path;
        NSValue *key;
        
        path = [[TouchPath alloc] init];
        key = [NSValue valueWithPointer:touch];
        [_activeTouches setObject:path forKey:key];
        [path release];
    }
}

- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event
{
    NSEnumerator *enumerator = [touches objectEnumerator];
    UITouch *touch;
    
    while ((touch = [enumerator nextObject])) {
        NSValue *key = [NSValue valueWithPointer:touch];
        TouchPath *path = [_activeTouches objectForKey:key];
        
        if (!path) {
            NSLog(@"No active touch for moved touch?");
            continue;
        }
        
        
        CGPoint now = [touch locationInView:self];
        CGPoint previous = [touch previousLocationInView:self];
        
        if (path.pointNMinus2.x == -1) {
            path.pointNMinus2 = previous;
            path.controlPoint2NMinus2 = previous;
            continue;
        }

        /* Normalizing the control point so that it's a distance of 1 from the previous point */
        /*
        CGFloat d1 = sqrtf((previous.x - path.previousControlPoint.x)*(previous.x - path.previousControlPoint.x) +
                          (previous.y - path.previousControlPoint.y)*(previous.y - path.previousControlPoint.y));
        CGFloat d2 = sqrtf((previous.x - now.x)*(previous.x - now.x) +
                           (previous.y - now.y)*(previous.y - now.y));*/
    
        CGPoint controlPoint1 = { path.pointNMinus2.x + (path.pointNMinus2.x - path.controlPoint2NMinus2.x),
                                  path.pointNMinus2.y + (path.pointNMinus2.y - path.controlPoint2NMinus2.y) };
                                                         
        CGPoint controlPoint2 = { previous.x - (now.x - path.pointNMinus2.x),
                                  previous.y - (now.y - path.pointNMinus2.y) };

        CGRect rect = CGRectMake(MIN(previous.x, path.pointNMinus2.x) - 20,
                                 MIN(previous.y, path.pointNMinus2.y) - 20,
                                 ABS(previous.x - path.pointNMinus2.x) + 40,
                                 ABS(previous.y - path.pointNMinus2.y) + 40);
 
        CGContextMoveToPoint(_imageContext, path.pointNMinus2.x, path.pointNMinus2.y);
        CGContextAddCurveToPoint(_imageContext,
                                 controlPoint1.x, controlPoint1.y,
                                 controlPoint2.x, controlPoint2.y,
                                 previous.x, previous.y);
        
        CGContextStrokePath(_imageContext);
        
        path.pointNMinus2 = previous;
        path.controlPoint2NMinus2 = controlPoint2;
        
        [self setNeedsDisplayInRect:rect];
    }
}

- (void) touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
    NSEnumerator *enumerator = [touches objectEnumerator];
    UITouch *touch;
        
    while ((touch = [enumerator nextObject])) {
        NSValue *key = [NSValue valueWithPointer:touch]; 
        [_activeTouches removeObjectForKey:key];
    }
}

- (void)dealloc
{
    [_activeTouches release];
    _activeTouches = nil;
    
    [super dealloc];
}

@end
