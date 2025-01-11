// SPDX-License-Identifier: GPL-3.0
        
pragma solidity >=0.4.22 <0.9.0;

// This import is automatically injected by Remix
import "remix_tests.sol"; 
import "remix_accounts.sol";
import "../Contracts/2_Owner.sol";

// File name has to end with '_test.sol', this file can contain more than one testSuite contracts
contract testSuite {
    Owner public owner;
    function beforeAll() public {
        owner = new Owner();
    }
		// accounts[0] = 0x5B38Da6a701c568545dCfcB03FcB875f56beddC4;
		// accounts[1] = 0xAb8483F64d9C6d1EcF9b849Ae677dD3315835cb2;
		// accounts[2] = 0x4B20993Bc481177ec7E8f571ceCaE8A9e22C02db;
		// accounts[3] = 0x78731D3Ca6b7E34aC0F824c42a7cC18A495cabaB;
		// accounts[4] = 0x617F2E2fD72FD9D5503197092aC168c91465E7f2;
    function checkGetOwner() public {
        Assert.equal(msg.sender, TestsAccounts.getAccount(1), "Invalid sender"); //testing fail account should be ddC4
    }
}
    