// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

// Have the invariants aka properties
// 1. The total supply of DSC should be less than the total value of collateral
// 2. Getter view functions should never revert => evergreen invariants

import {Test, console} from "forge-std/Test.sol";
import {StdInvariant} from "forge-std/StdInvariant.sol";
import {DeployDSC} from "../../script/DeployDSC.s.sol";
import {DSCEngine} from "../../src/DSCEngine.sol";
import {DecentralizedStableCoin} from "../../src/DecentralizedStableCoin.sol";
import {HelperConfig} from "../../script/HelperConfig.s.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {Handler} from "./Handler.t.sol";

contract Invariants is StdInvariant, Test {
    DeployDSC deployer;
    DSCEngine engine;
    DecentralizedStableCoin dsc;
    HelperConfig config;
    Handler handler;
    address weth;
    address wbtc;

    function setUp() external {
        deployer = new DeployDSC();
        (dsc, engine, config) = deployer.run();
        (, , weth, wbtc, ) = config.activeNetworkConfig();
        handler = new Handler(engine, dsc);
        targetContract(address(handler));
    }

    function invariant_protocolMustHaveMoreValueThanTotalSupply() public view {
        uint256 totalSupply = dsc.totalSupply();
        uint256 totalWethDeposited = IERC20(weth).balanceOf(address(dsc));
        uint256 totalBtcDeposited = IERC20(wbtc).balanceOf(address(dsc));

        uint256 wethValue = engine.getUsdValue(weth, totalWethDeposited);
        uint256 btcValue = engine.getUsdValue(wbtc, totalBtcDeposited);

        console.log("Total supply: ", totalSupply);
        console.log("Total WETH deposited: ", totalWethDeposited);
        console.log("Total BTC deposited: ", totalBtcDeposited);
        console.log("WETH value: ", wethValue);
        console.log("BTC value: ", btcValue);
        console.log("Times mint is called: ", handler.timesMintIsCalled());

        assert(totalSupply <= wethValue + btcValue);
    }

    // function invariant_gettersShouldNotRevert() public view {
    //     engine.getUsdValue(weth, 0);
    // }
}
