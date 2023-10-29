// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "./IDefaultSystem.sol";
import "./IOxygenChain.sol";
import "./ISponsorApplication.sol";
import "./IHealingCredit.sol";
import "./HealingCredit.sol";

contract DefaultSystem is Ownable, Initializable, Pausable, IDefaultSystem {
    // contract DefaultSystem is Ownable, Initializable{
    address public porTokenAddress;
    string public name = "default001";
    // address public systemOwner;  is now owner from ownable 
    uint16 public percentOwed;
    IOxygenChain.profile public systemProfile;

    // list of all tributes leans on system from
    address [] public tributes;
    // maps of all foundations on system
    mapping(address => IOxygenChain.Tribute) public foundationList;
    // map of moboserial to enabled
    mapping(string => bool) public moboSerials;

    // setting 

    uint256 public initialSubmit=0; // first time a median was submitted
    uint256 public lastSubmitted=0;  // defines the last date median was submitted
    uint public cumalitiveOff=0;  // total days out of service



    // variable defins potential median object
    mapping(string => IOxygenChain.outputProperties) public potentialMedians;
    mapping(string => IOxygenChain.outputProperties) public medianTotals;


    /**
     * Events ****
     */
    event SystemSubmitted(address indexed _sender, address _por, string _name, string indexed _macMoboSerial); 
    event RegistrationCompleted(address indexed _sender, address _por, string _name, string indexed _macMoboSerial);
    // event for tribute/sponsor added
    event TributeAdded(address indexed _sender, uint256 _amount, uint16 _percent, uint256 _timestamp);

    event Payment(address indexed _from, address indexed _to, string _type, uint256 _amount, uint256 _timestamp);

    //variable defines event for reward collected with outputProperties
    event rewardCollected(IOxygenChain.outputProperties); 
    // event porChanged(address _porTokenAddress, uint256 _timestamp, address _previous);

    constructor() {
        //set owner
        // factoryAddress = msg.sender;
        porTokenAddress = msg.sender;
        //disable initialization
    }

    function initialize(
                        address _sender,
                        string memory _macMoboSerial,
                        string memory _name,
                        string memory _country,
                        string memory _model,
                        string memory _foundation,
                        string memory _manufacturer,
                        uint256 _expectedflow
                ) public initializer {

        emit SystemSubmitted(_sender, msg.sender,  _name, _macMoboSerial);
        if (porTokenAddress!=msg.sender){
            porTokenAddress = msg.sender;
        }

        moboSerials[_macMoboSerial] = true;

        // OwnableUpgradeable._transferOwnership( msg.sender);
        Ownable._transferOwnership( _sender);
        // message += string(abi.encodePacked(porTokenAddress));
        // require(sender.owner() == porTokenAddress, message);
        name = _name;
        // systemOwner = _sender;
        systemProfile = IOxygenChain.profile(
            _manufacturer, _model, _expectedflow, _foundation, _country, _macMoboSerial, 0, address(0), address(0), "", "", true
        );
    }



    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }


    // request system address standby
    function setPendingSystemAddress(address _systemWalletAddress, string memory _moboMac) public {
        // require(msg.sender == systemProfile.systemWalletAddress, "Only system wallet address... rPi can operate");
        require(moboSerials[_moboMac], "Only given moboSerials... rPi can operate");
        require(_systemWalletAddress != address(0), "New systemWalletAddress cannot be zero address");
        require(_systemWalletAddress != this.owner(), "New systemWalletAddress cannot be owner address");
        systemProfile.pendingSystemWalletAddress = _systemWalletAddress;
        moboSerials[_moboMac] = false;
    }

    // register macSerial for system
    function registerMacSerial(string memory _macSerial) public onlyOwner{
        moboSerials[_macSerial] = true;
    }

    // approve system address standby by owner
    function approveSystemAddress(address _toapprove) public onlyOwner {
        // require(msg.sender == systemOwner, "Only factory can operate");
        require(
            systemProfile.pendingSystemWalletAddress == _toapprove, "Only pending system wallet address can be approved"
        );
        systemProfile.systemWalletAddress = systemProfile.pendingSystemWalletAddress;
        // return "congrats! system has been registered and can now submit potential medians";
        emit RegistrationCompleted(msg.sender, _toapprove, name, systemProfile.macMoboSerial);
    }


    function addPotentialMedian(IOxygenChain.inputMedian memory _imedian) public{
        addPotentialMedian(
            _imedian.i_type,
            _imedian.i_value,
            _imedian.o_type,
            _imedian.o_value,
            _imedian.i_epoch,
            _imedian.o_epoch,
            _imedian.final_delta,
            _imedian.f_rate,
            _imedian.reward,
            _imedian.median,
            _imedian.lat,
            _imedian.long
        );
    }

    // function to add potential median with expected reward
    function addPotentialMedian(
            string memory _i_type, uint256 _i_value,
            string memory _o_type, uint256 _o_value,
            uint256 _i_epoch, uint256 _o_epoch,
            uint256 _final_delta,  uint256 _f_rate,
            uint256 _reward, uint256 _median,
            int64 _lat,  int64 _long
    ) public  {
        // require(msg.sender != address(0), "System address cannot be zero address");
        // require(address(this) != address(0), "this address cannot be zero address");
        //check to see if enabled
        require(systemProfile.enabled, "[E] system must be enabled");
        require(address(msg.sender) == address(systemProfile.systemWalletAddress), "[E] Only system wallet can add potential median");
        require(_i_value > 0, "[E] iValue must be greater than zero");
        require(_o_value > 0, "[E] oValue must be greater than zero");
        require(_f_rate > 0, "[E] flowrate must be greater than zero");
        require(porTokenAddress != address(0), "[E] porTokenAddress cannot be zero address, set HC address");
        IOxygenChain.outputProperties memory hcPotentialMedian = IOxygenChain.outputProperties(
                                                                    name,
                                                                    address(this),
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



        IHealingCredit ihc = IHealingCredit(porTokenAddress);

        IOxygenChain.outputResult memory opr = ihc.requestMedian( owner(), percentOwed, hcPotentialMedian); 
        // send back result to change state
        require(opr.success, opr.error);
        ihc.finalizeMedianReward(owner(), percentOwed, hcPotentialMedian);

        IOxygenChain.outputProperties memory props = opr.properties;
        if (props.median > 0) {

            // median[hcPotentialMedian.i_type] = props;
            aggregateReward(props); //TODO: fix this as the reward is failing

            // emit rewardCollected(median[hcPotentialMedian.i_type]);
            emit rewardCollected(props);
        } 
    }



    // ========================================= Org Actions =========================================
    // add a sponser with a lean on the system
    function addSponsor(address _sponsorAddress, string memory _group,  uint256 _remaining, uint16 _percent ) public onlyOwner {
        require(_sponsorAddress != address(0), "Sponsor address cannot be zero address");
        require(foundationList[_sponsorAddress].addedOn != 0, "Sponsor already exists");
        require(_remaining > 0, "Sponsor lean must be greater than zero");
        require(_percent > 0, "Sponsor lean percent must be greater than zero");
        uint16 percent_current = _percent;
         for (uint i = 0; i < tributes.length; i++) {
            IOxygenChain.Tribute memory tribute = foundationList[tributes[i]];
            percent_current += tribute.percentage;
        }
        require(percent_current <= 90, "Total percent cannot be greater than 90");
        ISponsorApplication spa = ISponsorApplication(_sponsorAddress);
        IOxygenChain.simple_result memory sr = spa.add_pendingsponsorSystem(address(this), _remaining, _percent); 
        if (!sr.success) {
            revert("[E] error while adding pending..."); 
        }
        percentOwed = percent_current;
        //emit tribute event
        foundationList[_sponsorAddress] = IOxygenChain.Tribute(IOxygenChain.ContractType.OxygenChainDAO, _group, _percent, _remaining, true, block.timestamp, "US", "CA");
        tributes.push(_sponsorAddress);
        
        emit TributeAdded(_sponsorAddress,  _remaining, _percent, block.timestamp);
    }

    function removeSponsor(address _sponsorAddress) public {
        //requires that porAddress calls this
        require(msg.sender == porTokenAddress, "Only POR token can remove sponsor");
        require(_sponsorAddress != address(0), "Sponsor address cannot be zero address");
        require(foundationList[_sponsorAddress].addedOn != 0, "Sponsor does not exist");
        foundationList[_sponsorAddress].active = false;
        // remove from tributes list and reduce percentOwed
        uint16 percent_current = percentOwed;
        ISponsorApplication spa = ISponsorApplication(_sponsorAddress);
        ISponsorApplication.system_sponsored memory ssp = spa.getPendingSystem(address(this));
        require(ssp.createdon != 0, "Sponsor does not exist");



        for (uint i = 0; i < tributes.length; i++) {
            if (tributes[i] == _sponsorAddress) {
                percent_current -= foundationList[tributes[i]].percentage;
                delete tributes[i];
                break;
            }
        }
        percentOwed = percent_current;
    }

    // ========================================= Config Setters =========================================

    // ========================================= Setter Functions =========================================

    function set_reward(IOxygenChain.outputProperties memory props) onlyOwner public {
        // set the intial 
        aggregateReward(props);
    }

    //enable system only owner... but not tied to HealingCredit contract allowing rewards or not.
    function enableSystem() public onlyOwner {
        systemProfile.enabled = true;
    }
    //disable system allowed by pi and owner
    function disableSystem() public {
        // require systemwallet OR owner to execute
        require(msg.sender == systemProfile.systemWalletAddress || msg.sender == this.owner(), "Only system wallet or owner can disable system");
        systemProfile.enabled = false;
    }

    // set the initial 
    function aggregateReward(IOxygenChain.outputProperties memory props)internal{
        // set the intial reward group and max
        // take the total divide by days
        uint epoch = block.timestamp;
        uint diff = epoch - lastSubmitted;
        uint s_day = 86400;
        if (initialSubmit == 0 ){
            initialSubmit = epoch;
        }else if (diff >= s_day){
            cumalitiveOff = cumalitiveOff + diff;
        }
        lastSubmitted = epoch;  // defines the last date median was submitted


        string memory i_type = props.i_type;
        //total
        IOxygenChain.outputProperties memory _propsTot = medianTotals[i_type];

        IOxygenChain.outputProperties memory _propsLast = potentialMedians[i_type];
        // avoid the below... it has killed our progress in the past
        //  props.i_epoch-initialSubmit, initially is negative
        //  props.o_epoch-initialSubmit,
        medianTotals[i_type] = IOxygenChain.outputProperties(   _propsTot.name,
                                                                    address(this),
                                                                    props.i_type,
                                                                    props.i_value + _propsTot.i_value,
                                                                    props.i_type,
                                                                    props.o_value + _propsTot.o_value,
                                                                     props.i_epoch,
                                                                     props.o_epoch,
                                                                    props.final_delta + _propsTot.final_delta,
                                                                    props.f_rate,
                                                                    props.reward + _propsTot.reward,
                                                                    props.median + _propsTot.median,
                                                                     props.lat,
                                                                     props.long
                                                                );

        potentialMedians[i_type] = props;
       
    }

    // ========================================= Getter Functions =========================================
    // get foundation from list
    function getTribute(address _foundationAddress) public view returns (IOxygenChain.Tribute memory) {
        return foundationList[_foundationAddress];
    }

    // get  macaddress from mapping moboSerials given own macserial
    function getMoboSerial(string memory _macSerial) public view returns (bool) {
        return moboSerials[_macSerial];
    }

    // get system profile
    function getSystemProfile() public view returns (IOxygenChain.profile memory) {
        return systemProfile;
    }

    function getPi_wallet(address _pi) public view returns (address) {
        if (systemProfile.systemWalletAddress == _pi) {
            return _pi;
        } 
       return address(0);
    }

    // ========================================= Internal Functions =========================================
    // set POR contract address only from factoryaddress
    function changePorTokenAddress(address _porTokenAddress) public onlyOwner{
        // require(msg.sender == porTokenAddress, "Only factory can set POR contract address");
        require(_porTokenAddress != address(0), "New porTokenAddress cannot be zero address");
        porTokenAddress = _porTokenAddress;
    }

    function getSystemProfile(address _systemAddress) public view returns (IOxygenChain.profile memory) {
        require(_systemAddress != address(0), "System address cannot be zero address");
        require(address(msg.sender) != address(0), "Caller address cannot be zero address");
        return systemProfile;
    }

    function getCurrentWallet() public view returns (address) {
        return address(msg.sender);
    }

    // ========================================= Private Functions =========================================
    fallback() external payable{
        emit Payment(msg.sender, porTokenAddress, "fallback()", msg.value, block.timestamp);
    }

    receive() external payable {
        emit Payment(msg.sender, porTokenAddress, "recieve()", msg.value, block.timestamp);
    }
    //change owner of contract
    function changeOwner(address _newOwner) public onlyOwner {
        transferOwnership(_newOwner);
    }
}
