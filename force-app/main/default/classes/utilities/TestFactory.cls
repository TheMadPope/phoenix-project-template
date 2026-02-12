/**
 * Utility class to create data / perform common functions for test classes. Declared as @isTest so it doesn't contribute to custom code limits
 * @created 2022-12-08: Richard Moore
 */
@isTest
public without sharing abstract class TestFactory {
    
    /**
     * OVERLOAD: Builds an sObject using the defaults; Optionally inserts the record
     * @param doInsert (boolean): If TRUE, performs Database.insert
     * @return Account: Created sObject
     */
    public static Account accountBuild(boolean doInsert){
        return accountBuild(null, doInsert);
    }
    
    /**
     * Builds an sObject using the parameters provided (or defaults); Optionally inserts the record
     * @param parameters (Map<String, object>): Fields to set on the object
     * @param doInsert (boolean): If TRUE, performs Database.insert
     * @return Account: Created sObject.
     */
    public static Account accountBuild(Map<String, object> parameters, boolean doInsert){
        if (parameters==null){
            parameters = new Map<String, object>();
        }
        // Set defaults for required fieldsif not provided in parameters:
        if (!parameters.containsKey('Name')) {parameters.put('Name', 'TestAccount' + randomString(10));}
        Account result = (Account)JSON.deserialize(JSON.serialize(parameters), Type.forName('Account'));
        if (doInsert){
            Database.insert(result);
        }
        return result;
    }

    /**
     * OVERLOAD: Builds an sObject using the defaults; Optionally inserts the record
     * @param doInsert (boolean): If TRUE, performs Database.insert
     * @return Contact: Created sObject
     */
    public static Contact contactBuild(boolean doInsert){
        return ContactBuild(null, doInsert);
    }

    /**
     * Builds an sObject using the parameters provided (or defaults); Optionally inserts the record
     * @param parameters (Map<String, object>): Fields to set on the object
     * @param doInsert (boolean): If TRUE, performs Database.insert
     * @return Contact: Created sObject
     */
    public static Contact contactBuild(Map<String, object> parameters, boolean doInsert){
        if (parameters==null){
            parameters = new Map<String, object>();
        }
        // Set defaults for required fieldsif not provided in parameters:
        if (!parameters.containsKey('FirstName')) {parameters.put('FirstName', 'FIRST' + randomString(10));}
        if (!parameters.containsKey('LastName')) {parameters.put('LastName', 'LAST' + randomString(10));}
        Contact result = (Contact)JSON.deserialize(JSON.serialize(parameters), Type.forName('Contact'));
        if (doInsert){
            Database.insert(result);
        }
        return result;
    }

    /**
     * Builds a Case using the parameters provided (or defaults); Optionally inserts the record
     * @param parameters (Map<String, object>): Fields to set on the object
     * @param doInsert (boolean): If TRUE, performs Database.insert
     * @return Case: Created sObject
     */
    public static Case caseBuild(Map<String, object> parameters, boolean doInsert){
        if (parameters==null){
            parameters = new Map<String, object>();
        }
        // Set defaults for required fieldsif not provided in parameters:
        if (!parameters.containsKey('Subject')) {parameters.put('Subject', 'Test Case ' + randomString(6));}
        if (!parameters.containsKey('Status')) {parameters.put('Status', 'New');}
        if (!parameters.containsKey('Origin')) {parameters.put('Origin', 'Phone');}
        if (!parameters.containsKey('Priority')) {parameters.put('Priority', 'Low');}
        Case result = (Case)JSON.deserialize(JSON.serialize(parameters), Type.forName('Case'));
        if (doInsert){
            Database.insert(result);
        }
        return result;
    }

    /**
     * Used by getFakeId to ensure unique fake Ids
     */
    static integer fakeIdSeed = 1;
    /**
     * Generates a fake Id that is valid for the given object
     * @param objectType (Schema.SObjectType): The object type to use
     * @return String: The fake Id
     */
    public static String getFakeId(Schema.SObjectType objectType)
    {
        String result = String.valueOf(fakeIdSeed++);
        return objectType.getDescribe().getKeyPrefix() + '0'.repeat(12-result.length()) + result;
    }

    /**
     * Builds an sObject using the parameters provided (or defaults); Optionally inserts the record
     * @param parameters (Map<String, object>): Fields to set on the object
     * @param doInsert (boolean): If TRUE, performs Database.insert
     * @return User: Created sObject
     */
    public static User userBuild(Map<String, object> parameters, boolean doInsert){
        if (parameters==null){
            parameters = new Map<String, object>();
        }
        // Set defaults for required fieldsif not provided in parameters:
        if (!parameters.containsKey('UserName')) {parameters.put('UserName', 'user' + randomEmail());}
        if (!parameters.containsKey('Email')) {parameters.put('Email', parameters.get('UserName'));}
        if (!parameters.containsKey('LastName')) {parameters.put('LastName', 'last' + randomString(10));}
        if (!parameters.containsKey('Alias')) {parameters.put('Alias', randomString(8));}
        if (!parameters.containsKey('ProfileId')) {parameters.put('ProfileId', [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1].Id);}
        if (!parameters.containsKey('TimeZoneSidKey')) {parameters.put('TimeZoneSidKey', 'America/Los_Angeles');}
        if (!parameters.containsKey('EmailEncodingKey')) {parameters.put('EmailEncodingKey', 'UTF-8');}
        if (!parameters.containsKey('LanguageLocaleKey')) {parameters.put('LanguageLocaleKey', 'en_US');}
        if (!parameters.containsKey('LocaleSidKey')) {parameters.put('LocaleSidKey', 'en_US');}

        User result = (User)JSON.deserialize(JSON.serialize(parameters), Type.forName('User'));
        if (doInsert){
            Database.insert(result);
        }
        return result;
    }
    
    /**
     * Returns a random email address with 10 characters before and after the @
     * @return String: Randomly generated email
     */
    public static String randomEmail(){
        return randomString(10) + '@' + randomString(10) + '.com';
    }

    /**
     * Returns a random string of the specified length
     * @param length (integer): The length of string to generate
     * @return String: Random string
     */
    public static String randomString(integer length){
        String stagingKey = '';
        while (stagingKey.length()<length){
            stagingKey += EncodingUtil.base64encode(crypto.generateAesKey(192));
        }
        return stagingKey.substring(0, length).toLowerCase().replaceAll('[^a-zA-Z0-9]', '');
    }
    
    /**
     * Builds an sObject using the parameters provided (or defaults); Optionally inserts the record
     * @param parameters (Map<String, object>): Fields to set on the object
     * @param doInsert (boolean): If TRUE, performs Database.insert
     * @return Group: Created sObject
     */
    public static Group groupBuild(Map<String, object> parameters, boolean doInsert){
        if (parameters==null){
            parameters = new Map<String, object>();
        }
        if (!parameters.containsKey('Name')) {parameters.put('Name', randomString(10));}
        if (!parameters.containsKey('Type')) {parameters.put('Type', 'Regular');}
        Group result = (Group)JSON.deserialize(JSON.serialize(parameters), Type.forName('Group'));
        if (doInsert){
            Database.insert(result);
        }
        return result;
    }

    /**
     * Builds an sObject using the parameters provided (or defaults); Optionally inserts the record
     * @param parameters (Map<String, object>): Fields to set on the object
     * @param doInsert (boolean): If TRUE, performs Database.insert
     * @return GroupMember: Created sObject
     */
    public static GroupMember groupMemberBuild(Map<String, object> parameters, boolean doInsert){
        if (parameters==null){
            parameters = new Map<String, object>();
        }
        if (!parameters.containsKey('UserOrGroupId')) {parameters.put('UserOrGroupId', UserInfo.getUserId());}
        if (!parameters.containsKey('GroupId')) {parameters.put('GroupId', groupBuild(null, true).Id);}
        GroupMember result = (GroupMember)JSON.deserialize(JSON.serialize(parameters), Type.forName('GroupMember'));
        if (doInsert){
            Database.insert(result);
        }
        return result;
    }
}
