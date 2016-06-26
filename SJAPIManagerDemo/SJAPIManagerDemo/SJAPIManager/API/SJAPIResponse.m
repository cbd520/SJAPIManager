//
//  SJAPIResponse.m
//  SJFramework
//
//  Created by Sharejoy on 15/6/12.
//  Copyright (c) 2015年 sharejoy. All rights reserved.
//

#import "SJAPIResponse.h"
#import "NSURLRequest+SJNetworkingMethods.h"
#import "NSObject+AXNetworkingMethods.h"

@interface SJAPIResponse()

/** 响应状态 */
@property (nonatomic, assign, readwrite) SJSURLResponseStatus status;
/** 回调json字符串 */
@property (nonatomic, copy, readwrite) NSString *contentString;
/** 回调对象, 字典或者数组 */
@property (nonatomic, copy, readwrite) id content;
/** 请求记录id (app生命周期内递增不会减少) */
@property (nonatomic, assign, readwrite) NSInteger requestId;
/** 请求 */
@property (nonatomic, copy, readwrite) NSURLRequest *request;
/** 回调json的二进制Data */
@property (nonatomic, copy, readwrite) NSData *responseData;
/** 回调json的实际数据字典(不含返回码及message) */
@property (nonatomic, copy, readwrite) NSDictionary *result;
/** 返回码 */
@property (nonatomic,assign, readwrite) int responseCode;
/** 返回message */
@property (nonatomic,copy, readwrite) NSString *responseMessage;
/** 错误信息 */
@property (nonatomic, strong, readwrite) NSError *error;
/** 是否是缓存数据 */
@property (nonatomic, assign, readwrite) BOOL isCache;

@end

@implementation SJAPIResponse

#pragma mark - life cycle
//成功走这里, 这里需要根据公司不同格式定制
- (instancetype)initWithStatus:(SJSURLResponseStatus)status requestId:(NSNumber *)requestId request:(NSURLRequest *)request params:(NSDictionary *)params responseData:(NSData *)responseData responseString:(NSString *)responseString
{
    self = [super init];
    if (self) {
        self.status = status;
        
        self.requestId = [requestId integerValue];
        self.request = request;
        self.requestParams = params;
        
        self.responseData = responseData;
        self.contentString = responseString;
        self.content = [NSJSONSerialization JSONObjectWithData:responseData options:NSJSONReadingMutableContainers error:NULL];
        self.responseCode = [self.content[@"code"] intValue];
        self.responseMessage = self.content[@"message"];
        self.result = self.content[@"data"];
        
        NSLog(@"successCode : %d", self.responseCode);
        
        self.isCache = NO;
    }
    return self;
}

//错误走这里, 这里需要根据公司不同格式定制
- (instancetype)initWithRequestId:(NSNumber *)requestId request:(NSURLRequest *)request responseData:(NSData *)responseData  responseString:(NSString *)responseString error:(NSError *)error
{
    self = [super init];
    if (self) {
        self.status = [self responseStatusWithError:error];
        
        self.requestId = [requestId integerValue];
        self.request = request;
        self.requestParams = request.requestParams;
        
        self.responseData = responseData;
        self.contentString = [responseString SJ_defaultValue:@""];
        self.error = error;
        
        if (responseData) {
            self.content = [NSJSONSerialization JSONObjectWithData:responseData options:NSJSONReadingMutableContainers error:NULL];
            self.responseCode = [self.content[@"code"] intValue];
            self.result = self.content[@"data"];
        } else {
            self.content = nil;
        }
        
        self.isCache = NO;
    }
    return self;
}

// 使用initWithData的response，它的isCache是YES，上面两个函数生成的response的isCache是NO
- (instancetype)initWithData:(NSData *)data
{
    self = [super init];
    if (self) {
        self.status = SJSURLResponseStatusSuccess;
        
        self.requestId = 0;
        self.request = nil;
        
        self.responseData = [data copy];
        self.contentString = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
        self.content = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableContainers error:NULL];
        
        self.responseCode = [self.content[@"code"] intValue];
        self.responseMessage = self.content[@"message"];
        self.result = self.content[@"data"];
        
        self.isCache = YES;
    }
    return self;
}

#pragma mark - private methods
- (SJSURLResponseStatus)responseStatusWithError:(NSError *)error
{
    if (error) {
        SJSURLResponseStatus result = SJSURLResponseStatusNoNetwork;
        
        NSLog(@"errorCode: %zd  errorMessage: %@", error.code, error.userInfo[@"NSLocalizedDescription"]);
        // 除了超时以外，所有错误都当成是无网络
        if (error.code == NSURLErrorTimedOut) {
            result = SJSURLResponseStatusTimeout;
        }
        return result;
    } else {
        return SJSURLResponseStatusSuccess;
    }
}

@end
