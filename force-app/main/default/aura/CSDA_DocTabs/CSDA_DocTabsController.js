({
    doInit: function(component, event, helper) {
        helper.setMembershipChildren(component, event, helper);
    },

    handleActive : function(component, event, helper) {
        helper.loadTabs(component, event);
    },

    toggleDocSection: function(component, event, helper) {
        var id = event.target.id;
        component.set("v.documentExpanded", "true");
        helper.toggleClass(component,event,id);
    },

    toggleSection : function(component, event, helper) {
        var id = event.target.id;
        helper.toggleClass(component,event,id);
    },

    handleUploadFinished: function ( component, event) {
        // Get the list of uploaded files
        var uploadedFiles = event.getParam("files");

        var action = component.get("c.supportingDocRename");
        var documentRecNameID = event.getSource().get('v.name'); 
        console.log(documentRecNameID);
        console.log(uploadedFiles[0].documentId);
        console.log(JSON.stringify(action));
        action.setParams({"documentId":uploadedFiles[0].documentId,"documentRecNameID": documentRecNameID});
        action.setCallback(this, function(a){
            var state = a.getState();
           if (component.isValid() && state === "SUCCESS") {
                var toastEvent = $A.get("e.force:showToast");
                toastEvent.setParams({
                    "title": "Success!",
                    "type" : "Success",
                    "message": uploadedFiles[0].name + " uploaded"
                });
                toastEvent.fire();
                var supportDoc = component.get("v.supportingDocs");

                console.log(a.getReturnValue());
                
                supportDoc.forEach((element, index) => {
                    if(element.Id === a.getReturnValue()) {
                        supportDoc[index].Client_Provided__c = true;
                        component.set("v.supportingDocs",supportDoc );
                    }
                });

                var cpqDoc = component.get("v.CPQPricingDocs");
                cpqDoc.forEach((element, index) => {
                    if(element.Id === a.getReturnValue()) {
                        cpqDoc[index].Client_Provided__c = true;
                        component.set("v.CPQPricingDocs",cpqDoc );
                    }
                });
           }
        });
        
       $A.enqueueAction(action);
    }
})