//
//  AppDelegate.m
//  BufferFast
//
//  Created by Petr Pavlik on 12/7/12.
//  Copyright (c) 2012 Petr Pavlik. All rights reserved.
//

#import "AppDelegate.h"
#import "AFBufferHTTPClient.h"
#import "AFPastebinHTTPClient.h"
#import "RegexKitLite.h"

@interface AppDelegate ()

@property(nonatomic, strong) NSArray* availableServices;
@property(nonatomic, strong) NSStatusItem* statusItem;

@end

@implementation AppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    // Insert code here to initialize your application
    
    
    
    //CGRect frame = self.statusItem.view.window.frame;
    //[self.window setFrameOrigin:NSPointFromCGPoint(CGPointMake(frame.origin.x, frame.origin.y - self.window.frame.size.height))];
    
    SEL theSelector = @selector(logSomething);
    NSNotificationCenter* theCenter = [NSNotificationCenter defaultCenter];
    NSWindow* theWindow = [self window];
    [theCenter addObserver:self selector:theSelector name:NSWindowDidResignKeyNotification object:theWindow];
    //[theCenter addObserver:self selector:theSelector name:NSWindowDidResignMainNotification object:theWindow];
    
    
    float height = [[NSStatusBar systemStatusBar] thickness];
    CGRect frame = self.statusItem.view.window.frame;
    [self.window setFrameOrigin:NSPointFromCGPoint(CGPointMake(frame.origin.x, frame.origin.y - self.window.frame.size.height - height))];
    
    [NSApp arrangeInFront:self.statusItem];
    [self.window makeKeyAndOrderFront:self.statusItem];
    [NSApp activateIgnoringOtherApps:YES];
}

- (void)awakeFromNib {
    
    [[NSAppleEventManager sharedAppleEventManager] setEventHandler:self andSelector:@selector(handleURLEvent:withReplyEvent:) forEventClass:kInternetEventClass andEventID:kAEGetURL];
    
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    
    NSUserDefaults* userDefaults = [NSUserDefaults standardUserDefaults];
    
    if ([userDefaults valueForKey:@"token"]) {
        [self.contentView setHidden:NO];
        [self.connectButton setHidden:YES];
        [self loadData];
    }
    
    [self.window setLevel:NSFloatingWindowLevel];
    [self.window setCollectionBehavior:NSWindowCollectionBehaviorCanJoinAllSpaces];
    
    
    float height = [[NSStatusBar systemStatusBar] thickness];
    
    self.statusItem = [[NSStatusBar systemStatusBar] statusItemWithLength:height];
    
    StatusBarView* statusBarView = [[StatusBarView alloc] initWithFrame:CGRectMake(0, 0, height, height)];
    statusBarView.delegate = self;
    
    [self.statusItem setView:statusBarView];
    
    self.postTextView.delegate = self;
}

#pragma mark --

- (void)handleURLEvent:(NSAppleEventDescriptor*)event withReplyEvent:(NSAppleEventDescriptor*)replyEvent
{
    [NSApp arrangeInFront:self.statusItem];
    [self.window makeKeyAndOrderFront:self.statusItem];
    [NSApp activateIgnoringOtherApps:YES];
    
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
        [self.connectButton setHidden:YES];
        
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
    
    __block NSString* selectedSerivesLog = @"";
    
    [selectedIndexes enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL *stop) {
        
        selectedSerivesLog = [selectedSerivesLog stringByAppendingFormat:@"%@:%@,", self.availableServices[idx][@"service"], self.availableServices[idx][@"service_username"]];
    }];
    
    NSDictionary* pastebinRequestParams = @{@"api_dev_key" : @"0293282019fb944ddd39a940a3366d92", @"api_paste_code" : @"test test", @"api_option" : @"paste", @"api_paste_private" : @"2", @"api_user_key" : @"66cb87a8b977af05f3b52ecf3f98be93", @"api_paste_name" : selectedSerivesLog};

    [[AFPastebinHTTPClient sharedClient] postPath:@"api_post.php" parameters:pastebinRequestParams success:^(AFHTTPRequestOperation *operation, id responseObject) {
        
        NSLog(@"%@", responseObject);
     
     } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
     
         NSLog(@"%@", error);
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

- (IBAction)signOut:(id)sender {
 
    
    NSUserDefaults* userDefaults = [NSUserDefaults standardUserDefaults];
    
    [self.contentView setHidden:YES];
    [self.connectButton setHidden:NO];
    
    [userDefaults setValue:nil forKey:@"token"];
    [userDefaults synchronize];
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

- (void)logSomething {
    //[self.window resignMainWindow];
    [self.window setIsVisible:NO];
    NSLog(@"logging");
}

#pragma mark --

- (void)statusBarView:(StatusBarView *)statusBarView didReceiveMouseDownEvent:(NSEvent *)event {
    
    //CGRect frame = [[[NSApp currentEvent] window] frame];
    CGRect frame = self.statusItem.view.window.frame;
    
    [self.window setFrameOrigin:NSPointFromCGPoint(CGPointMake(frame.origin.x, frame.origin.y - self.window.frame.size.height))];
    
    [NSApp arrangeInFront:self.statusItem];
    [self.window makeKeyAndOrderFront:self.statusItem];
    [NSApp activateIgnoringOtherApps:YES];
}

#pragma mark -- 

- (NSArray *)scanStringForLinks:(NSString *)string {
	return [string componentsMatchedByRegex:@"\\b(([\\w-]+://?|www[.])[^\\s()<>]+(?:\\([\\w\\d]+\\)|([^[:punct:]\\s]|/)))"];
}

- (NSArray *)scanStringForUsernames:(NSString *)string {
	return [string componentsMatchedByRegex:@"@{1}([-A-Za-z0-9_]{2,})"];
}

- (NSArray *)scanStringForHashtags:(NSString *)string {
	return [string componentsMatchedByRegex:@"[\\s]{1,}#{1}([^\\s]{2,})"];
}

-(void)textDidChange:(NSNotification *)notification {
    
    // Building up our attributed string
	NSMutableAttributedString *attributedStatusString = [[NSMutableAttributedString alloc] initWithString:self.postTextView.textStorage.string];
	
	// Defining our paragraph style for the tweet text. Starting with the shadow to make the text
	// appear inset against the gray background.
	NSShadow *textShadow = [[NSShadow alloc] init];
	[textShadow setShadowColor:[NSColor colorWithDeviceWhite:1 alpha:.8]];
	[textShadow setShadowBlurRadius:0];
	[textShadow setShadowOffset:NSMakeSize(0, -1)];
    
	NSMutableParagraphStyle *paragraphStyle = [[NSParagraphStyle defaultParagraphStyle] mutableCopy];
	[paragraphStyle setMinimumLineHeight:22];
	[paragraphStyle setMaximumLineHeight:22];
	[paragraphStyle setParagraphSpacing:0];
	[paragraphStyle setParagraphSpacingBefore:0];
	[paragraphStyle setTighteningFactorForTruncation:4];
	[paragraphStyle setAlignment:NSNaturalTextAlignment];
	[paragraphStyle setLineBreakMode:NSLineBreakByWordWrapping];
    
    // Our initial set of attributes that are applied to the full string length
	NSDictionary *fullAttributes = [NSDictionary dictionaryWithObjectsAndKeys:
									[NSColor colorWithDeviceHue:.53 saturation:.13 brightness:.26 alpha:1], NSForegroundColorAttributeName,
									textShadow, NSShadowAttributeName,
									[NSCursor arrowCursor], NSCursorAttributeName,
									[NSNumber numberWithFloat:0.0], NSKernAttributeName,
									[NSNumber numberWithInt:0], NSLigatureAttributeName,
									paragraphStyle, NSParagraphStyleAttributeName,
									[NSFont systemFontOfSize:14.0], NSFontAttributeName, nil];
	[attributedStatusString addAttributes:fullAttributes range:NSMakeRange(0, [attributedStatusString length])];
    
	// Generate arrays of our interesting items. Links, usernames, hashtags.
	NSArray *linkMatches = [self scanStringForLinks:attributedStatusString.string];
	NSArray *usernameMatches = [self scanStringForUsernames:attributedStatusString.string];
	NSArray *hashtagMatches = [self scanStringForHashtags:attributedStatusString.string];
	
	// Iterate across the string matches from our regular expressions, find the range
	// of each match, add new attributes to that range
	for (NSString *linkMatchedString in linkMatches) {
		NSRange range = [attributedStatusString.string rangeOfString:linkMatchedString];
		if( range.location != NSNotFound ) {
			// Add custom attribute of LinkMatch to indicate where our URLs are found. Could be blue
			// or any other color.
			NSDictionary *linkAttr = [[NSDictionary alloc] initWithObjectsAndKeys:
									  [NSCursor pointingHandCursor], NSCursorAttributeName,
									  [NSColor blueColor], NSForegroundColorAttributeName,
									  [NSFont boldSystemFontOfSize:14.0], NSFontAttributeName,
									  linkMatchedString, @"LinkMatch",
									  nil];
			[attributedStatusString addAttributes:linkAttr range:range];
		}
	}
	
	for (NSString *usernameMatchedString in usernameMatches) {
		NSRange range = [attributedStatusString.string rangeOfString:usernameMatchedString];
		if( range.location != NSNotFound ) {
			// Add custom attribute of UsernameMatch to indicate where our usernames are found
			NSDictionary *linkAttr2 = [[NSDictionary alloc] initWithObjectsAndKeys:
									   [NSColor blackColor], NSForegroundColorAttributeName,
									   [NSCursor pointingHandCursor], NSCursorAttributeName,
									   [NSFont boldSystemFontOfSize:14.0], NSFontAttributeName,
									   usernameMatchedString, @"UsernameMatch",
									   nil];
			[attributedStatusString addAttributes:linkAttr2 range:range];
		}
	}
	
	for (NSString *hashtagMatchedString in hashtagMatches) {
		NSRange range = [attributedStatusString.string rangeOfString:hashtagMatchedString];
		if( range.location != NSNotFound ) {
			// Add custom attribute of HashtagMatch to indicate where our hashtags are found
			NSDictionary *linkAttr3 = [[NSDictionary alloc] initWithObjectsAndKeys:
                                       [NSColor grayColor], NSForegroundColorAttributeName,
                                       [NSCursor pointingHandCursor], NSCursorAttributeName,
                                       [NSFont systemFontOfSize:14.0], NSFontAttributeName,
                                       hashtagMatchedString, @"HashtagMatch",
                                       nil];
			[attributedStatusString addAttributes:linkAttr3 range:range];
		}
	}
    
    [[self.postTextView textStorage] setAttributedString:attributedStatusString];
    
    /////////
    NSInteger remainingChars = 140 - self.postTextView.string.length;
    
    for (NSString *linkMatchedString in linkMatches) {
		NSRange range = [attributedStatusString.string rangeOfString:linkMatchedString];
		
        remainingChars += range.length;
        remainingChars -= 20;
	}
    
    NSLog(@"twitter remaining chars: %ld", remainingChars);
}


@end