({
    doInit : function(component, event, helper) { 
        var now = new Date();
        component.set("v.curDateTime", $A.localizationService.formatDate(now));

        var getCurSessionIP = component.get("c.getCurSessionIP");
        $A.enqueueAction(getCurSessionIP);
        getCurSessionIP.setCallback(this, function(a){
            var state = a.getState();
            if (component.isValid() && state === "SUCCESS") {
                var respon = a.getReturnValue();
                component.set("v.IPAddress", respon);
            }
        }); 

        var memContacts = component.get("v.thisMembership.Membership_Contacts__r");
        var curUser = component.get("v.curUser");
        var curMemContact;

        if (curUser.Contact != undefined) {
           for (var eachCon of memContacts) {
                console.log(eachCon);
                if (eachCon.Contact__c == curUser.Contact.Id) {
                    curMemContact = eachCon;
                }
            }

            component.set("v.curMemContact", curMemContact); 
        }
    },

    closeMe: function(component, event, helper) {
        component.destroy();
    },

    agentSignDocument: function(component, event, helper) {
        var spinner = component.find("mySpinner");
        $A.util.toggleClass(spinner, 'slds-hide');

        var agentSignature = component.get("c.agentSignature");
        agentSignature.setParams
        ({
            "relationshipRecord":component.get("v.relationshipRecord"),
            "curUser": component.get("v.curUser"),
            "IPAddress": component.get("v.IPAddress"),
            "memContacts": component.get("v.thisMembership.Membership_Contacts__r"),
            "curDateTime": component.get("v.curDateTime")
        })

        $A.enqueueAction(agentSignature);
        agentSignature.setCallback(this, function(a){
            var state = a.getState();
            if (component.isValid() && state === "SUCCESS") {
                var resultsToast = $A.get("e.force:showToast");
                resultsToast.setParams({
                    "type": "success",
                    "title": "Result",
                    "message": "Signed"
                });
                resultsToast.fire(); 
                $A.get('e.force:refreshView').fire();
            }
            else
            {
                var errors = a.getError();
                if (errors)
                {
                    var errorMsg = "Error";
                    if (errors[0] && errors[0].message)
                    {
                        errorMsg = errors[0].message;
                    }
                    else if (errors[0] && errors[0].pageErrors)
                    {
                        errorMsg = errors[0].pageErrors;
                    }
                    
                    var resultsToast = $A.get("e.force:showToast");
                    resultsToast.setParams({
                        "type": "error",
                        "title": "Error",
                        "message": errorMsg
                    });
                    resultsToast.fire(); 
                }
            }
            $A.util.toggleClass(spinner, 'slds-hide');
        });  
    },

    signDocument: function(component, event, helper) {
        var spinner = component.find("mySpinner");
        $A.util.toggleClass(spinner, 'slds-hide');

        var generatePDF = component.get("c.generatePDF");
        generatePDF.setParams
        ({
            "docRecord":component.get("v.thisDocument"),
            "relationshipRecord":component.get("v.relationshipRecord"),
            "curUser": component.get("v.curUser"),
            "IPAddress": component.get("v.IPAddress"),
            "trueFalseString": component.get("v.trueFalseString"),
            "multiTrueFalseString": component.get("v.multiTrueFalseString"),
            "thisMembership": component.get("v.thisMembership"),
            "curDateTime": component.get("v.curDateTime"),
            "signingContact": component.get("v.curMemContact")
        })

        $A.enqueueAction(generatePDF);
        generatePDF.setCallback(this, function(a){
            var state = a.getState();
            if (component.isValid() && state === "SUCCESS") {
                var resultsToast = $A.get("e.force:showToast");
                resultsToast.setParams({
                    "type": "success",
                    "title": "Result",
                    "message": "Signed"
                });
                resultsToast.fire(); 
                $A.get('e.force:refreshView').fire();
            }
            else
            {
                var errors = a.getError();
                if (errors)
                {
                    console.log(errors);
                    var errorMsg = "Error";
                    if (errors[0] && errors[0].message)
                    {
                        errorMsg = errors[0].message;
                    }
                    else if (errors[0] && errors[0].pageErrors)
                    {
                        errorMsg = errors[0].pageErrors;
                    }
                    
                    var resultsToast = $A.get("e.force:showToast");
                    resultsToast.setParams({
                        "type": "error",
                        "title": "Error",
                        "message": errorMsg
                    });
                    resultsToast.fire(); 
                }
            }
            $A.util.toggleClass(spinner, 'slds-hide');
        });  
    },
})