// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.19;

import "forge-std/Script.sol";
import { IERC20 } from "@solidstate/contracts/interfaces/IERC20.sol";
import { IDiamondWritableInternal } from "@solidstate/contracts/proxy/diamond/writable/IDiamondWritableInternal.sol";
import { IERC20Extended } from "@solidstate/contracts/token/ERC20/extended/IERC20Extended.sol";
import { IERC20Metadata } from "@solidstate/contracts/token/ERC20/metadata/IERC20Metadata.sol";
import { IERC2612 } from "@solidstate/contracts/token/ERC20/permit/IERC20Permit.sol";

import { ITokenProxy } from "../../../contracts/diamonds/Token/ITokenProxy.sol";
import { TokenProxy } from "../../../contracts/diamonds/Token/TokenProxy.sol";
import { IToken } from "../../../contracts/facets/Token/IToken.sol";
import { Token } from "../../../contracts/facets/Token/Token.sol";
import { AxelarBridge } from "../../../contracts/facets/AxelarBridge/AxelarBridge.sol";
import { IAxelarBridge } from "../../../contracts/facets/AxelarBridge/IAxelarBridge.sol";
import { IAxelarExecutable } from "@axelar/interfaces/IAxelarExecutable.sol";

/// @title DeployToken
/// @dev deploys the TokenProxy diamond contract and the Token facet, and performs
/// a diamondCut of the Token facet onto the TokenProxy diamond
contract DeployToken is Script {
    /// @dev runs the script logic
    function run() external {
        //NOTE: CHANGE AS NEEDED FOR PRODUCTION
        string memory name = "MINT";
        string memory symbol = "$MINT";
        address gateway = vm.envAddress("GATEWAYWAY_ADDRESS");
        address gasService = vm.envAddress("GAS_SERVICE_ADDRESS");

        // read deployer private key
        uint256 deployerPrivateKey = vm.envUint("DEPLOYER_KEY");

        vm.startBroadcast(deployerPrivateKey);

        // deploy Token facet
        Token tokenFacet = new Token();

        uint256 canDeployAxelarBridgeFacet = vm.envUint(
            "CAN_DEPLOY_AXELAR_BRIDGE_FACET"
        );

        AxelarBridge axelarBridgeFacet;

        if (canDeployAxelarBridgeFacet == 1) {
            // deploy AxelarBridge facet
            axelarBridgeFacet = new AxelarBridge(gateway, gasService);

            console.log(
                "AxelarBridge Facet Address: ",
                address(axelarBridgeFacet)
            );
        }

        // deploy TokenProxy
        TokenProxy tokenProxy = new TokenProxy(name, symbol);

        console.log("Token Facet Address: ", address(tokenFacet));
        console.log("Token Proxy Address: ", address(tokenProxy));

        writeTokenProxyAddress(address(tokenProxy));

        // get Token facet cuts
        ITokenProxy.FacetCut[] memory facetCuts = getTokenFacetCuts(
            address(tokenFacet)
        );

        // cut Token into TokenProxy
        tokenProxy.diamondCut(facetCuts, address(0), "");

        if (canDeployAxelarBridgeFacet == 1) {
            // get AxelarBridge facet cut
            ITokenProxy.FacetCut[]
                memory axelarBridgeFacetCut = getAxelarBridgeFacetCuts(
                    address(axelarBridgeFacet)
                );

            // cut AxelarBridge into TokenProxy
            tokenProxy.diamondCut(axelarBridgeFacetCut, address(0), "");
        }

        vm.stopBroadcast();
    }

    /// @dev provides the facet cuts for cutting Token facet into TokenProxy
    /// @param facetAddress address of Token facet
    function getTokenFacetCuts(
        address facetAddress
    ) internal pure returns (ITokenProxy.FacetCut[] memory) {
        // map the ERC20 function selectors to their respective interfaces
        bytes4[] memory erc20FunctionSelectors = new bytes4[](14);

        // base selector
        erc20FunctionSelectors[0] = IERC20.totalSupply.selector;
        erc20FunctionSelectors[1] = IERC20.balanceOf.selector;
        erc20FunctionSelectors[2] = IERC20.allowance.selector;
        erc20FunctionSelectors[3] = IERC20.approve.selector;
        erc20FunctionSelectors[4] = IERC20.transfer.selector;
        erc20FunctionSelectors[5] = IERC20.transferFrom.selector;

        // extended selectors
        erc20FunctionSelectors[6] = IERC20Extended.increaseAllowance.selector;
        erc20FunctionSelectors[7] = IERC20Extended.decreaseAllowance.selector;

        // metadata selectors
        erc20FunctionSelectors[8] = IERC20Metadata.decimals.selector;
        erc20FunctionSelectors[9] = IERC20Metadata.name.selector;
        erc20FunctionSelectors[10] = IERC20Metadata.symbol.selector;

        // permit selectors
        erc20FunctionSelectors[11] = IERC2612.DOMAIN_SEPARATOR.selector;
        erc20FunctionSelectors[12] = IERC2612.nonces.selector;
        erc20FunctionSelectors[13] = IERC2612.permit.selector;

        ITokenProxy.FacetCut memory erc20FacetCut = IDiamondWritableInternal
            .FacetCut({
                target: address(facetAddress),
                action: IDiamondWritableInternal.FacetCutAction.ADD,
                selectors: erc20FunctionSelectors
            });

        // map the Token function selectors to their respective interfaces
        bytes4[] memory tokenFunctionSelectors = new bytes4[](19);

        tokenFunctionSelectors[0] = IToken.accrualData.selector;

        tokenFunctionSelectors[1] = IToken.addMintingContract.selector;

        tokenFunctionSelectors[2] = IToken.airdropSupply.selector;

        tokenFunctionSelectors[3] = IToken.BASIS.selector;

        tokenFunctionSelectors[4] = IToken.burn.selector;

        tokenFunctionSelectors[5] = IToken.claim.selector;

        tokenFunctionSelectors[6] = IToken.claimableTokens.selector;

        tokenFunctionSelectors[7] = IToken.disperseTokens.selector;

        tokenFunctionSelectors[8] = IToken.distributionFractionBP.selector;

        tokenFunctionSelectors[9] = IToken.distributionSupply.selector;

        tokenFunctionSelectors[10] = IToken.globalRatio.selector;

        tokenFunctionSelectors[11] = IToken.mint.selector;

        tokenFunctionSelectors[12] = IToken.mintAirdrop.selector;

        tokenFunctionSelectors[13] = IToken.mintReferral.selector;

        tokenFunctionSelectors[14] = IToken.mintingContracts.selector;

        tokenFunctionSelectors[15] = IToken.removeMintingContract.selector;

        tokenFunctionSelectors[16] = IToken.SCALE.selector;

        tokenFunctionSelectors[17] = IToken.setDistributionFractionBP.selector;

        tokenFunctionSelectors[18] = IToken.claimFor.selector;

        ITokenProxy.FacetCut memory tokenFacetCut = IDiamondWritableInternal
            .FacetCut({
                target: address(facetAddress),
                action: IDiamondWritableInternal.FacetCutAction.ADD,
                selectors: tokenFunctionSelectors
            });

        ITokenProxy.FacetCut[] memory facetCuts = new ITokenProxy.FacetCut[](2);
        facetCuts[0] = erc20FacetCut;
        facetCuts[1] = tokenFacetCut;

        return facetCuts;
    }

    /// @dev provides the facet cuts for cutting AxelarBridge facet into TokenProxy
    /// @param facetAddress address of AxelarBridge facet
    function getAxelarBridgeFacetCuts(
        address facetAddress
    ) internal pure returns (ITokenProxy.FacetCut[] memory) {
        // map the AxelarBridge function selectors to their respective interfaces
        bytes4[] memory axelarBridgeFunctionSelectors = new bytes4[](7);

        axelarBridgeFunctionSelectors[0] = IAxelarBridge.bridgeToken.selector;
        axelarBridgeFunctionSelectors[1] = IAxelarBridge
            .enableSupportedChains
            .selector;
        axelarBridgeFunctionSelectors[2] = IAxelarBridge
            .disableSupportedChains
            .selector;
        axelarBridgeFunctionSelectors[3] = IAxelarBridge
            .supportedChains
            .selector;
        axelarBridgeFunctionSelectors[4] = IAxelarExecutable.execute.selector;
        axelarBridgeFunctionSelectors[5] = IAxelarExecutable
            .executeWithToken
            .selector;
        axelarBridgeFunctionSelectors[6] = IAxelarExecutable.gateway.selector;

        ITokenProxy.FacetCut
            memory axelarBridgeFacetCut = IDiamondWritableInternal.FacetCut({
                target: address(facetAddress),
                action: IDiamondWritableInternal.FacetCutAction.ADD,
                selectors: axelarBridgeFunctionSelectors
            });

        ITokenProxy.FacetCut[] memory facetCuts = new ITokenProxy.FacetCut[](1);
        facetCuts[0] = axelarBridgeFacetCut;
        return facetCuts;
    }

    function writeTokenProxyAddress(address tokenProxyAddress) internal {
        string memory inputDir = string.concat(
            vm.projectRoot(),
            "/broadcast/01_deployToken.s.sol/"
        );

        string memory chainDir = string.concat(vm.toString(block.chainid), "/");

        string memory file = string.concat(
            "run-latest-token-proxy-address",
            ".txt"
        );

        vm.writeFile(
            string.concat(inputDir, chainDir, file),
            vm.toString(tokenProxyAddress)
        );
    }
}
