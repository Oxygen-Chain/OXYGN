// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;
// forge test --match-test testfactorySpawnSystem --match-contract HealingCreditTest -vv --via-ir
//forge test  --match-contract HealingCreditTest --via-ir --debug testfactorySpawnSystem

import {console} from "forge-std/console.sol";
import "forge-std/Test.sol";
// test with block


import "../src/DefaultSystem.sol";
import "../src/IDefaultSystem.sol";
import "../src/IHealingCredit.sol";
import "../src/HealingCredit.sol";
import "../src/IOxygenChain.sol";
import "../src/OxygenChain.sol";



// import "../src/DefaultSystem.sol";

// import "../src/OxygenChain.sol";
/**the defaultSystem contract will be created from the HealingCredit Factory
 * once created the PORaddress will be tied to the HC address
 * There will be functions to allow system owners to withdraw funds
 * Each systemContract will be referenced directly in the HC contract
 * */
contract HealingCreditTest is Test {
    HealingCredit public hc;
    DefaultSystem public ds;
    OxygenChain public oc;
    string moboSerial = "000000000abc0ab1_00-B0-D0-63-C2-26";
    address someRandomUser = vm.addr(1);
    address owner;
    address rpi;
    uint256 rpi_key;
    IOxygenChain.outputProperties propsMedian;

    address internal constant DAI_WHALE = 0xbEbc44782C7dB0a1A60Cb6fe97d0b483032FF1C7;

    struct median{
        string inputType;
        uint256 inputValue;
        string outputType;
        uint256 outputValue;
        
    }

    function setUp() public {
        // deal(DAI_WHALE, 10000 ether);
        uint16 percent = 900;
        address a = 0x0000000000000000000000000000000000000001;
        propsMedian = IOxygenChain.outputProperties(
            "wetNWild_Pooool",
            a,
            "dissolved_oxygen",
            75,
            "dissolved_oxygen",
            100,
            1673838392,
            1673838411,
            2345,
            832,
            43210000,
            38,
            40748817,
            -73985428
        );
        vm.prank(a);
        oc = new OxygenChain();

        // start prank
        // vm.startPrank(someRandomUser);
        // vm.deal(someRandomUser, 1 ether);
        owner = msg.sender;
        //    vm.prank(someRandomUser);
        vm.prank(a);
        hc = new HealingCredit();
        vm.prank(a);
        hc.setOxygenContract(address(oc));

        vm.startPrank(oc.owner());
        oc.setmaxInProgressPending(100);
        string memory role = "TreatmentPool";
        string memory typein = "sewer";
        string memory country = "br";
        string memory region = "rio";
        // vm.prank(oc.owner());
        oc.setPendingContract(address(hc),role, typein, country, region);
        // vm.prank(oc.owner());
        oc.approveContract(address(hc), percent);
        vm.stopPrank();
        (address alice, uint256 key) = makeAddrAndKey("raspberry");
        rpi = alice;
        rpi_key = key;
    }

    // function factorySpawnSystem(string memory _moboSerial, string memory _name, string memory _systemType , uint256 _percent,
    //                         string memory _country, string memory _model, string memory _foundation,
    //                         string memory _manufacturer, string memory _lat, string memory _long) internal returns (address) {

    //                         }
    //  forge test --match-test testDefaultSystemDeploy --match-contract HealingCreditTest -vvvv --via-ir
    function testDefaultSystemDeploy() public {
        address a = 0x0000000000000000000000000000000000000029;
        vm.prank(a);
        ds = new DefaultSystem();
        vm.prank(hc.owner());
        hc.setDefaultSystemContract(address(ds));

        vm.prank(a);
        ds.changePorTokenAddress(address(hc));
        // assertEq(hc.owner(), ds.porTokenAddress());
        assertEq(ds.owner(), a);
        // assertEq(ds.porTokenAddress(), a);
        assertEq(ds.porTokenAddress(), address(hc));
        // vm.prank(ds.owner());
        // ds.changeOwner(hc.owner());
    }

    // forge test --match-test testfactorySpawnSystem --match-contract HealingCreditTest -vvvv --via-ir
    function testfactorySpawnSystem() public {
        testDefaultSystemDeploy();
        int64 lat = 40748817; //"40.748817";
        int64  long = -73985428; //"-73.985428";
        string memory foundation = "OxygenChain_Miami";
        string memory man = "Toyota";
        string memory model = "Honda_v2022";
        string memory country = "us";
        string memory systemType = "sewage";
        string memory name = "wetNWild_Pooool";
        // add primary event
    
        uint256 eflow = 100;
        // uint256 percent = 0;
        // get new System
        // vm.prank(hc.owner());

        // assertEq(address(hc), hc.owner());
        vm.prank(address(hc));
        address raw_newSystem =
            hc.initializeSystem(moboSerial, name, systemType, country, model, foundation, man, eflow, lat, long);
        // DefaultSystem newSystem = DefaultSystem(raw_newSystem);
        ds = DefaultSystem(payable(raw_newSystem));
            vm.startPrank(ds.owner());
            ds.changeOwner(address(hc));
            changePrank(ds.owner());
            ds.changePorTokenAddress(ds.owner());
            // ds.changePorTokenAddress(address(hc)); //error of YulException: Variable _3 is 1 too deep in the stack 
        assertEq(ds.porTokenAddress(), address(hc));
        vm.stopPrank();
        // assertEq(hc.owner(), ds.owner());
    }

    // forge test --match-test testtokenBalance --match-contract HealingCreditTest -vvvv --via-ir 
    function testtokenBalance() public{
        uint256 amount = 10000e18;
        deal(address(hc), address(hc), amount);
        IERC20Upgradeable token = IERC20Upgradeable(address(hc));
        assertEq(token.balanceOf(address(hc)), amount);

        // oc.approveContract(address(hc), percent);
        uint256 totalReward = 1000000e18;
        uint256 reward = hc.medianFutureReward(propsMedian, totalReward);
        assertEq(reward, 1951040);
    }


    // forge test --match-test testrequestMedian --match-contract HealingCreditTest -vvvv --via-ir 
    // function to test a failed median request
    function testrequestMedian() public{
        testfactorySpawnSystem();
        address a = 0x0000000000000000000000000000000000000001;
        string memory name = "wetNWild_Pooool";
        // string memory systype = "sewage";
        string memory systype = "sewage";
        string memory country = "us";
        vm.prank(address(hc.owner()));
        hc.approveChildSystemContract(a, name, systype, country, 0, 0);

        uint16 percent = 0;
        address sys = address(ds);
        uint amount = 10000e18;
        
        deal(address(hc), address(hc), amount, true);
        // vm.deal(address(hc), amount);

        assertEq(hc.balanceOf(address(hc)), amount);
        vm.prank(address(a));
        hc.requestMedian(sys, percent, propsMedian);
    }

    // forge test --match-test testSendPotentialMedian --match-contract HealingCreditTest -vvvv --via-ir
    // test send median data
    function testSendPotentialMedian() public {
        testfactorySpawnSystem();
        address b = 0x0000000000000000000000000000000000000006;

        vm.prank(address(hc));
        ds.setPendingSystemAddress(b, moboSerial);
        // vm.prank(hc.owner());
        vm.prank(address(hc));
        ds.approveSystemAddress(b);
        assertEq(address(hc), ds.porTokenAddress());
        // assertEq(ds.porTokenAddress(), ds.porTokenAddress());
        
        //TODO: Resolve BELOW... ABOVE WORKS!!!!!
        deal(address(hc), address(hc), 10000e18, true );
        vm.prank(b);
        ds.addPotentialMedian(propsMedian.i_type, propsMedian.i_value, propsMedian.o_type, propsMedian.o_value,
                                propsMedian.i_epoch, propsMedian.o_epoch, propsMedian.final_delta,
                                propsMedian.f_rate, propsMedian.reward,
                                propsMedian.median, propsMedian.lat, propsMedian.long);

        
        // // vm.stopPrank();
        // //TODO: check if balance increased for default contract based on median

        // assertEq(hc.balanceOf(address(a)), propsMedian.reward);
    }

    // forge test --match-test testParticipantReward --match-contract HealingCreditTest -vvvv --via-ir
    function testParticipantReward() public{
        testDefaultSystemDeploy();  // doesn't matter who deployed it as long as we have address
        address oxgn_wallet = 0x0000000000000000000000000000000000000030;
        address sysown_wallet = 0x0000000000000000000000000000000000000031;
        address pi_wallet = 0x0000000000000000000000000000000000000032;
        int64 lat = 40748817; //"40.748817";
        int64  long = -73985428; //"-73.985428";
        string memory foundation = "OxygenChain_Miami";
        string memory man = "Toyota";
        string memory model = "Honda_v2022";
        string memory country = "us";
        string memory systemType = "sewage";
        string memory name = "wetNWild_Pooool";
        
        uint256 eflow = 100;
        vm.recordLogs();
        vm.prank(sysown_wallet);
        address raw_newSystem = hc.initializeSystem(moboSerial, name, systemType, country, model, foundation, man, eflow, lat, long);
        ////////////////////////////////////////////////////////////////////////////////////////
        ///////// THE ABOVE requires time to MINE to block before OWNERSHIP IS CHANGED  ////////
        ////////////////////////////////////////////////////////////////////////////////////////
        // ----------->>>>>           ----------->>>>>           ----------->>>>>           //
        // hc.initializeSystem(moboSerial, name, systemType, country, model, foundation, man, eflow, lat, long);


        // HC APPROVE CHILD SYSTEM CONTRACT... normally done by the DAO
        vm.prank(hc.owner());
        hc.approveChildSystemContract(address(raw_newSystem), name, systemType, country, 0, 0);
        // get event from above call
        // Vm.Log[] memory logs = vm.getRecordedLogs();

        // set the Default System INSTANCE ADDRESS here
        ds = DefaultSystem(payable(raw_newSystem));
        // vm.warp(1683764689+ 3 days); 
        // uint256 numberOfBlocks = 10;
        // vm.roll(block.number() + numberOfBlocks);
        address ds_owner = ds.owner();
        // emit log_named_address("ds_owner", ds_owner);
        assertEq(ds_owner, sysown_wallet);
        
        // POR = HC is it same as ds.porTokenAddress()?
        assertEq(ds.porTokenAddress(), address(hc));  // this could be zero and will cause an issue

        
        // // assertEq(logs.length, 4);
        // // address raw_sys = abi.decode(logs[0].data, (address));
        // // assertEq(raw_sys, address(hc));
        // // completed in testDefaultSystemDeploy()
        // // assertEq(logs[0].topics[0], keccak256("SystemSpawned(address,string,string,address,uint256)"));
        // // assertEq(abi.decode(entries[0].data, (string)), "operation completed");

        // // now owner register the pi's moboserial for the system
        vm.prank(address(sysown_wallet));
        ds.registerMacSerial(moboSerial);

        // // pi node will submit its own wallet address for approval
        vm.prank(address(pi_wallet));
        ds.setPendingSystemAddress(pi_wallet, moboSerial);
        // //
        // // OWNER will approvesystemaddress
        vm.prank(address(sysown_wallet));
        ds.approveSystemAddress(pi_wallet);

        // // // now request median
        vm.prank(address(pi_wallet));
        deal(address(hc), address(hc), 10000e18, true );
        //check how much  hc has now
        assertEq(hc.balanceOf(address(hc)), 10000e18);
        // // make sure the type remains the same:::: 
        // assertEq(propsMedian.i_type, systemType);
        vm.prank(address(pi_wallet));
        ds.addPotentialMedian(propsMedian.i_type, propsMedian.i_value, propsMedian.o_type, propsMedian.o_value,
                                propsMedian.i_epoch, propsMedian.o_epoch, propsMedian.final_delta,
                                propsMedian.f_rate, propsMedian.reward,
                                propsMedian.median, propsMedian.lat, propsMedian.long);

        
    }

    // testFail<function name>
}
