// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;
// forge test --match-test testapproveContract --match-contract OxygenChainTest -vv --via-ir
import {console} from "forge-std/console.sol";
import "forge-std/Test.sol";
import "../src/IOxygenChain.sol";
import "../src/OxygenChain.sol";


contract OxygenChainTest is Test {

    OxygenChain public oxygen;
    address someRandomUser = vm.addr(1);
    address owner;
    address rpi;
    uint256 rpi_key;
    address first_test = 0x9800000000000000000000000000000000000034;
    address a = 0x0000000000000000000000000000000000000001;
    function setUp() public {
        owner = first_test;
        vm.startPrank(owner);
        oxygen = new OxygenChain();
        (address alice, uint256 key) = makeAddrAndKey("raspberry");
        rpi = alice;
        rpi_key = key;
        vm.stopPrank();
    }
    // forge test --match-test testsetUp --match-contract OxygenChainTest -vvvv --via-ir
    function testsetUp() public {
        assertEq(oxygen.owner(), first_test);
    }
    function testsetmaxInProgressPending() public {
        uint16 max = 2;
        vm.prank(oxygen.owner());
        oxygen.setmaxInProgressPending(max);
        assertEq(oxygen.getmaxInProgressPending(), max);
    }

    // forge test --match-test testcheckTransferOxygen --match-contract OxygenChainTest -vvvv --via-ir
    function testcheckTransferOxygen() public {
        testapproveContract();
        vm.prank(a);
        oxygen.checkTransferOxygen(a, 100);
    }

    function testaddPendingContract() public {
        testsetmaxInProgressPending();
        string memory role = "TreatmentPool";
        string memory typein = "sewer";
        string memory country = "br";
        string memory region = "rio";
        vm.prank(oxygen.owner());
        oxygen.setPendingContract(a, role, typein, country, region);
        //get tribute attributes from getter getApprovedContract
        IOxygenChain.Tribute memory tribute = oxygen.getPendingContract(a);
        string memory tt_in = OutPut.getContractType(tribute.tributeRole);
        assertEq(tt_in, role);
        //call contract as this address for pending contract
    }

    function testapproveContract() public {
        uint16 percent = 0;
        testaddPendingContract();
        vm.prank(oxygen.owner());
        oxygen.approveContract(a, percent);
        IOxygenChain.Tribute memory tribute = oxygen.getApprovedContract(a);
        assertEq(tribute.percentage, percent);
        // TODO: Test that pendingContracts is empty or doesn't have our "a" in it
    }


    function testaddMaxPendingContract() public {
        testaddPendingContract();
        vm.startPrank(oxygen.owner());
        uint16 max = 0;
        oxygen.setmaxInProgressPending(max);
        assertEq(oxygen.getmaxInProgressPending(), max);
        string memory role = "TreatmentPool";
        string memory typein = "reuse";
        string memory country = "us";
        string memory region = "florida";
        vm.expectRevert("PendingContracts: Max number of pending contracts reached");
        oxygen.setPendingContract(a, role, typein, country, region);
        vm.stopPrank();
    }
}
