//
//  DAFSwiftStaticLibrary.mm
//  SwiftStaticLibrary
//
//  Created by David Flores on 4/17/16.
//  Copyright © 2016 David Flores. All rights reserved.
//

#include "DAFSwiftStaticLibrary.h"

//~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
// Exported from /Applications/Xcode.app/Contents/PlugIns/Xcode3Core.ideplugin/Contents/Frameworks/DevToolsCore.framework
extern "C" NSString* dg_get_string(id pMacroExpansionScope, NSString* pString);
extern "C" NSString* dg_make_path(NSString* pString, ...);

//~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
static NSString* (*g_pfnEvaluatedStringValueForMacroNamed)(id pSelf, SEL selCommand, NSString* pMacroNameString) = nullptr;
static NSArray<NSString*>* (*g_pfnArguments)(id pSelf, SEL selCommand) = nullptr;
static id (*g_pfnComputeDependencies)(id pSelf, SEL selCommand, id pInputNodes, id pType, id pVariant, id pArchitecture, id pOutputDirectory, id pMacroExpansionScope) = nullptr;

//~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
static NSString*
DAFEvaluatedStringValueForMacroNamed(id pSelf, SEL selCommand, NSString* pMacroNameString)
{
    assert( ::g_pfnEvaluatedStringValueForMacroNamed != nullptr );
    
    NSString* pEvaluatedStringValue = ::g_pfnEvaluatedStringValueForMacroNamed(pSelf, selCommand, pMacroNameString);
    
    if ( [pMacroNameString isEqualToString:@"MACH_O_TYPE"] &&
         [pEvaluatedStringValue isEqualToString:@"staticlib"] )
    {
        for ( NSString* pCallStackSymbolString in [NSThread callStackSymbols] )
            if ( [pCallStackSymbolString containsString:@"-[XCCompilerSpecificationSwift computeDependenciesForInputNodes:ofType:variant:architecture:outputDirectory:withMacroExpansionScope:]"] )
                pEvaluatedStringValue = @"mh_bundle";
    }
    
    return pEvaluatedStringValue;
}

//~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
static NSArray<NSString*>*
DAFArguments(id pSelf, SEL selCommand)
{
    assert( ::g_pfnArguments != nullptr );
    
    NSArray<NSString*>* pArgumentStringArray = ::g_pfnArguments(pSelf, selCommand);
    
    NSUInteger uIndexStatic = [pArgumentStringArray indexOfObject:@"-static"];
    NSUInteger uIndexAddAstPath = [pArgumentStringArray indexOfObject:@"-add_ast_path"];
    if ( uIndexStatic != NSNotFound &&
         uIndexAddAstPath != NSNotFound &&
         uIndexStatic < uIndexAddAstPath &&
         uIndexAddAstPath > 0 &&
         (uIndexAddAstPath + 2) < [pArgumentStringArray count] )
    {
        NSMutableArray<NSString*>* pArgumentStringMutableArray = [pArgumentStringArray mutableCopy];
        [pArgumentStringMutableArray removeObjectsInRange:(::NSMakeRange(uIndexAddAstPath - 1, 4))];
        pArgumentStringArray = pArgumentStringMutableArray;
    }
    
    return pArgumentStringArray;
}

//~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
static id
DAFComputeDependencies(id pSelf, SEL selCommand, id pInputNodes, id pType, id pVariant, id pArchitecture, id pOutputDirectory, id pMacroExpansionScope)
{
    assert( ::g_pfnComputeDependencies != nullptr );
    
    id pComputedDependencyNodeArray = ::g_pfnComputeDependencies(pSelf, selCommand, pInputNodes, pType, pVariant, pArchitecture, pOutputDirectory, pMacroExpansionScope);
    
    NSString* pDerivedFileDataDirectoryString = ::dg_get_string(pMacroExpansionScope,  @"DERIVED_FILE_DIR");
    NSString* pSwiftObjcInterfaceHeaderNameString = ::dg_get_string(pMacroExpansionScope, @"SWIFT_OBJC_INTERFACE_HEADER_NAME");
    NSString* pSourcePathString = ::dg_make_path(pDerivedFileDataDirectoryString, pSwiftObjcInterfaceHeaderNameString, nil);
    
    NSString* pTargetBuildDirectoryString = ::dg_get_string(pMacroExpansionScope,  @"TARGET_BUILD_DIR");
    NSString* pIncludeString = @"include";
    NSString* pProductNameString = ::dg_get_string(pMacroExpansionScope,  @"PRODUCT_NAME");
    NSString* pDestinationPathString = ::dg_make_path(pTargetBuildDirectoryString, pIncludeString, pProductNameString, pSwiftObjcInterfaceHeaderNameString, nil);

    id pDependencyGraphCreationContext = reinterpret_cast<id(*)(id, SEL)>(::objc_msgSend)(pMacroExpansionScope, ::NSSelectorFromString(@"dependencyGraphCreationContext"));
    id pDittoDependencyCommand =
        reinterpret_cast<id(*)(id, SEL, NSString*, NSString*, id)>(::objc_msgSend)(pDependencyGraphCreationContext,
                                                                                   ::NSSelectorFromString(@"dittoFileAtPath:toPath:withMacroExpansionScope:"),
                                                                                   pSourcePathString,
                                                                                   pDestinationPathString,
                                                                                   pMacroExpansionScope);
    
    NSString* pDescriptionString =
        [NSString stringWithFormat:@"Copy %@", pSwiftObjcInterfaceHeaderNameString, nil];
    reinterpret_cast<void(*)(id, SEL, NSString*)>(::objc_msgSend)(pDittoDependencyCommand, ::NSSelectorFromString(@"setExecutionDescription:"), pDescriptionString);
    reinterpret_cast<void(*)(id, SEL, NSString*)>(::objc_msgSend)(pDittoDependencyCommand, ::NSSelectorFromString(@"setProgressDescription:"), pDescriptionString);
    
    id pInputDependencyNode =
        reinterpret_cast<id(*)(id, SEL, NSString*)>(::objc_msgSend)(pDependencyGraphCreationContext, ::NSSelectorFromString(@"dependencyNodeForPath:"), pSourcePathString);
    reinterpret_cast<void(*)(id, SEL, id)>(::objc_msgSend)(pDittoDependencyCommand, ::NSSelectorFromString(@"addInputNode:"), pInputDependencyNode);

    id pOutputDependencyNode =
        reinterpret_cast<id(*)(id, SEL, NSString*)>(::objc_msgSend)(pDependencyGraphCreationContext, ::NSSelectorFromString(@"dependencyNodeForPath:"), pDestinationPathString);
    reinterpret_cast<void(*)(id, SEL, id)>(::objc_msgSend)(pDittoDependencyCommand, ::NSSelectorFromString(@"addOutputNode:"), pOutputDependencyNode);
    
    return [pComputedDependencyNodeArray arrayByAddingObject:pOutputDependencyNode];
}

//~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
@implementation DAFSwiftStaticLibrary

//~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
+ (void)pluginDidLoad:(NSBundle*)pPluginBundle
{
    if ( ! [[[NSBundle mainBundle] infoDictionary][@"CFBundleName"] isEqual:@"Xcode"] )
        return;

    static dispatch_once_t dispatchOnce;
    ::dispatch_once(&dispatchOnce,
                    ^void(void)
                    {
                        Class classDVTMacroExpansionScope = ::NSClassFromString(@"DVTMacroExpansionScope");
                        Method methodEvaluatedStringValueForMacroNamed =
                            ::class_getInstanceMethod(classDVTMacroExpansionScope, ::NSSelectorFromString(@"evaluatedStringValueForMacroNamed:"));
                        ::g_pfnEvaluatedStringValueForMacroNamed =
                            reinterpret_cast<decltype(::g_pfnEvaluatedStringValueForMacroNamed)>(
                                ::method_setImplementation(methodEvaluatedStringValueForMacroNamed,
                                                           reinterpret_cast<IMP>(DAFEvaluatedStringValueForMacroNamed)));
                        
                        Class classXCDependencyCommand = ::NSClassFromString(@"XCDependencyCommand");
                        Method methodArguments = ::class_getInstanceMethod(classXCDependencyCommand, ::NSSelectorFromString(@"arguments"));
                        ::g_pfnArguments =
                            reinterpret_cast<decltype(::g_pfnArguments)>(
                                ::method_setImplementation(methodArguments,
                                                           reinterpret_cast<IMP>(DAFArguments)));
                        
                        Class classXCCompilerSpecificationSwift = ::NSClassFromString(@"XCCompilerSpecificationSwift");
                        Method methodComputeDependencies =
                            ::class_getInstanceMethod(classXCCompilerSpecificationSwift,
                                                      ::NSSelectorFromString(@"computeDependenciesForInputNodes:ofType:variant:architecture:outputDirectory:withMacroExpansionScope:"));
                        ::g_pfnComputeDependencies =
                            reinterpret_cast<decltype(::g_pfnComputeDependencies)>(
                                ::method_setImplementation(methodComputeDependencies,
                                                           reinterpret_cast<IMP>(DAFComputeDependencies)));
                    });
}

@end
