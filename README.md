# CoreData-Conflict-Demo

A demo app for testing Core Data's merge conflict. 

### About `testUpdateUpdatedManyToManyRelationshipWithOverwritePolicy`

There're 3 contexts **on same coordinator**, which means they share the row cache.

1. Insert the following data to DB on `context1`:

```swift
/// EntityA(attribute: 100).toManyRelationship = [EntityB(attribute: 10), EntityB(attribute: 11)]
/// EntityA(attribute: 200).toManyRelationship = [EntityB(attribute: 11), EntityB(attribute: 12)]
///
/// EntityB(attribute: 10).toManyRelationship = [EntityA(attribute: 100)]
/// EntityB(attribute: 11).toManyRelationship = [EntityA(attribute: 100), EntityA(attribute: 200)]
/// EntityB(attribute: 12).toManyRelationship = [EntityA(attribute: 200)]
```

2. Set `mergePolicy` of `context1` to **`.overwrite`**.

2. Delete `EntityB(attribute: 10)` from `EntityA(attribute: 100)` on `context1`, **do not save**.

3. Delete `EntityB(attribute: 11)` from `EntityA(attribute: 100)` on `context2`, save changes.

4. Save changes on `context1`, where a conflict will occur..

5. Conflict is solved by Core Data, currently the data stored in DB is like:

```swift
/// EntityA(attribute: 100).toManyRelationship = []
/// EntityA(attribute: 200).toManyRelationship = [EntityB(attribute: 11), EntityB(attribute: 12)]
///
/// EntityB(attribute: 10).toManyRelationship = []
/// EntityB(attribute: 11).toManyRelationship = [EntityA(attribute: 200)]
/// EntityB(attribute: 12).toManyRelationship = [EntityA(attribute: 200)]
```

6. However, if we fetch data on `context3` with a newly created fetch request, the data would be:

```swift
/// EntityA(attribute: 100).toManyRelationship = [EntityB(attribute: 10)] ??????
/// ...Remaning are same as above
```


Discussion/Question: 
1. I think the relationship data are fetched from row cache instead of SQLite store, but why `EntityA(attribute: 100).toManyRelationship` is not empty?
2. And, if inserting the data on a different context like `context4` or contexts on other coordinator, doing 2~6 will result in the same data as SQLite storage. (Which is what I think it should be.)
