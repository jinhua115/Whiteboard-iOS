//
//  WhiteFPA.m
//  Whiteboard
//
//  Created by yleaf on 2021/11/2.
//

#import "WhiteFPA.h"
#import "WhiteSocket.h"
#import <AgoraFpaService/FPAService.h>

@interface WhiteFPA ()
@end

@implementation WhiteFPA

+ (FPAServiceConfig *)defaultFPAConfig {
    FPAServiceConfig *config = [[FPAServiceConfig alloc] init];
     // 设置 App ID
     config.appId = @"81ae40d666ed4fdc9b883962e9873a0b";
     // 设置 token。如果不开启 Token 鉴权，必须填入 App ID
     config.token = @"81ae40d666ed4fdc9b883962e9873a0b";
     config.chainIdTable = @{
         @"gateway.netless.link:443": @285
     };
    config.logLevel = AgoraFPALogLevelInfo;
    config.logFilePath = [NSString stringWithFormat:@"%@/fpa.log", NSTemporaryDirectory()];
    return config;
}

+ (void)setupFPA:(FPAServiceConfig *)config
{
     // 1. 初始化 config 的设置并创建 FPAService 对象
     // 2. 开启 FPA 服务并注册 FPAServiceDelegate
    [[FPAService sharedFPAService] startFPAServiceWithConfig:config addDelegate:(id<FPAServiceDelegate>)self];
    [WhiteSocket setProxyConfig:@{
        (id)kCFNetworkProxiesHTTPEnable:@YES,
        (id)kCFNetworkProxiesHTTPProxy:@"127.0.0.1",
        (id)kCFNetworkProxiesHTTPPort:@([[FPAService sharedFPAService] httpProxyPort]),
        @"HTTPSEnable":@YES,
        @"HTTPSProxy":@"127.0.0.1",
        @"HTTPSPort":@([[FPAService sharedFPAService] httpProxyPort]),
    }];
}

@end
