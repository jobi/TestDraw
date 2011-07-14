//
//  Canvas.m
//  TestDraw
//
//  Created by Johan Bilien on 7/12/11.
//

#import "Canvas.h"


@implementation Canvas

@synthesize content=_content;

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        self.backgroundColor = [UIColor whiteColor];
        self.multipleTouchEnabled = YES;
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
        
        CGContextSetRGBFillColor(_imageContext, 1, 0, 0, 1);
        CGContextSetLineWidth(_imageContext, 4);
        CGContextSetLineCap(_imageContext, kCGLineCapRound);
        CGContextSetLineJoin(_imageContext, kCGLineJoinRound);
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
    
}

- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event
{
    NSEnumerator *enumerator = [touches objectEnumerator];
    UITouch *touch;
    
    while ((touch = [enumerator nextObject])) {
        CGPoint now = [touch locationInView:self];
        CGPoint previous = [touch previousLocationInView:self];
        CGPoint controlPoint = { 2 * now.x - previous.x, 2 * now.y - previous.y };
        CGRect rect = CGRectMake(MIN(previous.x, now.x) - 5,
                                 MIN(previous.y, now.y) - 5,
                                 ABS(previous.x - now.x) + 5,
                                 ABS(previous.y - now.y) + 5);
 
        CGContextMoveToPoint(_imageContext, previous.x, previous.y);
        CGContextAddQuadCurveToPoint(_imageContext,
                                     controlPoint.x, controlPoint.y,
                                     now.x, now.y);
        
        CGContextStrokePath(_imageContext);
        
        [self setNeedsDisplayInRect:rect];
    }
}

- (void)dealloc
{
    [super dealloc];
}

@end
