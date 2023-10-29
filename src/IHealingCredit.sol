// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;


import "./IOxygenChain.sol";
//interface for ownable contract
interface IHealingCredit {


    // event Donation(address indexed _from, string _type, uint256 _amount, uint256 _timestamp);

    function pause() external;

    function unpause() external;


    function approveChildSystemContract(address _address, string memory _name,string memory _systemType,string memory _country,int64 _lat, int64 _long) external;

    function requestMedian(address systemOwner, uint16 _percent_owed, 
                            string memory _name,
                            string memory _i_type,
                            uint256 _i_value,
                            string memory _o_type,
                            uint256 _o_value,
                            uint256 _i_epoch,
                            uint256 _o_epoch,
                            uint256 _final_delta,
                            uint256 _f_rate,
                            uint256 _reward,
                            uint256 _median,
                            int64 _lat,
                            int64 _long
         ) external  returns (IOxygenChain.outputResult memory);


    function requestMedian(address systemOwner,  uint16 _percent_owed, IOxygenChain.outputProperties memory newPotentialMedian)
        external
        returns (IOxygenChain.outputResult memory);


    /**
     * @notice Finalizes the median reward and sends the reward to the system owner
     * Healing credits reviewed to see if sufficient credits are available
     * @param systemOwner - address of the system owner
     * @param _percent_owed - percent of the reward owed to the system owner
     * @param newPotentialMedian - new potential median to be added to the system
     */
    function finalizeMedianReward(address systemOwner, uint16 _percent_owed, IOxygenChain.outputProperties memory newPotentialMedian) external;

    // internal private function to calculate median reward from outputProperties
    // function medianReward(IOxygenChain.outputProperties memory _op) internal returns (uint256);
    //un reward function
    // function unReward(address _system, uint256 _amount) external;
    
    //convert string to uint

    // ========================================= Org Actions =========================================

    // function initializeSystem that calls the factory spwan system function and creates a new system

    /**
     * @notice Generates a new contract from DefaultSystems contract
     * @param _moboSerial - motherboard serial number tied with MAC address
     * @param _name - name of system can be custom or default
     * @param _systemType - type of system this maybe something like "reuse", "sewage" or "oilywater" or other..
     * @param _country - country the system is operating in
     * @param _model - model of system being used
     * @param _foundation - foundation that is running or sponsoring the system
     * @param _manufacturer - manufacturer of system being used
     * @param _lat - geographic latitude of system
     * @param _long geographic longitude of system
     */
    function initializeSystem(
                        string memory _moboSerial,
                        string memory _name,
                        string memory _systemType,
                        string memory _country,
                        string memory _model,
                        string memory _foundation,
                        string memory _manufacturer,
                        uint256 _expectedflow,
                        int64 _lat,
                        int64 _long
                    ) external returns (address);


    // function factorySpawnSystem(
    //                             address requestor,
    //                             string memory _name,
    //                             string memory _systemType,
    //                             int64  _lat,
    //                             int64  _long,
    //                             IOxygenChain.profile memory newProfile
    //                         ) external returns (address);

    // ========================================= Config Setters =========================================

    // ========================================= Setter Functions =========================================

    //set default system contract
    function setDefaultSystemContract(address _address) external;

    function setOxygenContract(address _address) external;

    function creditMaker (uint256 _amount) external;

    function transferOwnership(address newOwner) external;
    // ========================================= Getter Functions =========================================
    function getAddressFromMoboSerial(string memory _moboSerial) external returns (address);

    function supportsInterface(bytes4 interfaceId) external returns (bool);
    // ========================================= Internal Functions =========================================

    function getSmartContractBalance() external view returns(uint);

    //owner function
    // function owner() external view returns (address);

    // ========================================= Private Functions =========================================

}