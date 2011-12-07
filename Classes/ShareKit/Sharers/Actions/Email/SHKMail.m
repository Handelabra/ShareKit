//
//  SHKMail.m
//  ShareKit
//
//  Created by Nathan Weiner on 6/17/10.

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

#import "SHKMail.h"

NSString *const SHKMailRecipientsKey = @"SHKMailRecipientsKey";

@implementation MFMailComposeViewController (SHK)

- (void)SHKviewDidDisappear:(BOOL)animated
{	
	[super viewDidDisappear:animated];
	
	// Remove the SHK view wrapper from the window (but only if the view doesn't have another modal over it)
	if (self.modalViewController == nil)
		[[SHK currentHelper] viewWasDismissed];
}

@end



@implementation SHKMail

#pragma mark -
#pragma mark Configuration : Service Defination

+ (NSString *)sharerTitle
{
	return SHKLocalizedString(@"Email");
}

+ (BOOL)canShareText
{
	return YES;
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

+ (BOOL)canShare
{
	return [MFMailComposeViewController canSendMail];
}

- (BOOL)shouldAutoShare
{
	return YES;
}



#pragma mark -
#pragma mark Share API Methods

- (BOOL)send
{
	self.quiet = YES;
	
	if (![self validateItem])
		return NO;
	
	return [self sendMail]; // Put the actual sending action in another method to make subclassing SHKMail easier
}

- (BOOL)sendMail
{	
	MFMailComposeViewController *mailController = [[MFMailComposeViewController alloc] init];
	if (!mailController) {
		// e.g. no mail account registered (will show alert)
		[[SHK currentHelper] hideCurrentViewControllerAnimated:YES];
		return YES;
	}
	
	mailController.mailComposeDelegate = self;
	
	NSString *body = [self.item customValueForKey:@"body"];
	
	if (body == nil)
	{
		if (self.item.text != nil)
        {
			body = self.item.text;
        }
		
		if (self.item.URL != nil)
		{	
			NSString *urlStr = [self.item.URL.absoluteString stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
			
			if (body != nil)
            {
				body = [body stringByAppendingFormat:@"<br/><br/>%@", urlStr];
			}
			else
            {
				body = urlStr;
            }
		}
		
		if (self.item.data)
		{
			NSString *attachedStr = SHKLocalizedString(@"Attached: %@", self.item.title ? self.item.title : self.item.filename);
			
			if (body != nil)
            {
				body = [body stringByAppendingFormat:@"<br/><br/>%@", attachedStr];
            }
			else
            {
				body = attachedStr;
            }
		}
        
        if (self.item.dataItems)
        {
			NSString *attachedStr = SHKLocalizedString(@"Attached: %@ (%i)", self.item.title ? self.item.title : self.item.filename, self.item.dataItems.count);
			
			if (body != nil)
            {
				body = [body stringByAppendingFormat:@"<br/><br/>%@", attachedStr];
            }
			else
            {
				body = attachedStr;
            }
        }
		
		// fallback
		if (body == nil)
        {
			body = @"";
        }
		
		// sig
		if (SHKSharedWithSignature)
		{
			body = [body stringByAppendingString:@"<br/><br/>"];
			body = [body stringByAppendingString:SHKLocalizedString(@"Sent from %@", SHKMyAppName)];
		}
		
		// save changes to body
		[self.item setCustomValue:body forKey:@"body"];
	}
	
	if (self.item.data)
    {
		[mailController addAttachmentData:self.item.data mimeType:self.item.mimeType fileName:self.item.filename];
    }
    
    if (self.item.dataItems != nil)
    {
        NSUInteger i = 1;
        NSArray *filenameComps = [self.item.filename componentsSeparatedByString:@"."];
        for (NSData *data in self.item.dataItems)
        {
            [mailController addAttachmentData:data
                                     mimeType:self.item.mimeType
                                     fileName:[NSString stringWithFormat:@"%@-%i.%@",
                                               [filenameComps objectAtIndex:0], i, [filenameComps objectAtIndex:1]]];
        }
    }
	
    NSString *imageMimeType = @"image/jpeg";
    NSString *imageName = @"Image";
    NSString *imageExt = @"jpg";
	if (self.item.image)
    {
		[mailController addAttachmentData:UIImageJPEGRepresentation(self.item.image, 1.0)
                                 mimeType:imageMimeType
                                 fileName:[imageName stringByAppendingPathExtension:imageExt]];
    }
    if (self.item.images)
    {
        NSUInteger count = 1;
        for (UIImage *image in self.item.images)
        {
            [mailController addAttachmentData:UIImageJPEGRepresentation(image, 1.0)
                                     mimeType:imageMimeType
                                     fileName:[[NSString stringWithFormat:@"%@-%d", imageName, count] stringByAppendingPathExtension:imageExt]];
            count++;
        }
    }
	
	[mailController setSubject:self.item.title];
	[mailController setMessageBody:body isHTML:YES];
    
    NSArray *toRecipients = [self.item customValueForKey:SHKMailRecipientsKey];
    if (toRecipients != nil && toRecipients.count > 0)
    {
        [mailController setToRecipients:toRecipients];
    }
    
    self.item = nil;
			
	[[SHK currentHelper] showViewController:mailController];
    [mailController release];
	
	return YES;
}

- (void)mailComposeController:(MFMailComposeViewController*)controller didFinishWithResult:(MFMailComposeResult)result error:(NSError*)error
{
	[[SHK currentHelper] hideCurrentViewControllerAnimated:YES];
	
	switch (result) 
	{
		case MFMailComposeResultSent:
			[self sendDidFinish];
			break;
		case MFMailComposeResultSaved:
			[self sendDidFinish];
			break;
		case MFMailComposeResultCancelled:
			[self sendDidCancel];
			break;
		case MFMailComposeResultFailed:
			[self sendDidFailWithError:nil];
			break;
	}
}


@end
