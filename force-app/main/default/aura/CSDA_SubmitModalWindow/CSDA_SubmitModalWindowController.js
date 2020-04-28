({
    // Call requestform's submit when submitted
	submit: function(component, event, helper) {
        component.getEvent("SubmitEvt").fire();
		component.destroy();
    },

    closeMe: function(component, event, helper) {
		component.destroy();
	},
})