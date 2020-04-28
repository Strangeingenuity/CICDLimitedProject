({
    doInit : function(component, event, helper) {    
        var getDocument = component.get("c.getDocument");
        getDocument.setParams({"docID":component.get("v.docID")});
        $A.enqueueAction(getDocument);
        getDocument.setCallback(this, function(a){
            var state = a.getState();

            if (component.isValid() && state === "SUCCESS") {
                var docRespon = a.getReturnValue();
                component.set("v.thisDocument", docRespon);

                var modifiedHeader = helper.modifyWithInserts(component, docRespon.Document_Header__c);
                component.set("v.modifiedHeader", modifiedHeader);

                var modifiedName = helper.modifyWithInserts(component, docRespon.Document_Name__c);
                component.set("v.modifiedName", modifiedName);

                helper.renderDocument(component, event, helper);

                if (docRespon.Document_Name__c.includes('Affiliate Addendum')) {
                    component.set("v.isAffiliateAddendum", true);
                }
            }
        });  

        var getUser = component.get("c.getUser");
        $A.enqueueAction(getUser);  
        getUser.setCallback(this, function(a){
            var state = a.getState();
            if (component.isValid() && state === "SUCCESS") {
                var userRespon = a.getReturnValue();
                component.set("v.curUser", userRespon);

                var getAttachmentID = component.get("c.getAttachmentID");
                getAttachmentID.setParams
                ({
                    "memID":component.get("v.relationshipRecord.Membership__c"),
                    //"accountID": component.get("v.curUser.Contact.AccountId"),
                    "docName": component.get("v.relationshipRecord.CSDA_Membership_Documents__r.Document_Name__c")
                });
                $A.enqueueAction(getAttachmentID);
                getAttachmentID.setCallback(this, function(b){
                    var attachmentState = b.getState();
                    if (component.isValid() && attachmentState === "SUCCESS") {
                        var attachmentID = b.getReturnValue();
                        component.set("v.downloadURL", attachmentID);
                    }
                });  
            }
        });
        
        var getUnsignedDocument = component.get("c.getUnsignedDocument");
        getUnsignedDocument.setParams({
            "unsignedDocumentID":component.get("v.relationshipRecord.CSDA_Membership_Documents__c")
        });
        $A.enqueueAction(getUnsignedDocument);
        getUnsignedDocument.setCallback(this, function(a){
            var state = a.getState();
            if (component.isValid() && state === "SUCCESS") {
                var respon = a.getReturnValue();
                component.set("v.downloadUnsignedDocLink", respon);
            }
        });  

        if (component.get("v.thisMembership") != undefined) {
            var membershipAddressList = component.get("v.thisMembership.Membership_Address__r");
            var affiliateAddressList = [];

            if (membershipAddressList != undefined) {
                for (var eachAdd of membershipAddressList) {
                    if (eachAdd.Type__c == "Branch" || eachAdd.Type__c == "Affiliate") {
                        affiliateAddressList.push(eachAdd);
                    }
                }
            }
            
            component.set("v.affiliateAddressList", affiliateAddressList);

            // If this doc has a contact, means it is an agent addendum. In this case, need to find the agent's membership contact.
            var membershipContactList = component.get("v.thisMembership.Membership_Contacts__r");
            var relationshipRecord = component.get("v.relationshipRecord");

            if (membershipContactList != undefined) {
                for (var eachCont of membershipContactList) {
                    if (relationshipRecord.Contact__c == eachCont.Contact__c) {
                        component.set("v.agentContact", eachCont);
                    }
                }
            }            
        }

        console.log(component.get("v.agentContact"));
    },

    // Dynamically create modal component
    showAgreementModal: function(component, event, helper) {
        helper.showAgreementModalHelper(component, event, helper, false);
    },

    // Dynamically create modal component
    showAgreementModalForAgent: function(component, event, helper) {
        helper.showAgreementModalHelper(component, event, helper, true);
    },
    
    /*
    testButton: function(component, event, helper) {
        console.log(component.get("v.multiTrueFalseArray"));
    }
    */
})