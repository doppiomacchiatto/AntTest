/**
* Helper Class that saves the IDme JSONResponse to the Contact Object
*/
public class IdMeSaveProfile
{
    public List<Contact> findContact{get;set;}
    
    public Boolean saveIDmeProfile(Map<String, Object> JSONresponse, String contactId){
        Boolean isUpdated =  false;
        String firstName = (String)JSONresponse.get('fname');
        String lastName = (String)JSONresponse.get('lname');
        Boolean isValid = (Boolean)JSONresponse.get('verified');
        String typeAffiliation =(String)JSONresponse.get('affiliation');
        Contact contactInfo = new Contact();
        
        if(String.isNotBlank(contactId)){
             findContact = [select id, IDmeValidation__c from Contact where id =:contactId];
        }else{
            System.debug('The contactId was invalid: '+contactId);
        }
       
        if(findContact.size() == 1){
          contactInfo = findContact.get(findContact.size() - 1);
          contactInfo.IDmeValidation__c = isValid;
          //contactInfo.Type__c = typeAffiliation;
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
            }catch(DmlException dmle){
              ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR,'A System Error Has Occured.: ' +dmle.getMessage() ));
              System.debug('An Exception Occured while updating your IdMe Affiliation' + dmle.getMessage());
            }
            catch(Exception e){
              ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR,'A System Error Has Occured. Please re-validate your affiliation.' +e.getMessage() ));
              System.debug('An Exception Occured while updating your IdMe Affiliation. : ' + e.getMessage());
            }
        return isUpdated;
  }
}