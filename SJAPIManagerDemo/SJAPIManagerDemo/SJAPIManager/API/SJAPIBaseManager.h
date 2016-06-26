//
//  SJAPIBaseManager.h
//  SJFramework
//
//  Created by Sharejoy on 15/6/12.
//  Copyright (c) 2015年 sharejoy. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SJAPIResponse.h"

/**
 用TestAPI举例:
 1. 使用方法, 将TestAPI接口封装成类, 继承于SJAPIResponse
 2. 在具体api的init方法中设置相关代理, 一般该api作为代理, 即self.paramSource = self; 等等
 3. 遵守协议<SJAPIManager, SJAPIManagerParamSourceDelegate, SJAPIManagerHeaderSourceDelegate, 等等>, 每个协议具体功能及需要实现哪些方法见协议方法
 4. 在控制器内懒加载TestAPI, 同时设置_testAPI.delegate = self, 指定该控制器为接口的代理, 实现下面两个回调方法
 - (void)managerCallAPIDidSuccess:(SJAPIBaseManager *)manager;
 - (void)managerCallAPIDidFailed:(SJAPIBaseManager *)manager;
 
 5. 如果要在特定时刻或者某些情况删除缓存, 可以发通知实现, 通知的userInfo这种格式@{InvalidCacheKey : @[NSClassFromString(@"TestAPI"), ]}
 -(void)handleInvalidCache:(NSNotification*)notify
 {
    NSDictionary* dict = notify.userInfo;
    NSArray* arr = [dict objectForKey:SBInvalidCacheKey];
    for (Class cls in arr) {
        [[SJCache sharedInstance] deleteCacheWithClass:cls];
    }
 }
 6. 其他用法见源码, 自己理解
 */

@class SJAPIBaseManager;
//定义网络请求ID字典名称
static NSString * const kSJAPIRequestId = @"kSJAPIRequestId";

#pragma mark -- APAPIManager错误类型
typedef enum : NSUInteger {
    SJAPIManagerErrorTypeDefault,       //没有API请求，默认状态。
    SJAPIManagerErrorTypeSuccess,       //API请求成功且返回数据正确。
    SJAPIManagerErrorTypeErrorContent,  //API请求成功但返回数据不正确。
    SJAPIManagerErrorTypeParamsError,   //API请求参数错误。
    SJAPIManagerErrorTypeTimeout,       //API请求超时。
    SJAPIManagerErrorTypeNoNetWork      //网络故障。
    
} SJAPIManagerErrorType;

#pragma mark -- HTTP请求方式
typedef enum : NSUInteger {
    SJAPIManagerRequestTypeGet = 0,
    SJAPIManagerRequestTypePost,
    SJAPIManagerRequestTypeUpload
    
} SJAPIManagerRequestType;


#pragma mark -- api回调
@protocol SJAPIManagerCallBackDelegate <NSObject>
@required
- (void)managerCallAPIDidSuccess:(SJAPIBaseManager *)manager;
- (void)managerCallAPIDidFailed:(SJAPIBaseManager *)manager;
@end

#pragma mark -- 适配器,负责重新组装API数据的对象
@protocol SJAPIManagerCallBackDataAdaptor <NSObject>
@required
- (id)manager:(SJAPIBaseManager *)manager adaptorData:(NSDictionary *)data;
@end

#pragma mark -- 验证器，用于验证API的返回或者调用API的参数是否正确
@protocol SJAPIManagerValidator <NSObject>
@required
//验证CallBack数据的正确性
- (BOOL)manager:(SJAPIBaseManager *)manager isCorrectWithResponseData:(NSDictionary *)data;
//验证传递的参数数据的正确性
- (BOOL)manager:(SJAPIBaseManager *)manager isCorrectWithParamsData:(NSDictionary *)data;
@end

#pragma mark -- 让manager获取调用API所需要的数据(参数)
@protocol SJAPIManagerParamSourceDelegate <NSObject>
@required
- (NSDictionary *)paramsForAPI:(SJAPIBaseManager *)manager;
@end

#pragma mark -- 让manager获取调用API所需要的头部数据 (本项目一般用于携带token)
@protocol SJAPIManagerHeaderSourceDelegate <NSObject>
@required
- (NSDictionary *)headersForAPI:(SJAPIBaseManager *)manager;
@end

#pragma mark -- 让manager获取调用API所需要的上传数据
@protocol SJAPIManagerUploadSourceDelegate <NSObject>
@required
- (NSDictionary *)uploadsForAPI:(SJAPIBaseManager *)manager;
@end


#pragma mark -- API访问
@protocol SJAPIManager <NSObject>

@required
- (NSString *)requestUrl;
- (SJAPIManagerRequestType)requestType;
@optional
- (NSString *)cacheRegexKey;
@optional
/**
 *   用于给继承的类做重载，在调用API之前额外添加一些参数,但不应该在这个函数里面修改已有的参数
 *   如果子类实现这个方法, 一定要在传入的params基础上修改 , 再返回修改后的params
 *   子类中覆盖这个函数的时候就不需要调用[super reformParams:params]了
 *   SJAPIBaseManager会先调用这个函数，然后才会调用到 id<SJAPIManagerValidator> 中的 manager:isCorrectWithParamsData: 所以这里返回的参数字典还是会被后面的验证函数去验证的
 */
- (NSDictionary *)reformParams:(NSDictionary *)params;
/**
 * 允许修改网址,可用于url拼接
 */
- (NSString *)methodName;
- (void)cleanData;
- (BOOL)shouldCache;

@end

#pragma mark -- 拦截器
@protocol SJAPIManagerInterceptor <NSObject>

@optional
//参数拦截器, 通过参数判断是否发送请求
- (BOOL)manager:(SJAPIBaseManager *)manager shouldCallAPIWithParams:(NSDictionary *)params;
- (void)manager:(SJAPIBaseManager *)manager afterCallAPIWithParams:(NSDictionary *)params;

//结果拦截器, 拿到返回的原始json数据, 处理成model再给SJAPIManagerCallBackDelegate 使用
- (void)manager:(SJAPIBaseManager *)manager beforePerformSuccessWithResponse:(SJAPIResponse *)response;
- (void)manager:(SJAPIBaseManager *)manager beforePerformFailWithResponse:(SJAPIResponse *)response;

- (void)manager:(SJAPIBaseManager *)manager afterPerformSuccessWithResponse:(SJAPIResponse *)response;
- (void)manager:(SJAPIBaseManager *)manager afterPerformFailWithResponse:(SJAPIResponse *)response;

@end



@interface SJAPIBaseManager :NSObject

@property (nonatomic, weak) id<SJAPIManagerCallBackDelegate> delegate; //这个代理一般为控制器
//以下几个参数, 如果是直接继承SJAPIBasrManager, 则会调用子类的同名方法,(可不用遵守协议)
@property (nonatomic, weak) id<SJAPIManagerParamSourceDelegate> paramSource; //接口API
@property (nonatomic, weak) id<SJAPIManagerHeaderSourceDelegate> headerSource; //接口API
@property (nonatomic, weak) id<SJAPIManagerUploadSourceDelegate> uploadsSource; //接口API
@property (nonatomic, weak) id<SJAPIManagerValidator> validator;
@property (nonatomic, weak) NSObject<SJAPIManager> *child; //接口API, 里面会调用到NSObject的方法，所以这里不用id
@property (nonatomic, weak) id<SJAPIManagerInterceptor> interceptor;

/*
 baseManager是不会去设置errorMessage的，派生的子类manager可能需要给controller提供错误信息。所以为了统一外部调用的入口，设置了这个变量。
 派生的子类需要通过extension来在保证errorMessage在对外只读的情况下使派生的manager子类对errorMessage具有写权限。
 */
@property (nonatomic, copy, readonly) NSString *errorMessage;
@property (nonatomic, readonly) SJAPIManagerErrorType errorType;

@property (nonatomic, assign, readonly) BOOL isReachable;
@property (nonatomic, assign, readonly) BOOL isLoading;
//@property (nonatomic, assign, readonly) BOOL isPageMode;
///** 是否为读取新数据(对应下拉刷新) */
//@property (nonatomic,assign) BOOL isLoadNew;
///** 是否为最后一页 */
//@property (nonatomic,assign) BOOL isLastPage;

//所需数据的
- (id)fetchDataWithAdaptor:(id<SJAPIManagerCallBackDataAdaptor>)adaptor;

//获取数据
- (NSInteger)loadData;
- (void) invalidCache;

//取消全部网络请求
- (void)cancelAllRequests;

//根据requestId取消网络请求
- (void)cancelRequestWithRequestId:(NSInteger)requestId;

//清除数据
- (void)cleanData;

//设置是否需要缓存
- (BOOL)shouldCache;

// 拦截器方法，继承之后需要调用一下super
- (void)beforePerformSuccessWithResponse:(SJAPIResponse *)response;
- (void)afterPerformSuccessWithResponse:(SJAPIResponse *)response;

- (void)beforePerformFailWithResponse:(SJAPIResponse *)response;
- (void)afterPerformFailWithResponse:(SJAPIResponse *)response;

- (BOOL)shouldCallAPIWithParams:(NSDictionary *)params;
- (void)afterCallingAPIWithParams:(NSDictionary *)params;


@end
