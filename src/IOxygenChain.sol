// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;


interface IOxygenChain {
    //enum for contract type
    enum ContractType {
        MonitoringPool,
        TreatmentPool,
        StakeContract,
        Foundation,
        OxygenChainDAO,
        DonateContract,
        OtherContract
    }
    struct simple_result{
        bool success;
        string error;
    }
    //struct for tribute
    struct Tribute {
        ContractType tributeRole;
        string group;
        uint16 percentage;
        uint256 remaining;
        bool active;
        uint256 addedOn;
        string country;
        string region;
    }
    /**
     * 
     * system is relative to the INSTANCE of default contract
     */
    struct System { 
        string name;
        uint256 registeredDate;
        string systemType;
        string country;
        uint256 percentage;
        int64 long;
        int64 lat;
        bool active;
    }

    struct profile {
        string manufacturer;
        string model;
        uint256 expectedflow;
        string foundation;
        string country;
        string macMoboSerial;
        uint256 earnedCredits;
        address systemWalletAddress;
        address pendingSystemWalletAddress;
        string arweaveWalletAddress;
        string filecoinWalletAddress;
        // add enabled flag
        bool enabled;
    }

    struct outputProperties {
        string name;
        address system;
        string i_type;
        uint256 i_value;
        string o_type;
        uint256 o_value;
        uint256 i_epoch;
        uint256 o_epoch;
        uint256 final_delta;
        uint256 f_rate;
        uint256 reward;
        uint256 median;
        int64 lat;
        int64 long;
    }

    struct inputMedian {
        string i_type;
        uint256 i_value;
        string o_type;
        uint256 o_value;
        uint256 i_epoch;
        uint256 o_epoch;
        uint256 final_delta;
        uint256 f_rate;
        uint256 reward;
        uint256 median;
        int64 lat;
        int64 long;
    }

    struct outputResult{
        bool success;
        string error;
        outputProperties properties;
    }


    // function that returns string from each enum type



    //appoveContract function
    function approveContract(address _contract, uint16 _percent) external returns (bool);
    function removePendingContract(address _contract) external;

    /**
     * @notice Disables contract and sets it to pending requiring approval
     * @param _contract - target contract to be added to pending contracts and disabled
     */
    function disableContract(address _contract) external;

    /**
     * @notice Set the max number of concurrent InProgress proposals
     * @dev Only callable by self via _executeTransaction
     * @param _newmaxInProgressPending - new value for maxInProgressPending
     */
    function setmaxInProgressPending(uint16 _newmaxInProgressPending) external;
    function setPercentage(address _contract, uint16 _percentage) external;


    /**
     * @notice Adds a Supporting Contract to the pending contracts before approval
     * @param _contract - target contract to be added from pending contracts
     * @param _role - role of contract
     * @param _type - type of contract
     * @param _country - country of contract
     */
    function setPendingContract(address _contract,string memory _role,string memory _type,
                                string memory _country,string memory _region) external;

    /// @notice Get the max number of concurrent InProgress proposals
    function getmaxInProgressPending() external view returns (uint16);

    // function to getCirculatingTokenSupply() of OXGN token
    function getCirculatingTokenSupply() external view returns (uint256);


    function getPendingContract(address _contract) external view returns (Tribute memory);

    function getApprovedContract(address _contract) external view returns (Tribute memory);

    function transferOxygen(address _to, uint256 _amount) external returns (IOxygenChain.simple_result memory);

    function checkTransferOxygen(address _to, uint256 _amount) external view returns (IOxygenChain.simple_result memory);

    // function _authorizeUpgrade(address newImplementation) external internal override;
    // function transferOwnership(address newOwner) external; 
        function transferOwnership(address newOwner) external;

    //owner function
    // function owner() external view returns (address);

}
