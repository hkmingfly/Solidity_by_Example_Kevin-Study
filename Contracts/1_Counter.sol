// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.8.2 <0.9.0;

/**
 * @title Storage
 * @dev Store & retrieve value in a variable
 * @custom:dev-run-script ./scripts/deploy_with_ethers.ts
 */
contract Counter {

    uint256 number;

    /**
     * @dev Store value in variable
     * @param num value to store
     */
    function set(uint256 num) public {
        number = num;
    }

    function inc() public {
        number ++ ;
    }

    function dec() public {
        number -- ;
    }

    function get() public view returns (uint256){
        return number;
    }
}