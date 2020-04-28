({
	renderHeader : function(component, contentToRender) {
		// Create Headers of each content first
        $A.createComponents([
            ["ui:outputText",{
                "class": "contractSubHeaderText",
                "value": contentToRender.content
            }],
            ["div",{
                "class": "slds-border_top",
                "style": 'border-color: #632678;opacity:0.5'
            }],
            ],
            function(components, status, errorMessage){
                if (status === "SUCCESS") {
                    var body = component.get("v.body");
                    for (var j=0; j<components.length;j++)
                    {
                        body.push(components[j]);
                    }
                    component.set("v.body", body);
                }
                else if (status === "INCOMPLETE") {
                    console.log("No response from server or client is offline.")
                    // Show offline error
                }
                else if (status === "ERROR") {
                    console.log("Error: " + errorMessage);
                    // Show error message
                }
            }
        );
	},

	renderCheckbox : function(component, contentToRender) {
		var groupStartTag = "[Checkboxgroup:";
        var groupEndTag = "]";
        var startTag = "(!";
        var endTag = "!)";
        var trueFalseArray = component.get("v.trueFalseArray");

		var checkboxGroupString = contentToRender.content;
        var startTagIndex = checkboxGroupString.indexOf(startTag);
        var endTagIndex = checkboxGroupString.indexOf(endTag);

        // At this point a checkgroup has been found, so add one to this count.
        //numOfCheckboxGroups++;

        // Grab name of checkbox Group
        var checkboxGroupName = checkboxGroupString.substring(groupStartTag.length, startTagIndex);

        // Loop through the checkbox string, and create an inputradio for each checkbox.
        while (checkboxGroupString != "")
        {
            startTagIndex = checkboxGroupString.indexOf(startTag);
            endTagIndex = checkboxGroupString.indexOf(endTag);

            if (startTagIndex != -1)
            {
                var checkboxContent = checkboxGroupString.substring(startTagIndex+startTag.length, endTagIndex);

                $A.createComponent(
                    "ui:inputRadio",
                    {
                        "name": checkboxGroupName,
                        "label": checkboxContent,
                        "aura:id": "checkbox" + trueFalseArray.length,
                        "change": component.getReference("c.radioChange")
                    },
                    function(newButton, status, errorMessage){
                        //Add the new button to the body array
                        if (status === "SUCCESS") {
                            var body = component.get("v.body");
                            body.push(newButton);
                            component.set("v.body", body);
                        }
                        else if (status === "INCOMPLETE") {
                            console.log("No response from server or client is offline.")
                            // Show offline error
                        }
                        else if (status === "ERROR") {
                            console.log("Error: " + errorMessage);
                            // Show error message
                        }
                    }
                );

                checkboxGroupString = checkboxGroupString.substring(endTagIndex+endTag.length, checkboxGroupString.length);
                trueFalseArray.push("false");
            }
            else
            {
                checkboxGroupString = "";
            }
        }

        // First initializing true false array. This true false array is used to indicate values of each checkbox that is dynamically rendered.
        component.set("v.trueFalseArray", trueFalseArray);
	},

    renderText : function(component, contentToRender) {
        $A.createComponent(
            "ui:outputRichText",
            {
                "value": contentToRender.content
            },
            function(newButton, status, errorMessage){
                //Add the new button to the body array
                if (status === "SUCCESS") {
                    var body = component.get("v.body");
                    body.push(newButton);
                    component.set("v.body", body);
                }
                else if (status === "INCOMPLETE") {
                    console.log("No response from server or client is offline.")
                    // Show offline error
                }
                else if (status === "ERROR") {
                    console.log("Error: " + errorMessage);
                    // Show error message
                }
            }
        );
    },

    renderMultiCheckbox: function(component, contentToRender) {
        var groupStartTag = "[Multicheckbox:";
        var groupEndTag = "]";
        var startTag = "(!";
        var endTag = "!)";
        //var numOfCheckboxes = component.get("v.numOfCheckboxes");
        var multiTrueFalseArray = component.get("v.multiTrueFalseArray");

        var checkboxGroupString = contentToRender.content;
        var startTagIndex = checkboxGroupString.indexOf(startTag);
        var endTagIndex = checkboxGroupString.indexOf(endTag);

        // At this point a checkgroup has been found, so add one to this count.
        //numOfCheckboxGroups++;

        // Loop through the checkbox string, and create an inputradio for each checkbox.
        while (checkboxGroupString != "")
        {
            startTagIndex = checkboxGroupString.indexOf(startTag);
            endTagIndex = checkboxGroupString.indexOf(endTag);

            if (startTagIndex != -1)
            {
                var checkboxContent = checkboxGroupString.substring(startTagIndex+startTag.length, endTagIndex);

                (
                    "ui:inputCheckbox",
                    {
                        "label": checkboxContent,
                        "aura:id": "multiCheckbox" + multiTrueFalseArray.length,
                        "change": component.getReference("c.checkboxChange")
                    },
                    function(newButton, status, errorMessage){
                        //Add the new button to the body array
                        if (status === "SUCCESS") {
                            var body = component.get("v.body");
                            body.push(newButton);
                            component.set("v.body", body);
                        }
                        else if (status === "INCOMPLETE") {
                            console.log("No response from server or client is offline.")
                            // Show offline error
                        }
                        else if (status === "ERROR") {
                            console.log("Error: " + errorMessage);
                            // Show error message
                        }
                    }
                );

                checkboxGroupString = checkboxGroupString.substring(endTagIndex+endTag.length, checkboxGroupString.length);
                multiTrueFalseArray.push(false);
            }
            else
            {
                checkboxGroupString = "";
            }
        }

        component.set("v.multiTrueFalseArray", multiTrueFalseArray);
    },
})