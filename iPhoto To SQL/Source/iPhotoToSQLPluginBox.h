//
//  iPhotoToSQLPluginBox.h
//  iPhoto To SQL
//
//  Copyright (c) 2012 Aaron Linville.
//

#import <Cocoa/Cocoa.h>
#import "ExportPluginProtocol.h"
#import "ExportPluginBoxProtocol.h"

@interface iPhotoToSQLPluginBox : NSBox <ExportPluginBoxProtocol> {
    IBOutlet id <ExportPluginProtocol> mPlugin;
}

- (BOOL)performKeyEquivalent:(NSEvent *)anEvent;

@end
