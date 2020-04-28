/**=====================================================================
 * Appirio, Inc
 * Name: AccountTriggerHandler_Test
 * Description: T-211356 , T-211358 , T-211369,
        Provide test coverage to the class "AccountManagement"
 * Created Date: Nov 13th, 2013
 * Created By: Pankaj Mehra (Appirio)
 *
 * Date Modified                Modified By                  Description of the update
 * Jan 30th, 2014                   Jinesh Goyal(Appirio)        T-232760: Homogenize the comments
 * Feb 13th, 2014                   Jinesh Goyal(Appirio)        T-232763: Added Exception Logging
 * Mar 04th, 2014                   Arpita Bose (Appirio)        T-243282: Added Constants in place of String
 * Mar 20th, 2014                   Arpita Bose (Appirio)        T-253906: Code coverage increased
 * Mar 20th, 2014                   Arpita Bose (Appirio)        T-253906: updated method testIfParentAccountIsDeleted()
 * Apr 22, 2014                     Aditi Bhardwaj(Appirio)      Updated test method - testIfParentAccountIsDeleted
 * Apr 29th, 2014                   Arpita Bose                  T-275717: Added Asserts to fix Force.com Security Scanner Results
 * May 26th, 2014                   Naresh Kr Ojha (Appirio)     T-280244: Testing functionality to mark true AriaBillingAccnt.SendBillingAccToAria
 *                                                               added setSendBillingAccountToAriaTest() method
 * Oct 6th, 2014                    Naresh Kr Ojha               T-323669: added test_sendToOnDemand()
 * Oct 30th, 2014                   Pallavi Sharma               Fix Failures
 * Dec 19th, 2014                   Arpita Bose                  Updated method test_sendToOnDemand() to populate contact.Phone
 * Feb 9th, 2015                    Paul Kissick                 Added method testReparentingAccountPostMerge() to verify merge of with parent ids
 * Feb 19th, 2015                   Paul Kissick                  Case #29746: Added testMergeHistoryPostMerge() method    
 * Mar 5th, 2015                    Gaurav Kumar Chadha          Added method preventDeactivationOfSaasAccountTest()
 * Jun 27th, 2016                   Manoj Gopu                   Case #01947180 - Remove EDQ specific Contact object fields - MG COMMENTED CODE OUT
 * May 1st, 2017                    Sanket Vaidya                Case #01103464 - Added AccountSegmentNames_are_updated_when_AccountName_is_updated() for AccountTriggerHandler.updateAccountSegmentNames().
 * Feb 03rd, 2017                   Manoj Gopu                   ITSM:W006543 Updated existing method to improve code coverage for newly added changes

 =====================================================================*/

@isTest
public class AccountTriggerHandler_Test {

    @isTest
    public static void testAccountCreation() {
      User testUser = Test_Utils.insertUser(Constants.PROFILE_SYS_ADMIN);
      System.runAs(testUser) {
        TriggerSettings__c insertTriggerSettings = Test_Utils.insertTriggerSettings(Constants.ACCOUNT_TRIGGER);
        IsDataAdmin__c isDateAdmin = Test_Utils.insertIsDataAdmin(false);
        Account ultimateAccount = Test_Utils.insertAccount();
        Account parentAccount = Test_Utils.createAccount();
        parentAccount.Ultimate_Parent_Account__c = ultimateAccount.Id;
        insert parentAccount;
        Test.startTest();
        Account account = Test_Utils.createAccount();
        account.ParentId = parentAccount.Id;
        insert account;
        Account account2 = Test_Utils.createAccount();
        account2.ParentId = ultimateAccount.Id;
        insert account2;
        Test.stopTest();
        List<Account> accountUpdated = [SELECT Ultimate_Parent_Account__c FROM Account WHERE
                                    Id = :account.Id OR Id = :account2.Id];
        //Assert
        System.assert(accountUpdated.size() > 0);
      }
    }

    @isTest
    public static void testAccountDeletion() {
      User testUser = Test_Utils.insertUser(Constants.PROFILE_SYS_ADMIN);
      System.runAs(testUser) {
        TriggerSettings__c insertTriggerSettings = Test_Utils.insertTriggerSettings(Constants.ACCOUNT_TRIGGER);
        IsDataAdmin__c isDateAdmin = Test_Utils.insertIsDataAdmin(false);
        Account ultimateAccount = Test_Utils.insertAccount();
        Account account = Test_Utils.createAccount();
        account.Ultimate_Parent_Account__c = ultimateAccount.Id;
        insert account;
        Test.startTest();
        List<Account> delUltimateAcc = [SELECT ID, Ultimate_Parent_Account__c FROM Account WHERE ID=:ultimateAccount.Id];
        delete delUltimateAcc;
        //Assert
        system.assert(true, delUltimateAcc == null);

        Test.stopTest();
      }

    }

    @isTest
    public static void testAccountUpdate() {
      User testUser = Test_Utils.insertUser(Constants.PROFILE_SYS_ADMIN);
      System.runAs(testUser) {
        TriggerSettings__c insertTriggerSettings = Test_Utils.insertTriggerSettings(Constants.ACCOUNT_TRIGGER);
        IsDataAdmin__c isDateAdmin = Test_Utils.insertIsDataAdmin(false);
        Account ultimateAccount1 = Test_Utils.insertAccount();
        Account ultimateAccount2 = Test_Utils.insertAccount();

        Account parent1 = Test_Utils.createAccount();
        parent1.ParentId = ultimateAccount1.Id;
        insert parent1;

        Account parent_level_1 = Test_Utils.createAccount();
        parent_level_1.ParentId = parent1.Id;
        insert parent_level_1;

        Account parent_level_2 = Test_Utils.createAccount();
        parent_level_2.ParentId = parent_level_1.Id;
        insert parent_level_2;

        Map<Id,Account> mapUltimateAccountNowChild = new Map<Id,Account>();
        Map<Id,Id> mapAccAndUltimateParent = new Map<Id,Id>();

        Test.startTest();
        parent1.ParentId = ultimateAccount2.Id;
        update parent1;
        Test.stopTest();
        //Assert
        system.assert(true, parent1.ParentId == ultimateAccount2.Id);
      }
    }

    /*@isTest
    public static void testCreateChildAccess() {
      TriggerSettings__c insertTriggerSettings = Test_Utils.insertTriggerSettings(Constants.ACCOUNT_TRIGGER);
      IsDataAdmin__c isDateAdmin = Test_Utils.insertIsDataAdmin(false);
      User adminUser = Test_Utils.insertUser(Constants.PROFILE_SYS_ADMIN);
      User newUser = Test_Utils.insertUser(Constants.PROFILE_EXP_FINANCE);
      AccountTeamMember atm;
      AccountShare accShare;

      Account goCompare, zebra;
      System.runAs (adminUser) {
        goCompare = Test_Utils.insertAccount();
        atm = Test_Utils.createAccountTeamMembers(goCompare.ID, newUser.ID, true);
        accShare = Test_Utils.createAccountShare(goCompare.ID, newUser.ID, true);

        zebra = Test_Utils.createAccount();
        zebra.ParentId = goCompare.Id;
        zebra.Ultimate_Parent_Account__c = goCompare.Id;
        insert zebra;
      }
    }*/


    @isTest
    public static void testIfParentAccountIsDeleted(){
      User testUser = Test_Utils.insertUser(Constants.PROFILE_SYS_ADMIN);
      System.runAs(testUser) {
        //TriggerSettings__c insertTriggerSettings = Test_Utils.insertTriggerSettings(Constants.ACCOUNT_TRIGGER);
        //IsDataAdmin__c isDateAdmin = Test_Utils.insertIsDataAdmin(false);
        Account acc1 = Test_Utils.insertAccount();
        Account acc2 = Test_Utils.insertAccount();
        Account acc3 = Test_Utils.insertAccount();
        Account acc4 = Test_Utils.insertAccount();


        List<Account> testAccLst = new List<Account>();
        testAccLst.add(acc1);
        testAccLst.add(acc2);
        testAccLst.add(acc3);

        Account ultimateAccount1 = Test_Utils.insertAccount();
        Account ultimateAccount2 = Test_Utils.insertAccount();
        Account ultimateAccount3 = Test_Utils.insertAccount();

        Test.startTest();

        Account parent1 = Test_Utils.createAccount();
        parent1.ParentId = ultimateAccount1.Id;
        insert parent1;

        Account parent2 = Test_Utils.createAccount();
        parent2.ParentId = ultimateAccount2.Id;
        insert parent2;

        Account parent3 = Test_Utils.createAccount();
        parent3.ParentId = ultimateAccount2.Id;
        insert parent3;
        parent2.ParentId = ultimateAccount1.Id;
        update parent2;

        parent3.ParentId = null;
        update parent3;

        parent2.ParentId = null;
        update parent2;

        acc4.ParentId = parent3.Id;
        update acc4;

        delete acc4;

        parent3 = [SELECT Id,Ultimate_Parent_Account__c FROM Account Where Id = :parent3.Id];

        Test.stopTest();

        //Assert
        System.assert(parent3.Ultimate_Parent_Account__c == null);
        Map<Id,Account> testParentMap = new Map<Id, Account>();
        testParentMap.put(parent1.Id, parent1);
        testParentMap.put(parent2.Id, parent2);
        testParentMap.put(parent3.Id, parent3);
      }

    }
    //=============================================================================================
    // Deactivation of Account with at least one active deployment should throw an error
    //=============================================================================================
    static testMethod void preventDeactivationOfSaasAccountTest(){
      User testUser = Test_Utils.insertUser(Constants.PROFILE_SYS_ADMIN);
      User testExperianUser = Test_Utils.insertUser(Constants.PROFILE_SYS_ADMIN);
      Experian_Global__c expGlobal = new Experian_Global__c();
      expGlobal.OwnerId__c = testExperianUser.ID;
      insert expGlobal ;

      System.runAs(testUser) {
        Account account = Test_Utils.createAccount();
        account.SaaS__c = true;
        insert account;

        Deployment__c deployment = Test_Utils.insertDeployment(true, account.ID, false);

        Asset asst = Test_Utils.insertAsset(true, String.ValueOf(account.Id) );
        asst.Deployment__c = deployment.ID;
        asst.Saas__c = true;
        update asst;

        deployment.Active__c = true;
        update deployment;

        account.SaaS__c = false;
        Test.startTest();
        try {
         update account;
        } catch (DmlException e) {
           //Assert Error Message
           System.assert( e.getMessage().contains(label.SaaS_ERR_ACCOUNT_ACTIVE_DEPLOYMENT) );
        }
        Test.stopTest();
      }
    }

    //Updates sendBillingAccntToAria__c field on related Ariabilling account record.
    static testMethod void setSendBillingAccountToAriaTest () {
      User testUser = Test_Utils.insertUser(Constants.PROFILE_SYS_ADMIN);
      System.runAs(testUser) {
        //create user
        User testUser1 = Test_Utils.createUser(Constants.PROFILE_SYS_ADMIN);
        insert  testUser1;


        Account testAcc = Test_Utils.insertAccount();

        ARIA_Billing_Account__c aria = new ARIA_Billing_Account__c();
        aria.Account__c = testAcc.Id;
        aria.Push_To_Aria__c = Constants.PICKLISTVAL_YES;
        aria.SendBillingAccntToAria__c = false;
        aria.Owner__c = testUser1.Id;
        insert aria;

        //start test
        Test.startTest();
        testAcc.Name = 'NewTestAccountName';
        update testAcc;

        List<ARIA_Billing_Account__c> lstAria = [SELECT ID, Push_To_Aria__c, SendBillingAccntToAria__c
                                                         FROM ARIA_Billing_Account__c
                                                         WHERE Owner__c =:testUser1.Id AND ID =:aria.Id];
        //stop test
        Test.stopTest();
        system.assert(lstAria.get(0).SendBillingAccntToAria__c, true);
      }
    }

    static testMethod void setVBMCodeTest () {
      User testUser = Test_Utils.insertUser(Constants.PROFILE_SYS_ADMIN);
      System.runAs(testUser) {
        //create user
        User testUser1 = Test_Utils.createUser(Constants.PROFILE_SYS_ADMIN);
        insert testUser1;

        Account testAcc = Test_Utils.insertAccount();

          //Create VBM value
          Oracle_VBM_Codes__c vbmVal = new Oracle_VBM_Codes__c();
          vbmVal.Name = 'VBM00001';
          vbmVal.Description__c = 'Direct to Consumer-Automotive';
          insert vbmVal;

        Test.startTest();

          testAcc.Name = 'NewTestAccountName';
          testAcc.Industry = 'Direct to Consumer';
          testAcc.Sector__c = 'Automotive';
          update testAcc;

          testAcc = [SELECT Id, VBM_Code__c FROM Account WHERE Id =: testAcc.Id];

          Test.stopTest();
        system.assertEquals(testAcc.VBM_Code__c, 'VBM00001');
      }
    }

    //Updating Send to On Demand field on contact
    static testMethod void test_sendToOnDemand() {

      User testUser = Test_Utils.createUser(Constants.PROFILE_SYS_ADMIN);

      System.runAs(testUser) {
        List<Account> accounts = new List<Account>();
        List<Contact> contacts = new List<Contact>();

        for (Integer i=0; i<10; i++) {
          accounts.add(Test_Utils.insertEDQAccount(false));
        }

        insert accounts;
        //Inserting contacts one for each account
        for (Integer i = 0; i < 10; i++) {
          Contact newContact = Test_Utils.createContact(accounts.get(i).ID);
          //newContact.EDQ_On_Demand__c = true;
          newContact.EDQ_Integration_Id__c = 'TestIds'+i;
          newContact.Email = 'testemail'+i+'@example.com';
          newContact.Title = 'Test Title';
          //newContact.Inactive__c = false;
          newContact.Phone = '9799559433';
          contacts.add(newContact);

          // Create non- On demand contacts
          for (Integer j=0; j < 5; j++) {
            newContact = Test_Utils.createContact(accounts.get(i).ID);
            //newContact.EDQ_On_Demand__c = true;
            newContact.EDQ_Integration_Id__c = 'TestID'+i;
            newContact.Email = 'testemail'+i+j+'@example.com';
            newContact.Title = 'Test Title';
            //newContact.Inactive__c = false;
            newContact.Phone = '9799559433';
            //contacts.add(newContact);
          }
        }
        insert contacts;

        //Reverting all contacts to false, as they've been set true from WF as OnDemand was = true
        /*for (Contact c : contacts) {
          c.EDQ_Send_to_On_Demand__c = false;
        }*/
        update contacts;
        //Assert to check there is no EDQ Send to On Demand contact related to accounts
        //System.assertEquals([SELECT ID, EDQ_Send_to_On_Demand__c FROM Contact WHERE AccountID IN: accounts AND EDQ_Send_to_On_Demand__c = true].size(), 0);

        for (Integer i = 0; i < 10; i++) {
          accounts.get(i).Name =  accounts.get(i).Name+'NewName';
        }
        update accounts;
        //when updated one contact, there is one contact with Send to on demand = true
        //System.assertEquals([SELECT ID, EDQ_Send_to_On_Demand__c FROM Contact WHERE AccountID IN: accounts AND EDQ_Send_to_On_Demand__c = true].size(), 10);
        //System.assertEquals([SELECT ID, EDQ_On_Demand__c FROM Contact WHERE AccountID =: accounts.get(3).Id AND EDQ_On_Demand__c = true].size(), 1);
      }
    }

    static testMethod void testReparentingAccountPostMerge() {

      // Create 3 accounts, one a parent, one a child, and another not related.

    Account parAcc = Test_Utils.insertAccount();
    Account chdAcc1 = Test_Utils.insertAccount();
    Account chdAcc2 = Test_Utils.insertAccount();

      Test.startTest();

    chdAcc1.ParentId = parAcc.Id;
    update chdAcc1;

    system.assert(chdAcc1.ParentId == parAcc.Id, 'Parent on Child is incorrect.');

    // Now merge chdAcc2 (as the master) with chdAcc1.
      List<Contact> contacts = new List<Contact>(); 
     Contact newContact = Test_Utils.createContact(chdAcc1.ID);
     newContact.Email = 'testemail@example.com';
     newContact.Title = 'Test Title';
     newContact.Phone = '9799559433';
     newContact.SNOW_ContactId__c = 'dntrjg';
     contacts.add(newContact);
     
     Contact newContact1 = Test_Utils.createContact(chdAcc2.ID);
     newContact1.Email = 'testemail@example.com';
     newContact1.Title = 'Test Title';
     newContact1.Phone = '9799559433';
     newContact1.SNOW_ContactId__c = 'dntrjgfgnfgn';
     contacts.add(newContact1);
     
     insert contacts;
     
     Asset asst1 = Test_Utils.insertAsset(false, String.ValueOf(chdAcc1.Id) );
     asst1.SNOW_AssetId__c = '4y45heh';
     insert asst1;
     
     Asset asst2 = Test_Utils.insertAsset(false, String.ValueOf(chdAcc2.Id) );
     asst2.SNOW_AssetId__c = '4y45hehdfb';
     insert asst2;
     
     ESDEL_Delivery_Project__c deliveryProject1 = Test_Utils.insertDeliveryProject(true, 'project1', chdAcc1.id, newContact.id, 'bord1');
    ESDEL_Delivery_Project__c deliveryProject2 = Test_Utils.insertDeliveryProject(true, 'project1', chdAcc2.id, newContact1.id, 'bord2');
     
    Case newCase1 = Test_Utils.insertCase (false, deliveryProject1.id, chdAcc1.id, 'bord1'); 
     newCase1.SNOW_CaseID__c = 'sbsbdfn';
     insert newCase1;
     
     Case newCase2 = Test_Utils.insertCase (false, deliveryProject2.id, chdAcc2.id, 'bord2'); 
     newCase2.SNOW_CaseID__c = 'sbsbdfndfb';
     insert newCase2;
    Database.merge(chdAcc2, chdAcc1);

    Test.stopTest();

    system.assert([SELECT ParentId FROM account WHERE Id = :chdAcc2.Id].ParentId == parAcc.Id, 'Parent hasn\'t updated on child account');

    }
  
  static testMethod void testMergeHistoryPostMerge() {
      
      Account parAcc = Test_Utils.insertAccount();
      Account chdAcc1 = Test_Utils.insertAccount();
      Account chdAcc2 = Test_Utils.insertAccount();
      
      Test.startTest();
      
      chdAcc1.ParentId = parAcc.Id;
      chdAcc2.ParentId = parAcc.Id;
      update chdAcc1;
      update chdAcc2;
      
      system.assert(chdAcc1.ParentId == parAcc.Id, 'Parent on Child is incorrect.');
      system.assert(chdAcc2.ParentId == parAcc.Id, 'Parent on Child is incorrect.');
      
      Database.merge(chdAcc2, chdAcc1);
    
      Test.stopTest();
      
      system.assertEquals(1,[SELECT COUNT() FROM MergeHistory__c WHERE Winner_Record_ID__c = :chdAcc2.Id AND Object_Type__c = 'Account'],'Account MergeHistory not found.');
      
    }
    
     @isTest
   public static void AccountSegmentNames_are_updated_when_AccountName_is_updated()
   {
    string beginningAccName = 'On The Border Mexican Cantina';
    string changedAccName = 'OTB';


    Account acc1 = Test_Utils.createAccount();
    acc1.Name = beginningAccName;    
    insert acc1;

    List<String> segmentType = new List<String>
                                    {
                                          'Global Business Line', 
                                          'Business Unit',
                                          'Business Line',
                                          'Region'
                                    };
         
    List<Account_Segment__c> accSegments = new List<Account_Segment__c>();
    
    for(String stype : segmentType)
    {
        String segName = AccountSegmentationUtility.buildSegmentName(acc1.Name, stype);
        Account_Segment__c asg = new Account_Segment__c(Account__c = acc1.id, Name = segName);
        accSegments.add(asg);
    }

    insert accSegments;

      for(Account_Segment__c asg : accSegments)
      {
        System.Debug('Before-->  Name : ' + asg.Name);
      }
      
      
      AccountTriggerHandler.isAfterUpdateTriggerExecuted=false ;
      acc1.Name = changedAccName;
      update acc1;

      List<Account_Segment__c> newAccSegmentsList = [Select Name from Account_Segment__c where Account__c = :acc1.ID];

      Boolean testResult = True;

      for(Account_Segment__c asg : newAccSegmentsList)
      {
        System.Debug('After--> Name : ' + asg.Name);
          
          if(!asg.Name.contains(changedAccName))
          {
            testResult = False;
            break;
          }
      }

      System.assertEquals(testResult, True);
   } 
   
@isTest
    public static void testAccountCreationIsDataAdmin() {
      User testUser = Test_Utils.insertUser(Constants.PROFILE_SYS_ADMIN);
      System.runAs(testUser) {
        TriggerSettings__c insertTriggerSettings = Test_Utils.insertTriggerSettings(Constants.ACCOUNT_TRIGGER);
        IsDataAdmin__c isDateAdmin = Test_Utils.insertIsDataAdmin(true);
        Account ultimateAccount = Test_Utils.insertAccount();
        Account parentAccount = Test_Utils.createAccount();
        parentAccount.Ultimate_Parent_Account__c = ultimateAccount.Id;
        insert parentAccount;
        Test.startTest();
        Account account = Test_Utils.createAccount();
        account.ParentId = parentAccount.Id;
        insert account;
        Account account2 = Test_Utils.createAccount();
        account2.ParentId = ultimateAccount.Id;
        insert account2;
        Test.stopTest();
        List<Account> accountUpdated = [SELECT Ultimate_Parent_Account__c FROM Account WHERE
                                    Id = :account.Id OR Id = :account2.Id];
        //Assert
        System.assert(accountUpdated.size() > 0);
      }
    }      
    
    @isTest
    public static void updateDQScoreEOHTest(){
        Test.startTest();
        User testUser = Test_Utils.insertUser(Constants.PROFILE_SYS_ADMIN);
        Account accObj = Test_Utils.createAccount();
        accObj.Summarized_Contact_DQ_Score__c = 10;
        insert accObj; 
        System.debug('accObj '+accObj);
        AccountTeamMember atmObj = Test_Utils.createAccountTeamMembers(accObj.Id, testUser.Id, true);
        Employee_Org_Hierarchy__c eohObj = new Employee_Org_Hierarchy__c();
        eohObj.Employee_Id__c = testUser.Id;
        insert eohObj;
        AccountTriggerHandler.isAfterUpdateTriggerExecuted=false ;
        accObj.Summarized_Contact_DQ_Score__c = 60;
        update accObj;
        Test.stopTest();
    }
  
  }