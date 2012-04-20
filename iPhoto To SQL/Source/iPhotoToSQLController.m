//
//  iPhotoToSQLController.m
//  iPhoto To SQL
//
//  Created by Aaron Linville on 4/19/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "iPhotoToSQLController.h"
#import <QuickTime/QuickTime.h>

@implementation iPhotoToSQLController

- (id)initWithExportImageObj:(id <ExportImageProtocol>)obj
{
	if(self = [super init])
	{
		mExportMgr = obj;
		mProgress.message = nil;
		mProgressLock = [[NSLock alloc] init];
	}
	return self;
}

- (void)dealloc
{
	[mProgressLock release];
	[mProgress.message release];
	
	[super dealloc];
}


// protocol implementation
- (NSView <ExportPluginBoxProtocol> *)settingsView
{
	return mSettingsBox;
}

- (NSView *)firstView
{
	return mFirstView;
}

- (void)viewWillBeActivated
{
    
}

- (void)viewWillBeDeactivated
{
    
}

- (NSString *)requiredFileType
{
	if([mExportMgr imageCount] > 1)
		return @"";
	else
		return @"jpg";
}

- (BOOL)wantsDestinationPrompt
{
	return YES;
}

- (NSString*)getDestinationPath
{
	return @"";
}

- (NSString *)defaultFileName
{
	if([mExportMgr imageCount] > 1)
		return @"";
	else
		return @"sfe-0";
}

- (NSString *)defaultDirectory
{
	return @"~/Pictures/";
}

- (BOOL)treatSingleSelectionDifferently
{
	return YES;
}

- (BOOL)handlesMovieFiles
{
	return NO;
}

- (BOOL)validateUserCreatedPath:(NSString*)path
{
	return NO;
}

- (void)clickExport
{
	[mExportMgr clickExport];
}

- (void)startExport:(NSString *)path
{
	NSFileManager *fileMgr = [NSFileManager defaultManager];
	
	
	int count = [mExportMgr imageCount];
	
	// check for conflicting file names
	if(count == 1)
		[mExportMgr startExport];
	else
	{
		int i;
		for(i=0; i<count; i++)
		{
			NSString *fileName = [NSString stringWithFormat:@"sfe-%d.jpg",i];
			if([fileMgr fileExistsAtPath:[path stringByAppendingPathComponent:fileName]])
				break;
		}
		if(i != count)
		{
			if (NSRunCriticalAlertPanel(@"File exists", @"One or more images already exist in directory.", 
										@"Replace", nil, @"Cancel") == NSAlertDefaultReturn)
				[mExportMgr startExport];
			else
				return;
		}
		else
			[mExportMgr startExport];
	}
}

- (void)performExport:(NSString *)path
{
	NSLog(@"performExport path: %@", path);
    //NSLog(@"iPhoto To SQL -- performExport");
    
    [mProgressLock lock];
    mProgress.currentItem = 0;
    mProgress.totalItems = [mExportMgr imageCount];
    mProgress.indeterminateProgress = NO;
    [mProgressLock unlock];
    
    //NSLog([NSString stringWithFormat:@"%@/iPhoto Dump.sql", path]);
    
    //NSLog(@"Albumname: %@", [mExportMgr albumName]);
    //NSLog(@"# of albums: %d", [mExportMgr selectedAlbums] );
    
    // Create album directory if user wants images/thumbnails stored in directory named after album
    if([storeInAlbumDirectoryPopup state] == NSOnState) {
        // Loop through all albums
        int curAlbum;
        for(curAlbum = 0; curAlbum < [mExportMgr albumCount]; curAlbum++) {
            if(![[NSFileManager defaultManager] fileExistsAtPath: [NSString stringWithFormat:@"%@/%@", path, [mExportMgr albumNameAtIndex: curAlbum]]]) {
                [[NSFileManager defaultManager] createDirectoryAtPath: [NSString stringWithFormat:@"%@/%@", path, [mExportMgr albumNameAtIndex: curAlbum]] attributes: nil];
            }
        }
    }
    
    FILE *stream;
    stream = fopen([[NSString stringWithFormat:@"%@/iPhoto Dump.sql", path] UTF8String ], "w");
    
    fprintf(stream, "--\n");
    fprintf(stream, "-- Table structure for table `iphoto`\n");
    fprintf(stream, "--\n");
    if([createDropTablePopup state] == NSOnState) {
        fprintf(stream, "DROP TABLE IF EXISTS `iphoto`;\n");
    }
    fprintf(stream, "CREATE TABLE IF NOT EXISTS `iphoto` (\n");
    fprintf(stream, "  `id` int(11) NOT NULL auto_increment,\n");
    fprintf(stream, "  `title` varchar(255) default NULL,\n");
    fprintf(stream, "  `comment` text default NULL,\n");
    fprintf(stream, "  `keywords` text default NULL,\n");
    fprintf(stream, "  `stars` int(11) default NULL,\n");
    fprintf(stream, "  `date` datetime NOT NULL default '0000-00-00 00:00:00',\n");
    fprintf(stream, "  `album` varchar(255) default NULL,\n");
    fprintf(stream, "  `thumbnail_filename` varchar(255) NOT NULL, \n");
    fprintf(stream, "  `image_filename` varchar(255) NOT NULL, \n");
    //  fprintf(stream, "  `view_count` int(11) default NULL,\n");  
    fprintf(stream, "  PRIMARY KEY (`id`)\n");
    fprintf(stream, ") COMMENT='iPhoto Photos';\n");
    fprintf(stream, "\n\n");
    
    // Output Options
    ImageExportOptions thumbnailOptions;
    thumbnailOptions.format = kUTTypeJPEG; // kQTFileTypeJPEG
    thumbnailOptions.quality = EQualityMax;
    thumbnailOptions.rotation = 0.0;
    thumbnailOptions.width = [thumbnailWidthFormCell intValue];
    thumbnailOptions.height = [thumbnailHeightFormCell intValue];
    
    ImageExportOptions imageOptions;
    imageOptions.format = kUTTypeJPEG; // kQTFileTypeJPEG
    imageOptions.quality = EQualityMed;
    imageOptions.rotation = 0.0;
    imageOptions.width = [imageWidthFormCell intValue];
    imageOptions.height = [imageWidthFormCell intValue];    
        
    // Keep track of filenames of photos (for duplicate name avoidance)
    NSMutableArray *filenameArray = [NSMutableArray new];
    
    int curImage;
    for(curImage = 0; curImage < [mExportMgr imageCount]; ++curImage) {
        [mProgressLock lock];
        if(mProgress.shouldCancel == YES) {
            [mProgressLock unlock];
            break;
        }
        
        mProgress.currentItem = curImage + 1; // Progress bar is 1 index-ed so we compensate.
        [mProgressLock unlock];
        
        NSArray *pathComponents = [[mExportMgr imagePathAtIndex: curImage] pathComponents];
        
        // XXX - Ensure name is valid. This is not very robust at the moment.
        NSString *basename;
        if([titleIsFilenamePopup state] == NSOnState) {      
            // Replace spaces with underscores
            NSMutableString *despacedString = [[mExportMgr imageTitleAtIndex: curImage] mutableCopy];
            [despacedString replaceOccurrencesOfString:@" " withString:@"_" options: 0 range:NSMakeRange(0, [despacedString length])];
            
            // Scan through the title and make it websafe (remove non-alphanumeric and other allowed)
            NSScanner *scanner = [NSScanner scannerWithString:despacedString];
            NSMutableCharacterSet *allowedCharacters = [[NSCharacterSet alphanumericCharacterSet] mutableCopy];      
            [allowedCharacters addCharactersInString:@"_-"];
            
            NSMutableString *safeString = [NSMutableString stringWithString:@""];
            
            while(NO == [scanner isAtEnd]) {
                NSString *goodString;
                [scanner scanCharactersFromSet:allowedCharacters intoString:&goodString];
                
                [safeString appendString:goodString];
                
                if([scanner scanLocation] < [despacedString length]) {
                    [scanner setScanLocation:[scanner scanLocation] + 1];
                }
            }
            
            [allowedCharacters release];
            [despacedString release];
            
            basename = (NSString *) safeString;
        } else {
            basename = [[pathComponents lastObject] lowercaseString];
        }
        
        // Ensure there is no suffix.
        if([basename hasSuffix:@".jpg"]) {
            basename = [basename substringToIndex:[basename length] - 4];
        }
        
        //NSLog(@"Picture - %@", basename);
        
        // Ensure name is unique. If it isn't. Add _N suffix to it.
        if([filenameArray containsObject: basename]) {
            int suffix = 1;
            NSNumber *myInt;
            do {
                ++suffix;
                myInt = [NSNumber numberWithInt: suffix];
            } while([filenameArray containsObject: [NSString stringWithFormat:@"%@_%@", basename, [myInt stringValue]]]);
            
            basename = [NSString stringWithFormat:@"%@_%@", basename, [myInt stringValue]];
        }
        
        // Remember unique name.
        [filenameArray addObject: basename];
        
        basename = [basename stringByAppendingString:@".jpg"];
        
        //NSLog(@"Unique - %@", [mExportMgr makeUniqueFileNameWithTime:basename]);
        
        NSString *thumbnailFilename = [NSString stringWithFormat:@"thumbnail-%@", basename];
        NSString *imageFilename = basename;
        
        // NULL is for the id which is autoincrementing
        fprintf(stream, "INSERT INTO iphoto VALUES (NULL");
        
        // Title
        NSMutableString *escapedString = [[mExportMgr imageTitleAtIndex: curImage] mutableCopy];
        [escapedString replaceOccurrencesOfString:@"\n" withString:@"<br>" options: 0 range:NSMakeRange(0, [escapedString length])];
        [escapedString replaceOccurrencesOfString:@"\"" withString:@"\\\"" options: 0 range:NSMakeRange(0, [escapedString length])];    
        fprintf(stream, ", \"%s\"", [escapedString UTF8String]);
        [escapedString release];
        
        // Comment
        escapedString = [[mExportMgr imageCommentsAtIndex: curImage] mutableCopy];
        [escapedString replaceOccurrencesOfString:@"\n" withString:@"<br>" options: 0 range:NSMakeRange(0, [escapedString length])];
        [escapedString replaceOccurrencesOfString:@"\"" withString:@"\\\"" options: 0 range:NSMakeRange(0, [escapedString length])];    
        fprintf(stream, ", \"%s\"", [escapedString UTF8String]);
        [escapedString release];
        
        // Keywords
        fprintf(stream, ", ");
        if([[mExportMgr imageKeywordsAtIndex: curImage] count] == 0) {
            fprintf(stream, "NULL");
        } else {
            fprintf(stream, " \"%s\"", [[[mExportMgr imageKeywordsAtIndex: curImage] componentsJoinedByString:@" "] UTF8String]);
        }
        
        // Ranking
        fprintf(stream, ", %d", [mExportMgr imageRatingAtIndex: curImage]);
        
        // Date/Time
        fprintf(stream, ", \"%s\"", [[[[mExportMgr imageDateAtIndex: curImage] description] substringToIndex: [[[mExportMgr imageDateAtIndex: curImage] description] length] - 5] UTF8String]);
        
        // Album
        //NSLog(@"Albums: %@", [mExportMgr albumNameAtIndex: [[[mExportMgr albumsOfImageAtIndex: curImage] objectAtIndex: 0] intValue]]);
        fprintf(stream, ", \"%s\"", [[mExportMgr albumNameAtIndex: [[[mExportMgr albumsOfImageAtIndex: curImage] objectAtIndex: 0] intValue]] UTF8String]);
        
        // Paths
        fprintf(stream, ", \"%s\"", [thumbnailFilename UTF8String]);
        fprintf(stream, ", \"%s\"", [imageFilename UTF8String]);
        fprintf(stream, ");\n");
        
        // Done with SQL. Now create corresponding image/thumbnail for entry.
        
        // Create a full path to file the thumbernail will create
        NSString *thumbnailPath;
        NSString *imagePath;
        
        if([storeInAlbumDirectoryPopup state] == NSOnState) {
            thumbnailPath = [NSString stringWithFormat:@"%@/%@/%@", path, [mExportMgr albumNameAtIndex: [[[mExportMgr albumsOfImageAtIndex: curImage] objectAtIndex: 0] intValue]], thumbnailFilename];
            imagePath = [NSString stringWithFormat:@"%@/%@/%@", path, [mExportMgr albumNameAtIndex: [[[mExportMgr albumsOfImageAtIndex: curImage] objectAtIndex: 0] intValue]], imageFilename];    
        } else {
            thumbnailPath = [NSString stringWithFormat:@"%@/%@", path, thumbnailFilename];
            imagePath = [NSString stringWithFormat:@"%@/%@", path, imageFilename];
        }
        
        // Create the images
        [mExportMgr exportImageAtIndex:curImage dest:thumbnailPath options:&thumbnailOptions];
        [mExportMgr exportImageAtIndex:curImage dest:imagePath options:&imageOptions];
        
    } // for(curImage = 0; curImage < [mExportMgr imageCount]; ++curImage)
    
    fclose(stream);
    
	// Close the progress panel when done
	[self lockProgress];
	[mProgress.message autorelease];
	mProgress.message = nil;
	mProgress.shouldStop = YES;
	[self unlockProgress];
}

- (ExportPluginProgress *)progress
{
	return &mProgress;
}

- (void)lockProgress
{
	[mProgressLock lock];
}

- (void)unlockProgress
{
	[mProgressLock unlock];
}

- (void)cancelExport
{
	mCancelExport = YES;
}

- (NSString *)name
{
	return @"iPhoto To SQL";
}

@end
