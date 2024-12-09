package assettypes

import (
	"fmt"
	"strings"

	"github.com/hyperledger-labs/cc-tools/assets"
)

// DonationEvent Define the Donation asset for the event in donation systems
var DonationEvent = assets.AssetType{
	Tag:         "donationEvent",
	Label:       "Donation Event",
	Description: "- The purpose of the Donation Event is to Educate Poor Young Generation",

	// Props of the donation event
	Props: []assets.AssetProp{
		{
			// Composite Key
			Required: true,
			IsKey:    true,
			Tag:      "eventID",
			Label:    "Event ID",
			DataType: "string",
			// Only org1MSP can write
			Writers: []string{"org1MSP"}, // make this dynamic later
		},
		{
			Required: true,
			Tag:      "eventName",
			Label:    "Event Name",
			DataType: "string",
			// Validate function 
			Validate: func(eventName interface{}) error {
				nameStr := eventName.(string)
				if nameStr == "" {
					return fmt.Errorf("Event Name must be non-empty")
				}
				return nil
			},
			Writers: []string{"org1MSP"}, // Writing restricted to org1MSP
		},
		{
			Required: true,
			Tag:      "recipient",
			Label:    "Recipient Organization",
			DataType: "string",
			Writers: []string{"org1MSP"}, // Writing restricted to org1MSP
		},
		{
			Required: false,
			Tag:      "description",
			Label:    "Event Description",
			DataType: "string",
			Writers: []string{"org1MSP"},
		},
		{
			Required: true,
			Tag:      "email",
			Label:    "Email",
			DataType: "string",
			// Validate function
			Validate: func(email interface{}) error {
				emailStr := email.(string)
				if !strings.Contains(emailStr, "@") {
					return fmt.Errorf("Email must contain '@'")
				}
				return nil
			},
			Writers: []string{"org1MSP"},
		},
		{
			Required: true,
			Tag:      "timestamp",
			Label:    "Timestamp",
			DataType: "datetime",
			Writers: []string{"org1MSP"},
		},
		{
			Required: true,
			Tag:      "organization",
			Label:    "Organization",
			DataType: "string",
			Writers: []string{"org1MSP"}, // Writing restricted to org1MSP
		},
		{
			Required: false,
			Tag:      "donations",
			Label:    "Donations",
			DataType: "[]->donation", // Reference to the Donation assets (if defined as a separate asset type)
			Writers: []string{"org1MSP"}, // Writing restricted to org1MSP
		},
	},
}
