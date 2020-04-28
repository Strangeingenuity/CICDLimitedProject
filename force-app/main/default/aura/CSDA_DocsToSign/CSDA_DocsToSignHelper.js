({
    showAgreementModalHelper: function(component, event, helper, isAgent) {
        /*
        var thisDocument = component.get('v.thisDocument');
        var relationshipRecord = component.get('v.relationshipRecord');
        var curUser = component.get('v.curUser');
        */

        // Pass in true false string for checkboxes
        var multiTrueFalseArray = component.get("v.multiTrueFalseArray");
        var multiTrueFalseString = '';

        for (var i=0; i<multiTrueFalseArray.length; i++) {
            multiTrueFalseString += multiTrueFalseArray[i] + ',';
        }

        // Pass in true false string for radio buttons
        var trueFalseArray = component.get("v.trueFalseArray");
        var trueFalseString = '';
        var numOfTrue = 0;

        for (var i=0; i<trueFalseArray.length; i++) {
            //var auraID = 'checkbox' + i;
            //var eachCheckBox = component.find(auraID).get("v.value");
            
            trueFalseString = trueFalseString + trueFalseArray[i] + ',';
            if (trueFalseArray[i] == 'true') {
                numOfTrue++;
            }
        }

        // Make sure each checkboxgroup has at least one true value before opening the modals
        if (numOfTrue != component.get("v.numOfCheckboxGroups")) {
            var resultsToast = $A.get("e.force:showToast");
            resultsToast.setParams({
                "type": "warning",
                "title": "Warning",
                "message": "Please answer all questions on contract before agreeing."
            });
            resultsToast.fire(); 
        }
        else {
            helper.openAgreementWindow(component, trueFalseString, multiTrueFalseString, isAgent);
        }
    },

    openAgreementWindow: function(component, trueFalseString, multiTrueFalseString, isAgent)
    {
        (
            "c:CSDA_DocAgreementModal",
            {
                "thisDocument": component.get("v.thisDocument"),
                "relationshipRecord": component.get("v.relationshipRecord"),
                "curUser": component.get("v.curUser"),
                "trueFalseString": trueFalseString,
                "multiTrueFalseString": multiTrueFalseString,
                "thisMembership": component.get("v.thisMembership"),
                "isAgent": isAgent,
                "curMemContact": component.get("v.curMemContact")
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

    renderDocument: function(component, event, helper) {
        var contents = component.get("v.thisDocument.CSDA_Membership_Contents__r");
        var numOfCheckboxGroups = 0;

        var parsedContentArray = [];

        // Parse actual content to look for checkboxes
        // In every content, look for checkbox groups. Insert radio buttons grouped by checkbox groups.
        // Expecting this kind of string:
        // [Checkboxgroup:FirstGroup(Is)(Is Not)(am not)(am)]
        // Where each word surrounded by () is a checkbox option
        var checkboxStartTag = "[Checkboxgroup:";
        var checkboxEndTag = "]";

        // Expecting this kind of string:
        // [Multicheckbox:(Sample checkbox 1)(Sample checkbox 2)]
        var multiCheckStartTag = "[Multicheckbox:";
        var multiCheckEndTag = "]";
            

        if (contents == undefined) {
            return;
        }

        for (var i=0; i<contents.length; i++)
        {
            var headerObj = {
                type: "Header",
                content: contents[i].Name + '\n'
            }

            parsedContentArray.push(headerObj);

            var contentToParse = contents[i].Content__c;
            contentToParse = helper.modifyWithInserts(component, contentToParse);

            // Cut string down while populating into parsedContentArray
            while (contentToParse != "" && contentToParse != undefined)
            {
                var checkboxStartTagIndex = contentToParse.indexOf(checkboxStartTag);
                var checkboxEndTagIndex = contentToParse.indexOf(checkboxEndTag) + checkboxEndTag.length;

                var multiCheckStartTagIndex = contentToParse.indexOf(multiCheckStartTag);
                var multiCheckEndTagIndex = contentToParse.indexOf(multiCheckEndTag) + multiCheckEndTag.length;

                // If no checkbox group/multi group is found, put the rest of content into the array
                if (checkboxStartTagIndex == -1 && multiCheckStartTagIndex == -1)
                {
                    var textObj = {
                        type: "Text",
                        content: contentToParse
                    }
                    parsedContentArray.push(textObj);
                    contentToParse = "";
                }
                // If checkbox group/multi group is found, separate the content string to isolate the checkbox groups
                // Not considering if both are found.
                else if (checkboxStartTagIndex != -1)
                {
                    var textObj = {
                        type: "Text",
                        content: contentToParse.substring(0,checkboxStartTagIndex)
                    }
                    parsedContentArray.push(textObj);

                    //var checkboxGroupString = contentToParse.substring(checkboxStartTagIndex, checkboxEndTagIndex);

                    var checkboxObj = {
                        type: "Checkbox",
                        content: contentToParse.substring(checkboxStartTagIndex, checkboxEndTagIndex)
                    }
                    parsedContentArray.push(checkboxObj);

                    contentToParse = contentToParse.substring(checkboxEndTagIndex, contentToParse.length);
                    numOfCheckboxGroups++;
                }
                else if (multiCheckStartTagIndex != -1) {
                    var textObj = {
                        type: "Text",
                        content: contentToParse.substring(0,multiCheckStartTagIndex)
                    }
                    parsedContentArray.push(textObj);

                    var checkboxObj = {
                        type: "Multicheckbox",
                        content: contentToParse.substring(multiCheckStartTagIndex, multiCheckEndTagIndex)
                    }
                    parsedContentArray.push(checkboxObj);

                    contentToParse = contentToParse.substring(multiCheckEndTagIndex, contentToParse.length);
                }
            }
        }

        component.set("v.parsedContentArray", parsedContentArray);
        component.set("v.numOfCheckboxGroups", numOfCheckboxGroups);
    },

    modifyWithInserts: function(component, content) {
        if (content != undefined) {
            content = content.replace(new RegExp("INSERT CLIENT NAME", 'g'), component.get("v.thisMembership.Account__r.Name"));
            content = content.replace(new RegExp("INSERT CLIENT ADDRESS", 'g'), component.get("v.thisMembership.Registered_Address__c"));
            content = content.replace(new RegExp("INSERT AGENCY NAME", 'g'), component.get("v.agentContact.Third_Party_Account__c"));
            content = content.replace(new RegExp("INSERT AGENCY ADDRESS", 'g'), component.get("v.agentContact.Address__c") + ' ' + component.get("v.agentContact.City__c") + ' ' +
                component.get("v.agentContact.State__c") + ' ' + component.get("v.agentContact.Zip__c"));
            content = content.replace(new RegExp("INSERT AGENCY PHONE", 'g'), component.get("v.agentContact.Phone_Number__c"));
        }

        //component.set("v.contentToRender", contentToRender);s
        return content;
    },
})