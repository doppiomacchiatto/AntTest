public class Integration {
// The ExternalOrder class holds a string and integer
// received from the external fulfillment system.
public class ExternalOrder {
	public String id {get; set;}
	public Integer order_number {get; set;}
}
// The postOrder method integrates the local Force.com invoicing system
// with a remote fulfillment system; specifically, by posting data about
// closed orders to the remote system. Functionally, the method 1) prepares
// JSON-formatted data to send to the remote service, 2) makes an HTTP call
// to send the prepared data to the remote service, and then 3) processes
// any JSON-formatted data returned by the remote service to update the
// local Invoices with the corresponding external IDs in the remote system.
@future (callout=true) // indicates that this is an asynchronous call
public static void postOrder(List<Id> invoiceIds) {
	// 1) see above
	// Create a JSON generator object
	JSONGenerator gen = JSON.createGenerator(true);
	// open the JSON generator
	gen.writeStartArray();
	// interate through the list of invoices passed in to the call
	// writing each invoice ID to the array
	for (Id invoiceId : invoiceIds) {
	gen.writeStartObject();
	gen.writeStringField('id', invoiceId);
	gen.writeEndObject();
}
	// close the JSON generator
	gen.writeEndArray();
	// create a string from the JSON generator
	String jsonOrders = gen.getAsString();
	// debugging call, which you can check in debug logs
	System.debug('jsonOrders: ' + jsonOrders);
	// 2) see above
	// create an HTTPrequest object
	HttpRequest req = new HttpRequest();
	// set up the HTTP request with a method, endpoint, header, and body
	req.setMethod('POST');
	// DON'T FORGET TO UPDATE THE FOLLOWING LINE WITH YOUR APP NAME
	req.setEndpoint('https://calm-meadow-8418.herokuapp.com/order');
	req.setHeader('Content-Type', 'application/json');
	req.setBody(jsonOrders);
	// create a new HTTP object
	Http http = new Http();
	// create a new HTTP response for receiving the remote response
	// then use it to send the configured HTTPrequest
	HTTPResponse res = http.send(req);
	// debugging call, which you can check in debug logs
	System.debug('Fulfillment service returned '+ res.getBody());
	// 3) see above
	// Examine the status code from the HTTPResponse
	// If status code != 200, write debugging information, done
	if (res.getStatusCode() != 200) {
	System.debug('Error from ' + req.getEndpoint() + ' : ' +
	res.getStatusCode() + ' ' + res.getStatus());
}
// If status code = 200, update each Invoice
// with the external ID returned by the fulfillment service.
else {
// Retrieve all of the Invoice records
// originally passed into the method call to prep for update.
	List<Invoice__c> invoices =
	[SELECT Id FROM Invoice__c WHERE Id IN :invoiceIds];
	// Create a list of external orders by deserializing the
	// JSON data returned by the fulfillment service.
	List<ExternalOrder> orders =
	(List<ExternalOrder>)JSON.deserialize(res.getBody(),
	List<ExternalOrder>.class);
	// Create a map of Invoice IDs from the retrieved
	// invoices list.
	Map<Id, Invoice__c> invoiceMap =
	new Map<Id, Invoice__c>(invoices);
	// Update the order numbers in the invoices
	for ( ExternalOrder order : orders ) {
	Invoice__c invoice = invoiceMap.get(order.id);
	invoice.Order_Id__c = String.valueOf(order.order_number);
	}
	// Update all invoices in the database with a bulk update
	update invoices;
	}
	}
}