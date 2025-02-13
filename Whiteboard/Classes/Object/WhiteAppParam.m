//
//  WhiteAppParam.m
//
//  Created by yleaf on 2021/8/21.
//

#import "WhiteAppParam.h"

@implementation WhiteAppOptions

@end


@interface WhiteAppParam ()
@property (nonatomic, copy, readwrite) NSString *kind;
@property (nonatomic, strong, readwrite) WhiteAppOptions *options;
@property (nonatomic, copy, readwrite) NSDictionary *attrs;
@end

@implementation WhiteAppParam

+ (instancetype)createDocsViewerApp:(NSString *)dir scenes:(NSArray <WhiteScene *>*)scenes title:(NSString *)title {
    
    WhiteAppParam *param = [[WhiteAppParam alloc] init];
    param.kind = @"DocsViewer";
    
    WhiteAppOptions *ops = [[WhiteAppOptions alloc] init];
    ops.scenePath = dir;
    ops.scenes = scenes;
    ops.title = title;
    param.options = ops;
    
    param.attrs = @{};
    
    return param;
}

+ (instancetype)createMediaPlayerApp:(NSString *)src title:(NSString *)title
{
    WhiteAppParam *param = [[WhiteAppParam alloc] init];
    param.kind = @"MediaPlayer";
    
    WhiteAppOptions *ops = [[WhiteAppOptions alloc] init];
    ops.title = title;
    param.options = ops;
    
    NSAssert(src.length > 0, @"src cann't be nil");
    param.attrs = @{@"src": src ? @"" : src};
    
    return param;
}
@end
