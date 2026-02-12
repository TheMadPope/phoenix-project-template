# Salesforce Development Guidelines
---

## General Principles

- **Consider the entire #codebase** when answering questions
- **Disregard deprecated/legacy code** - ignore classes and methods marked as deprecated or legacy
- **Search comprehensively** - examine all subfolders within classes/ and triggers/ folders
- **Reuse existing code** - prefer existing patterns, methods, and classes over creating new ones
- **Avoid duplication** - utilize existing Service class methods rather than duplicating functionality
- **Compose methods** - when adding new methods to a class, check for existing methods that can be reused to reduce code duplication

### Method Composition Workflow (REQUIRED)

When adding a new method to an existing class, follow this workflow:

1. **READ the entire class first** - Review all existing methods before writing new code
2. **IDENTIFY reusable methods** - Look for methods that handle similar operations or create the same sObject types
3. **COMPOSE, don't duplicate** - Call existing methods and extend their functionality rather than rewriting logic
4. **ONLY add new fields** - If an existing method creates 80% of what you need, call it and add the remaining 20%

**Example of proper composition:**
```apex
// ✅ CORRECT: Reuses createTask() method
public static void createTacoReminders(Map<Id, Taco__c> tacoById) {
    List<Task> tasksToInsert = new List<Task>();

    for (Taco__c taco : tacoById.values()) {
        // Call existing method for base Task creation
        Task reminderTask = createTask('Eat your taco!', taco.OwnerId);

        // Add Taco-specific fields
        reminderTask.WhatId = taco.Id;
        reminderTask.Status = 'Not Started';
        reminderTask.Priority = 'High';
        reminderTask.ActivityDate = Date.today();
        reminderTask.ReminderDateTime = DateTime.now().addHours(1);
        reminderTask.IsReminderSet = true;
        tasksToInsert.add(reminderTask);
    }

    if (!tasksToInsert.isEmpty()) {
        Database.insert(tasksToInsert);
    }
}

// ❌ INCORRECT: Duplicates logic from createTask()
public static void createTacoReminders(Map<Id, Taco__c> tacoById) {
    List<Task> tasksToInsert = new List<Task>();

    for (Taco__c taco : tacoById.values()) {
        Task reminderTask = new Task();
        reminderTask.Subject = 'Eat your taco!';  // Duplicates createTask logic
        reminderTask.OwnerId = taco.OwnerId;      // Duplicates createTask logic
        // ... rest of fields
    }
}
```

---

## Architecture Patterns

### Separation of Concerns

- **Selector classes**: Handle all SOQL queries
- **Service classes**: Handle all DML operations
  - Prefer `Database` methods over DML statements (e.g., `Database.insert()` vs `insert`)
- **Trigger handlers**: Delegate to Service classes; don't perform business logic directly

### Service Class Ownership Rules

Service methods belong to the class representing the **object being modified**, not the input object:

- ✅ **Correct**: Method that creates `Bed__c` records from `Dog__c` data → `BedService`
- ❌ **Incorrect**: Same method → `DogService`

**Rule**: The Service class is determined by which object receives DML operations or is otherwise modified.

---

## Trigger Guidelines

### Required Structure

1. **Extend base class**: `./force-app/main/default/classes/utility/TriggerHandler.cls`
   - Reference: `ContactTrigger`
2. **Delegate to Service classes**: Use composed methods, pass records to Service
   - Reference: `./force-app/main/default/classes/triggerHandlers/QuizQuestionTriggerHandler.cls`
3. **Register all events**: Attach triggers to ALL events (before/after insert/update/delete/undelete)
4. **Location**: `./force-app/main/default/triggers/bridge/`
5. **One-line handler invocation**: Instantiate and call `.run()` in a single statement
   - ✅ **Correct**: `new ObjectTriggerHandler().run();`
   - ❌ **Incorrect**: Declaring a variable first, then calling `.run()` on separate line

**Example trigger:**
```apex
trigger ContactTrigger on Contact (after delete, after insert, after update, after undelete, before delete, before insert, before update){
    new ContactTriggerHandler().run();
}
```

---

## Code Organization and Style

### File Locations

- **Apex classes**: `./force-app/main/default/classes/[subfolder]/`
  - Subfolders: `triggerHandlers/`, `services/`, `selectors/`, `utilities/`, etc.
- **Triggers**: `./force-app/main/default/triggers/`

### Method Organization and Style

- Keep methods **thin and reusable**
- - **Target**: Methods should be 10-30 lines max
- - **If longer**: Break into smaller helper methods
- - **Single Responsibility**: Each method does ONE thing (SLAP principle)
- - **Reusable**: Parameterize instead of hardcoding values (DRY principle)
- Order methods **alphabetically** within each class
- Return type is defined by signature - don't include in method name
- **Use JavaDoc comments for every method** (except unit test methods)
  - Include description, `@param` for each parameter, and `@return` if applicable
  - Example:
    ```apex
    /**
     * Creates Task reminders for Taco owners to eat their tacos within 1 hour
     * @param tacoById (Map<Id, Taco__c>): Map of Taco records after insert
     */
    public static void createTacoReminders(Map<Id, Taco__c> tacoById) {
    ```

## Pre-Edit Checklist

Before modifying trigger/service/selector code:
1. ✅ Read the entire file to understand context
2. ✅ Search for existing similar methods to reuse
3. ✅ Check if related Service/Selector classes exist
4. ✅ Verify naming follows conventions
5. ✅ Plan test coverage (positive + negative cases)
---

## Testing Requirements

### Test Coverage

- Create test class for **every Apex class**
- Target **100% coverage** (or as close as possible)
- **Minimum**: 1 positive test + 1 negative test per method
- Test class naming: `[ClassName]Test` (no underscores)
  - Example: `CaseServiceTest`
- Test method naming: `itShould[ExpectedBehavior]`
  - Example: `itShouldCreateTacoReminders`, `itShouldHandleEmptyMap`
  - Use descriptive names that explain what the test verifies

### Test Strategy: Direct Unit Tests + Integration Tests

**CRITICAL**: For every method invoked via DML, write BOTH types of tests:

1. **Direct Unit Tests** (required for ALL methods)
   - Call the method DIRECTLY without database operations
   - Faster execution, no governor limits
   - Test the method's logic in isolation
   - Example:
     ```apex
     @isTest
     private static void itShouldAddErrorWhenEmailIsNull() {
         Contact contactRecord = TestFactory.contactBuild(new Map<String, Object>{'Email' => null}, false);
         List<Contact> contacts = new List<Contact>{ contactRecord };

         Test.startTest();
         ContactService.validateEmail(contacts); // Direct method call
         Test.stopTest();

         Assert.isTrue(contactRecord.hasErrors(), 'Contact should have errors');
     }
     ```
     - If the method is private, add the `@testVisible` decorator to allow direct testing

2. **Integration Tests** (to verify trigger/handler integration)
   - Test through database operations (insert/update/delete)
   - Verify the method works correctly when called through triggers
   - Example:
     ```apex
     @isTest
     private static void itShouldPreventInsertOfContactWithoutEmail() {
         Contact contactRecord = TestFactory.contactBuild(new Map<String, Object>{'Email' => null}, false);

         Test.startTest();
         Database.SaveResult result = Database.insert(contactRecord, false);
         Test.stopTest();

         Assert.isFalse(result.isSuccess(), 'Insert should fail');
     }
     ```

**When to use each**:
- ✅ **Direct Unit Tests**: Every method. To verify logic in isolation.
- ✅ **Integration Tests**: To verify trigger handlers, DML operations, and end-to-end flows
- 🔥 **BOTH**: Always write both when testing methods called from triggers

### Test Data Creation

- **ALWAYS use `TestFactory`** for creating test data - this is mandatory
- **NEVER create sObjects directly** in test classes using `new ObjectName()`
  - ❌ **WRONG**: `Account acc = new Account(); acc.Name = 'Test'; insert acc;`
  - ✅ **CORRECT**: `Account acc = TestFactory.accountBuild(new Map<String, Object>{'Name' => 'Test'}, true);`
- If needed object doesn't have a factory method, **add it to TestFactory first**
  - Follow pattern: `TestFactory.objectNameBuild(Map<String, Object> parameters, Boolean doInsert)`
  - Also create overload: `TestFactory.objectNameBuild(Boolean doInsert)`
- **ALWAYS use Assert class** for assertions, not `System.assert`

### Test Structure

```apex
// Setup test data BEFORE Test.startTest()

// Wrap the code being tested
Test.startTest();
// Unit of code being tested (NO ASSERTIONS HERE)
Test.stopTest();

// ALL assertions AFTER Test.stopTest()
// Use Assert class (not System.assert)
Assert.areEqual(expected, actual, 'Message');
```

**CRITICAL**:
- ❌ **NEVER** put assertions inside `Test.startTest()` and `Test.stopTest()` block
- ✅ **ALWAYS** put assertions after `Test.stopTest()`
- The Test.startTest/stopTest block is for executing the code under test, not for verifying results

### Test Data Principles

- **Avoid database calls** where possible
- **NEVER perform DML or SOQL inside loops** - always use bulk operations
  - ❌ **WRONG**: Loop with `TestFactory.tacoBuild(..., true)` on each iteration
  - ✅ **CORRECT**: Build collection in loop with `false`, then `Database.insert(collection)` after loop
- Create **minimum setup** required to test the method
- Focus on testing method behavior, not Salesforce platform features

---

## Naming Conventions

### Salesforce Objects & Fields

| Element | Convention | Example |
|---------|------------|---------|
| Custom fields | No underscores (except `__c`) | `MyCustomField__c` ✅<br>`My_Custom_Field__c` ❌ |

### Apex Code

| Element | Convention | Example |
|---------|------------|---------|
| Classes | PascalCase | `CaseService`, `AccountSelector` |
| Methods | camelCase | `processRecords`, `calculateTotal` |
| Methods | Avoid redundant context | In `TaskService`: `createReminder()` ✅<br>`createTaskReminder()` ❌ |
| Variables | camelCase | `loopCounter` (not `intLoopCounter`) |
| Maps | `valueByKey` pattern | `accountById`, `contactsByAccountId` |

### Flows

**Pattern**: `ObjectName_Action`

```
Case_AssignOwner
Invoice_SubmitForApproval
ObjectName_ThingYouAreDoing
```

### Class Types & Naming

| Type | Pattern | Examples |
|------|---------|----------|
| Trigger Handler | `[Object]TriggerHandler` | `CaseTriggerHandler`, `InvoiceTriggerHandler` |
| Service | `[Object]Service` | `CaseService`, `InvoiceService` |
| Selector | `[Object]Selector` | `CaseSelector`, `InvoiceSelector` |
| Test Class | `[ClassName]Test` | `CaseServiceTest` (no underscores) |

### Variable Naming Best Practices

- **Be descriptive but brief**: `account` ✅ vs `acct` ❌
- **Exception**: Use abbreviations only if commonly known
  - Example: `fbiAgent` ✅ (FBI is well-known abbreviation)
- **No type prefixes**: `loopCounter` ✅ vs `intLoopCounter` ❌
- **Longer names OK** when clarity requires it
---

## Lightning Web Components (LWC)

### LWC Naming Conventions

**CRITICAL**: Use **fully lowercase** naming for all LWC components, attributes, and properties:

| Element | Convention | Example |
|---------|------------|---------|
| Component names | lowercase | `magiccard` ✅, `magic-card` ❌, `magicCard` ❌ |
| Component folder | lowercase | `lwc/confirmation/` ✅, `lwc/genericConfirmation/` ❌ |
| HTML attributes | lowercase | `isvisible` ✅, `is-visible` ❌, `isVisible` ❌ |
| JavaScript properties | lowercase | `showconfirmation` ✅, `showConfirmation` ❌ |
| Event names | lowercase | `cardselected` ✅, `card-selected` ❌, `cardSelected` ❌ |

**Examples:**
```html
<!-- ✅ CORRECT -->
<c-confirmation
    isvisible={showconfirmation}
    title="Confirm Action"
    onconfirm={handleconfirm}
></c-confirmation>

<!-- ❌ INCORRECT -->
<c-confirmation
    is-visible={showConfirmation}
    title="Confirm Action"
    onconfirm={handleConfirm}
></c-confirmation>
```

```javascript
// ✅ CORRECT
export default class Confirmation extends LightningElement {
    @api isvisible = false;
    @api confirmLabel = 'Confirm';
}

// ❌ INCORRECT
export default class Confirmation extends LightningElement {
    @api isVisible = false;
    @api confirmLabel = 'Confirm';
}
```