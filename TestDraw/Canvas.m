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

void normalizeVector(CGPoint *v, CGFloat length)
{
    CGFloat d = sqrtf(v->x * v->x + v->y * v->y);
    
    v->x = v->x * sqrtf(length) / d;
    v->y = v->y * sqrtf(length) / d;
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
            continue;
        }

        
        CGFloat length = sqrtf((previous.x - path.pointNMinus2.x) * (previous.x - path.pointNMinus2.x) +
                               (previous.y - path.pointNMinus2.y) * (previous.y - path.pointNMinus2.y)) / 2;
        
        CGPoint vect1;
        
        if (path.controlPoint2NMinus2.x == -1) {
            vect1 = CGPointMake(previous.x - path.controlPoint2NMinus2.x,
                                previous.y - path.controlPoint2NMinus2.y);
        } else {
            vect1 = CGPointMake(path.pointNMinus2.x - path.controlPoint2NMinus2.x,
                                path.pointNMinus2.y - path.controlPoint2NMinus2.y);
        }
        
        normalizeVector(&vect1, length);
        CGPoint controlPoint1 = { path.pointNMinus2.x + vect1.x,
                                  path.pointNMinus2.y + vect1.y };
                                        
        CGPoint vect2 = CGPointMake(path.pointNMinus2.x - now.x, path.pointNMinus2.y - now.y);
        normalizeVector(&vect2, length);
        CGPoint controlPoint2 = { previous.x + vect2.x,
                                  previous.y + vect2.y };

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

- (void)motionEnded:(UIEventSubtype)motion withEvent:(UIEvent *)event
{
    CGContextClearRect(_imageContext, self.frame);
    [self setNeedsDisplay];
}

- (BOOL)canBecomeFirstResponder
{
    return YES;
}

- (void)dealloc
{
    [_activeTouches release];
    _activeTouches = nil;
    
    [super dealloc];
}

@end
