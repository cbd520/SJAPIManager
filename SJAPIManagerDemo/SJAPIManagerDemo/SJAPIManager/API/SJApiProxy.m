//
//  AXApiProxy.m
//  RTNetworking
//
//  Created by casa on 14-5-12.
//  Copyright (c) 2014年 anjuke. All rights reserved.
//

#import "AFNetworking.h"
#import "SJApiProxy.h"
#import "NSURLRequest+SJNetworkingMethods.h"

static NSString * const kAXApiProxyDispatchItemKeyCallbackSuccess = @"kAXApiProxyDispatchItemCallbackSuccess";
static NSString * const kAXApiProxyDispatchItemKeyCallbackFail = @"kAXApiProxyDispatchItemCallbackFail";


@interface SJApiProxy ()

@property (nonatomic, strong) NSMutableDictionary *dispatchTable;
@property (nonatomic, strong) NSNumber *recordedRequestId;

//AFNetworking stuff
@property (nonatomic, strong) AFHTTPRequestOperationManager *operationManager;

@end

@implementation SJApiProxy
#pragma mark - getters and setters
- (NSMutableDictionary *)dispatchTable
{
    if (_dispatchTable == nil) {
        _dispatchTable = [[NSMutableDictionary alloc] init];
    }
    return _dispatchTable;
}

- (AFHTTPRequestOperationManager *)operationManager
{
    if (_operationManager == nil) {
        _operationManager = [[AFHTTPRequestOperationManager alloc] initWithBaseURL:nil];
        //        _operationManager.responseSerializer = [AFJSONResponseSerializer serializer];  //都在具体请求里设置
        [_operationManager.securityPolicy setAllowInvalidCertificates:YES]; //设置这句话可以支持发布测试url
        
    }
    return _operationManager;
}

#pragma mark - life cycle
+ (instancetype)sharedInstance
{
    static dispatch_once_t onceToken;
    static SJApiProxy *sharedInstance = nil;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[SJApiProxy alloc] init];
    });
    return sharedInstance;
}

#pragma mark - 公有方法
- (NSInteger)callGETWithParams:(NSDictionary *)params url:(NSString *)url  headers:(NSDictionary*)headers methodName:(NSString *)methodName success:(AXCallback)success fail:(AXCallback)fail
{
    self.operationManager.requestSerializer = [AFHTTPRequestSerializer serializer];
    self.operationManager.requestSerializer.timeoutInterval = kSJSNetworkingTimeoutSeconds;
    
    [self fillHeader:headers];
    
    NSNumber *requestId = [self callApiWithParams:params url:url methodName:methodName requestType:REQUEST_GET success:success fail:fail upload:nil];
    return [requestId integerValue];
}

- (NSInteger)callPOSTWithParams:(NSDictionary *)params url:(NSString *)url  headers:(NSDictionary*)headers methodName:(NSString *)methodName success:(AXCallback)success fail:(AXCallback)fail
{
    self.operationManager.requestSerializer = [AFJSONRequestSerializer serializer];
    self.operationManager.requestSerializer.timeoutInterval = kSJSNetworkingTimeoutSeconds;
    
    [self fillHeader:headers];
    
    NSNumber *requestId = [self callApiWithParams:params url:url methodName:methodName requestType:REQUEST_POST success:success fail:fail upload:nil];
    
    return [requestId integerValue];
}

- (NSInteger)callUPLOADWithParams:(NSDictionary *)params url:(NSString *)url headers:(NSDictionary *)headers uploads:(NSDictionary *)uploads methodName:(NSString *)methodName success:(AXCallback)success fail:(AXCallback)fail
{
    
    [self.operationManager.requestSerializer setValue:@"multipart/form-data" forHTTPHeaderField:@"Content-Type"];
    self.operationManager.requestSerializer.timeoutInterval = 60.0f;
    
    [self fillHeader:headers];
    
    multipart upload = ^(id<AFMultipartFormData> formData){
        NSMutableArray *filepart = [uploads objectForKey:@"fileparts"];
        NSString *filename = [uploads objectForKey:@"filename"];
        for (int i = 0; i< filepart.count; i++) {
            NSData *imageData = filepart[i];
            [formData appendPartWithFileData:imageData
                                        name:[NSString stringWithFormat:@"%@",filename]
                                    fileName:[NSString stringWithFormat:@"image%d.jpg",i]mimeType:@"image/jpeg"];
        }
    };
    
    NSNumber *requestId = [self callApiWithParams:params url:url methodName:methodName requestType:REQUEST_UPLOAD success:success fail:fail upload:upload];
    return [requestId integerValue];
}

- (void)cancelRequestWithRequestID:(NSNumber *)requestID
{
    NSOperation *requestOperation = self.dispatchTable[requestID];
    [requestOperation cancel];
    [self.dispatchTable removeObjectForKey:requestID];
}

- (void)cancelRequestWithRequestIDList:(NSArray *)requestIDList
{
    for (NSNumber *requestId in requestIDList) {
        [self cancelRequestWithRequestID:requestId];
    }
}

#pragma mark - 私有方法
/** 这个函数存在的意义在于，如果将来要把AFNetworking换掉，只要修改这个函数的实现即可。因为最终调用三方的主要代码都在这个方法里 */
- (NSNumber *)callApiWithParams:(NSDictionary *)params url:(NSString *)url methodName:(NSString *)methodName requestType:(RequestType)type success:(AXCallback)success fail:(AXCallback)fail upload:(multipart)upload
{
    // 之所以不用getter，是因为如果放到getter里面的话，每次调用self.recordedRequestId的时候值就都变了，违背了getter的初衷(配合setter, 值才会变)
    NSNumber *requestId = [self generateRequestId];
    
    //AFN回调成功的block, 内部会将返回的参数转成SJAPIResponse, 在调用BaseManager中的success:(AXCallback)success的block实现回调(即从BaseManager中传进来一个block, 回调成功把这个block参数一填, 外部就回调了)
    suceesBlock sblk = ^(AFHTTPRequestOperation *operation, id reponseObject) {
        
        //假设连续发出请求, recordedRequestId连续增加, 这里的requestId为什么不会用最大的值, 因为block引用的值会引用当时该变量的值, 调用这个方法的时候, 定义了这个block时如果requestId = 2, 即使连续增长至5, 回调的时候requestId依然会是2
        AFHTTPRequestOperation *storedOperation = self.dispatchTable[requestId];
        
        if (storedOperation == nil) {
            // 如果这个operation是被cancel的(即self.dispatchTable中对应的operation已被删除了), 那就不用处理回调了。
            return;
        } else {
            [self.dispatchTable removeObjectForKey:requestId];  //成功返回数据, 删除掉request记录
        }
        
        SJAPIResponse *response = [[SJAPIResponse alloc] initWithStatus:SJSURLResponseStatusSuccess requestId:requestId request:operation.request params:params responseData:operation.responseData responseString:operation.responseString];
        
        success ? success(response) : nil;
        
    };
    
    
    failureBlock fblk =  ^(AFHTTPRequestOperation *operation, NSError *error) {

        AFHTTPRequestOperation *storedOperation = self.dispatchTable[requestId];
        if (storedOperation == nil) {
            // 如果这个operation是被cancel的(即self.dispatchTable中对应的operation已被删除了), 那就不用处理回调了。
            return;
        } else {
            [self.dispatchTable removeObjectForKey:requestId];
        }
        
        SJAPIResponse *response = [[SJAPIResponse alloc] initWithRequestId:requestId request:operation.request responseData:operation.responseData responseString:operation.responseString error:error];
        
        fail?fail(response):nil;
        
    };
    
    
    // 跑到这里的block的时候，就已经是主线程了。
    //返回的类型就是AFHTTPRequestOperation, 含请求头, 响应头等信息, 发起一个请求之后就会返回这个对象, 只不过内部的response为(null), 回调成功之后这个对象的response就会赋值真正的响应头
    AFHTTPRequestOperation *httpRequestOperation;
    switch (type) {
        case REQUEST_GET:
            httpRequestOperation = [self.operationManager GET:url parameters:params success:sblk failure:fblk];
            break;
        case REQUEST_POST:
            httpRequestOperation = [self.operationManager POST:url parameters:params success:sblk failure:fblk];
            break;
        case REQUEST_UPLOAD:
            httpRequestOperation = [self.operationManager POST:url parameters:params constructingBodyWithBlock:upload  success:sblk failure:fblk];
            break;
            
        default:
            break;
    }
    
    self.dispatchTable[requestId] = httpRequestOperation;   //发出请求之后立即将httpRequestOperation加进dispatchTable
    return requestId;
}

//生成的id在本次APP生命周期内一直递增, 会一直记录
- (NSNumber *)generateRequestId
{
    if (_recordedRequestId == nil) {
        _recordedRequestId = @(1);
    } else {
        if ([_recordedRequestId integerValue] == NSIntegerMax) {
            _recordedRequestId = @(1);
        } else {
            _recordedRequestId = @([_recordedRequestId integerValue] + 1);
        }
    }

    return _recordedRequestId;
    
}


-(void) fillHeader:(NSDictionary* )headers
{
    if (nil != headers) {
        for (id key in headers) {
            [self.operationManager.requestSerializer setValue:[headers objectForKey:key] forHTTPHeaderField:key];
        }
    }
}

@end
