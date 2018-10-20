/*
 * Licensed to the Apache Software Foundation (ASF) under one
 * or more contributor license agreements.  See the NOTICE file
 * distributed with this work for additional information
 * regarding copyright ownership.  The ASF licenses this file
 * to you under the Apache License, Version 2.0 (the
 * "License"); you may not use this file except in compliance
 * with the License.  You may obtain a copy of the License at
 *
 * http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing,
 * software distributed under the License is distributed on an
 * "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
 * KIND, either express or implied.  See the License for the
 * specific language governing permissions and limitations
 * under the License.
 */

/*
 * The sample smart contract for documentation topic:
 * Writing Your First Blockchain Application
 */

package main

import (
	"bytes"
	"fmt"

	"github.com/hyperledger/fabric/core/chaincode/shim"
	sc "github.com/hyperledger/fabric/protos/peer"
	// this lib makes access control based on the cert attributes 
	"github.com/hyperledger/fabric/core/chaincode/lib/cid"
)

// Define the Smart Contract structure
type SmartContract struct {
}


func (s *SmartContract) Init(APIstub shim.ChaincodeStubInterface) sc.Response {
	return shim.Success(nil)
}

func (s *SmartContract) Invoke(APIstub shim.ChaincodeStubInterface) sc.Response {

	// Retrieve the requested Smart Contract function and arguments
	function, args := APIstub.GetFunctionAndParameters()
	// Route to the appropriate handler function to interact with the ledger appropriately
	if function == "queryItem" {
		return s.queryItem(APIstub, args)
	} else if function == "initLedger" {
		return s.initLedger(APIstub)
	} else if function == "addElement" {
		return s.addElement(APIstub, args)
	} else if function == "listElements" {
		return s.listElements(APIstub)
	}

	return shim.Error("Invalid Smart Contract function name.")
}

func (s *SmartContract) initLedger(APIstub shim.ChaincodeStubInterface) sc.Response {
	return shim.Success([]byte("Init ledger successfully"))
}

// This is an example of making access control decisions!
// There may be a variety of such checks.
// For example, the following function can be used for making access control decisions
// based on 'objectsledger.Admin' attribute value.
// So users who don't have such attribute will not have access to
// some functions.
func isAdmin(APIstub shim.ChaincodeStubInterface) bool {
	err := cid.AssertAttributeValue(APIstub, "objectsledger.Admin", "true")
	return err == nil
}

func (s *SmartContract) addElement(APIstub shim.ChaincodeStubInterface, args []string) sc.Response {
	// For example, only admins can add elements to ledger
	// (but all users can query info, see below functions 'queryItem', 'listElements')
	// This is only to demonstrate how to make access control decision.
	if !isAdmin(APIstub) {
		return shim.Error("Only admins are allowed to add element")
	}
	if len(args) != 2 {
		return shim.Error("Incorrect number of arguments. Expecting 2: ID, data")
	}
	elemID, elemData := args[0], args[1]
	// check if this element exists yet
	elemAsBytes, _ := APIstub.GetState(elemID)
	if elemAsBytes != nil {
		return shim.Error("The element with such id exists already")
	}
	APIstub.PutState(elemID, []byte(elemData))
	return shim.Success(nil)
}

func (s *SmartContract) queryItem(APIstub shim.ChaincodeStubInterface, args []string) sc.Response {
	if len(args) != 1 {
		return shim.Error("Need only 1 arg -- item id")
	}
	itemAsBytes, _ := APIstub.GetState(args[0])
	if itemAsBytes == nil {
		return shim.Error("There is no an item with such id")
	}
	return shim.Success(itemAsBytes)
}


func (s *SmartContract) listElements(APIstub shim.ChaincodeStubInterface) sc.Response {

	startKey := "1"
	endKey := "999999"

	resultsIterator, err := APIstub.GetStateByRange(startKey, endKey)
	if err != nil {
		return shim.Error(err.Error())
	}
	defer resultsIterator.Close()

	// buffer is a JSON array containing QueryResults
	var buffer bytes.Buffer
	buffer.WriteString("[")

	bArrayMemberAlreadyWritten := false
	for resultsIterator.HasNext() {
		queryResponse, err := resultsIterator.Next()
		if err != nil {
			return shim.Error(err.Error())
		}
		// Add a comma before array members, suppress it for the first array member
		if bArrayMemberAlreadyWritten == true {
			buffer.WriteString(",")
		}
		buffer.WriteString("{\"Key\":")
		buffer.WriteString("\"")
		buffer.WriteString(queryResponse.Key)
		buffer.WriteString("\"")

		buffer.WriteString(", \"Record\":")
		// Record is a JSON object, so we write as-is
		buffer.WriteString(string(queryResponse.Value))
		buffer.WriteString("}")
		bArrayMemberAlreadyWritten = true
	}
	buffer.WriteString("]")

	return shim.Success(buffer.Bytes())
}


// The main function is only relevant in unit test mode. Only included here for completeness.
func main() {

	// Create a new Smart Contract
	err := shim.Start(new(SmartContract))
	if err != nil {
		fmt.Printf("Error creating new Smart Contract: %s", err)
	}
}
