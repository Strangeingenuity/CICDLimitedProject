/**=====================================================================
 * Appirio, Inc
 * Name: AccountTriggerHandler
 * Description: T-194935
 * Created Date: Oct 31st, 2013,On insert of an account if billing address is not blank
                then create address record and associate that address with
                the account by creating the AccountAddress record.
 * Created By: Manish Soni ( Appirio )
 *
 * Date Modified                Modified By                  Description of the update
 * Jan 30th, 2014               Jinesh Goyal(Appirio)        T-232760: Homogenize the comments
 * Feb 13th, 2014               Jinesh Goyal(Appirio)        T-232763: Added Exception Logging
 * Mar 03rd, 2014               Arpita Bose(Appirio)         T-243282: Added Constants in place of String
 * Mar 10th, 2014               Naresh kr Ojha (Appirio)     T-257200: Creating account team on insert and update as parent account
 * Mar 11th, 2014               Naresh kr Ojha (Appirio)     T-257200: Not to remove users from child account who are not on parent
 * Mar 28th, 2014               Sadar Yacob                  Contact Sharing setting is set as 'Controlled by Parent', commenting ContactAccessLevel
 * Apr 07th, 2014               Arpita Bose                  T-269372: Added addError() in try-catch block
 * May 01st, 2014               Naresh kr Ojha (Appirio)     Updated catch(Exception) to catch(DMLException) to use getDMLMessage Line # 430
 * May 15th, 2014               Nathalie Le Guay             getUserMap() - Get user isActive flag prior to creating an ATM record for them
 * Aug 13th, 2014               James Weatherall             setVBMCode() - Sets the field VBM_Code__c. Required for Aria migration.
 * Aug 22nd, 2014               Sadar Yacob                  Merge Zipcode/PostCode field - use PostCode__c from now on
 * Oct 06th, 2014               Naresh Kr Ojha               T-323669: update send to on demand field on contacts with account name changed
 *                                                           Added method sendToOnDemand();
 * Oct 14th, 2014               James Weatherall             Uncommented setVBMCode() method and calls from beforeInsert, beforeUpdate
 * Jan 26th, 2015               James Weatherall             Case #29764: Added afterDelete method
 * Feb 9th, 2015                Paul Kissick                 Case #542921: Added fix for missing parents (checkForOriginalParent,fixParentAccountPostMerge) post merge.
 * Feb 19th, 2015               Paul Kissick                 Case #29764: Expanded createMergeHistory() method to add an entry for Account merges into MergeHistory.
 * Mar 4th, 2015                Gaurav Kumar Chadha          T-366810 : Added method checkSaasAccntDeactivated()
 * May 18th, 2015               Paul Kissick                 Case #582156: Added fix for nulls on parentids causing query exception
 * Jun 04th, 2015               Naresh Kr Ojha               Commented method call for update case as per solution on : I-163031
 * Jun 05th, 2015               Naresh Kr Ojha               I-163031: Added future method updateAccountShare() to provide edit access on Accounts to CreatedBy User.
 * June 30th,2015               Noopur                       Added labels in place of text values. 
 * Jul 06th, 2015               Paul Kissick                 I-163031: Reverting all appirio changes and adding new code to fix this issue.
 * Oct 19th, 2015               Paul Kissick                 Fixing setVBMCode to keep code map in static variable
 * Nov 5th, 2015                Paul Kissick                 Case #01228336: Adding methods specific to isdataadmin settings 
 * Nov 19th, 2015               Tyaga Pati                   S-032: segmentRunForSingleAccount Adding Functionality to Create Segment for Single Accounts to Facilitate Automotive Vetting Process
 * Feb 16th, 2016               James Wills                  Case #00525537 Integrity Check Enhancement
 * Mar 08 2016                  Richard Joseph               Case #00005856 - addUserToAccountTeam menthos removed from after update
 * Jun 15th, 2016               Paul Kissick                 Case #02024883: Fixing AccountShare problems (v37.0)
 * Jun 27th, 2016               Manoj Gopu                   Case #01947180 - Remove EDQ specific Contact object fields - MG COMMENTED CODE OUT
 * Nov. 25th, 2016              James Wills                  DRM:W006453: Mechanism for updating Account_Staging__c Object when an Account is created or updated
 * Feb. 02nd, 2017              Manoj Gopu                   ITSM:W006543 Added a new method for Account Merge createTransactionQueueHistory()
 * May 1st, 2017                Sanket Vaidya                Case #01103464 - Added method updateAccountSegmentNames.
 * May 8th, 2017                James Wills                  Case #02396387: Added isAfterUpdateTriggerExecuted parameter and functionality.
 * May 12th 2017                Richard Joseph               Added beforeDeleteIsDataAdmin   to enable dataadmin deletes into Queue table 
 * Jun 7th, 2017                James Wills                  Case #02410797: Added filter to prevent LATAM Account inserts and updates being pushed to the Account Staging table.
 * Aug 1st, 2017                Tyaga Pati                   Case 13363768 : Query User Profile and Dont let them be added to Account Team if serasa customer care profile
 * Oct 26th, 2017               Mauricio Murillo             Case 02413263:  Added new method to update account segments names after an account is merged
 * Nov. 16th, 2017              James Wills                  Case 14031099: Stopped creation of Action Code 1 Account Staging records (merge code needs updated in subsequent case).
 * Dec. 18th, 2017              Mauricio Murillo             Case 15082239: Fixed account segment issue when merging accounts
 * Sep. 20th, 2018              Richard Joseph               Case 17300951: Re-enable DRM action code 1's
 * Mar. 18th, 2019              Malcolm Russell              Case 18651706: Ability to bypass beforeUpdateIsDataAdmin for batch.
 * Jan. 24th, 2020              Vaibhav Athikam              Added a method named updateEmpHierarchyOnDqChange to update the Employee Org Hierarchy records if the summarized Dq value changes on Account
 =====================================================================*/
public without sharing class AccountTriggerHandler {

  public static Map<Id, User> userMap = new Map<Id, User>();
  public static Map<String,String> vbmCodeMap = new Map<String,String>();  
  
  static Map<Id,Account> insertedAccounts = new Map<Id,Account>(); // I-163031 PK: Adding to fix created != owner issue

  public static Boolean isAfterUpdateTriggerExecuted = false;
  
  public static Boolean batchBypass = false; //Case 18651706
  
  //Before Insert Call
  public static void beforeInsert (List<Account> newList) {
    populateUltimateAccount(newList);
    
    setVBMCode(newList, null);    

    setAccountOrigin(newList); // W-014803
  }
  
  //After Insert Call
  public static void afterInsert (List<Account> newList) {
    loadInsertedAccounts(newList); // I-163031 PK: New method to load inserted accounts into static var
    
    //addUserToAccountTeam(newList);// Commented by RJ for case #v00005856

    // S-032 - TP Code to Create segment only for current Account
    if(newList.size()==1) {
      segmentRunForSingleAccount(newList[0]);
    }
    
    insertStagingTableEntries(newList, 1);//W006453//Case 14031099: Commented out. // RJ Uncommented for 17300951
  } 
  
  public static void segmentRunForSingleAccount(Account acc) {
    BatchAccountSegmentCreationViaATM SingleAccountSegment = new BatchAccountSegmentCreationViaATM();
    SingleAccountSegment.singleAccountId = acc.Id;
    if (!Test.isRunningTest()) {
      system.scheduleBatch(SingleAccountSegment,'BatchAccountSegmentCreationViaATM-'+acc.Id+'-'+String.valueOf(Datetime.now().getTime()),0,1);//Run For only one Record      
    }
  }

  //Before Update Call
  public static void beforeUpdate (List<Account> newList, Map<Id, Account> oldMap) {
    updateUltimateAccount (newList, oldMap);

    setVBMCode (newList, oldMap);

    checkSaasAccntDeactivated (newList, oldMap); // T-366810 GC
    
    // integrityCheckProcessing (newList, oldMap);//Case #525537 Integrity Check Enhancement James Wills
  }

  //After Update Call
  public static void afterUpdate (List<Account> newList, Map<Id, Account> oldMap) {
      
    if(!isAfterUpdateTriggerExecuted){
      isAfterUpdateTriggerExecuted = true;
  
      //MIrfan@201113, S-154585
      addUserToAccountTeam (newList); 

      setSendBillingAccountToAria (newList, oldMap);

      //sendToOnDemand (newList, oldMap);//As per T-323669.
    
      checkUpdatedAccountsForAccountStagingTable(newList,  oldMap);//W006453//Case 14031099: Commented out.
      updateAccountSegmentNames(newList, oldMap); 
        updateEmpHierarchyOnDqChange(oldMap, newList);
    }
  }

  //Before Delete Call
  public static void beforeDelete (Map<Id, Account> oldMap) {
    checkIfParentAccountIsDeleted (oldMap.values());
    createTransactionQueueHistory(oldMap); //W006543
  }

  //After Delete Call
  public static void afterDelete (List<Account> newList, Map<Id, Account> oldMap) {
    createMergeHistory(oldMap);
    updateAccountSegmentNames(oldmap); //MM: 02413263
    checkForOriginalParent(oldMap); // PK: Case #542921
    
    createDeletionEntryInStagingTable(oldMap);//DRM:W-006453
    
  }

  //Before Insert for IsDataAdmin Users
  public static void beforeInsertIsDataAdmin (List<Account> newList) {
    populateUltimateAccount(newList);
  }
  
  //Before Update for IsDataAdmin Users
  public static void beforeUpdateIsDataAdmin (List<Account> newList, Map<Id, Account> oldMap) {
    if(!batchBypass){
      updateUltimateAccount(newList, oldMap);
    }
  }
  
  //RJ Added
  //Before Delete Call IsDataAdmin Users 
  public static void beforeDeleteIsDataAdmin (Map<Id, Account> oldMap) {
    createTransactionQueueHistory(oldMap); //W006543
  } 
  
  
  //Before Insert for IsDataAdmin Users (W006453)
  public static void afterInsertIsDataAdmin(List<Account> newList){
    insertStagingTableEntries(newList, 1);//W006453   
  }//Case 14031099: Commented out. // RJ uncommented for 17300951
  
  //Before Update for IsDataAdmin Users (W006453)
  public static void afterUpdateIsDataAdmin(List<Account> newList, Map<Id, Account> oldMap){
  
    if (!isAfterUpdateTriggerExecuted) {
      isAfterUpdateTriggerExecuted = true;
  
      checkUpdatedAccountsForAccountStagingTable(newList,  oldMap);//W006453//Case 14031099: Commented out.
      updateAccountSegmentNames(newList, oldMap);
    }
  }

  // I-163031 PK: adding to fix inserted accounts....
  public static void loadInsertedAccounts(List<Account> insertedAccs) {
    insertedAccounts.putAll(insertedAccs);
  }

  //==========================================================================================
  // T-366810 : check if saas account is deactivated
  //==========================================================================================
    public static void checkSaasAccntDeactivated (List<Account> newList, Map<Id, Account> oldMap) {
    List<Account> lstDeactivatedAccounts = new List<Account>();
    for (Account acc : newList) {
      if (acc.Saas__c != null &&
          acc.Saas__c != oldMap.get(acc.Id).Saas__c &&
          acc.Saas__c == false) {
        lstDeactivatedAccounts.add(acc);
      }
    }
    if (!lstDeactivatedAccounts.isEmpty()) {
      preventDeactivationOfSaasAccount(lstDeactivatedAccounts);
    }
  }

  //==========================================================================================
  // T-366810 : prevent deactivation of saas account if there is a related active deployment
  //==========================================================================================
  public static void preventDeactivationOfSaasAccount (List<Account> lstDeactivatedAccounts) {
    Map<Id, Boolean> mapAccIdWithActiveDeployment = new Map<Id, Boolean>();
    
    for (Deployment__c deployment : [SELECT ID, Active__c, Account__c
                                     FROM  Deployment__c
                                     WHERE Account__c IN :lstDeactivatedAccounts
                                     AND Active__c = true]) {
      if (mapAccIdWithActiveDeployment.containsKey(deployment.Account__c) == false) {
        mapAccIdWithActiveDeployment.put(deployment.Account__c, true);
      }
    }

    for (Account account : lstDeactivatedAccounts) {
      if (mapAccIdWithActiveDeployment.containsKey(account.Id) &&
          mapAccIdWithActiveDeployment.get(account.Id) == true) {
        account.addError(system.label.SaaS_ERR_ACCOUNT_ACTIVE_DEPLOYMENT);
      }
    }
  }

  //populate Account's Ultimate_Parent_Account__c field when account is inserted
  public static void populateUltimateAccount(List<Account> newList) {
    Map<Id,Id> parentsUltimateAcc = new Map<Id,Id>();
    
    for (Account acc : newList) {
      if (acc.ParentId == null) {
        continue;
      }
      parentsUltimateAcc.put(acc.ParentId, null);
    }
    for(Account parent : [SELECT Ultimate_Parent_Account__c
                          FROM Account
                          WHERE Id IN : parentsUltimateAcc.keySet()]) {
      parentsUltimateAcc.put(parent.Id,parent.Ultimate_Parent_Account__c);
    }
    for (Account acc : newList) {
      if (acc.ParentId != NULL) {
        if (parentsUltimateAcc.containsKey(acc.ParentId) && parentsUltimateAcc.get(acc.ParentId) != null) {
          acc.Ultimate_Parent_Account__c = parentsUltimateAcc.get(acc.ParentId);
        } 
        else {
          acc.Ultimate_Parent_Account__c = acc.ParentId;
        }
      }
    }
  }

  //Restrict Parent account to be deleted
  public static void checkIfParentAccountIsDeleted (List<Account> newList) {

    Set<Id> parentAccounts = new Set<Id>();
    // Retrieve all childs
    for (Account acc : [SELECT Id,ParentId
                        FROM Account
                        WHERE ParentId IN :newList]) {
      parentAccounts.add(acc.ParentId);
    }
    /*
    Set<Id> ultimateAccounts = new Set<Id>();
    for(Account account : [SELECT Id
                           FROM Account
                           WHERE Ultimate_Parent_Account__c in :lstAccount]) {
      if(account.Ultimate_Parent_Account__c == NULL) {
        continue;
      }
        ultimateAccounts.add(account.Ultimate_Parent_Account__c);
    }
    */
    if (parentAccounts.isEmpty()) {
      return;
    }
    for (Account acc : newList) {
      if (parentAccounts.contains(acc.Id)) {
        acc.addError(Label.ACCOUNT_Please_re_parent_child_Accounts_before_deleting_this_Account + ' ' +acc.Name);
      }
    }
  }

  //Filter Account's where Parent is changed
  public static void updateUltimateAccount(List<Account> newList, Map<Id, Account> oldMap) {

    List<Account> lstAccountToUpdate = new List<Account>();
    Map<Id, Account> mapUltimateAccountNowChild = new Map<Id, Account>();
    Map<Id, Id> mapAccAndUltimateParent = new Map<Id, Id>();
    for (Account acc : newList) {
      if (acc.ParentId != null && acc.ParentId != oldMap.get(acc.Id).ParentId) {
        lstAccountToUpdate.add(acc);
      }
      if (acc.ParentId == null) {
        acc.Ultimate_Parent_Account__c = null;
      }
      //MIrfan. 10Dec13. I-84300. This is to align Child Records with correct Ultimate parent when Parent is not added.
      if (acc.ParentId != null && oldMap.get(acc.Id).ParentId == null) {
        mapUltimateAccountNowChild.put(acc.Id, acc);
      }

      //MIrfan. 17Dec13. I-84300. If Parent is blanked reparent children correctly.
      if (acc.ParentId == null && oldMap.get(acc.Id).ParentId != null) {
        mapAccAndUltimateParent.put(acc.Id, oldMap.get(acc.Id).Ultimate_Parent_Account__c);
      }
    }

    if (!lstAccountToUpdate.isEmpty()) {
      updateUltimateAccount(lstAccountToUpdate);
    }

    //MIrfan. 17Dec13. I-84300.
    if (!mapUltimateAccountNowChild.isEmpty()) {
      ultimateAccountUpdatedAlignChildren(mapUltimateAccountNowChild);
    }
    if (!mapAccAndUltimateParent.isEmpty()) {
      parentAccountRemovedAlignChildren(mapAccAndUltimateParent);
    }
  }
   
  //===========================================================================
  //MIrfan. 10Dec13. I-84300. If Parent Account is not Looking to another,
  //then all its Child records should reflect corrent Ultimate Parent.
  //===========================================================================
  public static void parentAccountRemovedAlignChildren(Map<Id, Id> mapAccAndUltimateParent) {
    List<Account> lstChildAccountsToUpdate = new List<Account>();
    
    // Retrieve all Children where Ultimate Parent matches removed Parent A/cs.

    // PK Case #582156 - Fix to avoid nulls in query below...
    List<Id> ultiParents = new List<Id>();
    for (Id ultiParentId : mapAccAndUltimateParent.values()) {
      if (ultiParentId != null) ultiParents.add(ultiParentId);
    }
    List<Id> accIds = new List<Id>();
    for (Id accId : mapAccAndUltimateParent.keyset()) {
      if (accId != null) {
        accIds.add(accId);
      }
    }

     // Retrieve all Children where Ultimate Parent matches removed Parent A/cs.
    Map<Id,Account> mapChildAccs = new Map<Id,Account>([
      SELECT Id, Ultimate_Parent_Account__c, ParentId 
      FROM Account
      WHERE Ultimate_Parent_Account__c IN :ultiParents
      AND Id != :accIds
      ORDER BY CreatedDate ASC
    ]);

    //Iterate through all Children records to align/correct hierarchy.
    for (Account accRec : mapChildAccs.values()) {
      //If this Child.Parent was one updated, meaning this is immediate child.
      //In this case Parent and Ultimate parent should be same A/c
      if (mapAccAndUltimateParent.containsKey(accRec.ParentId)) {
        //Add to list to update
        lstChildAccountsToUpdate.add(
          new Account(
            Id = accRec.Id,
            Ultimate_Parent_Account__c = accRec.ParentId
          )
        );
        //Also update the A/c in Map to reflect correct Ultimate Parent.
        mapChildAccs.get(accRec.Id).Ultimate_Parent_Account__c=accRec.ParentId;
      }
      else {
        //This to Iterate through Grand or Great Grand children records :-)
        //Pull the Current A/cs Parent A/c instace from Map.
        Account parentAccount = mapChildAccs.get(accRec.ParentId);

        system.debug('##########mapChildAccs##########'+mapChildAccs);
        system.debug('##########accRec##########'+accRec);

        //Iterate until Top level Parent A/c is reached.
        while(true)  {
          system.debug('##########parentAccount##########'+parentAccount);

          //If Parent is not known then move out of loop
          if (parentAccount == null) {
            break;
          }

          //If Parent A/c's Parent was the one updated the add to list, then break the loop.
          if (mapAccAndUltimateParent.containsKey(parentAccount.ParentId))  {
            system.debug('##########Found Parent in Removed##########');
            //Stamp Grand or Great Grand child with Ultimate Parent A/c
            lstChildAccountsToUpdate.add(
              new Account(
                Id = accRec.Id,
                Ultimate_Parent_Account__c = parentAccount.ParentId
              )
            );
            break;
          }

          //Get Parent A/c instance from Map for current Parent A/c.
          parentAccount = mapChildAccs.get(parentAccount.ParentId);
        }
      }
    }

    system.debug('##########lstChildAccountsToUpdate############'+lstChildAccountsToUpdate);

    if (!lstChildAccountsToUpdate.isEmpty()) {
      update lstChildAccountsToUpdate;
    }
  }

  //===========================================================================
  // MIrfan. 10Dec13. I-84300. If Ultimate Parent Account is not Looking upto another Parent,
  //                       then all its Child records should reflect corrent Ultimate Parent.
  //===========================================================================
  public static void ultimateAccountUpdatedAlignChildren (Map<Id, Account> mapUltimateAccountNowChild) {

    List<Account> lstChildAccountsToUpdate = new List<Account>();
    
    // Accounts where Ultimate account is same as Account's Ultimate whose parent is changed
    for (Account rec : [SELECT Id, Ultimate_Parent_Account__c, ParentId 
                        FROM Account
                        WHERE Ultimate_Parent_Account__c IN :mapUltimateAccountNowChild.keySet()
                        AND Id != :mapUltimateAccountNowChild.values()]) {
      lstChildAccountsToUpdate.add(
        new Account(
          Id = rec.Id,
          Ultimate_Parent_Account__c = mapUltimateAccountNowChild.get(rec.Ultimate_Parent_Account__c).Ultimate_Parent_Account__c
        )
      );
    }

    system.debug('##########lstChildAccountsToUpdate############'+lstChildAccountsToUpdate);

    if (!lstChildAccountsToUpdate.isEmpty()) {
      update lstChildAccountsToUpdate;
    }
  }
  
  //===========================================================================
  // Update Account's Ultimate_Parent_Account__c field when account is udpated
  // and its parent is changed
  //===========================================================================
  public static void updateUltimateAccount (List<Account> lstAccount) {

    Set<Id> newParentIds = new Set<Id>();
    Set<Id> setUltimateIds = new Set<Id>();
    for (Account acc : lstAccount) {
      if (acc.Ultimate_Parent_Account__c != null) {
        setUltimateIds.add(acc.Ultimate_Parent_Account__c);
      }
      if (acc.ParentId != null) {
        newParentIds.add(acc.ParentId);
      }
    }
    // Accounts where Ultimate account is same as Account's Ultimate whose parent is changed
    List<Account> accountToCheck = [
      SELECT Id,Ultimate_Parent_Account__c,ParentId
      FROM Account
      WHERE Ultimate_Parent_Account__c IN :setUltimateIds
      AND Id NOT IN :lstAccount
    ];
    
    // Parent Id To ultimate account Map
    Map<Id, Id> parentsUltimateAcc = new Map<Id, Id>();
    for(Account acc : [SELECT Id, Ultimate_Parent_Account__c, ParentId
                       FROM Account
                       WHERE Id IN :newParentIds]) {
      Id utlimateParent;
      if (acc.Ultimate_Parent_Account__c != null) {
        utlimateParent = acc.Ultimate_Parent_Account__c;
      }
      else {
        utlimateParent = acc.Id;
      }
      parentsUltimateAcc.put(acc.Id, utlimateParent);
    }
    // account Id To ultimate account Map
    Map<Id, Id> mpUltimateAcc = new Map<Id, Id>();
    // Update accounts where parent Id changed
    for (Account acc : lstAccount) {
      acc.Ultimate_Parent_Account__c = parentsUltimateAcc.get(acc.ParentId);
      mpUltimateAcc.put(acc.Id,parentsUltimateAcc.get(acc.ParentId));
    }
    
    Boolean iterateAgain = true;
    // List<Account> lstAccountToUpdate = new List<Account>();
    
    while (iterateAgain) {
      iterateAgain = false;
      for (Account accToCheck : accountToCheck) {
        if (mpUltimateAcc.containsKey(accToCheck.ParentId) && 
            accToCheck.Ultimate_Parent_Account__c != mpUltimateAcc.get(accToCheck.ParentId)) {
          accToCheck.Ultimate_Parent_Account__c = mpUltimateAcc.get(accToCheck.ParentId);
          mpUltimateAcc.put(accToCheck.Id,accToCheck.Ultimate_Parent_Account__c);
          iterateAgain = true;
        }
      }
    }
    // Udpate account where parent account is not checked but Ultimate account is updated indirectly
    update accountToCheck;
  }
  
  public static void addUserToAccountTeam (List<Account> newList) {
    List<AccountTeamMember> lstATMs = new List<AccountTeamMember>();
    // List<AccountShare> lstAccShare = new List<AccountShare>();
    
    //From Custom setting.
    Global_Settings__c custSettings = Global_Settings__c.getValues(Constants.GLOBAL_SETTING);
    system.debug('###########custSettings#########'+custSettings);

    //userMap = getUserMap(lstAccount);
    getUserMap (newList);
    for (Account accRec : newList) {
      system.debug('########accRec############'+accRec);
      // NLG - 2014-05-15 - do not create ATM if user is inactive
      if (userMap.get(accRec.CreatedById) != null && userMap.get(accRec.CreatedById).isActive == false) {
        continue;
      }
      //If creator and Owner is different then share the Add to Team and Share record with Edit
      // I-163031 PK: Adding change to check there is an inserted account as this should only run on new accounts.
      // RJ - Changed and Commented by RJ for case #v00005856
      //User globalAccountOwner = [Select ID from user where name = :custSettings.Global_Account_Owner__c limit 1 ];
      Experian_Global__c globalAccountOwnerId = Experian_Global__c.getInstance();
      // TP - Code to retrieve all the custom setting values
      //TP - adding check to make sure, this code does not run for Test Classes.
      List<Serasa_User_Profiles__c> allProfileCustSetting = Serasa_User_Profiles__c.getall().values();
      system.debug('Tyaga : The custom setting values are here '+ allProfileCustSetting);
      //Code to make sure this code does not break when creating accounts as part of Test Classes
      
      Set<String> serasaProfilesSet = New Set<String>();
         
      if(Test.isRunningTest()){           
          Set<String> serasaProfilesSettemp = new Set<String>{'Back Office and Legal','Consumer Contact Centre','eID Contact Center','Retention','SME Logon & VIP','Social Media Support','Support Coordinator / Supervisors','Third Level Support','Top SME/SME & Collections'};
          serasaProfilesSet = serasaProfilesSettemp.clone();
        }
      else
        {   
         //String CustomerCareProfile = allProfileCustSetting[0].Profiles__c;
         String CustomerCareProfile = allProfileCustSetting[1].Profiles__c;
         //Map<String,string> CustomerCareProfilesmap = New Map<String,String>(CustomerCareProfile);
         List<String> serasaProfiles = CustomerCareProfile.split(',');
         serasaProfilesSet.addAll(serasaProfiles);
        }
      
      system.debug('Tyaga : the profile list is ' + serasaProfilesSet);
      String whatToRemove = 'Experian Serasa';
      String userProfNameTemp = userMap.get(accRec.CreatedById).Profile.Name;
      String userProfName;
      if(userProfNameTemp.contains(whatToRemove)){
              userProfName = userProfNameTemp.remove('Experian Serasa'); 
     }
      
      if ((globalAccountOwnerId != null && globalAccountOwnerId.OwnerId__c != accRec.OwnerId) || 
           (insertedAccounts.containsKey(accRec.Id) && !serasaProfilesSet.contains(userProfName)))  {
          
          system.debug('Tyaga 133333: The custom setting values are here '+ !(serasaProfilesSet.contains(userMap.get(accRec.CreatedById).Profile.Name))); 
          lstATMs.add(
          new AccountTeamMember(
            AccountId = accRec.id,
            UserId = accRec.CreatedById,
            TeamMemberRole=custSettings.Account_Team_Member_Default_Role__c,
            AccountAccessLevel = Constants.ACCESS_LEVEL_EDIT,
            OpportunityAccessLevel = Constants.ACCESS_LEVEL_READ,
            CaseAccessLevel = Constants.ACCESS_LEVEL_READ
          )
        );
        /*
        // PK 02024883 - No longer required since v37
        //As Edit Access cannot be set via API for AccountTeamMember, has to create share record to give Edit access on Record.
        lstAccShare.add(new AccountShare(
          AccountId = accRec.id,
          AccountAccessLevel = Constants.ACCESS_LEVEL_EDIT,
          OpportunityAccessLevel = Constants.ACCESS_LEVEL_READ,
          // ContactAccessLevel = Constants.ACCESS_LEVEL_EDIT, // Sadar Mar 27 2014 - Sharing setting is set as 'Controlled by Parent'
          CaseAccessLevel = Constants.ACCESS_LEVEL_READ,
          UserOrGroupId = accRec.CreatedById
        ));
        */
      }
    }

    system.debug('##########lstATMs##########'+lstATMs);

    if (!lstATMs.isEmpty()) {
      try {
        insert lstATMs;
        // insert lstAccShare;
      }
      catch  (DMLException ex) {
        system.debug('##########ex##########'+ex);
        ApexLogHandler.createLogAndSave('AccountTriggerHandler','addUserToAccountTeam', ex.getStackTraceString(), ex);
        for (Integer i = 0; i < ex.getNumDml(); i++) {
          newList.get(0).addError(Label.Generic_message_for_system_error + '-'+ex.getDmlMessage(i));
        }
      }
    }
  }

  //=========================================================================
  // I-115460 - Get user isActive flag prior to creating an ATM record for them
  // added Profile to User Query : TP - Serasa Warranty Support case 13363768
  //=========================================================================
  private static void getUserMap(List<Account> accounts) {
    // userMap = new Map<Id, User>();
    Set<Id> createdByIds = new Set<Id>();

    for (Account acct : accounts) {
      if (!userMap.containsKey(acct.CreatedById)) {
        createdByIds.add(acct.CreatedById);
      }
    }
    userMap.putAll([
      SELECT Id, IsActive , Profile.Name
      FROM User
      WHERE Id IN :createdByIds
    ]);
  }

  // James Weatherall 10142014 - Uncommented code for migration to PROD
  //Start: Update VBM Code on the Account. Used mainly for Aria migration.
  // PK: Optimised to fix multiple call
  private static void setVBMCode (List<Account> newList, Map<Id, Account> oldMap) {
    Set<Id> accIDs = new Set<Id>();
    Map<Id, String> industrySectorMap = new Map<Id, String>();
    Map<String, String> vbmDescriptionCodes = new Map<String, String>();
    String vbmDescription, industrySector;

    // Get the list of Industries and Sectors
    // Set to lowercase due to case sensitivity in Map keySet
    for (Account acc : newList) {
      if (String.isNotBlank(acc.Industry) && String.isNotBlank(acc.Sector__c)) {
        String indSectorKey = (acc.Industry + '-' + acc.Sector__c).toLowerCase();
        if (vbmCodeMap.containsKey(indSectorKey)) {
          acc.VBM_Code__c = vbmCodeMap.get(indSectorKey);
        }
        else {
          accIDs.add(acc.Id);
          industrySectorMap.put(acc.Id, indSectorKey);
          system.debug('###########industrySector#########'+indSectorKey);
        }
      }
    }
    system.debug('###########industrySectorMap.values()#########'+industrySectorMap.values());
    // Create a map of Descriptions and VBM Codes
    if (!industrySectorMap.isEmpty()) {
      for (Oracle_VBM_Codes__c ovc : [SELECT Name, Description__c 
                                      FROM Oracle_VBM_Codes__c 
                                      WHERE Description__c IN :industrySectorMap.values()]) {
        vbmDescription = ovc.Description__c.toLowerCase();
        system.debug('###########vbmDescription#########'+vbmDescription);
        if (!vbmDescriptionCodes.containsKey(vbmDescription)) {
          vbmDescriptionCodes.put(vbmDescription, ovc.Name);
        }
        vbmCodeMap.put(vbmDescription, ovc.Name);
      }
    }
    system.debug('###########vbmDescriptionCodes#########'+vbmDescriptionCodes);
    // Set the VBM Code on the Account
    try {
      for (Account acc : newList) {
        if (accIDs.contains(acc.Id)) {
          acc.VBM_Code__c = vbmDescriptionCodes.get(industrySectorMap.get(acc.Id));
        }
      }
    } 
    catch (DMLException e) {
      system.debug('\n[AccountTriggerHandler: setVBMCode]: ['+e.getMessage()+']]');
      apexLogHandler.createLogAndSave('AccountTriggerHandler','setVBMCode', e.getStackTraceString(), e);
      for (Integer i = 0; i < e.getNumDml(); i++) {
        newList.get(0).addError(Label.Generic_message_for_system_error + ' - '+e.getDmlMessage(i));
      }
    }
  }

  /**************************************************************************
  *                           ARIA CODE BELOW                               *
  **************************************************************************/
  //=========================================================================
  //T-264687; to Update ARIA_BillingACC.SendBillingAccToAria = true
  //=========================================================================
  private static void setSendBillingAccountToAria (List<Account> newList, Map<ID, Account> oldMap) {
    Set<ID> accIDs = new Set<ID>();
    Set<String> accFieldNameSet = new Set<String>{
      'Website', 'Ultimate_Parent_Account__c',
      'Status__c', 'Sector__c', 'Phone', 'ParentId', 'Name', 'Industry',
      'BillingStreet', 'BillingState', 'BillingPostalCode', 
      'BillingCountry', 'BillingCity'
    };
    Map<String, ARIA_Billing_Account__c> ARIABilAcc_Map = new Map<String, ARIA_Billing_Account__c> ();
    //check whether above set of fields updated
    for (Account acc : newList) {
      if (isChangedAnyField(accFieldNameSet, acc, oldMap.get(acc.ID))) {
        accIDs.add(acc.ID);
      }
    }
    //If there is no field changed in the account list, return
    if (accIDs.isEmpty()) {
      return;
    }
    try {
      for (Account acc : [SELECT Id, (SELECT Id, Push_To_Aria__c, SendBillingAccntToAria__c , Billing_Account_Country__c, Direct_Debit__c
                                      FROM ARIA_Billing_Accounts__r
                                      WHERE Push_To_Aria__c = :Constants.PICKLISTVAL_YES)
                          FROM Account 
                          WHERE Id IN :accIDs]) {
        for (ARIA_Billing_Account__c abAcc : acc.ARIA_Billing_Accounts__r) {
          if (!ARIABilAcc_Map.containsKey(abAcc.ID)) {
            abAcc.SendBillingAccntToAria__c = true;
            ARIABilAcc_Map.put(abAcc.ID, abAcc);
            system.debug('\ncountry: '+ abacc.Billing_Account_Country__c + '\nDirectDebit: '+ abacc.Direct_Debit__c);
          }
        }
      }

      if (!ARIABilAcc_Map.isEmpty()) {
        update ARIABilAcc_Map.values();
      }
    }
    catch (DMLException e) {
      system.debug('\n[AccountTriggerHandler: setSendBillingAccountToAria]: ['+e.getMessage()+']]');
      apexLogHandler.createLogAndSave('AccountTriggerHandler','setSendBillingAccountToAria', e.getStackTraceString(), e);
      for (Integer i = 0; i < e.getNumDml(); i++) {
        newList.get(0).addError(Label.Generic_message_for_system_error + ' - ' + e.getDmlMessage(i));
      }
    }
  }

  //=========================================================================
  //T-264687; to check any field got changed.
  //=========================================================================
  private static Boolean isChangedAnyField (Set<String> fieldNameSet, Account newRecord, Account oldRecord) {
    if(fieldNameSet.isEmpty()){
      return false;
    }
    for (String fieldName : fieldNameSet) {
      if (newRecord.get(fieldName) != oldRecord.get(fieldName)) {
        return true;
      }
    }
    return false;
  }

  //===========================================================================
  // T-332669: Send to On-Demand
  //===========================================================================
  /*private static void sendToOnDemand (List<Account> newList, Map<Id, Account> oldMap) {

    Set<Id> accountIDs = new Set<Id>();
    
    Map<String, Contact> accID_contactsToSendOnDemand = new Map<String, Contact>();

    //Checking name changed of accounts
    for (Account acc : newList) {
      if (acc.Name != oldMap.get(acc.ID).Name) {
        accountIDs.add(acc.ID);
      }
    }
    
    if (accountIDs.isEmpty()) {
      return;
    }

    //Setting send to on demand = true
    for (Contact c : [SELECT Id, EDQ_Send_to_On_Demand__c, EDQ_On_Demand__c, AccountId
                      FROM Contact
                      WHERE AccountID IN :accountIDs 
                      AND EDQ_On_Demand__c = true]) {
      c.EDQ_Send_to_On_Demand__c = true;
      if (!accID_contactsToSendOnDemand.containsKey(c.AccountID)) {
        accID_contactsToSendOnDemand.put(c.AccountID, c);
      }
    }

    //Update contacts
    if (!accID_contactsToSendOnDemand.isEmpty()) {
      try {
        update accID_contactsToSendOnDemand.values();
      } 
      catch(DMLException e){
        newList.get(0).addError(Label.ACCOUNT_ERROR_NAME_CHANGE_On_Demand_Flag);
        system.debug('\n[AccountTriggerHandler: sendToOnDemand]: ['+e.getMessage()+']]');
        apexLogHandler.createLogAndSave('AccountTriggerHandler','sendToOnDemand', e.getStackTraceString(), e);
        for (Integer i = 0; i < e.getNumDml(); i++) {
          newList.get(0).addError(Label.Generic_message_for_system_error + ' - ' + e.getDmlMessage(i));
        }
      }
    }
  }*/

  

  //===========================================================================
  // Case # 02413263: Update account segment names 
  //===========================================================================
  private static void updateAccountSegmentNames(Map<Id, Account> oldMap) {
     List<Id> accountListIds = new List<Id>();
     
     for (Account acc : oldMap.values()) {
        accountListIds.add(acc.Id);
    }
     
     updateAccountSegmentNamesHelper(accountListIds);
  
 } 

  //===========================================================================
  // Case # 15082239: Update account segment names, created future method
  //===========================================================================
  @future
  private static void updateAccountSegmentNamesHelper(List<Id> accountListIds) {
  
    Map<Id, String> winnerIdsLoserNames = new Map<Id, String>();
    List<Account_Segment__c> accountSegmentsToUpdate = new List<Account_Segment__c>();
    List<Account> winnerAccounts = new List<Account>();
    Set<Id> loserIds = new Set<Id>();
    Set<Id> winningIds = new Set<Id>();
    
    for (Account deletedAccount : [Select id, name, MasterRecordId from Account where id IN :accountListIds ALL ROWS]) {
      if (deletedAccount.MasterRecordId != null) {
        // master is winning record.
        winnerIdsLoserNames.put(deletedAccount.MasterRecordId, deletedAccount.name);        
        winningIds.add(deletedAccount.MasterRecordId);
        loserIds.add(deletedAccount.id);        
      }
    }
    
    if (!winnerIdsLoserNames.isEmpty()) {
    
      winnerAccounts = [SELECT id, name, (select id, name from account_segments__r)
                        FROM Account 
                        WHERE Id IN :winningIds];    
                        
      for (Account winnerAccount : winnerAccounts){
        String newAccName = AccountSegmentationUtility.getAccNamePrefix(winnerAccount.Name);
        String oldAccName = AccountSegmentationUtility.getAccNamePrefix(winnerIdsLoserNames.get(winnerAccount.Id));
        if(!newAccName.equals(oldAccName)){
        
          for(Account_Segment__c accountSegment : winnerAccount.account_segments__r){
              accountSegment.Name = accountSegment.Name.replace(oldAccName, newAccName);
              accountSegmentsToUpdate.add(accountSegment);
          }
        }
      } 
    }
    
    if(accountSegmentsToUpdate.size() > 0){
      update accountSegmentsToUpdate;          
    }    
  }
    

  //===========================================================================
  // Case #29746: Merge History
  //===========================================================================
  private static void createMergeHistory(Map<Id, Account> oldMap) {
    // S-284433
    Map<Id, Id> loserToWinnerIds = new Map<Id, Id>();
    Set<Id> winningIds = new Set<Id>();
    for (Account deletedAccount : oldMap.values()) {
      if (deletedAccount.MasterRecordId != null) {
        // master is winning record.
        loserToWinnerIds.put(deletedAccount.Id,deletedAccount.MasterRecordId);
        // Set to hold which accounts won in the merge (normally only 1 record here, as merges don't get bulked.)
        winningIds.add(deletedAccount.MasterRecordId);
        // also adding the ultimate parent Id (if on the deleted records...) for use below
        if (deletedAccount.Ultimate_Parent_Account__c != null) {
          winningIds.add(deletedAccount.Ultimate_Parent_Account__c);
        }
      }
    }
    system.debug('AfterrrloserToWinnerIds@@@'+loserToWinnerIds);
    if (!loserToWinnerIds.isEmpty()) {
      // From these we need to get the CSDA_Integration_Id__c and EDQ_Integration_Id__c from both winner and loser (loser will be in the trigger, winner won't)
      List<MergeHistory__c> newHistory = new List<MergeHistory__c>(); 
      try {
        Map<Id, Account> winners = new Map<Id, Account>([
          SELECT EDQ_Integration_Id__c, 
            CSDA_Integration_Id__c, 
            Global_Unique_ID__c,
            Saas__c,  // This is for an account. It was removed!
            Experian_ID__c,
            Ultimate_Parent_Account__c, 
            Ultimate_Parent_Account__r.CSDA_Integration_Id__c 
          FROM Account 
          WHERE Id IN :winningIds
        ]);
        for (Id loserId : loserToWinnerIds.keySet()) {
          Account loserAcc = oldMap.get(loserId);
          Account winnerAcc = winners.get(loserToWinnerIds.get(loserId));
          // Calls new utility class to build the MergeHistory
          MergeHistory__c mh = MergeHistoryUtility.createMergeHistoryRecord(loserAcc,winnerAcc); 
          // Since this only applies to Accounts, add a check and set the top parent here.
          if (loserAcc.Ultimate_Parent_Account__c != null) {
            try {
              mh.Loser_Top_Parent_CSDA_Integration_ID__c = winners.get(loserAcc.Ultimate_Parent_Account__c).CSDA_Integration_Id__c;
            }
            catch (Exception e) {
              system.debug('\n[AccountTriggerHandler: createMergeHistory]: ['+e.getMessage()+']]');
              apexLogHandler.createLogAndSave('AccountTriggerHandler','createMergeHistory', e.getStackTraceString(), e);
            }
          }
          newHistory.add(mh);
        }
        insert newHistory;
        
      } 
      catch(DMLException e){
        system.debug('\n[AccountTriggerHandler: createMergeHistory]: ['+e.getMessage()+']]');
        apexLogHandler.createLogAndSave('AccountTriggerHandler','createMergeHistory', e.getStackTraceString(), e);
      }
    }
  }
  
  private static void createTransactionQueueHistory(Map<Id, Account> oldMap) { //W006543
    
    try {
        Map<Id, Id> loserToWinnerIds = new Map<Id, Id>();
        string currentURL = URL.getCurrentRequestUrl().toExternalForm();
        if(Test.isRunningTest()){           
            currentURL = 'merge/accmergewizard.jsp';        
        }        
        for (Account deletedAccount : oldMap.values()) {
          if(currentURL.contains('merge/accmergewizard.jsp')){
            // master is winning record.
            loserToWinnerIds.put(deletedAccount.Id,deletedAccount.MasterRecordId);
            // Set to hold which accounts won in the merge (normally only 1 record here, as merges don't get bulked.)
            
          }
        }
        system.debug('BeforeeeeloserToWinnerIds@@@'+loserToWinnerIds);
        if (!loserToWinnerIds.isEmpty()) {
      
            //Added by Manoj to create transaction queue records for contact, asset and case for the looser account
            list<Transaction_Queue__c> lstTrans = new list<Transaction_Queue__c>();
            for(Contact con:[select id,SNOW_ContactID__c from Contact where AccountId =: loserToWinnerIds.keySet() AND SNOW_ContactID__c!=null AND SNOW_ContactID__c!='']){
                Transaction_Queue__c obj = new Transaction_Queue__c();                                   
                obj.Action_Type__c = 'Update';                
                obj.Transaction_Object_Name__c = 'Contact';
                obj.Transaction_Status__c = 'New';
                obj.SF_Record_ID__c = con.Id;
                obj.Target_Application__c = 'ServiceNow';
                obj.Operation_Type__c = 'ContactUpdate';
                obj.Transaction_Type__c = 'Outbound';
                lstTrans.add(obj);          
            }
            for(Asset ast:[select id,SNOW_AssetID__c from Asset where AccountId =: loserToWinnerIds.keySet() AND SNOW_AssetID__c!=null AND SNOW_AssetID__c!='']){
                Transaction_Queue__c objAss = new Transaction_Queue__c();                                   
                objAss.Action_Type__c = 'Update';                
                objAss.Transaction_Object_Name__c = 'Asset';
                objAss.Transaction_Status__c = 'New';
                objAss.SF_Record_ID__c = ast.Id;
                objAss.Target_Application__c = 'ServiceNow';
                objAss.Operation_Type__c = 'AssetUpdate';
                objAss.Transaction_Type__c = 'Outbound';
                lstTrans.add(objAss);           
            }
            for(Case cse:[select id,SNOW_CaseID__c from Case where AccountId =: loserToWinnerIds.keySet() AND SNOW_CaseID__c!=null AND SNOW_CaseID__c!='']){
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
            if(!lstTrans.isEmpty())
                Database.insert(lstTrans);
           }
       }
       catch(DMLException e){
          system.debug('\n[AccountTriggerHandler: createMergeHistory]: ['+e.getMessage()+']]');
          apexLogHandler.createLogAndSave('AccountTriggerHandler','createMergeHistory', e.getStackTraceString(), e);
       }
      
    
  }
   
  // Case #542921 : Check and replace the parent on a merged record, if it's there on the 'deleted' account.
  private static void checkForOriginalParent (Map<Id, Account> oldMap) {
    Map<Id, Id> winningToParent = new Map<Id, Id>();
    for(Account deletedAccount : oldMap.values()) {
      if (deletedAccount.MasterRecordId != null) {
        // find the parentid on the deleted record, and set this on the new masterrecordid record...
        if (deletedAccount.ParentId != null) {
          winningToParent.put(deletedAccount.MasterRecordId,deletedAccount.ParentId);
        }
      }
    }
    if (!winningToParent.isEmpty()) {
      // Due to a SELF_REFERENCE_FROM_TRIGGER DML exception, the update of the winning records must be in a future method.
      AccountTriggerHandler.fixParentAccountPostMerge(winningToParent);
    }
  }

  // Case #542921 : After the merge has completed, find the winning records, and reparent them if there is no original parent record.
  // This doesn't happen immediately though, so the parent will eventually be fixed!
  @future
  public static void fixParentAccountPostMerge (Map<Id, Id> winningToParent) {
    List<Account> updateWinningWithParent = [
      SELECT ParentId, Id 
      FROM Account 
      WHERE Id IN :winningToParent.keySet() 
      AND ParentId = null
    ];
    if (!updateWinningWithParent.isEmpty()) {
      // For each account, get the new 'parent' and save.
      for (Account a : updateWinningWithParent) {
        // Adding fix for the parent id on the old (losing) merged record being the id of this record.
        if (a.ParentId == null && winningToParent.get(a.Id) != a.Id) {
          a.ParentId = winningToParent.get(a.Id);
        }
      }
      update updateWinningWithParent;
    }
  }
  
  //DRM:W006453
  public static void checkUpdatedAccountsForAccountStagingTable(List<Account> newList, Map<ID, Account> oldMap){
    List<Account> accountsForStagingTableList = new List<Account>();
    
    Set<String> accFieldNameSet = new Set<String>{
      'Name', 'Account_Type__c','Client_Tier__c','DQ_Status__c','Experian_Company__c','ParentId',
      'Phone','Strategic_Parent__c','Strategic_Child__c','Strategic_Client_Level__c','Ultimate_Parent_Account__c',
      'Ultimate_Parent_Account_ID__c','VBM_Code__c', 'Additional_AKA__c','Additional_FKA__c',
      'Global_Strategic_Client__c', 'APAC_Regional_Strategic_Client__c',
      'EMEA_Regional_Strategic_Client__c','LATAM_Regional_Strategic_Client__c',
      'NA_Regional_Strategic_Client__c','UK_I_Regional_Strategic_Client__c'     
    };
    /** We do not need to check here for the value of Strategic_Client__c as it will be updated when 
       Global_Strategic_Client__c,APAC_Regional_Strategic_Client__c,EMEA_Regional_Strategic_Client__c,
       LATAM_Regional_Strategic_Client__c,NA_Regional_Strategic_Client__c,UK_I_Regional_Strategic_Client__c 
       and its inclusion here would cause an incorrect double-write of two records to the Account_Staging__c table**/
      
    //check whether above set of fields updated
    for (Account acc : newList) {
      //Case #02410797
      if (acc.Region__c != Constants.REGION_LATIN_AMERICA && isChangedAnyField(accFieldNameSet, acc, oldMap.get(acc.ID))){
        accountsForStagingTableList.add(acc);
      }
    }
    //If there is no field changed in the account list, return
    if (accountsForStagingTableList.isEmpty()) {
      return;
    }
    
    insertStagingTableEntries(accountsForStagingTableList, 1);
    
  }//Case 14031099: Commented out. // RJ Uncommented for 17300951
  
  //DRM:W-006453
  public static void createDeletionEntryInStagingTable(Map<ID, Account> oldMap){
    List<Account> deletedList = oldMap.values();
    
    insertStagingTableEntries(deletedList, 5);
    
  }
  
  
  
  //DRM:W006453
  //Case 14031099 - Still used for Account merges (Action Code 5).
  public static void insertStagingTableEntries(List<Account> newList, Integer actionCode){     
    List<Account_Staging__c> accStagingListinsert = new List<Account_Staging__c>();      
    Map<ID,ID> winnerLoserAccountID_Map = new Map<ID,ID>();
    List<Account> accountsForAccountStaging = new List<Account>();
    List<Account> accountsForAccountStaging_SI = new List<Account>();
    //List<Id> accId_List = new List<Id>();
    
    //Case #02410797
    for(Account acc : newList){
      if(/*acc.Drm_Name__c!=null &&*/
         acc.Region__c != Constants.REGION_LATIN_AMERICA){
        accountsForAccountStaging.add(acc);
        //accId_List.add(acc.id);
      }
    }
    
    /*Previously added for Case 14031099, now commented out.
    Map<Id, Account> account_SI_Map = new Map<Id,Account>([SELECT id, (SELECT id FROM SalesInsight_Cross_References__r)
                                                           FROM Account WHERE id IN :accID_List]);
    for(Account acc0 : accountsForAccountStaging){
      //if(account_SI_Map.get(acc0.id).SalesInsight_Cross_References__r.isEmpty()==false){
        accountsForAccountStaging_SI.add(acc0);
      //}
    }
    
    if(accountsForAccountStaging_SI.isEmpty()){
      return;
    }*/
    
    for(Account acc1 : accountsForAccountStaging){ // RJ Uncommented for 17300951
      Account_Staging__c newAccStagingEntry = new Account_Staging__c();
      
      newAccStagingEntry.Action_Code__c                      = actionCode;
      
      //Fields derived from Account Object
      if(ActionCode == 5 && acc1.MasterRecordId != Null){
        //The Account has been merged so set the 'Winner' and 'Loser' account details
        newAccStagingEntry.Account_Id__c                       = acc1.id;
        newAccStagingEntry.Account_Id_Winner__c                = acc1.MasterRecordId;
        newAccStagingEntry.Account_Id_Loser__c                 = acc1.id;
        winnerLoserAccountID_Map.put(acc1.MasterRecordId, acc1.id);
     
      } else {
        newAccStagingEntry.Account_Id__c                       = acc1.id;
      }
      
      assignStagingTableValues(newAccStagingEntry, acc1, actionCode);
        
      accStagingListinsert.add(newAccStagingEntry);
      
    }
   
    try{
      insert accStagingListinsert;
      
    } catch(Exception e){
      system.debug('\n[AccountTriggerHandler: insertStagingTableEntries]: ['+e.getMessage()+']]');
      apexLogHandler.createLogAndSave('AccountTriggerHandler','insertStagingTableEntries', e.getStackTraceString(), e);
    }
           
    if(winnerLoserAccountID_Map.isEmpty()==false){
      List<Account> winnerAccountsForStaging = ([SELECT id, Name, ParentId, Parent.Name, Account_Type__c, Additional_AKA__c, Additional_FKA__c, Phone,
                                                /*SI_Key__c, SI_Name__c,*/ DQ_Status__c, Experian_Company__c, Partner_Type__c,
                                                Strategic_Parent__c, Strategic_Child__c, Strategic_Client_Level__c,
                                                Ultimate_Parent_Account__c, VBM_Code__c, Global_Strategic_Client__c,
                                                Ultimate_Parent_Account_ID__c, Strategic_Client__c,
                                                APAC_Regional_Strategic_Client__c, EMEA_Regional_Strategic_Client__c, LATAM_Regional_Strategic_Client__c,
                                                NA_Regional_Strategic_Client__c, UK_I_Regional_Strategic_Client__c, Client_Tier__c,
                                                BillingStreet, BillingCity, BillingCountry, BillingPostalCode, BillingState, CreatedBy.Id, CreatedDate,
                                                LastModifiedBy.Id, LastModifiedDate
                                                FROM Account WHERE id IN :winnerLoserAccountID_Map.KeySet()]);

      insertStagingTableEntriesForWinnerRecords(winnerAccountsForStaging, winnerLoserAccountID_Map);
    }      
           
           
  }
  

  //DRM:W006453   
  public static void insertStagingTableEntriesForWinnerRecords(List<Account> newList, Map<ID,ID> winnerLoserAccountIDList){
     
    List<Account_Staging__c> accStagingListinsert = new List<Account_Staging__c>();  
    
      
    for(Account acc : newList){
      Account_Staging__c newAccStagingEntry = new Account_Staging__c();
      
      newAccStagingEntry.Action_Code__c                      = 5;
      

      //The Account has been merged so set the 'Winner' and 'Loser' account details
      newAccStagingEntry.Account_Id__c                       = acc.id;
      newAccStagingEntry.Account_Id_Winner__c                = acc.id;
      newAccStagingEntry.Account_Id_Loser__c                 = winnerLoserAccountIDList.get(acc.id);
  
      assignStagingTableValues(newAccStagingEntry, acc, 5);
        
      accStagingListinsert.add(newAccStagingEntry);
      
    }
   
    try{
      insert accStagingListinsert;
    } catch(Exception e){
      system.debug('\n[AccountTriggerHandler: insertStagingTableEntries]: ['+e.getMessage()+']]');
      apexLogHandler.createLogAndSave('AccountTriggerHandler','insertStagingTableEntries', e.getStackTraceString(), e);
    }
  }
  
  public static void assignStagingTableValues(Account_Staging__c newAccStagingEntry, Account acc, Integer actionCode){
  
      newAccStagingEntry.Account_Name__c                     = acc.Name;
      newAccStagingEntry.Parent_Account_Id__c                = acc.ParentId;
      newAccStagingEntry.Parent_Name__c                      = acc.Parent.Name;
      newAccStagingEntry.Account_CreatedBy__c                = acc.CreatedById;          
      newAccStagingEntry.Account_CreatedDate__c              = acc.CreatedDate;
      newAccStagingEntry.Account_LastModifiedBy__c           = acc.LastModifiedById;
      newAccStagingEntry.Account_LastModifiedDate__c         = acc.LastModifiedDate;
      newAccStagingEntry.Ultimate_Parent_Account__c          = acc.Ultimate_Parent_Account__c;
      newAccStagingEntry.Ultimate_Parent_Account_ID__c       = acc.Ultimate_Parent_Account_ID__c;
      
      if(actionCode!=5){
        newAccStagingEntry.Account_Type__c                     = acc.Account_Type__c;   
        newAccStagingEntry.Additional_AKA__c                   = acc.Additional_AKA__c;
        newAccStagingEntry.Additional_FKA__C                   = acc.Additional_FKA__c;    
        newAccStagingEntry.Phone__c                            = acc.Phone;

        //newAccStagingEntry.SI_Key__c                           = acc.SI_Key__c;
        //newAccStagingEntry.SI_Name__c                          = acc.SI_Name__c;
      
        newAccStagingEntry.Client_Tier__c                      = acc.Client_Tier__c;
        newAccStagingEntry.DQ_Status__c                        = acc.DQ_Status__c;
        newAccStagingEntry.Experian_Company__c                 = acc.Experian_Company__c     ? 'true' : 'false';
        newAccStagingEntry.Partner_Type__c                     = acc.Partner_Type__c;
        newAccStagingEntry.Strategic_Parent__c                 = acc.Strategic_Parent__c     ? 'true' : 'false';
        newAccStagingEntry.Strategic_Child__c                  = acc.Strategic_Child__c      ? 'true' : 'false';
        newAccStagingEntry.Strategic_Client_Level__c           = acc.Strategic_Client_Level__c;
        newAccStagingEntry.VBM_Code__c                         = acc.VBM_Code__c;
  
        newAccStagingEntry.Global_Regional_Strategic_Client__c = acc.Global_Strategic_Client__c         ? 'true' : 'false';          
        newAccStagingEntry.Strategic_Client__c                 = acc.Strategic_Client__c                ? 'true' : 'false';
        newAccStagingEntry.APAC_Regional_Strategic_Client__c   = acc.APAC_Regional_Strategic_Client__c  ? 'true' : 'false';
        newAccStagingEntry.EMEA_Regional_Strategic_Client__c   = acc.EMEA_Regional_Strategic_Client__c  ? 'true' : 'false';
        newAccStagingEntry.LATAM_Regional_Strategic_Client__c  = acc.LATAM_Regional_Strategic_Client__c ? 'true' : 'false';
        newAccStagingEntry.NA_Regional_Strategic_Client__c     = acc.NA_Regional_Strategic_Client__c    ? 'true' : 'false';
        newAccStagingEntry.UK_I_Regional_Strategic_Client__c   = acc.UK_I_Regional_Strategic_Client__c  ? 'true' : 'false';
      
        //Billing Details          
        newAccStagingEntry.BillingStreet__c     = acc.BillingStreet;
        newAccStagingEntry.BillingCity__c       = acc.BillingCity;
        newAccStagingEntry.BillingCountry__c    = acc.BillingCountry;
        newAccStagingEntry.BillingPostCode__c   = acc.BillingPostalCode;
        newAccStagingEntry.BillingState__c      = acc.BillingState;
      }
  }
  
  
  //===========================================================================
  // Case #525537: For Account Integrity check setup If "Integrity Check Not Approved" checkbox is 
  //  checked trigger child open Opptys will be edited to fire a workflow
  //===========================================================================
  // PK Commenting out since this case is not signed off and hotfix on other code is required.
  /*
  public static void integrityCheckProcessing(List<Account> newList, Map<Id, Account> oldMap){  

    Map<Id, Account> changedAccounts = new Map<Id, Account>();
    
    for (Account accCheck : newList) {
      Account old = oldMap.get(accCheck.Id);
      if (accCheck.Integrity_Check_Not_Approved__c != old.Integrity_Check_Not_Approved__c) {
        changedAccounts.put(accCheck.Id, accCheck);
      }
    }

    if (changedAccounts.size() > 0) {           
      List<Opportunity> opportunitiesToUpdate = new List<Opportunity>();
                  
      for (Opportunity changedAccountOpportunity : [SELECT Id, AccountId, Account_Integrity_Check_Not_Approved__c FROM Opportunity WHERE AccountId IN :changedAccounts.keySet()]) {
        Account parentAccount = changedAccounts.get(changedAccountOpportunity.AccountId);        
        Boolean parentAccountValue = parentAccount.Integrity_Check_Not_Approved__c != null;

        //if (changedAccountOpportunity.Account_Integrity_Check_Not_Approved__c != parentAccountValue) {
        if(parentAccount.Integrity_Check_Not_Approved__c==True){    
          changedAccountOpportunity.Account_Integrity_Check_Not_Approved__c = True;
        } else if(parentAccount.Integrity_Check_Approved__c==True) {
          changedAccountOpportunity.Account_Integrity_Check_Not_Approved__c = False;
        }
          opportunitiesToUpdate.add(changedAccountOpportunity); 
        //}
      }
            
      try {
        update(opportunitiesToUpdate);
      } catch(DMLException e){
        System.debug('\n[AccountTriggerHandler: integrityCheck]: ['+e.getMessage()+']]');
        apexLogHandler.createLogAndSave('AccountTriggerHandler','integrityCheck', e.getStackTraceString(), e);
      }      

      
      List<Account> changedAccountsList = changedAccounts.values();
      //Now perform field updates
      for(Account acc : changedAccountsList){
         if(acc.Integrity_Check_Not_Approved__c==true){
           //acc.Do_Not_Deal__c = true;
           //acc.Do_Not_Deal_Reason__c ='Integrity Check';
         } else if(acc.Integrity_Check_Not_Approved__c==false){
           acc.Do_Not_Deal__c = false;
           acc.Do_Not_Deal_Reason__c =NULL;          
         }
         acc.Validated_Date__c = datetime.now();
         acc.Validated_By__c = acc.LastModifiedById;
      }
            

    }          
      
   }
   */
    
   public static void updateAccountSegmentNames(List<Account> newList, Map<Id, Account> oldMap){ 
      List<Account> accsWithNameUpdates = new List<Account>();

      for(Account acc : newList){
         String newAccName = AccountSegmentationUtility.getAccNamePrefix(acc.Name);
         String oldAccName = AccountSegmentationUtility.getAccNamePrefix(oldMap.get(acc.Id).Name);

         if(!newAccName.equals(oldAccName)){
            accsWithNameUpdates.add(acc);
         }
      }
      
      if(accsWithNameUpdates.size() > 0){
        List<Account_Segment__c> listSegmentsToUpdate = new List<Account_Segment__c>();

        List<Account> listAcctsWithSegments = [SELECT ID, NAME, (SELECT ID, NAME FROM ACCOUNT_SEGMENTS__R) 
                                                        FROM ACCOUNT 
                                                        WHERE ID IN :accsWithNameUpdates];

        for(Account acc : listAcctsWithSegments){
            String newAccName = AccountSegmentationUtility.getAccNamePrefix(acc.Name);
            String oldAccName = AccountSegmentationUtility.getAccNamePrefix(oldMap.get(acc.Id).Name);

            for(Account_Segment__c seg : acc.Account_Segments__r){
                seg.Name = seg.Name.replace(oldAccName, newAccName);  
                listSegmentsToUpdate.add(seg);
            }            
        }

        if(listSegmentsToUpdate.size() > 0){
          update listSegmentsToUpdate;          
        }
      }
   }

  public static void setAccountOrigin(List<Account> newList){
    String originStr;
    originStr = URL.getOrgDomainUrl().toExternalForm();
    System.Debug('*** domain url: ' + originStr + '   sizeof list='  + newList.size() + ' ***');
    originStr = URL.getSalesforceBaseUrl().toExternalForm();
    System.Debug('*** base url: ' + originStr + '   sizeof list='  + newList.size() + ' ***');
    for(Account acc : newList){
      if(originStr.contains('ebaportal-experianconsumercommunity.cs4.force.com')){  // ExperianSales EBA portal
        acc.Origin__c = 'Service Source';
      }
    }
  }
    
    public static void updateEmpHierarchyOnDqChange(Map<Id, Account> oldMap, List<Account> newList){
        Set<String> accountIdSet = new Set<String>();
        
        for(Account accObj : newList){
            if(accObj.Summarized_Contact_DQ_Score__c != oldMap.get(accObj.Id).Summarized_Contact_DQ_Score__c){
                accountIdSet.add(accObj.Id);
            }
        }
            updateEOHOnDqChangeFuture(accountIdSet);
    }
    
    public static void updateEOHOnDqChangeFuture(Set<String> accountIdSet){
        Set<Id> userIdSet = new Set<Id>();
        List<Employee_Org_Hierarchy__c> empHierarchyList = new List<Employee_Org_Hierarchy__c>();
        Map<Id, Decimal> individualScoreMap = new Map<Id, Decimal>();
        
        if(!accountIdSet.isEmpty()){
            for(AccountTeamMember accTM : [SELECT UserId FROM AccountTeamMember WHERE AccountId IN :accountIdSet]){
                userIdSet.add(accTM.UserId);
            }
            for(AggregateResult aggRes : [SELECT userId, AVG(account.Summarized_Contact_DQ_Score__c) sumConDQScore FROM AccountTeamMember WHERE userId IN :userIdSet Group By userId]){
                    individualScoreMap.put((String) aggRes.get('userId'), (Decimal)aggRes.get('sumConDQScore'));
            }
            
            if(!userIdSet.isEmpty()){
                for(Employee_Org_Hierarchy__c empHierObj : [SELECT Employee_Id__c,Cumulative_Score__c, Employee_Rec_Changed__c FROM Employee_Org_Hierarchy__c WHERE Employee_Id__c IN :userIdSet]){
                    empHierObj.Employee_Rec_Changed__c = true;
                    empHierObj.Individual_Score__c = individualScoreMap.get(empHierObj.Employee_Id__c);
                    if(empHierObj.Cumulative_Score__c == null){
                        empHierObj.Cumulative_Score__c = individualScoreMap.get(empHierObj.Employee_Id__c);
                    }
                    empHierarchyList.add(empHierObj);
                }
                update empHierarchyList;
            }
        }
    }
}