//
//  OBAURLData.m
//  Sitemap
//
//  Created by Chris Brown on 2/13/13.
//  Copyright (c) 2013 Chris Brown. All rights reserved.
//

#import "OBAURLData.h"

@implementation OBAURLData

- (id)init
{
    if ((self = [super init])) {
        self.incomingLinks = 1;
    }
    return self;
}

- (void)addToIncomingLinks
{
    self.incomingLinks++;
}

@end
