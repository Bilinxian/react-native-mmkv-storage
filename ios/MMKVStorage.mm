#import "MMKVStorage.h"
#import "SecureStorage.h"
#import "YeetJSIUtils.h"

#import <React/RCTBridge+Private.h>
#import <React/RCTUtils.h>
#import <jsi/jsi.h>

#import <MMKV/MMKV.h>

using namespace facebook;
using namespace jsi;
using namespace std;



@implementation MMKVStorage
@synthesize bridge = _bridge;
@synthesize methodQueue = _methodQueue;
NSString *rPath = @"";
NSMutableDictionary *mmkvInstances;

static dispatch_queue_t RCTGetMethodQueue()
{
    static dispatch_queue_t queue;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        queue = dispatch_queue_create("MMKVStorage.Queue", DISPATCH_QUEUE_SERIAL);
    });
    return queue;
}

SecureStorage *secureStorage;

RCT_EXPORT_MODULE()

- (dispatch_queue_t)methodQueue
{
    return RCTGetMethodQueue();
}

+ (BOOL)requiresMainQueueSetup
{
    return YES;
}

MMKV *getInstance(NSString* ID)
{
    if ([[mmkvInstances allKeys] containsObject:ID]) {
        MMKV *kv = [mmkvInstances objectForKey:ID];
        
        return kv;
    } else {
        return NULL;
    }
}


MMKV *createInstance(NSString* ID, MMKVMode mode, NSString* key, NSString* path)
{
    
    MMKV *kv;
    
    if (![key  isEqual: @""] && [path  isEqual: @""])
    {
        NSData *cryptKey = [key dataUsingEncoding:NSUTF8StringEncoding];
        kv = [MMKV mmkvWithID:ID cryptKey:cryptKey mode:mode];
    }
    else if (![path  isEqual: @""] && [key  isEqual: @""])
    {
        kv = [MMKV mmkvWithID:ID mode:mode];
    }
    else if (![path  isEqual: @""] && ![key  isEqual: @""])
    {
        NSData *cryptKey = [key dataUsingEncoding:NSUTF8StringEncoding];
        kv = [MMKV mmkvWithID:ID cryptKey:cryptKey mode:mode];
    }
    else
    {
        kv = [MMKV mmkvWithID:ID mode:mode];
    }
    [mmkvInstances setObject:kv forKey:ID];
    return kv;
}


void setIndex(MMKV *kv, NSString* type, NSString* key) {
    
    NSMutableArray *indexer = [NSMutableArray array];
    
    if ([kv containsKey:type]) {
        indexer =
        [kv getObjectOfClass:NSMutableArray.class forKey:type];
    }
    if (![indexer containsObject:key]) {
        [indexer addObject:key];
        [kv setObject:indexer forKey:type];
    }
}

NSMutableArray* getIndex(MMKV *kv, NSString* type) {
    
    NSMutableArray *indexer = [NSMutableArray array];
    
    if ([kv containsKey:type]) {
        return [kv getObjectOfClass:NSMutableArray.class forKey:type];
    } else {
        return indexer;
    }
}

void removeKeyFromIndexer(MMKV *kv, NSString* key) {
    
    NSMutableArray *index = getIndex(kv, @"stringIndex");
    
    if (index != NULL && [index containsObject:key]) {
        
        [index removeObject:key];
        [kv setObject:index forKey:@"stringIndex"];
        return;
    }
    
    index = getIndex(kv, @"intIndex");
    
    if (index != NULL && [index containsObject:key]) {
        
        [index removeObject:key];
        [kv setObject:index forKey:@"indIndex"];
        return;
    }
    
    index = getIndex(kv, @"boolIndex");
    
    if (index != NULL && [index containsObject:key]) {
        
        [index removeObject:key];
        [kv setObject:index forKey:@"boolIndex"];
        return;
    }
    
    index = getIndex(kv, @"mapIndex");
    
    if (index != NULL && [index containsObject:key]) {
        
        [index removeObject:key];
        [kv setObject:index forKey:@"mapIndex"];
        return;
    }
    
    index = getIndex(kv, @"arrayIndex");
    
    if (index != NULL && [index containsObject:key]) {
        
        [index removeObject:key];
        [kv setObject:index forKey:@"arrayIndex"];
        return;
    }
}








#pragma mark setSecureKey
RCT_EXPORT_METHOD(setSecureKey: (NSString *)alias value:(NSString *)value
                  options: (NSDictionary *)options
                  callback:(RCTResponseSenderBlock)callback
                  )
{
    
    [secureStorage setSecureKey:alias value:value options:options callback:callback];
    
}

#pragma mark getSecureKey
RCT_EXPORT_METHOD(getSecureKey:(NSString *)alias
                  callback:(RCTResponseSenderBlock)callback)
{
    
    [secureStorage getSecureKey:alias callback:callback];
    
    
}

#pragma mark secureKeyExists
RCT_EXPORT_METHOD(secureKeyExists:(NSString *)key
                  callback:(RCTResponseSenderBlock)callback)
{
    
    [secureStorage secureKeyExists:key callback:callback];
    
}
#pragma mark removeSecureKey
RCT_EXPORT_METHOD(removeSecureKey:(NSString *)key
                  callback:(RCTResponseSenderBlock)callback)
{
    
    [secureStorage removeSecureKey:key callback:callback];
    
}


static void install(jsi::Runtime & jsiRuntime)
{
    
    auto initializeMMKV = Function::createFromHostFunction(jsiRuntime,
                                                           PropNameID::forAscii(jsiRuntime,
                                                                                "initializeMMKV"),
                                                           0,
                                                           [](Runtime &runtime,
                                                              const Value &thisValue,
                                                              const Value *arguments,
                                                              size_t count) -> Value {
        
        [MMKV initializeMMKV:rPath];
        return Value::undefined();
    });
    
    jsiRuntime.global().setProperty(jsiRuntime, "initializeMMKV", move(initializeMMKV));
    
    auto setupMMKVInstance = Function::createFromHostFunction(jsiRuntime,
                                                              PropNameID::forAscii(jsiRuntime,
                                                                                   "setupMMKVInstance"),
                                                              4,
                                                              [](Runtime &runtime,
                                                                 const Value &thisValue,
                                                                 const Value *arguments,
                                                                 size_t count) -> Value {
        NSString*  ID = convertJSIStringToNSString(runtime, arguments[0].getString(
                                                                                   runtime));
        
        MMKVMode mode = (MMKVMode)(int)arguments[1].getNumber();
        NSString*  cryptKey = convertJSIStringToNSString(runtime, arguments[2].getString(
                                                                                         runtime));
        
        
        NSString* path = convertJSIStringToNSString(runtime, arguments[3].getString(
                                                                                    runtime));
        
        createInstance(ID, mode,
                       cryptKey,
                       path);
        
        return Value::null();
    });
    
    jsiRuntime.global().setProperty(jsiRuntime, "setupMMKVInstance", move(setupMMKVInstance));
    
    auto setStringMMKV = Function::createFromHostFunction(jsiRuntime,
                                                          PropNameID::forAscii(jsiRuntime,
                                                                               "setStringMMKV"),
                                                          3,
                                                          [](Runtime &runtime,
                                                             const Value &thisValue,
                                                             const Value *arguments,
                                                             size_t count) -> Value {
        MMKV *kv = getInstance(convertJSIStringToNSString(runtime, arguments[2].getString(
                                                                                          runtime)));
        
        if (!kv)
        {
            return Value::undefined();
        }
        
        NSString* key = convertJSIStringToNSString(runtime, arguments[0].getString(
                                                                                   runtime));
        
        setIndex(kv, @"stringIndex", key);
        
        [kv setString:convertJSIStringToNSString(runtime, arguments[1].getString(
                                                                                 runtime)) forKey:key];
        
        return Value::null();
    });
    
    
    
    jsiRuntime.global().setProperty(jsiRuntime, "setStringMMKV", move(setStringMMKV));
    
    
    auto getStringMMKV = Function::createFromHostFunction(jsiRuntime,
                                                          PropNameID::forAscii(jsiRuntime,
                                                                               "getStringMMKV"),
                                                          2,
                                                          [](Runtime &runtime,
                                                             const Value &thisValue,
                                                             const Value *arguments,
                                                             size_t count) -> Value {
        
        MMKV *kv = getInstance(convertJSIStringToNSString(runtime, arguments[1].getString(
                                                                                          runtime)));
        
        if (!kv)
        {
            return Value::undefined();
        }
        
        NSString* key = convertJSIStringToNSString(runtime, arguments[0].getString(
                                                                                   runtime));
        
        if ([kv containsKey:key]) {
            return Value(convertNSStringToJSIString(runtime, [kv getStringForKey:key]));
        } else {
            return Value::null();
        }
        
        
        
    });
    
    jsiRuntime.global().setProperty(jsiRuntime, "getStringMMKV", move(getStringMMKV));
    
    auto setMapMMKV = Function::createFromHostFunction(jsiRuntime,
                                                       PropNameID::forAscii(jsiRuntime,
                                                                            "setMapMMKV"),
                                                       3,
                                                       [](Runtime &runtime,
                                                          const Value &thisValue,
                                                          const Value *arguments,
                                                          size_t count) -> Value {
        MMKV *kv = getInstance(convertJSIStringToNSString(runtime, arguments[2].getString(
                                                                                          runtime)));
        
        if (!kv)
        {
            return Value::undefined();
        }
        
        NSString* key = convertJSIStringToNSString(runtime, arguments[0].getString(
                                                                                   runtime));
        
        setIndex(kv, @"mapIndex", key);
        
        [kv setString:convertJSIStringToNSString(runtime, arguments[1].getString(
                                                                                 runtime)) forKey:key];
        
        return Value::null();
    });
    
    
    
    jsiRuntime.global().setProperty(jsiRuntime, "setMapMMKV", move(setMapMMKV));
    
    
    auto getMapMMKV = Function::createFromHostFunction(jsiRuntime,
                                                       PropNameID::forAscii(jsiRuntime,
                                                                            "getMapMMKV"),
                                                       2,
                                                       [](Runtime &runtime,
                                                          const Value &thisValue,
                                                          const Value *arguments,
                                                          size_t count) -> Value {
        
        MMKV *kv = getInstance(convertJSIStringToNSString(runtime, arguments[1].getString(
                                                                                          runtime)));
        
        if (!kv)
        {
            return Value::undefined();
        }
        
        NSString* key = convertJSIStringToNSString(runtime, arguments[0].getString(
                                                                                   runtime));
        
        if ([kv containsKey:key]) {
            return Value(convertNSStringToJSIString(runtime, [kv getStringForKey:key]));
        } else {
            return Value::null();
        }
        
        
        
    });
    
    jsiRuntime.global().setProperty(jsiRuntime, "getMapMMKV", move(getMapMMKV));
    
    auto setArrayMMKV = Function::createFromHostFunction(jsiRuntime,
                                                         PropNameID::forAscii(jsiRuntime,
                                                                              "setArrayMMKV"),
                                                         3,
                                                         [](Runtime &runtime,
                                                            const Value &thisValue,
                                                            const Value *arguments,
                                                            size_t count) -> Value {
        MMKV *kv = getInstance(convertJSIStringToNSString(runtime, arguments[2].getString(
                                                                                          runtime)));
        
        if (!kv)
        {
            return Value::undefined();
        }
        
        NSString* key = convertJSIStringToNSString(runtime, arguments[0].getString(
                                                                                   runtime));
        
        setIndex(kv, @"arrayIndex", key);
        
        [kv setString:convertJSIStringToNSString(runtime, arguments[1].getString(
                                                                                 runtime)) forKey:key];
        
        return Value::null();
    });
    
    
    
    jsiRuntime.global().setProperty(jsiRuntime, "setArrayMMKV", move(setArrayMMKV));
    
    
    auto getArrayMMKV = Function::createFromHostFunction(jsiRuntime,
                                                         PropNameID::forAscii(jsiRuntime,
                                                                              "getArrayMMKV"),
                                                         2,
                                                         [](Runtime &runtime,
                                                            const Value &thisValue,
                                                            const Value *arguments,
                                                            size_t count) -> Value {
        
        MMKV *kv = getInstance(convertJSIStringToNSString(runtime, arguments[1].getString(
                                                                                          runtime)));
        
        if (!kv)
        {
            return Value::undefined();
        }
        
        NSString* key = convertJSIStringToNSString(runtime, arguments[0].getString(
                                                                                   runtime));
        
        if ([kv containsKey:key]) {
            return Value(convertNSStringToJSIString(runtime, [kv getStringForKey:key]));
        } else {
            return Value::null();
        }
        
        
        
    });
    
    jsiRuntime.global().setProperty(jsiRuntime, "getArrayMMKV", move(getArrayMMKV));
    
    
    auto setNumberMMKV = Function::createFromHostFunction(jsiRuntime,
                                                          PropNameID::forAscii(jsiRuntime,
                                                                               "setNumberMMKV"),
                                                          3,
                                                          [](Runtime &runtime,
                                                             const Value &thisValue,
                                                             const Value *arguments,
                                                             size_t count) -> Value {
        MMKV *kv = getInstance(convertJSIStringToNSString(runtime, arguments[2].getString(
                                                                                          runtime)));
        
        if (!kv)
        {
            return Value::undefined();
        }
        
        NSString* key = convertJSIStringToNSString(runtime, arguments[0].getString(
                                                                                   runtime));
        
        setIndex(kv, @"numberIndex", key);
        
        [kv setDouble:arguments[1].getNumber() forKey:key];
        
        return Value::null();
    });
    
    jsiRuntime.global().setProperty(jsiRuntime, "setNumberMMKV", move(setNumberMMKV));
    
    
    auto getNumberMMKV = Function::createFromHostFunction(jsiRuntime,
                                                          PropNameID::forAscii(jsiRuntime,
                                                                               "getNumberMMKV"),
                                                          2,
                                                          [](Runtime &runtime,
                                                             const Value &thisValue,
                                                             const Value *arguments,
                                                             size_t count) -> Value {
        
        MMKV *kv = getInstance(convertJSIStringToNSString(runtime, arguments[1].getString(
                                                                                          runtime)));
        
        if (!kv)
        {
            return Value::undefined();
        }
        
        NSString* key = convertJSIStringToNSString(runtime, arguments[0].getString(
                                                                                   runtime));
        
        if ([kv containsKey:key]) {
            return Value( [kv getDoubleForKey:key]);
        } else {
            return Value::null();
        }
        
    });
    
    jsiRuntime.global().setProperty(jsiRuntime, "getNumberMMKV", move(getNumberMMKV));
    
    auto setBoolMMKV = Function::createFromHostFunction(jsiRuntime,
                                                        PropNameID::forAscii(jsiRuntime,
                                                                             "setBoolMMKV"),
                                                        3,
                                                        [](Runtime &runtime,
                                                           const Value &thisValue,
                                                           const Value *arguments,
                                                           size_t count) -> Value {
        MMKV *kv = getInstance(convertJSIStringToNSString(runtime, arguments[2].getString(
                                                                                          runtime)));
        
        if (!kv)
        {
            return Value::undefined();
        }
        
        NSString* key = convertJSIStringToNSString(runtime, arguments[0].getString(
                                                                                   runtime));
        
        setIndex(kv, @"boolIndex", key);
        
        [kv setBool:arguments[1].getBool() forKey:key];
        
        return Value::null();
    });
    
    
    
    jsiRuntime.global().setProperty(jsiRuntime, "setBoolMMKV", move(setBoolMMKV));
    
    
    auto getBoolMMKV = Function::createFromHostFunction(jsiRuntime,
                                                        PropNameID::forAscii(jsiRuntime,
                                                                             "getBoolMMKV"),
                                                        2,
                                                        [](Runtime &runtime,
                                                           const Value &thisValue,
                                                           const Value *arguments,
                                                           size_t count) -> Value {
        
        MMKV *kv = getInstance(convertJSIStringToNSString(runtime, arguments[1].getString(
                                                                                          runtime)));
        
        if (!kv)
        {
            return Value::undefined();
        }
        
        NSString* key = convertJSIStringToNSString(runtime, arguments[0].getString(
                                                                                   runtime));
        
        if ([kv containsKey:key]) {
            return Value([kv getBoolForKey:key]);
        } else {
            return Value::null();
        }
        
        
        
    });
    
    jsiRuntime.global().setProperty(jsiRuntime, "getBoolMMKV", move(getBoolMMKV));
    
    auto removeValueMMKV = jsi::Function::createFromHostFunction(jsiRuntime,
                                                                 jsi::PropNameID::forAscii(
                                                                                           jsiRuntime,
                                                                                           "removeValueMMKV"),
                                                                 2, // key
                                                                 [](jsi::Runtime &runtime,
                                                                    const jsi::Value &thisValue,
                                                                    const jsi::Value *arguments,
                                                                    size_t count) -> jsi::Value {
        MMKV *kv = getInstance(convertJSIStringToNSString(runtime, arguments[1].getString(
                                                                                          runtime)));
        
        if (!kv)
        {
            return Value::undefined();
        }
        
        NSString* key = convertJSIStringToNSString(runtime, arguments[0].getString(
                                                                                   runtime));
        
        
        removeKeyFromIndexer(kv, key);
        [kv removeValueForKey:key];
        
        return jsi::Value::null();
    });
    jsiRuntime.global().setProperty(jsiRuntime, "removeValueMMKV", std::move(removeValueMMKV));
    
    
    auto getAllKeysMMKV = jsi::Function::createFromHostFunction(jsiRuntime,
                                                                jsi::PropNameID::forAscii(
                                                                                          jsiRuntime,
                                                                                          "getAllKeysMMKV"),
                                                                1,
                                                                [](jsi::Runtime &runtime,
                                                                   const jsi::Value &thisValue,
                                                                   const jsi::Value *arguments,
                                                                   size_t count) -> jsi::Value {
        MMKV *kv = getInstance(convertJSIStringToNSString(runtime, arguments[0].getString(
                                                                                          runtime)));
        
        if (!kv)
        {
            return Value::undefined();
        }
        
        NSArray* keys = [kv allKeys];
        
        return Value(convertNSArrayToJSIArray(runtime, keys));
    });
    jsiRuntime.global().setProperty(jsiRuntime, "getAllKeysMMKV", std::move(getAllKeysMMKV));
    
    auto getIndexMMKV = jsi::Function::createFromHostFunction(jsiRuntime,
                                                              jsi::PropNameID::forAscii(
                                                                                        jsiRuntime,
                                                                                        "getIndexMMKV"),
                                                              2,
                                                              [](jsi::Runtime &runtime,
                                                                 const jsi::Value &thisValue,
                                                                 const jsi::Value *arguments,
                                                                 size_t count) -> jsi::Value {
        MMKV *kv = getInstance(convertJSIStringToNSString(runtime, arguments[1].getString(
                                                                                          runtime)));
        if (!kv)
        {
            return Value::undefined();
        }
        
        NSMutableArray* keys = getIndex(kv, convertJSIStringToNSString(runtime, arguments[0].getString(
                                                                                                       runtime)));
        return Value(convertNSArrayToJSIArray(runtime, keys));
    });
    
    jsiRuntime.global().setProperty(jsiRuntime, "getIndexMMKV", std::move(getIndexMMKV));
    
    
    auto containsKeyMMKV = jsi::Function::createFromHostFunction(jsiRuntime,
                                                                 jsi::PropNameID::forAscii(
                                                                                           jsiRuntime,
                                                                                           "containsKeyMMKV"),
                                                                 2,
                                                                 [](jsi::Runtime &runtime,
                                                                    const jsi::Value &thisValue,
                                                                    const jsi::Value *arguments,
                                                                    
                                                                    size_t count) -> jsi::Value {
        MMKV *kv = getInstance(convertJSIStringToNSString(runtime, arguments[1].getString(
                                                                                          runtime)));
        if (!kv)
        {
            return Value::undefined();
        }
        return Value([kv containsKey:convertJSIStringToNSString(runtime, arguments[0].getString(
                                                                                                runtime))]);
    });
    jsiRuntime.global().setProperty(jsiRuntime, "containsKeyMMKV", std::move(containsKeyMMKV));
    
    auto clearMMKV = jsi::Function::createFromHostFunction(jsiRuntime,
                                                           jsi::PropNameID::forAscii(
                                                                                     jsiRuntime,
                                                                                     "clearMMKV"),
                                                           1,
                                                           [](jsi::Runtime &runtime,
                                                              const jsi::Value &thisValue,
                                                              const jsi::Value *arguments,
                                                              
                                                              size_t count) -> jsi::Value {
        MMKV *kv = getInstance(convertJSIStringToNSString(runtime, arguments[1].getString(
                                                                                          runtime)));
        if (!kv)
        {
            return Value::undefined();
        }
        
        [kv clearAll];
        
        return Value::null();
    });
    jsiRuntime.global().setProperty(jsiRuntime, "clearMMKV", std::move(clearMMKV));
    
    auto encryptMMKV = jsi::Function::createFromHostFunction(jsiRuntime,
                                                             jsi::PropNameID::forAscii(
                                                                                       jsiRuntime,
                                                                                       "encryptMMKV"),
                                                             2,
                                                             [](jsi::Runtime &runtime,
                                                                const jsi::Value &thisValue,
                                                                const jsi::Value *arguments,
                                                                
                                                                size_t count) -> jsi::Value {
        MMKV *kv = getInstance(convertJSIStringToNSString(runtime, arguments[1].getString(
                                                                                          runtime)));
        if (!kv)
        {
            return Value::undefined();
        }
        
        
        NSString* key = convertJSIStringToNSString(runtime, arguments[0].getString(
                                                                                   runtime));
        
        NSData *cryptKey = [key dataUsingEncoding:NSUTF8StringEncoding];
        [kv reKey:cryptKey];
        
        return Value(true);
    });
    
    jsiRuntime.global().setProperty(jsiRuntime, "encryptMMKV", std::move(encryptMMKV));
    
    auto decryptMMKV = jsi::Function::createFromHostFunction(jsiRuntime,
                                                             jsi::PropNameID::forAscii(
                                                                                       jsiRuntime,
                                                                                       "decryptMMKV"),
                                                             2,
                                                             [](jsi::Runtime &runtime,
                                                                const jsi::Value &thisValue,
                                                                const jsi::Value *arguments,
                                                                
                                                                size_t count) -> jsi::Value {
        MMKV *kv = getInstance(convertJSIStringToNSString(runtime, arguments[1].getString(
                                                                                          runtime)));
        if (!kv)
        {
            return Value::undefined();
        }
        
        [kv reKey:NULL];
        
        return Value(true);
    });
    
    jsiRuntime.global().setProperty(jsiRuntime, "decryptMMKV", std::move(decryptMMKV));
}




- (void)setBridge:(RCTBridge *)bridge
{
    _bridge = bridge;
    _setBridgeOnMainQueue = RCTIsMainQueue();
    secureStorage = [[SecureStorage alloc]init];
    mmkvInstances = [NSMutableDictionary dictionary];   

    RCTCxxBridge *cxxBridge = (RCTCxxBridge *)self.bridge;
    if (!cxxBridge.runtime) {
        return;
    }
    
  
    
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES);
    NSString *libraryPath = (NSString *) [paths firstObject];
    NSString *rootDir = [libraryPath stringByAppendingPathComponent:@"mmkv"];
    rPath = rootDir;
    [MMKV initializeMMKV:rootDir];
    createInstance(@"mmkvIDStore", MMKVSingleProcess, @"", @"");
    install(*(jsi::Runtime *)cxxBridge.runtime);
}

@end
