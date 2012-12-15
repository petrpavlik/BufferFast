//
//  AppDelegate.h
//  BufferFast
//
//  Created by Petr Pavlik on 12/7/12.
//  Copyright (c) 2012 Petr Pavlik. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "StatusBarView.h"
#import "TVTextView.h"

@interface AppDelegate : NSObject <NSApplicationDelegate, NSTableViewDelegate, NSTableViewDataSource, StatusBarViewDelegate, NSTextViewDelegate>

@property (assign) IBOutlet NSWindow *window;


@property (unsafe_unretained) IBOutlet TVTextView *postTextView;

@property (weak) IBOutlet NSView *contentView;

@property (weak) IBOutlet NSTableView *tableView;
@property (weak) IBOutlet NSTextField *twitterCharLimitInfo;

@property (weak) IBOutlet NSButton *connectButton;


@end
