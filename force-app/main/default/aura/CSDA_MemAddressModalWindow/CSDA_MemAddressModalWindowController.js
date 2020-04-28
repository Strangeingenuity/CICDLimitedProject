({
	doInit: function(component, event, helper) {
		var isSameBilling = component.get("v.isSameBilling");
		var thisMembership = component.get("v.thisMembership");

		var registeredAddress = null;

		if (thisMembership.Membership_Address__r != undefined) {
			for (var eachAddr of thisMembership.Membership_Address__r) {
				if (eachAddr.Type__c == 'Registered') {
					registeredAddress = eachAddr;
				}
			}
		}
		
		var addressToAdd = {
            'sobjectType': 'Membership_Address__c',
            'Membership__c': thisMembership.Id,
            'Membership__r': null,
            //'Billing_Address__c':true,
            'isNewRecord':true,
            'Type__c': 'Billing'
	    };

		if (isSameBilling == 'Yes' && registeredAddress != null)
		{
			/*
			if (thisMembership.Subsidiery_Account__c != null) {
				addressToAdd.Address_Line_1__c = thisMembership.Subsidiery_Account__r.BillingStreet;
				addressToAdd.City__c = thisMembership.Subsidiery_Account__r.BillingCity;
				addressToAdd.State__c = thisMembership.Subsidiery_Account__r.BillingState;
				addressToAdd.Zip__c = thisMembership.Subsidiery_Account__r.BillingPostalCode;
				addressToAdd.Phone_Number__c = thisMembership.Subsidiery_Account__r.Phone;
			}
			else if (thisMembership.Account__c != null) {
				addressToAdd.Address_Line_1__c = thisMembership.Account__r.BillingStreet;
				addressToAdd.City__c = thisMembership.Account__r.BillingCity;
				addressToAdd.State__c = thisMembership.Account__r.BillingState;
				addressToAdd.Zip__c = thisMembership.Account__r.BillingPostalCode;
				addressToAdd.Phone_Number__c = thisMembership.Account__r.Phone;
			}
			*/

			addressToAdd.Address_Line_1__c = registeredAddress.Address_Line_1__c;
			addressToAdd.City__c = registeredAddress.City__c;
			addressToAdd.State__c = registeredAddress.State__c;
			addressToAdd.Zip__c = registeredAddress.Zip__c;
			addressToAdd.Phone_Number__c = registeredAddress.Phone_Number__c;
		}

		component.set("v.addressToAdd", addressToAdd);
	},

	save : function(component, event, helper) {
		var addressToAdd = component.get("v.addressToAdd");

		if (addressToAdd.Address_Line_1__c == null || addressToAdd.City__c == null || addressToAdd.Phone_Number__c == null 
			|| addressToAdd.State__c == null || addressToAdd.Zip__c == null)
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
			component.getEvent("AddAddressEvt").setParams(
	        {
	       		"record":addressToAdd
	       	}).fire();

			component.destroy();
		}
	},

	closeMe: function(component, event, helper) {
		component.destroy();
	},
})