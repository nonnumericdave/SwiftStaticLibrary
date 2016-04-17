//
//  SwiftStaticLibrary.h
//  SwiftStaticLibrary
//
//  Created by David Flores on 4/17/16.
//  Copyright © 2016 David Flores. All rights reserved.
//

#import <AppKit/AppKit.h>

@class SwiftStaticLibrary;

static SwiftStaticLibrary *sharedPlugin;

@interface SwiftStaticLibrary : NSObject

+ (instancetype)sharedPlugin;
- (id)initWithBundle:(NSBundle *)plugin;

@property (nonatomic, strong, readonly) NSBundle* bundle;
@end