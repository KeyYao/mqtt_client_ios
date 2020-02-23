//
//  MqttClient.m
//  library
//
//  Created by Key.Yao on 2020/2/23.
//  Copyright © 2020 Key.Yao. All rights reserved.
//

#import "MqttClient.h"
#include "mosquitto_wrapper.h"

using namespace mqttclient;

#pragma mark - Objective-C define
@interface MqttClient ()

@property (nonatomic, assign) long ptr;

@end

#pragma mark - c++ define
class ExtraData {
public:
    MqttClient *ocInstance;
    NSString *host;
    int port;
    BOOL loopBreakFlag = NO;
    NSLock *reconnectLock;
};

static void mqtt_on_message(void *instance, const struct mosquitto_message * message);
static void mqtt_on_connect(void *instance, int rc);
static void mqtt_on_connect_with_flag(void *instance, int rc, int flags);
static void mqtt_on_disconnect(void *instance, int rc);
static void mqtt_on_publish(void *instance, int rc);
static void mqtt_on_subscribe(void *instance, int mid, int qos_count, const int * granted_qos);
static void mqtt_on_unsubscribe(void *instance, int rc);
static void mqtt_on_log(void *instance, int level, const char * str);


#pragma mark - Objective-C implement
@implementation MqttClient

@synthesize ptr = _ptr;
@synthesize eventDelegate = _eventDelegate;


+ (instancetype)shareClient
{
    static MqttClient *client;
    
    static dispatch_once_t onceToken;
    
    dispatch_once(&onceToken, ^{
        
        client = [[super allocWithZone:NULL] init];
        
    });
    
    return client;
}

+ (id)allocWithZone:(struct _NSZone *)zone
{
    return [MqttClient shareClient];
}

- (instancetype)init
{
    self = [super init];
    
    if (self) {
        mqttclient::lib_init();
    }
    
    return self;
}

- (void)dealloc
{
    mqttclient::lib_cleanup();
}

- (void)startWithHost:(NSString *)hostString port:(NSInteger)port uuid:(NSString *)uuidString clearSession:(BOOL)clearSessionFlag
{
    [self startInternalWithHost:hostString port:port uuid:uuidString clearSession:clearSessionFlag isTLS:NO caFilePath:@"" username:@"" password:@""];
}

- (void)startWithHost:(NSString *)hostString port:(NSInteger)port uuid:(NSString *)uuidString clearSession:(BOOL)clearSessionFlag caFilePath:(NSString *)caFilePathString username:(NSString *)usernameString password:(NSString *)passwordString
{
    [self startInternalWithHost:hostString port:port uuid:uuidString clearSession:clearSessionFlag isTLS:YES caFilePath:caFilePathString username:usernameString password:passwordString];
}

- (void)reconnect
{
    if (!self.ptr)
    {
        return;
    }
    [self reconnectService:self.ptr];
}

- (void)subscribeTopic:(NSString *)topicString
{
    if (!self.ptr)
    {
        return;
    }
    [self subscribeTopic:topicString withQos:0 toService:self.ptr];
}

- (void)subscribeTopic:(NSString *)topicString withQos:(NSInteger)qos
{
    if (!self.ptr)
    {
        return;
    }
    [self subscribeTopic:topicString withQos:qos toService:self.ptr];
}

- (void)unsubscribeTopic:(NSString *)topicString
{
    if (!self.ptr)
    {
        return;
    }
    [self unsubscribeTopic:topicString toService:self.ptr];
}

- (void)publishMessage:(NSString *)messageString forTopic:(NSString *)topicString
{
    if (!self.ptr)
    {
        return;
    }
    [self publishMessage:messageString forTopic:topicString withQos:0 toService:self.ptr];
}

- (void)publishMessage:(NSString *)messageString forTopic:(NSString *)topicString withQos:(NSInteger)qos
{
    if (!self.ptr)
    {
        return;
    }
    [self publishMessage:messageString forTopic:topicString withQos:qos toService:self.ptr];
}


#pragma mark - private method
+ (void)log:(NSString *)message
{
#ifdef DEBUG
    NSLog(@"MqttClient: %@", message);
#else
    
#endif
    
}

- (void)startInternalWithHost:(NSString *)hostString port:(NSInteger)port uuid:(NSString *)uuidString clearSession:(BOOL)clearSessionFlag isTLS:(BOOL)isTLSFlag caFilePath:(NSString *)caFilePathString username:(NSString *)usernameString password:(NSString *)passwordString
{
    if (!self.ptr) {
        // init
        self.ptr = [self initServiceWithHost:hostString port:port uuid:uuidString clearSession:clearSessionFlag isTLS:isTLSFlag caFilePath:caFilePathString username:usernameString password:passwordString];
    }
    // start
    [self startService:self.ptr];
}

- (long)initServiceWithHost:(NSString *)hostString port:(NSInteger)port uuid:(NSString *)uuidString clearSession:(BOOL)clearSessionFlag isTLS:(BOOL)isTLSFlag caFilePath:(NSString *)caFilePathString username:(NSString *)usernameString password:(NSString *)passwordString
{
    
    const char *caFile = [caFilePathString UTF8String];
    const char *uuid = [uuidString UTF8String];
    const char *username = [usernameString UTF8String];
    const char *password = [passwordString UTF8String];
    
    mosquitto_wrapper *mosq = new mosquitto_wrapper(uuid, clearSessionFlag);
    
    mosq->on_connect_callback = mqtt_on_connect;
    mosq->on_connect_with_flag_callback = mqtt_on_connect_with_flag;
    mosq->on_disconnect_callback = mqtt_on_disconnect;
    mosq->on_publish_callback = mqtt_on_publish;
    mosq->on_message_callback = mqtt_on_message;
    mosq->on_subscribe_callback = mqtt_on_subscribe;
    mosq->on_unsubscribe_callback = mqtt_on_unsubscribe;
    mosq->on_log_callback = mqtt_on_log;
    
    if (isTLSFlag)
    {
        mosq->tls_insecure_set(true);
        mosq->tls_opts_set(1, "tlsv1", nullptr);
        if (strlen(caFile) != 0) {
            mosq->tls_set(caFile);
        }
        if (strlen(username) != 0 && strlen(password) != 0) {
            mosq->username_pw_set(username, password);
        }
    }
    
    ExtraData *extra = new ExtraData();
    extra->ocInstance = self;
    extra->host = hostString;
    extra->port = (int) port;
    extra->reconnectLock = [[NSLock alloc] init];
    
    mosq->extra = extra;
    
    return reinterpret_cast<long>(mosq);
}

- (void)startService:(long)ptr
{
    if (!ptr)
    {
        return;
    }
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        
        mosquitto_wrapper *mosq = reinterpret_cast<mosquitto_wrapper *>(ptr);
        
        if (!mosq)
        {
            return;
        }
        
        ExtraData *extra = reinterpret_cast<ExtraData *>(mosq->extra);
        
        mosq->connect([extra->host UTF8String], extra->port);
        
        while (1)
        {
            int rc = mosq->loop();
            if (extra->loopBreakFlag)
            {
                break;
            }
            if (rc != MOSQ_ERR_SUCCESS)
            {
                const char *errMsg = mqttclient::strerror(rc);
                [MqttClient log:[NSString stringWithFormat:@"connect error: %s", errMsg]];
            }
            if (rc)
            {
                sleep(10);
                mosq->reconnect();
            }
        }
        
        extra->ocInstance = nil;
        extra->host = nil;
        extra->reconnectLock = nil;
        
        mosq->extra = NULL;
        delete extra;
        
        delete mosq;
    });
}

- (void)reconnectService:(long)ptr
{
    mosquitto_wrapper *mosq = reinterpret_cast<mosquitto_wrapper *>(ptr);
    if (!mosq->extra) {
        return;
    }
    ExtraData *extra = reinterpret_cast<ExtraData *>(mosq->extra);
    if (!extra) {
        return;
    }
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [extra->reconnectLock lock];
        mosq->disconnect();
        [extra->reconnectLock unlock];
    });
}

- (void)subscribeTopic:(nonnull NSString *)topicString withQos:(NSInteger)qos toService:(long)ptr
{
    mosquitto_wrapper *mosq = reinterpret_cast<mosquitto_wrapper *>(ptr);
    int mid;
    mosq->subscribe(&mid, [topicString UTF8String], (int)qos);
    [MqttClient log:[NSString stringWithFormat:@"subscribe topic: %@", topicString]];
}

- (void)unsubscribeTopic:(nonnull NSString *)topicString toService:(long)ptr
{
    mosquitto_wrapper *mosq = reinterpret_cast<mosquitto_wrapper *>(ptr);
    int mid;
    mosq->unsubscribe(&mid, [topicString UTF8String]);
    [MqttClient log:[NSString stringWithFormat:@"unsubscribe topic: %@", topicString]];
}

- (void)publishMessage:(nonnull NSString *)messageString forTopic:(nonnull NSString *)topicString withQos:(NSInteger)qos toService:(long)ptr
{
    const char *topic = [topicString UTF8String];
    const char *message = [messageString UTF8String];
    
    mosquitto_wrapper *mosq = reinterpret_cast<mosquitto_wrapper *>(ptr);
    mosq->publish(NULL, topic, (int) strlen(message), message, (int) qos);
    [MqttClient log:[NSString stringWithFormat:@"publish message: %@, for topic: %@", messageString, topicString]];
}

@end

#pragma mark - c++ implement
void mqtt_on_message(void *instance, const struct mosquitto_message * message)
{
    if (!instance)
    {
        return;
    }
    mosquitto_wrapper *mosq = reinterpret_cast<mosquitto_wrapper *>(instance);
    
    if (!mosq)
    {
        return;
    }
    
    ExtraData *extra = reinterpret_cast<ExtraData *>(mosq->extra);
    
    if (!extra)
    {
        return;
    }
    
    if (extra->ocInstance.eventDelegate)
    {
        NSString *topicString = [NSString stringWithUTF8String:message->topic];
        NSString *messageString = [NSString stringWithUTF8String:(char *)message->payload];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            [extra->ocInstance.eventDelegate onMessage:messageString forTopic:topicString];
        });
    }
}

void mqtt_on_connect(void *instance, int rc)
{
    if (!instance)
    {
        return;
    }
    mosquitto_wrapper *mosq = reinterpret_cast<mosquitto_wrapper *>(instance);
    
    if (!mosq)
    {
        return;
    }
    
    ExtraData *extra = reinterpret_cast<ExtraData *>(mosq->extra);
    
    if (!extra)
    {
        return;
    }
    
    if (extra->ocInstance.eventDelegate)
    {
        dispatch_async(dispatch_get_main_queue(), ^{
            [extra->ocInstance.eventDelegate onConnnect];
        });
    }
}

void mqtt_on_connect_with_flag(void *instance, int rc, int flags)
{
    if (!instance)
    {
        return;
    }
    mosquitto_wrapper *mosq = reinterpret_cast<mosquitto_wrapper *>(instance);
    
    if (!mosq)
    {
        return;
    }
    
    ExtraData *extra = reinterpret_cast<ExtraData *>(mosq->extra);
    
    if (!extra)
    {
        return;
    }
    
    if (extra->ocInstance.eventDelegate)
    {
        dispatch_async(dispatch_get_main_queue(), ^{
            [extra->ocInstance.eventDelegate onConnnectWithFlag:flags];
        });
    }
}

void mqtt_on_disconnect(void *instance, int rc)
{
    if (!instance)
    {
        return;
    }
    mosquitto_wrapper *mosq = reinterpret_cast<mosquitto_wrapper *>(instance);
    
    if (!mosq)
    {
        return;
    }
    
    ExtraData *extra = reinterpret_cast<ExtraData *>(mosq->extra);
    
    if (!extra)
    {
        return;
    }
    
    if (extra->ocInstance.eventDelegate)
    {
        dispatch_async(dispatch_get_main_queue(), ^{
            [extra->ocInstance.eventDelegate onDisconnect];
        });
    }
}

void mqtt_on_publish(void *instance, int rc)
{
    if (!instance)
    {
        return;
    }
    mosquitto_wrapper *mosq = reinterpret_cast<mosquitto_wrapper *>(instance);
    
    if (!mosq)
    {
        return;
    }
    
    ExtraData *extra = reinterpret_cast<ExtraData *>(mosq->extra);
    
    if (!extra)
    {
        return;
    }
    
    if (extra->ocInstance.eventDelegate)
    {
        dispatch_async(dispatch_get_main_queue(), ^{
            [extra->ocInstance.eventDelegate onPublish];
        });
    }
}

void mqtt_on_subscribe(void *instance, int mid, int qos_count, const int * granted_qos)
{
    if (!instance)
    {
        return;
    }
    mosquitto_wrapper *mosq = reinterpret_cast<mosquitto_wrapper *>(instance);
    
    if (!mosq)
    {
        return;
    }
    
    ExtraData *extra = reinterpret_cast<ExtraData *>(mosq->extra);
    
    if (!extra)
    {
        return;
    }
    
    if (extra->ocInstance.eventDelegate)
    {
        dispatch_async(dispatch_get_main_queue(), ^{
            [extra->ocInstance.eventDelegate onSubscribe];
        });
    }
}

void mqtt_on_unsubscribe(void *instance, int rc)
{
    if (!instance)
    {
        return;
    }
    mosquitto_wrapper *mosq = reinterpret_cast<mosquitto_wrapper *>(instance);
    
    if (!mosq)
    {
        return;
    }
    
    ExtraData *extra = reinterpret_cast<ExtraData *>(mosq->extra);
    
    if (!extra)
    {
        return;
    }
    
    if (extra->ocInstance.eventDelegate)
    {
        dispatch_async(dispatch_get_main_queue(), ^{
            [extra->ocInstance.eventDelegate onUnsubscribe];
        });
    }
}

void mqtt_on_log(void *instance, int level, const char * str)
{
    if (!instance)
    {
        return;
    }
    mosquitto_wrapper *mosq = reinterpret_cast<mosquitto_wrapper *>(instance);
    
    if (!mosq)
    {
        return;
    }
    
    ExtraData *extra = reinterpret_cast<ExtraData *>(mosq->extra);
    
    if (!extra)
    {
        return;
    }
    
    if (extra->ocInstance.eventDelegate)
    {
        NSString *messageString = [NSString stringWithUTF8String:str];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            [extra->ocInstance.eventDelegate onLog:messageString forLevel:level];
        });
    }
}
