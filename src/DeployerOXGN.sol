// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

import "@openzeppelin/contracts/access/Ownable.sol";
// #Initializable

import "./IOxygenChain.sol";
import "./IHealingCredit.sol";
// import "./IDefaultSystem.sol";
// import ownable contract from openzeppelin
// import "@openzeppelin/contracts/access/Ownable.sol";

import "./DefaultSystem.sol";


import "./OutPut.sol";

import "./IDeployer.sol";

/// new contract to initialize oxygen chain
contract DeployerOXGN is Ownable, IDeployer  {
    //owner of the contract
    address public original_owner;
    
    address public oxygenContract;
    address public hcContract;
    address public defaultSystemContract;

    uint16 public step=3;
    //constructor
    constructor() {
        step=6;
        // _transferOwnership(msg.sender);
        // __Ownable_init();
        original_owner = msg.sender;
    }

    function initializeChain(address _oxygenContract
                            , address _hcContract
                            , address _systemContract
                            , address _original_owner) public onlyOwner{
        // require(original_owner == msg.sender, "only original owner can set chain contracts");
            setOxygenContract(_oxygenContract);
            setHcContract(_hcContract);
            setSystemContract(_systemContract);
            setOriginalOwner(_original_owner);
            // if the below has an issue it will return with NOT OWNER error which is confusing
            setChainContracts();
    }

    function setOriginalOwner(address _original_owner) public onlyOwner{
        original_owner = _original_owner;
    }

    function setOxygenContract(address _oxygenContract) public onlyOwner{
        oxygenContract = _oxygenContract;
    }

    function setHcContract(address _hcContract) public onlyOwner{
        hcContract = _hcContract;
    }

    function setSystemContract(address _systemContract) public onlyOwner{
        defaultSystemContract = _systemContract;
    }

    function revertOwnership() public onlyOwner{
        Ownable(hcContract).transferOwnership(original_owner);
        Ownable(oxygenContract).transferOwnership(original_owner);
        Ownable(defaultSystemContract).transferOwnership(original_owner);
    }

    function setChainContracts() public onlyOwner{
        // require(original_owner == msg.sender, "only original owner can set chain contracts");
        IOxygenChain oc = IOxygenChain(oxygenContract);
        IHealingCredit hc = IHealingCredit(hcContract);
        // IDefaultSystem defaultSystem = IDefaultSystem(defaultSystemContract);


        uint16 percent = 900;  //is off by 2 decimals so 900 = 9%

        string memory role = "TreatmentPool";
        string memory typein = "liquids";
        string memory country = "br";
        string memory region = "rio";

        oc.setmaxInProgressPending(10);
        oc.setPendingContract(hcContract, role, typein, country, region);
        oc.approveContract(hcContract, percent);


        hc.setOxygenContract(oxygenContract);
        hc.setDefaultSystemContract(defaultSystemContract);


        // hc.approveChildSystemContract(initSysContract);
        // set owners to wanted owner
        transferOwners(original_owner);
    }

    function transferOwners(address _to) public onlyOwner{
        IOxygenChain oc = IOxygenChain(oxygenContract);
        IHealingCredit hc = IHealingCredit(hcContract);
        // IDefaultSystem defaultSystem = IDefaultSystem(defaultSystemContract);

        oc.transferOwnership(_to);
        hc.transferOwnership(_to);
        // defaultSystem.transferOwnership(original_owner);
    }

    function concat(uint256 _uint, string memory _string) public pure returns(string memory) {
        bytes memory bytesString = bytes(_string);
        bytes memory bytesUint = bytes(abi.encodePacked(_uint));
        bytes memory concatenatedBytes = new bytes(bytesString.length + bytesUint.length);
        uint i;
        for (i = 0; i < bytesString.length; i++) {
            concatenatedBytes[i] = bytesString[i];
        }
        for (i = 0; i < bytesUint.length; i++) {
            concatenatedBytes[bytesString.length + i] = bytesUint[i];
        }
        return string(concatenatedBytes);
    }

    function verifyDeployment(address sysOwner, address systemContract, address pi_wallet, string memory _moboMac) public view returns(string memory){
        verifyContractSetup(sysOwner, systemContract);
        verifySystemSetup(sysOwner, systemContract, pi_wallet, _moboMac);

        //concatenate uint256 to string
        string memory uintStr = concat(address(hcContract).balance, "All tests pass and hc and oc balance is ");
        uintStr = concat(address(oxygenContract).balance, uintStr);
        return uintStr;
    }
    function verifyContractSetup(address sysOwner, address systemContract) public view returns(string memory){
        IOxygenChain oc = IOxygenChain(oxygenContract);
        IHealingCredit hc = IHealingCredit(hcContract);
        DefaultSystem dc = DefaultSystem(payable(systemContract));
        // IDefaultSystem defaultSystem = IDefaultSystem(defaultSystemContract);
        require(Ownable(hcContract).owner() == original_owner, "hc owner is not original owner");
        require(Ownable(oxygenContract).owner() == original_owner, "oc owner is not original owner");
        require(Ownable(systemContract).owner() == sysOwner, "dc owner is not sys owner");
        require(dc.porTokenAddress() == hcContract, "dc porTokenAddress is not hcContract");
        require(address(hcContract).balance >0, "hc balance is 0");
        require(address(oxygenContract).balance >0, "oxygen balance is 0");
        
        string memory uintStr = concat(address(hcContract).balance, "[2] All Contracts pass and hc and oc balance is ");
        uintStr = concat(address(oxygenContract).balance, uintStr);
        return uintStr;
    }


    function verifySystemSetup(address sysOwner, address systemContract, address pi_wallet, string memory _moboMac) public view returns(string memory){
        DefaultSystem dc = DefaultSystem(payable(systemContract));
        // IDefaultSystem defaultSystem = IDefaultSystem(defaultSystemContract);
        require(dc.moboSerials(_moboMac), "Mac_mobo is not registered");
        require(dc.getPi_wallet(pi_wallet) == pi_wallet, "default conract pi_wallet is not valid");
        require(address(pi_wallet).balance >0, "pi_wallet balance is 0 they'll need something to pay for gas on first transaction");
        require(address(sysOwner).balance >0, "Owner balance is 0 need something to pay  gas on first transaction");
        require(address(dc).balance >0, "dc balance is 0 default contract needs to pay for gas on first transaction");

        string memory uintStr = concat(address(systemContract).balance, "[3] All SETUP tests pass and hc and oc balance is ");
        uintStr = concat(address(oxygenContract).balance, uintStr);
        return uintStr;
    }

    


}