# iOS Mqtt Client
基于[mosquitto](https://github.com/eclipse/mosquitto)的iOS mqtt客户端
* 使用[mosquitto/lib](https://github.com/eclipse/mosquitto/tree/master/lib)的代码，用c++封装接口
* 对外提供objc接口，简单易用
* 支持OpenSSL加密
* 实现订阅、解除订阅、发布消息等功能

## 接口
MqttClient.h
```objc
/**
 * 获取单例
 */
+ (instancetype)shareClient;
```
```objc
/**
 * 启动mqtt服务
 */
- (void)startWithHost:(NSString *)hostString port:(NSInteger)port uuid:(NSString *)uuidString clearSession:(BOOL)clearSessionFlag;
- (void)startWithHost:(NSString *)hostString port:(NSInteger)port uuid:(NSString *)uuidString clearSession:(BOOL)clearSessionFlag caFilePath:(NSString *)caFilePathString username:(NSString *)usernameString password:(NSString *)passwordString;
```
```objc
/**
 * 重连服务
 */
- (void)reconnect;
```
```objc
/**
 * 订阅主题
 */
- (void)subscribeTopic:(NSString *)topicString;
- (void)subscribeTopic:(NSString *)topicString withQos:(NSInteger)qos;
```
```objc
/**
 * 解除订阅
 */
- (void)unsubscribeTopic:(NSString *)topicString;
```
```objc
/**
 * 发布消息
 */
- (void)publishMessage:(NSString *)messageString forTopic:(NSString *)topicString;
- (void)publishMessage:(NSString *)messageString forTopic:(NSString *)topicString withQos:(NSInteger)qos;
```
MqttEventDelegate.h
```objc
/**
 * mqtt事件回调接口
 */
- (void)onMessage:(NSString *)message forTopic:(NSString *)topic;
- (void)onConnnect;
- (void)onConnnectWithFlag:(NSInteger)flags;
- (void)onDisconnect;
- (void)onPublish;
- (void)onSubscribe;
- (void)onUnsubscribe;
- (void)onLog:(NSString *)log forLevel:(NSInteger)level;
```
## 使用
导入Module：XCode -> File -> Add Files to ... -> 选中 /MqttLibrary/MqttLibrary.xcodeproj -> 选中目标target -> 点击add添加
```swift
swift：
/// 引入模块
import MqttLibrary

MqttClient.share()
```

## 例子
app module只实现了简单的调用，相关日志输出到了控制台