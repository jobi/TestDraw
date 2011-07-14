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
        CGPoint p = [touch locationInView:self];
        CGRect rect = CGRectMake(p.x-5, p.y-5, 10, 10);
                
        CGContextSetRGBFillColor(_imageContext, 1, 0, 0, 1);
        CGContextFillRect(_imageContext, rect);
        
        [self setNeedsDisplayInRect:rect];
    }
}

- (void)dealloc
{
    [super dealloc];
}

@end
