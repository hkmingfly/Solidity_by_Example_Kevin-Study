// SPDX-License-Identifier: GPL-3.0
        
pragma solidity >=0.4.22 <0.9.0;

// This import is automatically injected by Remix
import "remix_tests.sol"; 
import "remix_accounts.sol";
import "../Contracts/1_Counter.sol";

// File name has to end with '_test.sol', this file can contain more than one testSuite contracts

contract testSuite {
    Counter public counter;
    // beforeEach() - Runs before each test
    // beforeAll() - Runs before all tests, means only run 1 time, then run other tests
    // afterEach() - Runs after each test
    // afterAll() - Runs after all tests
    function beforeEach() public {
        counter = new Counter();
    }

    function checkInc() public {
        counter.inc();
        Assert.equal(counter.get(), 1, 'Number equal 1');
    }
    

    function checkDec() public {
        counter.inc();
        counter.inc();
        counter.dec();
        Assert.equal(counter.get(), 1, 'Number equal 1');
    }
    



}
    