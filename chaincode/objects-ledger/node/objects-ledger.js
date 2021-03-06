'use strict';
/*
# Copyright IBM Corp. All Rights Reserved.
#
# SPDX-License-Identifier: Apache-2.0
*/
/*
 * Modified by Vlad Duplyakin https://github.com/duplyakin
 */

const shim = require('fabric-shim');
const util = require('util'); 
const ClientIdentity = require('fabric-shim').ClientIdentity;


let Chaincode = class {

  // The Init method is called when the Smart Contract 'objects-ledger' is instantiated by the blockchain network
  // Best practice is to have any Ledger initialization in separate function -- see initLedger()
  async Init(stub) {
    console.info('=========== Instantiated objects-ledger chaincode ===========');
    return shim.success();
  }

  // The Invoke method is called as a result of an application request to run the Smart Contract
  // 'objects-ledger'. The calling application program has also specified the particular smart contract
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

  async initLedger(stub, args) {
    console.info('============= START : Initialize Ledger ===========');
    console.info('============= END : Initialize Ledger ===========');
  }

async addElement(stub, args) {
  console.info('============= START : addEvent ===========');
    if (args.length != 2) {
      throw new Error('Incorrect number of arguments. Expecting 2: ID, data');
    }

    await stub.putState(args[0], Buffer.from(JSON.stringify(args[1])));
    console.info('============= END : addEvent ===========');
}


async listElements(stub,  args) {
    console.info('============= START : listEvents ===========');
    if (args.length != 1) {
        throw new Error('Incorrect number of arguments. Expecting 1: datatype');
    }
    let query = {
        "selector":{
            "_id": { "$gt": null }
        }
    };
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
async queryItem(stub, args) {
  console.info('============= START : queryItem ===========');
    /*let query={selector: {
                Key: {
                  $eq: args[0]
              }}};
    */
    let res = await stub.getState(args[0]);

    return Buffer.from(JSON.stringify(res));

  console.info('============= END : queryItem ===========');
}





};

shim.start(new Chaincode());
