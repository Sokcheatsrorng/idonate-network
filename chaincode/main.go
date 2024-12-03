/*
SPDX-License-Identifier: Apache-2.0
*/

package main

import (

	"fmt"

	"github.com/hyperledger/fabric-contract-api-go/contractapi"
)

// Chaincode implements the Hyperledger Fabric smart contract interface
type Chaincode struct {
	contractapi.Contract
}

// InitLedger initializes the ledger
func (c *Chaincode) InitLedger(ctx contractapi.TransactionContextInterface) error {
	fmt.Println("Initialized Ledger")
	return nil
}

// QueryBlockchain queries the ledger by key
func (c *Chaincode) QueryBlockchain(ctx contractapi.TransactionContextInterface, key string) (string, error) {
	data, err := ctx.GetStub().GetState(key)
	if err != nil {
		return "", fmt.Errorf("failed to read from world state: %v", err)
	}
	if data == nil {
		return "", fmt.Errorf("%s does not exist", key)
	}

	fmt.Println(string(data))
	return string(data), nil
}

// InvokeTransaction writes a transaction payload to the ledger
func (c *Chaincode) InvokeTransaction(ctx contractapi.TransactionContextInterface, id string, jsonPayload string) error {
	err := ctx.GetStub().PutState(id, []byte(jsonPayload))
	if err != nil {
		return fmt.Errorf("failed to write to world state: %v", err)
	}

	fmt.Println("Transaction committed to the ledger")
	return nil
}

func main() {
	chaincode, err := contractapi.NewChaincode(new(Chaincode))
	if err != nil {
		fmt.Printf("Error creating chaincode: %v\n", err)
		return
	}

	if err := chaincode.Start(); err != nil {
		fmt.Printf("Error starting chaincode: %v\n", err)
	}
}