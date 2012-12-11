//
//  AppDelegate.h
//  BufferFast
//
//  Created by Petr Pavlik on 12/7/12.
//  Copyright (c) 2012 Petr Pavlik. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface AppDelegate : NSObject <NSApplicationDelegate, NSTableViewDelegate, NSTableViewDataSource>

@property (assign) IBOutlet NSWindow *window;


@property (unsafe_unretained) IBOutlet NSTextView *postTextView;

@property (weak) IBOutlet NSView *contentView;

@property (weak) IBOutlet NSTableView *tableView;



@end
