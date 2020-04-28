({
	doInit : function(component, event, helper) {
        var contentToRender = component.get("v.contentToRender");

		// Depending on type of contentToRender, we create the component dynamically
		if (contentToRender.type == "Header") {
			helper.renderHeader(component, contentToRender);
		}
		else if (contentToRender.type == "Checkbox") {
			helper.renderCheckbox(component, contentToRender);
		}
		else if (contentToRender.type == "Text") {
			helper.renderText(component, contentToRender);
		}
        else if (contentToRender.type == 'Multicheckbox') {
            helper.renderMultiCheckbox(component, contentToRender);
        }
	},

    // This will be called when any of the dynamically created radio buttons are clicked
	radioChange: function(component, event, helper) {
        // RadioName is the checkbox Group Name
        var clickedRadioName = event.getSource().get("v.name");
        // RadioID is the auraID
        var clickedRadioID = event.getSource().getLocalId();
        var trueFalseArray = component.get("v.trueFalseArray");

        // Looping through all checkboxes that exist from the perspective of parent component. 
        for (var i in trueFalseArray)
        {
            var curAuraID = 'checkbox' + i;
            
            // If the clicked radio is in the same checkbox group, but is not the one that is clicked, then we set value to false. 
            // Need to do this because salesforce has a bug where radio button values are not updated correctly. This is the only workaround.
            if (component.find(curAuraID) != undefined && component.find(curAuraID).get("v.name") == clickedRadioName && curAuraID != clickedRadioID) {
                trueFalseArray[i] = "false";
            }
            
            if (curAuraID == clickedRadioID) {
            	trueFalseArray[i] = "true";
            }
        }

        console.log(trueFalseArray);
        component.set("v.trueFalseArray", trueFalseArray);
    },

    checkboxChange: function(component, event, helper) {
        // RadioID is the auraID
        var clickedCheckboxID = event.getSource().getLocalId();
        var multiTrueFalseArray = component.get("v.multiTrueFalseArray");

        // Looping through all checkboxes that exist from the perspective of parent component. 
        for (var i in multiTrueFalseArray)
        {
            var curAuraID = 'multiCheckbox' + i;
            
            if (curAuraID == clickedCheckboxID) {
                multiTrueFalseArray[i] = component.find(curAuraID).get("v.value");
            }
        }

        console.log(multiTrueFalseArray);
        component.set("v.multiTrueFalseArray", trueFmultiTrueFalseArrayalseArray);
    }
})