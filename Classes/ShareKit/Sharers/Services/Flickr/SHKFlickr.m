//
//  SHKFlickr
//  Flickr
//
//  Created by Neil Bostrom on 23/02/2011.
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
//  Flickr Library: ObjectiveFlickr - https://github.com/lukhnos/objectiveflickr


#import "SHKFlickr.h"

NSString *kStoredAuthTokenKeyName = @"FlickrAuthToken";

NSString *kGetAuthTokenStep = @"kGetAuthTokenStep";
NSString *kCheckTokenStep = @"kCheckTokenStep";
NSString *kUploadImageStep = @"kUploadImageStep";
NSString *kSetImagePropertiesStep = @"kSetImagePropertiesStep";
NSString *kGetPrivacy = @"kGetPrivacy";

@interface SHKFlickr ()

- (NSDictionary*) privacySettingsDictionary;

@end

@implementation SHKFlickr

@synthesize flickrContext, flickrUserName;
@synthesize sendImageCount;

+ (NSString *)sharerTitle
{
	return @"Flickr";
}

+ (BOOL)canShareImage
{
	return YES;
}

+ (BOOL)canShareImages
{
    return YES;
}

+ (BOOL)canShare
{
	return YES;
}

- (BOOL)isAuthorized 
{
	return ([self.flickrContext.authToken length] > 0);
}

- (OFFlickrAPIContext *)flickrContext
{
    if (!flickrContext) {
        flickrContext = [[OFFlickrAPIContext alloc] initWithAPIKey: SHKFlickrConsumerKey sharedSecret: SHKFlickrSecretKey];
		
        NSString *authToken = [SHK getAuthValueForKey: kStoredAuthTokenKeyName forSharer:[self sharerId]];
        if (authToken != nil) {
            flickrContext.authToken = authToken;
        }
    }
    
    return flickrContext;
}

- (OFFlickrAPIRequest *)flickrRequest
{
	if (!flickrRequest) {
		flickrRequest = [[OFFlickrAPIRequest alloc] initWithAPIContext:self.flickrContext];
		flickrRequest.delegate = self;	
		flickrRequest.requestTimeoutInterval = 60.0;	
	}
	
	return flickrRequest;
}

+ (void)logout
{
	[SHK removeAuthValueForKey:kStoredAuthTokenKeyName forSharer:[self sharerId]];
}

- (void)authorizationFormShow 
{	
	NSURL *loginURL = [self.flickrContext loginURLFromFrobDictionary:nil requestedPermission:OFFlickrWritePermission];
	SHKOAuthView *auth = [[SHKOAuthView alloc] initWithURL:loginURL delegate:self];
	[[SHK currentHelper] showViewController:auth];	
	[auth release];
}

- (BOOL)send
{	
	if (self.flickrUserName != nil) {
		[self sendPhoto];
	}
	else {
		
		[[SHKActivityIndicator currentIndicator] displayActivity:SHKLocalizedString(@"Logging In...")];
		
		[self flickrRequest].sessionInfo = kCheckTokenStep;
		[flickrRequest callAPIMethodWithGET:@"flickr.auth.checkToken" arguments:nil];
	}
	
	return YES;
}

- (void)sendPhoto {
    
    NSMutableArray *images = [NSMutableArray array];
    if (item.image != nil)
    {
        [images addObject:item.image];
    }
    if (item.images != nil && item.images.count > 0)
    {
        [images addObjectsFromArray:item.images];
    }
    self.sendImageCount = 0;
	
    for (UIImage *image in images)
    {
        if (self.sendImageCount == 0)
        {
            [self sendDidStart];
        }
        
        NSData *JPEGData = UIImageJPEGRepresentation(image, 1.0);
        
        self.flickrRequest.sessionInfo = kUploadImageStep;
        [self.flickrRequest uploadImageStream:[NSInputStream inputStreamWithData:JPEGData] suggestedFilename:item.title MIMEType:@"image/jpeg" arguments:[self privacySettingsDictionary]];
        
        self.sendImageCount++;
    }
}

- (NSURL *)authorizeCallbackURL {
	return [NSURL URLWithString: SHKFlickrCallbackUrl];
}

- (void)tokenAuthorizeView:(SHKOAuthView *)authView didFinishWithSuccess:(BOOL)success queryParams:(NSMutableDictionary *)queryParams error:(NSError *)error {
	
	[[SHK currentHelper] hideCurrentViewControllerAnimated:YES];
	
	if (!success)
	{
		[[[[UIAlertView alloc] initWithTitle:SHKLocalizedString(@"Authorize Error")
									 message:error!=nil?[error localizedDescription]:SHKLocalizedString(@"There was an error while authorizing")
									delegate:nil
						   cancelButtonTitle:SHKLocalizedString(@"Close")
						   otherButtonTitles:nil] autorelease] show];
	}
	else 
	{
		[[SHKActivityIndicator currentIndicator] displayActivity:SHKLocalizedString(@"Logging In...")];
		
		// query has the form of "&frob=", the rest is the frob
		NSString *frob = [queryParams objectForKey:@"frob"];
		
		[self flickrRequest].sessionInfo = kGetAuthTokenStep;
		[flickrRequest callAPIMethodWithGET:@"flickr.auth.getToken" arguments:[NSDictionary dictionaryWithObjectsAndKeys:frob, @"frob", nil]];
	}
}

- (void)tokenAuthorizeCancelledView:(SHKOAuthView *)authView {
	
	[[SHK currentHelper] hideCurrentViewControllerAnimated:YES];
}

- (void)setAndStoreFlickrAuthToken:(NSString *)inAuthToken
{
	if (![inAuthToken length]) {
		
		[SHKFlickr logout];
	}
	else {
		
		self.flickrContext.authToken = inAuthToken;
		[SHK setAuthValue:inAuthToken forKey:kStoredAuthTokenKeyName forSharer:[self sharerId]];
	}
}

- (void)flickrAPIRequest:(OFFlickrAPIRequest *)inRequest didCompleteWithResponse:(NSDictionary *)inResponseDictionary
{
	if (inRequest.sessionInfo == kUploadImageStep) {
		
        NSString *photoID = [[inResponseDictionary valueForKeyPath:@"photoid"] textContent];
		
        flickrRequest.sessionInfo = kSetImagePropertiesStep;
        [flickrRequest callAPIMethodWithPOST:@"flickr.photos.setMeta" arguments:[NSDictionary dictionaryWithObjectsAndKeys:photoID, @"photo_id", item.title, @"title", nil, @"description", nil]];        		        
	}
    else if (inRequest.sessionInfo == kGetPrivacy)
    {
        if (inResponseDictionary != nil)
        {
            NSDictionary *person = (NSDictionary*)[inResponseDictionary valueForKey:@"person"];
            if (person != nil)
            {
                NSString *privacy = (NSString*)[person valueForKey:@"privacy"];
                if (privacy != nil)
                {
                    privacySetting = (NSUInteger)[privacy intValue];
                }
            }
        }
        [self sendPhoto];
    }
	else if (inRequest.sessionInfo == kSetImagePropertiesStep) {
        self.sendImageCount--;
        if (self.sendImageCount == 0)
        {
            [[SHKActivityIndicator currentIndicator] displayCompleted:SHKLocalizedString(@"Uploaded to %@", self.title)];
            
            [self sendDidFinish];
        }
	}
	else {
		
		if (inRequest.sessionInfo == kGetAuthTokenStep) {
			[self setAndStoreFlickrAuthToken:[[inResponseDictionary valueForKeyPath:@"auth.token"] textContent]];
			self.flickrUserName = [inResponseDictionary valueForKeyPath:@"auth.user.username"];
			
			[self share];
		}
		else if (inRequest.sessionInfo == kCheckTokenStep) {
			self.flickrUserName = [inResponseDictionary valueForKeyPath:@"auth.user.username"];
            
            [[SHKActivityIndicator currentIndicator] displayCompleted:SHKLocalizedString(@"Logged in!")];
			
            flickrRequest.sessionInfo = kGetPrivacy;
            [flickrRequest callAPIMethodWithPOST:@"flickr.prefs.getPrivacy" arguments:nil];
		}
	}
}

- (void)flickrAPIRequest:(OFFlickrAPIRequest *)inRequest didFailWithError:(NSError *)inError
{
	if (inRequest.sessionInfo == kUploadImageStep)
    {
        self.sendImageCount--;
    }
	else if (inRequest.sessionInfo == kGetPrivacy)
    {
        // Ignore error. Just fall back to default non-public privacy setting.
        return;
    }
    else if (inRequest.sessionInfo == kGetAuthTokenStep) {
	}
	else if (inRequest.sessionInfo == kCheckTokenStep) {
		[self setAndStoreFlickrAuthToken:nil];
	}
	
	[self sharer: self failedWithError: inError shouldRelogin: NO];
}

- (void)dealloc
{
    [flickrContext release];
	[flickrRequest release];
	[flickrUserName release];
    [super dealloc];
}

#pragma mark - Privacy methods

// See: http://www.flickr.com/services/api/flickr.prefs.getPrivacy.html
// Set is_public, is_friend, is_family for upload based on privacySetting.
- (NSDictionary*) privacySettingsDictionary
{
    NSMutableDictionary *privacySettingsDictionary = [NSMutableDictionary dictionaryWithCapacity:1];
    
    switch (privacySetting)
    {
        case 1:
            [privacySettingsDictionary setValue:@"1" forKey:@"is_public"];
            [privacySettingsDictionary setValue:@"1" forKey:@"is_friend"];
            [privacySettingsDictionary setValue:@"1" forKey:@"is_family"];
            break;
            
        case 2:
            [privacySettingsDictionary setValue:@"0" forKey:@"is_public"];
            [privacySettingsDictionary setValue:@"1" forKey:@"is_friend"];
            [privacySettingsDictionary setValue:@"0" forKey:@"is_family"];
            break;
            
        case 3:
            [privacySettingsDictionary setValue:@"0" forKey:@"is_public"];
            [privacySettingsDictionary setValue:@"0" forKey:@"is_friend"];
            [privacySettingsDictionary setValue:@"1" forKey:@"is_family"];
            break;
            
        case 4:
            [privacySettingsDictionary setValue:@"0" forKey:@"is_public"];
            [privacySettingsDictionary setValue:@"1" forKey:@"is_friend"];
            [privacySettingsDictionary setValue:@"1" forKey:@"is_family"];
            break;
            
        default:
            [privacySettingsDictionary setValue:@"0" forKey:@"is_public"];
            [privacySettingsDictionary setValue:@"0" forKey:@"is_friend"];
            [privacySettingsDictionary setValue:@"0" forKey:@"is_family"];
            break;
    }
    
    return privacySettingsDictionary;
}

@end
