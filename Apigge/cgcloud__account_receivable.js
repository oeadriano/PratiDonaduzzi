/**
 * Function that is called during the JavaScript Task execution.
 * @param {IntegrationEvent} event
 */
function formatDate(year, dateString) {
    var subStr =  dateString.substring(4).match(/.{1,2}/g)
    return `${year}-${subStr[0]}-${subStr[1]}`
}

function transformBqDataInSFJson(bqData, event) {

    //var year = bqData.f[4].v

    // event.log(`${bqData.f}`)

    // "User:Proprietario_Original__r.Codigo_SAP__c ": bqData.f[16].v ==  null ? bqData.f[17].v : bqData.f[16].v,
    // "User:Proprietario_Atual__r.Codigo_SAP__c": bqData.f[17].v,

    return {
        "cgcloud__Account__r.Codigo_SAP__c": bqData.f[0].v,
        "cgcloud__Amount_Open__c": bqData.f[1].v,
        "cgcloud__Amount__c": bqData.f[2].v,
        "cgcloud__Document_Type__c": bqData.f[3].v,
        "Ano_Exercicio__c": bqData.f[4].v,
        "cgcloud__Due_Date__c": bqData.f[5].v,        
        "cgcloud__External_Id__c": bqData.f[6].v,
        "cgcloud__Invoice_Status__c": bqData.f[7].v,
        "cgcloud__Receipt_Date__c":  bqData.f[11].v,
        "Codigo_SAP__c": bqData.f[9].v,
        "Data_Emissao__c": bqData.f[10].v,
        "Linha_Digitavel__c": bqData.f[12].v,
        "Nota_Fiscal__c": bqData.f[13].v,
        "Proprietario_Atual__r.Codigo_SAP__c": bqData.f[17].v,
        "Pedido__r.Codigo_Pedido_SAP__c": bqData.f[14].v,
        "Pedido_CGCloud__r.Codigo_Pedido_SAP__c": bqData.f[14].v,
    }
}

function executeScript(event) {

    const bqResponse =  JSON.parse(event.getParameter('`Task_2_responseBody`'))

    if(parseInt(bqResponse.totalRows) > 0) {
        event.setParameter('isHaveData', true)
        var outputData = bqResponse.rows.map(jsonData => transformBqDataInSFJson(jsonData, event))
        event.setParameter('records', outputData)
    }else {
        event.setParameter('isHaveData', false)
    }
}