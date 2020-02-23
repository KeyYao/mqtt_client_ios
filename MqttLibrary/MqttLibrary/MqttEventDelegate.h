//
//  MqttEventDelegate.h
//  library
//
//  Created by Key.Yao on 2020/2/23.
//  Copyright © 2020 Key.Yao. All rights reserved.
//

#ifndef MqttEventDelegate_h
#define MqttEventDelegate_h

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@protocol MqttEventDelegate <NSObject>

@required

- (void)onMessage:(NSString *)message forTopic:(NSString *)topic;
- (void)onConnnect;
- (void)onConnnectWithFlag:(NSInteger)flags;
- (void)onDisconnect;
- (void)onPublish;
- (void)onSubscribe;
- (void)onUnsubscribe;
- (void)onLog:(NSString *)log forLevel:(NSInteger)level;

@end

NS_ASSUME_NONNULL_END

#endif /* MqttEventDelegate_h */
