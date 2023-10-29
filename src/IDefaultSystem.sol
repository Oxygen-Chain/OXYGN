// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;


import "./IOxygenChain.sol";
interface IDefaultSystem  {

    // event SystemSubmitted(address indexed _sender, string _name, string _macMoboSerial);

    //variable defines event for reward collected with outputProperties
    // event rewardCollected(IOxygenChain.outputProperties);
    // event porChanged(address _porTokenAddress, uint256 _timestamp, address _previous);

    // variable porTokenAddress


    function pause() external; 
    function unpause() external; 

    // set POR contract address only from factoryaddress
    function changePorTokenAddress(address _porTokenAddress) external;

    // request system address standby
    function setPendingSystemAddress(address _systemWalletAddress, string memory _moboMac) external;

    // allows system to self register before owner approving
    function registerMacSerial(string memory _macSerial) external;

    // approve system address standby by owner
    function approveSystemAddress(address _toapprove) external;

    //send median proposal with reward expected
    function addPotentialMedian(IOxygenChain.inputMedian memory _imedian) external;
    function addPotentialMedian(
                    string memory _i_type,
                    uint256 _i_value,
                    string memory _o_type,
                    uint256 _o_value,
                    uint256 _i_epoch,
                    uint256 _o_epoch,uint256 _final_delta,uint256 _f_rate,
                    uint256 _reward,uint256 _median, int64 _lat,int64 _long) 
                    external;




    // ========================================= Org Actions =========================================

    // ========================================= Config Setters =========================================

    // ========================================= Setter Functions =========================================

    // ========================================= Getter Functions =========================================

    function getTribute(address _foundationAddress) external returns (IOxygenChain.Tribute memory);


    function getMoboSerial(string memory _macSerial) external returns (bool);

    // ========================================= Internal Functions =========================================

    // ========================================= Private Functions =========================================

    //change owner of contract
    function changeOwner(address _newOwner) external;
    //owner function
    // function owner() external view returns (address);
}
