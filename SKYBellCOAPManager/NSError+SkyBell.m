//
//  NSError+SkyBell.m
//  SkyBell
//
//  Created by Luis Hernandez on 7/14/15.
//  Copyright (c) 2015 SkyBell Technologies, Inc. All rights reserved.
//

#import "NSError+SkyBell.h"

@implementation NSError (SkyBell)

//UNIQUE_KEY( SKYWebServiceErrorDomain );
//UNIQUE_KEY( SKYDeviceStreamingErrorDomain );
//UNIQUE_KEY( SKYCoAPErrorDomain );
//UNIQUE_KEY( SKYErrorHTTPResponseUserInfoKey );
//UNIQUE_KEY( SKYErrorAlertTitleUserInfoKey );
//UNIQUE_KEY( SKYErrorAlertMessageUserInfoKey );

- (NSUInteger)httpErrorCode {
    NSHTTPURLResponse *httpUrlResponse = [self.userInfo valueForKey:@"com.alamofire.serialization.response.error.response"];

    if (!httpUrlResponse) {
        NSError *internalError = [self.userInfo valueForKey:@"NSUnderlyingError"];
        if (internalError) {
            httpUrlResponse = [internalError.userInfo valueForKey:@"com.alamofire.serialization.response.error.response"];
        }
    }
    return httpUrlResponse.statusCode;
}

+ (instancetype)SKYWebServiceHTTPError: (NSHTTPURLResponse *)response {
//    NSString *title = NSLocalizedStringWithDefaultValue( @"IDCWebServiceHTTPAlertTitle", nil, [NSBundle mainBundle], @"Server Error", nil );
//    NSString *action = [[response URL] lastPathComponent];
//    NSString *messageFormat = NSLocalizedStringWithDefaultValue( @"IDCWebServiceHTTPAlertMessage", nil, [NSBundle mainBundle], @"A server error occurred. [%@/%d]", nil );
//    NSString *message = [NSString stringWithFormat: messageFormat, action, [response statusCode]];
//    NSDictionary *userInfo = @{
//                               NSLocalizedDescriptionKey : message,
//                               SKYErrorHTTPResponseUserInfoKey : response,
//                               SKYErrorAlertTitleUserInfoKey : title,
//                               SKYErrorAlertMessageUserInfoKey : message,
//                               };
//
//    return [[self class] errorWithDomain: SKYWebServiceErrorDomain code: [response statusCode] userInfo: userInfo];
    return @"this is getting called";
}

+ (instancetype)SKYCoAPErrorWithCode:(SKYCoAPError)code userInfo:(NSDictionary *)dictionary {
//    return [[self class] errorWithDomain:SKYCoAPErrorDomain code:code userInfo:dictionary];
     return @"this is getting called";
}

@end
