window.sosData = window.sosData || {};
sosData.currentStep = 1;

//resetData();

getAllUsers();
showUsers();
fillInNames();

$('#org-id').text(sosData.orgId);

function fillInNames() {
    $('#service-presence-name').val(sosData.servicePresence.name);   
    $('#routing-config-name').val(sosData.routingConfig.name);    
	$('#queue-name').val(sosData.queue.name);    
	$('#permission-set-name').val(sosData.permissionSet.name);    
	$('#sos-deployment-name').val(sosData.sosDeployment.name); 
}

function escapeSoql(str) {
    return str.replace(/\\/g, '\\\\').replace(/'/g, "\\'");
}

function buildOption(selectBox, val, name, selected) {
    //Option not supported in IE9
    if (Option) {
        selectBox.append(new Option(name, val, false, selected));
    } else {
        selectBox.append($('<option></option>').val(val).text(name).prop('selected', selected));
    }
}

function selectedUsers() {
    $('#user-steps').show();
    $('#profile-steps').hide();
    $('.nextButton').show();
    $('.previousButton').prop('disabled', false);
	sosData.pathSelected = 'users';

    nextStep(5);
}

function selectedProfiles() {
    $('#user-steps').hide();
    $('#profile-steps').show();
    $('.nextButton').show();
    $('.previousButton').prop('disabled', false);
	sosData.pathSelected = 'profiles';

    nextStep(8);
}

function nextStep(jumpToStep) {
	var oldStep = $('#seven' + sosData.currentStep);
    var nextButton = $('.nextButton');
    var previousButton = $('.previousButton');

    if (jumpToStep) {
        sosData.currentStep = jumpToStep;
    } else if (sosData.currentStep == 4 && sosData.pathSelected == 'profiles') {
        sosData.currentStep = 8;
    } else {
        sosData.currentStep++;
    }

    var newStep = $('#seven' + sosData.currentStep);

    previousButton.prop('disabled', false);

    if (sosData.currentStep == 10 || sosData.currentStep == 7) {
        nextButton.hide();
    }

    oldStep.hide();
    newStep.show();
    stepText();

    //don't show next button on step 4 if path not selected
    if (sosData.currentStep == 4 && !sosData.pathSelected) {
        $('.nextButton').hide();
    } else if (sosData.currentStep == 10 || sosData.currentStep == 7) {
        nextButton.hide();
    } else {
       $('.nextButton').show();
    }
}

function previousStep() {
	var oldStep = $('#seven' + sosData.currentStep);
    var nextButton = $('.nextButton');
    var previousButton = $('.previousButton');

    if (sosData.currentStep == 8) {
        sosData.currentStep = 4;
    } else {
    	sosData.currentStep--;
    }

    var newStep = $('#seven' + sosData.currentStep);

    nextButton.show();

    if (sosData.currentStep == 1) {
        previousButton.prop('disabled',true);
    }

    oldStep.hide();
    newStep.show();
    $('.nextButton').show();
    stepText();
}

function stepText() {
	var textA;
    var textB;

    var userSteps = $('#user-steps');
    var profileSteps = $('#profile-steps');

    switch(sosData.currentStep) {
    	case 1:
            textA = 'Showing step 6a (' + sosData.currentStep + ' of 4)';
            textB = '';
            break;
        case 2:
            textA ='Showing step 6b (' + sosData.currentStep + ' of 4)';
            textB = '';
            break;
        case 3:
            textA ='Showing step 6c (' + sosData.currentStep + ' of 4)';
            textB = '';
            break;
        case 4:
            textA ='Showing step 6d (' + sosData.currentStep + ' of 4)';
            textB = '';
            break;
        case 5:
        case 8:
            textB ='1 of 3';
            textA = '';
            break;
        case 6:
        case 9:
            textB ='2 of 3';
            textA = '';
            break;
        case 7:
        case 10:
            textB ='3 of 3';
            textA = '';
            break;
    }

    var bName = '';

    if (sosData.currentStep < 5) {
        $('#step-a-buttons').show();
        $('#step-b-buttons').hide();
        userSteps.hide();
        profileSteps.hide();
    } else {
        $('#step-b-buttons').show();
        $('#step-a-buttons').hide();

        if (sosData.currentStep < 8) {
            userSteps.show();
            bName = 'Showing user step ';
        } else {
            profileSteps.show();
			bName = 'Showing profile step ';
        }
    }

    $('#stepNumA').text(textA);
    $('#stepNumB').text(bName + textB);

}

if (sforce.console.setCustomConsoleComponentWidth) {
    var passEverything = true;
    
    var laHostname = createLAHostname();

    if (laHostname) {
        $('.la-info').hide();
        $('#la-hostname').text(laHostname);
    }

    var q = "SELECT Id FROM ServiceChannel WHERE DeveloperName ='SOS'";
    var records;
    
    try {
   		records = soqlCall(q);
    } catch(err) {
        emailNick('service-channel-status');
        passEverything = false;
        $('#service-channel-edit').hide();
    }
    
    if (records && records.length) {
        sosData.serviceChannelId = records[0].Id;
    }
    
    try {
        q = "SELECT Id FROM SOSSession LIMIT 1";
        record = soqlCall(q);  
    } catch (err) {
        emailNick('sos-session-status');
        passEverything = false;
    }
    
    try {
        q = "SELECT Id FROM ServicePresenceStatus LIMIT 1";
        record = soqlCall(q);  
    } catch (err) {
        emailNick('service-presence-status');
        passEverything = false;
    }
    
    if (passEverything) {
        $('#bothPass').text('You have everything you need! Please proceed to Step 2.');
    }

} else {
    $('#release-pass').removeClass('pass').addClass('fail').text('FAIL');
}

function emailNick(failed) {
    $('#'+failed).addClass('fail').removeClass('pass').text('FAIL');
    $('#bothPass').hide();
    $('#email-nick').show();
}

//Verification (final step)
function checkServicePresenceStatus() {
    //check for Service Presence Status with specific name
    var q = "SELECT Id FROM ServicePresenceStatus WHERE DeveloperName = '" + escapeSoql(sosData.servicePresence.devName) + "'";
    var records = soqlCall(q);

    sosData.servicePresence.id = records.length && records[0].Id;
    if (sosData.servicePresence.id && sosData.serviceChannelId) {

        //check if correct service channel is selected for the service presence status
        q = "SELECT Id, ServiceChannelId FROM ServiceChannelStatus WHERE "
        + "ServicePresenceStatusId  = '" + escapeSoql(sosData.servicePresence.id) + "' AND "
        + "ServiceChannelId = '" + escapeSoql(sosData.serviceChannelId) + "'";
        var records2 = soqlCall(q);

        sosData.servicePresence.serviceChannel = !!records2.length;
    };

    if (sosData.servicePresence.id && sosData.servicePresence.serviceChannel) {
		passCheck('service-presence-status');
    } else if (sosData.servicePresence.id) {
        $('#service-presence-status-info').text('- Selected Channels should contain "SOS"');
        $('#service-presence-status-link').hide();
        $('#service-presence-status-direct-link').show().attr('href', '/'+sosData.servicePresence.id+'/e').text('Edit');
    } else {
        $('#service-presence-status-info').text('- Service Presence Status with name "'+sosData.servicePresence.name+'" does not exist');
    }
}

function checkRoutingConfig() {
    var q = "SELECT Id, ServiceChannelId FROM QueueRoutingConfig WHERE DeveloperName = '" + escapeSoql(sosData.routingConfig.devName) + "'";
    var records = soqlCall(q);

    if (records.length) {
        sosData.routingConfig.id = records[0].Id;
        sosData.routingConfig.serviceChannel = records[0].ServiceChannelId == sosData.serviceChannelId;
    }

    if (sosData.routingConfig.id && sosData.routingConfig.serviceChannel) {
        passCheck('routing-config');
    } else if (sosData.routingConfig.id) {
        $('#routing-config-info').text('- Service Channel should be "SOS"');
        $('#routing-config-link').hide();
        $('#routing-config-direct-link').show().attr('href', '/'+sosData.routingConfig.id+'/e').text('Edit');
    } else {
        $('#routing-config-info').text('- Routing Configuration with the name "'+sosData.routingConfig.name+'" does not exist');
    }
}

function checkQueue() {
    var q = "SELECT Id, QueueRoutingConfigId FROM Group WHERE DeveloperName = '" + escapeSoql(sosData.queue.devName) + "'";
    var records = soqlCall(q);

    if (records.length) {
        sosData.queue.id = records[0].Id;
        sosData.queue.routingConfig = records[0].QueueRoutingConfigId == sosData.routingConfig.id;

        q = "SELECT Id FROM QueueSobject WHERE "
        	+ "QueueId  = '" + escapeSoql(sosData.queue.id) + "' AND "
        	+ "SobjectType = 'SOSSession'";
        var records2 = soqlCall(q);

        sosData.queue.object = !!records2.length;
    }

    if (sosData.queue.id && sosData.queue.routingConfig && sosData.queue.object) {
        passCheck('queue');
    } else if (sosData.queue.id) {
        var editText;
        if (!sosData.queue.routingConfig && !sosData.queue.object) {
            editText = '- SOS Session should be a supported object and Route Configuration should be "'+sosData.routingConfig.name+'"';
        } else if (!sosData.queue.routingConfig) {
         	editText = '- Routing Configuration should be "'+sosData.routingConfig.name+'"';
        } else {
            editText = '- SOS Session should be a supported object';
        }

        $('#queue-info').text(editText);
        $('#queue-link').hide();
        $('#queue-direct-link').show().attr('href', '/p/own/Queue/e?id='+sosData.queue.id).text('Edit');
    } else {
        $('#queue-info').text('- Queue with the name "'+sosData.queue.name+'" does not exist');
    }
}

function checkPermissionSet() {
    var q = "SELECT Id FROM PermissionSet WHERE Name = '" + escapeSoql(sosData.permissionSet.devName) + "'";
    var records = soqlCall(q);

    sosData.permissionSet.id = records.length && records[0].Id;
    sosData.permissionSet.servicePresenceStatus = false;

    if (sosData.permissionSet.id && sosData.servicePresence.id) {

        //check if service presence status was assigned to the permission set
        q = "SELECT Id FROM SetupEntityAccess WHERE "
        	+ "ParentId  = '" + escapeSoql(sosData.permissionSet.id) + "' AND "
        	+ "SetupEntityId = '" + escapeSoql(sosData.servicePresence.id) + "'";
        var records2 = soqlCall(q);

        sosData.permissionSet.servicePresenceStatus = !!records2.length;
    }

    if (sosData.permissionSet.id && sosData.permissionSet.servicePresenceStatus) {
        passCheck('permission-set');
    } else if (sosData.permissionSet.id) {
        $('#permission-set-info').text('- Enabled Service Presence Status should contain "'+sosData.servicePresence.name+'"');
        $('#permission-set-link').hide();
        $('#permission-set-direct-link').show().attr('href', '/'+sosData.permissionSet.id+'/e?s=ServicePresenceStatusAccess').text('Edit');
    } else {
        $('#permission-set-info').text('- Permission Set with the name "'+sosData.permissionSet.name+'" does not exist');
    }
}

function checkSOSDeployment() {
    var q = "SELECT Id, QueueId, OptionsIsEnabled FROM SOSDeployment WHERE DeveloperName = '" + escapeSoql(sosData.sosDeployment.devName) + "'";
    var records = soqlCall(q);

    if (records.length) {
        sosData.sosDeployment.id = records[0].Id;
        sosData.sosDeployment.queue = records[0].QueueId == sosData.queue.id;
        sosData.sosDeployment.enabled = records[0].OptionsIsEnabled == 'true';

        //sosData.sosDeployment.shortId = records[0].Id.substr(0,15);
    }

    if (sosData.sosDeployment.id && sosData.sosDeployment.queue && sosData.sosDeployment.enabled) {
        passCheck('sos-deploy');
    } else if (sosData.sosDeployment.id) {
        if (!sosData.sosDeployment.queue && !sosData.sosDeployment.enabled) {
            editText = '- SOS Deployment is not enabled and appears to have an invalid Queue';
        } else if (!queueMatch) {
            editText = '- SOS Deployment appears to have an invaild Queue';
        } else {
            editText = '- SOS Deployment is not enabled'
        }

        $('#sos-deploy-info').text(editText);
        $('#sos-deploy-link').hide();
        $('#sos-deploy-direct-link').show().attr('href', '/'+sosData.sosDeployment.id+'/e').text('Edit');
    } else {
        $('#sos-deploy-info').text('- SOS Deployment with the name "'+sosData.sosDeployment.name+'" does not exist');
    }
}

function passCheck(id) {
    $('#'+id).removeClass('fail').addClass('pass').text('PASS');
    $('#'+id+'-info').text('');
}

function verifySetup() {
    //reset everything incase this is not the first time they opened this step
    $('#collapse_8 .accordion-toggle').show();
    $('#collapse_8 .pass').removeClass('pass').addClass('fail').text('FAIL -');
    $('#collapse_8 .info').text('');
    $('.direct-link').hide();

    checkServicePresenceStatus();
	checkRoutingConfig();
	checkQueue();
	checkPermissionSet();
	checkSOSDeployment();
}

//individual Users check
function getAllUsers() {
    var q = "SELECT Id, Name FROM User WHERE IsActive = true AND (UserType = 'Standard' OR UserType = 'Guest') ORDER BY Name ASC NULLS FIRST"
    sosData.allUsers = soqlCall(q);
}

function showUsers() {
    $(".check-user").hide();
    var searchVal = $('#search-users').val();
    $('#user-list option').remove();

    var userList = $('#user-list');
    for (var i = 0; i < sosData.allUsers.length; i++) {
        if (!searchVal || sosData.allUsers[i].Name.toLowerCase().indexOf(searchVal.toLowerCase()) != -1) {
            buildOption(userList, sosData.allUsers[i].Id, sosData.allUsers[i].Name);
        }
    }
}

function clearSearch() {
    $('#search-users').val('');
	showUsers();
}

function userServiceCloudEnabled(userId) {
    //UserPermissionsLiveAgentUser UserPermissionsSupportUser
    var q = "SELECT UserPermissionsSupportUser FROM User WHERE Id = '" + escapeSoql(userId) + "'";
    var records = soqlCall(q);

    if (!records.length) {
        return false;
    }

    return records[0].UserPermissionsSupportUser == 'true';
}

//check group members
function userAssignedPermissionSet(userId) {
    if (!sosData.permissionSet.id) {
        return false;
    }

    var q = "SELECT Id FROM PermissionSetAssignment "
     	+ "WHERE PermissionSetId = '" + escapeSoql(sosData.permissionSet.id) + "' AND "
    	+ "AssigneeId = '" + escapeSoql(userId) + "'";
    var records = soqlCall(q);

    
    if (records.length) {
        return true;
    }
   
    //Check if permission assigned to profile
    q = "SELECT ProfileId FROM User WHERE Id = '" + escapeSoql(userId) + "'";
    records = soqlCall(q);
    
    if (!records.length) {
        //should never happen
        alert('Issue checking user, please reload the page.');
        return false;
    }
    
    var profileId = records[0].ProfileId;
    
    q = "SELECT Id FROM PermissionSet WHERE ProfileId = '" + escapeSoql(profileId) + "'";
    
    var allPermissions = soqlCall(q);
    
    if (!allPermissions.length) {
        //no permissions assigned to this profile
        return false;
    }
    
    if (!sosData.servicePresence.id) {
        return false;
    }
    
    q = "SELECT ParentId FROM SetupEntityAccess WHERE SetupEntityId  = '" + escapeSoql(sosData.servicePresence.id) + "'";
    var allServicePresenceRules = soqlCall(q);
    
    if (!allServicePresenceRules.length) {
        return false;
    }
    
    for (var i = 0; i < allServicePresenceRules.length; i++) {
        for (var j = 0; j < allPermissions.length; j++) {
            if (allServicePresenceRules[i].ParentId == allPermissions[j].Id) {
                return true;
            }
        }
    }
    return false;
}

function userQueueMember(userId) {
    if (!sosData.queue.id) {
        return false;
    }

    var q = "SELECT Id FROM GroupMember "
    	+ "WHERE GroupId  = '" + escapeSoql(sosData.queue.id) + "' AND "
    	+ "UserOrGroupId  = '" + escapeSoql(userId) + "'";
    var records = soqlCall(q);

    if (!records.length) {
        return false;
    }

    return true;
}

function setupUser() {
    var userId = $("#setup-user-list option:selected").val();

    if (!userId) {
        alert('No user selected.');
        return;
    }

    $('.check-user').show();
 
    var enableServiceCloudResult = enableServiceCloud();
  	setupUserResult(enableServiceCloudResult, 'service-cloud');
    
    var addToQueueResult = addUserToQueue();
    setupUserResult(addToQueueResult, 'permission-set-assigned');
    
    var addToPermissionSetResult = addUserToPermissionSet();
    setupUserResult(addToPermissionSetResult, 'queue-member');
}

function setupUserResult(resultData, id) {
    var status = $('#'+id);
    $('#'+id+'-info').text('- '+resultData.msg);
    
    if (resultData.success) {
        status.text('PASS').addClass('pass').removeClass('fail');
    } else {
        status.text('FAIL').addClass('fail').removeClass('pass');
    }
}

function createLAHostname() {
    var currentHostname = window.location.hostname;

    if (currentHostname.indexOf('gs0.') !== -1) {
    	return 'd.la.gus.salesforce.com';

    } else if (currentHostname.indexOf('na1-blitz03.') !== -1) {
 		return 'd.la-blitz04.soma.salesforce.com';

    }  else if (currentHostname.indexOf('na1-blitz02.') !== -1) {
 		return 'd.la-blitz03.soma.salesforce.com';

    }  else if (currentHostname.indexOf('na1-blitz04.') !== -1) {
 		return 'd.la-blitz01.soma.salesforce.com';

    } else if (currentHostname.indexOf('na1.') !== -1 ||
               currentHostname.indexOf('na5.') !== -1 ||
               currentHostname.indexOf('na6.') !== -1) {
 		return 'd.la1s1.salesforceliveagent.com';

    } else if (currentHostname.indexOf('cs1.') !== -1 ||
               currentHostname.indexOf('cs3.') !== -1 ||
               currentHostname.indexOf('cs12.') !== -1) {
 		return 'd.la1cs.salesforceliveagent.com';

    } else if (currentHostname.indexOf('na0.') !== -1 ||
               currentHostname.indexOf('na3.') !== -1) {
 		return 'd.la1a1.salesforceliveagent.com';

    } else if (currentHostname.indexOf('cs2.') !== -1 ||
               currentHostname.indexOf('cs4.') !== -1 ||
               currentHostname.indexOf('cs13.') !== -1) {
 		return 'd.la2cs.salesforceliveagent.com';

    } else if (currentHostname.indexOf('na8.') !== -1 ||
               currentHostname.indexOf('na9.') !== -1 ||
               currentHostname.indexOf('na10.') !== -1 ||
               currentHostname.indexOf('eu1.') !== -1) {
 		return 'd.la1c1.salesforceliveagent.com';

    } else if (currentHostname.indexOf('cs8.') !== -1) {
 		return 'd.la5cs.salesforceliveagent.com';

    } else if (currentHostname.indexOf('cs7.') !== -1 ||
               currentHostname.indexOf('cs14.') !== -1) {
 		return 'd.la7cs.salesforceliveagent.com';

    } else if (currentHostname.indexOf('na2.') !== -1 ||
               currentHostname.indexOf('na15.') !== -1) {
 		return 'd.la2c1.salesforceliveagent.com';

    } else if (currentHostname.indexOf('cs15.') !== -1 ||
               currentHostname.indexOf('cs16.') !== -1 ||
               currentHostname.indexOf('cs19.') !== -1) {
 		return 'd.la2c1cs.salesforceliveagent.com';

    } else if (currentHostname.indexOf('na19.') !== -1) {
 		return 'd.la3-c1-chi.salesforceliveagent.com';

    } else if (currentHostname.indexOf('cs23.') !== -1) {
 		return 'd.la3-c1cs-chi.salesforceliveagent.com';

    } else if (currentHostname.indexOf('cs24.') !== -1) {
 		return 'd.la3-c2cs-chi.salesforceliveagent.com';

    } else if (currentHostname.indexOf('na7.') !== -1 ||
               currentHostname.indexOf('na11.') !== -1 ||
               currentHostname.indexOf('na12.') !== -1 ||
               currentHostname.indexOf('na14.') !== -1) {
 		return 'd.la1w1.salesforceliveagent.com';

    } else if (currentHostname.indexOf('cs10.') !== -1) {
 		return 'd.la6cs.salesforceliveagent.com';

    } else if (currentHostname.indexOf('cs9.') !== -1 ||
               currentHostname.indexOf('cs11.') !== -1) {
 		return 'd.la8cs.salesforceliveagent.com';

    } else if (currentHostname.indexOf('na4.') !== -1 ||
               currentHostname.indexOf('eu2.') !== -1) {
 		return 'd.la2w1.salesforceliveagent.com';

    } else if (currentHostname.indexOf('cs17.') !== -1 ||
               currentHostname.indexOf('cs18.') !== -1 ||
               currentHostname.indexOf('cs20.') !== -1) {
 		return 'd.la2w1cs.salesforceliveagent.com';

    } else if (currentHostname.indexOf('na16.') !== -1 ||
               currentHostname.indexOf('eu3.') !== -1 ||
               currentHostname.indexOf('eu4.') !== -1 ||
               currentHostname.indexOf('eu0.') !== -1) {
 		return 'd.la2w2.salesforceliveagent.com';

    } else if (currentHostname.indexOf('na17.') !== -1) {
 		return 'd.la3-c1-was.salesforceliveagent.com';

    } else if (currentHostname.indexOf('cs21.') !== -1) {
 		return 'd.la3-c1cs-was.salesforceliveagent.com';

    } else if (currentHostname.indexOf('cs22.') !== -1) {
 		return 'd.la3-c2cs-was.salesforceliveagent.com';

    } else if (currentHostname.indexOf('ap0.') !== -1 ||
               currentHostname.indexOf('ap1.') !== -1) {
 		return 'd.la1t1.salesforceliveagent.com';

    } else if (currentHostname.indexOf('cs5.') !== -1) {
 		return 'd.la9cs.salesforceliveagent.com';

    } else if (currentHostname.indexOf('cs6.') !== -1) {
 		return 'd.la10cs.salesforceliveagent.com';
    }

	return false;
}

function soqlCall(query) {
    var queryResult = sforce.connection.query(query);
    return queryResult.getArray('records');
}

//ON events
$('.previousButton').click(function() {
    previousStep();
});

$('.nextButton').click(function() {
    nextStep();
});

$('#select-users').click(function() {
    selectedUsers();
});

$('#select-profiles').click(function() {
    selectedProfiles();
});

$('#check-again').click(function() {
    verifySetup();
});

$('#find-users-button').click(function() {
    showUsers();
});

$('#setup-user-button').click(function() {
    setupUser();
});

$('#clear-search-button').click(function() {
    clearSearch();
});


//NOT SURE HOW TO CHECK:
// - presence widget (prob can't as we wouldn't know which app)
