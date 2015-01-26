public class IdMeControllerV2 {

    public String code{get;set;}
    public String body{get;set;}
    public String accessToken{get;set;}
    public String affiliation{get;set;}
    public String email{get;set;}
    public String message{get;set;}
    public Boolean isValidated{get;set;}
    public String error{get;set;}
    public List<Contact> findContact{get;set;}
    public static final String clientId ='69c42560addee7012d81d188a7d75f40';
    public static final String clientSecret='52264fa118382d939841fef2c87418c7';
    public static final String redirectURI='https://na16.salesforce.com/apex/idme3';
    public static final String militaryURI='https://api.id.me/api/public/v2/military.json?&access_token=';
    public static final String grantType='authorization_code';
    public HttpResponse resToken;
    public PageReference init(){
       if ( ApexPages.currentPage().getParameters().get('code') != null ){
         code = ApexPages.currentPage().getParameters().get('code');
         //get the access token
         //Starts the validation orchestration.  There's a conversation between the oauth auth, then 
         //we validate the user.
         getAccessToken(code);
       }
       return null;
   }
 public void getAccessToken(String code) {
        //POST Request by using the authorization code
       Http httpToken = new Http();
       String httpMethod = 'POST';
       try{
           HttpRequest reqToken = new HttpRequest();
           reqToken.setEndpoint('https://api.id.me/oauth/token?&code='+code+'&redirect_uri='+EncodingUtil.urlEncode(redirectURI,'UTF-8')+'&client_id='+clientId+'&client_secret='+clientSecret+'&grant_type='+grantType);
           reqToken.setMethod(httpMethod);
           resToken = httpToken.send(reqToken);
           
           body = resToken.getBody();
    
           Map<String, Object> at= (Map<String, Object>)JSON.deserializeUntyped(body);
           accessToken = (String)at.get('access_token');
           
           if(resToken.getStatusCode() != 200){
            System.debug('ERROR http status code: ' + resToken.getStatusCode());
            throw new HttpCalloutException(String.valueOf(resToken.getStatusCode()));
           }
           if(String.isNotEmpty(accessToken)){
                getMilitaryProfile(accessToken);
            }
         }catch(System.CalloutException sce){
          ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR,'A System Error Has Occured.  Please try again later:'+sce.getMessage() ));
          System.debug('ERROR: '+ sce.getMessage());
         }
         catch(HttpCallOutException hce){
          ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR,'A System Error Has Occured.  Please try again later: Status Code='+hce.getMessage() ));
          System.debug('ERROR: '+ hce.getMessage());
         }
    }
 //TODO create generic method to call service - parametize access token if needed.
 public void getMilitaryProfile(String accessToken){
  //GET Military affiliation
       Http httpToken = new Http();
       String httpMethod = 'GET';
       try{
          HttpRequest reqToken = new HttpRequest();
          reqToken.setEndpoint(militaryUri+accessToken);
          reqToken.setMethod(httpMethod);
          resToken = httpToken.send(reqToken);
          body = resToken.getBody();
          
          Map<String, Object> JSONresponse = (Map<String, Object>)JSON.deserializeUntyped(body);
          isValidated = saveIDmeProfile(JSONresponse);
          if(isValidated){
            message = 'The ID.me validation was successfull';
          }else{
            message = 'The ID.me validation failed.  Please try again another time.';
          }
          //Refactor: when test is complete
          affiliation = (String)JSONresponse.get('affiliation');
          email = (String)JSONresponse.get('email');
        
     }catch(System.CalloutException sce){
          ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR,'A System Error Has Occured.  Please try again later:'+sce.getMessage() ));
          System.debug('ERROR: '+ sce.getMessage());
         }
    }
 //Refactor this code ti: Add a Helper class that saves the ID.me to the Contact object
  public Boolean saveIDmeProfile(Map<String, Object> JSONresponse){
    Boolean isUpdated =  false;
    String firstName = (String)JSONresponse.get('fname');
    String lastName = (String)JSONresponse.get('lname');
    Boolean isValid = (Boolean)JSONresponse.get('verified');
    String typeAffiliation =(String)JSONresponse.get('affiliation');
    Contact contactInfo = new Contact();
    findContact = [select id, IDmeValidation__c from Contact where FirstName =: firstName and LastName =: lastName];

    if(findContact.size() == 1){
      contactInfo = findContact.get(findContact.size() - 1);
      contactInfo.IDmeValidation__c = isValid;
   //   contactInfo.Type__c = typeAffiliation;
      }
      try{
        Database.SaveResult srList = Database.update(contactInfo,false);
        if (srList.isSuccess()) {
            // Operation was successful, so get the ID of the record that was processed
            System.debug('Successfully inserted account. Account ID: ' + srList.getId());
            isUpdated = true;
        }
        else {
         // Operation failed, so get all errors                
          for(Database.Error err : srList.getErrors()) {
              System.debug('The following error has occurred.');                    
              System.debug(err.getStatusCode() + ': ' + err.getMessage());
              System.debug('Contact fields that affected this error: ' + err.getFields());
            }
          }
        }catch(Exception e){
          ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR,'A System Error Has Occured. Please re-validate your affiliation.' +e.getMessage() ));
          System.debug('An Exception Occured while updating your IdMe Affiliation' + e.getMessage());
        }
    return isUpdated;
  }
}