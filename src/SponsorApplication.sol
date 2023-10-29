// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;
// import UUPS from OpenZeppelin


import "@openzeppelin-upgradeable/contracts/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin-upgradeable/contracts/access/OwnableUpgradeable.sol";
import "@openzeppelin-upgradeable/contracts/security/PausableUpgradeable.sol";
import "./ISponsorApplication.sol";
import "./IDefaultSystem.sol";
import "./IOxygenChain.sol";

contract SponsorApplication is UUPSUpgradeable, OwnableUpgradeable,PausableUpgradeable, ISponsorApplication {
    //map of system addresses tied to amount owed and percent per reward paid
    mapping(address => ISponsorApplication.system_sponsored) public systemAmountOwed;
    //pending systems map
    mapping(address => ISponsorApplication.system_sponsored) public pendingSystems;
    //max pending systems
    uint16 public maxPendingSystems = 10;
    uint16 public totalPendingSystems = 0;


    constructor() {
        initialize();
        _disableInitializers();
    }

    function initialize() public initializer {
        __Pausable_init();
        __Ownable_init();
        __UUPSUpgradeable_init();
    }

    function getPendingSystem(address _system) public view returns (ISponsorApplication.system_sponsored memory){
        return pendingSystems[_system];
    }

    function add_pendingsponsorSystem(address _system, uint256 _amount, uint16 _percent) public returns (IOxygenChain.simple_result memory){
        // require(msg.sender == foundation, "Only foundation can sponsor a system"); 
        require(totalPendingSystems < maxPendingSystems, "Max pending systems reached");
        require(systemAmountOwed[_system].owed != 0, "System is already sponsored");
        require(pendingSystems[_system].owed != 0, "System is already pending");
        require((_amount > 0 && _percent > 0), "Amount4 must be greater than 0");
        require(_percent <= 90, "Percent must be less than or equal to 90");
        require(_system != address(0), "System address cannot be 0");
        pendingSystems[_system].owed = _amount;
        pendingSystems[_system].reward_percent = _percent;
        pendingSystems[_system].createdon = block.timestamp;
        pendingSystems[_system].createdby = msg.sender;
        totalPendingSystems++;
        return IOxygenChain.simple_result(true, "System added to pending");
    }
    // remove systems given
    function remove_pendingSponsorSystem(address[] memory _systems) public onlyOwner {
        // require(msg.sender == foundation, "Only foundation can remove a system");
        for (uint i = 0; i < _systems.length; i++) {
            delete pendingSystems[_systems[i]];
            totalPendingSystems--;
        }
    }

    //function that allows a foundation to sponsor a system
    function approve_sponsorSystem(address _system) public onlyOwner {
        // require(msg.sender == foundation, "Only foundation can sponsor a system");
        require(systemAmountOwed[_system].owed > 0, "System is not sponsored");
        //check to see if default system already has approved sponsor
        IDefaultSystem defaultSystem = IDefaultSystem(_system);
        IOxygenChain.Tribute memory tribute = defaultSystem.getTribute(address(this));
        require(tribute.remaining == 0, "Default system sponsor not found");
        systemAmountOwed[_system] = pendingSystems[_system];
        totalPendingSystems--;
    }



    function remove_sponsorSystem(address _system) public onlyOwner {
        // require(msg.sender == foundation, "Only foundation can remove a system");
        require(systemAmountOwed[_system].owed > 0, "System is not sponsored");
        delete systemAmountOwed[_system];
    }

    //functin to change maxPendingSystems
    function change_maxPendingSystems(uint16 _max) public onlyOwner {
        require(_max > 0, "Max must be greater than 0");
        maxPendingSystems = _max;
    } 

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function _authorizeUpgrade(address) internal override onlyOwner {}


    function transferOwnership(address newOwner) public override onlyOwner {
        _transferOwnership(newOwner);
        assembly {
            sstore(_ADMIN_SLOT, newOwner)
        }
    }


}
