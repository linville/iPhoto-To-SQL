//
//  iPhotoToSQLPluginBox.h
//  iPhoto To SQL
//
//  Created by Aaron Linville on 4/19/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "ExportPluginProtocol.h"
#import "ExportPluginBoxProtocol.h"

@interface iPhotoToSQLPluginBox : NSBox <ExportPluginBoxProtocol> {
    IBOutlet id <ExportPluginProtocol> mPlugin;
}

- (BOOL)performKeyEquivalent:(NSEvent *)anEvent;

@end
