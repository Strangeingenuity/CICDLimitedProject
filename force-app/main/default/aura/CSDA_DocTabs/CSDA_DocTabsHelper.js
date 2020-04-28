({
	loadTabs : function(component, event) {
		var tab = event.getSource();
		this.injectComponent(component, 'c:CSDA_DocsToSign', tab);
	},

	injectComponent: function (component, name, target) {
        (
        	name, 
        	{
        		"relationshipRecord": component.get("v.selTabId"),
        		"docID": component.get("v.selTabId"), //component.get("v.selTabId").CSDA_Membership_Documents__c,
        		"thisMembership": component.get("v.thisMembership")
	        }, 
	        function (contentComponent, status, error) {
	            if (status === "SUCCESS") 
	            {
	                target.set('v.body', contentComponent);
	            } 
	            else 
	            {
	                throw new Error(error);
	            }
        	}
        );
    },

    toggleClass: function(component, event, secId) {
        //var acc = component.find(secId);
        //$A.util.toggleClass(acc, 'slds-show');  
        //$A.util.toggleClass(acc, 'slds-hide');  

        var acc = component.find(secId);
        if (acc.length >1)
        {
            for(var cmp in acc) {
                $A.util.toggleClass(acc[cmp], 'slds-show');  
                $A.util.toggleClass(acc[cmp], 'slds-hide');  
            }
        }
        else
        {
            $A.util.toggleClass(acc, 'slds-show');  
            $A.util.toggleClass(acc, 'slds-hide');  
        }
    },

    setMembershipChildren: function(component, event, helper) {
        var thisMembership = component.get("v.thisMembership");

        component.set("v.membershipContacts", thisMembership.Membership_Contacts__r);
        component.set("v.membershipAddresses", thisMembership.Membership_Address__r);

        if (thisMembership.Confidential_Information__r != undefined && thisMembership.Confidential_Information__r != null)
        {   
            component.set("v.docConfInfoID", thisMembership.Confidential_Information__r[0].Id);
        }

        // 4/17/18: W-011674
        var supportingDocs = [];
        var CPQPricingDocs = [];
        
        if (thisMembership.Membership_Document_Upload_Requests__r != undefined) {
            for (var eachUploadReq of thisMembership.Membership_Document_Upload_Requests__r) {
                
                if(eachUploadReq.CPQ_Attachment_Type__c=='ContentDocument' && eachUploadReq.CPQ_Attachment_ID__c !=null ){
                    eachUploadReq.CPQ_Attachment_ID__c='/CSDAMemOnboarding/sfc/servlet.shepherd/document/download/'+eachUploadReq.CPQ_Attachment_ID__c;
                }
                if(eachUploadReq.CPQ_Attachment_Type__c=='Attachment' && eachUploadReq.CPQ_Attachment_ID__c !=null ){
                    eachUploadReq.CPQ_Attachment_ID__c='/CSDAMemOnboarding/servlet/servlet.FileDownload?file='+eachUploadReq.CPQ_Attachment_ID__c;
                }

                if (eachUploadReq.CPQ_Pricing__c) {
                    CPQPricingDocs.push(eachUploadReq);
                }
                else {
                    supportingDocs.push(eachUploadReq);
                }
            }
        }

        component.set("v.supportingDocs", supportingDocs);
        component.set("v.CPQPricingDocs", CPQPricingDocs);
    }
})