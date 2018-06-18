/*
# Copyright IBM Corp. All Rights Reserved.
#
# SPDX-License-Identifier: Apache-2.0
*/

'use strict';
const shim = require('fabric-shim');
const util = require('util');

let Chaincode = class {

  // The Init method is called when the Smart Contract 'fabcar' is instantiated by the blockchain network
  // Best practice is to have any Ledger initialization in separate function -- see initLedger()
  async Init(stub) {
    console.info('=========== Instantiated fabcar chaincode ===========');
    return shim.success();
  }

  // The Invoke method is called as a result of an application request to run the Smart Contract
  // 'fabcar'. The calling application program has also specified the particular smart contract
  // function to be called, with arguments
  async Invoke(stub) {
    let ret = stub.getFunctionAndParameters();
    console.info(ret);

    let method = this[ret.fcn];
    if (!method) {
      console.error('no function of name:' + ret.fcn + ' found');
      throw new Error('Received unknown function ' + ret.fcn + ' invocation');
    }
    try {
      let payload = await method(stub, ret.params);
      return shim.success(payload);
    } catch (err) {
      console.log(err);
      return shim.error(err);
    }
  }

/*args = id, name*/
async addEquipmentType(stub, args){

console.info('============= START : addEquipmentType ===========');
    if (args.length != 2) {
      throw new Error('Incorrect number of arguments. Expecting 2');
    }

    var type = {
      dataType: 'EquipmentType',
      name: args[1]
    };
    //type.dataType

    await stub.putState(args[0], Buffer.from(JSON.stringify(type)));
    console.info('============= END : addEquipmentType ===========');

}
/*args = id, name*/
async updEquipmentType(stub, args){
 console.info('============= START : updEquipmentType ===========');
    if (args.length != 2) {
      throw new Error('Incorrect number of arguments. Expecting 2');
    }

    let typeAsBytes = await stub.getState(args[0]);
    let type = JSON.parse(typeAsBytes);
    type.name = args[1];

    await stub.putState(args[0], Buffer.from(JSON.stringify(type)));
    console.info('============= END : updEquipmentType ===========');


}


 function standardQuery(stub, query){
 let iterator = await stub.getQueryResult(JSON.stringify(query));

    let allResults = [];
    while (true) {
      let res = await iterator.next();

      if (res.value && res.value.value.toString()) {
        let jsonRes = {};
        console.log(res.value.value.toString('utf8'));

        jsonRes.Key = res.value.key;
        try {
          jsonRes.Record = JSON.parse(res.value.value.toString('utf8'));
        } catch (err) {
          console.log(err);
          jsonRes.Record = res.value.value.toString('utf8');
        }
        allResults.push(jsonRes);
      }
      if (res.done) {
        console.log('end of data');
        await iterator.close();
        console.info(allResults);
        return Buffer.from(JSON.stringify(allResults));
      }
    }

}




async listEquipmentType(stub, args){
    console.info('============= START : listType ===========');
    let query={selector: {        
                dataType: {
                  $eq: 'EquipmentType'
                }
              }};
   return standardQuery(stub,query);
}
 
async addEvent(stub,args){

}


async listEvents(stub,args){

}
/*
 user 
  add 
  upd
  list

 event 
  add
   list
*/


};

shim.start(new Chaincode());
