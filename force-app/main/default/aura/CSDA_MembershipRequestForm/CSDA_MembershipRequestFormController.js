({
	doInit : function(component, event, helper) {
        console.log('test');
        helper.setMembershipChildren(component, event, helper);
        helper.getPermPurpose(component, event, helper);
        helper.getUploadedResellerFile(component, event, helper);
        helper.determineShowPPSection(component, event, helper);
        helper.setupComboBoxOptions(component, event, helper);
	}, 

    toggleSection : function(component, event, helper) {
        var id = event.target.id;
        helper.toggleClass(component,event,id);
    },

    toggleAddressTable: function(component, event, helper) {
        // Expand address list table
        if (!component.get("v.addressListExpanded") && component.get("v.thisMembership.Multiple_Locations__c") == true)
        {
            helper.toggleClass(component, event,'addressSection');
        }
    },

    AddContactRow: function(component, event, helper) {
        // call the common "createObjectData" helper method for add new Object Row to List  
        helper.createObjectData(component, event, 'Membership_Contacts__c', component.get('v.membershipContacts'));
    },

    AddAddressRow: function(component, event, helper) {
        // Only allow this if there's less than 10 Branch Addresses in total list, AND is less than num specified by client
        var addressList = component.get("v.membershipAddresses");
        var numOfOtherLocations = component.get("v.thisMembership.Num_Of_Other_Locations__c");
        var branchAddressList = [];

        for (var i=0; i<addressList.length; i++)
        {
            if (addressList[i].Type__c == 'Branch' || addressList[i].Type__c == 'Affiliate')
            {
                branchAddressList.push(addressList[i]);
            }
        }

        if (branchAddressList.length >=10)
        {
            var resultsToast = $A.get("e.force:showToast");
            resultsToast.setParams({
                "type": "error",
                "title": "Page Error",
                "message": "You cannot add more than 10 Branch/Affiliate Membership Addresses."
            });
            resultsToast.fire(); 
        }
        else if (numOfOtherLocations == null)
        {
            var resultsToast = $A.get("e.force:showToast");
            resultsToast.setParams({
                "type": "error",
                "title": "Page Error",
                "message": "Please mark 'Is the product going to be used at other location/locations?' then specify the number of other locations."
            });
            resultsToast.fire(); 
        }
        else if (numOfOtherLocations != null && branchAddressList.length >= numOfOtherLocations)
        {
            var resultsToast = $A.get("e.force:showToast");
            resultsToast.setParams({
                "type": "error",
                "title": "Page Error",
                "message": "You have specified that there is(are) " + numOfOtherLocations + " other location(s). Please change this number if you want to add more addresses."
            });
            resultsToast.fire(); 
        }
        else
        {
            // call the common "createObjectData" helper method for add new Object Row to List  
            helper.createObjectData(component, event, 'Membership_Address__c', component.get('v.membershipAddresses'));
        }
    },

    removeRow: function(component, event, helper) {
        // get the selected row Index for delete, from Lightning Event Attribute  
        var index = event.getParam("indexVar");
        var objectType = event.getParam("objectType");
        // get the all List (contactList attribute) and remove the Object Element Using splice method    
        if (objectType == 'Membership_Contacts__c')
        {
            var AllRowsList = component.get("v.membershipContacts");
            AllRowsList.splice(index, 1); 
            component.set("v.membershipContacts", AllRowsList);
        }
        else if (objectType == 'Membership_Address__c')
        {
            var AllRowsList = component.get("v.membershipAddresses");
            AllRowsList.splice(index, 1); 
            component.set("v.membershipAddresses", AllRowsList);
        }
    },

    showContactModal: function(component, event, helper) {
        console.log('charlie test');
        console.log(event.getParam("value"));
        var contactRole = event.getSource().get('v.value');
        var thisMembership = component.get('v.thisMembership');
        var applicantContact = null;

        if (thisMembership.Membership_Contacts__r != undefined) {
            for (var eachMemContact of thisMembership.Membership_Contacts__r) {
                if (eachMemContact.Role__c == "Applicant") {
                    applicantContact = eachMemContact;
                }
            }
        }
        
        // Pass in cur contact info into modal component if 'Yes'
        if (contactRole.includes('Yes'))
        {
            helper.openWindow(component, applicantContact, contactRole.replace("Yes-", ""), 'Membership_Contacts__c');
        }
        // Dont pass any contact info into modal component if 'No'
        else if (contactRole.includes('No'))
        {
            helper.openWindow(component, null, contactRole.replace("No-", ""), 'Membership_Contacts__c');
        }
    },

    showTPContactModal: function(component, event, helper) {
        var contactAnswer = event.getSource().get('v.value');

        if (contactAnswer)
        {
            helper.openWindow(component, null, null, 'ThirdParty_Membership_Contacts__c');
        }
    },

    showAddressModal: function(component, event, helper) {
        var addressAnswer = event.getSource().get('v.value');

        // Auto create billing address based on membership's account if answer is Yes
        helper.openWindow(component, null, addressAnswer, 'Membership_Address__c');
    },

    addContactFromEvt: function(component, event, helper) {
        var memContact = event.getParam("record");
        var contactList = component.get("v.membershipContacts");
        contactList.push(memContact);
        component.set("v.membershipContacts", contactList);

        // Expand contact list table
        if (!component.get("v.contactListExpanded"))
        {
            helper.toggleClass(component, event,'contactSection');
        }
    },

    addAddressFromEvt: function(component, event, helper) {
        var memAddress = event.getParam("record");
        var addressList = component.get("v.membershipAddresses");
        addressList.push(memAddress);
        component.set("v.membershipAddresses", addressList);

        // Expand address list table
        if (!component.get("v.addressListExpanded"))
        {
            helper.toggleClass(component, event,'addressSection');
        }
    },

    save: function(component, event, helper) {
        if (confirm("Are you sure you want to save this request?"))
        {
            var spinner = component.find("mySpinner");
            var DQFlag = false;

            // W-010998: Flag for DQ team if name, address or website was edited.
            if (component.get("v.accountEdit") == true || component.get("v.addressEdit") == true || component.get("v.websiteEdit") == true)
            {
                DQFlag = true;
            }
            var saveAll = component.get("c.saveAll");
            saveAll.setParams({
                "thisMembership":component.get("v.thisMembership"), 
                "contactList":component.get("v.membershipContacts"),
                "originalContactList":component.get("v.originalMembershipContacts"),
                "addressList":component.get("v.membershipAddresses"),  
                "originalAddressList":component.get("v.originalMembershipAddresses"),  
                "DQFlag": DQFlag
            });
            saveAll.setCallback(this, function(a){
                var state = a.getState();
                if (component.isValid() && state === "SUCCESS") {
                    var resultsToast = $A.get("e.force:showToast");
                    resultsToast.setParams({
                        "type": "success",
                        "title": "Result",
                        "message": "Saved"
                    });
                    resultsToast.fire(); 

                    //helper.getMembership(component, event, helper);
                    // Changing this, so we don't have to requery on each membership level. Trying to query only on the tab level.
                    //$A.get('e.force:refreshView').fire();

                    // I-2609: Need to requery for save. refreshView will always kick back user to the first tab.
                    helper.rerenderPage(component, event, helper);
                }
                else
                {
                    var errors = a.getError();
                    if (errors)
                    {
                        var errorMsg = "Error";

                        if (errors[0] && errors[0].message) {
                            errorMsg = errors[0].message;
                        }
                        else {
                            // This means there is an email format error
                            if (errors[0] != undefined && errors[0].fieldErrors.Email__c) {
                                errorMsg = errors[0].fieldErrors.Email__c[0].message;
                            }
                            else if (errors[0] != undefined && errors[0].pageErrors.length > 0) {
                                errorMsg = errors[0].pageErrors[0].message;
                            }
                        }

                        var resultsToast = $A.get("e.force:showToast");
                        resultsToast.setParams({
                            "type": "error",
                            "title": "Error",
                            "message": errorMsg
                        });
                        resultsToast.fire(); 
                        console.log('error from save');
                        console.log(errors);
                    }
                }
                $A.util.toggleClass(spinner, 'slds-hide');
            });

            $A.enqueueAction(saveAll);
            $A.util.toggleClass(spinner, 'slds-hide');
        }
    },

    submit: function(component, event, helper) {
        try{

            /*
            var req = new XMLHttpRequest();
            req.open('GET', document.location, false);
            req.send(null);
            var headers = req.getAllResponseHeaders();
            */
        
            var url = location.href;
            var index = url.indexOf(".com");
            var fixedurl = url.substring(0, index+4);

            //headers += 'Content-Language: ' + navigator.language;
            var headers = 'User-Agent: ' + navigator.userAgent;
            headers += '\nHost: ' + fixedurl;

            /*
            function checkCookie() {
                var username = getCookie("username");
                if (username != "") {
                    alert("Welcome again " + username);
                } 
                else {
                    username = prompt("Please enter your name:", "");
                    if (username != "" && username != null) {
                        setCookie("username", username, 365);
                    }
                }
            }
            */

            mempxe.lav('tupni');
            // Once .lav is called, tupni and tupnimidh should be populated on the parent component. Grab these and assign to shared attributes so I can grab in the child
            // To do this, need to fire an event for the parent to listen to. The parent will respond by setting the attributes.
            component.getEvent("GetProximityAttributes").fire();

            var thisMembership = component.get("v.thisMembership");
            thisMembership.Proximity_jsc__c = component.get("v.jscProximity");
            thisMembership.Proximity_hdim__c = component.get("v.hdimProximity");

            thisMembership.Proximity_Header_Info__c = headers;
            component.set("v.thisMembership", thisMembership);
        }
        catch(error) {
            var resultsToast = $A.get("e.force:showToast");
            resultsToast.setParams({
                "type": "error",
                "title": "Error",
                "message": error.message
            });
            resultsToast.fire(); 
            console.log(error);
        }

        if (confirm("Are you sure you want to submit this request?"))
        {
            var spinner = component.find("mySpinner");
            var DQFlag = false;

            // W-010998: Flag for DQ team if name, address or website was edited.
            if (component.get("v.accountEdit") == true || component.get("v.addressEdit") == true || component.get("v.websiteEdit") == true)
            {
                DQFlag = true;
            }
            var submitAll = component.get("c.submitAll");
            submitAll.setParams({
                "thisMembership":component.get("v.thisMembership"), 
                "contactList":component.get("v.membershipContacts"), 
                "originalContactList":component.get("v.originalMembershipContacts"),
                "addressList":component.get("v.membershipAddresses"), 
                "originalAddressList":component.get("v.originalMembershipAddresses"),  
                "ppMatchingRec":component.get("v.ppMatchingRec"),
                "DQFlag": DQFlag
            });
            submitAll.setCallback(this, function(a){
                var state = a.getState();
                if (component.isValid() && state === "SUCCESS") {
                    var resultsToast = $A.get("e.force:showToast");
                    resultsToast.setParams({
                        "type": "success",
                        "title": "Result",
                        "message": "Submitted"
                    });
                    resultsToast.fire(); 

                    //mempxe.lav('tupni');
                    $A.get('e.force:refreshView').fire();
                }
                else
                {
                    var errors = a.getError();
                    if (errors)
                    {
                        var errorMsg = "Error";

                        if (errors[0] && errors[0].message) {
                            errorMsg = errors[0].message;
                        }
                        else {
                            // This means there is an email format error
                            if (errors[0] != undefined && errors[0].fieldErrors.Email__c) {
                                errorMsg = errors[0].fieldErrors.Email__c[0].message;
                            }
                            else if (errors[0] != undefined && errors[0].pageErrors.length > 0) {
                                errorMsg = errors[0].pageErrors[0].message;
                            }
                        }

                        var resultsToast = $A.get("e.force:showToast");
                        resultsToast.setParams({
                            "type": "error",
                            "title": "Error",
                            "message": errorMsg
                        });
                        resultsToast.fire(); 
                        console.log('error from submit');
                        console.log(errors);
                    }
                }
                $A.util.toggleClass(spinner, 'slds-hide');
            });

            $A.enqueueAction(submitAll);
            $A.util.toggleClass(spinner, 'slds-hide')
        }
    },

    openSubmitModal: function(component, event, helper) {
        $A.createComponent(
            "c:CSDA_SubmitModalWindow",
            {
                StaticDocList: component.get("v.StaticDocList")
            },
            function(msgBox){                
                if (component.isValid()) {
                    var targetCmp = component.find('ModalDialogPlaceholder');
                    var body = targetCmp.get("v.body");
                    body.push(msgBox);
                    targetCmp.set("v.body", body); 
                }
            }
        );
    },

    mempxeInitialize: function(component, event, helper) {
        mempxe.noitcelloc(null);
    },

    rerenderPage: function(component, event, helper) {
        helper.rerenderPage(component, event, helper);
    },

    permPurposeChanged: function(component, event, helper) {
        var selectedOptionValue = event.getParam("value");
        var thisMembership = component.get("v.thisMembership");
        thisMembership.Permissible_Purposes__c = selectedOptionValue.join(';');
        component.set("v.thisMembership", thisMembership);
    },

    setupComboBoxOptions: function(component, event, helper) {
        // Need to reconstruct SQD dropdown lists everytime SQD Active is set to true
        if (event.getParam("value")) {
            helper.setupComboBoxOptions(component, event, helper);
        }
    },

    handleUploadFinished: function ( component, event) {
        // Get the list of uploaded files
        var uploadedFiles = event.getParam("files");

        var action = component.get("c.documentRename");
        
        action.setParams({"documentId":uploadedFiles[0].documentId});
        action.setCallback(this, function(a){
            var state = a.getState();
           if (component.isValid() && state === "SUCCESS") {
                var toastEvent = $A.get("e.force:showToast");
                toastEvent.setParams({
                    "title": "Success!",
                    "type" : "Success",
                    "message": uploadedFiles[0].name + " uploaded"
                });
                component.getEvent("UploadedEvt").fire();                                             
           }
        });
        
       $A.enqueueAction(action);
    }
})