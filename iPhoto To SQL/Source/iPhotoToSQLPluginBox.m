//
//  iPhotoToSQLPluginBox.m
//  iPhoto To SQL
//
//  Created by Aaron Linville on 4/19/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "iPhotoToSQLPluginBox.h"

@implementation iPhotoToSQLPluginBox

- (BOOL)performKeyEquivalent:(NSEvent *)anEvent
{
    NSString *keyString = [anEvent charactersIgnoringModifiers];
    unichar keyChar = [keyString characterAtIndex:0];
    
    switch (keyChar)
    {
        case NSFormFeedCharacter:
        case NSNewlineCharacter:
        case NSCarriageReturnCharacter: case NSEnterCharacter:
        {
            [mPlugin clickExport];
            return(YES);
        }
        default:
            break;
    }
    return([super performKeyEquivalent:anEvent]);
}

@end
