({
    doSave: function(component, event, helper) {
        if (component.find("fileId").get("v.files").length > 0) {
            helper.uploadHelper(component, event);
        } else {
            var resultsToast = $A.get("e.force:showToast");
            resultsToast.setParams({
                "type": "error",
                "title": "Error",
                "message": "Please Select a Valid File."
            });
            resultsToast.fire(); 
        }
    },
 
    handleFilesChange: function(component, event, helper) {
        var fileName = 'No File Selected..';
        if (event.getSource().get("v.files").length > 0) {
            fileName = event.getSource().get("v.files")[0]['name'];
        }
        component.set("v.fileName", fileName);
    },
    
    PACE_NewRecordIdEvent: function(component, event, helper) {
      console.log('PACE_NewRecordIdEvent' + event.getParam("recordId"));
        
        component.set("v.parentId", event.getParam("recordId"));
        if (component.find("fileId").get("v.files").length > 0) {
            helper.uploadHelper(component, event);
        } else {
            var resultsToast = $A.get("e.force:showToast");
            resultsToast.setParams({
                "type": "error",
                "title": "Error",
                "message": "Please Select a Valid File."
            });
            resultsToast.fire(); 
        }
    },
})