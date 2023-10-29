// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;


//interface for ownable contract
interface IDeployer {


    // event Donation(address indexed _from, string _type, uint256 _amount, uint256 _timestamp);

    function initializeChain(address _oxygenContract
                            , address _hcContract
                            , address _systemContract
                            , address _original_owner)  external;

    function setOriginalOwner(address _original_owner) external;


    function setOxygenContract(address _oxygenContract) external;

    
    function setHcContract(address _hcContract) external;


    function setSystemContract(address _systemContract) external;

    function setChainContracts() external;

    function transferOwners(address _newOwner) external;

    function verifyDeployment(address sysOwner, address systemContract, address pi_wallet, string memory _moboMac) external returns(string memory);

    function verifyContractSetup(address sysOwner, address systemContract) external returns(string memory);
   
    function verifySystemSetup(address sysOwner, address systemContract, address pi_wallet, string memory _moboMac) external returns(string memory);
   
    // ========================================= Private Functions =========================================

}