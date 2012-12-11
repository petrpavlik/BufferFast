//
//  AppDelegate.m
//  BufferFast
//
//  Created by Petr Pavlik on 12/7/12.
//  Copyright (c) 2012 Petr Pavlik. All rights reserved.
//

#import "AppDelegate.h"
#import "AFBufferHTTPClient.h"
#import "StatusBarView.h"

@interface AppDelegate ()

@property(nonatomic, strong) NSArray* availableServices;
@property(nonatomic, strong) NSStatusItem* statusItem;

@end

@implementation AppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    // Insert code here to initialize your application
    
    float height = [[NSStatusBar systemStatusBar] thickness];
    
    self.statusItem = [[NSStatusBar systemStatusBar] statusItemWithLength:75];
    
    [self.statusItem setHighlightMode:YES];
    [self.statusItem setTitle:@"BufferFast"];
    //[self.statusItem setView:[[StatusBarView alloc] initWithFrame:viewFrame]];

    [self.statusItem setTarget:self];
    [self.statusItem setAction:@selector(statusItemClicked:)];

    [[NSAppleEventManager sharedAppleEventManager] setEventHandler:self andSelector:@selector(handleURLEvent:withReplyEvent:) forEventClass:kInternetEventClass andEventID:kAEGetURL];
    
    //CGRect frame = self.statusItem.view.window.frame;
    //[self.window setFrameOrigin:NSPointFromCGPoint(CGPointMake(frame.origin.x, frame.origin.y - self.window.frame.size.height))];
}

- (void)awakeFromNib {
    
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    
    NSUserDefaults* userDefaults = [NSUserDefaults standardUserDefaults];
    
    if ([userDefaults valueForKey:@"token"]) {
        [self.contentView setHidden:NO];
        [self loadData];
    }
    
    /*[self.window setFrameOrigin:NSPointFromCGPoint(CGPointMake(self.s, 100))];
    
    [self.popover showRelativeToRect:self.statusItem.view.frame ofView:self.statusItem.view preferredEdge:NSMinYEdge];*/
}

#pragma mark --

- (void)handleURLEvent:(NSAppleEventDescriptor*)event withReplyEvent:(NSAppleEventDescriptor*)replyEvent
{
    NSString* url = [[event paramDescriptorForKeyword:keyDirectObject] stringValue];
    
    NSRange codeRange = [url rangeOfString:@"code="];
    
    if (codeRange.location != NSNotFound) {
        
        NSString* code = [url substringFromIndex:codeRange.location+codeRange.length];
        
        code = [code stringByReplacingOccurrencesOfString:@"%2F" withString:@"/"];
        
        NSLog(@"%@", code);
        
        [self requestTokenWithCode:code];
    }
    else {
        
        NSAlert *alert = [[NSAlert alloc] init];
        [alert setMessageText:url];
        [alert setInformativeText:@"Login Failed"];
        [alert addButtonWithTitle:@"Cancel"];
        [alert runModal];
    }
    
    NSLog(@"%@", url);
}

#pragma mark -- 

- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView {
    
    return self.availableServices.count;
}

- (NSView *)tableView:(NSTableView *)tableView
   viewForTableColumn:(NSTableColumn *)tableColumn
                  row:(NSInteger)row {
    
    NSTextField *result = [tableView makeViewWithIdentifier:@"MyView" owner:self];
    
    if (result == nil) {
    
        result = [[NSTextField alloc] initWithFrame:CGRectMake(0, 0, 200, 50)];
        result.identifier = @"MyView";
        [result setEditable:NO];
        [result setBordered:NO];
        [result setBackgroundColor:[NSColor clearColor]];
    }
    
    result.stringValue = [NSString stringWithFormat:@"%@ - %@", self.availableServices[row][@"service"], self.availableServices[row][@"formatted_username"]];
    // return the result.
    return result;
    
}


#pragma mark --

- (void)requestTokenWithCode:(NSString*)code {
    
    NSDictionary* params = @{@"client_id" : @"50b7d4a11b81f68546000038", @"client_secret" : @"e93dab9498c80630452a2554a17c12da", @"redirect_uri" : @"bufferfast://auth", @"code" : code, @"grant_type" : @"authorization_code"};
    
    [[AFBufferHTTPClient sharedClient] postPath:@"oauth2/token.json" parameters:params success:^(AFHTTPRequestOperation *operation, id responseObject) {
        
        [self.contentView setHidden:NO];
        
        NSUserDefaults* userDefaults = [NSUserDefaults standardUserDefaults];
        [userDefaults setValue:[responseObject valueForKey:@"access_token"] forKey:@"token"];
        [userDefaults synchronize];
        
        [self loadData];
        
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        
        NSAlert *alert = [[NSAlert alloc] init];
        [alert setMessageText:@"Login Failed"];
        [alert setInformativeText:error.localizedRecoverySuggestion];
        [alert addButtonWithTitle:@"Cancel"];
        [alert runModal];
    }];
}

#pragma mark --

- (IBAction)connectButtonClicked:(id)sender {
    
    [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:@"https://bufferapp.com/oauth2/authorize?client_id=50b7d4a11b81f68546000038&redirect_uri=bufferfast://auth&response_type=code"]];
}

- (IBAction)refreshButtonClicked:(id)sender {
    [self loadData];
}

- (IBAction)publishButtonClicked:(id)sender {
    
    if (self.availableServices.count==0) {
        return;
    }
    
    NSUserDefaults* userDefaults = [NSUserDefaults standardUserDefaults];
    
    NSIndexSet* selectedIndexes = [self.tableView selectedRowIndexes];
    
    if (selectedIndexes.count==0) {

        NSAlert *alert = [[NSAlert alloc] init];
        [alert setMessageText:@"Posting Failed"];
        [alert setInformativeText:@"Please select one or more services you want to share to"];
        [alert addButtonWithTitle:@"Cancel"];
        [alert runModal];
        return;
    }
    
    NSMutableDictionary* requestParams = [[NSMutableDictionary alloc] init];
    
    [requestParams setValue:self.postTextView.string forKey:@"text"];
    [requestParams setValue:[userDefaults valueForKey:@"token"] forKey:@"access_token"];
    [requestParams setValue:@"1" forKey:@"now"];
    
    __block NSInteger index = 0;
    
    [selectedIndexes enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL *stop) {
        
        [requestParams setValue:self.availableServices[idx][@"id"] forKey:[NSString stringWithFormat:@"profile_ids[%ld]", index]];
        
        index++;
    }];
    
    [[AFBufferHTTPClient sharedClient] postPath:@"updates/create.json" parameters:requestParams success:^(AFHTTPRequestOperation *operation, id responseObject) {
        
        NSLog(@"%@", responseObject);
        self.postTextView.string = @"";
        
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        
        NSAlert *alert = [[NSAlert alloc] init];
        [alert setMessageText:@"Posting Failed"];
        [alert setInformativeText:error.localizedRecoverySuggestion];
        [alert addButtonWithTitle:@"Cancel"];
        [alert runModal];
    }];

}

- (void)statusItemClicked:(id)sender {
    NSLog(@"status item clicked");
    
    CGRect frame = [[[NSApp currentEvent] window] frame];
    
    [self.window setFrameOrigin:NSPointFromCGPoint(CGPointMake(frame.origin.x, frame.origin.y - self.window.frame.size.height))];
    
    [NSApp arrangeInFront:sender];
    [self.window makeKeyAndOrderFront:sender];
    [NSApp activateIgnoringOtherApps:YES];
}

- (IBAction)quitClicked:(id)sender {
    [NSApp terminate: nil];
}

#pragma mark --

- (void)loadData {
    
    NSUserDefaults* userDefaults = [NSUserDefaults standardUserDefaults];
    
    [[AFBufferHTTPClient sharedClient] getPath:@"profiles.json" parameters:@{@"access_token" : [userDefaults valueForKey:@"token"]} success:^(AFHTTPRequestOperation *operation, id responseObject) {
        
        NSLog(@"%@", responseObject);
        self.availableServices = responseObject;
        [self.tableView reloadData];
        
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        
        NSAlert *alert = [[NSAlert alloc] init];
        [alert setMessageText:@"Posting Failed"];
        [alert setInformativeText:error.localizedRecoverySuggestion];
        [alert addButtonWithTitle:@"Cancel"];
        [alert runModal];
        
    }];
}



@end