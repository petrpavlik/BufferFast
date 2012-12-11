//
//  AFBufferHTTPClient.m
//  BufferTest
//
//  Created by Petr Pavlik on 11/29/12.
//  Copyright (c) 2012 Petr Pavlik. All rights reserved.
//

#import "AFBufferHTTPClient.h"

#import "AFJSONRequestOperation.h"

static NSString * const kAFBufferAPIBaseURLString = @"https://api.bufferapp.com/1/";

@implementation AFBufferHTTPClient

+ (AFBufferHTTPClient*)sharedClient {
    
    static AFBufferHTTPClient *_sharedClient = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _sharedClient = [[AFBufferHTTPClient alloc] initWithBaseURL:[NSURL URLWithString:kAFBufferAPIBaseURLString]];
    });
    
    return _sharedClient;
}

- (id)initWithBaseURL:(NSURL *)url {
    self = [super initWithBaseURL:url];
    if (!self) {
        return nil;
    }
    
    [self registerHTTPOperationClass:[AFJSONRequestOperation class]];
    
    // Accept HTTP Header; see http://www.w3.org/Protocols/rfc2616/rfc2616-sec14.html#sec14.1
	[self setDefaultHeader:@"Accept" value:@"application/json"];
    
    return self;
}

@end
