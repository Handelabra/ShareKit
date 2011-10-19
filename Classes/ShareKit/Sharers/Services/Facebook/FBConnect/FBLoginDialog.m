/*
 * Copyright 2010 Facebook
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 * 
 *    http://www.apache.org/licenses/LICENSE-2.0
 
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

#import "FBDialog.h"
#import "FBLoginDialog.h"

///////////////////////////////////////////////////////////////////////////////////////////////////

@implementation FBLoginDialog

///////////////////////////////////////////////////////////////////////////////////////////////////
// public 

/*
 * initialize the FBLoginDialog with url and parameters
 */
- (id)initWithURL:(NSString*) loginURL 
      loginParams:(NSMutableDictionary*) params 
         delegate:(id <FBLoginDialogDelegate>) delegate{
  
<<<<<<< HEAD
  if (_session.getSessionProxy) {
    [_getSessionRequest post:_session.getSessionProxy params:params];
  } else {
    [_getSessionRequest call:@"facebook.auth.getSession" params:params];
  }
}

- (void)loadLoginPage {
  NSDictionary* params = [NSDictionary dictionaryWithObjectsAndKeys:
    @"1", @"fbconnect", @"touch", @"connect_display", _session.apiKey, @"api_key",
    @"fbconnect://success", @"next", nil];

  [self loadURL:kLoginURL method:@"GET" get:params post:nil];
}

///////////////////////////////////////////////////////////////////////////////////////////////////
// NSObject

- (id)initWithSession:(FBSession*)session {
  if ((self = [super initWithSession:session])) {
    _getSessionRequest = nil;
  }
=======
  self = [super init];
  _serverURL = [loginURL retain];
  _params = [params retain];
  _loginDelegate = delegate;
>>>>>>> newfb-fork
  return self;
}

///////////////////////////////////////////////////////////////////////////////////////////////////
// FBDialog

/**
 * Override FBDialog : to call when the webView Dialog did succeed
 */
- (void) dialogDidSucceed:(NSURL*)url {
  NSString *q = [url absoluteString];
  NSString *token = [self getStringFromUrl:q needle:@"access_token="];
  NSString *expTime = [self getStringFromUrl:q needle:@"expires_in="];
  NSDate *expirationDate =nil;
  
  if (expTime != nil) {
    int expVal = [expTime intValue];
    if (expVal == 0) {
      expirationDate = [NSDate distantFuture];
    } else {
      expirationDate = [NSDate dateWithTimeIntervalSinceNow:expVal];
    } 
  } 
  
  if ((token == (NSString *) [NSNull null]) || (token.length == 0)) {
    [self dialogDidCancel:url];
    [self dismissWithSuccess:NO animated:YES];
  } else {
    if ([_loginDelegate respondsToSelector:@selector(fbDialogLogin:expirationDate:)]) {
      [_loginDelegate fbDialogLogin:token expirationDate:expirationDate];
    }
    [self dismissWithSuccess:YES animated:YES];
  }
  
}

/**
 * Override FBDialog : to call with the login dialog get canceled 
 */
- (void)dialogDidCancel:(NSURL *)url {
  [self dismissWithSuccess:NO animated:YES];
  if ([_loginDelegate respondsToSelector:@selector(fbDialogNotLogin:)]) {
    [_loginDelegate fbDialogNotLogin:YES];
  }
}

<<<<<<< HEAD
///////////////////////////////////////////////////////////////////////////////////////////////////
// FBRequestDelegate

- (void)request:(FBRequest*)request didLoad:(id)result {
  NSDictionary* object = result;
  FBUID uid = (FBUID)[[object objectForKey:@"uid"] longLongValue];
  NSString* sessionKey = [object objectForKey:@"session_key"];
  NSString* sessionSecret = [object objectForKey:@"secret"];
  NSTimeInterval expires = [[object objectForKey:@"expires"] floatValue];
  NSDate* expiration = expires ? [NSDate dateWithTimeIntervalSince1970:expires] : nil;
  
  [_getSessionRequest release];
  _getSessionRequest = nil;

  [_session begin:uid sessionKey:sessionKey sessionSecret:sessionSecret expires:expiration];
  [_session resume];
  
  [self dismissWithSuccess:YES animated:YES];
=======
- (void)webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error {
  if (!(([error.domain isEqualToString:@"NSURLErrorDomain"] && error.code == -999) ||
        ([error.domain isEqualToString:@"WebKitErrorDomain"] && error.code == 102))) {
    [super webView:webView didFailLoadWithError:error];
    if ([_loginDelegate respondsToSelector:@selector(fbDialogNotLogin:)]) {
      [_loginDelegate fbDialogNotLogin:NO];
    }
  }
>>>>>>> newfb-fork
}

@end
