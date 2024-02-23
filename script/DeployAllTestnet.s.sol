// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import {DeployAllBase} from "./base/DeployAllBase.sol";

// forge script ./script/DeployAllTestnet.s.sol --legacy --broadcast
contract DeployAll is DeployAllBase {
    function _getUSTBAddress() internal pure override returns (address) {
        return 0x83feDBc0B85c6e29B589aA6BdefB1Cc581935ECD;
    }

    function _getSwapRouterAddress() internal pure override returns (address) {
        return 0xC1734f65345A162edc078edB6465853CF86100B7;
    }

    function _getPearlFactoryAddress() internal pure override returns (address) {
        return 0xC46cDB77FF184562A834Ff684f0393b0cA57b5E5;
    }

    function _getQuoterAddress() internal pure override returns (address) {
        return 0xbA72f9Afb2759eC1882e5D51aa5f8c480Fe61Bd8;
    }

    function _getGelatoMessageSender() internal pure override returns (address) {
        return 0xFe48C99fD8A7cbb8d3a5257E1dCcC69e9a991A48;
    }

    function _getTeamWallet() internal pure override returns (address) {
        return 0x839AEeA3537989ce05EA1b218aB0F25E54cC3B3f;
    }

    function _getAMO() internal pure override returns (address) {
        return 0x839AEeA3537989ce05EA1b218aB0F25E54cC3B3f;
    }

    function _getWETH9() internal pure override returns (address) {
        return 0x9801EEB848987c0A8d6443912827bD36C288F8FB;
    }

    function _getDeploymentChainAliases() internal pure override returns (string[] memory aliases) {
        aliases = new string[](2);
        aliases[0] = "unreal";
        aliases[1] = "sepolia";
    }
}
