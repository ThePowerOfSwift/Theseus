//
//  DataProcessor.m
//  Theseus
//
//  Created by Mike Lazer-Walker on 5/27/14.
//  Copyright (c) 2014 Mike Lazer-Walker
//
//  This program is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 2 of the License, or
//  (at your option) any later version.
//
//  This program is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with this program.  If not, see <http://www.gnu.org/licenses/>

#define EXP_SHORTHAND
#define HC_SHORTHAND
#define MOCKITO_SHORTHAND
#import <OCMockito/OCMockito.h>
#import <Specta.h>
#import <Expecta.h>

#import "DataProcessor.h"
#import "Fixture.h"

SpecBegin(DataProcessor)

describe(@"DataProcessor", ^{
    __block DataProcessor *processor;
    beforeEach(^{
        [Fixture clearData];
        processor = [DataProcessor new];
    });

    describe(@"Doing a full process from scratch", ^{
        beforeEach(^{
            [Fixture loadFixtureNamed:@"ProcessAll"];
        });
        
        xit(@"should do the thing", ^AsyncBlock {
            setAsyncSpecTimeout(60);
            [processor reprocessDataWithCompletion:^(BOOL success, NSError *error) {
                expect(processor.allEvents.count).to.equal(4);
                done();
            }];
        });
    });
});

SpecEnd