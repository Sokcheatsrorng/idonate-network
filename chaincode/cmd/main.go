package main

import (
	"chaincode-donation/contract"
	"log"
	"github.com/hyperledger/fabric-contract-api-go/contractapi"
)

func main() {
		// Create an instance of DonationContract
		donationContract := new(contract.DonationContract)
	
		// Assign metadata to the contract
		// donationContract.Info.Contact.Name = "org.example.donationcontract"
		// donationContract.Info.Version = "0.0.1"
		// donationContract.Info.Description = "Donation management smart contract"
	
		// Optional license information (comment this out if the field doesn't exist in your framework)
		// donationContract.Info.License.Name = "Apache-2.0"
	

		// Create the chaincode
		chaincode, err := contractapi.NewChaincode(donationContract)
		if err != nil {
			log.Panicf("Error creating donation chaincode: %v", err)
		}
	
		// Start the chaincode
		if err := chaincode.Start(); err != nil {
			log.Panicf("Error starting donation chaincode: %v", err)
		}
}