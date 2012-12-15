//
//  AFPastebinHTTPClient.m
//  BufferFast
//
//  Created by Petr Pavlik on 12/15/12.
//  Copyright (c) 2012 Petr Pavlik. All rights reserved.
//

#import "AFPastebinHTTPClient.h"
#import "AFJSONRequestOperation.h"

static NSString * const kAFBufferAPIBaseURLString = @"http://pastebin.com/api/";

@implementation AFPastebinHTTPClient

+ (AFPastebinHTTPClient*)sharedClient {
    
    static AFPastebinHTTPClient *_sharedClient = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _sharedClient = [[AFPastebinHTTPClient alloc] initWithBaseURL:[NSURL URLWithString:kAFBufferAPIBaseURLString]];
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
