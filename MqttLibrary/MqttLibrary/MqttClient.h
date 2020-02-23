//
//  MqttClient.h
//  library
//
//  Created by Key.Yao on 2020/2/23.
//  Copyright © 2020 Key.Yao. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MqttEventDelegate.h"

NS_ASSUME_NONNULL_BEGIN

@interface MqttClient : NSObject

@property (nonatomic, weak) id<MqttEventDelegate> eventDelegate;

+ (instancetype)shareClient;

- (void)startWithHost:(NSString *)hostString port:(NSInteger)port uuid:(NSString *)uuidString clearSession:(BOOL)clearSessionFlag;

- (void)startWithHost:(NSString *)hostString port:(NSInteger)port uuid:(NSString *)uuidString clearSession:(BOOL)clearSessionFlag caFilePath:(NSString *)caFilePathString username:(NSString *)usernameString password:(NSString *)passwordString;

- (void)reconnect;

- (void)subscribeTopic:(NSString *)topicString;

- (void)subscribeTopic:(NSString *)topicString withQos:(NSInteger)qos;

- (void)unsubscribeTopic:(NSString *)topicString;

- (void)publishMessage:(NSString *)messageString forTopic:(NSString *)topicString;

- (void)publishMessage:(NSString *)messageString forTopic:(NSString *)topicString withQos:(NSInteger)qos;

@end

NS_ASSUME_NONNULL_END
