({
	doInit: function(component, event, helper) {
		var contactToAdd;
		//var isThirdParty = component.get("v.isThirdParty");
		//var curUserContact = component.get("v.curUserContact");
		var applicantContact = component.get("v.applicantContact");

		/*
		if (curUserContact != null) {
			contactToAdd = {
	            'sobjectType': 'Membership_Contacts__c',
	            'Membership__c': component.get("v.membershipID"),
	            'Membership__r': null,
	            'Role__c': component.get("v.contactRole"),
	            'Email__c': curUserContact.Email,
	            'First_Name__c': curUserContact.FirstName,
	            'Last_Name__c': curUserContact.LastName,
	            'Phone_Number__c': curUserContact.Phone,
	            'isNewRecord': true
	        };

	        if (curUserContact.Contact_Addresses__r != null) {
	        	var curUserContactAddress = curUserContact.Contact_Addresses__r[0];
	        	contactToAdd.Address__c = curUserContactAddress.Contact_Address1__c;
	        	contactToAdd.City__c = curUserContactAddress.Contact_Address_City__c;
	        	contactToAdd.State__c = curUserContactAddress.Address__r.State__c;
	        	contactToAdd.Zip__c = curUserContactAddress.Address__r.Postcode__c;
	        }
		}
		*/
		
		if (applicantContact != null) {
			contactToAdd = {
	            'sobjectType': 'Membership_Contacts__c',
	            'Membership__c': component.get("v.membershipID"),
	            'Membership__r': null,
	            'Role__c': component.get("v.contactRole"),
	            'Email__c': applicantContact.Email__c,
	            'First_Name__c': applicantContact.First_Name__c,
	            'Last_Name__c': applicantContact.Last_Name__c,
	            'Phone_Number__c': applicantContact.Phone_Number__c,
	            'isNewRecord': true,
	            'Address__c': applicantContact.Address__c,
	        	'City__c' : applicantContact.City__c,
	        	'State__c': applicantContact.State__c,
	        	'Zip__c': applicantContact.Zip__c
	        };	  
	        
		}
		else {
			contactToAdd = {
	            'sobjectType': 'Membership_Contacts__c',
	            'Membership__c': component.get("v.membershipID"),
	            'Membership__r': null,
	            'Role__c': component.get("v.contactRole"),
	            'Is_Third_Party__c': component.get("v.isThirdParty"),
	            'isNewRecord': true
	        };
		}

		component.set("v.contactToAdd", contactToAdd);
	},

	save : function(component, event, helper) {
		var contactToAdd = component.get("v.contactToAdd");

		if (contactToAdd.First_Name__c == null || contactToAdd.Last_Name__c == null || contactToAdd.Email__c == null || contactToAdd.Phone_Number__c == null || contactToAdd.Address__c == null
			|| contactToAdd.City__c == null || contactToAdd.State__c == null || contactToAdd.Zip__c == null 
			|| (contactToAdd.Is_Third_Party__c && (contactToAdd.Third_Party_Account__c == null || contactToAdd.Third_Party_Web_Address__c == null || contactToAdd.Third_Party_Role__c == null)))
		{
			var resultsToast = $A.get("e.force:showToast");
            resultsToast.setParams({
                "type": "warning",
                "title": "Warning",
                "message": "You must fill out all information before saving."
            });
            resultsToast.fire(); 
		}
		else
		{
			component.getEvent("AddContactEvt").setParams(
	        {
	       		"record":contactToAdd
	       	}).fire();

			component.destroy();
		}
	},

	closeMe: function(component, event, helper) {
		component.destroy();
	},
})