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

#import "MergeEntityDirectTests.h"
#import "WAToolkit.h"

@implementation MergeEntityDirectTests

#ifdef INTEGRATION_DIRECT

- (void)setUp
{
    [super setUp];
    
    [directClient createTableNamed:randomTableNameString withCompletionHandler:^(NSError *error) {
        XCTAssertNil(error, @"Error returned by createTableNamed: %@", [error localizedDescription]);   
        [directDelegate markAsComplete];
    }];
    [directDelegate waitForResponse];
    
    
    _testEntity = [WATableEntity createEntityForTable:randomTableNameString];	
	_testEntity.partitionKey = @"a";
	_testEntity.rowKey = @"01021972";
	[_testEntity setObject:@"199" forKey:@"Price"];
    
	// Setup before we run the actual test
    [directClient insertEntity:_testEntity withCompletionHandler:^(NSError *error) {
        XCTAssertNil(error, @"Setup: Error returned by insertEntity: %@", [error localizedDescription]);
        [directDelegate markAsComplete];
    }];
    [directDelegate waitForResponse];
}

- (void)tearDown
{
    [directClient deleteTableNamed:randomTableNameString withCompletionHandler:^(NSError *error) {
        XCTAssertNil(error, @"Error returned by deleteTableNamed: %@", [error localizedDescription]);
        [directDelegate markAsComplete];
    }];
    [directDelegate waitForResponse];
    
    [super tearDown];
}

-(void)testShouldMergeTableEntityWithCompletionHandler
{
	[_testEntity setObject:@"399" forKey:@"Price"];
    [directClient mergeEntity:_testEntity withCompletionHandler:^(NSError *error) {
        XCTAssertNil(error, @"Error returned by updateEntity: %@", [error localizedDescription]);
        [directDelegate markAsComplete];
    }];
    [directDelegate waitForResponse];
    
    NSError *error = nil;
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"Price = '399'"];
    WATableFetchRequest* fetchRequest = [WATableFetchRequest fetchRequestForTable:randomTableNameString predicate:predicate error:&error];
	XCTAssertNil(error, @"Predicate parser error: %@", [error localizedDescription]);
    
    [directClient fetchEntitiesWithRequest:fetchRequest usingCompletionHandler:^(NSArray *entities, WAResultContinuation *resultContinuation, NSError *error) {
        XCTAssertNil(error, @"Error returned by fetchEntities: %@", [error localizedDescription]);
        XCTAssertNotNil(entities, @"fetchEntities returned nil");
        XCTAssertEqual(entities.count, (NSUInteger)1, @"fetchEntities returned incorrect number of entities");
        WATableEntity *entityFound = [entities objectAtIndex:0];
        XCTAssertEqualObjects([entityFound objectForKey:@"Price"], @"399", @"Entity was not updated.");
        [directDelegate markAsComplete];
    }];
    [directDelegate waitForResponse];    
}

#endif

@end
