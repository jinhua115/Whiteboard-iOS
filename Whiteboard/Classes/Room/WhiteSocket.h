//
//  WhiteSocket.h
//  Whiteboard
//
//  Created by yleaf on 2021/11/1.
//

#import <Foundation/Foundation.h>
#import "WhiteBoardView.h"

NS_ASSUME_NONNULL_BEGIN

API_AVAILABLE(ios(13.0))
@interface WhiteSocket : NSObject

+ (void)setProxyConfig:(NSDictionary *)proxyConfig;

@end

NS_ASSUME_NONNULL_END
