// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;


import "@openzeppelin/contracts/access/Ownable.sol";
import "./IDeployer.sol";
import "./IHealingCredit.sol";
import "./IDefaultSystem.sol";
import "./DeployerOXGN.sol";
contract OxygenChainFacade is Ownable {
    // all contracts must be deployed on chain FIRST!!!
    // including DeployerOXGN.sol

    address public original_owner;
    address public deployerContract;
    address public systemPiOwner;
    address public pi_wallet;
    address public hcContract;
    address public dsContract;

    DeployerOXGN ideploy;
    function initializeChain(address oxygenChainContract
                            , address healingCreditContract
                            , address defaultSystemContract
                            , address DeployerContract
                            , address pi
    ) public onlyOwner{
        deployerContract = DeployerContract; //same owners msg.sender
        ideploy = DeployerOXGN(deployerContract);
        hcContract = healingCreditContract;
        dsContract = defaultSystemContract; 
        pi_wallet = pi;
        // needs the wallets of OxygenDAO (original owner), systemOwner, SystemPi
        // systemOwner and SystemPi normally will be out of sequence....
        //For now I will assume the OxygenDAO is this msg.sender
        original_owner = msg.sender;
        ideploy.initializeChain(oxygenChainContract, healingCreditContract, defaultSystemContract, original_owner);
        ideploy.setChainContracts();
        ideploy.transferOwners(original_owner);

        emit ChainInitialized( oxygenChainContract   , healingCreditContract, defaultSystemContract, msg.sender);
    }

    function setPiOwner(address _newOwner) public onlyOwner{
        systemPiOwner = _newOwner;
    }

    function initializePiSystem(string memory macMoboSerial
                        , string memory systemType
    
                        , string memory name
                        , string memory country
                        , string memory model
                        , string memory foundation
                        , string memory manufacturer
                        , uint256 expectedflow
                    ) public onlyOwner {
        // vm.prank(sysown_wallet);
        int64 lat = 40748817; //"40.748817";
        int64  long = -73985428; //"-73.985428";
        IHealingCredit hc = IHealingCredit(hcContract);
        address raw_newSystem = hc.initializeSystem(macMoboSerial, name, systemType, country, model, foundation, manufacturer, expectedflow, lat, long);
        // vm.prank(hc.owner());
        hc.approveChildSystemContract(address(raw_newSystem), name, systemType, country, 0, 0);
        IDefaultSystem ds = IDefaultSystem(address(ideploy.defaultSystemContract()));
        // vm.prank(address(sysown_wallet));
        ds.registerMacSerial(macMoboSerial);
        // vm.prank(address(pi_wallet));
        ds.setPendingSystemAddress(pi_wallet, macMoboSerial);
        // vm.prank(address(sysown_wallet));
        ds.approveSystemAddress(pi_wallet);
        // deal(address(hc), address(hc), 10000e18, true );
    }

    function registerSystem(address rpiAddress
                        , string memory macMoboSerial
                        , string memory name
                        , string memory country
                        , string memory model
                        , string memory foundation
                        , string memory manufacturer
                        , uint256 expectedflow
    ) public onlyOwner{
        // who is the system treatment Owner??? i.e. who owns the Pi?
        // Original_owner is for DAO and won't own the Pi's [systemPiOwner]
        // Now the owner will call hc to setup and invoke the pi to start
        // the pi will call based on the above request with its own wallet
        // ideploy = IDeployer(deployerContract);
        // here we need to deploy via hc contract
        // here we need to set pi as the  reward caller
        ideploy.verifyContractSetup(systemPiOwner, ideploy.defaultSystemContract());

        ideploy.verifySystemSetup(systemPiOwner, ideploy.defaultSystemContract(), rpiAddress, macMoboSerial);



        emit SystemRegistered(        
         rpiAddress,
         macMoboSerial,
         name,
         country,
         model,
         foundation,
         manufacturer,
         expectedflow,
         msg.sender);
    }

    function addPotentialMedian(uint256 finalDelta
                                , uint256 flowRate
                                , int64 latitude
                                , int64 longitude
    ) public onlyOwner{
        // for this to work HC must have liquidity
        // oxygen also needs $$$
        emit PotentialMedianAdded(finalDelta, flowRate, latitude, longitude, msg.sender);
    }

    event ChainInitialized(
        address oxygenChainContract
        , address healingCreditContract
        , address defaultSystemContract
        , address sender);

    // Event emitted when a system is registered
    event SystemRegistered(       
        address rpiAddress,
        string macMoboSerial,
        string name,
        string country,
        string model,
        string foundation,
        string manufacturer,
        uint256 expectedflow,
        address sender);

    // Event emitted when a potential median is added
    event PotentialMedianAdded(uint256 finalDelta
    ,  uint256 flowRate
    , int64 latitude
    , int64 longitude
    , address sender);
}