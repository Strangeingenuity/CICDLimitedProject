/**=====================================================================
 * Appirio, Inc
 * Name: AccountTrigger
 * Description: Trigger on Account
 Before Insert : If the Parent Account field is populated, retrieve the parent accounts Ultimate_Parent_Account__c value
                                If null, populate the Account that's being created Ultimate_Parent_Account__c field, with the parent Account Id                             
                                otherwise populate with the value in the parents Account Ultimate_Parent_Account__c field
                                
Before Update : If the value in Parent Account has changed, proceed, otherwise ignore the Account
                                List accountsToCheck = Take the value in the field Ultimate_Parent_Account__c and retrieve any other Accounts with the same value populated
                                Id NewUltimateParent = Get the new Parent Accounts value in the field Ultimate_Parent_Account__c
                                    if blank use the Parent Accounts Id instead
                                Populate the value in the updated Accounts Ultimate_Parent_Account__c with NewUltimateParent
                                Create a new Set of Ids called "changingNodes"
                                    Add the updated Account into this set
                                Create a boolean called "iterateAgain" set to true
                                while iterateAgain = true
                                    set iterateAgain = false
                                    Iterate through accountsToCheck
                                        if account parentId is in the set changingNodes
                                            update it's Ultimate_Parent_Account__c to NewUltimateParent value
                                            put the accounts Id into changingNodes set
                                            iterateAgain = true
                                Update any Accounts that have been changed by this process
                                
Before Delete : Retrieve any other accounts where the ParentId = the account being deleted
                                If there are "child" accounts then stop the delete operation happening with the following message (from custom label"): Please re-parent child Accounts before deleting this Account

 * Created Date: Nov 13th, 2013
 * Created By: Pankaj Mehra (Appirio)
 * 
 * Date Modified        Modified By                  Description of the update
 * Jan 30th, 2014       Naresh Kr Ojha(Appirio)      T-232755: Homogenize triggers
 * Jan 30th, 2014       Jinesh Goyal(Appirio)        T-232760: Homogenize the comments
 * Mar 04th, 2014       Arpita Bose (Appirio)        T-243282: Added Constants in place of String
 * Jan 26th, 2015       James Weatherall             Case #29746: Added afterDelete mathod  
 * Mar 9th, 2015        Paul Kissick                 Case #583339: Moved the isAfter AND isDelete to outside of the 'IsDataAdmin' check
 * Nov 5th, 2015        Paul Kissick                 Case #01228336: Adding beforeInsertIsDataAdmin and beforeUpdateIsDataAdmin methods
 * Mar 9th, 2017        James Wills                  DRM:W-006453 : Added sections for afterInsert and afterUpdate so that AccountStaging records are generated for isDataAdmin=true users
 * Nov. 16th, 2017      James Wills                  Case 14031099: Stopped creation of Action Code 1 Account Staging records.
 * Sep. 20th, 2018      Richard Joseph               Case 17300951: Re-enable DRM action code 1's
=====================================================================*/

trigger AccountTrigger on Account ( before insert, before update, before delete, 
                                    after insert,  after update, after delete ) {
       
    if (IsDataAdmin__c.getInstance().IsDataAdmin__c == false) {
      //Before insert
      if (Trigger.isBefore && Trigger.isInsert) {
        AccountTriggerHandler.beforeInsert(Trigger.new);
      }
      //Before update
      if (Trigger.isBefore && Trigger.isUpdate) {
        AccountTriggerHandler.beforeUpdate(Trigger.New, Trigger.oldMap);
      }
      //After insert
      if (Trigger.isAfter && Trigger.isInsert) {
        AccountTriggerHandler.afterInsert(Trigger.new);
      }
      //After update
      if (Trigger.isAfter && Trigger.isUpdate) {
        AccountTriggerHandler.afterUpdate(Trigger.new, Trigger.oldMap);
      }
      // Before Delete
      if (Trigger.isBefore && Trigger.isDelete) {
        AccountTriggerHandler.beforeDelete(Trigger.oldMap);
      }
    }
    else {
    //RJ Added it here 
    if (TriggerState.isActive(Constants.ACCOUNT_TRIGGER)) {
      //Before insert
      if (Trigger.isBefore && Trigger.isInsert) {
        AccountTriggerHandler.beforeInsertIsDataAdmin(Trigger.new);
      }
      //Before update
      if (Trigger.isBefore && Trigger.isUpdate) {
        AccountTriggerHandler.beforeUpdateIsDataAdmin(Trigger.New, Trigger.oldMap);
      }
      
      //After insert
      if (Trigger.isAfter && Trigger.isInsert) {
        AccountTriggerHandler.afterInsertIsDataAdmin(Trigger.new);
      }//Case 14031099: Commented out. // RJ Uncommented for 17300951
      
      //After update
      if (Trigger.isAfter && Trigger.isUpdate) {
        AccountTriggerHandler.afterUpdateIsDataAdmin(Trigger.New, Trigger.oldMap);
      }
      //Before Delete
      if (Trigger.isBefore && Trigger.isDelete) {
        AccountTriggerHandler.beforeDeleteIsDataAdmin(Trigger.oldMap);
      }
      }
    }
    //After Delete - Always runs
    if (Trigger.isAfter && Trigger.isDelete) {
      AccountTriggerHandler.afterDelete(Trigger.new, Trigger.oldMap);
    }
  //}
}