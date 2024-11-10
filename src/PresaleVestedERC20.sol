// SPDX-License-Identifier: MIT
pragma solidity 0.8.27;

import "openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";
import "openzeppelin-contracts/contracts/access/Ownable.sol";
import "openzeppelin-contracts/contracts/utils/Strings.sol";
import "v2-periphery/interfaces/IUniswapV2Router02.sol";
import 'v2-core/interfaces/IUniswapV2Factory.sol';


contract PresaleVestedERC20 is ERC20, Ownable {

    Presale public presale;
    Vesting public ethVesting;
    Vesting public tokenVesting;
    Vesting public liquidityVesting;
    Stage public stage = Stage.Initial;
    IUniswapV2Router02 public immutable uniswapRouter;
    IUniswapV2Factory public immutable uniswapFactory;

    enum Stage {
        Initial,
        Presale,
        Refund,
        Trade
    }

    struct Presale {
        PresaleConfiguration configuration;
        mapping(address => uint256) contributions;
        uint256 ethContributed;
        uint256 startedTime;
    }

    struct PresaleConfiguration {
        uint256 duration;
        uint256 minContribution;
        uint256 maxContribution;
        uint256 softCap;
        uint256 hardCap;
        uint256 ethPercentLiquidity;
        uint256 ethPercentVest;
        uint256 tokensPercentPresale;
        uint256 tokensPercentLiquidity;
        uint256 tokensPercentVest;
    }

    struct Vesting {
        VestingConfiguration configuration;
        uint256 totalAmount;
        uint256 releasedAmount;
    }

    struct VestingConfiguration {
        uint256 cliff;
        uint256 duration;
    }

    constructor(
        address owner,
        string memory name,
        string memory symbol,
        uint256 totalSupply,
        address _uniswapRouter,
        address _uniswapFactory,
        PresaleConfiguration memory _presale,
        VestingConfiguration memory _ethVesting,
        VestingConfiguration memory _tokenVesting,
        VestingConfiguration memory _liquidityVesting
    ) ERC20(name, symbol) Ownable(owner) {
        require(owner != address(0), "Owner address cannot be empty");
        require(bytes(name).length > 0, "Name cannot be empty");
        require(bytes(symbol).length > 0, "Symbol cannot be empty");
        require(totalSupply > 0, "Total supply must be greater than zero");
        require(_uniswapRouter != address(0), "Uniswap router must be provided");
        require(_uniswapFactory != address(0), "Uniswap factory must be provided");
        require(_presale.duration > 0, "Presale duration must be greater than zero");
        require(_presale.minContribution > 0, "Minimum contribution must be greater than zero");
        require(_presale.softCap > 0, "Presale soft cap must be greater than zero");
        require(
            _presale.maxContribution >= _presale.minContribution,
            "Maximum contribution must be greater than or equal to the minimum contribution"
        );
        require(
            _presale.hardCap >= _presale.softCap,
            "Hard cap must be greater than or equal to the soft cap"
        );
        require(
            _presale.tokensPercentPresale + _presale.tokensPercentLiquidity + _presale.tokensPercentVest == 100 ,
            "tokensPercentPresale + tokensPercentLiquidity + tokensPercentVest must equal 100"
        );
        require(
            _presale.ethPercentLiquidity + _presale.ethPercentVest == 100 ,
            "ethPercentLiquidity + ethPercentVest must equal 100"
        );
        require(
            _ethVesting.duration >= _ethVesting.cliff &&
            _tokenVesting.duration >= _tokenVesting.cliff &&
            _liquidityVesting.duration >= _liquidityVesting.cliff,
            "Vesting duration must be >= cliff period"
        );

        presale.configuration = _presale;
        ethVesting.configuration = _ethVesting;
        tokenVesting.configuration = _tokenVesting;
        liquidityVesting.configuration = _liquidityVesting;
        uniswapRouter = IUniswapV2Router02(_uniswapRouter);
        uniswapFactory = IUniswapV2Factory(_uniswapFactory);

        _mint(address(this), totalSupply);
    }

    function startPresale() external onlyOwner {
        require(stage == Stage.Initial, "Presale was already started");
        presale.startedTime = block.timestamp;
        stage = Stage.Presale;
    }

    function contributeToPresale() external payable checkPresaleOver {
        require(
            stage == Stage.Presale,
            string.concat(
                "Contributions cannot be made. ",
                stage == Stage.Initial ? "The presale has not started." :
                stage == Stage.Refund ? "The presale ended without meeting the soft cap. Call claimRefund." :
                stage == Stage.Trade ? "The presale ended and met the soft cap. Call claimTokens." : ""
            )
        );

        uint256 totalContribution = presale.contributions[msg.sender] + msg.value;
        require(
            totalContribution >= presale.configuration.minContribution,
            string.concat(
                "Contribution minimum is ",
                Strings.toString(presale.configuration.minContribution), " wei, but ", 
                Strings.toString(totalContribution), " was provided"
            )
        );
        require(
            totalContribution <= presale.configuration.maxContribution,
            string.concat(
                "Contribution maximum is ",
                    Strings.toString(presale.configuration.maxContribution), " wei, but ", 
                    Strings.toString(totalContribution), " was provided"
            )
        );
        require(
            presale.ethContributed + msg.value <= presale.configuration.hardCap,
            string.concat(
                "Contribution would exceed hard cap of ",
                Strings.toString(presale.configuration.hardCap), " wei"
            )
        );

        presale.ethContributed += msg.value;
        presale.contributions[msg.sender] += msg.value;
    }

    /// Checks if the presale is over, and transitions to the next stage if necessary
    modifier checkPresaleOver() {
        if (stage == Stage.Presale && block.timestamp > presale.startedTime + presale.configuration.duration) {
            if (presale.ethContributed < presale.configuration.softCap) {
                stage = Stage.Refund;
            } else {
                // Add liquidity
                uint256 ethAmountLiquidity = (presale.ethContributed * presale.configuration.ethPercentLiquidity) / 100;
                uint256 tokenAmountLiquidity = (totalSupply() * presale.configuration.tokensPercentLiquidity) / 100;

                _approve(address(this), address(uniswapRouter), tokenAmountLiquidity);
                (,, liquidityVesting.totalAmount) = uniswapRouter.addLiquidityETH{value: ethAmountLiquidity}(
                    address(this),
                    tokenAmountLiquidity,
                    tokenAmountLiquidity,
                    ethAmountLiquidity,
                    address(this),
                    block.timestamp
                );

                // Start trading + vesting
                ethVesting.totalAmount =  (presale.ethContributed * presale.configuration.ethPercentVest) / 100;
                tokenVesting.totalAmount = (totalSupply() * presale.configuration.tokensPercentVest) / 100;
                stage = Stage.Trade;
            }
        }
        _;
    }

    function claimRefund() external checkPresaleOver {
        require(
            stage == Stage.Refund,
            string.concat(
                "Refunds cannot be claimed. ",
                stage == Stage.Initial ? "The presale has not started." :
                stage == Stage.Presale ? "The presale is still active." :
                stage == Stage.Trade ? "The presale ended and met the soft cap. Call claimTokens." : ""
            )
        );
        uint256 contribution = presale.contributions[msg.sender];
        require(contribution > 0, "No contribution to refund");
        presale.contributions[msg.sender] = 0;
        (bool success, ) = payable(msg.sender).call{value: contribution}("");
        require(success, "Refund failed");
    }

    function claimTokens() external checkPresaleOver {
        require(
            stage == Stage.Trade,
            string.concat(
                "Tokens cannot be claimed. ",
                stage == Stage.Initial ? "The presale has not started." :
                stage == Stage.Presale ? "The presale is still active." :
                stage == Stage.Refund ? "The presale ended without meeting the soft cap. Call claimRefund." : ""
            )
        );

        uint256 contribution = presale.contributions[msg.sender];
        require(contribution > 0, "No contribution to claim");
        presale.contributions[msg.sender] = 0;

        uint256 tokenAmount = (contribution * presale.configuration.tokensPercentPresale * totalSupply()) / (presale.ethContributed * 100);
        _transfer(address(this), msg.sender, tokenAmount);
    }

    function calculateWithdrawableAmount(Vesting memory vesting) internal view returns (uint256) {
        uint256 vestingStartTime = presale.startedTime + presale.configuration.duration;

        uint256 vestedAmount;
        if (block.timestamp < vestingStartTime + vesting.configuration.cliff) {
            vestedAmount = 0;
        } else if (block.timestamp < vestingStartTime + vesting.configuration.duration) {
            uint256 timeVested = block.timestamp - vestingStartTime;
            vestedAmount = (vesting.totalAmount * timeVested) / vesting.configuration.duration;
        } else {
            vestedAmount = vesting.totalAmount;
        }

        return vestedAmount - vesting.releasedAmount;
    }

    function withdrawEth() external onlyOwner() checkPresaleOver {
        require(
            stage == Stage.Trade,
            string.concat(
                "ETH cannot be withdrawn. ",
                stage == Stage.Initial ? "The presale has not started." :
                stage == Stage.Presale ? "The presale is still active." :
                stage == Stage.Refund ? "The presale ended without meeting the soft cap." : ""
            )
        );
        uint256 withdrawableAmount = calculateWithdrawableAmount(ethVesting);
        require(withdrawableAmount > 0, "0 ETH is withdrawable");
        ethVesting.releasedAmount += withdrawableAmount;
        (bool success, ) = owner().call{value: withdrawableAmount}("");
        require(success, "ETH transfer failed");
    }


    function withdrawTokens() external onlyOwner() checkPresaleOver {
        require(
            stage == Stage.Trade,
            string.concat(
                "Tokens cannot be withdrawn. ",
                stage == Stage.Initial ? "The presale has not started." :
                stage == Stage.Presale ? "The presale is still active." :
                stage == Stage.Refund ? "The presale ended without meeting the soft cap." : ""
            )
        );

        uint256 withdrawableAmount = calculateWithdrawableAmount(tokenVesting);
        require(withdrawableAmount > 0, "0 tokens are withdrawable");
        tokenVesting.releasedAmount += withdrawableAmount;
        _transfer(address(this), owner(), withdrawableAmount);
    }

    function withdrawLiquidity() external onlyOwner() checkPresaleOver {
        require(
            stage == Stage.Trade,
            string.concat(
                "Liquidity cannot be withdrawn. ",
                stage == Stage.Initial ? "The presale has not started." :
                stage == Stage.Presale ? "The presale is still active." :
                stage == Stage.Refund ? "The presale ended without meeting the soft cap." : ""
            )
        );

        uint256 withdrawableAmount = calculateWithdrawableAmount(liquidityVesting);
        require(withdrawableAmount > 0, "0 liquidity is withdrawable");
        liquidityVesting.releasedAmount += withdrawableAmount;
        IERC20 liquidityToken = IERC20(uniswapFactory.getPair(address(this), uniswapRouter.WETH()));
        liquidityToken.transfer(owner(), withdrawableAmount);
    }

    function _update(address from, address to, uint256 value) internal override {
        require(
            from == address(0) || to != address(this),
            "Tokens cannot be transferred to the contract itself"
        );
        super._update(from, to, value);
    }

    function getContribution(address contributor) public view returns (uint256) {
        return presale.contributions[contributor];
    }
}
