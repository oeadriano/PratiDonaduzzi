-- record type
SELECT id 
FROM RecordType 
WHERE SobjectType = 'Product2' and DeveloperName = 'Product_Group'

-- VB_MD_CGCLOUD_MATERIAL_CATEG_FAMILIA

/**
 * Function that is called during the JavaScript Task execution.
 * @param {IntegrationEvent} event
 */
function executeScript(event) {
  var jsonData = event.getParameter('`Task_2_connectorOutputPayload`');
  var recordTypeInfo = event.getParameter('RecordTypeID');
  

  function getData(jsonData) {
    return jsonData.map((data) => ({
      Name: data.Name,
      'cgcloud__Product_Template__r.Name':
        data.cgcloud__Product_Template__r_Name,
      RecordTypeId: recordTypeInfo,
      cgcloud__Consumer_Goods_Product_Code__c:
        data.cgcloud__Consumer_Goods_Product_Code__c,
      cgcloud__Product_Short_Code__c: data.cgcloud__Product_Short_Code__c,
      cgcloud__Description_1_Language_1__c:
        data.cgcloud__Description_1_Language_1__c,
      cgcloud__Short_Description_Language_1__c:
        data.cgcloud__Short_Description_Language_1__c,
      cgcloud__Product_Level__c: data.cgcloud__Product_Level__c,
      cgcloud__Is_Bill_Of_Material__c: data.cgcloud__Is_Bill_Of_Material__c,
      cgcloud__Consumer_Goods_External_Product_Id__c: data.cgcloud__Consumer_Goods_External_Product_Id__c
    }));
  }

  var outputData = getData(jsonData);

  event.setParameter('transformerResponse', outputData);
}