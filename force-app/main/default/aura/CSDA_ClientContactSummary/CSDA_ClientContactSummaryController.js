({
	doInit : function(component, event, helper) {
        var getCurUser = component.get("c.getCurUser");
        $A.enqueueAction(getCurUser);
        getCurUser.setCallback(this, function(a){
            var state = a.getState();
            if (component.isValid() && state === "SUCCESS") {
                var respon = a.getReturnValue();
                component.set("v.curUser", respon);
            }
        });
	}
})