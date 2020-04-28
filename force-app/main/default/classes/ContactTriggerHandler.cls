/**=====================================================================
 * Appirio, Inc
 * Name: ContactTriggerHandler
 * Description: Add Owner to Contact Team.
 * Created Date: Dec 12th, 2013
 * Created By: Mohammed Irfan (Appirio)
 * 
 * Date Modified       Modified By                  Description of the update
 * Jan 30th, 2014      Jinesh Goyal(Appirio)        T-232760: Homogenize the comments
 * Feb 13th, 2014      Jinesh Goyal(Appirio)        T-232763: Added Exception Logging
 * Apr 08th, 2014      Arpita Bose (Appirio)        T-269372: Added addError()in try-catch block
 * May 01st, 2014      Arpita Bose                  Updated catch(Exception) to catch(DMLException) to use getDMLException Line#49
 * Aug 25th, 2014      Noopur (Appirio)             T-313856: Created Methods for befor Insert and Before Update also created two methods
 *                                                  checkContactHasContainerAccount - to check the contact,if it belongs to holding Account
 *                                                  checkContactCountForAccount - to check if holding account has crossed the number of contacts
 *                                                  as stated in the custom setting, if yes then create new account and change the accountId to the new one.
 * Sep 2nd, 2014       Nathalie Le Guay             Follow up on T-313856: Contacts need to be originally attached to the Account whose name is specified
 *                                                  on the Global_Setting__s, and this trigger will find the appropriate container to attach it to.
 * Sep 8th, 2014       Noopur (Appirio)             I-129046:  Added a check for ignoring the case in the Container Account name stored in the custom setting 
 *                                                  and the actual account name. Converting both to upper case before comparison.
 * Sep 8th, 2014       Naresh Kr Ojha               T-317847: added onDemandCOntact() to make other contact on account not to be on demand contact.
 * Sep 8th, 2014       Noopur(Appirio)              I-129046: modified the method checkContactCountForAccount to handle the situation where the contact is 
 *                                                  added to any of the accounts starting with the name stored in custom setting.
 * Sep 10th, 2014      Noopur(Appirio)              Broke the method "checkContactCountForAccount()" into sub methods. Created new methods named 
 *                                                  "getRunningAccount()" and "updateContactWithNewAccount()".
 * Oct 20, 2014        Nathalie Le Guay             I-135529: checks are made in the trigger because a WF Rule relies on the outcome. As of Winter 15 we cannot order
 *                                                  the WF Rules. Adding checkOnDemandSyncRequired()
 * Dec 12, 2014        Noopur                       T-339472 : added method orderOnDemandSync()
 * Jan 14, 2015        Sadar Yacob                  I-145611 : Fixed issue with Send to ON Demand Flag set to true for all Contacts 
 * Feb 06th, 2015      Naresh kr Ojha               T-330645: Updated code for best practice and better implementation, updated onDemandContact() method.
 * Feb 6th, 2015       Paul Kissick                 Case # 50069 : Fix for duplicate contact teams and addresses (checkMergeAndCleanup) post merge.
 * Feb 19th, 2015      Paul Kissick                 Case #29746 : Adding mergehistory creation when merges occur.
 * Apr 7th, 2015       Paul Kissick                 Case #50069 : Fixed merge failure by implementing a future method for the cleanup.
 * May 21st, 2015      Arpita Bose                  I-163339 : Updated method addOwnerToContactTeam() for Roles used in Gleam
 * Jun 29th, 2015      Arpita Bose                  Added Custom Label- Generic_message_for_system_error in catch block
 * Aug 31st, 2015      Noopur                       Added method checkCPFNumberForSerasa() for validating CPF numbers.
 * Oct 2nd, 2015       Paul Kissick                 Case #10121: Set Domain on Account if new on a contact.
 * Jan 21st, 2016      Paul Kissick                 Case #01816971: Adding limit to contact query (50000) to prevent overflows.
 * Jun 24th, 2016      Manoj Gopu                   Case #01947180 - Remove EDQ specific Contact object fields - MG COMMENTED CODE OUT
 * Feb 06nd, 2017      Manoj Gopu                   ITSM:W006544 Added a new method for Contact Merge createTransactionQueueHistory()
 * Mar 16th, 2017      Ryan (Weijie) Hu             W-007535: Associate a placeholder account for consumer contacts
 * Mar 29th, 2017      Ryan (Weijie) Hu             W-007431: Added support for consumer account record type when creating dummy acct for W-007090
 * May 12th, 2017      Richard Joseph               Added suppor for DataAdmin beforeDeleteisDataAdmin  in createTransactionQueueHistory
 * - UNCOMMENTED Feb. 7th, 2018      James Wills                  Case 15531100 :  Prevent Contact Insert Error.
 * Feb 14th, 2018      James Wills                  Case 15564878: Added section for isDataAdmin to ensure that no more than 9700 Contacts associated with Serasa Consumer Account.
 * Apr 11th, 2018      Mauricio Murillo             Case 15701563: Synchronized do not email flag for other contacts with same email address
 * Aug 07th, 2018      Mauricio Murillo             Case 15101055: Updated community user to Inactive when Contact status is set to No Longer With Company
 * Feb 12th, 2018      Herbert Oliveira             Case 18130254: Stop Contact Relationship creation when contact is created by API user (integration) 
 * Feb 13th, 2020      Ganesh Dheekonda             Work W-020399: skip the consumer contact update logic for other record types
 * Mar 10th, 2020      Tyaga pati                   Future call set up to calculate Contact DQ score at Account Level for the corresponding contact. 
 * Apr 2nd, 2020       Tyaga Pati                   case 20464812: Added a new methods for Insert and Update to be called for IsDataAdmin and Non-IsDataAdmin
 * Apr 21st  2020      Sunil Kumar                  Case #20406825: Added method updateRelationshipIds to update Contact_Relationship_Team_IDs__c if a contact merge happenes.
 =====================================================================*/

public class ContactTriggerHandler {
    
  public static boolean hasOwnerAddedToTeam = false;
    
  //Before insert call
  public static void afterInsert (List<Contact> newList) {
    addOwnerToContactTeam(newList);
    updateAccountDomain(newList, null);
    syncDoNotEmailFlag(newList, null); //15701563
  }

  //before insert call
  public static void beforeInsert (List<Contact> newList) {
    //checkOnDemandSyncRequired(newList, null);
    checkCPFNumberForSerasa(newList);
    updateConsumerContactParentAccount(newList);
  }
  
  //Case 15564878
  //before insert call
  public static void beforeInsertIsDataAdmin (List<Contact> newList) {
    checkCPFNumberForSerasa(newList);
    updateConsumerContactParentAccount(newList);
  }
  
  //before update call
  public static void beforeUpdate (List<Contact> newList, Map<Id,Contact> oldMap) {
    //onDemandContact(newList, oldMap);
    //checkOnDemandSyncRequired(newList, oldMap);
    checkCPFNumberForSerasa(newList);
  }
    
  //after update call
  public static void afterUpdate (List<Contact> newList,Map<Id,Contact> oldMap) {
    refreshOppScoreCalculations();
    //orderOnDemandSync(newList, oldMap);
    updateAccountDomain(newList, oldMap);
    syncDoNotEmailFlag(newList, oldMap); //15701563    
    inactivateCommunityUsers(newList, oldMap); //15101055
    //TP Update Summarized Contact DQ Score At Account Level. 
    calcSummaryDQScoreOnAccount(newList,oldMap);
  }
 
 //after update call To NOT allow skipping trigger as IsDataAdmin.TP Created this to have this process run even when DQ Admin is running at IsDataAdmin
  public static void runAlwaysAfterUpdate (List<Contact> newList,Map<Id,Contact> oldMap) {
    //TP Update Summarized Contact DQ Score At Account Level.
    calcSummaryDQScoreOnAccount(newList,oldMap);
  } 
  
 //after Insert call To NOT allow skipping trigger as IsDataAdmin.TP Created this to have this process run even when DQ Admin is running at IsDataAdmin
  public static void runAlwaysAfterInsert(List<Contact> newList) {
    //TP Update Summarized Contact DQ Score At Account Level.
    calcSummaryDQScoreOnAccountOnInsert(newList);
  } 
  
  
  //Before Delete Call // Added by MG
  public static void beforeDelete (Map<Id,Contact> oldMap) {   
    createTransactionQueueHistory(oldMap); //W006544
  }  
  
  //Added by RJ 
 public static void beforeDeleteisDataAdmin (Map<Id,Contact> oldMap) {   
    createTransactionQueueHistory(oldMap); //W006544
  } 
  
  // after delete call
  public static void afterDelete (Map<Id,Contact> oldMap) {
    createMergeHistory(oldMap);
    checkMergeAndCleanup(oldMap);
    updateAccountDomainFromDelete(oldMap);
  }

//TP Update Summarized Contact DQ Score At Account Level On Insert. 
  Public Static Void calcSummaryDQScoreOnAccountOnInsert(List<Contact> newList){
    Set<Id> acntIdSet = new Set<Id>();
    for (Contact con : (List<Contact>) Trigger.new) {
        acntIdSet.add(con.accountId);
       }//End Of For Loop
    
    if(acntIdSet.size()>0 && !System.isFuture() && !System.isBatch()){
        system.debug('Tyaga the accounts to be processed are ' + acntIdSet);
        calcSummScoreOnAccountfuture(acntIdSet);
     }
  
  
  }//end of Function


  //TP Update Summarized Contact DQ Score At Account Level. 
  Public Static Void calcSummaryDQScoreOnAccount(List<Contact> newList,Map<Id,Contact> oldMap){
     system.debug('tyaga here 111');
     Set<Id> acntIdSet = new Set<Id>();
     for (Contact con : (List<Contact>) Trigger.new) {
         if(((con.get('Contact_DQ_Score__c') != Trigger.oldMap.get(con.id).get('Contact_DQ_Score__c')) || (con.get('Remove_After_DataLoad__c') != Trigger.oldMap.get(con.id).get('Remove_After_DataLoad__c')))&&(con.RecordType.Name !='Consumer_Contact')&&(con.accountId !='001i000001hEJ6FAAW')&&(con.accountId!='001i000001C77C9AAJ')) 
         {
             system.debug('tyaga here 222');
             acntIdSet.add(con.accountId);
         } 
     }//End Of For Loop
     if(acntIdSet.size()>0 && !System.isFuture() && !System.isBatch()){
             system.debug('Tyaga the accounts to be processed are ' + acntIdSet);
             calcSummScoreOnAccountfuture(acntIdSet);
         }
      
  }


  //Method to add Owner to Contact Team.
  public static void addOwnerToContactTeam (List<Contact> lstContact) {
    //If method has completed adding Contact to Team then skip, to avoid recursive update.
    if (hasOwnerAddedToTeam) {
      return;
    }
    List<Contact_Team__c> lstCTs = new List<Contact_Team__c>();
    // I-163339
    Set<String> userId = new Set<String>();
    Set<string> notPrimaryUserRole = new Set<String> {
      'EMEA_MS_France_Client_Services_Manager','France_Evolution','France_Level_1_Client_Services_Agent',
      'France_Level_2_Client_Services_Agent','France_Onboarding','EMEA_MS_Germany_Client_Services_Manager',
      'Germany_Evolution','Germany_Level_1_Client_Services_Agent','Germany_Level_2_Client_Services_Agent',
      'Germany_Onboarding','EMEA_MS_Spain_Client_Services_Manager','Spain_Evolution',
      'Spain_Level_1_Client_Services_Agents','Spain_Level_2_Client_Services_Agents','Spain_Onboarding'
    };
    Set<String> profilesToSkipSet = new Set<String>{'API Only'};
    String currentUserProfile = [SELECT Name FROM Profile WHERE Id =: UserInfo.getProfileId()].Name;
    Map<Id,Set<Id>> accountTeamMemberMap = new Map<Id,Set<Id>>();
    Set<Id> accountIDsSet = new Set<Id>();
    Set<Id> currentRoleIds = new Set<Id>();
    
    if (profilesToSkipSet.contains(currentUserProfile)) {
          return;
    }
      
    for (Contact c : lstContact) {
      accountIDsSet.add(c.AccountId);          
    }
      
    for (Account acc : [SELECT Id, (SELECT UserId FROM AccountTeamMembers) FROM Account WHERE Id IN :accountIDsSet]) {
        accountTeamMemberMap.put(acc.Id, new Set<Id>());
        for (AccountTeamMember accTeamMember : acc.AccountTeamMembers) {
            accountTeamMemberMap.get(acc.Id).add(accTeamMember.UserId);    
        }           
    }
        
    for (UserRole userRole :[SELECT Id FROM UserRole WHERE DeveloperName IN :notPrimaryUserRole]) {
      currentRoleIds.add(userRole.Id);
    }
          
    for (User userRec : [SELECT Id, UserRoleId FROM User WHERE UserRoleId IN :currentRoleIds]) {
      userId.add(userRec.Id);
    }
                                                          
    for (Contact conRec : lstContact) {
      //If Owner is user then Add to Team
      if (conRec.OwnerId.getsObjectType() == User.sObjectType && !profilesToSkipSet.contains(currentUserProfile) && accountTeamMemberMap.get(conRec.AccountId) != null && accountTeamMemberMap.get(conRec.AccountId).contains(UserInfo.getUserId())) {
        // I-163339 : if user role is in the set of Roles notPrimaryUserRole, set Primary_User__c = false
        lstCTs.add(
          new Contact_Team__c(
            Contact__c = conRec.id, 
            Relationship_Owner__c = conRec.CreatedById, 
            Primary_User__c = (userId.contains(conRec.OwnerId) ? false : true)
          )
        );
      }
    }
    if(lstCTs.size() > 0) {
      try {
        insert lstCTs;
      }
      catch (DMLException ex) {
        ApexLogHandler.createLogAndSave('ContactTriggerHandler','addOwnerToContactTeam', ex.getStackTraceString(), ex);
        system.debug('##########ex##########'+ex);
        for (Integer i = 0; i < ex.getNumDml(); i++) {
          lstContact.get(0).addError(Label.Generic_message_for_system_error + ex.getDmlMessage(i));
        }
      }   
    }
    
    //Update flag.
    hasOwnerAddedToTeam = true;   
  }
    
  //blank update on all opp plan for score calculation
  public static void refreshOppScoreCalculations() {
    Set<Id> contactIds = new Set<Id>();
    for (Contact contact : (List<Contact>) Trigger.new) {
      if (contact.get('Title') != Trigger.oldMap.get(contact.id).get('Title') || 
          contact.get('Contact_Role__c') != Trigger.oldMap.get(contact.id).get('Contact_Role__c')) {
        contactIds.add(contact.Id);
      }
    }
    try {
      if(contactIds.size() > 0) {
        update [
          SELECT Id 
          FROM Opportunity_Plan__c 
          WHERE Id IN (
            SELECT Opportunity_Plan__c 
            FROM Opportunity_Plan_Contact__c 
            WHERE Contact__c = :contactIds 
            OR Reports_To__r.Contact__c = :contactIds
          )
        ];
      }
    }
    catch(Exception ex) {
      ApexLogHandler.createLogAndSave('ContactTriggerHandler','refreshOppScoreCalculations', ex.getStackTraceString(), ex);
    }
  }

  
  //===========================================================================
  // T-317847: Checks on account and created one contact per account as per task.
  //===========================================================================
  /*private static void onDemandContact (List<Contact> newList, Map<Id,Contact> oldMap) {
    Set<ID> accountIDs = new Set<ID>();
    Map<ID, Account> accountMap = new Map<ID, Account>();
    Map<ID, List<Contact>> accID_ContactListMap = new Map<ID, List<Contact>>();
    List<Contact> contactsNotToBeOnDemand = new List<Contact>();
    //As per T-330645

    for (Contact newContact : newList) {
      if (newContact.EDQ_On_Demand__c != oldMap.get(newContact.ID).EDQ_On_Demand__c && 
          newContact.EDQ_On_Demand__c == true && 
          newContact.AccountId != null) {
        accountIDs.add(newContact.AccountId);
      }
    }
    
    //If there is no update, return as per T-330645
    if (accountIDs.isEmpty()) {
      return;
    }
    
    for (Contact c : [SELECT Id, EDQ_On_Demand__c, AccountId 
                      FROM Contact 
                      WHERE EDQ_On_Demand__c = true
                      AND ID != :newList
                      AND AccountID IN :accountIDs]) {
      if (!accID_ContactListMap.containsKey(c.AccountID)) {
        accID_ContactListMap.put(c.AccountID, new List<Contact>());
      }
      accID_ContactListMap.get(c.AccountID).add(c);
    }

    try {
      //Checking weather there is any on demand contact on account if any then current one
      //wont be no more on demand.
      for (Contact newContact : newList) {
        if (newContact.EDQ_On_Demand__c == true && 
            accID_ContactListMap.containsKey(newContact.AccountID) && 
            accID_ContactListMap.get(newContact.AccountID).size() > 0) {
          //Setting on demand to false
          for (Contact c : accID_ContactListMap.get(newContact.AccountID)) {
            //As per T-330645
            if (c.EDQ_On_Demand__c == true) { 
              c.EDQ_On_Demand__c = false;
              contactsNotToBeOnDemand.add(c);
            }
          }
        }
      }
      //Updating other contacts for Not to be on demand anymore.
      if (contactsNotToBeOnDemand.size() > 0) {
        update contactsNotToBeOnDemand;
      }
    } 
    catch (DMLException ex) {
      ApexLogHandler.createLogAndSave('ContactTriggerHandler','onDemandContact', ex.getStackTraceString(), ex);
      for (Integer i=0; i < ex.getNumDml(); i++) {
        newList.get(0).addError(Label.Generic_message_for_system_error + ex.getDMLMessage(i)); 
      }
    }
  }*/
  
  //===================================================================================
  // I-135529: Checks for any update of field needing to trigger a sync with On Demand
  //===================================================================================
  /*private static void checkOnDemandSyncRequired (List<Contact> contacts, Map<Id, Contact> oldMap) {
    for (Contact cont : contacts) {
      if (oldMap == null && cont.EDQ_On_Demand__c == true) {
        cont.EDQ_Send_to_On_Demand__c = true;
      }
      else {
        if (oldMap != null && 
            cont.EDQ_On_Demand__c &&(
              cont.FirstName != oldMap.get(cont.Id).FirstName ||
              cont.LastName != oldMap.get(cont.Id).LastName ||
              cont.Email != oldMap.get(cont.Id).Email ||
              cont.MobilePhone != oldMap.get(cont.Id).MobilePhone ||
              cont.Phone != oldMap.get(cont.Id).Phone ||
              cont.Title != oldMap.get(cont.Id).Title ||
              cont.Salutation != oldMap.get(cont.Id).Salutation ||
              cont.EDQ_On_Demand__c != oldMap.get(cont.Id).EDQ_On_Demand__c)) {
          cont.EDQ_Send_to_On_Demand__c = true;
        }
      }
    }
  }*/
  
  //============================================================================
  //Method to populate the Order's EDQ_Send_to_On_Demand__c when contacts same field is changed.
  //============================================================================
  /*private static void orderOnDemandSync (List<Contact> contacts, Map<Id, Contact> oldMap) {
    try {
      Set<String> contactIds = new Set<String>();
      List<Order__c> orderToBeUpdated = new List<Order__c>();
      for (Contact cont: contacts) {
        if (cont.EDQ_Send_to_On_Demand__c == false && oldMap.get(cont.Id).EDQ_Send_to_On_Demand__c != false) {
          contactIds.add(cont.Id);
        }
      }
      for (Order__c ordObj : [SELECT Id, EDQ_Send_to_On_Demand__c, Contact__c
                              FROM Order__c
                              WHERE Contact__c IN :contactIds 
                              AND Number_of_On_Demand_Order_Line_Items__c > 0]) {
        ordObj.EDQ_Send_to_On_Demand__c = true;
        orderToBeUpdated.add(ordObj);
      }
      if (!orderToBeUpdated.isEmpty()) {
        update orderToBeUpdated;
      }
    }
    catch (DMLException ex) {
      ApexLogHandler.createLogAndSave('ContactTriggerHandler','orderOnDemandSync', ex.getStackTraceString(), ex);
      for (Integer i=0; i < ex.getNumDml(); i++) {
        contacts.get(0).addError(Label.Generic_message_for_system_error + ex.getDMLMessage(i)); 
      }
    }
  }*/

  //===========================================================================
  // Case #29746: Merge History
  //===========================================================================
  private static void createMergeHistory(Map<Id, Contact> oldMap) {
    Map<Id,Id> loserToWinnerIds = new Map<Id,Id>();
    Set<Id> winningIds = new Set<Id>();
    for(Contact deletedContact : oldMap.values()) {
      if (deletedContact.MasterRecordId != null) {
        // master is winning record.
        loserToWinnerIds.put(deletedContact.Id,deletedContact.MasterRecordId);
        // Set to hold which accounts won in the merge (normally only 1 record here, as merges don't get bulked.)
        winningIds.add(deletedContact.MasterRecordId);
      }
    }
    if (loserToWinnerIds.size() > 0) {
      // From these we need to get the CSDA_Integration_Id__c and EDQ_Integration_Id__c from both winner and loser (loser will be in the trigger, winner won't)
      List<MergeHistory__c> newHistory = new List<MergeHistory__c>();
      try {
        Map<Id,Contact> winners = new Map<Id,Contact>([
          SELECT EDQ_Integration_Id__c, 
            // CSDA_Integration_Id__c, //PK: Not on Contact object yet. 
            Global_Unique_ID__c,
            //Saas__c,
            Experian_ID__c            
          FROM Contact 
          WHERE Id IN :winningIds
        ]);
        for (Id loserId : loserToWinnerIds.keySet()) {
          Contact loserAcc = oldMap.get(loserId);
          Contact winnerAcc = winners.get(loserToWinnerIds.get(loserId));
          // Calls new utility class to build the MergeHistory
          MergeHistory__c mh = MergeHistoryUtility.createMergeHistoryRecord(loserAcc,winnerAcc);
          newHistory.add(mh);
        }
        insert newHistory;
        updateRelationshipIds(winningIds);
      } 
      catch(DMLException e){
        system.debug('\n[ContactTriggerHandler: createMergeHistory]: ['+e.getMessage()+']]');
        apexLogHandler.createLogAndSave('ContactTriggerHandler','createMergeHistory', e.getStackTraceString(), e);
      }
    }
  }

  // Case #50069
  private static void checkMergeAndCleanup(Map<Id, Contact> oldMap) {
    Set<Id> winningContacts = new Set<Id>();
    for (Contact oldCont : oldMap.values()) {
      if (oldCont.MasterRecordId != null) {
        // we have a merged record, so we must now tidy up the related list records (Contact_Team__c and Contact_Address__c of the winning record...)
        winningContacts.add(oldCont.MasterRecordId);
      }
    }
    if (!winningContacts.isEmpty()) {
      // Due to a SELF_REFERENCE_FROM_TRIGGER DML exception, the update of the winning records must be in a future method.
      ContactTriggerHandler.fixContactRelatedPostMerge(winningContacts);
    }
  }

  // Fix for rollup fields preventing the merge.
  // 2015-04-07 Added as future method. 
  @future
  public static void fixContactRelatedPostMerge (Set<Id> winningContacts) {
    List<Contact> fixContacts = [
      SELECT Id, 
       (SELECT Id, Relationship_Owner__c, Contact_Team_Role__c, Contact__c, Communication_Notes__c, Primary_User__c 
        FROM Contact_Teams__r 
        WHERE Relationship_Owner__c != null 
        ORDER BY LastModifiedDate DESC),
       (SELECT Id, Contact__c, Address__c, Address_Type__c 
        FROM Contact_Addresses__r 
        ORDER BY LastModifiedDate DESC)
      FROM Contact
      WHERE Id IN :winningContacts
    ];
    List<Contact_Team__c> toDeleteTeam = new List<Contact_Team__c>();
    List<Contact_Address__c> toDeleteAddress = new List<Contact_Address__c>();
    for (Contact c : fixContacts) {
      // run through each member and verify uniqueness...
      List<Contact_Team__c> contactTeamMembers = c.Contact_Teams__r;
      List<Contact_Address__c> contactAddresses = c.Contact_Addresses__r;
      Set<Id> extraUserIds = new Set<Id>();
      Id primaryRelationshipId;
      if (contactTeamMembers != null) {
        // Remove the extra relationships, keeping only unique ones. This doesn't check for other data in the  Communication_Notes__c field, or Contact_Team_Role__c field.
        for (Contact_Team__c ctm : contactTeamMembers) {
          // system.debug('Contact : ' + ctm.Contact__c + ' & Team Member : ' + ctm.Relationship_Owner__c);
          // Check to see if the primary user is true, and the relationship hasn't been set already
          if (ctm.Primary_User__c == true && primaryRelationshipId == null) {
            primaryRelationshipId = ctm.Id;
          }
          // Add to the extra users set (unique) if not already there, and if not, prepare to add for deletion.
          if (!extraUserIds.contains(ctm.Relationship_Owner__c)) {
            extraUserIds.add(ctm.Relationship_Owner__c);
          }
          else {
            // does contain the user, so add for deletion, unless it's the primary relationship!
            if (ctm.Id != primaryRelationshipId) {
              toDeleteTeam.add(ctm);
            }
          }
        }
      }
      if (contactAddresses != null) {
        Set<Id> extraAddressIds = new Set<Id>();
        Id regAddressId;
        for(Contact_Address__c cadd : contactAddresses) {
          // Keep the first registered address we find
          if (cadd.Address_Type__c == Constants.ADDRESS_TYPE_REGISTERED && regAddressId == null) {
            regAddressId = cadd.Id;
          }
          // Of the others, if not already unique...
          if (!extraAddressIds.contains(cadd.Address__c)) {
            extraAddressIds.add(cadd.Address__c);
          }
          else {
            // delete them of not the registered address found above.
            if (cadd.Id != regAddressId) {
              toDeleteAddress.add(cadd);
            }
          }
        }
      }
    }
    if (!toDeleteTeam.isEmpty()) {
      delete toDeleteTeam;
    }
    if (!toDeleteAddress.isEmpty()) {
      delete toDeleteAddress;
    }
  }
 
  private static void createTransactionQueueHistory(Map<Id, Contact> oldMap) { //W006544 Added by MG
    
    try {
        Map<Id, Id> loserToWinnerIds = new Map<Id, Id>();
        string currentURL = URL.getCurrentRequestUrl().toExternalForm();
        if(Test.isRunningTest()){           
            currentURL = 'merge/conmergewizard.jsp';        
        }        
        for (Contact deletedContact : [SELECT id,RecordType.Name,MasterRecordId  FROM Contact WHERE id =: oldMap.values() AND RecordType.Name NOT IN ('Consumer_Contact')]) {
          if(currentURL.contains('merge/conmergewizard.jsp')){
            // master is winning record.
            loserToWinnerIds.put(deletedContact.Id,deletedContact.MasterRecordId);
            // Set to hold which Contacts won in the merge (normally only 1 record here, as merges don't get bulked.)
            
          }
        }
        system.debug('BeforeeeeloserToWinnerIds@@@'+loserToWinnerIds);
        if (!loserToWinnerIds.isEmpty()) {
         //Added by Manoj to create transaction queue records for case for the looser contact
        list<Transaction_Queue__c> lstTrans = new list<Transaction_Queue__c>();     
        for(Case cse:[select id,SNOW_CaseID__c from Case where ContactId =: loserToWinnerIds.keySet() AND SNOW_CaseID__c!=null AND SNOW_CaseID__c!='']){
            Transaction_Queue__c objCse = new Transaction_Queue__c();                                   
            objCse.Action_Type__c = 'Update';                
            objCse.Transaction_Object_Name__c = 'Case';
            objCse.Transaction_Status__c = 'New';
            objCse.SF_Record_ID__c = cse.Id;
            objCse.Target_Application__c = 'ServiceNow';
            objCse.Operation_Type__c = 'CaseUpdate';
            objCse.Transaction_Type__c = 'Outbound';
            lstTrans.add(objCse);           
        }
        /*for(Asset ast:[select id,SNOW_AssetID__c from Asset where ContactId =: loserToWinnerIds.keySet() AND SNOW_AssetID__c!=null AND SNOW_AssetID__c!='']){
                Transaction_Queue__c objAss = new Transaction_Queue__c();                                   
                objAss.Action_Type__c = 'Update';                
                objAss.Transaction_Object_Name__c = 'Asset';
                objAss.Transaction_Status__c = 'New';
                objAss.SF_Record_ID__c = ast.Id;
                objAss.Target_Application__c = 'ServiceNow';
                objAss.Operation_Type__c = 'AssetUpdate';
                objAss.Transaction_Type__c = 'Outbound';
                lstTrans.add(objAss);           
        }*/
        if(!lstTrans.isEmpty())
            Database.insert(lstTrans);
      } 
     }
      catch(DMLException e){
        system.debug('\n[ContactTriggerHandler: createMergeHistory]: ['+e.getMessage()+']]');
        apexLogHandler.createLogAndSave('ContactTriggerHandler','createMergeHistory', e.getStackTraceString(), e);
      }
     }
  //===============================================================================
  // Case 10121: Domain Field on Accounts
  // TODO: We may need to modify this to account for catchall accounts
  //===============================================================================
  public static void updateAccountDomain(List<Contact> newConts, Map<Id,Contact> oldConts) {
    Set<Id> accountsToUpdate = new Set<Id>();
    for (Contact c : newConts) {
      // check if there is a change if oldConts != null
      if (c.AccountId != null) {
          if (oldConts != null) {
            if (c.Email != oldConts.get(c.Id).Email) {
              // email has changed..
              accountsToUpdate.add(c.AccountId);
            }
          }
          else {
            if (String.isNotBlank(c.Email)) {
              // always update
            accountsToUpdate.add(c.AccountId);
            }
          }
      }
    }
    // if calling an update from a batch or future, do the update now, otherwise future it
    if (System.isFuture() || System.isBatch()) {
      updateDomainOnAccount(accountsToUpdate);
    }
    else {
      updateDomainOnAccountFuture(accountsToUpdate);
    }
  }
  
  public static void updateAccountDomainFromDelete (Map<Id,Contact> oldConts) {
    Set<Id> accountsToUpdate = new Set<Id>();
    for (Contact c : oldConts.values()) {
      // check if there is a change if oldConts != null
      if (c.AccountId != null && String.isNotBlank(c.Email)) {
        // always update
        accountsToUpdate.add(c.AccountId);
      }
    }
    // if calling an update from a batch or future, do the update now, otherwise future it
    if (System.isFuture() || System.isBatch()) {
      updateDomainOnAccount(accountsToUpdate);
    }
    else {
      updateDomainOnAccountFuture(accountsToUpdate);
    }
  }
  
  //===============================================================================
  // Case 10121: Domain Field on Accounts
  //===============================================================================
  @future
  public static void updateDomainOnAccountFuture (Set<Id> accountIdSet) {
    updateDomainOnAccount(accountIdSet);
  }
  
  //===============================================================================
  // Case 10121: Domain Field on Accounts
  // For each contact that's been updated, find all the contacts at their accounts, and build a new domain string
  // 
  //===============================================================================
  public static void updateDomainOnAccount (Set<Id> accountIdSet) {
    
    Integer domainFieldLen = Account.Domain__c.getDescribe().getLength(); // Find the length of the domain field, could be increased.
    
    Integer queryRowsLimit = Limits.getLimitQueryRows();
    
    Integer rows90percent = Integer.valueOf(queryRowsLimit * 0.90);
    
    List<Contact> conts = [
      SELECT Email, Account.Domain__c, AccountId 
      FROM Contact 
      WHERE AccountId IN :accountIdSet 
      AND Email != null
      LIMIT :rows90percent         // Case 01816971
    ];
    
    Map<Id,Set<String>> accountIdToDomainSet = new Map<Id,Set<String>>();
    Map<Id,String> accountIdToDomainString = new Map<Id,String>();
    Map<Id,String> accountIdToNewDomainString = new Map<Id,String>();
    
    for(Contact c : conts) {
      String emailDomain = c.Email.substringAfterLast('@').toLowerCase(); // Always set to lowercase, eases matching
      
      //Build new set of domains for this account...
      if (!accountIdToDomainSet.containsKey(c.AccountId)) {
        accountIdToDomainSet.put(c.AccountId,new Set<String>());
      }
      // Add the current domain into the set
      accountIdToDomainSet.get(c.AccountId).add(emailDomain);
      
      // Also hold the current domain field for reference later
      if (!accountIdToDomainString.containsKey(c.AccountId)) {
        accountIdToDomainString.put(c.AccountId,c.Account.Domain__c);
      }
    }
    
    for(Id accountId : accountIdToDomainSet.keySet()) {
      //Convert this set to a list (for sorting & joining)
      List<String> domainList = new List<String>(accountIdToDomainSet.get(accountId));
      domainList.sort();
      String domains = String.join(domainList,', ');
      
      // Now compare the old domain streeing with the new one, and prepare to update if different
      if (domains != accountIdToDomainString.get(accountId)) {
        accountIdToNewDomainString.put(accountId,domains);
      }
    }
    
    if (accountIdToNewDomainString.size() > 0) {
      List<Account> accsToUpdate = new List<Account>();
      for(Id accId : accountIdToNewDomainString.keySet()) {
        Account a = new Account(
          Id = accId, 
          Domain__c = accountIdToNewDomainString.get(accId).mid(0,domainFieldLen)
        );
        accsToUpdate.add(a);
      }
      update accsToUpdate;
    }
  }
  
  // Method to validate the CPF Number 
  public static void checkCPFNumberForSerasa (List<Contact> newCons) {
    for (Contact con : newCons) {
      if ((con.CPF__c != null && con.CPF__c != '') && 
          (!con.CPF__c.isNumeric() || con.CPF__c.length()!= 11)) {
        con.addError(Label.Invalid_CPF_Number);
      }
        else if ((con.CPF__c != null && con.CPF__c != '') && 
                 !SerasaUtilities.validateCPFNumber(con.CPF__c)) {
          con.addError(Label.Invalid_CPF_Checksum_Error_Message);
        }
    }
  }
//===============================================================================
  // User Story: W-007535
  // For each consumer contact, associate a placeholder account for it. No more than 10K
  // consumer contacts should be linked with one account. Create a new one and mark it as
  // active at a reasonable range (greater than or equals to 9700).
  // 
  //===============================================================================
  public static void updateConsumerContactParentAccount (List<Contact> newCons) {

    RecordType consumer_contact_rt = [SELECT Description,DeveloperName,Id,Name,SobjectType FROM RecordType WHERE SobjectType = 'Contact' AND DeveloperName = 'Consumer_Contact'];
    RecordType consumer_account_rt = [SELECT Description,DeveloperName,Id,Name,SobjectType FROM RecordType WHERE SobjectType = 'Account' AND DeveloperName = 'Consumer_Account'];

    // Pre-validate how many new consumer contact will be adding
    Integer countOfNewContacts = 0;
    Account serasaActiveAcct;
    
    // Count how many contacts are consumer contacts.
    for (Contact c : newCons) {
      if (c.RecordTypeId == consumer_contact_rt.Id) {
        countOfNewContacts++;
      }
    }
    //Added by Ganesh to skip the logic for other record types -- W-020399
    if(countOfNewContacts == 0)
        return ;

    if (newCons != null && newCons.size() > 0) {

      List<Serasa_Consumer_Contact_Active_Account__c> serasaActiveAcctCustomSettingList = [SELECT Active_Account_Id__c FROM Serasa_Consumer_Contact_Active_Account__c LIMIT 1];

      if (serasaActiveAcctCustomSettingList == null || serasaActiveAcctCustomSettingList.size() == 0) {// Case 15531100 - I am not sure if this code is ever reached.
        serasaActiveAcct = new Account (
          Serasa_Consumer_Active_Account__c = true,
          Name = 'Serasa Consumer Account',
          Serasa_Consumer_Contact_Count__c = countOfNewContacts,
          RecordTypeId = consumer_account_rt.Id
        );
        insert serasaActiveAcct;

        Serasa_Consumer_Contact_Active_Account__c newRecordOnSetting = new Serasa_Consumer_Contact_Active_Account__c();
        newRecordOnSetting.Active_Account_Id__c = serasaActiveAcct.Id;
        insert newRecordOnSetting;
      }
      else {
        String activeSerasaAcctIdStr = serasaActiveAcctCustomSettingList.get(0).Active_Account_Id__c;

        List<Account> serasaActiveAcctList = [SELECT Id, Serasa_Consumer_Contact_Count__c, Serasa_Consumer_Active_Account__c FROM Account WHERE Id =: activeSerasaAcctIdStr];
        
        if (serasaActiveAcctList == null || serasaActiveAcctList.size() == 0) {// Case 15531100 - I am not sure if this code is ever reached.
          serasaActiveAcct = new Account (
            Serasa_Consumer_Active_Account__c = true,
            Name = 'Serasa Consumer Account',
            Serasa_Consumer_Contact_Count__c = countOfNewContacts,
            RecordTypeId = consumer_account_rt.Id
          );
          insert serasaActiveAcct;

          Serasa_Consumer_Contact_Active_Account__c newRecordOnSetting = serasaActiveAcctCustomSettingList.get(0);
          newRecordOnSetting.Active_Account_Id__c = serasaActiveAcct.Id;
          update newRecordOnSetting;
        }
        else {
          serasaActiveAcct = serasaActiveAcctList.get(0);
          if (serasaActiveAcct.Serasa_Consumer_Contact_Count__c == null) {
            serasaActiveAcct.Serasa_Consumer_Contact_Count__c = 0;
          }
          
          // Case 15531100 - This code commented out when duplicate rule was preventing the addition of Contacts.
          // The active Serasa Consumer Account had 11,000+ Contacts associated with it anyway by the time that the Serasa_Consumer_Contact_Count__c reached 9700.
          // The active Serasa Consumer Account can also be set up from a VF Page Controller and there was more than one Account has Serasa_Consumer_Active_Account__c 
          //  set to true at the time of the investigation.
          if (serasaActiveAcct.Serasa_Consumer_Contact_Count__c >= 9700 || (serasaActiveAcct.Serasa_Consumer_Contact_Count__c + countOfNewContacts > 10000)) {
            serasaActiveAcct.Serasa_Consumer_Active_Account__c = false;
            update serasaActiveAcct;

            serasaActiveAcct = new Account (
              Serasa_Consumer_Active_Account__c = true,
              Name = 'Serasa Consumer Account',
              Serasa_Consumer_Contact_Count__c = countOfNewContacts,
              RecordTypeId = consumer_account_rt.Id
            );
            insert serasaActiveAcct;

            Serasa_Consumer_Contact_Active_Account__c newRecordOnSetting = serasaActiveAcctCustomSettingList.get(0);
            newRecordOnSetting.Active_Account_Id__c = serasaActiveAcct.Id;
            update newRecordOnSetting;
          }// Case 15531100 - Previously commented out.
          else {
            serasaActiveAcct.Serasa_Consumer_Contact_Count__c += countOfNewContacts;
            update serasaActiveAcct;
          }
        }
      }

      for (Contact c : newCons) {
        if (c.RecordTypeId == consumer_contact_rt.Id) {
          c.AccountId = serasaActiveAcct.Id;
        }
      }
    }
  }
  
  //===============================================================================
  // Case 15701563: syncDoNotEmailFlag
  // Sets do not mail flag for contacts with same email address
  //===============================================================================
  public static boolean doNotEmailRun = false; //Used to stop recursive calls
  
  public static void syncDoNotEmailFlag(List<Contact> newContacts, Map<Id,Contact> oldContacts) {
      
      // Query the project for the parent's fields
      Set<ID> contactIDs = new Set<ID>();
      Set<String> contactEmails = new Set<String>();
      Map<String, Boolean> emailMap = new Map<String, Boolean>();
      List<Contact> contactsToUpdate = new List<Contact>();
      
      for (Contact contactRecord: newContacts)
      { 
          // If insert, or if it's update and the do not email flag has changed
          if ( (oldContacts != null && (contactRecord.HasOptedOutOfEmail != oldContacts.get(contactRecord.ID).HasOptedOutOfEmail)) 
                || oldContacts == null)            
          {
            if(!emailMap.containsKey(contactRecord.email) && (contactRecord.email != null)){
              emailMap.put(contactRecord.email, contactRecord.HasOptedOutOfEmail);  
              contactEmails.add(contactRecord.email);
            }                    
          }
      }
      
      if (contactEmails.isEmpty() || doNotEmailRun)
      {
          return;
      }
      else{
        ContactTriggerHandler.doNotEmailRun = true;
        for(Contact contactRecord : [Select id, email, HasOptedOutOfEmail from Contact where email in :emailMap.keySet()]){
           //flag is different so needs to be updated
           if (contactRecord.HasOptedOutOfEmail != emailMap.get(contactRecord.email)){
              contactRecord.HasOptedOutOfEmail = !contactRecord.HasOptedOutOfEmail;
              contactsToUpdate.add(contactRecord);
           }
        }
      }
      
      if (contactsToUpdate.size() > 0){
        Database.SaveResult[] srList = Database.update(contactsToUpdate, false);
        
        // Iterate through each returned result
        for (Database.SaveResult sr : srList) {
            if (!sr.isSuccess()) {
                // Operation failed, so get all errors                
                for(Database.Error err : sr.getErrors()) {
                    System.debug('ContactTriggerHandler syncDoNotEmailFlag error. ' + err.getStatusCode() + ': ' + err.getMessage());
                }
            }
        }
      }
  }   
  
  //===============================================================================
  // Case 15101055: inactivateCommunityUsers
  // Set user status to Inactive when Contact status is set to No Longer With Company
  //===============================================================================
  public static boolean doNotInactivateCommunityUsers = false; //Used to stop recursive calls
  
  public static void inactivateCommunityUsers(List<Contact> newContacts, Map<Id,Contact> oldContacts) {
      
      if(doNotInactivateCommunityUsers){
          return;
      }
      else{
          doNotInactivateCommunityUsers = true;
      }
      
      Set<ID> contactIds = new Set<ID>();
      List<User> usersToUpdate = new List<User>();
      
      for (Contact contactRecord: newContacts)
      {   
         if(contactRecord.status__c != oldContacts.get(contactRecord.ID).status__c && contactRecord.status__c == Constants.CONTACT_STATUS_LEFT){
            contactIds.add(contactRecord.ID);
         }
      }
      
      if(contactIds.size() > 0 && !System.isFuture()){ 
          inactivateCommunityUsersHelper(contactIds);
          
      }
  }  
  
  //===============================================================================
  // Case 15101055: inactivateCommunityUsersHelper
  // Set user status to Inactive when Contact status is set to No Longer With Company.  Future method to avoid mixed DML 
  //===============================================================================
  @future
  public static void inactivateCommunityUsersHelper(Set<ID> contactIds) {
      
      List<User> usersToUpdate = new List<User>();
      
      usersToUpdate = [Select Id, isactive from User where contactId in: contactIds and IsPortalEnabled = true and isActive = true];          
      
      for (User userRecord: usersToUpdate){
          userRecord.isActive = false;
      }
      
      if(usersToUpdate.size() > 0){  
          UserTriggerHandler.isAfterUpdateTriggerExecuted = true; //bypass user trigger since action is coming from Community Contact    
          update usersToUpdate;
      }
  }
  
  //===============================================================================
  // TP: Summarized Contact DQ Score at Account Level
  // Takes the input at the Account Id of the contact in context, Queries the DQ score on all the associated contacts and averages it. 
  //===============================================================================
  @future
  public static void calcSummScoreOnAccountfuture(Set<Id> AcntIdSet) {
      system.debug('tyaga here 333');
      List<Account> updateAcntList = New List<Account>();
      Map<Id,Decimal> eachAccountScoreMap = new Map<Id,Decimal>();
      system.debug('The account list is' + AcntIdSet);
      if(!AcntIdSet.isEmpty()){
          for(AggregateResult groupedDQResults : [select AccountId, AVG(Contact_DQ_Score__c)summDQScore from Contact where AccountId IN :AcntIdSet group by AccountId]){
              eachAccountScoreMap.put(((String)groupedDQResults.get('AccountId')),((Decimal)groupedDQResults.get('summDQScore')));
              system.debug('tyaga the object is' + eachAccountScoreMap);
              }
        }
      for(Account acnt : [SELECT Summarized_Contact_DQ_Score__c from Account where Id IN: AcntIdSet]){
           acnt.Summarized_Contact_DQ_Score__c = eachAccountScoreMap.get(acnt.id);  
           system.debug('tyaga the score is' + eachAccountScoreMap.get(acnt.id)) ;
           updateAcntList.add(acnt);  
      }

      if(!updateAcntList.isEmpty()){
      system.debug('Tyaga the account list is' + updateAcntList);
          update updateAcntList;
      }
      

  }
    //Case #20406825:-Mthod created by Sunil to update Contact_Relationship_Team_IDs__c if a contact merge happenes.
    @future
    public static void updateRelationshipIds(Set<Id> conidSet){
        string contString;
        list<contact> contactToUpdate = new list<contact>(); 
        list<contact> conlist = [select id,Contact_Relationship_Team_IDs__c,Total_Contact_Relationship_Count__c,Active_Contact_Relationship_Count__c,(select id,Relationship_Owner__c,Relationship_Owner__r.User_Hex_ID__c,Relationship_Owner__r.isActive from Contact_Teams__r) from contact where id in: conidSet];
        if(!conlist.isEmpty()){
			Integer activeContactTeamCounter = 0;
            for(contact conObj : conlist){
                contString = '';
				conObj.Total_Contact_Relationship_Count__c = conObj.Contact_Teams__r.size();
				if(conObj.Contact_Teams__r.size()>0){
					for(Contact_Team__c contmObj : conObj.Contact_Teams__r){
						if (!contString.contains(contmObj.Relationship_Owner__r.User_Hex_ID__c)) {							
							contString = (contString + ';' + contmObj.Relationship_Owner__r.User_Hex_ID__c).replace(';;',';');
							contString = contString.removeStart(';');
							if(contmObj.Relationship_Owner__r.isActive) {
								activeContactTeamCounter++;
							}
						}						
					}
				}
				conObj.Active_Contact_Relationship_Count__c = activeContactTeamCounter;
				activeContactTeamCounter = 0;
                conObj.Contact_Relationship_Team_IDs__c =contString;
                contactToUpdate.add(conObj);
            }   
      
        }
        if(!contactToUpdate.isEmpty()){
              update contactToUpdate;
         }
    } 
  
}//END: Class