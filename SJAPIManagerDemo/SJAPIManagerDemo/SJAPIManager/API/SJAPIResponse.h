//
//  SJAPIResponse.h
//  SJFramework
//
//  Created by Sharejoy on 15/6/12.
//  Copyright (c) 2015年 sharejoy. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SJNetworkConfiguration.h"

@interface SJAPIResponse : NSObject

/** 状态 */
@property (nonatomic, assign, readonly) SJSURLResponseStatus status;
/** 回调json字符串 */
@property (nonatomic, copy, readonly) NSString *contentString;
/** 回调对象, 字典或者数组 */
@property (nonatomic, copy, readonly) id content;
/** 请求记录id (app生命周期内递增不会减少) */
@property (nonatomic, assign, readonly) NSInteger requestId;
/** 请求 */
@property (nonatomic, copy, readonly) NSURLRequest *request;
/** 回调json的二进制Data */
@property (nonatomic, copy, readonly) NSData *responseData;
/** 回调json的实际数据字典(不含返回码及message) */
@property (nonatomic, copy, readonly) NSDictionary *result;
/** 返回码 */
@property (nonatomic,assign, readonly) int responseCode;
/** 返回message */
@property (nonatomic,copy, readonly) NSString *responseMessage;
/** 请求参数 */
@property (nonatomic, copy) NSDictionary *requestParams;
/** 错误信息 */
@property (nonatomic, strong, readonly) NSError *error;

/** 是否是缓存数据 */
@property (nonatomic, assign, readonly) BOOL isCache;

/** 回调成功 SJAPIResponse初始化方法 */
- (instancetype)initWithStatus:(SJSURLResponseStatus)status requestId:(NSNumber *)requestId request:(NSURLRequest *)request params:(NSDictionary *)params responseData:(NSData *)responseData responseString:(NSString *)responseString;

/** 回调失败 SJAPIResponse初始化方法 */
- (instancetype)initWithRequestId:(NSNumber *)requestId request:(NSURLRequest *)request responseData:(NSData *)responseData  responseString:(NSString *)responseString error:(NSError *)error;

/** 使用缓存数据 SJAPIResponse的初始化方法，它的isCache是YES，上面两个函数生成的response的isCache是NO */
- (instancetype)initWithData:(NSData *)data;

@end
