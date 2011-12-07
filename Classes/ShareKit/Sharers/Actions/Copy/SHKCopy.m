//
//  SHKCopy.m
//  ShareKit
//
//  Created by Nathan Weiner on 6/20/10.

//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.
//
//

#import "SHKCopy.h"
#import <MobileCoreServices/MobileCoreServices.h>

@implementation SHKCopy

#pragma mark -
#pragma mark Configuration : Service Defination

+ (NSString *)sharerTitle
{
	return SHKLocalizedString(@"Copy");
}

+ (BOOL)canShareURL
{
	return YES;
}

+ (BOOL)canShareImage
{
	return YES;
}

+ (BOOL)canShareImages
{
	return YES;
}

+ (BOOL)canShareFile
{
    return YES;
}

+ (BOOL)canShareFiles
{
    return YES;
}

+ (BOOL)shareRequiresInternetConnection
{
	return NO;
}

+ (BOOL)requiresAuthentication
{
	return NO;
}


#pragma mark -
#pragma mark Configuration : Dynamic Enable

- (BOOL)shouldAutoShare
{
	return YES;
}


#pragma mark -
#pragma mark Share API Methods

- (BOOL)send
{	
	UIPasteboard *generalPasteboard = [UIPasteboard generalPasteboard];
    switch (item.shareType)
    {
        case SHKShareTypeURL:
            [generalPasteboard setString:item.URL.absoluteString];
            break;
        
        case SHKShareTypeImage:
            [generalPasteboard setImage:item.image];
            break;
        
        case SHKShareTypeImages:
            [generalPasteboard setImages:item.images];
            break;
        
        case SHKShareTypeFile:
            // TODO: map item mimeType to UTI.
            [generalPasteboard setData:self.item.data forPasteboardType:(NSString*)kUTTypeJPEG];
            break;
            
        case SHKShareTypeFiles:
            {
                // TODO: map item mimeType to UTI.
                NSMutableArray *items = [NSMutableArray arrayWithCapacity:self.item.dataItems.count];
                for (NSData *data in self.item.dataItems)
                {
                    [items addObject:[NSDictionary dictionaryWithObjectsAndKeys:data, (NSString*)kUTTypeJPEG, nil]];
                }
                generalPasteboard.items = items;
            }
            break;
            
        case SHKShareTypeText:
            // TODO: support these types.
            break;
        
        case SHKShareTypeUndefined:
        default:
            break;
    }
	
	// Notify user
	[[SHKActivityIndicator currentIndicator] displayCompleted:SHKLocalizedString(@"Copied!")];
	
	// Notify delegate, but quietly
	self.quiet = YES;
	[self sendDidFinish];
	
	return YES;
}

@end
