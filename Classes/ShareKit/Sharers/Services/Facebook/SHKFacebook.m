//
//  SHKFacebook.m
//  ShareKit
//
//  Created by Nathan Weiner on 6/18/10.

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

#import "SHKFacebook.h"

static NSString *const kSHKStoredItemKey = @"kSHKStoredItem";
static NSString *const kSHKFacebookAccessTokenKey = @"kSHKFacebookAccessToken";
static NSString *const kSHKFacebookExpiryDateKey = @"kSHKFacebookExpiryDate";

static NSString *const kSHKStoredItemImagePathKey = @"imagePath";
static NSString *const kSHKStoredItemImagePathsKey = @"imagePaths";

static NSString *const kSHKStoredItemDataPathKey = @"dataPath";
//static NSString *const kSHKStoredItemDataPathsKey = @"dataPaths";

@interface SHKFacebook ()
+ (Facebook*)  facebook;
+ (void)       flushAccessToken;
+ (NSString *) storedImagePath:(UIImage*)image;
+ (UIImage*)   storedImage:(NSString*)imagePath;
+ (NSString *) storedDataPath:(NSData*)data;
+ (NSData*)   storedData:(NSString*)dataPath;

- (void) sendImage:(UIImage*)image forItem:(SHKItem*)anItem;
- (void) sendData:(NSData*)data forItem:(SHKItem*)anItem;

@end

@implementation SHKFacebook

@synthesize sendImageIndex;

- (void) dealloc
{
    [super dealloc];
}

+ (Facebook*) facebook
{
    static Facebook *facebook = nil;

    @synchronized([SHKFacebook class ])
    {
        if (!facebook)
            facebook = [[Facebook alloc] initWithAppId:SHKFacebookAppID];
    }
    return facebook;
}

+ (void) flushAccessToken
{
    Facebook *facebook = [self facebook];

    facebook.accessToken = nil;
    facebook.expirationDate = nil;
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults removeObjectForKey:kSHKFacebookAccessTokenKey];
    [defaults removeObjectForKey:kSHKFacebookExpiryDateKey];
    [defaults synchronize];
}

+ (NSString *) storedImagePath:(UIImage*)image
{
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
    NSString *cache = [paths objectAtIndex:0];
    NSString *imagePath = [cache stringByAppendingPathComponent:@"SHKImage"];

    // Check if the path exists, otherwise create it
    if (![fileManager fileExistsAtPath:imagePath])
    {
        [fileManager createDirectoryAtPath:imagePath withIntermediateDirectories:YES attributes:nil error:nil];
    }

    NSString *uid = [NSString stringWithFormat:@"img-%i-%i", (int)[[NSDate date] timeIntervalSince1970], arc4random()];
    // store image in cache
    NSData *imageData = UIImagePNGRepresentation(image);
    imagePath = [imagePath stringByAppendingPathComponent:uid];
    [imageData writeToFile:imagePath atomically:YES];

    return imagePath;
}

+ (UIImage*) storedImage:(NSString*)imagePath
{
    NSData *imageData = [[NSData alloc] initWithContentsOfFile:imagePath];
    UIImage *image = nil;

    if (imageData)
    {
        image = [UIImage imageWithData:imageData];
        [imageData release];
    }
    // Unlink the stored file:
    [[NSFileManager defaultManager] removeItemAtPath:imagePath error:nil];
    return image;
}

+ (NSString *) storedDataPath:(NSData*)data
{
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
    NSString *cache = [paths objectAtIndex:0];
    NSString *dataPath = [cache stringByAppendingPathComponent:@"SHKData"];
    
    // Check if the path exists, otherwise create it
    if (![fileManager fileExistsAtPath:dataPath])
    {
        [fileManager createDirectoryAtPath:dataPath withIntermediateDirectories:YES attributes:nil error:nil];
    }
    
    NSString *uid = [NSString stringWithFormat:@"dat-%i-%i", (int)[[NSDate date] timeIntervalSince1970], arc4random()];
    // store data in cache
    dataPath = [dataPath stringByAppendingPathComponent:uid];
    [data writeToFile:dataPath atomically:YES];
    
    return dataPath;
}

+ (NSData*) storedData:(NSString*)dataPath
{
    NSData *data = [[[NSData alloc] initWithContentsOfFile:dataPath] autorelease];
    // Unlink the stored file:
    [[NSFileManager defaultManager] removeItemAtPath:dataPath error:nil];
    return data;
}

+ (BOOL) handleOpenURL:(NSURL*)url
{
    Facebook *fb = [SHKFacebook facebook];

    if (!fb.sessionDelegate)
    {
        SHKFacebook *sharer = [[[SHKFacebook alloc] init] autorelease];
        fb.sessionDelegate = sharer;
    }
    return [fb handleOpenURL:url];
}

#pragma mark -
#pragma mark Configuration : Service Defination

+ (NSString *) sharerTitle
{
    return @"Facebook";
}

+ (BOOL) canShareURL
{
    return YES;
}

+ (BOOL) canShareText
{
    return YES;
}

+ (BOOL) canShareImage
{
    return YES;
}

+ (BOOL) canShareImages
{
    return YES;
}

+ (BOOL) canShareOffline
{
    return NO;     // TODO - would love to make this work
}

+ (BOOL) canShareFile
{
    return YES;
}

#pragma mark -
#pragma mark Configuration : Dynamic Enable

- (BOOL) shouldAutoShare
{
    return YES;
}

#pragma mark -
#pragma mark Authentication

- (BOOL) isAuthorized
{
    Facebook *facebook = [SHKFacebook facebook];

    if ([facebook isSessionValid])
    {
        return YES;
    }

    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    facebook.accessToken = [defaults stringForKey:kSHKFacebookAccessTokenKey];
    facebook.expirationDate = [defaults objectForKey:kSHKFacebookExpiryDateKey];
    return [facebook isSessionValid];
}

- (void) promptAuthorization
{
    NSMutableDictionary *itemRep = [NSMutableDictionary dictionaryWithDictionary:[self.item dictionaryRepresentation]];

    if (self.item.image)
    {
        [itemRep setObject:[SHKFacebook storedImagePath:self.item.image] forKey:kSHKStoredItemImagePathKey];
    }
    else if (self.item.images)
    {
        NSMutableArray *images = [NSMutableArray arrayWithCapacity:self.item.images.count];
        for (UIImage *image in self.item.images)
        {
            [images addObject:[SHKFacebook storedImagePath:image]];
        }
        [itemRep setObject:images forKey:kSHKStoredItemImagePathsKey];
    }
    else if (self.item.data)
    {
        [itemRep setObject:[SHKFacebook storedDataPath:self.item.data] forKey:kSHKStoredItemDataPathKey];
    }
    [[NSUserDefaults standardUserDefaults] setObject:itemRep forKey:kSHKStoredItemKey];
#ifdef SHKFacebookLocalAppID
    [[SHKFacebook facebook] authorize:[NSArray arrayWithObjects:@"publish_stream",
                                       @"offline_access", nil]
                             delegate:self
                           localAppId:SHKFacebookLocalAppID];
#else
    [[SHKFacebook facebook] authorize:@[@"publish_stream",
                                       @"offline_access"]
                             delegate:self];
#endif
}

- (void) authFinished:(SHKRequest *)req
{
}

+ (void) logout
{
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:kSHKStoredItemKey];
    [self flushAccessToken];
    [[self facebook] logout:nil];
}

#pragma mark -
#pragma mark Share API Methods

- (BOOL) send
{
    NSMutableDictionary *params = [NSMutableDictionary dictionary];
    NSString *actions = [NSString stringWithFormat:@"{\"name\":\"Get %@\",\"link\":\"%@\"}",
                         SHKMyAppName, SHKMyAppURL];

    [params setObject:actions forKey:@"actions"];

    if (self.item.shareType == SHKShareTypeURL && self.item.URL)
    {
        NSString *url = [self.item.URL absoluteString];
        [params setObject:url forKey:@"link"];
        [params setObject:self.item.title == nil ? url:self.item.title
                   forKey:@"name"];
        if (self.item.text)
        {
            [params setObject:self.item.text forKey:@"message"];
        }
        NSString *pictureURI = [self.item customValueForKey:@"picture"];
        if (pictureURI)
        {
            [params setObject:pictureURI forKey:@"picture"];
        }
    }
    else if (self.item.shareType == SHKShareTypeText && self.item.text)
    {
        [params setObject:self.item.text forKey:@"message"];
    }

    else if ((self.item.shareType == SHKShareTypeImage && self.item.image) || (self.item.shareType == SHKShareTypeImages && self.item.images))
    {
        [self sendImage];
        return YES;
    }
    else if (self.item.shareType == SHKShareTypeFile && self.item.data != nil)
    {
        [self sendData];
        return YES;
    }
    else
    {
        // There is nothing to send
        return NO;
    }

    [[SHKFacebook facebook] requestWithGraphPath:@"me/feed" 
                                       andParams:params 
                                   andHttpMethod:@"POST" 
                                     andDelegate:self];
    return YES;
}

 - (void)sendImage
 {
     UIImage *sendImage = nil;
     if (item.image != nil)
     {
         sendImage = item.image;
     }
     else if (item.images != nil && item.images.count > 0)
     {
         self.sendImageIndex = 0;
         sendImage = [item.images objectAtIndex:self.sendImageIndex];
     }

     if (sendImage != nil)
     {
         [self sendDidStart];

         [self sendImage:sendImage forItem:item];
     }
 }

 - (void)sendImage:(UIImage*)image forItem:(SHKItem*)anItem
 {
     NSMutableDictionary *params = [NSMutableDictionary dictionary];
     if (item.title)
     {
         [params setObject:item.title forKey:@"caption"];
     }
     if (item.text)
     {
         [params setObject:item.text forKey:@"message"];
     }
     [params setObject:image forKey:@"picture"];
     
     // There does not appear to be a way to add the photo
     // via the dialog option:
     [[SHKFacebook facebook] requestWithGraphPath:@"me/photos"
                                        andParams:params
                                    andHttpMethod:@"POST"
                                      andDelegate:self];
 }

- (void) sendData
{
    if (self.item.data != nil)
    {
        [self sendDidStart];
        [self sendData:self.item.data forItem:self.item];
    }
}

- (void) sendData:(NSData*)data forItem:(SHKItem*)anItem
{
    NSMutableDictionary *params = [NSMutableDictionary dictionary];
    if (item.title)
    {
        [params setObject:item.title forKey:@"caption"];
    }
    if (item.text)
    {
        [params setObject:item.text forKey:@"message"];
    }

    // TODO: handle non-image data properly here.
    [params setObject:data forKey:@"picture"];
    
    // There does not appear to be a way to add the photo
    // via the dialog option:
    [[SHKFacebook facebook] requestWithGraphPath:@"me/photos"
                                       andParams:params
                                   andHttpMethod:@"POST"
                                     andDelegate:self];
}

#pragma mark -
#pragma mark FBDialogDelegate methods

- (void) dialogDidComplete:(FBDialog *)dialog
{
    [self sendDidFinish];
}

- (void) dialogCompleteWithUrl:(NSURL *)url
{
    // error_code=190: user changed password or revoked access to the application,
    // so spin the user back over to authentication :
    NSRange errorRange = [[url absoluteString] rangeOfString:@"error_code=190"];

    if (errorRange.location != NSNotFound)
    {
        [SHKFacebook flushAccessToken];
        [self authorize];
    }
}

- (void) dialogDidCancel:(FBDialog*)dialog
{
    [self sendDidCancel];
}

- (void) dialog:(FBDialog *)dialog didFailWithError:(NSError *)error
{
    [self sendDidFailWithError:error];
}

- (BOOL) dialog:(FBDialog*)dialog shouldOpenURLInExternalBrowser:(NSURL*)url
{
    return YES;
}

#pragma mark FBSessionDelegate methods

- (void) fbDidLogin
{
    NSString *accessToken = [[SHKFacebook facebook] accessToken];
    NSDate *expiryDate = [[SHKFacebook facebook] expirationDate];
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];

    [defaults setObject:accessToken forKey:kSHKFacebookAccessTokenKey];
    [defaults setObject:expiryDate forKey:kSHKFacebookExpiryDateKey];
    NSDictionary *storedItem = [defaults objectForKey:kSHKStoredItemKey];
    if (storedItem)
    {
        self.item = [SHKItem itemFromDictionary:storedItem];
        NSString *imagePath = [storedItem objectForKey:kSHKStoredItemImagePathKey];
        NSArray *imagePaths = [storedItem objectForKey:kSHKStoredItemImagePathsKey];
        NSString *dataPath  = [storedItem objectForKey:kSHKStoredItemDataPathKey];
        if (imagePath != nil)
        {
            self.item.image = [SHKFacebook storedImage:imagePath];
        }
        else if (imagePaths != nil)
        {
            NSMutableArray *images = [NSMutableArray arrayWithCapacity:imagePaths.count];
            for (NSString *p in imagePaths)
            {
                [images addObject:[SHKFacebook storedImage:p]];
            }
            self.item.images = images;
        }
        else if (dataPath != nil)
        {
            self.item.data = [SHKFacebook storedData:dataPath];
        }
        [defaults removeObjectForKey:kSHKStoredItemKey];
    }
    [defaults synchronize];
    if (self.item)
    {
        [self share];
    }
}

#pragma mark FBRequestDelegate methods

- (void) requestLoading:(FBRequest *)request
{
    [self sendDidStart];
}

- (void) request:(FBRequest *)aRequest didLoad:(id)result
{
    if ([aRequest.url rangeOfString:@"me/photos"].location != NSNotFound)
    {
        if (self.item.images != nil && self.sendImageIndex != (self.item.images.count - 1))
        {
            self.sendImageIndex++;
            [self sendImage:[item.images objectAtIndex:self.sendImageIndex] forItem:item];
        }
        else
        {
            [self sendDidFinish];
        }
    }
}

- (void) request:(FBRequest*)aRequest didFailWithError:(NSError*)error
{
    if ([aRequest.url rangeOfString:@"me/photos"].location != NSNotFound)
    {
        self.sendImageIndex++;
    }
    [self sendDidFailWithError:error];
}

@end
