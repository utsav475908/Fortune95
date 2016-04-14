//
//  SKYKeychainService.m
//  SkyBell
//
//  Created by Juan Jose Karam on 8/25/15.
//  Copyright (c) 2015 SkyBell Technologies, Inc. All rights reserved.
//

#import "SKYKeychainService.h"

static NSString * const kSkybellKeychainService = @"kSkybellKeychainService";

@implementation SKYKeychainService

+ (instancetype)defaultKeychainService {
    static SKYKeychainService *_defaultKeychainService = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _defaultKeychainService = [[SKYKeychainService alloc] init];
    });
    
    return _defaultKeychainService;
}

- (NSDictionary *)queryDictionaryForIdentifier:(NSString *)identifier {
    NSCParameterAssert(identifier);
    
    return @{
             (__bridge id)kSecClass : (__bridge id)kSecClassGenericPassword,
             (__bridge id)kSecAttrService : kSkybellKeychainService,
             (__bridge id)kSecAttrAccount : identifier,
             (__bridge id)kSecAttrAccessible : (__bridge id)kSecAttrAccessibleWhenUnlocked
             };
}

- (BOOL)storeObject:(id)object withIdentifier:(NSString *)identifier {
    if (!object) {
        return [self deleteObjectWithIdentifier:identifier];
    }
    
    NSDictionary *queryDictionary = [[self queryDictionaryForIdentifier:identifier] mutableCopy];
    NSDictionary *dataDictionary = @{
                                      (__bridge id)kSecValueData : [NSKeyedArchiver archivedDataWithRootObject:object],
                                      (__bridge id)kSecAttrAccessible : (__bridge id)kSecAttrAccessibleWhenUnlocked
                                     };
    OSStatus status;
    BOOL objectForKeyExist = ([self retrieveObjectWithIdentifier:identifier] != nil);
    if (objectForKeyExist) {
        status = SecItemUpdate((__bridge CFDictionaryRef)queryDictionary, (__bridge CFDictionaryRef)dataDictionary);
    } else {
        NSMutableDictionary *addDictionary = [queryDictionary mutableCopy];
        [addDictionary addEntriesFromDictionary:dataDictionary];
        status = SecItemAdd((__bridge CFDictionaryRef)addDictionary, NULL);
    }
    
    if (status != errSecSuccess) {
#if DEBUG
        NSLog(@"Unable to %@ credential with identifier \"%@\" (Error %li)", objectForKeyExist ? @"update" : @"add", identifier, (long int)status);
#endif
    }
    
    return (status == errSecSuccess);
}

- (id)retrieveObjectWithIdentifier:(NSString *)identifier {
    NSMutableDictionary *queryDictionary = [[self queryDictionaryForIdentifier:identifier] mutableCopy];
    queryDictionary[(__bridge id)kSecReturnData] = (__bridge id)kCFBooleanTrue;
    queryDictionary[(__bridge id)kSecMatchLimit] = (__bridge id)kSecMatchLimitOne;
    
    CFDataRef result = nil;
    OSStatus status = SecItemCopyMatching((__bridge CFDictionaryRef)queryDictionary, (CFTypeRef *)&result);
    
    if (status != errSecSuccess) {
        if ((long int)status == -34018) {
            self.didFailToReadKeychain = YES;
        }
#if DEBUG
        NSLog(@"Unable to fetch credential with identifier \"%@\" (Error %li)", identifier, (long int)status);
#endif
        return nil;
    }
    
    return [NSKeyedUnarchiver unarchiveObjectWithData:(__bridge_transfer NSData *)result];
}

- (BOOL)deleteObjectWithIdentifier:(NSString *)identifier {
    NSDictionary *queryDictionary = [self queryDictionaryForIdentifier:identifier];
    OSStatus status = SecItemDelete((__bridge CFDictionaryRef)queryDictionary);
    
    if (status != errSecSuccess) {
#if DEBUG
        NSLog(@"Unable to delete credential with identifier \"%@\" (Error %li)", identifier, (long int)status);
#endif
    }
    
    return (status == errSecSuccess);
}

@end
