//
//  NSObject_Extension.m
//  SwiftStaticLibrary
//
//  Created by David Flores on 4/17/16.
//  Copyright © 2016 David Flores. All rights reserved.
//


#import "NSObject_Extension.h"
#import "SwiftStaticLibrary.h"

@implementation NSObject (Xcode_Plugin_Template_Extension)

+ (void)pluginDidLoad:(NSBundle *)plugin
{
    static dispatch_once_t onceToken;
    NSString *currentApplicationName = [[NSBundle mainBundle] infoDictionary][@"CFBundleName"];
    if ([currentApplicationName isEqual:@"Xcode"]) {
        dispatch_once(&onceToken, ^{
            sharedPlugin = [[SwiftStaticLibrary alloc] initWithBundle:plugin];
        });
    }
}
@end
