({
    init: function(component, event, helper) {
        helper.initializeRoleOptions(component);
    },

	removeRow : function(component, event, helper) {
     // fire the DeleteRowEvt Lightning Event and pass the deleted Row Index to Event parameter/attribute
        //component.getEvent("DeleteRowEvt").setParams({"indexVar":component.get("v.rowIndex"), "LoadDate":component.get("v.WaterfallRecord").Load_View_End_ts__c}).fire();
        if (confirm("Are you sure?"))
        {
        	component.getEvent("DeleteRowEvt").setParams(
	        {
	       		"indexVar":component.get("v.rowIndex"), 
	       		"objectType":'Membership_Contacts__c'
	       	}).fire();
        }
    },

    SQDChange: function(component, event, helper) {
        helper.initializeRoleOptions(component);
    }
})