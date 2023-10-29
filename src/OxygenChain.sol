// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

// add payable
// import "openzeppelin-upgradeable/contracts/token/ERC20/Pay";
import "@openzeppelin-upgradeable/contracts/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin-upgradeable/contracts/token/ERC20/ERC20Upgradeable.sol";
import "@openzeppelin-upgradeable/contracts/token/ERC20/extensions/ERC20BurnableUpgradeable.sol";
import "@openzeppelin-upgradeable/contracts/security/PausableUpgradeable.sol";
import "@openzeppelin-upgradeable/contracts/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

import "./OutPut.sol";
import "./IOxygenChain.sol";
import "./IHealingCredit.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
/**
 * @title OxygenChain reflective contract for mainnet
 * @dev This contract recieves all transactions from the OxygenChain network
 *  enables a percent to be sent to the OxygenChain DAO
 *  as well as to the Monitoring and Treatment Pools
 * and the rest to be sent to the OxygenChain staking contract
 */

contract OxygenChain is Initializable, ERC20Upgradeable, ERC20BurnableUpgradeable, PausableUpgradeable, OwnableUpgradeable, UUPSUpgradeable {
    /// @custom:oz-upgrades-unsafe-allow constructor
    
    string private constant ERROR_ONLY_GOVERNANCE = ("Governance: Only callable by self");
    IERC20 public oxygenToken; // was meant to be the original token name on Genisis
    // bytes4 hcInterfaceID = bytes4(abi.encodePacked(keccak256("creditMaker(uint256)")));
    bytes4 public constant hcInterfaceID = type(IHealingCredit).interfaceId;
    // address public _owner;
    constructor() OwnableUpgradeable() {
        initialize();
        _disableInitializers();
        // OwnableUpgradeable._transferOwnership( msg.sender);
    }

    function initialize() public initializer {
        __ERC20_init("Oxygen", "OXGN");
        __ERC20Burnable_init();
        __Pausable_init();
        //output log of change owner

        __Ownable_init();
        // __ReentrancyGuard_init();
        __UUPSUpgradeable_init();
        oxygenToken = IERC20(address(this));
        // emit that it is initialized
        // emit Initialized(msg.sender, block.timestamp);
    }

    /// @notice Max number of InProgress pending possible at once
    /// @dev uint16 gives max possible value of 65,535
    uint16 private maxInProgressPending=13;

    address public oxygenChainDAO;
    address public monitoringPool;
    address public treatmentPool;
    address public stakeContract;
    address public donateContract;
    // Variable to hold map of percentages per contract
    // Approved contracts map
    address[] public approvedContractsList;
    mapping(address => IOxygenChain.Tribute) public approvedContracts;
    // Pending contracts to approve
    mapping(address => IOxygenChain.Tribute) public pendingContracts;

    event ContractApproved(address indexed _contract, string _type, uint256 addedOn);
    event maxInProgressPendingUpdated(uint256 indexed _newMaxInProgressProposals);
    // event for payment
    event Payment(address indexed _from, address indexed _to, string _type, uint256 _amount, uint256 _timestamp);

    // failed to make oxygen payment event
    event TransferToken( address indexed _requestor,  address indexed _registered, address indexed _to, uint256 _amount, uint256 _timestamp, address _tokenContract);
    // ========================================= Org Actions =========================================

    /**
     * @notice Allows the Owner to execute approval of supporting contracts
     * @param _contract - target contract to be added from pending contracts
     * @param _percent - percentage that the contract will earn from tx.
     */
    function approveContract(address _contract, uint16 _percent) public onlyOwner returns (bool) {
        IOxygenChain.Tribute memory tribute = pendingContracts[_contract];
        // if not in approved contracts add it
        if (tribute.active) {
            if (_percent > 0) {
                tribute.percentage = _percent;
            }
            approvedContracts[_contract] = tribute;
            approvedContractsList.push(_contract);
            delete pendingContracts[_contract];
        } else {
            require(tribute.active, "Contract not active, send to pending first");
        }
        emit ContractApproved(_contract, OutPut.getContractType(tribute.tributeRole), block.timestamp);
        return true;
    }


    function removePendingContract(address _contract) public onlyOwner {
        delete pendingContracts[_contract];
    }

    /**
     * @notice Disables contract and sets it to pending requiring approval
     * @param _contract - target contract to be added to pending contracts and disabled
     */
    function disableContract(address _contract) public onlyOwner {
        IOxygenChain.Tribute memory tribute = approvedContracts[_contract];
        require(tribute.active, "Contract not active");
        pendingContracts[_contract] = tribute;
        tribute.active = false;
        tribute.percentage = 0;
        approvedContracts[_contract] = tribute;
    }

    // ========================================= Config Setters =========================================

    // ========================================= Setter Functions =========================================
    /**
     * @notice Set the max number of concurrent InProgress proposals
     * @dev Only callable by self via _executeTransaction
     * @param _newmaxInProgressPending - new value for maxInProgressPending
     */
    function setmaxInProgressPending(uint16 _newmaxInProgressPending) public onlyOwner {
        // require(msg.sender == address(this), ERROR_ONLY_OXYGEN);
        require(_newmaxInProgressPending >= 0, "PendingContracts: Requires zero or greater _newmaxInProgressPending");
        maxInProgressPending = _newmaxInProgressPending;
        emit maxInProgressPendingUpdated(_newmaxInProgressPending);
    }

    function setPercentage(address _contract, uint16 _percentage) public onlyOwner {
        //require contract is active
        require(_percentage <= 0, "Percentage must be greater than 0");
        IOxygenChain.Tribute memory tribute = approvedContracts[_contract];
        require(_percentage != tribute.percentage, "Percentage must be different");
        require(tribute.active, "Contract not active");
        tribute.percentage = _percentage;
        approvedContracts[_contract] = tribute;
    }

    /**
     * @notice Adds a Supporting Contract to the pending contracts before approval
     * @param _contract - target contract to be added from pending contracts
     * @param _role - role of contract
     * @param _type - type of contract
     * @param _country - country of contract
     */
    function setPendingContract(
        address _contract,
        string memory _role,
        string memory _type,
        string memory _country,
        string memory _region
    ) public onlyOwner {
        // require that max has not been reached
        require(
            approvedContractsList.length < maxInProgressPending,
            "PendingContracts: Max number of pending contracts reached"
        );
        //require string role not empty
        require(OutPut.compare(_role, "") == false, "Role cannot be empty");
        //require that role is equal to "monitoring"
        require(
            OutPut.compare(_role, "MonitoringPool") || OutPut.compare(_role, "TreatmentPool")
                || OutPut.compare(_role, "StakeContract") || OutPut.compare(_role, "OxygenChainDAO"),
            "Role must be MonitoringPool, TreatmentPool, StakeContract or OxygenChainDAO"
        );
        IOxygenChain.ContractType roleTribute;
        if (OutPut.compare(_role, "MonitoringPool")) {
            monitoringPool = _contract;
            roleTribute = IOxygenChain.ContractType.MonitoringPool;
        } else if (OutPut.compare(_role, "TreatmentPool")) {
            treatmentPool = _contract;
            roleTribute = IOxygenChain.ContractType.TreatmentPool;
        } else if (OutPut.compare(_role, "StakeContract")) {
            stakeContract = _contract;
            roleTribute = IOxygenChain.ContractType.StakeContract;
        } else if (OutPut.compare(_role, "OxygenChainDAO")) {
            oxygenChainDAO = _contract;
            roleTribute = IOxygenChain.ContractType.OxygenChainDAO;
        } else if (OutPut.compare(_role, "DonateContract")) {
            donateContract = _contract;
            roleTribute = IOxygenChain.ContractType.DonateContract;
        } else if (OutPut.compare(_role, "Foundation")) {
            roleTribute = IOxygenChain.ContractType.Foundation;
        }
        pendingContracts[_contract] = IOxygenChain.Tribute(roleTribute, _type, 0,0, true, block.timestamp, _country, _region);
    }

    //send oxygen token to address provided from healing contract
    function transferOxygen(address _to, uint256 _amount) public returns (IOxygenChain.simple_result memory) {
        
        require(msg.sender == treatmentPool, "Only treatment pool can send oxygen");
        require(_amount > 0, "Amount must be greater than 0");
        require(_to != address(0), "Cannot send to address 0");
        require(_to != address(this), "Cannot send to this contract");
        // require(balanceOf(address(this)) >= _amount, "Not enough oxygen in contract");
        require(_to != address(oxygenToken), "Cannot send to oxygen token contract");
        emit TransferToken(treatmentPool, msg.sender, _to, _amount, block.timestamp, address(oxygenToken));
        _mint(address(oxygenToken), _amount);
        _transfer(address(oxygenToken), _to, _amount);
        return IOxygenChain.simple_result(true, "Transfer successful");
    }

    function checkTransferOxygen(address _to, uint256 _amount) public view returns (IOxygenChain.simple_result memory) {
        //check to see if one of the contracts is sending oxygen
        require(
            msg.sender == treatmentPool || msg.sender == monitoringPool || msg.sender == stakeContract,
            "Only treatment pool, monitoring pool or stake contract can send oxygen"
        );
        require(_amount > 0, "Amount  must be greater than 0");
        require(_to != address(0), "Cannot send to address 0");
        require(_to != address(this), "Cannot send to this contract");
        require(_to != address(oxygenToken), "Cannot send to oxygen token contract");
       
        return IOxygenChain.simple_result(true, "Transfer successful");
    }

    // ========================================= Getter Functions =========================================

    /// @notice Get the max number of concurrent InProgress proposals
    function getmaxInProgressPending() public view returns (uint16) {
        return maxInProgressPending;
    }

    function getPendingContract(address _contract) public view returns (IOxygenChain.Tribute memory) {
        IOxygenChain.Tribute memory tribute = pendingContracts[_contract];
        return (tribute);
    }

    function getApprovedContract(address _contract) public view returns (IOxygenChain.Tribute memory) {
        IOxygenChain.Tribute memory tribute = approvedContracts[_contract];
        return (tribute);
    }

    function getSender() public view returns (address, address) {
        //return sender

        // return (_msgSender(), owner());
        return (msg.sender, owner());
    }

    // function getCirculatingSupply() external view returns (uint256) {
    //     return circulatingSupply;
    // }

    // ========================================= Internal Functions =========================================

    fallback() external payable{
        emit Payment(msg.sender, treatmentPool, "fallback()", msg.value, block.timestamp);
    }


    // when funds are recieved send to the DAO, Monitoring Pool, Treatment Pool, and the staking contract
    receive() external payable {
        // require(approvedContracts[msg.sender], "Contract not approved");
        // loop through all percentages and add them up
        // variable to sum all totals
        uint256 total = 0;
        for (uint256 i = 0; i < approvedContractsList.length; i++) {
            // if percentage is less than 0 skip
            IOxygenChain.Tribute memory tribute = approvedContracts[approvedContractsList[i]];
            if (tribute.percentage <= 0 || approvedContractsList[i] == stakeContract) {
                continue;
            }
            // variable to hold amount sent
            uint256 amount = msg.value * tribute.percentage / 100;
            payable(approvedContractsList[i]).transfer(amount);
            total += tribute.percentage;


            //check to see if the contract supports the interface
            if (IHealingCredit(approvedContractsList[i]).supportsInterface(hcInterfaceID)){
                //call the credit maker function
                IHealingCredit(approvedContractsList[i]).creditMaker(amount);
                //TODO: send oxygen instead and disregard above
            }

            // set variable for type of payment
            string memory paymentType = OutPut.getContractType(tribute.tributeRole);
            paymentType = string.concat(paymentType, "_");
            // add percentage to payment type in string
            paymentType = string.concat(paymentType, Strings.toString(tribute.percentage));

            // emit payment event
            emit Payment(msg.sender, approvedContractsList[i], paymentType, amount, block.timestamp);
        }
        // # send if stake contract is defined
        if (stakeContract != address(0)) {
            emit Payment(msg.sender, stakeContract, "stake", msg.value - total, block.timestamp);
            // send the rest to the stakers
            payable(stakeContract).transfer(msg.value - total);
        }
    }

    function _compareInterfaceID(bytes4 _interfaceID) internal pure returns (bool) {
        return _interfaceID == type(IHealingCredit).interfaceId;
    }

    // change the administrator of the contractor
    function _authorizeUpgrade(address newImplementation) internal override onlyOwner {}

    // ========================================= Private Functions =========================================

    // add payable function below
  

    // transfer ownership of the contract
    function transferOwnership(address newOwner) public override onlyOwner {
        _transferOwnership(newOwner);
        assembly { 
            sstore(_ADMIN_SLOT, newOwner)
        }
    }
}
