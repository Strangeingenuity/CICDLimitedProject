({
	doInit : function(component, event, helper) {
                helper.getMemberships(component, event, helper);
                helper.getResellerFile(component, event, helper);
                //helper.getPermPurpose(component, event, helper);
                helper.getCurContact(component, event, helper);
                helper.getThirdPartyRoles(component, event, helper);
                helper.getStaticDocs(component, event, helper);
	},

	handleActive : function(component, event, helper) {
		helper.loadTabs(component, event);
	},

        updateProximityAttributes: function(component, event, helper) {
                component.set("v.jscProximity", component.find("tupni").getElement().value);
                component.set("v.hdimProximity", component.find("tupnimidh").getElement().value);
        }
})