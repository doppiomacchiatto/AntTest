global class LiveAgentService {
    public String deploymentID {Get;set;}
    public String buttonId {Get;set;}
    public String orgId {Get;set;}
    public String proactiveId {Get;set;}
    
    //Hard Coded Live Agent Buttons for now - until 
    public LiveAgentService() {
        LiveChatDeployment lcd             = [SELECT DeveloperName,Id FROM LiveChatDeployment where developername = 'Cirrus_Deployment_2' limit 1];
        LiveChatButton     lcb             = [SELECT DeveloperName,Id FROM LiveChatButton WHERE DeveloperName     = 'PKB_Cirrus_Button'   limit 1];
        LiveChatButton     proactiveButton = [SELECT DeveloperName,Id FROM LiveChatButton WHERE DeveloperName     = 'Consumer_Public_Site_Chat_Button_Small' limit 1];
        deploymentID = lcd.id;
        buttonId     = lcb.id;
        proactiveId  = proactiveButton.id;
        orgId        = UserInfo.getOrganizationId();
        
    } 
}