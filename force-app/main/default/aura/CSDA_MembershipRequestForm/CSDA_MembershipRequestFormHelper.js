({
	createObjectData: function(component, event, objectType, dataList) {
        var objectData = {
            'sobjectType': objectType,
            'Membership__c': component.get("v.thisMembership.Id"),
            'Membership__r': null,
            'isNewRecord': true
        };

        if (objectType == 'Membership_Contacts__c')
        {
            dataList.push(objectData);
        	component.set("v.membershipContacts", dataList);
        }
        else if (objectType == 'Membership_Address__c')
        {
            objectData.Type__c = 'Branch';
            objectData.Account_Name__c = component.get("v.thisMembership.Account__r.Name");
            dataList.push(objectData);
        	component.set("v.membershipAddresses", dataList);
        }
    },

    toggleClass: function(component, event, secId) {
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

        // Toggle the expanded indicator attribute as well
        if (secId == 'contactSection') {
            if (component.get("v.contactListExpanded")) {
                component.set("v.contactListExpanded", false);
            }
            else {
                component.set("v.contactListExpanded", true);
            }
        }

        if (secId == 'addressSection') {
            if (component.get("v.addressListExpanded")) {
                component.set("v.addressListExpanded", false);
            }
            else {
                component.set("v.addressListExpanded", true);
            }
        }
    },

    addClass: function(component, event, secId) {
        var acc = component.find(secId);
        for(var cmp in acc) {
            $A.util.addClass(acc[cmp], 'slds-show');
            $A.util.removeClass(acc[cmp], 'slds-hide');     
       }
    },

    openWindow: function(component, applicantContact, answer, objType) {
        if (objType == 'ThirdParty_Membership_Contacts__c')
        {
            $A.createComponent(
                "c:CSDA_MemContactModalWindow",
                {
                    "membershipID": component.get("v.thisMembership.Id"),
                    "isThirdParty": true,
                    "ThirdPartyRoleList": component.get("v.ThirdPartyRoleList")
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
        }
        else if (objType == 'Membership_Contacts__c')
        {
            $A.createComponent(
                "c:CSDA_MemContactModalWindow",
                {
                    "applicantContact": applicantContact,
                    "membershipID": component.get("v.thisMembership.Id"),
                    "contactRole": answer,
                    "ThirdPartyRoleList": component.get("v.ThirdPartyRoleList")
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
        }
        else if (objType == 'Membership_Address__c')
        {
            $A.createComponent(
                "c:CSDA_MemAddressModalWindow",
                {
                    "isSameBilling": answer,
                    "thisMembership": component.get("v.thisMembership")
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
        }
    },

    setMembershipChildren: function(component, event, helper){
        var membershipContacts = [];
        var membershipAddresses = [];
        var respon = component.get("v.thisMembership");

        if (respon.Membership_Contacts__r != undefined)
        {
            for (var i=0; i<respon.Membership_Contacts__r.length; i++)
            {
                membershipContacts.push(respon.Membership_Contacts__r[i]);
            }
        }
        if (respon.Membership_Address__r != undefined)
        {
            for (var i=0; i<respon.Membership_Address__r.length; i++)
            {
                membershipAddresses.push(respon.Membership_Address__r[i]);
            }
        }
        
        component.set("v.membershipContacts", membershipContacts);
        component.set("v.originalMembershipContacts", membershipContacts);

        component.set("v.membershipAddresses", membershipAddresses);
        component.set("v.originalMembershipAddresses", membershipAddresses);

        if (respon.Confidential_Information__r != undefined && respon.Confidential_Information__r != null)
        {   
            component.set("v.docConfInfoID", respon.Confidential_Information__r[0].Id);
            /*
            var confInfoList = respon.Confidential_Information__r;
            if (confInfoList != null)
            {
                component.set("v.docConfInfoID", confInfoList[0].Id);
            }
            */
        }

        if (respon.Membership_Matching__r != undefined)
        {
            component.set("v.ppMatchingRec", respon.Membership_Matching__r[0]);
        }

        // 4/17/18: W-011674
        component.set("v.supportingDocs", respon.Membership_Document_Upload_Requests__r);
    },

    // Should only get called in rerender
    getMembership: function(component, event, helper){
        // Based on which tab is clicked, display the appropriate form for that specific membership
        // Query the membership
        var getMembership = component.get("c.getMembership");
        getMembership.setParams({"recordId":component.get("v.thisMembership.Id")});

        $A.enqueueAction(getMembership);
        getMembership.setCallback(this, function(a){
            var state = a.getState();
            if (component.isValid() && state === "SUCCESS") {
                var respon = a.getReturnValue();
                component.set("v.thisMembership", respon);

                var membershipContacts = [];
                var membershipAddresses = [];

                if (respon.Membership_Contacts__r != undefined)
                {
                    for (var i=0; i<respon.Membership_Contacts__r.length; i++)
                    {
                        membershipContacts.push(respon.Membership_Contacts__r[i]);
                    }
                }
                if (respon.Membership_Address__r != undefined)
                {
                    for (var i=0; i<respon.Membership_Address__r.length; i++)
                    {
                        membershipAddresses.push(respon.Membership_Address__r[i]);
                    }
                }

                component.set("v.membershipContacts", membershipContacts);
                component.set("v.originalMembershipContacts", membershipContacts);

                component.set("v.membershipAddresses", membershipAddresses);
                component.set("v.originalMembershipAddresses", membershipAddresses);
                
                if (respon.Confidential_Information__r != undefined)
                {   
                    var confInfoList = respon.Confidential_Information__r;
                    if (confInfoList != null)
                    {
                        component.set("v.docConfInfoID", confInfoList[0].Id);
                    }
                }

                if (respon.Membership_Matching__r != undefined)
                {
                    component.set("v.ppMatchingRec", respon.Membership_Matching__r[0]);
                }

                // 4/17/18: W-011674
                component.set("v.supportingDocs", respon.Membership_Onboarding_Documents__r);
            }
        });
    },

    getPermPurpose: function(component, event, helper) {
        // Need to set the dualListBox options before async call or markup doesn't render '+' icons.
        var opts = [];
        component.find("permPurposeList").set("v.options", opts);

        var getPermPurpose = component.get("c.getPermPurpose");
        getPermPurpose.setParams({"thisMembership":component.get("v.thisMembership")});
        $A.enqueueAction(getPermPurpose);
        getPermPurpose.setCallback(this, function(a){
            var state = a.getState();
            if (component.isValid() && state === "SUCCESS") {
                var respon = a.getReturnValue();
                
                for (var i=0; i<respon.length; i++)
                {
                    var eachOption = 
                    {
                        label: respon[i].Purpose_for_client_approaching_Experian__c + ': \n' + respon[i].Client_Facing_Permissible_Purposes__c,
                        value: respon[i].Purpose_for_client_approaching_Experian__c
                    }
                    opts.push(eachOption);
                }

                opts.push({label:'Other', value:'Other'});
                component.find("permPurposeList").set("v.options", opts);

                var selectedPP = component.get("v.thisMembership.Permissible_Purposes__c");
                if (selectedPP != undefined) {
                    var PPArray = selectedPP.split(';');
                    component.find("permPurposeList").set("v.value", PPArray);
                }
            }
        });
    },

    // Get the latest uploaded file with the name 'Reseller Questionnaire'
    getUploadedResellerFile: function(component, event, helper) {
        var getUploadedResellerFile = component.get("c.getUploadedResellerFile");
        getUploadedResellerFile.setParams({"docConfInfoID":component.get("v.docConfInfoID")});
        $A.enqueueAction(getUploadedResellerFile);
        getUploadedResellerFile.setCallback(this, function(a){
            var state = a.getState();
            if (component.isValid() && state === "SUCCESS") {
                var respon = a.getReturnValue();
                component.set("v.uploadedQuestionnaire", respon);
            }
        });
    },

    // W-012146: Don't display PP section if non revenue and falls into certain non opp request types
    determineShowPPSection: function(component, event, helper) {
        var thisMembership = component.get("v.thisMembership");
        var requestTypeList = [
            'Agent',
            '3PP',
            'Vendor',
            'Data Processor',
            'Reactivations',
            'Credit Educator',
            'Test subcode requests',
            'Existing Client adding agent for existing product',
            'Name Change'
        ];
        
        if (thisMembership.RecordType.DeveloperName == 'Membership_Non_Revenue' && requestTypeList.includes(thisMembership.Non_Opp_Request_Type__c)) {
            component.set("v.showPPSection", false);
        }
    },

    rerenderPage: function(component, event, helper) {
        helper.getMembership(component, event, helper);
        helper.getUploadedResellerFile(component, event, helper);
    },

    setupComboBoxOptions: function(component, event, helper) {
        var comboboxComponents = component.find("combobox");

        for (var eachComp of comboboxComponents) {
            var name;
            if (eachComp.get("v.name") != undefined) {
                name = "-" + eachComp.get("v.name");
            }
            else {
                name = "";
            }
            
            var opts = [
                {value:"Yes" + name, label:"Yes"},
                {value:"No" + name, label:"No"}
            ];

            eachComp.set("v.options", opts);
        }
    }
})