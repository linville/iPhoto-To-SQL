//
//  iPhotoToSQLController.h
//  iPhoto To SQL
//
//  Created by Aaron Linville on 4/19/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "ExportPluginProtocol.h"

@interface iPhotoToSQLController : NSObject <ExportPluginProtocol>
{
    // iPhoto Elements
    id <ExportImageProtocol> mExportMgr;
    IBOutlet NSBox <ExportPluginBoxProtocol> *mSettingsBox;
    IBOutlet NSControl *mFirstView;
    
    // Panel Form Elements
    IBOutlet NSFormCell *thumbnailWidthFormCell;
	IBOutlet NSFormCell *thumbnailHeightFormCell;
	IBOutlet NSFormCell *imageWidthFormCell;
	IBOutlet NSFormCell *imageHeightFormCell;
    
    IBOutlet NSButton *createDropTablePopup;
    IBOutlet NSButton *storeInAlbumDirectoryPopup;
    IBOutlet NSButton *titleIsFilenamePopup;

    // Exporting Progress Elements
    ExportPluginProgress mProgress;
    NSLock *mProgressLock;
    BOOL mCancelExport;
}

// Overrides
- (void)dealloc;

@end