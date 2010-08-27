//
//  NXOAuth2PostBodyPart.m
//  OAuth2Client
//
//  Created by Ullrich Schäfer on 27.08.10.
//  Copyright 2010 nxtbgthng. All rights reserved.
//

#import "NXOAuth2FileStreamWrapper.h"

#import "NXOAuth2PostBodyPart.h"


@interface NXOAuth2PostBodyPart(Private)
- (id)initWithName:(NSString *)name dataContent:(NSData *)data;
- (id)initWithName:(NSString *)name fileContent:(NSString *)path;
- (id)initWithName:(NSString *)name stringContent:(NSString *)string;
@end


@implementation NXOAuth2PostBodyPart

#pragma mark Lifecycle

+ partWithName:(NSString *)name content:(id)content;
{
	return [[[self alloc] initWithName:name content:content] autorelease];
}

- (id)initWithName:(NSString *)name content:(id)content;
{
	if ([content isKindOfClass:[NSString class]]) {
		return [self initWithName:name stringContent:content];
	} else if ([content isKindOfClass:[NSURL class]] && [content isFileURL]) {
		return [self initWithName:name fileContent:[content path]];
	} else if ([content isKindOfClass:[NSData class]]) {
		return [self initWithName:name dataContent:content];
	} else if ([content isKindOfClass:[NXOAuth2FileStreamWrapper class]]) {
		return [self initWithName:name streamContent:[content stream] streamLength:[content contentLength]];
	} else {
		NSAssert1(NO, @"NXOAuth2PostBodyPart with illegal type:\n%@", [content class]);
		return nil;
	}
}

- (id)initWithName:(NSString *)name streamContent:(NSInputStream *)stream streamLength:(unsigned long long)streamLength;
{
    NSMutableString *headers = [NSMutableString string];
	[headers appendFormat:@"Content-Disposition: form-data; name=\"%@\"; filename=\"unknown\"\r\n", name];
    [headers appendString:@"Content-Transfer-Encoding: binary\r\n"];
	[headers appendString:@"Content-Type: application/octet-stream\r\n"];
	[headers appendString:@"\r\n"];
    return [self initWithHeaders:headers streamContent:stream length:streamLength];
}

- (id)initWithName:(NSString *)name dataContent:(NSData *)data;
{
    NSMutableString *headers = [NSMutableString string];
	[headers appendFormat:@"Content-Disposition: form-data; name=\"%@\"; filename=\"unknown\"\r\n", name];
    [headers appendString:@"Content-Transfer-Encoding: binary\r\n"];
	[headers appendString:@"Content-Type: application/octet-stream\r\n"];
	[headers appendString:@"\r\n"];
    return [self initWithHeaders:headers dataContent:data];
}

- (id)initWithName:(NSString *)name fileContent:(NSString *)path;
{
    NSMutableString *headers = [NSMutableString string];
    [headers appendFormat:@"Content-Disposition: form-data; name=\"%@\"; filename=\"%@\"\r\n", name, [path lastPathComponent]];
    [headers appendString:@"Content-Transfer-Encoding: binary\r\n"];
    [headers appendString:@"Content-Type: application/octet-stream\r\n"];
	[headers appendString:@"\r\n"];
	
#if MAC_OS_X_VERSION_MIN_REQUIRED >= MAC_OS_X_VERSION_10_6
	NSDictionary *fileAttributes = [[NSFileManager defaultManager] attributesOfItemAtPath:path error:nil];
#else
    NSDictionary *fileAttributes = [[NSFileManager defaultManager] fileAttributesAtPath:path traverseLink:YES];
#endif
    NSNumber *fileSize = [fileAttributes valueForKey:NSFileSize];
    
    return [self initWithHeaders:headers
                   streamContent:[NSInputStream inputStreamWithFileAtPath:path]
                          length:[fileSize unsignedLongLongValue]];
}

- (id)initWithName:(NSString *)name stringContent:(NSString *)string;
{
	NSMutableString *headers = [NSMutableString string];
	[headers appendFormat:@"Content-Disposition: form-data; name=\"%@\"\r\n", name];
	[headers appendString:@"\r\n"];
	return [self initWithHeaders:headers dataContent:[string dataUsingEncoding:NSUTF8StringEncoding]];
}

- (id)initWithHeaders:(NSString *)headers dataContent:(NSData *)data;
{
    return [self initWithHeaders: headers
                   streamContent: [NSInputStream inputStreamWithData:data]
                          length: [data length]];
}

- (id)initWithHeaders:(NSString *)headers streamContent:(NSInputStream *)stream length:(unsigned long long)length;
{
    if(self = [super init]){
		contentHeaders = [headers retain];
		contentStream = [stream retain];
		contentLength  = length;
	}    
    return self;
}

- (void)dealloc;
{
    [contentHeaders release];
    [contentStream release];
    [super dealloc];
}


#pragma mark Accessors

@synthesize contentHeaders;
@synthesize contentStream;
@synthesize contentLength;


@end