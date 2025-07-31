 {
  "operation": "upsert",
  "object": "Product2",
  "contentType": "CSV",
  "lineEnding": "CRLF",
  "externalIdFieldName": "Name"
}
Name,cgcloud__Product_Template__r.Name,RecordTypeId,cgcloud__Consumer_Goods_Product_Code__c,cgcloud__Product_Short_Code__c,cgcloud__Description_1_Language_1__c,cgcloud__Short_Description_Language_1__c,cgcloud__Product_Level__c,cgcloud__Is_Bill_Of_Material__c,cgcloud__Consumer_Goods_External_Product_Id__c
"VITAMINAS","Grupo de Produto","0124x000000aJvXAAU","VITAMINAS","VITAMINAS","VITAMINAS","VITAMINAS","Category","false","VITAMINAS"
"OTC","Grupo de Produto","0124x000000aJvXAAU","OTC","OTC","OTC","OTC","Category","false","OTC"
"OUTROS","Grupo de Produto","0124x000000aJvXAAU","OUTROS","OUTROS","OUTROS","OUTROS","Category","false","OUTROS"




/**
 * Function that is called during the JavaScript Task execution.
 * @param {IntegrationEvent} event
 */
function executeScript(event) {
  var jsonData = event.getParameter('`Task_2_connectorOutputPayload`');

  function getData(jsonData) {
    return jsonData.map((data) => ({
      'cgcloud__Child_Product__r.Name': data.cgcloud__Child_Product__r_Name,
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