/***************************************************************************************************
 * Name: Mohammed Irfan
 * Date: 12/Dec/2013
 * Description: Test for Adding Owner to Contact Team.
 * Date Modified       Modified By                  Description of the update
 * Sep 8th, 2014      Noopur (Appirio)              Changed the Class name. 
 *                                                  Added the test method to verify the Container Account 
 *                                                  Functionality added for task T-313856
 * Sep 8th, 2014      Naresh kr Ojha                T-317847: Added test method to test onDemandContact method.
 * Dec 12th,2014      Noopur                        T-339472 : added method test_orderOnDemandSync()
 * Dec 19th,2014      Arpita Bose                   Updated methods test_onDemandContact() and test_orderOnDemandSync() to populate 
 *                                                  con.Phone for OnDemand Decider contact
 * Feb 9th, 2015      Paul Kissick                  Added method testContactMergeChecks() to test cleanup of contacts post merge.
 * Feb 19th, 2015     Paul Kissick                  Case #29746 - Changed testContactMergeChecks() to also check for mergehistory record. 
 * Apr 7th, 2015      Paul Kissick                  Case #50069 : Better testing of the contact merge checks.\
 * Apr 29th, 2015     Suminder Singh(Appirio)       Fixed test_onDemandContact() for test class failures
 * Sep 07th, 2015     Naresh Kr Ojha                Updated class to test ContactTriggerHandler. Uncommented two test methods too.
 * Oct 2nd, 2015      Paul Kissick                  Case #10121: Tests for Set Domain on Account if new on a contact.
 * Jun 24th, 2016     Manoj Gopu                    Case #01947180 - Remove EDQ specific Contact object fields - MG COMMENTED CODE OUT
 * Aug 19th, 2016     Tyaga Pati                    CRM2.0W-005402 - Removed all References to Inactive__c because field will not be used in CRM anymore
 * Feb 07rd, 2017     Manoj Gopu                    ITSM:W006544 Updated existing method to improve code coverage for newly added changes
 * Mar 16th, 2017     Ryan (Weijie) Hu              W-007535: Test method for changes made for this story
 * Jun 06th, 2017     Manoj Gopu                    Fixed testmethod testUpdateConsumerContactParentAccount_2 Failure to avoid the Duplicate rule
 * - COMMENTED OUT Feb. 7th, 2018      James Wills                  Case 15531100 :  Prevent Contact Insert Error.
 * Feb. 14th, 2018     James Wills                  Case 15564878: Coverage for beforeInsertIsDataAdmin.
 ****************************************************************************************************/
@isTest(seeAllData=false)
private class ContactTriggerHandler_Test {

    static testMethod void runTest() {
      Account a = Test_Utils.insertAccount();
      User usr = [select id from User where IsActive=true limit 1];
      Contact con = new Contact(FirstName='First',LastName='Last',OwnerId=usr.id);
      insert con;
      
    }

    //=======================================================================
    // Testing onDemandContact to check other contacts should not be onDemand
    //=======================================================================
    static testMethod void test_onDemandContact () {
      //create test user 
      User testUser = Test_Utils.createUser(Constants.PROFILE_SYS_ADMIN);
      insert  testUser;
      
      System.runAs(testUser) {
        Account testAccount = Test_Utils.insertEDQAccount(true);

        Contact testContact0;
        List<Contact> contactsToInsert = new List<Contact>();
        for (Integer i = 0; i < 20; i++) {
          testContact0 = Test_Utils.createContact(testAccount.ID);
          /*testContact0.EDQ_On_Demand__c = false;
          if (i == 0) {
            testContact0.EDQ_On_Demand__c = true;
          }*/
          testContact0.Email = 'testemail00'+i+'@test.com';
          testContact0.Title = 'testTitle';
          // testContact0.Inactive__c = false; //W-005402
          testContact0.EDQ_Integration_Id__c = String.valueOf(Math.random());
          testContact0.Phone = '9799559433';
          contactsToInsert.add(testContact0);
        }
        insert contactsToInsert;
        system.debug('***contactsToInsert>>>' +contactsToInsert);
        
      //  List<Contact> onDemandContacts = [SELECT ID, Email FROM Contact WHERE ID IN: contactsToInsert];
        
      // System.assertEquals(1, onDemandContacts.size());
       
        
        Test.startTest();
        /*Contact testContact1 = Test_Utils.insertEDQContact(testAccount.ID, false); 
        //testContact1.EDQ_On_Demand__c = true;
        testContact1.Email = 'testemail001@test.com';
        testContact1.Title = 'testTitle';
        //testContact1.Inactive__c = false; //W-005402
        testContact1.Phone = '9723876478';
        insert testContact1;*/
        //contactsToInsert[1].EDQ_On_Demand__c = true;
        update contactsToInsert[1];
        Test.stopTest();
        //List<Contact> onDemandContacts1 = [SELECT ID, Email FROM Contact WHERE ID = :contactsToInsert[0].Id];
       // System.assert(onDemandContacts1.size() == 0);
        List<Contact> con = [SELECT Id, AccountId 
                                   FROM Contact
                                   WHERE AccountID =: testAccount.ID];
        system.debug('con >>>' +con);
                       
        System.assert(Limits.getDMLStatements() < 20);
        //Insertion of new OnDemand Contact should make previous one false on EDQ_On_Demand__c
        contactsToInsert = [SELECT ID FROM Contact WHERE ID IN: contactsToInsert];
        system.debug('contactsToInsert>>>' +contactsToInsert);
        
        
        //for (Integer i = 0; i< 200; i++) {
        //  System.assertEquals(contactsToInsert.get(0).EDQ_On_Demand__c, false);
        //}
        delete contactsToInsert;
      }
    }
    
    //=======================================================================
    // Testing onDemandContact to check other contacts should not be onDemand
    //=======================================================================
    static testMethod void test_orderOnDemandSync () {
      //create test user 
      User testUser = Test_Utils.createUser(Constants.PROFILE_SYS_ADMIN);
      insert  testUser;
      
      System.runAs(testUser) {
        Account testAccount = Test_Utils.insertEDQAccount(true);

        Contact testContact0;
        List<Contact> contactsToInsert = new List<Contact>();
        for (Integer i = 0; i < 5; i++) {
          testContact0 = Test_Utils.createContact(testAccount.ID);
          /*testContact0.EDQ_On_Demand__c = false;
          if (i == 0) {
            testContact0.EDQ_On_Demand__c = true;
          }*/
          testContact0.Email = 'testemail00'+i+'@test.com';
          testContact0.Title = 'testTitle';
          //testContact0.Inactive__c = false;//W-005402
          testContact0.EDQ_Integration_Id__c = String.valueOf(Math.random());
          //testContact0.EDQ_Send_to_On_Demand__c = true;
          testContact0.Phone = '9799559433';
          contactsToInsert.add(testContact0);
        }
        insert contactsToInsert;
        
        List<Order__c> orderList = new List<Order__c>();
        for (Integer i=0; i<5; i++) {
          Order__c ordObj = new Order__c();
          ordObj.contact__c = contactsToInsert[i].Id;
          ordObj.Account__c = contactsToInsert[i].AccountId;
          ordObj.Name = 'testOrder'+i;
          ordObj.Type__c = 'New';
          ordObj.PO_Required__c = 'No';
          ordObj.Transactional_Sale__c = true;
          orderList.add(ordObj);
        }
        insert orderList;
        
        List<Order_Line_Item__c> oliList = new List<Order_Line_Item__c>();
        for (Integer i=0; i<5; i++) {
          Order_Line_Item__c oliObj = new Order_Line_Item__c();
          oliObj.Order__c = orderList[i].Id;
          oliObj.EDQ_On_Demand_Product__c = true;
          oliObj.Type__c = 'One-off Sale';
          oliList.add(oliObj);
        }
        insert oliList;

        Test.startTest();
        /*for (Integer i=0; i<5; i++) {
          contactsToInsert[i].EDQ_Send_to_On_Demand__c = false;
        }*/
        update contactsToInsert;
        
        Test.stopTest();
        
        /*orderList = [SELECT EDQ_Send_to_On_Demand__c, ID FROM Order__c WHERE Contact__c IN: contactsToInsert];
        for (Integer i = 0; i< 5; i++) {
          System.assertEquals(orderList.get(i).EDQ_Send_to_On_Demand__c, true);
        }*/
        contactsToInsert.get(0).Title = 'MyTitle';
        update contactsToInsert;
      }
    }
   
    
    //=======================================================================
    // Test for merging contact related information
    //=======================================================================
    static testMethod void testContactMergeChecks () {
      
      
      
      // we need 2 contacts, an address on each, and a role on each.
      Account acc1 = Test_Utils.insertAccount();
      Contact cont1 = new Contact(FirstName = 'Test1', LastName = 'Contact', AccountId = acc1.Id);
      Contact cont2 = new Contact(FirstName = 'Test2', LastName = 'Contact', AccountId = acc1.Id);
      
      insert new Contact[]{cont1,cont2};
      
      
      Address__c contAddr = Test_Utils.insertAddress(true);
      
      // Add the same address to both records.
      Contact_Address__c cAdd1 = Test_Utils.insertContactAddress(true,contAddr.Id,cont1.Id);
      Contact_Address__c cAdd2 = Test_Utils.insertContactAddress(true,contAddr.Id,cont2.Id);
      
      system.assertEquals(1,[SELECT COUNT() FROM Contact_Team__c WHERE Contact__c = :cont1.Id],'There should only be 1 Contact Team member.');
      system.assertEquals(1,[SELECT COUNT() FROM Contact_Team__c WHERE Contact__c = :cont2.Id],'There should only be 1 Contact Team member.');
      
      system.assertEquals(1,[SELECT COUNT() FROM Contact_Address__c WHERE Contact__c = :cont1.Id],'There should only be 1 Contact Address.');
      system.assertEquals(1,[SELECT COUNT() FROM Contact_Address__c WHERE Contact__c = :cont2.Id],'There should only be 1 Contact Address.');
      
      // now, lets merge the 2 contacts, 
      system.debug('**** Your IsDataAdmin setting: '+(((Boolean)IsDataAdmin__c.getInstance().IsDataAdmin__c) ? ' ENABLED ' : ' DISABLED '));
      IsDataAdmin__c disableIsDataAdm = new IsDataAdmin__c(SetupOwnerId = UserInfo.getUserId(), IsDataAdmin__c = false);
      insert disableIsDataAdm;
      
      ESDEL_Delivery_Project__c deliveryProject1 = Test_Utils.insertDeliveryProject(true, 'project1', acc1.id, cont1.id, 'bord1');
      ESDEL_Delivery_Project__c deliveryProject2 = Test_Utils.insertDeliveryProject(true, 'project1', acc1.id, cont2.id, 'bord2');
    
      Case newCase1 = Test_Utils.insertCase (false, deliveryProject1.id, acc1.id, 'bord1');  
      newCase1.ContactId = cont1.Id;
      newCase1.SNOW_CaseID__c = '363437';
      //insert newCase1;
      
      Case newCase2 = Test_Utils.insertCase (false, deliveryProject2.id, acc1.id, 'bord2'); 
      newCase2.ContactId = cont2.Id;
      newCase2.SNOW_CaseID__c = 'dht57856858';
      //insert newCase2;
      insert new Case[]{newCase1,newCase2};
      
      Test.startTest();

      Database.merge(cont1,cont2);

      Test.stopTest();

      system.assertEquals(1,[SELECT COUNT() FROM Contact],'There should only be 1 contact left.');

      system.assertEquals(1,[SELECT COUNT() FROM Contact_Team__c WHERE Contact__c = :cont1.Id],'There should only be 1 Contact Team member, after merge');
      system.assertEquals(1,[SELECT COUNT() FROM Contact_Address__c WHERE Contact__c = :cont1.Id],'There should only be 1 Contact Address, after merge');
      
      system.assertEquals(0,[SELECT COUNT() FROM Contact_Team__c WHERE Contact__c = :cont2.Id],'There shouldn\'t be any contact team members left on losing record.');
      system.assertEquals(0,[SELECT COUNT() FROM Contact_Address__c WHERE Contact__c = :cont2.Id],'There shouldn\'t be any contact addresses left on losing record.');
      
      // MergeHistory should be created too 
      system.assertEquals(1,[SELECT COUNT() FROM MergeHistory__c WHERE Winner_Record_ID__c = :cont1.Id],'Unable to find MergeHistory record');

      
    } 
    static testMethod void refreshOppScoreCalculations () {
    }
    
    private static testMethod void testAccountDomainFromContact_SingleContact() {
      
      Account a = Test_Utils.insertAccount();
      system.assertEquals(null,a.Domain__c,'Domain field should be null:' + a.Domain__c);
      Test.startTest();
      Contact c = Test_Utils.insertContact(a.Id);
      Test.stopTest();
      system.assertNotEquals(null, c.Email, 'Contact email should not be null:' +c.Email);
      
      String emailDomain = c.Email.substringafterLast('@').toLowerCase();
      String testDomain = [SELECT Domain__c FROM Account WHERE Id = :a.Id LIMIT 1].Domain__c;
      system.assertEquals(emailDomain, testDomain, 'Domain is not correct: '+emailDomain + ' vs '+testDomain);
      
    }
    
    private static testMethod void testAccountDomainFromContact_MultiContact() {
      
      Account a = Test_Utils.insertAccount();
      system.assertEquals(null,a.Domain__c,'Domain field should be null:' + a.Domain__c);
      Test.startTest();
      Contact c = Test_Utils.insertContact(a.Id);
      Contact c2 = Test_Utils.insertContact(a.Id);
      Test.stopTest();
      system.assertNotEquals(null, c.Email, 'Contact email should not be null:' +c.Email);
      system.assertNotEquals(null, c2.Email, 'Contact email should not be null:' +c2.Email);
      
      String emailDomain1 = c.Email.substringafterLast('@').toLowerCase();
      String emailDomain2 = c2.Email.substringafterLast('@').toLowerCase();
      
      String testDomain = [SELECT Domain__c FROM Account WHERE Id = :a.Id LIMIT 1].Domain__c;
      system.assert(testDomain.contains(emailDomain1), 'Domain is not added: '+emailDomain1 + ' inside '+testDomain);
      system.assert(testDomain.contains(emailDomain2), 'Domain is not added: '+emailDomain2 + ' inside '+testDomain);
      
    }
    
    private static testMethod void testAccountDomainFromContact_EditMultiContact() {
      
      Account a = Test_Utils.insertAccount();
      system.assertEquals(null,a.Domain__c,'Domain field should be null:' + a.Domain__c);
      Test.startTest();
      Contact c = Test_Utils.insertContact(a.Id);
      Contact c2 = Test_Utils.insertContact(a.Id);
      c.Email = 'test@newdomainfortesting.com';
      c2.Email = null;
      update new List<Contact>{c,c2};
      Test.stopTest();
      system.assertNotEquals(null, c.Email, 'Contact email should not be null:' +c.Email);
      system.assertEquals(null, c2.Email, 'Contact email should be null:' +c2.Email);
      
      String emailDomain = c.Email.substringafterLast('@').toLowerCase();
      
      String testDomain = [SELECT Domain__c FROM Account WHERE Id = :a.Id LIMIT 1].Domain__c;
      system.assertEquals(emailDomain, testDomain, 'Domain is not correct: '+emailDomain + ' vs '+testDomain);
      // system.assert(testDomain.contains(emailDomain2), 'Domain is not added: '+emailDomain2 + ' inside '+testDomain);
      
    }
    
    private static testMethod void testAccountDomainFromContact_DeletedContact() {
      
      Account a = Test_Utils.insertAccount();
      system.assertEquals(null,a.Domain__c,'Domain field should be null:' + a.Domain__c);
      Test.startTest();
      Contact c = Test_Utils.insertContact(a.Id);
      Contact c2 = Test_Utils.insertContact(a.Id);
      delete c2;
      Test.stopTest();
      system.assertNotEquals(null, c.Email, 'Contact email should not be null:' +c.Email);
      
      String emailDomain = c.Email.substringafterLast('@').toLowerCase();
      
      String testDomain = [SELECT Domain__c FROM Account WHERE Id = :a.Id LIMIT 1].Domain__c;
      system.assertEquals(emailDomain, testDomain, 'Domain is not correct: '+emailDomain + ' vs '+testDomain);
      
    }

    private static testMethod void testUpdateConsumerContactParentAccount_1() {
      //RecordType consumer_contact_rt = [SELECT Description,DeveloperName,Id,Name,SobjectType FROM RecordType WHERE SobjectType = 'Contact' AND DeveloperName = 'Consumer_Contact'];
      //RecordType consumer_account_rt = [SELECT Description,DeveloperName,Id,Name,SobjectType FROM RecordType WHERE SobjectType = 'Account' AND DeveloperName = 'Consumer_Account'];
      
      //Account a = Test_Utils.createAccount(); // for creating custom setting, etc.
      //a.RecordTypeId = consumer_account_rt.id;//Case 15531100
      //insert a;
        
      Account a = Test_Utils.insertAccount(); // for creating custom setting, etc.
      RecordType consumer_contact_rt = [SELECT Description,DeveloperName,Id,Name,SobjectType FROM RecordType WHERE SobjectType = 'Contact' AND DeveloperName = 'Consumer_Contact'];
     
      //Case 15564878
      system.debug('**** Your IsDataAdmin setting: '+(((Boolean)IsDataAdmin__c.getInstance().IsDataAdmin__c) ? ' ENABLED ' : ' DISABLED '));
      IsDataAdmin__c disableIsDataAdm = new IsDataAdmin__c(SetupOwnerId = UserInfo.getUserId(), IsDataAdmin__c = true);
      insert disableIsDataAdm;
     
         
      Contact c = new Contact();
      c.FirstName = 'testing cc';
      c.LastName = 'tt';
      c.RecordTypeId = consumer_contact_rt.Id;

      insert c;

      List<Account> acctList = [SELECT Id, Serasa_Consumer_Contact_Count__c, Serasa_Consumer_Active_Account__c FROM Account WHERE Serasa_Consumer_Active_Account__c = true];
      System.assertEquals(1, acctList.get(0).Serasa_Consumer_Contact_Count__c);
           
      disableIsDataAdm.IsDataAdmin__c = true;
      update disableIsDataAdm;
      
      Contact c2 = new Contact();
      c2.FirstName = 'Second testing cc';
      c2.LastName = 'Second tt';
      c2.RecordTypeId = consumer_contact_rt.Id;

      insert c2;
      
      List<Account> acctList2 = [SELECT Id, Serasa_Consumer_Contact_Count__c, Serasa_Consumer_Active_Account__c FROM Account WHERE Serasa_Consumer_Active_Account__c = true];
      System.assertEquals(2, acctList2.get(0).Serasa_Consumer_Contact_Count__c);

      
    }

    private static testMethod void testUpdateConsumerContactParentAccount_2() {      
      //RecordType consumer_contact_rt = [SELECT Description,DeveloperName,Id,Name,SobjectType FROM RecordType WHERE SobjectType = 'Contact' AND DeveloperName = 'Consumer_Contact'];
      //RecordType consumer_account_rt = [SELECT Description,DeveloperName,Id,Name,SobjectType FROM RecordType WHERE SobjectType = 'Account' AND DeveloperName = 'Consumer_Account'];
      
      //Account a = Test_Utils.createAccount(); // for creating custom setting, etc.
      //a.RecordTypeId = consumer_account_rt.id;//Case 15531100
      //insert a;
      
      Account a = Test_Utils.insertAccount(); // for creating custom setting, etc.
      RecordType consumer_contact_rt = [SELECT Description,DeveloperName,Id,Name,SobjectType FROM RecordType WHERE SobjectType = 'Contact' AND DeveloperName = 'Consumer_Contact'];
       
      Contact c = new Contact();
      c.FirstName = 'cc';
      c.LastName = 'bb';
      c.RecordTypeId = consumer_contact_rt.Id;

      insert c;

      c = new Contact();
      c.FirstName = 'yy11';
      c.LastName = 'll11';
      c.RecordTypeId = consumer_contact_rt.Id;

      insert c;
      List<Account> acctList = [SELECT Id, Serasa_Consumer_Contact_Count__c, Serasa_Consumer_Active_Account__c FROM Account WHERE Serasa_Consumer_Active_Account__c = true];
      System.assertEquals(2, acctList.get(0).Serasa_Consumer_Contact_Count__c);



      acctList.get(0).Serasa_Consumer_Contact_Count__c = 9700;
      update acctList;

      c = new Contact();
      c.FirstName = 'testing cc2';
      c.LastName = 'tt2';
      c.RecordTypeId = consumer_contact_rt.Id;

      insert c;
      acctList = [SELECT Id, Serasa_Consumer_Contact_Count__c, Serasa_Consumer_Active_Account__c FROM Account WHERE Serasa_Consumer_Active_Account__c = true];
      System.assertEquals(1, acctList.get(0).Serasa_Consumer_Contact_Count__c);//Case 15531100
    }
    
       //TP : Test Class update to cover for contact DQ Score summarization at account level
    private static testMethod void test_calcSummaryDQScoreOnAccount() {
      
      Account a = Test_Utils.insertAccount();
      Contact c = Test_Utils.insertContact(a.Id); 
      Contact c2 = Test_Utils.insertContact(a.Id);
      
      //Create a new address
      Address__c contAddr = Test_Utils.insertAddress(true);
      
      // Add the same address to both records.
      Contact_Address__c cAdd1 = Test_Utils.insertContactAddress(true,contAddr.Id,c.Id);
      Contact_Address__c cAdd2 = Test_Utils.insertContactAddress(true,contAddr.Id,c2.Id);
      
      
      List<Contact> setConRecs = new List<Contact>();

      Test.startTest();
        c.Department__c = 'Collections';
        setConRecs.add(c);
        c2.Department__c = 'Collections';
        setConRecs.add(c2);
      // ContactTriggerHandler.calcSummScoreOnAccountfuture(setAcntIds);
      Update setConRecs;
      Test.stopTest();
      Decimal score1 = [select Contact_DQ_Score__c from Contact where Id =: c.Id].Contact_DQ_Score__c ;
      Decimal score2 = [select Contact_DQ_Score__c from Contact where Id =: c2.Id].Contact_DQ_Score__c ;
      Decimal SummScore = (score1+score2)/2;
      system.debug('tyaga the score 1' + SummScore);
      Decimal AccontScore = [Select Summarized_Contact_DQ_Score__c from Account where Id=:a.Id].Summarized_Contact_DQ_Score__c;
      system.debug('tyaga the score 2' + AccontScore );
      system.assertEquals(SummScore,[Select Summarized_Contact_DQ_Score__c from Account where Id=:a.Id].Summarized_Contact_DQ_Score__c );
      
    }
    
}