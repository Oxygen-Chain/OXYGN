// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin-upgradeable/contracts/token/ERC721/IERC721Upgradeable.sol";
import "@openzeppelin-upgradeable/contracts/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin-upgradeable/contracts/token/ERC20/extensions/ERC20BurnableUpgradeable.sol";
import "@openzeppelin-upgradeable/contracts/security/PausableUpgradeable.sol";
import "@openzeppelin-upgradeable/contracts/access/OwnableUpgradeable.sol";
import "@openzeppelin-upgradeable/contracts/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/proxy/Clones.sol";

import "@openzeppelin-upgradeable/contracts/proxy/utils/Initializable.sol";


import "./IHealingCredit.sol";
import "./OutPut.sol";

import "./IOxygenChain.sol";
import "./IDefaultSystem.sol";
//openzepplin math
// import "@openzeppelin/contracts/utils/math/SafeMath.sol";
// openzeppelin proxy factory
// import "@openzeppelin-upgradeable/contracts/proxy/ClonesUpgradeable.sol";
/**
 * @dev Responsible for recieving data from all systems and validating it
 * when valid, a median is calculated and stored in the contract
 * rewards are provided from this contract to the system contract
 * lists of registered systems
 * Oracles tied to Arweave and Filecoin
 * historical data used to calculate median based on type given, flow, lat and long
 */
/// @custom:security-contact security@oxygenchain.earth

contract HealingCredit is
    Initializable,
    IERC20Upgradeable,
    ERC20BurnableUpgradeable,
    PausableUpgradeable,
    OwnableUpgradeable,
    UUPSUpgradeable,
    IHealingCredit
{
    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        token = IERC20Upgradeable(address(this));
        initialize();
        // OwnableUpgradeable._transferOwnership( msg.sender);
        _disableInitializers();
    }

    function initialize() public initializer {
        __ERC20_init("HealingCredit", "OXHD");
        __ERC20Burnable_init();
        __Pausable_init();
        __Ownable_init();
        __UUPSUpgradeable_init();


    }

    uint256 public rate = 1;

    address public oxygenContract;
    address public defaultSystemContract;


    bytes4 private constant SELECTOR = 0xfba3f97d; // bytes4(keccak256(bytes('initialize(address,string,string,string,string,string,string,uint256)')));


    // address of nft contract
    address public nftContract;
    IERC20Upgradeable public token;

    // MOBO/SERIAL to address mapping
    mapping(string => address) public moboSerialToAddress;

    // variable to hold systems
    mapping(address => IOxygenChain.System) public systems;
    //variable to hold system types
    mapping(string => address[]) public systemTypes;
    // variable to hold percent pay out by system type
    mapping(string => uint256) public systemTypePercentages;

    event Donation(address indexed _from, string _type, uint256 _amount, uint256 _timestamp);

    event SystemSpawned(address indexed _requestor, string _name, string _systemType, address _sys_address, address _base_address, uint256 _timestamp);
    //error 
    event rewardFailed(address indexed _systemAddress, string _errormsg, uint256 _amount, uint256 _timestamp);

    event Payment(address indexed _from, address indexed _to, string _type, uint256 _amount, uint256 _timestamp);

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }



    function _beforeTokenTransfer(address from, address to, uint256 amount) internal override whenNotPaused {
        super._beforeTokenTransfer(from, to, amount);
    }


    function requestMedian(address systemOwner,  uint16 _percent_owed,
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
         ) public  returns (IOxygenChain.outputResult memory){
        IOxygenChain.outputProperties memory hcPotentialMedian = IOxygenChain.outputProperties(
                                                            _name,
                                                            address(msg.sender),
                                                            _i_type,
                                                            _i_value,
                                                            _o_type,
                                                            _o_value,
                                                            _i_epoch,
                                                            _o_epoch,
                                                            _final_delta,
                                                            _f_rate,
                                                            _reward,
                                                            _median,
                                                            _lat,
                                                            _long
                                                        );
        return requestMedianExe(systemOwner, _percent_owed, hcPotentialMedian);
    }


    function requestMedian(address systemOwner, uint16 _percent_owed, IOxygenChain.outputProperties memory newPotentialMedian)
        public
        returns (IOxygenChain.outputResult memory)
    {
        // emit rewardFailed(systemOwner, "...DEBUG Testing... starting...", newPotentialMedian.reward, block.timestamp);
        IOxygenChain.outputResult memory amp_ready = requestMedianExe(systemOwner, _percent_owed, newPotentialMedian);
        if (amp_ready.success == false) {
            emit rewardFailed(systemOwner, amp_ready.error, newPotentialMedian.reward, block.timestamp);
        }
        // require(amp_ready.success, amp_ready.error);
        return amp_ready;
    }


    //function requestMedian to request median from system
    function requestMedianExe(address systemOwner, uint16 _percent_owed, IOxygenChain.outputProperties memory newPotentialMedian)
        internal view
        returns (IOxygenChain.outputResult memory)
    {
        IOxygenChain.outputResult memory amp_ready = IOxygenChain.outputResult(true,"1 completed!", newPotentialMedian);
        // uint256 gasFee = tx.gasprice;
        
        // require(systems[_address].registeredDate > 0, "System is not registered");
        if (systems[address(msg.sender)].registeredDate == 0 || owner() == address(msg.sender)){
            // string memory senderAddress = msg.sender;
            amp_ready.error =  "[E] System is not registered";
            amp_ready.success = false;
            return amp_ready;
        }
        // system is enabled?
        if (!systems[address(msg.sender)].active){
            amp_ready.error =  "[E] System is not active";
            amp_ready.success = false;
            return amp_ready;
        }

        if (newPotentialMedian.system == address(0)){
            amp_ready.error =  "[E] Address is eq 0";
            amp_ready.success = false;
            return amp_ready;
        }
        if (newPotentialMedian.system == address(this)){
            amp_ready.error =  "[E] Address is this contract";
            amp_ready.success = false;
            return amp_ready;
        }
        
        uint256 thc = balanceOf(address(this));
        if (thc == 0){
            string memory rwrd = Strings.toString(newPotentialMedian.reward);
            amp_ready.error =  "[E] No healing credits in pool";
            amp_ready.success = false;
            return amp_ready;
        }
        // uint256 raw_reward = medianFutureReward(newPotentialMedian, totalHealingCredits);
        uint256 raw_reward = medianFutureReward(newPotentialMedian, thc);
        //final reward minus percent owed
        uint256 reward = raw_reward - (raw_reward * _percent_owed / 100);
        if (reward == 0){
            // set error to represent reward concatentated with string
            string memory rwrd = Strings.toString(newPotentialMedian.reward);
            // string memory hcreds = Strings.toString(totalHealingCredits);
            string memory hcreds = Strings.toString( balanceOf(address(this)));
           
            amp_ready.error = string(abi.encodePacked("[E] reward is 0 from p.reward: ", rwrd, "and  pool thc:", hcreds));
            amp_ready.success = false;
            return amp_ready;
        }
        newPotentialMedian.reward = reward;
        if (newPotentialMedian.median > 0) {
            if (token.balanceOf(address(this)) <= reward){
                amp_ready.error =  "[E] Not enough tokens in contract @G31";
                amp_ready.success = false;
                return amp_ready;
            }

            if (oxygenContract == address(0)){
                amp_ready.error =  "[E] Oxygen contract not set";
                amp_ready.success = false;
                return amp_ready;
            }
            // if (!token.transfer(systemOwner, token.balanceOf(address(this)))){
            IOxygenChain ioc = IOxygenChain(oxygenContract);
            // return checkTransferOxygen from oxygen contract
            IOxygenChain.simple_result memory sr = ioc.checkTransferOxygen(systemOwner, reward);
            if (!sr.success){
                amp_ready.error =  "[E an issue occured during transfer";
                amp_ready.success = false;
                return amp_ready;
            }else { // remove healing credit from pool
                // unReward(newPotentialMedian.system, reward);
            }
        }

        return amp_ready;
    }

    function medianFutureReward(IOxygenChain.outputProperties memory _op, uint256 _totalCredits)public pure returns (uint256) { 
        uint256 reward = _op.final_delta * _op.f_rate;
        uint256 eightyPercent = _totalCredits*100/80;
        if (reward > eightyPercent){
            reward = eightyPercent*100/80; // 80% of 80 ends up  64%
        }
        return reward;
    }

    // internal private function to calculate median reward from outputProperties
    function medianReward(IOxygenChain.outputProperties memory _op) internal returns (uint256) { 

        uint256 reward = _op.final_delta * _op.f_rate;
        _burn(address(this), reward);
        _mint(_op.system, reward);
        // return reward
        return reward;
    }
    //un reward function
    function unReward(address _system, uint256 _amount) internal { 
        _burn(_system, _amount);
        _mint(address(this), _amount);
    }

    function mintTokens() private {
        uint256 tokens = msg.value * rate;
        _mint(address(this), tokens);
    } 


    function finalizeMedianReward(address systemOwner, uint16 _percent_owed, IOxygenChain.outputProperties memory newPotentialMedian)
        public
    {
        // IOxygenChain.outputResult memory amp_ready = IOxygenChain.outputResult(true,"", newPotentialMedian);
        require(systems[address(msg.sender)].registeredDate > 0, "System is not registered");
        //system enabled
        require(systems[address(msg.sender)].active, "System is not active");
        require(newPotentialMedian.system != address(0), "Address is eq 0");
        require(newPotentialMedian.system != address(this), "Address is this contract");

        uint256 raw_reward = medianReward(newPotentialMedian);
        //final reward minus percent owed
        uint256 reward = raw_reward - (raw_reward * _percent_owed / 100);
        newPotentialMedian.reward = reward;
        if (newPotentialMedian.median > 0) {
            if (token.balanceOf(address(this)) <= reward){
                unReward(newPotentialMedian.system, reward);
                require(token.balanceOf(address(this)) >= reward, "[E] Not enough tokens in contract @G31");
            }
            if (address(this).balance > reward){ // there is enough here to pay directly
                payable(systemOwner).transfer(reward);
                emit Payment(address(this), systemOwner, "finalizeMedianReward", reward, block.timestamp);
            }else{ //fallback pay from oxygen contract...
                IOxygenChain ioc = IOxygenChain(oxygenContract);
                IOxygenChain.simple_result memory sr = ioc.transferOxygen(systemOwner, reward);
                if (!sr.success){
                    // revert();
                    unReward(newPotentialMedian.system, reward);
                    require(sr.success, "[E] an issue occured during transfer");
                }
            }

        }
    }

    function creditMaker (uint256 _amount) public {
        require(oxygenContract == msg.sender, "Only Oxygen contract can call this function");
        require(_amount > 0, "Amount2 must be greater than 0");
        require(oxygenContract != address(0), "Oxygen contract not set");
        // mint amount to contract
        _mint(address(this), _amount);
        // totalHealingCredits += _amount;
    }
    

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
     * @param _expectedflow - expected flow rate of system
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
    ) public returns (address) {
        // Check to see if this MOBO/MAC address has been used before
        if (moboSerialToAddress[_moboSerial] != address(0)) {
            return moboSerialToAddress[_moboSerial];
        }
        //require that mobo isn't already registered
        require(moboSerialToAddress[_moboSerial] == address(0), "MOBO already registered");
        IOxygenChain.profile memory newProfile =
            IOxygenChain.profile(_manufacturer, _model, _expectedflow, _foundation, _country, _moboSerial, 0, address(0), address(0), "", "", true);
        // factorySpawnSystem(msg.sender, _name, _systemType, _lat, _long, newProfile);
        return factorySpawnSystem(msg.sender, _name, _systemType, _lat, _long, newProfile);
    }

    function factorySpawnSystem(
        address requestor,
        string memory _name,
        string memory _systemType,
        int64  _lat,
        int64  _long,
        IOxygenChain.profile memory newProfile
    ) private returns (address) {
        address newSystemRaw = Clones.clone(defaultSystemContract);
        // SECURITY REQUIREMENT: check if systemType exists
        systems[newSystemRaw] = IOxygenChain.System(_name, block.timestamp, _systemType, newProfile.country, 0, _lat, _long, true);
        systemTypes[_systemType].push(newSystemRaw);
        // LEAVE ABOVE IN PLACE FOR SECURITY REQUIREMENT
        // add this new address to the mapping
        moboSerialToAddress[newProfile.macMoboSerial] = newSystemRaw;

        // bytes memory data = OutPut.bindEncode("initialize(address,string,string,string,string,string,string,uint256)", 
        //                                         requestor, _name, newProfile );
        bytes memory data = OutPut.bindEncode2(SELECTOR,requestor, _name, newProfile );

        (bool success,) = address(newSystemRaw).call(data);
        require(success, "Error calling systemDefault initialize");
        emit SystemSpawned(requestor, _name, _systemType, newSystemRaw, defaultSystemContract, block.timestamp);
        return newSystemRaw;
    }

    // ========================================= Config Setters =========================================

    // ========================================= Setter Functions =========================================

    //set default system contract
    function setDefaultSystemContract(address _address) public onlyOwner {
        defaultSystemContract = _address;
    }

    //set the oxygen contract
    function setOxygenContract(address _address) public onlyOwner {
        oxygenContract = _address;
    }

    function approveChildSystemContract(address _address, string memory _name,string memory _systemType,string memory _country,int64 _lat, int64 _long) public onlyOwner {
        require(_address != address(0), "Address is eq 0");
        require(_address != address(this), "Address is this contract");
        require(systems[_address].registeredDate != 0, "System  Already registered");
        systems[_address] = IOxygenChain.System(_name, block.timestamp, _systemType, _country, 0, _lat, _long, true);
    }

    //disable system
    function toggleSystemRewards(address _address, bool value) public onlyOwner {
        require(_address != address(0), "Address is eq 0");
        require(_address != address(this), "Address is this contract");
        require(systems[_address].registeredDate != 0, "System is not registered");
        require (systems[_address].active != value, "System is already set to this value");
        systems[_address].active = value;
    }

    // unregister system to allow systems to be recycled if needed on a different contract
    function unRegisterSystem(address _address, string memory _moboSerial, string memory systype) public onlyOwner {
        require(_address != address(0), "Address is eq 0");
        require(_address != address(this), "Address is this contract");
        require(systems[_address].registeredDate != 0, "System is not registered");
        require(moboSerialToAddress[_moboSerial] == _address, "MOBO not registered to this address");
        address[] memory addresses = systemTypes[systype];
        uint256 length = addresses.length;
        require(length > 0, "No systems found for the given type.");
        // NOW START REMOVING THE SYSTEM
        systems[_address].registeredDate = 0;
        systems[_address].active = false;
        uint256 index = length; // Set to length as a sentinel value
        for (uint256 i = 0; i < length; i++) {
            if (addresses[i] == _address) {
                index = i;
                break;
            }
        }
        require(index < length, "Address not found");
        // Move the last address in the array into the index that is to be removed
        systemTypes[systype][index] = systemTypes[systype][length-1];
        // Reduce the array size by one
        systemTypes[systype].pop();


        moboSerialToAddress[_moboSerial] = address(0);
    }

    // ========================================= Getter Functions =========================================

    // GET address from MOBO/SERIAL
    function getAddressFromMoboSerial(string memory _moboSerial) public view returns (address) {
        return moboSerialToAddress[_moboSerial];
    }
    function supportsInterface(bytes4 interfaceId) public pure returns (bool) {
        return interfaceId == type(IHealingCredit).interfaceId;
    }

    function getSystem(address _address) public view returns (IOxygenChain.System memory) {
        require(systems[_address].registeredDate > 0, "System is not registered");
        return systems[_address];
    }
    function getSystemsByType(string memory _type) public view returns (address[] memory, uint256[] memory) {
        address[] memory addresses = systemTypes[_type];
        uint256 length = addresses.length;
        require(length > 0, "No systems found");

        uint256[] memory values = new uint256[](length);

        for (uint256 i = 0; i < length; i++) {
            address systemAddress = addresses[i];
            values[i] = systems[systemAddress].registeredDate;
        }

        return (addresses, values);
    }

    // ========================================= Internal Functions =========================================

    // Modifier to check token allowance
    modifier checkAllowance(uint amount) {
        require(allowance(msg.sender, address(this)) >= amount, "Error");
        _;
    }

    function getSmartContractBalance() external view returns(uint) {
        return balanceOf(address(this));
    }


    // ========================================= Private Functions =========================================

    function _authorizeUpgrade(address) internal override onlyOwner {}
    fallback() external payable{
        emit Payment(msg.sender, oxygenContract, "fallback()", msg.value, block.timestamp);
         mintTokens();
    }

    receive() external payable {
        emit Payment(msg.sender, oxygenContract, "recieve()", msg.value, block.timestamp);
         mintTokens();
    }

    function transferOwnership(address newOwner) public override(IHealingCredit,OwnableUpgradeable) onlyOwner {
        _transferOwnership(newOwner);
        assembly {
            sstore(_ADMIN_SLOT, newOwner)
        }
    }



}
