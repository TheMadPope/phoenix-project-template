/**
 * @description  This is the base class to be extended by all trigger handler classes.
 *               Simply Override the methods which are required for the trigger.
 *               Ignore any events that you do not need, as if you do not override them, nothing happens (via the default virtual method).
 *               In the Trigger itself, register on EVERY step, and invoke triggerHandler.Run(), e.g.:
 *
 * trigger ExampleTrigger on Contact (before insert, after insert, before update, after udpate, before delete, after delete) {
 *    ContactTriggerHandler handler = new ContactTriggerHandler();
 *    handler.Run();
 * }
 * @author Chris Aldridge, http://chrisaldridge.com/triggers/lightweight-apex-trigger-framework/
 * @date Jan 4, 2016
 * @author Mark H. Morrison, https://github.com/MarkHMorrison/Lightweight-Trigger-Framework
 * @date Sat Dec 29, 2018
 * @author Richard E. Moore - changed from Interface to base(virtual) class, https://github.com/TheMadPope/Lighter-Weight-Trigger-Framework.git
 * @date Sat Nov 7, 2019
 */
public virtual class TriggerHandler {

    /**
     * Boolean to bypass triggerHandler action. This can be set on instantiation, using a Custom Metadata record, for example.
     * If not implementing, you can get rid of this.
     */
    public Boolean IsDisabled { get; set; }

    /**
     * Default constructor, setting IsDisabled=false
     */
    public TriggerHandler() {
        IsDisabled = false;
    }

    /**
     * Constructor to allow deliberate overriding of the IsDisabled boolean, which can be set by, perhaps, a Custom Metadata record.
     * This allows the TriggerHandler action to be bypassed (during bulk loads, for example).
     * If you are not implementing a bypass, you can get rid of this constructor.
     * @param disable (boolean): If true, the Triggerhandler will not execute any actions
     */
    public TriggerHandler(boolean disable) {
        IsDisabled = disable;
    }

    /**
     * In the trigger itself, invoke a new triggerhandler extending this class, and invoke the run() method.
     * In that triggerHandler class, override any of the virtual methods below that you want to invoke
     * This method will fire the appropriate methods on the handler depending on the trigger context.
     */
    public virtual void run() {
        // Check to see if the trigger has been disabled. If it has, return.
        // NOTE: If you are not implementing a bypass, delete this check.
        if(IsDisabled) { return; }

        // Detect the current trigger context and fire the relevant methods on the trigger handler:
        switch on Trigger.operationType {
            when BEFORE_INSERT { beforeInsert(trigger.new); }
            when BEFORE_UPDATE { beforeUpdate(trigger.oldMap, trigger.newMap); }
            when BEFORE_DELETE { beforeDelete(trigger.oldMap); }
            when AFTER_INSERT { afterInsert(Trigger.newMap); }
            when AFTER_UPDATE { afterUpdate(trigger.oldMap, trigger.newMap); }
            when AFTER_DELETE { afterDelete(trigger.oldMap); }
            when AFTER_UNDELETE { afterUndelete(trigger.newMap); }
        }
    }

    /**
     * Action to take on After Delete action. Override in implementing class if action is desired
     * Implementing class can use explicit sObject type name in place of SObject
     * @param oldRecords (Map<Id, SObject>): Map of records before delete, by their Ids
     */
    public virtual void afterDelete(Map<Id, SObject> oldRecords) {
    }

    /**
     * Action to take on After Insert action. Override in implementing class if action is desired
     * Implementing class can use explicit sObject type name in place of SObject
     * @param newRecords (Map<Id, SObject>): Map of records after insert, by their Ids
     */
    public virtual void afterInsert(Map<Id, SObject> newRecords) {
    }

    /**
     * Action to take on After Update action. Override in implementing class if action is desired
     * Implementing class can use explicit sObject type name in place of SObject
     * @param oldRecords (Map<Id, SObject>): Map of records before update, by their Ids
     * @param newRecords (Map<Id, SObject>): Map of records after update, by their Ids
     */
    public virtual void afterUpdate(Map<Id, SObject> oldRecords, Map<Id, SObject> newRecords) {
    }

    /**
     * Action to take on After Undelete action. Override in implementing class if action is desired
     * Implementing class can use explicit sObject type name in place of SObject
     * @note As of 2022-10-20 this only works for SOME standard objects: https://developer.salesforce.com/docs/atlas.en-us.apexcode.meta/apexcode/apex_triggers_recovered_records.htm
     * @param newRecords (Map<Id, SObject>): Map of records after insert, by their Ids
     */
    public virtual void afterUndelete(Map<Id, SObject> newRecords) {
    }

    /**
     * Action to take on Before Delete action. Override in implementing class if action is desired
     * Implementing class can use explicit sObject type name in place of SObject
     * @param oldRecords (Map<Id, SObject>): Map of records before delete, by their Ids
     */
    public virtual void beforeDelete(Map<Id, SObject> oldRecords) {
    }

    /**
     * Action to take on Before Insert action. Override in implementing class if action is desired
     * Implementing class can use explicit sObject type name in place of SObject
     * @param newRecords (List<SObject>): Array of new records before insert
     */
    public virtual void beforeInsert(List<SObject> newRecords) {
    }

    /**
     * Action to take on Before Update action. Override in implementing class if action is desired
     * Implementing class can use explicit sObject type name in place of SObject
     * @param oldRecords (Map<Id, SObject>): Map of records before update, by their Ids
     * @param newRecords (Map<Id, SObject>): Map of records after update, by their Ids
     */
    public virtual void beforeUpdate(Map<Id, SObject> oldRecords, Map<Id, SObject> newRecords) {
    }
}