({
	initializeRoleOptions : function(component) {
		var opts = [
            {value:"Contract signer", label:"Contract signer"},
            {value:"Head Designate", label:"Head Designate"},
            {value:"Applicant", label:"Applicant"},
            {value:"Principal Contact", label:"Principal Contact"}
        ];

        if (component.get("v.SQDSectionActive")) {
            opts.push(
                {value:"Data Processing", label:"Data Processing"},
                {value:"Credit", label:"Credit"},
                {value:"Metric Report", label:"Metric Report"},
                {value:"Responsible for sending data", label:"Responsible for sending data"}
            );
        }
        
        component.set("v.roleOptionList", opts);
	}
})