/**
 * Function that is called during the JavaScript Task execution.
 * @param {IntegrationEvent} event
 */
function executeScript(event) {
  var jsonData = JSON.parse(event.getParameter('cloudsql-response'));
  var recordTypeIDinfo = event.getParameter('RecordTypeID');

  function getData(jsonData) {
    return jsonData.map((jsonData) => ({
      'cgcloud__product__r.codigo_sap__c':
      jsonData.cgcloud__product__r_codigo_sap__c,
      'cgcloud__Tour__r.Chave_Externa__c': jsonData.tour,
      'cgcloud__inventory_template__r.name':
      jsonData.cgcloud__inventory_template__r_name,
      cgcloud__phase__c: jsonData.cgcloud__phase__c,
      cgcloud__initial_inventory__c: jsonData.cgcloud__initial_inventory__c,
      cgcloud__invalid__c: jsonData.cgcloud__invalid__c,
      //RecordTypeId: recordTypeIDinfo,
      'record_type.name': jsonData.record_type_name,
      cgcloud__valid_from__c: jsonData.cgcloud__valid_from__c,
      cgcloud__valid_thru__c: jsonData.cgcloud__valid_thru__c,
      Prazo_de_Validade_Meses__c: jsonData.prazo_de_validade_meses__c,
      cgcloud__description_language_1__c: jsonData.cgcloud__description_language_1__c,
      chave_externa__c: jsonData.chave_externa__c,
    }));
  }

  // function formatDate(date) {
  //   var formattedDate;

  //   if (typeof date !== 'string' || date.length === 0) {
  //     return (formattedDate = '');
  //   } else {
  //     const year = date.substr(0, 4);
  //     const month = date.substr(4, 2);
  //     const day = date.substr(6, 2);
  //     return (formattedDate = `${year}-${month}-${day}`);
  //   }
  // }

  var outputData = getData(jsonData);

  event.setParameter('transformerResponse', outputData);
}