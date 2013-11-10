//
//  ViewController.m
//  cheapmotion
//
//  Created by Zainul Shah on 11/10/13.
//  Copyright (c) 2013 Zainul Shah. All rights reserved.
//

#import "ViewController.h"

@interface ViewController ()

@end

@implementation ViewController

NSMutableArray *images;
float width;
float height;
NSMutableArray *fingerPixels;
NSMutableArray *contexts;
bool didDraw1;
bool didDraw2;
unsigned char *rawData1;
unsigned char *rawData2;

- (void)viewDidLoad
{
    [super viewDidLoad];
    NSBundle *mainBundle = [NSBundle mainBundle];
    
    images = [[NSMutableArray alloc] init];
    fingerPixels = [[NSMutableArray alloc] init];
    contexts = [[NSMutableArray alloc] init];
    didDraw1 = false;
    didDraw2 = false;
    
    NSArray *imagePaths = [mainBundle pathsForResourcesOfType:@".JPG" inDirectory:@""];
    
    NSLog(@"pngs in my dir:%@", imagePaths); // Do any additional setup after loading the view, typically from a nib.
    for (NSString *path in imagePaths) {
        [images addObject:[self imageWithImage:[UIImage imageWithContentsOfFile:path] scaledToSize:CGSizeMake(245, 326)]];
        NSLog(@"image paths: %@ and size of image array: %i", path, images.count);
    }
    
    
    width = [images[0] size].width;
    height = [images[0] size].height;
    for (int x=0; x<width; x++) {
        for (int y=0; y<height; y++) {
            //if(([self getLuminanceFromImage:images[0] atX:x andY:y]-[self getLuminanceFromImage:images[1] atX:x andY:y])>0.5){
            if([self luminanceDifferenceXY:images[0] second:images[1] atX:x atY:y]>0.5){
                [fingerPixels addObject:[NSString stringWithFormat:@"x: %i, y: %i", x, y]];
                //NSLog(@"logging finger position!: %i", fingerPixels.count);
            }
        }
    }
    NSLog(@"done pixeling stuff. Finger is %f percent of the screen", fingerPixels.count/(width*height));
}

- (UIImage *)imageWithImage:(UIImage *)image scaledToSize:(CGSize)newSize {
    //UIGraphicsBeginImageContext(newSize);
    // In next line, pass 0.0 to use the current device's pixel scaling factor (and thus account for Retina resolution).
    // Pass 1.0 to force exact pixel size.
    UIGraphicsBeginImageContextWithOptions(newSize, NO, 0.0);
    [image drawInRect:CGRectMake(0, 0, newSize.width, newSize.height)];
    UIImage *newImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return newImage;
}

-(float)luminanceDifferenceXY:(UIImage*)first second:(UIImage*)second atX:(int)x atY:(int)y{
    CGFloat red1, red2, green1, green2, blue1, blue2, alpha1, alpha2;
    [[self getRGBAsFromImage:first atX:x andY:y count:1 forIndex:0][0] getRed:&red1 green:&green1 blue:&blue1 alpha:&alpha1];
    [[self getRGBAsFromImage:second atX:x andY:y count:1 forIndex:1][0] getRed:&red2 green:&green2 blue:&blue2 alpha:&alpha2];
    return (0.2126*red2) + (0.7152*green2) + (0.0722*blue2) - (0.2126*red1) + (0.7152*green1) + (0.0722*blue1);
}

- (NSArray*)getRGBAsFromImage:(UIImage*)image atX:(int)xx andY:(int)yy count:(int)count forIndex:(int)i
{
    static dispatch_once_t onceToken;
    
    
    // First get the image into your data buffer
    CGImageRef imageRef = [image CGImage];
    NSUInteger width = CGImageGetWidth(imageRef);
    NSUInteger height = CGImageGetHeight(imageRef);
    dispatch_once(&onceToken, ^{
        rawData1 = (unsigned char*) calloc(height * width * 4, sizeof(unsigned char));
        rawData2 = (unsigned char*) calloc(height * width * 4, sizeof(unsigned char));
        
    });
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    NSUInteger bytesPerPixel = 4;
    NSUInteger bytesPerRow = bytesPerPixel * width;
    NSUInteger bitsPerComponent = 8;
   
    CGContextRef context;

    if(i==0 && !didDraw1){
        contexts[i] = (__bridge id)(CGBitmapContextCreate(rawData1, width, height,
                                                     bitsPerComponent, bytesPerRow, colorSpace,
                                                     kCGImageAlphaPremultipliedLast | kCGBitmapByteOrder32Big));
        CGContextDrawImage((__bridge CGContextRef)(contexts[i]), CGRectMake(0, 0, width, height), imageRef);

        didDraw1 = true;
    }
    else if(i==1 && !didDraw2){
        contexts[i] = (__bridge id)(CGBitmapContextCreate(rawData2, width, height,
                                                          bitsPerComponent, bytesPerRow, colorSpace,
                                                          kCGImageAlphaPremultipliedLast | kCGBitmapByteOrder32Big));
        CGContextDrawImage((__bridge CGContextRef)(contexts[i]), CGRectMake(0, 0, width, height), imageRef);
        
        didDraw2 = true;
    }
    else{


    NSMutableArray *result = [NSMutableArray arrayWithCapacity:count];
    
    CGColorSpaceRelease(colorSpace);
    
    //CGContextRelease(context);
    
    // Now your rawData contains the image data in the RGBA8888 pixel format.
    int byteIndex = (bytesPerRow * yy) + xx * bytesPerPixel;
        if(i == 0){
            for (int ii = 0 ; ii < count ; ++ii)
            {
                CGFloat red   = (rawData1[byteIndex]     * 1.0) / 255.0;
                CGFloat green = (rawData1[byteIndex + 1] * 1.0) / 255.0;
                CGFloat blue  = (rawData1[byteIndex + 2] * 1.0) / 255.0;
                CGFloat alpha = (rawData1[byteIndex + 3] * 1.0) / 255.0;
                byteIndex += 4;
        
                UIColor *acolor = [UIColor colorWithRed:red green:green blue:blue alpha:alpha];
                [result addObject:acolor];
            }
        }
        if(i == 1){
            for (int ii = 0 ; ii < count ; ++ii)
            {
                CGFloat red   = (rawData2[byteIndex]     * 1.0) / 255.0;
                CGFloat green = (rawData2[byteIndex + 1] * 1.0) / 255.0;
                CGFloat blue  = (rawData2[byteIndex + 2] * 1.0) / 255.0;
                CGFloat alpha = (rawData2[byteIndex + 3] * 1.0) / 255.0;
                byteIndex += 4;
                
                UIColor *acolor = [UIColor colorWithRed:red green:green blue:blue alpha:alpha];
                [result addObject:acolor];
            }
        }
    
    //free(rawData);
        return result;
    }
    return NULL;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
