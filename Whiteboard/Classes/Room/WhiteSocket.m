//
//  WhiteSocket.m
//  Whiteboard
//
//  Created by yleaf on 2021/11/1.
//

#import "WhiteSocket.h"
#import "WhiteFPA.h"

@interface WhiteSocket()<NSURLSessionWebSocketDelegate>

@property (nonatomic, weak, readonly) WhiteBoardView *bridge;
@property (nonatomic, strong) NSURLSessionWebSocketTask *websocket;
@property (nonatomic, strong) NSURLSession *session;
@property (nonatomic, copy) NSNumber *key;
@property (nonatomic, copy) NSDictionary *connectionProxyDictionary;

@end

@implementation WhiteSocket

static NSDictionary *_proxyConfig = nil;
+ (NSDictionary *)proxyConfig {
    return _proxyConfig;
}

+ (void)setProxyConfig:(NSDictionary *)proxyConfig
{
    _proxyConfig = proxyConfig;
}

#pragma mark - Instace Class

- (void)dealloc {
    NSLog(@"white socket dealloc");
}

- (instancetype)initWithBridge:(WhiteBoardView *)bridge {
    self = [super init];
    _bridge = bridge;
    return self;
}

- (void)injectSocket {
    WhiteSocket *socket = [[WhiteSocket alloc] initWithBridge:self.bridge];
    [self.bridge addJavascriptObject:socket namespace:@"ws"];
}

- (NSURLSession *)session {
    if (!_session) {
        NSURLSessionConfiguration *config = [NSURLSessionConfiguration defaultSessionConfiguration];
        config.connectionProxyDictionary = [WhiteSocket proxyConfig];
        // delegate 会被强制引用 WhiteSocket 实例，需要手动 invalidateAndCancel
        _session = [NSURLSession sessionWithConfiguration:config delegate:self delegateQueue:[NSOperationQueue mainQueue]];
    }
    return _session;
}

#pragma mark - private

- (NSDictionary *)connectionProxyDictionary {
    if (!_connectionProxyDictionary) {
        _connectionProxyDictionary = [WhiteSocket proxyConfig];
    }
    return _connectionProxyDictionary;
}

- (BOOL)isCurrentSocket:(NSDictionary *)payload {
    return [self.key isEqual:payload[kPayloadKey]];
}

- (void)releaseSocket {
    [self releaseSocketIfNeeded];
    [self.session invalidateAndCancel];
    self.session = nil;
}

- (void)releaseSocketIfNeeded {
    if (self.websocket) {
        NSURLSessionWebSocketTask *websocket = self.websocket;
        self.websocket = nil;
        [websocket cancelWithCloseCode:NSURLSessionWebSocketCloseCodeNormalClosure reason:nil];
    }
}

#pragma mark - consts

static NSString * const kPayloadKey = @"key";
static NSString * const kPayloadData = @"data";
static NSString * const kPayloadType = @"type";

typedef NSString * WhiteSocketPayloadType NS_STRING_ENUM;
WhiteSocketPayloadType const PayloadArrayBuffer = @"arraybuffer";
WhiteSocketPayloadType const PayloadTypeString = @"string";

#pragma mark - ws DSBridge

- (NSString *)setup:(NSDictionary *)payload
{
    [self setupWebSocket:payload];
    return @"";
}

- (NSString *)send:(NSDictionary *)payload {
    if ([self isCurrentSocket:payload]) {
        return @"";
    }
    NSString *dataString = payload[kPayloadData];
    NSURLSessionWebSocketMessage *message;
    if ([payload[kPayloadType] isEqualToString:PayloadArrayBuffer]) {
        NSData *data = [[NSData alloc] initWithBase64EncodedString:dataString options:NSDataBase64DecodingIgnoreUnknownCharacters];
        message = [[NSURLSessionWebSocketMessage alloc] initWithData:data];
    } else if ([payload[kPayloadType] isEqualToString:PayloadTypeString]) {
        message = [[NSURLSessionWebSocketMessage alloc] initWithString:dataString];
    }
    if (message) {
        [self.websocket sendMessage:message completionHandler:^(NSError * _Nullable error) {
            if (error) {
                NSLog(@"websocket send message error: %@", error);
            }
        }];
    }
    return @"";
}

- (NSString *)close:(NSDictionary *)payload {
    if ([self isCurrentSocket:payload]) {
        return @"";
    }
    
    [self.websocket cancelWithCloseCode:NSURLSessionWebSocketCloseCodeNormalClosure reason:nil];
    return @"";
}

#pragma mark - WebSocket

- (void)setupWebSocket:(NSDictionary *)dict {
    
    [self releaseSocketIfNeeded];
    
    self.key = dict[kPayloadKey];

    NSURL *url = [NSURL URLWithString:dict[@"url"]];
    self.websocket = [self.session webSocketTaskWithURL:url];
    [self.websocket resume];

    [self receiveMessageWithCompletionHandler:^(NSURLSessionWebSocketMessage * _Nullable message, NSError * _Nullable error) {
        if (error) {
            [self.bridge callHandler:@"ws.onError" arguments:@[@{kPayloadKey: self.key}]];
        } else if (message.type == NSURLSessionWebSocketMessageTypeString) {
            [self.bridge callHandler:@"ws.onMessage" arguments:@[@{kPayloadKey: self.key, kPayloadData: message.string, kPayloadType: PayloadTypeString}]];
        } else if (message.type == NSURLSessionWebSocketMessageTypeData) {
            [self.bridge callHandler:@"ws.onMessage" arguments:@[@{kPayloadKey: self.key, kPayloadData: [message.data base64EncodedStringWithOptions:NSDataBase64Encoding64CharacterLineLength], kPayloadType: PayloadArrayBuffer}]];
        }
    }];
}

- (void)receiveMessageWithCompletionHandler:(void (^)(NSURLSessionWebSocketMessage * _Nullable message, NSError * _Nullable error))completionHandler {
    __weak typeof(self)weakSelf = self;
    [self.websocket receiveMessageWithCompletionHandler:^(NSURLSessionWebSocketMessage * _Nullable message, NSError * _Nullable error) {
        if (completionHandler) {
            completionHandler(message, error);
        }
        [weakSelf receiveMessageWithCompletionHandler:completionHandler];
    }];
}

#pragma mark - NSURLSessionWebSocketDelegate


/* Indicates that the WebSocket handshake was successful and the connection has been upgraded to webSockets.
 * It will also provide the protocol that is picked in the handshake. If the handshake fails, this delegate will not be invoked.
 */
- (void)URLSession:(NSURLSession *)session webSocketTask:(NSURLSessionWebSocketTask *)webSocketTask didOpenWithProtocol:(nullable NSString *) protocol;
{
    if (self.websocket == webSocketTask) {
        [self.bridge callHandler:@"ws.onOpen" arguments:@[@{kPayloadKey: self.key}]];
    }
}

- (void)URLSession:(NSURLSession *)session webSocketTask:(NSURLSessionWebSocketTask *)webSocketTask didCloseWithCode:(NSURLSessionWebSocketCloseCode)closeCode reason:(nullable NSData *)reason;
{
    if (self.websocket == webSocketTask) {
        NSString *r = reason ? @"" : [[NSString alloc] initWithData:reason encoding:NSUTF8StringEncoding];
        NSDictionary *payload = @{@"code": @(closeCode), @"reason": r, kPayloadKey: self.key, @"wasClean": @(YES)};
        [self.bridge callHandler:@"ws.onClose" arguments:@[payload]];
    }
}

@end
