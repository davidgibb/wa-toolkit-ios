/*
 Copyright 2010 Microsoft Corp
 
 Licensed under the Apache License, Version 2.0 (the "License");
 you may not use this file except in compliance with the License.
 You may obtain a copy of the License at
 
 http://www.apache.org/licenses/LICENSE-2.0
 
 Unless required by applicable law or agreed to in writing, software
 distributed under the License is distributed on an "AS IS" BASIS,
 WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 See the License for the specific language governing permissions and
 limitations under the License.
 */

#import "WACloudURLRequest.h"
#import "WAXMLHelper.h"
#import <libxml/parser.h>

#define SELF_SIGNED_SSL 1 // indicates that the library supports self signed SSL certs

#if SELF_SIGNED_SSL
static NSString* proxyAddress = @"wazmobiletoolkit.cloudapp.net";
#endif

#if USE_QUEUE
static WACloudURLRequest* _head = nil;
static WACloudURLRequest* _tail = nil;
static NSLock* _lock;
#endif

@implementation WACloudURLRequest

#if USE_QUEUE
#pragma mark Request Queuing support

- (void) append:(WACloudURLRequest*)request
{
    _tail = _next = [request retain];
}

- (WACloudURLRequest*)next
{
    return _next;
}

- (void) startNext
{
    [_lock lock];
    @try
    {
        WACloudURLRequest* next = [_head next];
        [_head release];
        if(next)
        {
            _head = next;
            [NSURLConnection connectionWithRequest:_head delegate:_head];
        }
        else
        {
            _head = _tail = nil;
        }
    }
    @finally 
    {
        [_lock unlock];
    }
}

- (void) queueRequest
{
    if(!_lock)
    {
        _lock = [[NSLock alloc] init];
    }
    
    [_lock lock];
    @try
    {
        if(_tail)
        {
            [_tail append:self];
        }
        else
        {
            _head = _tail = [self retain];

            // if I'm the first in queue, start me right away
            [NSURLConnection connectionWithRequest:self delegate:self];
        }
    }
    @finally 
    {
        [_lock unlock];
    }
}

#pragma mark -
#endif

- (void) fetchNoResponseWithCompletionHandler:(WANoResponseHandler)block
{
    _noResponseBlock = [block copy];
	
#if USE_QUEUE
    [self queueRequest];
#else
	[NSURLConnection connectionWithRequest:self delegate:self];
#endif
}

- (void) fetchXMLWithCompletionHandler:(WAFetchXMLHandler)block
{
    _xmlBlock = [block copy];
	
#if USE_QUEUE
    [self queueRequest];
#else
	[NSURLConnection connectionWithRequest:self delegate:self];
#endif
}

- (void) fetchDataWithCompletionHandler:(WAFetchDataHandler)block
{
    _dataBlock = [block copy];
	
#if USE_QUEUE
    [self queueRequest];
#else
	[NSURLConnection connectionWithRequest:self delegate:self];
#endif
}

- (void)dealloc
{
	[_xmlBlock release];
	[_dataBlock release];
	[_data release];
	
	[super dealloc];
}

- (void)sendDataResponse:(NSData*)data error:(NSError*)err 
{
    if(_dataBlock)
    {
        _dataBlock(data, err);
        return;
    }
}

- (void)sendDocumentResponse:(xmlDocPtr)doc error:(NSError*)err 
{
    if(_xmlBlock)
    {
        _xmlBlock(doc, err);
        return;
    }
}

#pragma mark NSURLConnectionDelegate

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response
{
    _expectedContentLength = [response expectedContentLength];
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data
{
	if(!_data)
	{
		_data = [data mutableCopy];
	}
	else 
	{
		[_data appendData:data];
	}
}

#ifdef SELF_SIGNED_SSL

- (BOOL)connection:(NSURLConnection *)connection
canAuthenticateAgainstProtectionSpace:(NSURLProtectionSpace *)protectionSpace
{
	return [protectionSpace.authenticationMethod
			isEqualToString:NSURLAuthenticationMethodServerTrust];
}

- (void)connection:(NSURLConnection *)connection
didReceiveAuthenticationChallenge:(NSURLAuthenticationChallenge *)challenge
{
	if ([challenge.protectionSpace.authenticationMethod
		 isEqualToString:NSURLAuthenticationMethodServerTrust])
	{
		if ([challenge.protectionSpace.host isEqualToString:proxyAddress])
		{
			NSURLCredential *credential =
            [NSURLCredential credentialForTrust:challenge.protectionSpace.serverTrust];
			[challenge.sender useCredential:credential forAuthenticationChallenge:challenge];
		}
	}
	[challenge.sender continueWithoutCredentialForAuthenticationChallenge:challenge];
}
#endif

-(void)connectionDidFinishLoading:(NSURLConnection *)connection
{
    if(_noResponseBlock)
    {
#if FULL_LOGGING
        if(_data)
        {
            NSString* xmlStr = [[NSString alloc] initWithData:_data encoding:NSUTF8StringEncoding];
            NSLog(@"Request URL: %@", [self URL]);
            NSLog(@"XML response: %@", xmlStr);
            [xmlStr release];
        }
#endif
        if(_data)
        {
            const char *baseURL = NULL;
            const char *encoding = NULL;
            
            xmlDocPtr doc = xmlReadMemory([_data bytes], (int)[_data length], baseURL, encoding, (XML_PARSE_NOCDATA | XML_PARSE_NOBLANKS)); 
            NSError* error = [WAXMLHelper checkForError:doc];
            xmlFreeDoc(doc);
            
            if(error)
            {
                _noResponseBlock(error);
                return;
            }
        }
        
        _noResponseBlock(nil);
    }
	else if(_xmlBlock)
	{
        const char *baseURL = NULL;
        const char *encoding = NULL;
        
#if FULL_LOGGING
        NSString* xmlStr = [[NSString alloc] initWithData:_data encoding:NSUTF8StringEncoding];
        NSLog(@"Request URL: %@", [self URL]);
        NSLog(@"XML response: %@", xmlStr);
        [xmlStr release];
#endif
        
        xmlDocPtr doc = xmlReadMemory([_data bytes], (int)[_data length], baseURL, encoding, (XML_PARSE_NOCDATA | XML_PARSE_NOBLANKS)); 
        
        NSError* error = [WAXMLHelper checkForError:doc];

        if(error)
        {
            _xmlBlock(nil, error);
        }
        else
        {
            _xmlBlock(doc, nil);
        }
		
		xmlFreeDoc(doc);
	}
	else if(_dataBlock)
	{
        _dataBlock(_data, nil);
	}

#if USE_QUEUE
    [self startNext];
#endif
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error
{
    if(_noResponseBlock)
    {
        _noResponseBlock(error);
    }
	else if(_xmlBlock)
	{
        _xmlBlock(nil, error);
    }
    else if(_dataBlock)
    {
        _dataBlock(nil, error);
    }

#if USE_QUEUE
    [self startNext];
#endif
}

#pragma mark -

@end


@implementation NSString (URLEncode)

- (NSString*) URLEncode
{
	NSString *result = (NSString *) CFURLCreateStringByAddingPercentEscapes(kCFAllocatorDefault, (CFStringRef)self, NULL, CFSTR(":/?#[]@!$&’()* +,;="), kCFStringEncodingUTF8); 
	return [result autorelease]; 
}

- (NSString*) URLDecode
{
	NSString *result = (NSString *) CFURLCreateStringByReplacingPercentEscapesUsingEncoding(kCFAllocatorDefault, (CFStringRef)self, CFSTR(""), kCFStringEncodingUTF8); 
	return [result autorelease]; 
}

@end