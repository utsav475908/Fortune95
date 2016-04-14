//
//  SKYCallConfiguration.m
//  SkyBell
//
//  Created by Gabriel Sosa Martínez on 5/1/15.
//  Copyright (c) 2015 SkyBell Technologies, Inc. All rights reserved.
//

#import "SKYCallConfiguration.h"

@implementation SKYCallConfiguration

#pragma mark -
#pragma mark Instance Setup and Teardown

- (instancetype)init {
    if ((self = [super init])) {
        _destinationHost = nil;
        _destinationAudioPort = 0;
        _destinationVideoPort = 0;
        _localAudioPort = SKYCallConfigurationDefaultAudioPort;
        _localVideoPort = SKYCallConfigurationDefaultVideoPort;
        _callId = nil;
        _deviceId = nil;
        _callTrigger = SKYCallTriggerUndefined;
        _role = kRoleClient;
    }

    return self;
}

- (NSString *)triggerDescription {
    NSString *description = nil;

    switch (_callTrigger) {
        case SKYCallTriggerMobileInitiated:
            description = @"mobile initiated call";
            break;

        case SKYCallTriggerSkyBellButtonInitiated:
        case SKYCallTriggerSkyBellMotionSensorInitiated:
        case SKYCallTriggerSkyBellSoundSensorInitiated:
        case SKYCallTriggerSkyBellApiInitiated:
            description = @"button call";
            break;

        default:
            description = @"undefined";
            break;
    }

    return description;
}

@end
