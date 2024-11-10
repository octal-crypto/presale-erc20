// SPDX-License-Identifier: MIT
pragma solidity 0.8.27;

import {Test, console} from "forge-std/Test.sol";
import {PresaleVestedERC20} from "../src/PresaleVestedERC20.sol";
import "openzeppelin-contracts/contracts/access/Ownable.sol";
import "openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";
import "v2-periphery/interfaces/IUniswapV2Router02.sol";
import 'v2-core/interfaces/IUniswapV2Factory.sol';

contract PresaleVestedERC20Test is Test {

    function setUp() public {
        vm.createSelectFork(vm.rpcUrl("mainnet"), 20000000);
    }

    struct Constructor {
        address owner;
        string name;
        string symbol;
        uint256 totalSupply;
        address uniswapRouter;
        address uniswapFactory;
        PresaleVestedERC20.PresaleConfiguration presale;
        PresaleVestedERC20.VestingConfiguration ethVesting;
        PresaleVestedERC20.VestingConfiguration tokenVesting;
        PresaleVestedERC20.VestingConfiguration liquidityVesting;
    }

    function deployContract(Constructor memory _c) internal returns (PresaleVestedERC20) {
        return new PresaleVestedERC20({ 
            owner: _c.owner, 
            name: _c.name, 
            symbol: _c.symbol, 
            totalSupply: _c.totalSupply, 
            _uniswapRouter: _c.uniswapRouter,
            _uniswapFactory: _c.uniswapFactory, 
            _presale:_c.presale, 
            _ethVesting: _c.ethVesting, 
            _tokenVesting: _c.tokenVesting, 
            _liquidityVesting: _c.liquidityVesting
        });
    }

    function defaultConstructor() internal view returns (Constructor memory)  {
        return Constructor({
            owner: address(this),
            name: "Test Token",
            symbol: "TEST",
            totalSupply: 1000000 * 10**18,
            uniswapRouter: address(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D),
            uniswapFactory: address(0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f),
            presale: PresaleVestedERC20.PresaleConfiguration({
                duration: 1 days,
                minContribution: 1 ether,
                maxContribution: 2 ether,
                softCap: 10 ether,
                hardCap: 20 ether,
                ethPercentLiquidity: 90,
                ethPercentVest: 10,
                tokensPercentPresale: 60,
                tokensPercentLiquidity: 30,
                tokensPercentVest: 10
            }),
            ethVesting: PresaleVestedERC20.VestingConfiguration({
                cliff: 30 days,
                duration: 365 days
            }),
            tokenVesting: PresaleVestedERC20.VestingConfiguration({
                cliff: 30 days,
                duration: 365 days
            }),
            liquidityVesting: PresaleVestedERC20.VestingConfiguration({
                cliff: 30 days,
                duration: 365 days
            })
        });
    }

    function getAddresses(uint256 count) internal view returns (address[] memory) {
        address[] memory addresses = new address[](count);
        for (uint256 i = 0; i < count; i++) {
            addresses[i] = address(uint160(uint256(keccak256(abi.encodePacked(block.timestamp, i)))));
        }
        return addresses;
    }

    function test_constructor_stage() public {
        PresaleVestedERC20 erc20 = deployContract(defaultConstructor());
        assertEq(uint(erc20.stage()), uint(PresaleVestedERC20.Stage.Initial));
    }

    function test_constructor_owner_empty() public {
        Constructor memory _constructor = defaultConstructor();
        _constructor.owner = address(0);
        vm.expectRevert(
            abi.encodeWithSelector(
                Ownable.OwnableInvalidOwner.selector,
                address(0x0000000000000000000000000000000000000000)
            )
        );
        deployContract(_constructor);
    }

    function test_constructor_owner_valid() public {
        Constructor memory _constructor = defaultConstructor();
        _constructor.owner = getAddresses(1)[0];
        PresaleVestedERC20 erc20 = deployContract(_constructor);
        assertEq(erc20.owner(), _constructor.owner);
    }

    function test_constructor_name_empty() public {   
        Constructor memory _constructor = defaultConstructor();
        _constructor.name = "";
        vm.expectRevert("Name cannot be empty");
        deployContract(_constructor);
    }

    function test_constructor_name_valid() public {   
        Constructor memory _constructor = defaultConstructor();
        _constructor.name = "Test Token";
        PresaleVestedERC20 erc20 = deployContract(_constructor);
        assertEq(erc20.name(), _constructor.name);
    }

    function test_constructor_symbol_empty() public {
        Constructor memory _constructor = defaultConstructor();
        _constructor.symbol = "";
        vm.expectRevert("Symbol cannot be empty");
        deployContract(_constructor);
    }

    function test_constructor_symbol_valid() public {
        Constructor memory _constructor = defaultConstructor();
        _constructor.symbol = "TEST";
        PresaleVestedERC20 erc20 = deployContract(_constructor);
        assertEq(erc20.symbol(), _constructor.symbol);
    }

    function test_constructor_totalSupply_zero() public {
        Constructor memory _constructor = defaultConstructor();
        _constructor.totalSupply = 0;
        vm.expectRevert("Total supply must be greater than zero");
        deployContract(_constructor);
    }

    function test_constructor_totalSupply_valid() public {
        Constructor memory _constructor = defaultConstructor();
        _constructor.totalSupply = 1000000 * 10**18;
        PresaleVestedERC20 erc20 = deployContract(_constructor);
        assertEq(erc20.totalSupply(), _constructor.totalSupply);
    }

    function test_constructor_uniswapRouter_empty() public {
        Constructor memory _constructor = defaultConstructor();
        _constructor.uniswapRouter = address(0);
        vm.expectRevert("Uniswap router must be provided");
        deployContract(_constructor);
    }

    function test_constructor_uniswapRouter_valid() public {
        Constructor memory _constructor = defaultConstructor();
        _constructor.uniswapRouter = getAddresses(1)[0];
        PresaleVestedERC20 erc20 = deployContract(_constructor);
        assertEq(address(erc20.uniswapRouter()), _constructor.uniswapRouter);
    }

    function test_constructor_uniswapFactory_empty() public {
        Constructor memory _constructor = defaultConstructor();
        _constructor.uniswapFactory = address(0);
        vm.expectRevert("Uniswap factory must be provided");
        deployContract(_constructor);
    }

    function test_constructor_uniswapFactory_valid() public {
        Constructor memory _constructor = defaultConstructor();
        _constructor.uniswapFactory = getAddresses(1)[0];
        PresaleVestedERC20 erc20 = deployContract(_constructor);
        assertEq(address(erc20.uniswapFactory()), _constructor.uniswapFactory);
    }

    function test_constructor_presale_duration_empty() public {
        Constructor memory _constructor = defaultConstructor();
        _constructor.presale.duration = 0;
        vm.expectRevert("Presale duration must be greater than zero");
        deployContract(_constructor);
    }

    function test_constructor_presale_duration_valid() public {
        Constructor memory _constructor = defaultConstructor();
        _constructor.presale.duration = 1 days;
        PresaleVestedERC20 erc20 = deployContract(_constructor);
        (PresaleVestedERC20.PresaleConfiguration memory presale,,) = erc20.presale();
        assertEq(presale.duration, _constructor.presale.duration);
    }

    function test_constructor_presale_minContribution_zero() public {
        Constructor memory _constructor = defaultConstructor();
        _constructor.presale.minContribution = 0;
        vm.expectRevert("Minimum contribution must be greater than zero");
        deployContract(_constructor);
    }

    function test_constructor_presale_minContribution_valid() public {
        Constructor memory _constructor = defaultConstructor();
        _constructor.presale.minContribution = 1 ether;
        PresaleVestedERC20 erc20 = deployContract(_constructor);
        (PresaleVestedERC20.PresaleConfiguration memory presale,,) = erc20.presale();
        assertEq(presale.minContribution, _constructor.presale.minContribution);
    }

    function test_constructor_presale_softCap_zero() public {
        Constructor memory _constructor = defaultConstructor();
        _constructor.presale.softCap = 0;
        vm.expectRevert("Presale soft cap must be greater than zero");
        deployContract(_constructor);
    }

    function test_constructor_presale_softCap_valid() public {
        Constructor memory _constructor = defaultConstructor();
        _constructor.presale.softCap = 1 ether;
        PresaleVestedERC20 erc20 = deployContract(_constructor);
        (PresaleVestedERC20.PresaleConfiguration memory presale,,) = erc20.presale();
        assertEq(presale.softCap, _constructor.presale.softCap);
    }

    function test_constructor_presale_maxContribution_lessThanMinContribution() public {
        Constructor memory _constructor = defaultConstructor();
        _constructor.presale.minContribution = 2 ether;
        _constructor.presale.maxContribution = 1 ether;
        vm.expectRevert("Maximum contribution must be greater than or equal to the minimum contribution");
        deployContract(_constructor);
    }

    function test_constructor_presale_maxContribution_valid() public {
        Constructor memory _constructor = defaultConstructor();
        _constructor.presale.minContribution = 1 ether;
        _constructor.presale.maxContribution = 2 ether;
        PresaleVestedERC20 erc20 = deployContract(_constructor);
        (PresaleVestedERC20.PresaleConfiguration memory presale,,) = erc20.presale();
        assertEq(presale.maxContribution, _constructor.presale.maxContribution);
    }

    function test_constructor_presale_hardCap_lessThanSoftCap() public {
        Constructor memory _constructor = defaultConstructor();
        _constructor.presale.softCap = 2 ether;
        _constructor.presale.hardCap = 1 ether;
        vm.expectRevert("Hard cap must be greater than or equal to the soft cap");
        deployContract(_constructor);
    }

    function test_constructor_presale_hardCap_valid() public {
        Constructor memory _constructor = defaultConstructor();
        _constructor.presale.softCap = 1 ether;
        _constructor.presale.hardCap = 2 ether;
        PresaleVestedERC20 erc20 = deployContract(_constructor);
        (PresaleVestedERC20.PresaleConfiguration memory presale,,) = erc20.presale();
        assertEq(presale.hardCap, _constructor.presale.hardCap);
    }

    function test_constructor_presale_tokenPercentages_invalid() public {
        Constructor memory _constructor = defaultConstructor();
        _constructor.presale.tokensPercentPresale = 50;
        _constructor.presale.tokensPercentLiquidity = 50;
        _constructor.presale.tokensPercentVest = 10;
        vm.expectRevert("tokensPercentPresale + tokensPercentLiquidity + tokensPercentVest must equal 100");
        deployContract(_constructor);
    }

    function test_constructor_presale_tokenPercentages_valid() public {
        Constructor memory _constructor = defaultConstructor();
        _constructor.presale.tokensPercentPresale = 60;
        _constructor.presale.tokensPercentLiquidity = 30;
        _constructor.presale.tokensPercentVest = 10;
        PresaleVestedERC20 erc20 = deployContract(_constructor);
        (PresaleVestedERC20.PresaleConfiguration memory presale,,) = erc20.presale();
        assertEq(presale.tokensPercentPresale, _constructor.presale.tokensPercentPresale);
        assertEq(presale.tokensPercentLiquidity, _constructor.presale.tokensPercentLiquidity);
        assertEq(presale.tokensPercentVest, _constructor.presale.tokensPercentVest);
    }

    function test_constructor_presale_ethPercentages_invalid() public {
        Constructor memory _constructor = defaultConstructor();
        _constructor.presale.ethPercentLiquidity = 80;
        _constructor.presale.ethPercentVest = 30;
        vm.expectRevert("ethPercentLiquidity + ethPercentVest must equal 100");
        deployContract(_constructor);
    }

    function test_constructor_presale_ethPercentages_valid() public {
        Constructor memory _constructor = defaultConstructor();
        _constructor.presale.ethPercentLiquidity = 90;
        _constructor.presale.ethPercentVest = 10;
        PresaleVestedERC20 erc20 = deployContract(_constructor);
        (PresaleVestedERC20.PresaleConfiguration memory presale,,) = erc20.presale();
        assertEq(presale.ethPercentLiquidity, _constructor.presale.ethPercentLiquidity);
        assertEq(presale.ethPercentVest, _constructor.presale.ethPercentVest);
    }

    function test_constructor_ethVesting_invalid() public { 
        Constructor memory _constructor = defaultConstructor();
        _constructor.ethVesting.cliff = 60 days;
        _constructor.ethVesting.duration = 30 days;
        vm.expectRevert("Vesting duration must be >= cliff period");
        deployContract(_constructor);
    }

    function test_constructor_ethVesting_valid() public { 
        Constructor memory _constructor = defaultConstructor();
        _constructor.ethVesting.cliff = 30 days;
        _constructor.ethVesting.duration = 365 days;
        PresaleVestedERC20 erc20 = deployContract(_constructor);
        (PresaleVestedERC20.VestingConfiguration memory ethVesting,,) = erc20.ethVesting();
        assertEq(ethVesting.cliff, _constructor.ethVesting.cliff);
        assertEq(ethVesting.duration, _constructor.ethVesting.duration);
    }

    function test_constructor_tokenVesting_invalid() public { 
        Constructor memory _constructor = defaultConstructor();
        _constructor.tokenVesting.cliff = 60 days;
        _constructor.tokenVesting.duration = 30 days;
        vm.expectRevert("Vesting duration must be >= cliff period");
        deployContract(_constructor);   
    }

    function test_constructor_tokenVesting_valid() public { 
        Constructor memory _constructor = defaultConstructor();
        _constructor.tokenVesting.cliff = 30 days;
        _constructor.tokenVesting.duration = 365 days;
        PresaleVestedERC20 erc20 = deployContract(_constructor);
        (PresaleVestedERC20.VestingConfiguration memory tokenVesting,,) = erc20.tokenVesting();
        assertEq(tokenVesting.cliff, _constructor.tokenVesting.cliff);
        assertEq(tokenVesting.duration, _constructor.tokenVesting.duration);
    }

    function test_constructor_liquidityVesting_invalid() public { 
        Constructor memory _constructor = defaultConstructor();
        _constructor.liquidityVesting.cliff = 60 days;
        _constructor.liquidityVesting.duration = 30 days;
        vm.expectRevert("Vesting duration must be >= cliff period");
        deployContract(_constructor);
    }

    function test_constructor_liquidityVesting_valid() public { 
        Constructor memory _constructor = defaultConstructor();
        _constructor.liquidityVesting.cliff = 30 days;
        _constructor.liquidityVesting.duration = 365 days;
        PresaleVestedERC20 erc20 = deployContract(_constructor);
        (PresaleVestedERC20.VestingConfiguration memory liquidityVesting,,) = erc20.liquidityVesting();
        assertEq(liquidityVesting.cliff, _constructor.liquidityVesting.cliff);
        assertEq(liquidityVesting.duration, _constructor.liquidityVesting.duration);
    }

    function test_startPresale_nonOwner() public {
        PresaleVestedERC20 erc20 = deployContract(defaultConstructor());
        address nonOwner = getAddresses(1)[0];
        vm.prank(nonOwner);
        vm.expectRevert(
            abi.encodeWithSelector(
                Ownable.OwnableUnauthorizedAccount.selector,
                nonOwner
            )
        );
        erc20.startPresale();
    }

    function test_startPresale_owner() public {
        PresaleVestedERC20 erc20 = deployContract(defaultConstructor());
        (,,uint256 startedTime) = erc20.presale();
        assertEq(startedTime, 0);
        erc20.startPresale();
        (,,startedTime) = erc20.presale();
        assertEq(startedTime, block.timestamp);
        assertEq(uint(erc20.stage()), uint(PresaleVestedERC20.Stage.Presale));
    }

    function test_contributeToPresale_stage_initial() public {
        PresaleVestedERC20 erc20 = deployContract(defaultConstructor());
        vm.expectRevert("Contributions cannot be made. The presale has not started.");
        erc20.contributeToPresale();
    }

    function test_contributeToPresale_stage_refund() public {
        Constructor memory _constructor = defaultConstructor();
        _constructor.presale.softCap = 1 ether;
        PresaleVestedERC20 erc20 = deployContract(_constructor);
        erc20.startPresale();
        vm.warp(vm.getBlockTimestamp() + _constructor.presale.duration + 1);
        vm.expectRevert("Contributions cannot be made. The presale ended without meeting the soft cap. Call claimRefund.");
        erc20.contributeToPresale{value: 1 ether}();
    }

    function test_contributeToPresale_stage_trade() public {
        Constructor memory _constructor = defaultConstructor();
        _constructor.presale.softCap = 1 ether;
        PresaleVestedERC20 erc20 = deployContract(_constructor);
        erc20.startPresale();
        erc20.contributeToPresale{value: _constructor.presale.softCap}();
        vm.warp(vm.getBlockTimestamp() + _constructor.presale.duration + 1);
        vm.expectRevert("Contributions cannot be made. The presale ended and met the soft cap. Call claimTokens.");
        erc20.contributeToPresale();
    }

    function test_contributeToPresale_lessThanMinContribution() public {
        Constructor memory _constructor = defaultConstructor();
        _constructor.presale.minContribution = 1 ether;
        _constructor.presale.maxContribution = 2 ether;
        PresaleVestedERC20 erc20 = deployContract(_constructor);
        erc20.startPresale();
        vm.expectRevert("Contribution minimum is 1000000000000000000 wei, but 500000000000000000 was provided");
        erc20.contributeToPresale{value: _constructor.presale.minContribution / 2 }();
    }

    function test_contributeToPresale_greaterThanMaxContribution() public {
        Constructor memory _constructor = defaultConstructor();
        _constructor.presale.minContribution = 1 ether;
        _constructor.presale.maxContribution = 2 ether;
        PresaleVestedERC20 erc20 = deployContract(_constructor);
        erc20.startPresale();
        vm.expectRevert("Contribution maximum is 2000000000000000000 wei, but 4000000000000000000 was provided");
        erc20.contributeToPresale{value: _constructor.presale.maxContribution * 2}();
    }

    function test_contributeToPresale_greaterThanMaxContribution_multipleTransactions() public {
        Constructor memory _constructor = defaultConstructor();
        _constructor.presale.minContribution = 1 ether;
        _constructor.presale.maxContribution = 2 ether;
        PresaleVestedERC20 erc20 = deployContract(_constructor);
        erc20.startPresale();
        erc20.contributeToPresale{value: _constructor.presale.maxContribution}();
        vm.expectRevert("Contribution maximum is 2000000000000000000 wei, but 4000000000000000000 was provided");
        erc20.contributeToPresale{value: _constructor.presale.maxContribution}();
    }

    function test_contributeToPresale_exceedsHardCap() public {
        Constructor memory _constructor = defaultConstructor();
        _constructor.presale.minContribution = 1 ether;
        _constructor.presale.maxContribution = 2 ether;
        _constructor.presale.softCap = 1 ether;
        _constructor.presale.hardCap = 1 ether;
        PresaleVestedERC20 erc20 = deployContract(_constructor);
        erc20.startPresale();
        vm.expectRevert("Contribution would exceed hard cap of 1000000000000000000 wei");
        erc20.contributeToPresale{value: 2 * _constructor.presale.hardCap}();
    }

    function test_contributeToPresale_exceedsHardCap_multipleTransactions() public {
        Constructor memory _constructor = defaultConstructor();
        _constructor.presale.minContribution = 1 ether;
        _constructor.presale.maxContribution = 2 ether;
        _constructor.presale.softCap = 1 ether;
        _constructor.presale.hardCap = 1 ether;
        PresaleVestedERC20 erc20 = deployContract(_constructor);
        erc20.startPresale();
        erc20.contributeToPresale{value: _constructor.presale.hardCap}();
        vm.expectRevert("Contribution would exceed hard cap of 1000000000000000000 wei");
        erc20.contributeToPresale{value: _constructor.presale.hardCap}();
    }

    function test_contributeToPresale_success() public {
        Constructor memory _constructor = defaultConstructor();
        _constructor.presale.minContribution = 0.1 ether;
        _constructor.presale.maxContribution = 2 ether;
        _constructor.presale.softCap = 10 ether;
        _constructor.presale.hardCap = 20 ether;
        PresaleVestedERC20 erc20 = deployContract(_constructor);
        erc20.startPresale();

        (,uint256 ethContributed,) = erc20.presale();
        assertEq(ethContributed, 0);

        address[] memory addresses = getAddresses(_constructor.presale.hardCap / _constructor.presale.maxContribution);
        uint256 numContributions = _constructor.presale.maxContribution / _constructor.presale.minContribution;

        for (uint256 a = 0; a < addresses.length; a++) {
            address contributor = addresses[a];
            vm.deal(contributor, _constructor.presale.maxContribution);

            for (uint256 c = 1; c <= numContributions; c++) {
                vm.prank(contributor);
                erc20.contributeToPresale{value: _constructor.presale.minContribution}();

                (, ethContributed,) = erc20.presale();
                assertEq(address(erc20).balance, ethContributed);
                assertEq(ethContributed, a * _constructor.presale.maxContribution + c * _constructor.presale.minContribution);
                assertEq(erc20.getContribution(contributor), c * _constructor.presale.minContribution);
                assertEq(contributor.balance, _constructor.presale.maxContribution - c * _constructor.presale.minContribution);
            }
        }

        for (uint256 a = 0; a < addresses.length; a++) {
            assertEq(erc20.getContribution(addresses[a]), _constructor.presale.maxContribution);
        }
    }

    function test_claimRefund_stage_initial() public {
        PresaleVestedERC20 erc20 = deployContract(defaultConstructor());
        vm.expectRevert("Refunds cannot be claimed. The presale has not started.");
        erc20.claimRefund();
    }

    function test_claimRefund_stage_presale() public {
        PresaleVestedERC20 erc20 = deployContract(defaultConstructor());
        erc20.startPresale();
        vm.expectRevert("Refunds cannot be claimed. The presale is still active.");
        erc20.claimRefund();
    }

    function test_claimRefund_stage_trade() public {
        Constructor memory _constructor = defaultConstructor();
        _constructor.presale.softCap = 1 ether;
        PresaleVestedERC20 erc20 = deployContract(_constructor);
        erc20.startPresale();
        erc20.contributeToPresale{value: _constructor.presale.softCap}();
        vm.warp(vm.getBlockTimestamp() + _constructor.presale.duration + 1);
        vm.expectRevert("Refunds cannot be claimed. The presale ended and met the soft cap. Call claimTokens.");
        erc20.claimRefund();
    }

    function test_claimRefund_success() public {
        Constructor memory _constructor = defaultConstructor();
        _constructor.presale.minContribution = 1 ether;
        _constructor.presale.maxContribution = 2 ether;
        _constructor.presale.softCap = 10 ether;
        _constructor.presale.hardCap = 20 ether;
        PresaleVestedERC20 erc20 = deployContract(_constructor);
        erc20.startPresale();

        address[] memory addresses = getAddresses(_constructor.presale.softCap / _constructor.presale.maxContribution);
        uint256 contribution = _constructor.presale.maxContribution - 1 wei;

        for (uint256 i = 0; i < addresses.length; i++) {
            vm.deal(addresses[i], contribution);
            vm.prank(addresses[i]);
            erc20.contributeToPresale{value: contribution}();
        }

        vm.warp(vm.getBlockTimestamp() + _constructor.presale.duration + 1);

        for (uint256 i = 0; i < addresses.length; i++) {
            assertEq(addresses[i].balance, 0);
            vm.prank(addresses[i]);
            erc20.claimRefund();
            assertEq(addresses[i].balance, contribution);

            vm.expectRevert("No contribution to refund");
            vm.prank(addresses[i]);
            erc20.claimRefund();
        }
    }

    function test_claimRefund_nonContributor() public {
        Constructor memory _constructor = defaultConstructor();
        PresaleVestedERC20 erc20 = deployContract(_constructor);
        erc20.startPresale();

        address[] memory addresses = getAddresses(2);
        address nonContributor = addresses[0];
        address contributor = addresses[1];

        vm.deal(contributor, _constructor.presale.maxContribution);
        vm.prank(contributor);
        erc20.contributeToPresale{value: _constructor.presale.maxContribution}();

        vm.warp(vm.getBlockTimestamp() + _constructor.presale.duration + 1);

        vm.expectRevert("No contribution to refund");
        vm.prank(nonContributor);
        erc20.claimRefund();
    }

    function test_claimTokens_stage_initial() public {
        PresaleVestedERC20 erc20 = deployContract(defaultConstructor());
        vm.expectRevert("Tokens cannot be claimed. The presale has not started.");
        erc20.claimTokens();
    }

    function test_claimTokens_stage_presale() public {
        PresaleVestedERC20 erc20 = deployContract(defaultConstructor());
        erc20.startPresale();
        vm.expectRevert("Tokens cannot be claimed. The presale is still active.");
        erc20.claimTokens();
    }

    function test_claimTokens_stage_refund() public {
        Constructor memory _constructor = defaultConstructor();
        PresaleVestedERC20 erc20 = deployContract(_constructor);
        erc20.startPresale();
        vm.warp(vm.getBlockTimestamp() + _constructor.presale.duration + 1);
        vm.expectRevert("Tokens cannot be claimed. The presale ended without meeting the soft cap. Call claimRefund.");
        erc20.claimTokens();
    }

    function test_claimTokens_success() public {
        Constructor memory _constructor = defaultConstructor();
        _constructor.presale.minContribution = 1 ether;
        _constructor.presale.maxContribution = 2 ether;
        _constructor.presale.softCap = 10 ether;
        _constructor.presale.hardCap = 20 ether;
        PresaleVestedERC20 erc20 = deployContract(_constructor);
        erc20.startPresale();

        address[] memory addresses = getAddresses(_constructor.presale.softCap / _constructor.presale.maxContribution);
        uint256 contribution = _constructor.presale.maxContribution;

        for (uint256 i = 0; i < addresses.length; i++) {
            vm.deal(addresses[i], contribution);
            vm.prank(addresses[i]);
            erc20.contributeToPresale{value: contribution}();
        }

        vm.warp(vm.getBlockTimestamp() + _constructor.presale.duration + 1);
        (,uint256 ethContributed,) = erc20.presale();

        for (uint256 i = 0; i < addresses.length; i++) {
            address contributor = addresses[i];
            assertEq(erc20.balanceOf(contributor), 0);

            vm.prank(contributor);
            erc20.claimTokens();

            uint256 expectedBalance = (contribution * erc20.totalSupply() * _constructor.presale.tokensPercentPresale) / (ethContributed * 100);
            assertEq(erc20.balanceOf(contributor), expectedBalance);
        }
    }

    function test_claimTokens_nonContributor() public {
        Constructor memory _constructor = defaultConstructor();
        _constructor.presale.maxContribution = _constructor.presale.softCap;
        PresaleVestedERC20 erc20 = deployContract(_constructor);
        erc20.startPresale();

        address[] memory addresses = getAddresses(2);
        address nonContributor = addresses[0];
        address contributor = addresses[1];

        vm.deal(contributor, _constructor.presale.maxContribution);
        vm.prank(contributor);
        erc20.contributeToPresale{value: _constructor.presale.maxContribution}();

        vm.warp(vm.getBlockTimestamp() + _constructor.presale.duration + 1);

        vm.expectRevert("No contribution to claim");
        vm.prank(nonContributor);
        erc20.claimTokens();
    }

    function test_transfer_toContract() public {
        PresaleVestedERC20 erc20 = deployContract(defaultConstructor());
        address contributor = getAddresses(1)[0];
        vm.expectRevert("Tokens cannot be transferred to the contract itself");
        vm.prank(contributor);
        erc20.transfer(address(erc20), 0);
    }

    function test_presale_liquidity() public {
        Constructor memory _constructor = defaultConstructor();
        _constructor.presale.maxContribution = _constructor.presale.softCap;
        PresaleVestedERC20 erc20 = deployContract(_constructor);
        erc20.startPresale();


        address contributor = getAddresses(1)[0];
        vm.deal(contributor, _constructor.presale.softCap);
        vm.prank(contributor);
        erc20.contributeToPresale{value: _constructor.presale.softCap}();

        vm.warp(vm.getBlockTimestamp() + _constructor.presale.duration + 1);
        (,uint256 ethContributed,) = erc20.presale();

        vm.prank(contributor);
        erc20.claimTokens();

        IERC20 weth = IERC20(IUniswapV2Router02(_constructor.uniswapRouter).WETH());
        IERC20 liquidity = IERC20(
            IUniswapV2Factory(_constructor.uniswapFactory).getPair(address(erc20), address(weth))
        );

        assertEq(ethContributed * _constructor.presale.ethPercentLiquidity / 100, weth.balanceOf(address(liquidity)));
        assertEq(erc20.totalSupply() * _constructor.presale.tokensPercentLiquidity / 100, erc20.balanceOf(address(liquidity)));
    }

    function test_withdrawEth_stage_initial() public {
        PresaleVestedERC20 erc20 = deployContract(defaultConstructor());
        vm.expectRevert("ETH cannot be withdrawn. The presale has not started.");
        erc20.withdrawEth();
    }

    function test_withdrawEth_stage_presale() public {
        PresaleVestedERC20 erc20 = deployContract(defaultConstructor());
        erc20.startPresale();
        vm.expectRevert("ETH cannot be withdrawn. The presale is still active.");
        erc20.withdrawEth();
    }

    function test_withdrawEth_stage_refund() public {
        Constructor memory _constructor = defaultConstructor();
        PresaleVestedERC20 erc20 = deployContract(_constructor);
        erc20.startPresale();
        vm.warp(vm.getBlockTimestamp() + _constructor.presale.duration + 1);
        vm.expectRevert("ETH cannot be withdrawn. The presale ended without meeting the soft cap.");
        erc20.withdrawEth();
    }


    function test_withdrawEth_nonOwner() public {
        PresaleVestedERC20 erc20 = deployContract(defaultConstructor());
        address nonOwner = getAddresses(1)[0];
        vm.prank(nonOwner);
        vm.expectRevert(
            abi.encodeWithSelector(
                Ownable.OwnableUnauthorizedAccount.selector,
                nonOwner
            )
        );
        erc20.withdrawEth();
    }

    function test_withdrawEth_success() public {
        address [] memory addresses = getAddresses(2);
        address contributor = addresses[0];
        address owner = addresses[1];

        Constructor memory _constructor = defaultConstructor();
        _constructor.owner = owner;
        _constructor.presale.maxContribution = _constructor.presale.softCap;
        PresaleVestedERC20 erc20 = deployContract(_constructor);

        vm.prank(owner);
        erc20.startPresale();

        vm.deal(contributor, _constructor.presale.softCap);
        vm.prank(contributor);
        erc20.contributeToPresale{value: _constructor.presale.softCap}();

        vm.warp(vm.getBlockTimestamp() + _constructor.presale.duration + 1);

        // cliff

        uint256 chunkSize = _constructor.ethVesting.cliff / 100;
        for (uint256 i = 0; i < _constructor.ethVesting.cliff; i += chunkSize) {
            vm.expectRevert("0 ETH is withdrawable");
            vm.prank(owner);
            erc20.withdrawEth();
            vm.warp(vm.getBlockTimestamp() + chunkSize);
        }

        // todo: linear vesting



        // vm.expectRevert("0 ETH is withdrawable");
        // vm.prank(owner);
        // erc20.withdrawEth();
    }

    

    // more withdrawEth tests

    function test_withdrawTokens_stage_initial() public {
        PresaleVestedERC20 erc20 = deployContract(defaultConstructor());
        vm.expectRevert("Tokens cannot be withdrawn. The presale has not started.");
        erc20.withdrawTokens();
    }

    function test_withdrawTokens_stage_presale() public {
        PresaleVestedERC20 erc20 = deployContract(defaultConstructor());
        erc20.startPresale();
        vm.expectRevert("Tokens cannot be withdrawn. The presale is still active.");
        erc20.withdrawTokens();
    }

    function test_withdrawTokens_stage_refund() public {
        Constructor memory _constructor = defaultConstructor();
        PresaleVestedERC20 erc20 = deployContract(_constructor);
        erc20.startPresale();
        vm.warp(vm.getBlockTimestamp() + _constructor.presale.duration + 1);
        vm.expectRevert("Tokens cannot be withdrawn. The presale ended without meeting the soft cap.");
        erc20.withdrawTokens();
    }

    function test_withdrawTokens_nonOwner() public {
        PresaleVestedERC20 erc20 = deployContract(defaultConstructor());
        address nonOwner = getAddresses(1)[0];
        vm.prank(nonOwner);
        vm.expectRevert(
            abi.encodeWithSelector(
                Ownable.OwnableUnauthorizedAccount.selector,
                nonOwner
            )
        );
        erc20.withdrawTokens();
    }

    // more withdrawTokens tests

    function test_withdrawLiquidity_stage_initial() public {
        PresaleVestedERC20 erc20 = deployContract(defaultConstructor());
        vm.expectRevert("Liquidity cannot be withdrawn. The presale has not started.");
        erc20.withdrawLiquidity();
    }

    function test_withdrawLiquidity_stage_presale() public {
        PresaleVestedERC20 erc20 = deployContract(defaultConstructor());
        erc20.startPresale();
        vm.expectRevert("Liquidity cannot be withdrawn. The presale is still active.");
        erc20.withdrawLiquidity();
    }

    function test_withdrawLiquidity_stage_refund() public {
        Constructor memory _constructor = defaultConstructor();
        PresaleVestedERC20 erc20 = deployContract(_constructor);
        erc20.startPresale();
        vm.warp(vm.getBlockTimestamp() + _constructor.presale.duration + 1);
        vm.expectRevert("Liquidity cannot be withdrawn. The presale ended without meeting the soft cap.");
        erc20.withdrawLiquidity();
    }

    function test_withdrawLiquidity_nonOwner() public {
        PresaleVestedERC20 erc20 = deployContract(defaultConstructor());
        address nonOwner = getAddresses(1)[0];
        vm.prank(nonOwner);
        vm.expectRevert(
            abi.encodeWithSelector(
                Ownable.OwnableUnauthorizedAccount.selector,
                nonOwner
            )
        );
        erc20.withdrawLiquidity();
    }

    // more withdrawLiquidity tests

}