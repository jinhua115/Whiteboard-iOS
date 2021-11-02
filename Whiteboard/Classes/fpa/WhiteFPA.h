//
//  WhiteFPA.h
//  Whiteboard
//
//  Created by yleaf on 2021/11/2.
//

#import <Foundation/Foundation.h>
#import <AgoraFpaService/FPAService.h>

NS_ASSUME_NONNULL_BEGIN

API_AVAILABLE(ios(13.0))
@interface WhiteFPA : NSObject

+ (FPAServiceConfig *)defaultFPAConfig;
// 初始化 fpa 服务，并配置 socket Proxy config
+ (void)setupFPA:(FPAServiceConfig *)config;

@end

NS_ASSUME_NONNULL_END
