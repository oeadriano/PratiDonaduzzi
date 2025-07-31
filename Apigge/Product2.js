-- familia X produtos
cgcloud__Criterion_1_Product__r.Name = categoria(vitaminas)
cgcloud__Criterion_2_Product__r.Name = familia(LAvitan)

cgcloud__Parent_Product__r_Name 
MATERIAIS DE  MARKETING 

	-- familia tem produtos
	-- MARKETING - MATERIAIS DE  MARKETING
	-- CIMELIDE - GEN & EQ
	
-- familia X categoria
	-- categoria tem familias
	PRD_FAM
	
	
	



-- dados-prod.sap_view.VB_MD_CGCLOUD_MATERIAL LIMIT 1800 OFFSET ${offsetNumber}`,

/**
 * Function that is called during the JavaScript Task execution.
 * @param {IntegrationEvent} event
 */
function executeScript(event) {
  var jsonData = JSON.parse(event.getParameter('`Task_35_responseBody`'));
  var profileIDNumber = event.getParameter('ProfileID');

  function getData(jsonData) {
    return jsonData.rows.map((jsonData) => ({
      N_Europeu_Artigo_EAN__c: jsonData.f[0].v,
      Codigo_SAP__c: jsonData.f[1].v,
      Name: jsonData.f[2].v,
      Principio_Ativo__c: jsonData.f[3].v,
      Generico__c: jsonData.f[4].v,
      Lista__c: jsonData.f[5].v,
      Codigo_Produto_Ministerio_Saude__c: jsonData.f[6].v,
      LINHA__c: jsonData.f[7].v,
      'Status_Produto__r.C_digo_SAP__c': jsonData.f[8].v,
      Produto_Controlado__c: jsonData.f[9].v,
      'Grupo_de_mercadoria__r.C_digo_SAP__c': jsonData.f[10].v,
      Fabricante__c: jsonData.f[11].v,
      Caixa_Padrao__c: jsonData.f[12].v,
      IPI__c: jsonData.f[13].v,
      Farmacia_Popular__c: jsonData.f[14].v,
      Family: jsonData.f[15].v,
      PROD_CLASSEI__c: jsonData.f[16].v,
      PROD_FATOR__c: jsonData.f[17].v,
      NMC__c: jsonData.f[18].v,
      GRPMERCEXTERNO__c: jsonData.f[19].v,
      HIERARQUIA__c: jsonData.f[10].v,
      MANDT__c: jsonData.f[21].v,
      'Categoria_Produto_SAP__r.Codigo_Categoria_Produto__c': jsonData.f[22].v,
      DataLancamento__c: jsonData.f[23].v,
      RecordTypeId: profileIDNumber,
      'cgcloud__Product_Template__r.Name': jsonData.f[24].v,
      cgcloud__Consumer_Goods_Product_Code__c: jsonData.f[25].v,
      cgcloud__Consumer_Goods_External_Product_Id__c: jsonData.f[26].v,
      cgcloud__Product_Short_Code__c: jsonData.f[27].v,
      cgcloud__GTIN__c: jsonData.f[28].v,
      cgcloud__Description_1_Language_1__c: jsonData.f[29].v,
      cgcloud__Short_Description_Language_1__c: jsonData.f[30].v,
      cgcloud__Product_Level__c: jsonData.f[31].v,
      'cgcloud__Criterion_1_Product__r.Name': jsonData.f[32].v,
      'cgcloud__Criterion_2_Product__r.Name': jsonData.f[33].v,
      cgcloud__Is_Bill_Of_Material__c: jsonData.f[34].v,
      cgcloud__Category__c: jsonData.f[35].v,
      cgcloud__State__c: jsonData.f[36].v,
      cgcloud__Field_Valid_From__c: jsonData.f[37].v,
      cgcloud__Field_Valid_Thru__c: jsonData.f[38].v,
      cgcloud__KAM_Valid_From__c: jsonData.f[37].v,
      cgcloud__KAM_Valid_Thru__c: jsonData.f[38].v,
      IsActive: jsonData.f[39].v,
      Venda_somente_caixa_fechada__c: jsonData.f[40].v,
      cgcloud__Delivery_Valid_From__c: jsonData.f[37].v,
      cgcloud__Delivery_Valid_Thru__c: jsonData.f[38].v
    }));
  }

  var outputData = getData(jsonData);

  event.setParameter('transformerResponse', outputData);
}