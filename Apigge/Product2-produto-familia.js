--VB_MD_CGCLOUD_MATERIAL_HIERARQUIA

/**
 * Function that is called during the JavaScript Task execution.
 * @param {IntegrationEvent} event
 */
function executeScript(event) {
  var jsonData = event.getParameter('`Task_2_connectorOutputPayload`');

  function getData(jsonData) {
    return jsonData.map((data) => ({
      'cgcloud__Child_Product__r.Codigo_SAP__c':
        data.cgcloud__Child_Product__r_Name,
      'cgcloud__Parent_Product__r.Name': data.cgcloud__Parent_Product__r_Name,
      cgcloud__Structure_Type__c: data.cgcloud__Structure_Type__c,
      cgcloud__Valid_From__c: data.cgcloud__Valid_From__c,
      cgcloud__Valid_Thru__c: data.cgcloud__Valid_Thru__c,
      Chave_externa__c: data.Chave_externa__c,
    }));
  }

  var outputData = getData(jsonData);

  event.setParameter('transformerResponse', outputData);
}