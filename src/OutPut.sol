// SPDX-License-Identifier: MIT
// Inspired by https://solidity-by-example.org/defi/uniswap-v2/

pragma solidity ^0.8.13;


import "./IOxygenChain.sol";
// import "@openzeppelin/contracts/proxy/utils/Initializable.sol";
/**
 * @dev Provides a set of functions to operate with system properties.
 *
 * _Available since v3.5._
 */
library OutPut {



    // function that returns string from each enum type
    function getContractType(IOxygenChain.ContractType _role) internal pure returns (string memory) {
        if (_role == IOxygenChain.ContractType.Foundation) { 
            return "Foundation";
        } else if (_role == IOxygenChain.ContractType.MonitoringPool) {
            return "MonitoringPool";
        } else if (_role == IOxygenChain.ContractType.TreatmentPool) {
            return "TreatmentPool";
        } else if (_role == IOxygenChain.ContractType.StakeContract) {
            return "StakeContract";
        } else if (_role == IOxygenChain.ContractType.OxygenChainDAO) {
            return "OxygenChainDAO";
        } else if (_role == IOxygenChain.ContractType.OtherContract) {
            return "OtherContract";
        }
        return "Unknown";
    }

    function compare(string memory str1, string memory str2) public pure returns (bool) {
        if (bytes(str1).length != bytes(str2).length) {
            return false;
        }
        return _compareEq(str1, str2);
    }

    function _compareEq(string memory str1, string memory str2) private pure returns (bool) {
        return keccak256(abi.encodePacked(str1)) == keccak256(abi.encodePacked(str2));
    }
    // function computeCloneAddress(address deployer, bytes32 salt, bytes32 initCodeHash) public pure returns (address) {
    //     bytes32 rawAddress = keccak256(abi.encodePacked(bytes1(0xff), deployer, salt, initCodeHash));
    //     return address(uint160(uint256(rawAddress)));
    // }

    function stringToUint(string memory s) internal pure returns (uint256 result) {
        bytes memory b = bytes(s);
        uint256 i;
        result = 0;
        for (i = 0; i < b.length; i++) {
            uint256 c = uint256(uint8(b[i]));
            if (c >= 48 && c <= 57) {
                result = result * 10 + (c - 48);
            }
        }
    }


    function bindEncode2(bytes4 _template, address _sender, string memory _name, IOxygenChain.profile memory _profile)
        internal
        pure
        returns (bytes memory)
    {
        return abi.encodeWithSelector(
            _template,
            _sender,
            _profile.macMoboSerial,
            _name,
            _profile.country,
            _profile.model,
            _profile.foundation,
            _profile.manufacturer

        );
    }


}
