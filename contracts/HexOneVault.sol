// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "./interfaces/IHexOneVault.sol";
import "./interfaces/IHexOnePriceFeed.sol";

contract HexOneVault is Ownable, IHexOneVault {

    using SafeERC20 for IERC20;

    /// @dev The address of HexOneProtocol contract.
    address public hexOneProtocol;

    /// @dev The contract address to get token price.
    address private hexOnePriceFeed;

    /// @dev The address of collateral(base token).
    /// @dev It can't be updates if is't set once.
    address immutable public baseToken;

    /// @dev The total amount of locked base token.
    uint256 private totalLocked;

    /// @dev The total USD value of locked base tokens.
    uint256 private lockedUSDValue;

    uint16 public LIMIT_PRICE_PERCENT = 66; // 66%

    /// @dev User infos to mange deposit and retrieve.
    mapping(address => UserInfo) private userInfos;

    modifier onlyHexOneProtocol {
        require (msg.sender == hexOneProtocol, "only hexOneProtocol");
        _;
    }

    constructor (
        address _baseToken,
        address _hexOnePriceFeed
    ) {
        require (_baseToken != address(0), "zero base token address");
        require (_hexOnePriceFeed != address(0), "zero priceFeed contract address");

        baseToken = _baseToken;
        hexOnePriceFeed = _hexOnePriceFeed;
    }

    /// @inheritdoc IHexOneVault
    function setHexOneProtocol(address _hexOneProtocol) external onlyOwner {
        require (_hexOneProtocol != address(0), "Zero HexOneProtocol address");
        hexOneProtocol = _hexOneProtocol;
    }

    /// @inheritdoc IHexOneVault
    function depositCollateral(
        address _depositor, 
        uint256 _amount,
        bool _isCommit
    ) external onlyHexOneProtocol override returns (uint256 shareAmount) {
        address sender = msg.sender;
        IERC20(baseToken).safeTransferFrom(sender, address(this), _amount);
        shareAmount = IHexOnePriceFeed(hexOnePriceFeed).getBaseTokenPrice(baseToken, _amount);

        UserInfo storage userInfo = userInfos[_depositor];
        uint256 depositId = userInfo.depositId;
        userInfo.claimed = false;
        userInfo.depositInfos[depositId] = DepositInfo(_amount, shareAmount, block.timestamp, _isCommit);
        userInfo.depositId += 1;

        totalLocked += _amount;
        lockedUSDValue += shareAmount;
    }

    /// @inheritdoc IHexOneVault
    function emergencyWithdraw() external onlyOwner {
        uint256 currentUSDValue = IHexOnePriceFeed(hexOnePriceFeed).getBaseTokenPrice(baseToken, totalLocked);
        uint256 limitUSDValue = totalLocked * LIMIT_PRICE_PERCENT / 100;
        require (limitUSDValue > currentUSDValue, "emergency withdraw condition not meet");
        IERC20(baseToken).safeTransfer(msg.sender, totalLocked);
    }
}