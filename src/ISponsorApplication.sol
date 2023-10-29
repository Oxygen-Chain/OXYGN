// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;
// import UUPS from OpenZeppelin

import "./IOxygenChain.sol";
interface ISponsorApplication {


    struct system_sponsored {
        uint256 owed;
        uint16 reward_percent;
        uint256 createdon;
        address createdby;
    }




    function getPendingSystem(address _system) external view returns (ISponsorApplication.system_sponsored memory);

    //function that allows a foundation to sponsor a system
    function add_pendingsponsorSystem(address _system, uint256 _amount, uint16 _percent) external returns (IOxygenChain.simple_result memory);

    function remove_pendingSponsorSystem(address[] memory _systems)external;

    function approve_sponsorSystem(address _system) external;

    function remove_sponsorSystem(address _system) external;

    function change_maxPendingSystems(uint16 _max) external;

    

}