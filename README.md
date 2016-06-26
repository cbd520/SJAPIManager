# SJAPIManager
基于 AFNetworking 封装的 iOS 网络库

本框架把每一个网络请求封装成对象。所以使用SJAPIManager，你的每一个请求都需要继承SJAPIBaseManager类，通过覆盖父类的一些方法来构造指定的网络请求。

本框架提供了以下功能  
* 封装了一层网络访问抽象, 可以方便的替换或者升级AFNetworking  
* 支持按时间, 登陆状态, 版本号缓存网络请求数据   
* 在发送请求, 回调等位置均设置拦截器, 用于验证是否合法  
* 支持检查返回的 JSON 是否合法  
* 采用delegate方式回调  
* ...

使用方法举例:  
用Demo中的TestAPI举例:  
1.将`TestAPI`接口封装成类, 继承于`SJAPIBaseManager`  
2.在具体api的init方法中设置相关代理, 一般该api作为代理, 即`self.paramSource = self;` 等等  
3.遵守协议`<SJAPIManager, SJAPIManagerParamSourceDelegate, SJAPIManagerHeaderSourceDelegate, 等等>`, 每个协议具体功能及需要实现哪些方法见协议方法  
举例 :

```
* 设置请求类型  - (SJAPIManagerRequestType)requestType , 
* 设置是否需要缓存(默认需要)     - (BOOL)shouldCache
* 如果需要在某些时刻清除特定缓存, 需实现     - (NSString *)cacheRegexKey 
* 设置url     - (NSString *)requestUrl , 
* 设置参数     - (NSDictionary *)paramsForAPI:(SJAPIBaseManager *)manager , 
* 设置请求头    - (NSDictionary *)headersForAPI:(SJAPIBaseManager *)manager
* 请求数据回调成功后, 可以在拦截器中-(void)beforePerformSuccessWithResponse:(SJAPIResponse *)response 中预处理, 供控制器使用
* 其他使用见源码
```

4.在控制器内懒加载`TestAPI`, 同时设置`_testAPI.delegate = self`, 指定该控制器为接口的代理, 实现下面两个回调方法  
 
```
- (void)managerCallAPIDidSuccess:(SJAPIBaseManager *)manager;  
- (void)managerCallAPIDidFailed:(SJAPIBaseManager *)manager;
```
  
5.在要调用接口的时候,`[self.testAPI loadData]`即可;  
6.如果要在特定时刻或者某些情况删除缓存, 可以发通知实现, 通知的userInfo这种格式`@{InvalidCacheKey : @[NSClassFromString(@"TestAPI"), ]}`  

```
-(void)handleInvalidCache:(NSNotification*)notify
 {
    NSDictionary* dict = notify.userInfo;
    NSArray* arr = [dict objectForKey:SBInvalidCacheKey];
    for (Class cls in arr) {
        [[SJCache sharedInstance] deleteCacheWithClass:cls];
    }
 }
 ```
 7.其他用法见源码, 自己理解




