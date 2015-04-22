//
//  KSS3AbortMultipartUploadRequest.m
//  KS3iOSSDKDemo
//
//  Created by Blues on 12/18/14.
//  Copyright (c) 2014 Blues. All rights reserved.
//

#import "KS3AbortMultipartUploadRequest.h"
#import "KS3Constants.h"

@implementation KS3AbortMultipartUploadRequest

- (instancetype)initWithName:(NSString *)bucketName
{
    self = [super init];
    if (self) {
        self.bucket = [self URLEncodedString:bucketName];
        self.httpMethod = kHttpMethodDelete;
        self.contentMd5 = @"";
        self.contentType = @"";
        self.kSYHeader = @"";
        self.kSYResource = [NSString stringWithFormat:@"/%@", self.bucket];
        self.host = [NSString stringWithFormat:@"http://%@.kss.ksyun.com/", self.bucket];
    }
    return self;
}

-(id)initWithMultipartUpload:(KS3MultipartUpload *)multipartUpload
{
    if(self = [super init])
    {
        self.bucket   = [self URLEncodedString:multipartUpload.bucket];
        self.key      = [self URLEncodedString:multipartUpload.key];
        self.uploadId = multipartUpload.uploadId;
        
        self.httpMethod = kHttpMethodDelete;
        self.contentMd5 = @"";
        self.contentType = @"";
        self.kSYHeader = @"";
        self.kSYResource = [NSString stringWithFormat:@"/%@", self.bucket];
        self.host = [NSString stringWithFormat:@"http://%@.kss.ksyun.com", self.bucket];
    }
    
    return self;
}

- (KS3URLRequest *)configureURLRequest{
    
    self.kSYResource = [NSString stringWithFormat:@"%@/%@?uploadId=%@", self.kSYResource, _key, self.uploadId];
    self.host = [NSString stringWithFormat:@"%@/%@?uploadId=%@",self.host,_key, _uploadId];
    [super configureURLRequest];
    return self.urlRequest;
}

@end
