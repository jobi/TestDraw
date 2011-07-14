//
//  Canvas.m
//  TestDraw
//
//  Created by Johan Bilien on 7/12/11.
//

#import "Canvas.h"

@interface TouchPath : NSObject {
}

@property CGPoint previousControlPoint;

@end

@implementation TouchPath

@synthesize previousControlPoint;

- (id) init
{
    if ((self = [super init])) {
        self.previousControlPoint = CGPointMake(-1, -1);
        NSLog(@"Initialized previous");
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
        
        if (path.previousControlPoint.x == -1) {
            path.previousControlPoint = previous;
            NSLog(@"Set previous CP to %f,%f", previous.x, previous.y); 
            continue;
        }

        /* Normalizing the control point so that it's a distance of 1 from the previous point */
        CGFloat d1 = sqrtf((previous.x - path.previousControlPoint.x)*(previous.x - path.previousControlPoint.x) +
                          (previous.y - path.previousControlPoint.y)*(previous.y - path.previousControlPoint.y));
        CGFloat d2 = sqrtf((previous.x - now.x)*(previous.x - now.x) +
                           (previous.y - now.y)*(previous.y - now.y));
    
        CGPoint controlPoint1 = { previous.x + ((previous.x - path.previousControlPoint.x) * d2 / (10 * d1)),
                                  previous.y + ((previous.y - path.previousControlPoint.y) * d2 / (10 * d1)) };

        CGRect rect = CGRectMake(MIN(previous.x, now.x) - 20,
                                 MIN(previous.y, now.y) - 20,
                                 ABS(previous.x - now.x) + 40,
                                 ABS(previous.y - now.y) + 40);
 
        CGContextMoveToPoint(_imageContext, previous.x, previous.y);
        CGContextAddQuadCurveToPoint(_imageContext,
                                 controlPoint1.x, controlPoint1.y,
                             //    controlPoint2.x, controlPoint2.y,
                                 now.x, now.y);
        
        CGContextStrokePath(_imageContext);
        
        path.previousControlPoint = controlPoint1;
        
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
